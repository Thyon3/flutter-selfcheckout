import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:selfcheckoutapp/services/logging_service.dart';
import 'package:selfcheckoutapp/services/cache_service.dart';
import 'package:selfcheckoutapp/services/security_service.dart';

class SocialSharingService {
  static const String _apiKey = 'social_sharing_api_key_12345';
  static const String _baseUrl = 'https://api.social.scango.app';
  static const String _cacheKey = 'social_sharing_cache';
  
  static bool _isInitialized = false;
  static final Map<String, SocialPlatform> _connectedPlatforms = {};
  static final List<SharedContent> _sharedHistory = [];

  // Social sharing service initialization
  static Future<bool> initialize() async {
    try {
      if (_isInitialized) return true;
      
      LoggingService.info('Initializing social sharing service');
      
      // Load connected platforms
      await _loadConnectedPlatforms();
      
      // Load sharing history
      await _loadSharingHistory();
      
      _isInitialized = true;
      
      LoggingService.info('Social sharing service initialized successfully');
      return true;
    } catch (e) {
      LoggingService.error('Failed to initialize social sharing service: $e');
      return false;
    }
  }

  // Platform management
  static Future<bool> connectPlatform({
    required SocialPlatform platform,
    required String accessToken,
    String? refreshToken,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      // Validate access token
      final isValid = await _validateAccessToken(platform, accessToken);
      if (!isValid) {
        LoggingService.error('Invalid access token for platform: ${platform.name}');
        return false;
      }

      // Store platform credentials
      final credentials = SocialCredentials(
        platform: platform,
        accessToken: accessToken,
        refreshToken: refreshToken,
        additionalData: additionalData ?? {},
        connectedAt: DateTime.now(),
        isActive: true,
      );

      _connectedPlatforms[platform.name] = platform;
      
      // Securely store credentials
      await _storePlatformCredentials(platform, credentials);
      
      LoggingService.info('Connected to social platform: ${platform.name}');
      return true;
    } catch (e) {
      LoggingService.error('Failed to connect to platform: $e');
      return false;
    }
  }

  static Future<void> disconnectPlatform(SocialPlatform platform) async {
    try {
      _connectedPlatforms.remove(platform.name);
      
      // Remove stored credentials
      await _removePlatformCredentials(platform);
      
      LoggingService.info('Disconnected from social platform: ${platform.name}');
    } catch (e) {
      LoggingService.error('Failed to disconnect from platform: $e');
    }
  }

