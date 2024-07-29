import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:selfcheckoutapp/services/logging_service.dart';
import 'package:selfcheckoutapp/services/cache_service.dart';
import 'package:selfcheckoutapp/services/ar_service.dart';

class VirtualTryOnService {
  static const String _baseUrl = 'https://api.vto.scango.app';
  static const String _apiKey = 'vto_api_key_12345';
  static const String _cacheKey = 'vto_cache';
  
  static bool _isInitialized = false;
  static bool _isCameraActive = false;
  static StreamSubscription? _cameraSubscription;
  static final List<VirtualItem> _availableItems = [];
  static final List<TryOnSession> _sessionHistory = [];
  static TryOnSession? _currentSession;
  static StreamController<VTOEvent>? _eventController;

  // Virtual try-on service initialization
  static Future<bool> initialize() async {
    try {
      if (_isInitialized) return true;
      
      LoggingService.info('Initializing virtual try-on service');
      
      // Initialize AR service dependency
      await ARService.initialize();
      
      // Initialize event controller
      _eventController = StreamController<VTOEvent>.broadcast();
      
      // Load available items
      await _loadAvailableItems();
      
      // Load session history
      await _loadSessionHistory();
      
      _isInitialized = true;
      
      LoggingService.info('Virtual try-on service initialized successfully');
      return true;
    } catch (e) {
      LoggingService.error('Failed to initialize virtual try-on service: $e');
      return false;
    }
  }

  // Camera management
  static Future<CameraResult> startCamera() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      if (_isCameraActive) {
        return CameraResult(
          success: false,
          error: 'Camera already active',
        );
      }
      
      // Mock camera initialization
      await Future.delayed(Duration(milliseconds: 1500));
      
      _isCameraActive = true;
      
      // Start camera stream
      _cameraSubscription = _mockCameraStream().listen(
        (frame) {
          _handleCameraFrame(frame);
        },
        onError: _handleCameraError,
      );
      
