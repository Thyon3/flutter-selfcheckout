import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:selfcheckoutapp/services/logging_service.dart';
import 'package:selfcheckoutapp/services/cache_service.dart';
import 'package:selfcheckoutapp/services/security_service.dart';

class LiveStreamingService {
  static const String _baseUrl = 'https://api.stream.scango.app';
  static const String _wsUrl = 'wss://stream.scango.app/ws';
  static const String _apiKey = 'streaming_api_key_12345';
  static const String _streamKey = 'live_stream_key_12345';
  
  static bool _isInitialized = false;
  static bool _isStreaming = false;
  static bool _isWatching = false;
  static WebSocketChannel? _streamChannel;
  static WebSocketChannel? _watchChannel;
  static StreamSubscription? _streamSubscription;
  static StreamSubscription? _watchSubscription;
  
  static LiveStream? _currentStream;
  static final List<LiveStream> _availableStreams = [];
  static final List<StreamViewer> _currentViewers = [];
  static final List<StreamMessage> _chatMessages = [];
  static StreamController<StreamEvent>? _eventController;

  // Live streaming service initialization
  static Future<bool> initialize() async {
    try {
      if (_isInitialized) return true;
      
      LoggingService.info('Initializing live streaming service');
      
      // Initialize event controller
      _eventController = StreamController<StreamEvent>.broadcast();
      
      // Load available streams
      await _loadAvailableStreams();
      
      _isInitialized = true;
      
      LoggingService.info('Live streaming service initialized successfully');
      return true;
    } catch (e) {
      LoggingService.error('Failed to initialize live streaming service: $e');
      return false;
    }
  }

