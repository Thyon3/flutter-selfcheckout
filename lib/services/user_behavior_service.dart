import 'dart:async';
import 'package:flutter/material.dart';
import 'package:selfcheckoutapp/services/analytics_service.dart';
import 'package:selfcheckoutapp/services/firebase_services.dart';

class UserBehaviorService {
  static final UserBehaviorService _instance = UserBehaviorService._internal();
  factory UserBehaviorService() => _instance;
  UserBehaviorService._internal();

  final AnalyticsService _analytics = AnalyticsService();
  final FirebaseServices _firebaseServices = FirebaseServices();
  
  // Session tracking
  DateTime? _sessionStart;
  String? _currentScreen;
  Timer? _sessionTimer;
  int _sessionDuration = 0;
  
  // User interaction tracking
  final List<String> _userActions = [];
  final Map<String, int> _featureUsage = {};
  
  // Shopping behavior
  final List<Map<String, dynamic>> _shoppingSessions = [];
  Map<String, dynamic>? _currentShoppingSession;
  
  Future<void> initialize() async {
    _sessionStart = DateTime.now();
    _startSessionTimer();
    await _analytics.trackAppOpen();
  }

  void _startSessionTimer() {
    _sessionTimer = Timer.periodic(Duration(seconds: 1), (_) {
      _sessionDuration++;
    });
  }

  // Screen tracking
  Future<void> trackScreenTransition(String screenName) async {
    if (_currentScreen != null) {
      await _trackScreenTime(_currentScreen!);
    }
    
    _currentScreen = screenName;
    await _analytics.trackScreen(screenName);
    _trackFeatureUsage('screen_view', screenName);
  }

  Future<void> _trackScreenTime(String screenName) async {
    // Track how long user spent on each screen
    await _analytics.trackEvent('screen_time', parameters: {
      'screen_name': screenName,
      'duration_seconds': _sessionDuration,
    });
  }

  // Feature usage tracking
  void trackFeatureUsage(String feature, String? detail) {
    final key = detail != null ? '$feature:$detail' : feature;
    _featureUsage[key] = (_featureUsage[key] ?? 0) + 1;
    
    _userActions.add('Used $feature${detail != null ? ' ($detail)' : ''}');
    
    // Keep only last 100 actions
    if (_userActions.length > 100) {
      _userActions.removeAt(0);
    }
  }

  // Shopping behavior tracking
  Future<void> startShoppingSession() async {
    _currentShoppingSession = {
      'start_time': DateTime.now().toIso8601String(),
      'actions': <Map<String, dynamic>>[],
      'items_scanned': 0,
      'items_added': 0,
      'items_removed': 0,
    };
    
    await _analytics.trackEvent('shopping_session_start');
  }