      LoggingService.info('Camera started for virtual try-on');
      return CameraResult(
        success: true,
        cameraId: 'vto_camera_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      LoggingService.error('Failed to start camera: $e');
      return CameraResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<void> stopCamera() async {
    try {
      if (!_isCameraActive) return;
      
      await _cameraSubscription?.cancel();
      _cameraSubscription = null;
      _isCameraActive = false;
      
      LoggingService.info('Camera stopped');
    } catch (e) {
      LoggingService.error('Failed to stop camera: $e');
    }
  }

  static Stream<CameraFrame> _mockCameraStream() async* {
    // Mock camera stream
    while (_isCameraActive) {
      await Future.delayed(Duration(milliseconds: 33)); // ~30 FPS
      yield CameraFrame(
        data: Uint8List.fromList(List.generate(640 * 480 * 3, (_) => Random().nextInt(256))),
        timestamp: DateTime.now(),
        width: 640,
        height: 480,
      );
    }
  }

  static void _handleCameraFrame(CameraFrame frame) {
    // Process camera frame for AR tracking
    _emitEvent(VTOEvent(
      type: VTOEventType.cameraFrame,
      data: {
        'timestamp': frame.timestamp.toIso8601String(),
        'width': frame.width,
        'height': frame.height,
      },
    ));
  }

  static void _handleCameraError(dynamic error) {
    LoggingService.error('Camera error: $error');
    _emitEvent(VTOEvent(
      type: VTOEventType.error,
      data: {'error': error.toString()},
    ));
  }

  // Try-on sessions
  static Future<TryOnResult> startTryOnSession({
    required String productId,
    required String productName,
    required ItemType itemType,
    Map<String, dynamic>? itemMetadata,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      if (!_isCameraActive) {
        final cameraResult = await startCamera();
        if (!cameraResult.success) {
          return TryOnResult(
            success: false,
            error: 'Failed to start camera: ${cameraResult.error}',
          );
        }
      }
      
      // Get virtual item
      final virtualItem = await _getVirtualItem(productId, itemType);
      if (virtualItem == null) {
        return TryOnResult(
          success: false,
          error: 'Virtual item not found: $productId',
        );
      }
      
      // Create try-on session
      final session = TryOnSession(
        id: _generateSessionId(),
        productId: productId,
        productName: productName,
        itemType: itemType,
        itemMetadata: itemMetadata ?? {},
        virtualItem: virtualItem,
        startedAt: DateTime.now(),
        isActive: true,
        snapshots: [],
        measurements: {},
      );
      
      _currentSession = session;
      
      // Start AR tracking
      await _startARTracking(session);
      
      // Emit session started event
      _emitEvent(VTOEvent(
        type: VTOEventType.sessionStarted,
        data: session.toJson(),
      ));
      
      LoggingService.info('Try-on session started: ${session.id}');
      return TryOnResult(
        success: true,
        session: session,
      );
    } catch (e) {
      LoggingService.error('Failed to start try-on session: $e');
      return TryOnResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<void> _startARTracking(TryOnSession session) async {
    try {
      // Initialize AR session for try-on
      final arSession = await ARService.createSession(
        sessionId: 'vto_${session.id}',
        sessionType: ARSessionType.tryOn,
      );
      
      if (arSession != null) {
        // Add virtual item to AR session
        await ARService.addObject(
          sessionId: arSession.id,
          objectId: 'vto_item_${session.id}',
          modelUrl: session.virtualItem.model3DUrl,
          position: Vector3(0, 0, 0),
          scale: Vector3(1, 1, 1),
        );
        
        session.arSessionId = arSession.id;
      }
    } catch (e) {
      LoggingService.error('Failed to start AR tracking: $e');
    }
  }

  static Future<void> stopTryOnSession() async {
    try {
      if (_currentSession == null) return;
      
      final session = _currentSession!;
      session.isActive = false;
      session.endedAt = DateTime.now();
      
      // Stop AR tracking
      if (session.arSessionId != null) {
        await ARService.endSession(session.arSessionId!);
      }
      
      // Add to history
      _sessionHistory.add(session);
      
      // Save session
      await _saveSession(session);
      
      // Emit session ended event
      _emitEvent(VTOEvent(
        type: VTOEventType.sessionEnded,
        data: session.toJson(),
      ));
      
      _currentSession = null;
      
      LoggingService.info('Try-on session ended');
    } catch (e) {
      LoggingService.error('Failed to stop try-on session: $e');
    }
  }

  // Virtual items
  static Future<VirtualItem?> _getVirtualItem(String productId, ItemType type) async {
    try {
      // Try to find in available items
      final item = _availableItems.firstWhere(
        (i) => i.productId == productId && i.type == type,
        orElse: () => throw Exception('Item not found'),
      );
      
      return item;
    } catch (e) {
      // Create virtual item on-demand
      return await _createVirtualItem(productId, type);
    }
  }

  static Future<VirtualItem> _createVirtualItem(String productId, ItemType type) async {
    try {
      // Mock API call to create virtual item
      await Future.delayed(Duration(milliseconds: 1000));
      
      final virtualItem = VirtualItem(
        id: 'vto_item_${productId}',
        productId: productId,
        type: type,
        name: 'Virtual $type $productId',
        model3DUrl: 'https://api.vto.scango.app/models/${productId}.glb',
        textureUrl: 'https://api.vto.scango.app/textures/${productId}.jpg',
        size: Vector3(1, 1, 1),
        color: '#FFFFFF',
        material: 'default',
        isAvailable: true,
        createdAt: DateTime.now(),
      );
      
      _availableItems.add(virtualItem);
      
      return virtualItem;
    } catch (e) {
      LoggingService.error('Failed to create virtual item: $e');
      rethrow;
    }
  }

  static Future<List<VirtualItem>> getAvailableItems({ItemType? type}) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (type != null) {
      return _availableItems.where((item) => item.type == type).toList();
    }
    
    return List.from(_availableItems);
  }

  // Session interactions
  static Future<TryOnSnapshot> captureSnapshot({
    String? pose,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (_currentSession == null) {
        throw Exception('No active try-on session');
      }
      
      // Capture current camera frame with AR overlay
      final snapshot = TryOnSnapshot(
        id: _generateSnapshotId(),
        sessionId: _currentSession!.id,
        pose: pose ?? 'front',
        imageUrl: 'https://api.vto.scango.app/snapshots/${_currentSession!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        metadata: metadata ?? {},
        timestamp: DateTime.now(),
      );
      
      _currentSession!.snapshots.add(snapshot);
      
      // Emit snapshot captured event
      _emitEvent(VTOEvent(
        type: VTOEventType.snapshotCaptured,
        data: snapshot.toJson(),
      ));
      
      LoggingService.info('Snapshot captured: ${snapshot.id}');
      return snapshot;
    } catch (e) {
      LoggingService.error('Failed to capture snapshot: $e');
      rethrow;
    }
  }

  static Future<void> updateItemPosition({
    required Vector3 position,
    Vector3? rotation,
    Vector3? scale,
  }) async {
    try {
      if (_currentSession == null || _currentSession!.arSessionId == null) {
        throw Exception('No active AR session');
      }
      
      // Update AR object position
      await ARService.updateObject(
        sessionId: _currentSession!.arSessionId!,
        objectId: 'vto_item_${_currentSession!.id}',
        position: position,
        rotation: rotation,
        scale: scale,
      );
      
      // Emit position updated event
      _emitEvent(VTOEvent(
        type: VTOEventType.itemPositionUpdated,
        data: {
          'position': position.toJson(),
          'rotation': rotation?.toJson(),
          'scale': scale?.toJson(),
        },
      ));
    } catch (e) {
      LoggingService.error('Failed to update item position: $e');
    }
  }

  static Future<void> changeItemColor({
    required String color,
    String? textureUrl,
  }) async {
    try {
      if (_currentSession == null) {
        throw Exception('No active try-on session');
      }
      
      // Update virtual item color
      _currentSession!.virtualItem.color = color;
      if (textureUrl != null) {
        _currentSession!.virtualItem.textureUrl = textureUrl;
      }
      
      // Update AR object material
      if (_currentSession!.arSessionId != null) {
        await ARService.updateObjectMaterial(
          sessionId: _currentSession!.arSessionId!,
          objectId: 'vto_item_${_currentSession!.id}',
          textureUrl: textureUrl,
          color: color,
        );
      }
      
      // Emit color changed event
      _emitEvent(VTOEvent(
        type: VTOEventType.itemColorChanged,
        data: {
          'color': color,
          'texture_url': textureUrl,
        },
      ));
    } catch (e) {
      LoggingService.error('Failed to change item color: $e');
    }
  }

  static Future<void> takeMeasurements() async {
    try {
      if (_currentSession == null) {
        throw Exception('No active try-on session');
      }
      
      // Mock measurements based on AR tracking
      final measurements = {
        'chest': Random().nextInt(20) + 80, // 80-100 cm
        'waist': Random().nextInt(15) + 60, // 60-75 cm
        'hips': Random().nextInt(20) + 85, // 85-105 cm
        'height': Random().nextInt(30) + 150, // 150-180 cm
        'arm_length': Random().nextInt(10) + 55, // 55-65 cm
      };
      
      _currentSession!.measurements = measurements;
      
      // Emit measurements taken event
      _emitEvent(VTOEvent(
        type: VTOEventType.measurementsTaken,
        data: measurements,
      ));
      
      LoggingService.info('Measurements taken: $measurements');
    } catch (e) {
      LoggingService.error('Failed to take measurements: $e');
    }
  }

  // Shopping-specific features
  static Future<TryOnResult> tryOnClothing({
    required String productId,
    required String productName,
    required String size,
    String? color,
  }) async {
    try {
      final metadata = {
        'size': size,
        'color': color ?? 'default',
        'category': 'clothing',
      };
      
      return await startTryOnSession(
        productId: productId,
        productName: productName,
        itemType: ItemType.clothing,
        itemMetadata: metadata,
      );
    } catch (e) {
      LoggingService.error('Failed to try on clothing: $e');
      return TryOnResult(success: false, error: e.toString());
    }
  }

  static Future<TryOnResult> tryOnAccessories({
    required String productId,
    required String productName,
    required AccessoryType accessoryType,
    String? color,
  }) async {
    try {
      final metadata = {
        'accessory_type': accessoryType.name,
        'color': color ?? 'default',
        'category': 'accessories',
      };
      
      return await startTryOnSession(
        productId: productId,
        productName: productName,
        itemType: ItemType.accessories,
        itemMetadata: metadata,
      );
    } catch (e) {
      LoggingService.error('Failed to try on accessories: $e');
      return TryOnResult(success: false, error: e.toString());
    }
  }

  static Future<TryOnResult> tryOnFootwear({
    required String productId,
    required String productName,
    required String size,
    String? color,
  }) async {
    try {
      final metadata = {
        'size': size,
        'color': color ?? 'default',
        'category': 'footwear',
      };
      
      return await startTryOnSession(
        productId: productId,
        productName: productName,
        itemType: ItemType.footwear,
        itemMetadata: metadata,
      );
    } catch (e) {
      LoggingService.error('Failed to try on footwear: $e');
      return TryOnResult(success: false, error: e.toString());
    }
  }

  // Session history and analytics
  static Future<List<TryOnSession>> getSessionHistory({
    DateTime? startDate,
    DateTime? endDate,
    ItemType? itemType,
    int? limit,
  }) async {
    try {
      var history = List<TryOnSession>.from(_sessionHistory);
      
      if (startDate != null) {
        history = history.where((session) => session.startedAt.isAfter(startDate)).toList();
      }
      
      if (endDate != null) {
        history = history.where((session) => session.startedAt.isBefore(endDate)).toList();
      }
      
      if (itemType != null) {
        history = history.where((session) => session.itemType == itemType).toList();
      }
      
      history.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      
      if (limit != null && history.length > limit) {
        history = history.take(limit).toList();
      }
      
      return history;
    } catch (e) {
      LoggingService.error('Failed to get session history: $e');
      return [];
    }
  }

  static Future<VTOAnalytics> getAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final history = await getSessionHistory(startDate: startDate, endDate: endDate);
      
      final itemTypeStats = <ItemType, int>{};
      int totalSessions = history.length;
      int totalSnapshots = 0;
      Duration totalDuration = Duration.zero;
      
      for (final session in history) {
        itemTypeStats[session.itemType] = (itemTypeStats[session.itemType] ?? 0) + 1;
        totalSnapshots += session.snapshots.length;
        
        if (session.endedAt != null) {
          totalDuration += session.endedAt!.difference(session.startedAt);
        }
      }
      
      final avgSessionDuration = totalSessions > 0 
          ? Duration(milliseconds: totalDuration.inMilliseconds ~/ totalSessions)
          : Duration.zero;
      
      return VTOAnalytics(
        totalSessions: totalSessions,
        totalSnapshots: totalSnapshots,
        averageSessionDuration: avgSessionDuration,
        itemTypeStats: itemTypeStats,
        startDate: startDate ?? DateTime.now().subtract(Duration(days: 30)),
        endDate: endDate ?? DateTime.now(),
      );
    } catch (e) {
      LoggingService.error('Failed to get VTO analytics: $e');
      return VTOAnalytics(
        totalSessions: 0,
        totalSnapshots: 0,
        averageSessionDuration: Duration.zero,
        itemTypeStats: {},
        startDate: DateTime.now(),
        endDate: DateTime.now(),
      );
    }
  }

