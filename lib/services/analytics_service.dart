import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static FirebaseAnalytics? _analytics;
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _analytics = FirebaseAnalytics.instance;
      await _analytics.setAnalyticsCollectionEnabled(true);
      _isInitialized = true;
      
      // Set default user properties
      await _analytics.setUserProperty('app_version', '1.0.0');
      await _analytics.setUserProperty('platform', kIsWeb ? 'web' : 'mobile');
    } catch (e) {
      debugPrint('Analytics initialization failed: $e');
    }
  }

  static Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (!_isInitialized || _analytics == null) return;
    
    await _analytics.logScreenView(
      screenName: screenName,
      screenClassOverride: screenClass,
    );
  }

  static Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized || _analytics == null) return;
    
    await _analytics.logEvent(
      name: name,
      parameters: parameters,
    );
  }

  static Future<void> logLogin({
    required String method,
    bool success = true,
    String? errorMessage,
  }) async {
    if (!_isInitialized || _analytics == null) return;
    
    final params = <String, dynamic>{
      'method': method,
      'success': success,
      if (errorMessage != null) 'error_message': errorMessage,
    };
    
    await logEvent(
      name: 'login',
      parameters: params,
    );
  }

  static Future<void> logSignUp({
    required String method,
    bool success = true,
    String? errorMessage,
  }) async {
    if (!_isInitialized || _analytics == null) return;
    
    final params = <String, dynamic>{
      'method': method,
      'success': success,
      if (errorMessage != null) 'error_message': errorMessage,
    };
    
    await logEvent(
      name: 'sign_up',
      parameters: params,
    );
  }

  static Future<void> logPurchase({
    required double amount,
    required String currency,
    required int itemCount,
    String? paymentMethod,
  }) async {
    if (!_isInitialized || _analytics == null) return;
    
    final params = <String, dynamic>{
      'amount': amount,
      'currency': currency,
      'item_count': itemCount,
      'payment_method': paymentMethod ?? 'unknown',
    };
    
    await logEvent(
      name: 'purchase_completed',
      parameters: params,
    );
  }

  static Future<void> logBarcodeScan({
    required String barcode,
    bool productFound = true,
    String? productName,
  }) async {
    if (!_isInitialized || _analytics == null) return;
    
    final params = <String, dynamic>{
      'barcode': barcode,
      'product_found': productFound,
      'product_name': productName,
    };
    
    await logEvent(
      name: 'barcode_scan',
      parameters: params,
    );
  }

  // Shopping list events
  Future<void> trackShoppingListAction({
    required String action,
    required String itemName,
  }) async {
    await trackEvent('shopping_list_action', parameters: {
      'action': action, // 'add', 'remove', 'edit'
      'item_name': itemName,
    });
  }

  // Error tracking
  Future<void> trackError(String error, {String? context}) async {
    await trackEvent('app_error', parameters: {
      'error_message': error,
      'context': context,
    });
  }

  // Performance tracking
  Future<void> trackPerformance({
    required String operation,
    required int durationMs,
  }) async {
    await trackEvent('performance_metric', parameters: {
      'operation': operation,
      'duration_ms': durationMs,
    });
  }

  // App lifecycle events
  Future<void> trackAppOpen() async {
    await _analytics?.logAppOpen();
  }

  Future<void> trackAppBackground() async {
    await trackEvent('app_background');
  }

  Future<void> trackAppForeground() async {
    await trackEvent('app_foreground');
  }
}