  // Content sharing
  static Future<ShareResult> shareContent({
    required ShareableContent content,
    required List<SocialPlatform> platforms,
    String? customMessage,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final results = <SocialPlatform, SocialShareResult>{};
      
      for (final platform in platforms) {
        if (!_connectedPlatforms.containsKey(platform.name)) {
          results[platform] = SocialShareResult(
            success: false,
            error: 'Platform not connected',
          );
          continue;
        }

        final result = await _shareToPlatform(
          platform,
          content,
          customMessage,
          metadata,
        );
        
        results[platform] = result;
      }

      // Create share result
      final shareResult = ShareResult(
        content: content,
        platforms: platforms,
        results: results,
        sharedAt: DateTime.now(),
      );

      // Add to history
      await _addToSharingHistory(shareResult);
      
      final successCount = results.values.where((r) => r.success).length;
      LoggingService.info('Content shared to $successCount/${platforms.length} platforms');
      
      return shareResult;
    } catch (e) {
      LoggingService.error('Failed to share content: $e');
      return ShareResult(
        content: content,
        platforms: platforms,
        results: {},
        sharedAt: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  static Future<SocialShareResult> _shareToPlatform(
    SocialPlatform platform,
    ShareableContent content,
    String? customMessage,
    Map<String, dynamic>? metadata,
  ) async {
    try {
      switch (platform) {
        case SocialPlatform.facebook:
          return await _shareToFacebook(content, customMessage, metadata);
        case SocialPlatform.twitter:
          return await _shareToTwitter(content, customMessage, metadata);
        case SocialPlatform.instagram:
          return await _shareToInstagram(content, customMessage, metadata);
        case SocialPlatform.linkedin:
          return await _shareToLinkedIn(content, customMessage, metadata);
        case SocialPlatform.whatsapp:
          return await _shareToWhatsApp(content, customMessage, metadata);
        case SocialPlatform.telegram:
          return await _shareToTelegram(content, customMessage, metadata);
        default:
          return SocialShareResult(
            success: false,
            error: 'Unsupported platform',
          );
      }
    } catch (e) {
      LoggingService.error('Failed to share to ${platform.name}: $e');
      return SocialShareResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // Platform-specific sharing methods
  static Future<SocialShareResult> _shareToFacebook(
    ShareableContent content,
    String? customMessage,
    Map<String, dynamic>? metadata,
  ) async {
    try {
      final credentials = await _getPlatformCredentials(SocialPlatform.facebook);
      if (credentials == null) {
        return SocialShareResult(success: false, error: 'No credentials found');
      }

      final message = customMessage ?? content.description;
      
      // Mock Facebook API call
      await Future.delayed(Duration(milliseconds: 1500));
      
      final postId = 'fb_${DateTime.now().millisecondsSinceEpoch}';
      
      return SocialShareResult(
        success: true,
        postId: postId,
        url: 'https://facebook.com/post/$postId',
        engagement: SocialEngagement(
          likes: 0,
          shares: 0,
          comments: 0,
          views: 0,
        ),
      );
    } catch (e) {
      LoggingService.error('Failed to share to Facebook: $e');
      return SocialShareResult(success: false, error: e.toString());
    }
  }

  static Future<SocialShareResult> _shareToTwitter(
    ShareableContent content,
    String? customMessage,
    Map<String, dynamic>? metadata,
  ) async {
    try {
      final credentials = await _getPlatformCredentials(SocialPlatform.twitter);
      if (credentials == null) {
        return SocialShareResult(success: false, error: 'No credentials found');
      }

      final message = customMessage ?? content.description;
      
      // Mock Twitter API call
      await Future.delayed(Duration(milliseconds: 1200));
      
      final tweetId = 'tw_${DateTime.now().millisecondsSinceEpoch}';
      
      return SocialShareResult(
        success: true,
        postId: tweetId,
        url: 'https://twitter.com/status/$tweetId',
        engagement: SocialEngagement(
          likes: 0,
          shares: 0,
          comments: 0,
          views: 0,
        ),
      );
    } catch (e) {
      LoggingService.error('Failed to share to Twitter: $e');
      return SocialShareResult(success: false, error: e.toString());
    }
  }

  static Future<SocialShareResult> _shareToInstagram(
    ShareableContent content,
    String? customMessage,
    Map<String, dynamic>? metadata,
  ) async {
    try {
      final credentials = await _getPlatformCredentials(SocialPlatform.instagram);
      if (credentials == null) {
        return SocialShareResult(success: false, error: 'No credentials found');
      }

      // Instagram requires image/video content
      if (content.mediaUrl == null && content.imageUrl == null) {
        return SocialShareResult(
          success: false,
          error: 'Instagram requires media content',
        );
      }
      
      // Mock Instagram API call
      await Future.delayed(Duration(milliseconds: 2000));
      
      final postId = 'ig_${DateTime.now().millisecondsSinceEpoch}';
      
      return SocialShareResult(
        success: true,
        postId: postId,
        url: 'https://instagram.com/p/$postId',
        engagement: SocialEngagement(
          likes: 0,
          shares: 0,
          comments: 0,
          views: 0,
        ),
      );
    } catch (e) {
      LoggingService.error('Failed to share to Instagram: $e');
      return SocialShareResult(success: false, error: e.toString());
    }
  }

  static Future<SocialShareResult> _shareToLinkedIn(
    ShareableContent content,
    String? customMessage,
    Map<String, dynamic>? metadata,
  ) async {
    try {
      final credentials = await _getPlatformCredentials(SocialPlatform.linkedin);
      if (credentials == null) {
        return SocialShareResult(success: false, error: 'No credentials found');
      }

      final message = customMessage ?? content.description;
      
      // Mock LinkedIn API call
      await Future.delayed(Duration(milliseconds: 1300));
      
      final postId = 'li_${DateTime.now().millisecondsSinceEpoch}';
      
      return SocialShareResult(
        success: true,
        postId: postId,
        url: 'https://linkedin.com/posts/$postId',
        engagement: SocialEngagement(
          likes: 0,
          shares: 0,
          comments: 0,
          views: 0,
        ),
      );
    } catch (e) {
      LoggingService.error('Failed to share to LinkedIn: $e');
      return SocialShareResult(success: false, error: e.toString());
    }
  }

  static Future<SocialShareResult> _shareToWhatsApp(
    ShareableContent content,
    String? customMessage,
    Map<String, dynamic>? metadata,
  ) async {
    try {
      final message = customMessage ?? content.description;
      final url = content.url ?? '';
      
      final whatsappUrl = 'https://wa.me/?text=${Uri.encodeComponent('$message $url')}';
      
      final launched = await launchUrl(Uri.parse(whatsappUrl));
      
      if (launched) {
        return SocialShareResult(
          success: true,
          postId: 'wa_${DateTime.now().millisecondsSinceEpoch}',
        );
      } else {
        return SocialShareResult(
          success: false,
          error: 'Failed to launch WhatsApp',
        );
      }
    } catch (e) {
      LoggingService.error('Failed to share to WhatsApp: $e');
      return SocialShareResult(success: false, error: e.toString());
    }
  }

  static Future<SocialShareResult> _shareToTelegram(
    ShareableContent content,
    String? customMessage,
    Map<String, dynamic>? metadata,
  ) async {
    try {
      final message = customMessage ?? content.description;
      final url = content.url ?? '';
      
      final telegramUrl = 'https://t.me/share/url?text=${Uri.encodeComponent(message)}&url=${Uri.encodeComponent(url)}';
      
      final launched = await launchUrl(Uri.parse(telegramUrl));
      
      if (launched) {
        return SocialShareResult(
          success: true,
          postId: 'tg_${DateTime.now().millisecondsSinceEpoch}',
        );
      } else {
        return SocialShareResult(
          success: false,
          error: 'Failed to launch Telegram',
        );
      }
    } catch (e) {
      LoggingService.error('Failed to share to Telegram: $e');
      return SocialShareResult(success: false, error: e.toString());
    }
  }

  // Native sharing
  static Future<void> shareNative({
    required String text,
    String? subject,
    List<String>? filePaths,
  }) async {
    try {
      await Share.share(
        text,
        subject: subject,
        sharePositionOrigin: Rect.zero,
      );
      
      LoggingService.info('Content shared via native share dialog');
    } catch (e) {
      LoggingService.error('Failed to share natively: $e');
    }
  }

  // Shopping-specific sharing
  static Future<ShareResult> shareProduct({
    required String productId,
    required String productName,
    required double price,
    String? imageUrl,
    String? description,
    List<SocialPlatform>? platforms,
  }) async {
    try {
      final content = ShareableContent(
        type: ContentType.product,
        title: productName,
        description: description ?? 'Check out this amazing product: $productName for Rs $price',
        url: 'https://scango.app/product/$productId',
        imageUrl: imageUrl,
        metadata: {
          'product_id': productId,
          'price': price,
          'type': 'product',
        },
      );

      final targetPlatforms = platforms ?? [SocialPlatform.facebook, SocialPlatform.whatsapp];
      
      return await shareContent(
        content: content,
        platforms: targetPlatforms,
        customMessage: '🛍️ $productName - Only Rs $price! 🛍️',
      );
    } catch (e) {
      LoggingService.error('Failed to share product: $e');
      rethrow;
    }
  }

  static Future<ShareResult> shareShoppingList({
    required List<Map<String, dynamic>> items,
    String? listName,
    List<SocialPlatform>? platforms,
  }) async {
    try {
      final listTitle = listName ?? 'My Shopping List';
      final itemsText = items.map((item) => '• ${item['name']} (${item['quantity']})').join('\n');
      
      final content = ShareableContent(
        type: ContentType.shoppingList,
        title: listTitle,
        description: 'My shopping list:\n$itemsText',
        url: 'https://scango.app/lists/shared/${DateTime.now().millisecondsSinceEpoch}',
        metadata: {
          'items': items,
          'list_name': listTitle,
          'type': 'shopping_list',
        },
      );

      final targetPlatforms = platforms ?? [SocialPlatform.whatsapp, SocialPlatform.telegram];
      
      return await shareContent(
        content: content,
        platforms: targetPlatforms,
        customMessage: '📝 $listTitle\n$itemsText',
      );
    } catch (e) {
      LoggingService.error('Failed to share shopping list: $e');
      rethrow;
    }
  }

  static Future<ShareResult> shareAchievement({
    required String achievementType,
    required String achievementTitle,
    required String achievementDescription,
    String? imageUrl,
    List<SocialPlatform>? platforms,
  }) async {
    try {
      final content = ShareableContent(
        type: ContentType.achievement,
        title: achievementTitle,
        description: achievementDescription,
        url: 'https://scango.app/achievements/shared/${DateTime.now().millisecondsSinceEpoch}',
        imageUrl: imageUrl,
        metadata: {
          'achievement_type': achievementType,
          'title': achievementTitle,
          'type': 'achievement',
        },
      );

      final targetPlatforms = platforms ?? [SocialPlatform.facebook, SocialPlatform.twitter];
      
      return await shareContent(
        content: content,
        platforms: targetPlatforms,
        customMessage: '🏆 $achievementTitle! 🏆\n$achievementDescription',
      );
    } catch (e) {
      LoggingService.error('Failed to share achievement: $e');
      rethrow;
    }
  }

  // Analytics and insights
  static Future<SocialAnalytics> getAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var history = List<SharedContent>.from(_sharedHistory);
      
      if (startDate != null) {
        history = history.where((content) => content.sharedAt.isAfter(startDate)).toList();
      }
      
      if (endDate != null) {
        history = history.where((content) => content.sharedAt.isBefore(endDate)).toList();
      }

      final platformStats = <SocialPlatform, PlatformStats>{};
      final contentTypeStats = <ContentType, int>{};
      
      int totalShares = 0;
      int totalEngagement = 0;

      for (final sharedContent in history) {
        totalShares++;
        
        // Platform stats
        for (final platform in sharedContent.platforms) {
          final result = sharedContent.results[platform];
          if (result != null && result.success) {
            platformStats[platform] = (platformStats[platform] ?? PlatformStats(
              platform: platform,
              shares: 0,
              engagement: 0,
            ))..shares++;
            
            if (result.engagement != null) {
              totalEngagement += result.engagement!.total;
              platformStats[platform]!.engagement += result.engagement!.total;
            }
          }
        }
        
        // Content type stats
        contentTypeStats[sharedContent.content.type] = 
            (contentTypeStats[sharedContent.content.type] ?? 0) + 1;
      }

      return SocialAnalytics(
        totalShares: totalShares,
        totalEngagement: totalEngagement,
        platformStats: platformStats.values.toList(),
        contentTypeStats: contentTypeStats,
        startDate: startDate ?? DateTime.now().subtract(Duration(days: 30)),
        endDate: endDate ?? DateTime.now(),
      );
    } catch (e) {
      LoggingService.error('Failed to get social analytics: $e');
      return SocialAnalytics(
        totalShares: 0,
        totalEngagement: 0,
        platformStats: [],
        contentTypeStats: {},
        startDate: DateTime.now(),
        endDate: DateTime.now(),
      );
    }
  }

  // Utility methods
  static Future<bool> _validateAccessToken(SocialPlatform platform, String token) async {
    try {
      // Mock token validation
      await Future.delayed(Duration(milliseconds: 500));
      return token.isNotEmpty && token.length > 10;
    } catch (e) {
      LoggingService.error('Failed to validate access token: $e');
      return false;
    }
  }

  static Future<void> _storePlatformCredentials(
    SocialPlatform platform,
    SocialCredentials credentials,
  ) async {
    try {
      final key = 'social_${platform.name}_credentials';
      final data = json.encode(credentials.toJson());
      await SecurityService.secureStore(key, data);
    } catch (e) {
      LoggingService.error('Failed to store platform credentials: $e');
    }
  }

  static Future<void> _removePlatformCredentials(SocialPlatform platform) async {
    try {
      final key = 'social_${platform.name}_credentials';
      await SecurityService.secureDelete(key);
    } catch (e) {
      LoggingService.error('Failed to remove platform credentials: $e');
    }
  }

  static Future<SocialCredentials?> _getPlatformCredentials(SocialPlatform platform) async {
    try {
      final key = 'social_${platform.name}_credentials';
      final data = await SecurityService.secureRetrieve(key);
      
      if (data != null) {
        final credentialsData = json.decode(data);
        return SocialCredentials.fromJson(credentialsData);
      }
      
      return null;
    } catch (e) {
      LoggingService.error('Failed to get platform credentials: $e');
      return null;
    }
  }

  static Future<void> _loadConnectedPlatforms() async {
    try {
      // Load connected platforms from cache or secure storage
      for (final platform in SocialPlatform.values) {
        final credentials = await _getPlatformCredentials(platform);
        if (credentials != null && credentials.isActive) {
          _connectedPlatforms[platform.name] = platform;
        }
      }
    } catch (e) {
      LoggingService.error('Failed to load connected platforms: $e');
    }
  }

  static Future<void> _addToSharingHistory(ShareResult result) async {
    try {
      final sharedContent = SharedContent(
        content: result.content,
        platforms: result.platforms,
        results: result.results,
        sharedAt: result.sharedAt,
        error: result.error,
      );
      
      _sharedHistory.add(sharedContent);
      
      // Keep only last 1000 shared items
      if (_sharedHistory.length > 1000) {
        _sharedHistory.removeAt(0);
      }
      
      // Save to cache
      final data = json.encode(_sharedHistory.map((c) => c.toJson()).toList());
      await CacheService.cacheData(_cacheKey, data, ttlHours: 24);
    } catch (e) {
      LoggingService.error('Failed to add to sharing history: $e');
    }
  }

  static Future<void> _loadSharingHistory() async {
    try {
      final cachedData = await CacheService.getCachedData(_cacheKey);
      if (cachedData != null) {
        final historyData = json.decode(cachedData);
        _sharedHistory.clear();
        _sharedHistory.addAll(
          (historyData as List).map((item) => SharedContent.fromJson(item)),
        );
      }
    } catch (e) {
      LoggingService.error('Failed to load sharing history: $e');
    }
  }

  // Getters
  static bool get isInitialized => _isInitialized;
  static List<SocialPlatform> get connectedPlatforms => _connectedPlatforms.values.toList();
  static List<SharedContent> get sharingHistory => List.from(_sharedHistory);
}

// Data models
class ShareableContent {
  final ContentType type;
  final String title;
  final String description;
  final String? url;
  final String? imageUrl;
  final String? mediaUrl;
  final Map<String, dynamic> metadata;

  ShareableContent({
    required this.type,
    required this.title,
    required this.description,
    this.url,
    this.imageUrl,
    this.mediaUrl,
    required this.metadata,
  });
}

class ShareResult {
  final ShareableContent content;
  final List<SocialPlatform> platforms;
  final Map<SocialPlatform, SocialShareResult> results;
  final DateTime sharedAt;
  final String? error;

  ShareResult({
    required this.content,
    required this.platforms,
    required this.results,
    required this.sharedAt,
    this.error,
  });
}

class SocialShareResult {
  final bool success;
  final String? postId;
  final String? url;
  final SocialEngagement? engagement;
  final String? error;

  SocialShareResult({
    required this.success,
    this.postId,
    this.url,
    this.engagement,
    this.error,
  });
}

class SocialEngagement {
  final int likes;
  final int shares;
  final int comments;
  final int views;

  SocialEngagement({
    required this.likes,
    required this.shares,
    required this.comments,
    required this.views,
  });

  int get total => likes + shares + comments + views;
}

class SocialCredentials {
  final SocialPlatform platform;
  final String accessToken;
  final String? refreshToken;
  final Map<String, dynamic> additionalData;
  final DateTime connectedAt;
  final DateTime? lastUsed;
  bool isActive;

  SocialCredentials({
    required this.platform,
    required this.accessToken,
    this.refreshToken,
    required this.additionalData,
    required this.connectedAt,
    this.lastUsed,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'platform': platform.name,
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'additional_data': additionalData,
      'connected_at': connectedAt.toIso8601String(),
      'last_used': lastUsed?.toIso8601String(),
      'is_active': isActive,
    };
  }

  factory SocialCredentials.fromJson(Map<String, dynamic> json) {
    return SocialCredentials(
      platform: SocialPlatform.values.firstWhere(
        (p) => p.name == json['platform'],
        orElse: () => SocialPlatform.facebook,
      ),
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      additionalData: Map<String, dynamic>.from(json['additional_data'] ?? {}),
      connectedAt: DateTime.parse(json['connected_at']),
      lastUsed: json['last_used'] != null ? DateTime.parse(json['last_used']) : null,
      isActive: json['is_active'],
    );
  }
}

class SharedContent {
  final ShareableContent content;
  final List<SocialPlatform> platforms;
  final Map<SocialPlatform, SocialShareResult> results;
  final DateTime sharedAt;
  final String? error;

  SharedContent({
    required this.content,
    required this.platforms,
    required this.results,
    required this.sharedAt,
    this.error,
  });

  Map<String, dynamic> toJson() {
    return {
      'content': {
        'type': content.type.name,
        'title': content.title,
        'description': content.description,
        'url': content.url,
        'image_url': content.imageUrl,
        'media_url': content.mediaUrl,
        'metadata': content.metadata,
      },
      'platforms': platforms.map((p) => p.name).toList(),
      'results': results.map((key, value) => MapEntry(
        key.name,
        {
          'success': value.success,
          'post_id': value.postId,
          'url': value.url,
          'engagement': value.engagement != null ? {
            'likes': value.engagement!.likes,
            'shares': value.engagement!.shares,
            'comments': value.engagement!.comments,
            'views': value.engagement!.views,
          } : null,
          'error': value.error,
        },
      )),
      'shared_at': sharedAt.toIso8601String(),
      'error': error,
    };
  }

  factory SharedContent.fromJson(Map<String, dynamic> json) {
    final contentData = json['content'];
    final content = ShareableContent(
      type: ContentType.values.firstWhere(
        (t) => t.name == contentData['type'],
        orElse: () => ContentType.general,
      ),
      title: contentData['title'],
      description: contentData['description'],
      url: contentData['url'],
      imageUrl: contentData['image_url'],
      mediaUrl: contentData['media_url'],
      metadata: Map<String, dynamic>.from(contentData['metadata'] ?? {}),
    );

    final platforms = (json['platforms'] as List)
        .map((p) => SocialPlatform.values.firstWhere(
          (sp) => sp.name == p,
          orElse: () => SocialPlatform.facebook,
        ))
        .toList();

    final resultsData = json['results'] as Map<String, dynamic>;
    final results = <SocialPlatform, SocialShareResult>{};
    
    for (final entry in resultsData.entries) {
      final platform = SocialPlatform.values.firstWhere(
        (p) => p.name == entry.key,
        orElse: () => SocialPlatform.facebook,
      );
      final resultData = entry.value;
      
      final engagement = resultData['engagement'] != null
          ? SocialEngagement(
              likes: resultData['engagement']['likes'],
              shares: resultData['engagement']['shares'],
              comments: resultData['engagement']['comments'],
              views: resultData['engagement']['views'],
            )
          : null;
      
      results[platform] = SocialShareResult(
        success: resultData['success'],
        postId: resultData['post_id'],
        url: resultData['url'],
        engagement: engagement,
        error: resultData['error'],
      );
    }

    return SharedContent(
      content: content,
      platforms: platforms,
      results: results,
      sharedAt: DateTime.parse(json['shared_at']),
      error: json['error'],
    );
  }
}

class SocialAnalytics {
  final int totalShares;
  final int totalEngagement;
  final List<PlatformStats> platformStats;
  final Map<ContentType, int> contentTypeStats;
  final DateTime startDate;
  final DateTime endDate;

  SocialAnalytics({
    required this.totalShares,
    required this.totalEngagement,
    required this.platformStats,
    required this.contentTypeStats,
    required this.startDate,
    required this.endDate,
  });
}

class PlatformStats {
  final SocialPlatform platform;
  final int shares;
  final int engagement;

  PlatformStats({
    required this.platform,
    required this.shares,
    required this.engagement,
  });
}

enum SocialPlatform {
  facebook,
  twitter,
  instagram,
  linkedin,
  whatsapp,
  telegram,
  pinterest,
  snapchat,
}

enum ContentType {
  product,
  shoppingList,
  achievement,
  promotion,
  review,
  general,
}