  // Utility methods
  static void _emitEvent(VTOEvent event) {
    _eventController?.add(event);
  }

  static Future<void> _loadAvailableItems() async {
    try {
      // Mock loading available items
      _availableItems.addAll([
        VirtualItem(
          id: 'vto_shirt_1',
          productId: 'shirt_1',
          type: ItemType.clothing,
          name: 'Virtual T-Shirt',
          model3DUrl: 'https://api.vto.scango.app/models/shirt_1.glb',
          textureUrl: 'https://api.vto.scango.app/textures/shirt_1.jpg',
          size: Vector3(1, 1, 1),
          color: '#FFFFFF',
          material: 'cotton',
          isAvailable: true,
          createdAt: DateTime.now(),
        ),
        VirtualItem(
          id: 'vto_pants_1',
          productId: 'pants_1',
          type: ItemType.clothing,
          name: 'Virtual Jeans',
          model3DUrl: 'https://api.vto.scango.app/models/pants_1.glb',
          textureUrl: 'https://api.vto.scango.app/textures/pants_1.jpg',
          size: Vector3(1, 1, 1),
          color: '#0000FF',
          material: 'denim',
          isAvailable: true,
          createdAt: DateTime.now(),
        ),
        VirtualItem(
          id: 'vto_watch_1',
          productId: 'watch_1',
          type: ItemType.accessories,
          name: 'Virtual Watch',
          model3DUrl: 'https://api.vto.scango.app/models/watch_1.glb',
          textureUrl: 'https://api.vto.scango.app/textures/watch_1.jpg',
          size: Vector3(0.5, 0.5, 0.5),
          color: '#C0C0C0',
          material: 'metal',
          isAvailable: true,
          createdAt: DateTime.now(),
        ),
      ]);
    } catch (e) {
      LoggingService.error('Failed to load available items: $e');
    }
  }