  // Stream management
  static Future<LiveStreamResult> startStream({
    required String title,
    required String description,
    StreamCategory category = StreamCategory.shopping,
    StreamQuality quality = StreamQuality.high,
    bool isPrivate = false,
    List<String>? allowedViewers,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      if (_isStreaming) {
        return LiveStreamResult(
          success: false,
          error: 'Already streaming',
        );
      }
      
      // Create stream
      final stream = LiveStream(
        id: _generateStreamId(),
        title: title,
        description: description,
        category: category,
        quality: quality,
        isPrivate: isPrivate,
        allowedViewers: allowedViewers ?? [],
        metadata: metadata ?? {},
        streamerId: 'current_user',
        streamKey: _streamKey,
        rtmpUrl: 'rtmp://stream.scango.app/live/${_streamKey}',
        hlsUrl: 'https://stream.scango.app/hls/${_streamKey}.m3u8',
        viewerCount: 0,
        isLive: false,
        startedAt: DateTime.now(),
        thumbnailUrl: null,
      );
      
      // Start streaming session
      final success = await _startStreamingSession(stream);
      
      if (success) {
        _currentStream = stream;
        _isStreaming = true;
        
        // Add to available streams
        _availableStreams.add(stream);
        
        // Emit stream started event
        _emitEvent(StreamEvent(
          type: StreamEventType.streamStarted,
          data: stream.toJson(),
        ));
        
        LoggingService.info('Live stream started: ${stream.id}');
        return LiveStreamResult(
          success: true,
          stream: stream,
        );
      }
      
      return LiveStreamResult(
        success: false,
        error: 'Failed to start streaming session',
      );
    } catch (e) {
      LoggingService.error('Failed to start stream: $e');
      return LiveStreamResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<bool> _startStreamingSession(LiveStream stream) async {
    try {
      // Connect to streaming server
      _streamChannel = WebSocketChannel.connect(Uri.parse('$_wsUrl/stream'));
      
      // Authenticate and start stream
      final authMessage = {
        'type': 'start_stream',
        'stream_id': stream.id,
        'stream_key': stream.streamKey,
        'api_key': _apiKey,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _streamChannel!.sink.add(json.encode(authMessage));
      
      // Listen for stream events
      _streamSubscription = _streamChannel!.stream.listen(
        _handleStreamEvent,
        onError: _handleStreamError,
        onDone: _handleStreamDisconnect,
      );
      
      // Wait for stream to be live
      await Future.delayed(Duration(seconds: 3));
      stream.isLive = true;
      
      return true;
    } catch (e) {
      LoggingService.error('Failed to start streaming session: $e');
      return false;
    }
  }

  static Future<void> stopStream() async {
    try {
      if (!_isStreaming || _currentStream == null) return;
      
      // Send stop message
      if (_streamChannel != null) {
        final stopMessage = {
          'type': 'stop_stream',
          'stream_id': _currentStream!.id,
          'timestamp': DateTime.now().toIso8601String(),
        };
        _streamChannel!.sink.add(json.encode(stopMessage));
      }
      
      // Close connections
      await _streamSubscription?.cancel();
      await _streamChannel?.sink.close();
      _streamChannel = null;
      _streamSubscription = null;
      
      _currentStream!.isLive = false;
      _currentStream!.endedAt = DateTime.now();
      
      _isStreaming = false;
      
      // Emit stream ended event
      _emitEvent(StreamEvent(
        type: StreamEventType.streamEnded,
        data: _currentStream!.toJson(),
      ));
      
      LoggingService.info('Live stream stopped: ${_currentStream!.id}');
      _currentStream = null;
    } catch (e) {
      LoggingService.error('Failed to stop stream: $e');
    }
  }

  // Stream watching
  static Future<WatchStreamResult> watchStream({
    required String streamId,
    String? userId,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      if (_isWatching) {
        return WatchStreamResult(
          success: false,
          error: 'Already watching a stream',
        );
      }
      
      final stream = _availableStreams.firstWhere(
        (s) => s.id == streamId,
        orElse: () => throw Exception('Stream not found: $streamId'),
      );
      
      if (!stream.isLive) {
        return WatchStreamResult(
          success: false,
          error: 'Stream is not live',
        );
      }
      
      // Connect to stream
      _watchChannel = WebSocketChannel.connect(Uri.parse('$_wsUrl/watch'));
      
      // Authenticate and join stream
      final joinMessage = {
        'type': 'join_stream',
        'stream_id': streamId,
        'user_id': userId ?? 'anonymous',
        'api_key': _apiKey,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _watchChannel!.sink.add(json.encode(joinMessage));
      
      // Listen for stream events
      _watchSubscription = _watchChannel!.stream.listen(
        _handleWatchEvent,
        onError: _handleWatchError,
        onDone: _handleWatchDisconnect,
      );
      
      _isWatching = true;
      
      // Add viewer to stream
      final viewer = StreamViewer(
        id: userId ?? 'anonymous',
        joinedAt: DateTime.now(),
        isActive: true,
      );
      _currentViewers.add(viewer);
      stream.viewerCount++;
      
      // Emit viewer joined event
      _emitEvent(StreamEvent(
        type: StreamEventType.viewerJoined,
        data: {
          'stream_id': streamId,
          'viewer_id': viewer.id,
        },
      ));
      
      LoggingService.info('Started watching stream: $streamId');
      return WatchStreamResult(
        success: true,
        stream: stream,
        viewerId: viewer.id,
      );
    } catch (e) {
      LoggingService.error('Failed to watch stream: $e');
      return WatchStreamResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<void> stopWatching() async {
    try {
      if (!_isWatching) return;
      
      // Send leave message
      if (_watchChannel != null) {
        final leaveMessage = {
          'type': 'leave_stream',
          'timestamp': DateTime.now().toIso8601String(),
        };
        _watchChannel!.sink.add(json.encode(leaveMessage));
      }
      
      // Close connections
      await _watchSubscription?.cancel();
      await _watchChannel?.sink.close();
      _watchChannel = null;
      _watchSubscription = null;
      
      // Remove viewer
      if (_currentViewers.isNotEmpty) {
        final viewer = _currentViewers.last;
        viewer.isActive = false;
        viewer.leftAt = DateTime.now();
        
        if (_currentStream != null) {
          _currentStream!.viewerCount--;
        }
      }
      
      _isWatching = false;
      
      LoggingService.info('Stopped watching stream');
    } catch (e) {
      LoggingService.error('Failed to stop watching: $e');
    }
  }

  // Shopping-specific streaming features
  static Future<LiveStreamResult> startProductShowcase({
    required String productId,
    required String productName,
    required double price,
    String? description,
    String? imageUrl,
    Map<String, dynamic>? productDetails,
  }) async {
    try {
      final title = '🛍️ $productName - Live Product Showcase';
      final streamDescription = description ?? 'Check out this amazing product: $productName for Rs $price';
      
      final metadata = {
        'type': 'product_showcase',
        'product_id': productId,
        'product_name': productName,
        'price': price,
        'image_url': imageUrl,
        'product_details': productDetails ?? {},
      };
      
      return await startStream(
        title: title,
        description: streamDescription,
        category: StreamCategory.shopping,
        metadata: metadata,
      );
    } catch (e) {
      LoggingService.error('Failed to start product showcase: $e');
      return LiveStreamResult(success: false, error: e.toString());
    }
  }

  static Future<LiveStreamResult> startShoppingTour({
    required String storeId,
    required String storeName,
    List<String>? productIds,
    Map<String, dynamic>? tourDetails,
  }) async {
    try {
      final title = '🏪 Shopping Tour: $storeName';
      final description = 'Join me for a live shopping tour at $storeName!';
      
      final metadata = {
        'type': 'shopping_tour',
        'store_id': storeId,
        'store_name': storeName,
        'product_ids': productIds ?? [],
        'tour_details': tourDetails ?? {},
      };
      
      return await startStream(
        title: title,
        description: description,
        category: StreamCategory.shopping,
        metadata: metadata,
      );
    } catch (e) {
      LoggingService.error('Failed to start shopping tour: $e');
      return LiveStreamResult(success: false, error: e.toString());
    }
  }

  static Future<LiveStreamResult> startLiveQAndA({
    required String topic,
    List<String>? panelists,
    Map<String, dynamic>? sessionDetails,
  }) async {
    try {
      final title = '❓ Live Q&A: $topic';
      final description = 'Join our live Q&A session about $topic';
      
      final metadata = {
        'type': 'live_qa',
        'topic': topic,
        'panelists': panelists ?? [],
        'session_details': sessionDetails ?? {},
      };
      
      return await startStream(
        title: title,
        description: description,
        category: StreamCategory.qa,
        metadata: metadata,
      );
    } catch (e) {
      LoggingService.error('Failed to start live Q&A: $e');
      return LiveStreamResult(success: false, error: e.toString());
    }
  }

  // Chat and interaction
  static Future<void> sendChatMessage({
    required String message,
    String? userId,
    String? username,
  }) async {
    try {
      if (!_isWatching || _watchChannel == null) {
        throw Exception('Not watching any stream');
      }
      
      final chatMessage = {
        'type': 'chat_message',
        'message': message,
        'user_id': userId ?? 'anonymous',
        'username': username ?? 'Anonymous',
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _watchChannel!.sink.add(json.encode(chatMessage));
      
      LoggingService.info('Chat message sent: $message');
    } catch (e) {
      LoggingService.error('Failed to send chat message: $e');
    }
  }

  static Future<void> sendReaction({
    required StreamReaction reaction,
    String? userId,
  }) async {
    try {
      if (!_isWatching || _watchChannel == null) {
        throw Exception('Not watching any stream');
      }
      
      final reactionMessage = {
        'type': 'reaction',
        'reaction': reaction.name,
        'user_id': userId ?? 'anonymous',
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _watchChannel!.sink.add(json.encode(reactionMessage));
      
      LoggingService.info('Reaction sent: ${reaction.name}');
    } catch (e) {
      LoggingService.error('Failed to send reaction: $e');
    }
  }

  static Future<void> sendGift({
    required String giftId,
    required String giftName,
    required int giftValue,
    String? userId,
  }) async {
    try {
      if (!_isWatching || _watchChannel == null) {
        throw Exception('Not watching any stream');
      }
      
      final giftMessage = {
        'type': 'gift',
        'gift_id': giftId,
        'gift_name': giftName,
        'gift_value': giftValue,
        'user_id': userId ?? 'anonymous',
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _watchChannel!.sink.add(json.encode(giftMessage));
      
      LoggingService.info('Gift sent: $giftName');
    } catch (e) {
      LoggingService.error('Failed to send gift: $e');
    }
  }

  // Stream discovery
  static Future<List<LiveStream>> getAvailableStreams({
    StreamCategory? category,
    bool? liveOnly,
    int? limit,
  }) async {
    try {
      var streams = List<LiveStream>.from(_availableStreams);
      
      if (category != null) {
        streams = streams.where((s) => s.category == category).toList();
      }
      
      if (liveOnly == true) {
        streams = streams.where((s) => s.isLive).toList();
      }
      
      streams.sort((a, b) => b.viewerCount.compareTo(a.viewerCount));
      
      if (limit != null && streams.length > limit) {
        streams = streams.take(limit).toList();
      }
      
      return streams;
    } catch (e) {
      LoggingService.error('Failed to get available streams: $e');
      return [];
    }
  }

  static Future<LiveStream?> getStream(String streamId) async {
    try {
      return _availableStreams.firstWhere(
        (s) => s.id == streamId,
        orElse: () => throw Exception('Stream not found: $streamId'),
      );
    } catch (e) {
      LoggingService.error('Failed to get stream: $e');
      return null;
    }
  }

  // Stream analytics
  static Future<StreamAnalytics> getStreamAnalytics({
    String? streamId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Mock analytics data
      final totalViews = Random().nextInt(10000);
      final totalWatchTime = Duration(minutes: Random().nextInt(120));
      final peakViewers = Random().nextInt(500);
      final avgWatchTime = Duration(minutes: Random().nextInt(30));
      
      return StreamAnalytics(
        streamId: streamId,
        totalViews: totalViews,
        totalWatchTime: totalWatchTime,
        peakViewers: peakViewers,
        averageWatchTime: avgWatchTime,
        engagementRate: Random().nextDouble() * 100,
        startDate: startDate ?? DateTime.now().subtract(Duration(days: 7)),
        endDate: endDate ?? DateTime.now(),
      );
    } catch (e) {
      LoggingService.error('Failed to get stream analytics: $e');
      return StreamAnalytics(
        streamId: streamId,
        totalViews: 0,
        totalWatchTime: Duration.zero,
        peakViewers: 0,
        averageWatchTime: Duration.zero,
        engagementRate: 0.0,
        startDate: DateTime.now(),
        endDate: DateTime.now(),
      );
    }
  }

  // Event handlers
  static void _handleStreamEvent(dynamic event) {
    try {
      final data = json.decode(event);
      final eventType = data['type'];
      
      switch (eventType) {
        case 'stream_started':
          if (_currentStream != null) {
            _currentStream!.isLive = true;
            _emitEvent(StreamEvent(
              type: StreamEventType.streamLive,
              data: _currentStream!.toJson(),
            ));
          }
          break;
        case 'viewer_joined':
          if (_currentStream != null) {
            _currentStream!.viewerCount++;
            _emitEvent(StreamEvent(
              type: StreamEventType.viewerJoined,
              data: data,
            ));
          }
          break;
        case 'viewer_left':
          if (_currentStream != null) {
            _currentStream!.viewerCount--;
            _emitEvent(StreamEvent(
              type: StreamEventType.viewerLeft,
              data: data,
            ));
          }
          break;
        case 'chat_message':
          final message = StreamMessage.fromJson(data);
          _chatMessages.add(message);
          _emitEvent(StreamEvent(
            type: StreamEventType.chatMessage,
            data: message.toJson(),
          ));
          break;
      }
    } catch (e) {
      LoggingService.error('Failed to handle stream event: $e');
    }
  }

  static void _handleWatchEvent(dynamic event) {
    try {
      final data = json.decode(event);
      final eventType = data['type'];
      
      switch (eventType) {
        case 'stream_data':
          // Handle stream data (video/audio)
          break;
        case 'chat_message':
          final message = StreamMessage.fromJson(data);
          _chatMessages.add(message);
          _emitEvent(StreamEvent(
            type: StreamEventType.chatMessage,
            data: message.toJson(),
          ));
          break;
        case 'reaction':
          _emitEvent(StreamEvent(
            type: StreamEventType.reaction,
            data: data,
          ));
          break;
        case 'gift':
          _emitEvent(StreamEvent(
            type: StreamEventType.gift,
            data: data,
          ));
          break;
      }
    } catch (e) {
      LoggingService.error('Failed to handle watch event: $e');
    }
  }

  static void _handleStreamError(dynamic error) {
    LoggingService.error('Stream error: $error');
    _emitEvent(StreamEvent(
      type: StreamEventType.error,
      data: {'error': error.toString()},
    ));
  }

  static void _handleStreamDisconnect() {
    LoggingService.info('Stream disconnected');
    _isStreaming = false;
    if (_currentStream != null) {
      _currentStream!.isLive = false;
    }
    _emitEvent(StreamEvent(
      type: StreamEventType.streamDisconnected,
      data: {},
    ));
  }

  static void _handleWatchError(dynamic error) {
    LoggingService.error('Watch error: $error');
    _emitEvent(StreamEvent(
      type: StreamEventType.error,
      data: {'error': error.toString()},
    ));
  }

  static void _handleWatchDisconnect() {
    LoggingService.info('Watch disconnected');
    _isWatching = false;
    _currentViewers.clear();
    _emitEvent(StreamEvent(
      type: StreamEventType.watchDisconnected,
      data: {},
    ));
  }

  static void _emitEvent(StreamEvent event) {
    _eventController?.add(event);
  }

  // Data persistence
  static Future<void> _loadAvailableStreams() async {
    try {
      // Mock loading available streams
      _availableStreams.addAll([
        LiveStream(
          id: 'stream_1',
          title: 'Live Product Showcase: iPhone 15',
          description: 'Check out the latest iPhone 15 features',
          category: StreamCategory.shopping,
          quality: StreamQuality.high,
          isPrivate: false,
          allowedViewers: [],
          metadata: {
            'type': 'product_showcase',
            'product_id': 'iphone_15',
            'product_name': 'iPhone 15',
          },
          streamerId: 'user_1',
          streamKey: 'stream_key_1',
          rtmpUrl: 'rtmp://stream.scango.app/live/stream_key_1',
          hlsUrl: 'https://stream.scango.app/hls/stream_key_1.m3u8',
          viewerCount: 150,
          isLive: true,
          startedAt: DateTime.now().subtract(Duration(minutes: 30)),
          thumbnailUrl: 'https://example.com/thumb1.jpg',
        ),
        LiveStream(
          id: 'stream_2',
          title: 'Shopping Tour: Supermarket',
          description: 'Live tour of the local supermarket',
          category: StreamCategory.shopping,
          quality: StreamQuality.medium,
          isPrivate: false,
          allowedViewers: [],
          metadata: {
            'type': 'shopping_tour',
            'store_id': 'store_1',
            'store_name': 'Local Supermarket',
          },
          streamerId: 'user_2',
          streamKey: 'stream_key_2',
          rtmpUrl: 'rtmp://stream.scango.app/live/stream_key_2',
          hlsUrl: 'https://stream.scango.app/hls/stream_key_2.m3u8',
          viewerCount: 75,
          isLive: true,
          startedAt: DateTime.now().subtract(Duration(minutes: 15)),
          thumbnailUrl: 'https://example.com/thumb2.jpg',
        ),
      ]);
    } catch (e) {
      LoggingService.error('Failed to load available streams: $e');
    }
  }

  static String _generateStreamId() {
    return 'stream_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Getters
  static bool get isInitialized => _isInitialized;
  static bool get isStreaming => _isStreaming;
  static bool get isWatching => _isWatching;
  static LiveStream? get currentStream => _currentStream;
  static List<LiveStream> get availableStreams => List.from(_availableStreams);
  static List<StreamViewer> get currentViewers => List.from(_currentViewers);
  static List<StreamMessage> get chatMessages => List.from(_chatMessages);
  static Stream<StreamEvent> get events => _eventController?.stream ?? Stream.empty();
}

// Data models
class LiveStream {
  final String id;
  final String title;
  final String description;
  final StreamCategory category;
  final StreamQuality quality;
  final bool isPrivate;
  final List<String> allowedViewers;
  final Map<String, dynamic> metadata;
  final String streamerId;
  final String streamKey;
  final String rtmpUrl;
  final String hlsUrl;
  int viewerCount;
  bool isLive;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? thumbnailUrl;

  LiveStream({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.quality,
    required this.isPrivate,
    required this.allowedViewers,
    required this.metadata,
    required this.streamerId,
    required this.streamKey,
    required this.rtmpUrl,
    required this.hlsUrl,
    required this.viewerCount,
    required this.isLive,
    required this.startedAt,
    this.endedAt,
    this.thumbnailUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'quality': quality.name,
      'is_private': isPrivate,
      'allowed_viewers': allowedViewers,
      'metadata': metadata,
      'streamer_id': streamerId,
      'stream_key': streamKey,
      'rtmp_url': rtmpUrl,
      'hls_url': hlsUrl,
      'viewer_count': viewerCount,
      'is_live': isLive,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'thumbnail_url': thumbnailUrl,
    };
  }
}

class StreamViewer {
  final String id;
  final DateTime joinedAt;
  final DateTime? leftAt;
  bool isActive;

  StreamViewer({
    required this.id,
    required this.joinedAt,
    this.leftAt,
    required this.isActive,
  });
}

class StreamMessage {
  final String id;
  final String streamId;
  final String userId;
  final String username;
  final String message;
  final DateTime timestamp;

  StreamMessage({
    required this.id,
    required this.streamId,
    required this.userId,
    required this.username,
    required this.message,
    required this.timestamp,
  });

  factory StreamMessage.fromJson(Map<String, dynamic> json) {
    return StreamMessage(
      id: json['id'] ?? 'msg_${DateTime.now().millisecondsSinceEpoch}',
      streamId: json['stream_id'] ?? '',
      userId: json['user_id'] ?? '',
      username: json['username'] ?? '',
      message: json['message'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stream_id': streamId,
      'user_id': userId,
      'username': username,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class StreamAnalytics {
  final String? streamId;
  final int totalViews;
  final Duration totalWatchTime;
  final int peakViewers;
  final Duration averageWatchTime;
  final double engagementRate;
  final DateTime startDate;
  final DateTime endDate;

  StreamAnalytics({
    this.streamId,
    required this.totalViews,
    required this.totalWatchTime,
    required this.peakViewers,
    required this.averageWatchTime,
    required this.engagementRate,
    required this.startDate,
    required this.endDate,
  });
}

class StreamEvent {
  final StreamEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  StreamEvent({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class LiveStreamResult {
  final bool success;
  final LiveStream? stream;
  final String? error;

  LiveStreamResult({
    required this.success,
    this.stream,
    this.error,
  });
}

class WatchStreamResult {
  final bool success;
  final LiveStream? stream;
  final String? viewerId;
  final String? error;

  WatchStreamResult({
    required this.success,
    this.stream,
    this.viewerId,
    this.error,
  });
}

enum StreamCategory {
  shopping,
  gaming,
  music,
  sports,
  education,
  qa,
  lifestyle,
}

enum StreamQuality {
  low,
  medium,
  high,
  ultra,
}

enum StreamReaction {
  like,
  love,
  laugh,
  wow,
  sad,
  angry,
}

enum StreamEventType {
  streamStarted,
  streamEnded,
  streamLive,
  streamDisconnected,
  viewerJoined,
  viewerLeft,
  watchDisconnected,
  chatMessage,
  reaction,
  gift,
  error,
}
