import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:flutter/material.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  FirebaseAnalytics? _analytics;
  static FirebaseAnalyticsObserver? _observer;

  Future<void> initialize() async {
    _analytics = FirebaseAnalytics.instance;
    _observer = FirebaseAnalyticsObserver(analytics: _analytics!);
    
    // Enable analytics collection
    await _analytics!.setAnalyticsCollectionEnabled(true);
  }

  FirebaseAnalyticsObserver? get observer => _observer;

  // Screen tracking
  Future<void> trackScreen(String screenName, {String? screenClassOverride}) async {
    await _analytics?.setCurrentScreen(
      screenName: screenName,
      screenClassOverride: screenClassOverride,
    );
  }

  // Event tracking
  Future<void> trackEvent(String name, {Map<String, Object>? parameters}) async {
    await _analytics?.logEvent(
      name: name,
      parameters: parameters,
    );
  }

  // User properties
  Future<void> setUserProperty(String name, {String? value}) async {
    await _analytics?.setUserProperty(name: name, value: value);
  }

  // User ID tracking
  Future<void> setUserId(String userId) async {
    await _analytics?.setUserId(userId);
  }

  // E-commerce events
  Future<void> trackAddToCart({
    required String itemId,
    required String itemName,
    required double price,
    required String category,
  }) async {
    await trackEvent('add_to_cart', parameters: {
      'item_id': itemId,
      'item_name': itemName,
      'price': price,
      'category': category,
    });
  }

  Future<void> trackRemoveFromCart({
    required String itemId,
    required String itemName,
    required double price,
  }) async {
    await trackEvent('remove_from_cart', parameters: {
      'item_id': itemId,
      'item_name': itemName,
      'price': price,
    });
  }

  Future<void> trackBeginCheckout({
    required double totalAmount,
    required int itemCount,
  }) async {
    await trackEvent('begin_checkout', parameters: {
      'value': totalAmount,
      'currency': 'LKR',
      'item_count': itemCount,
    });
  }

  Future<void> trackPurchaseComplete({
    required String transactionId,
    required double totalAmount,
    required int itemCount,
  }) async {
    await trackEvent('purchase', parameters: {
      'transaction_id': transactionId,
      'value': totalAmount,
      'currency': 'LKR',
      'item_count': itemCount,
    });
  }

  // User engagement events
  Future<void> trackLogin({String? method}) async {
    await _analytics?.logLogin(loginMethod: method ?? 'email');
  }

  Future<void> trackSignUp({String? method}) async {
    await _analytics?.logSignUp(signUpMethod: method ?? 'email');
  }

  Future<void> trackSearch(String searchTerm) async {
    await _analytics?.logSearch(searchTerm: searchTerm);
  }

  // Barcode scanning events
  Future<void> trackBarcodeScan({
    required String barcode,
    bool success = true,
    String? error,
  }) async {
    await trackEvent('barcode_scan', parameters: {
      'barcode': barcode,
      'success': success,
      'error': error,
    });
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