  static Future<void> _loadSessionHistory() async {
    try {
      // Load session history from cache
      final cachedData = await CacheService.getCachedData(_cacheKey);
      if (cachedData != null) {
        final historyData = json.decode(cachedData);
        _sessionHistory.clear();
        _sessionHistory.addAll(
          (historyData as List).map((item) => TryOnSession.fromJson(item)),
        );
      }
    } catch (e) {
      LoggingService.error('Failed to load session history: $e');
    }
  }

  static Future<void> _saveSession(TryOnSession session) async {
    try {
      // Save session to cache
      final data = json.encode(_sessionHistory.map((s) => s.toJson()).toList());
      await CacheService.cacheData(_cacheKey, data, ttlHours: 24);
    } catch (e) {
      LoggingService.error('Failed to save session: $e');
    }
  }

  static String _generateSessionId() {
    return 'vto_session_${DateTime.now().millisecondsSinceEpoch}';
  }

  static String _generateSnapshotId() {
    return 'vto_snapshot_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Getters
  static bool get isInitialized => _isInitialized;
  static bool get isCameraActive => _isCameraActive;
  static TryOnSession? get currentSession => _currentSession;
  static List<VirtualItem> get availableItems => List.from(_availableItems);
  static List<TryOnSession> get sessionHistory => List.from(_sessionHistory);
  static Stream<VTOEvent> get events => _eventController?.stream ?? Stream.empty();
}

// Data models
class VirtualItem {
  final String id;
  final String productId;
  final ItemType type;
  final String name;
  final String model3DUrl;
  final String textureUrl;
  final Vector3 size;
  String color;
  final String material;
  final bool isAvailable;
  final DateTime createdAt;