  Future<void> trackBarcodeScan(String barcode, {bool success = true}) async {
    if (_currentShoppingSession != null) {
      _currentShoppingSession!['actions'].add({
        'type': 'barcode_scan',
        'barcode': barcode,
        'success': success,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      if (success) {
        _currentShoppingSession!['items_scanned'] = 
            (_currentShoppingSession!['items_scanned'] ?? 0) + 1;
      }
    }
    
    await _analytics.trackBarcodeScan(barcode: barcode, success: success);
    _trackFeatureUsage('barcode_scan', success ? 'success' : 'failed');
  }

  Future<void> trackCartItemAction(String action, Map<String, dynamic> item) async {
    if (_currentShoppingSession != null) {
      _currentShoppingSession!['actions'].add({
        'type': 'cart_action',
        'action': action,
        'item': item,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      switch (action) {
        case 'add':
          _currentShoppingSession!['items_added'] = 
              (_currentShoppingSession!['items_added'] ?? 0) + 1;
          break;
        case 'remove':
          _currentShoppingSession!['items_removed'] = 
              (_currentShoppingSession!['items_removed'] ?? 0) + 1;
          break;
      }
    }
    
    _trackFeatureUsage('cart_action', action);
  }

  Future<void> endShoppingSession({bool completed = false}) async {
    if (_currentShoppingSession != null) {
      _currentShoppingSession!['end_time'] = DateTime.now().toIso8601String();
      _currentShoppingSession!['completed'] = completed;
      _currentShoppingSession!['duration_seconds'] = _sessionDuration;
      
      _shoppingSessions.add(_currentShoppingSession!);
      
      // Track session analytics
      await _analytics.trackEvent('shopping_session_end', parameters: {
        'completed': completed,
        'duration_seconds': _sessionDuration,
        'items_scanned': _currentShoppingSession!['items_scanned'],
        'items_added': _currentShoppingSession!['items_added'],
        'items_removed': _currentShoppingSession!['items_removed'],
      });
      
      _currentShoppingSession = null;
    }
  }

  // Shopping list behavior
  Future<void> trackShoppingListAction(String action, {String? itemName}) async {
    await _analytics.trackShoppingListAction(
      action: action,
      itemName: itemName ?? '',
    );
    
    _trackFeatureUsage('shopping_list', action);
  }

  // Payment behavior
  Future<void> trackPaymentAttempt(String method, {bool success = false}) async {
    await _analytics.trackEvent('payment_attempt', parameters: {
      'method': method,
      'success': success,
    });
    
    _trackFeatureUsage('payment', success ? 'success' : 'failed');
  }

  // User engagement metrics
  Future<void> trackUserEngagement() async {
    final engagementScore = _calculateEngagementScore();
    
    await _analytics.trackEvent('user_engagement', parameters: {
      'engagement_score': engagementScore,
      'session_duration': _sessionDuration,
      'actions_count': _userActions.length,
      'features_used': _featureUsage.length,
    });
  }

  double _calculateEngagementScore() {
    // Simple engagement score calculation
    double score = 0.0;
    
    // Time spent (max 40 points)
    score += (_sessionDuration / 60.0).clamp(0.0, 40.0);
    
    // Actions performed (max 30 points)
    score += (_userActions.length * 2.0).clamp(0.0, 30.0);
    
    // Features used (max 30 points)
    score += (_featureUsage.length * 3.0).clamp(0.0, 30.0);
    
    return score;
  }

  // Get behavior insights
  Map<String, dynamic> getUserBehaviorSummary() {
    return {
      'session_duration': _sessionDuration,
      'current_screen': _currentScreen,
      'total_actions': _userActions.length,
      'features_used': _featureUsage,
      'recent_actions': _userActions.take(10).toList(),
      'shopping_sessions_count': _shoppingSessions.length,
      'engagement_score': _calculateEngagementScore(),
    };
  }

  Map<String, dynamic> getShoppingBehaviorSummary() {
    if (_shoppingSessions.isEmpty) {
      return {
        'total_sessions': 0,
        'completed_sessions': 0,
        'average_duration': 0,
        'total_items_scanned': 0,
        'completion_rate': 0.0,
      };
    }
    
    final completedSessions = _shoppingSessions
        .where((session) => session['completed'] == true)
        .toList();
    
    final totalDuration = _shoppingSessions
        .map((session) => session['duration_seconds'] as int)
        .reduce((a, b) => a + b);
    
    final totalItemsScanned = _shoppingSessions
        .map((session) => session['items_scanned'] as int)
        .reduce((a, b) => a + b);
    
    return {
      'total_sessions': _shoppingSessions.length,
      'completed_sessions': completedSessions.length,
      'average_duration': totalDuration ~/ _shoppingSessions.length,
      'total_items_scanned': totalItemsScanned,
      'completion_rate': completedSessions.length / _shoppingSessions.length,
    };
  }

  void dispose() {
    _sessionTimer?.cancel();
    _userActions.clear();
    _featureUsage.clear();
    _shoppingSessions.clear();
    _currentShoppingSession = null;
  }
}