  VirtualItem({
    required this.id,
    required this.productId,
    required this.type,
    required this.name,
    required this.model3DUrl,
    required this.textureUrl,
    required this.size,
    required this.color,
    required this.material,
    required this.isAvailable,
    required this.createdAt,
  });
}

class TryOnSession {
  final String id;
  final String productId;
  final String productName;
  final ItemType itemType;
  final Map<String, dynamic> itemMetadata;
  VirtualItem virtualItem;
  final DateTime startedAt;
  DateTime? endedAt;
  bool isActive;
  String? arSessionId;
  final List<TryOnSnapshot> snapshots;
  final Map<String, dynamic> measurements;

  TryOnSession({
    required this.id,
    required this.productId,
    required this.productName,
    required this.itemType,
    required this.itemMetadata,
    required this.virtualItem,
    required this.startedAt,
    this.endedAt,
    required this.isActive,
    this.arSessionId,
    required this.snapshots,
    required this.measurements,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'item_type': itemType.name,
      'item_metadata': itemMetadata,
      'virtual_item': {
        'id': virtualItem.id,
        'name': virtualItem.name,
        'color': virtualItem.color,
      },
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'is_active': isActive,
      'ar_session_id': arSessionId,
      'snapshots': snapshots.map((s) => s.toJson()).toList(),
      'measurements': measurements,
    };
  }

  factory TryOnSession.fromJson(Map<String, dynamic> json) {
    final virtualItemData = json['virtual_item'];
    return TryOnSession(
      id: json['id'],
      productId: json['product_id'],
      productName: json['product_name'],
      itemType: ItemType.values.firstWhere(
        (t) => t.name == json['item_type'],
        orElse: () => ItemType.clothing,
      ),
      itemMetadata: Map<String, dynamic>.from(json['item_metadata']),
      virtualItem: VirtualItem(
        id: virtualItemData['id'],
        productId: json['product_id'],
        type: ItemType.values.firstWhere(
          (t) => t.name == json['item_type'],
          orElse: () => ItemType.clothing,
        ),
        name: virtualItemData['name'],
        model3DUrl: '',
        textureUrl: '',
        size: Vector3(1, 1, 1),
        color: virtualItemData['color'],
        material: 'default',
        isAvailable: true,
        createdAt: DateTime.now(),
      ),
      startedAt: DateTime.parse(json['started_at']),
      endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at']) : null,
      isActive: json['is_active'],
      arSessionId: json['ar_session_id'],
      snapshots: (json['snapshots'] as List)
          .map((s) => TryOnSnapshot.fromJson(s))
          .toList(),
      measurements: Map<String, dynamic>.from(json['measurements']),
    );
  }
}

class TryOnSnapshot {
  final String id;
  final String sessionId;
  final String pose;
  final String imageUrl;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  TryOnSnapshot({
    required this.id,
    required this.sessionId,
    required this.pose,
    required this.imageUrl,
    required this.metadata,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'pose': pose,
      'image_url': imageUrl,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory TryOnSnapshot.fromJson(Map<String, dynamic> json) {
    return TryOnSnapshot(
      id: json['id'],
      sessionId: json['session_id'],
      pose: json['pose'],
      imageUrl: json['image_url'],
      metadata: Map<String, dynamic>.from(json['metadata']),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class CameraFrame {
  final Uint8List data;
  final DateTime timestamp;
  final int width;
  final int height;

  CameraFrame({
    required this.data,
    required this.timestamp,
    required this.width,
    required this.height,
  });
}

class VTOAnalytics {
  final int totalSessions;
  final int totalSnapshots;
  final Duration averageSessionDuration;
  final Map<ItemType, int> itemTypeStats;
  final DateTime startDate;
  final DateTime endDate;

  VTOAnalytics({
    required this.totalSessions,
    required this.totalSnapshots,
    required this.averageSessionDuration,
    required this.itemTypeStats,
    required this.startDate,
    required this.endDate,
  });
}

class VTOEvent {
  final VTOEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  VTOEvent({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class CameraResult {
  final bool success;
  final String? cameraId;
  final String? error;

  CameraResult({
    required this.success,
    this.cameraId,
    this.error,
  });
}

class TryOnResult {
  final bool success;
  final TryOnSession? session;
  final String? error;

  TryOnResult({
    required this.success,
    this.session,
    this.error,
  });
}

class Vector3 {
  final double x;
  final double y;
  final double z;

  Vector3(this.x, this.y, this.z);

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'z': z,
    };
  }
}

enum ItemType {
  clothing,
  accessories,
  footwear,
  jewelry,
  eyewear,
}

enum AccessoryType {
  watch,
  necklace,
  bracelet,
  earrings,
  ring,
  hat,
  scarf,
  belt,
  bag,
}

enum VTOEventType {
  sessionStarted,
  sessionEnded,
  cameraFrame,
  snapshotCaptured,
  itemPositionUpdated,
  itemColorChanged,
  measurementsTaken,
  error,
}
