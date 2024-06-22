import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:selfcheckoutapp/services/analytics_service.dart';

class MonitoringService {
  static final MonitoringService _instance = MonitoringService._internal();
  factory MonitoringService() => _instance;
  MonitoringService._internal();

  final AnalyticsService _analytics = AnalyticsService();
  final List<String> _errorLog = [];
  final Map<String, int> _errorCounts = {};
  
  // Performance metrics
  final Map<String, List<int>> _performanceMetrics = {};
  Timer? _performanceTimer;

  Future<void> initialize() async {
    // Set up error handlers
    if (kDebugMode) {
      FlutterError.onError = _handleFlutterError;
    }
    
    PlatformDispatcher.instance.onError = (error, stack) {
      _handlePlatformError(error, stack);
      return true;
    };

    // Set up periodic performance monitoring
    _startPerformanceMonitoring();
  }

  void _handleFlutterError(FlutterErrorDetails details) {
    final errorString = details.toString();
    _logError(errorString, context: 'Flutter Error');
    _analytics.trackError(errorString, context: 'Flutter Error');
  }

  void _handlePlatformError(Object error, StackTrace stack) {
    final errorString = error.toString();
    _logError(errorString, context: 'Platform Error');
    _analytics.trackError(errorString, context: 'Platform Error');
  }

  void _logError(String error, {String? context}) {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '[$timestamp] $error${context != null ? ' (Context: $context)' : ''}';
    
    _errorLog.add(logEntry);
    _errorCounts[error] = (_errorCounts[error] ?? 0) + 1;
    
    // Keep only last 100 errors
    if (_errorLog.length > 100) {
      _errorLog.removeAt(0);
    }
    
    // Log to console in debug mode
    if (kDebugMode) {
      print('MONITORING ERROR: $logEntry');
    }
  }

  void _startPerformanceMonitoring() {
    _performanceTimer = Timer.periodic(Duration(minutes: 5), (_) {
      _collectPerformanceMetrics();
    });
  }

  void _collectPerformanceMetrics() {
    // Memory usage
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _recordMetric('memory_usage', _getCurrentMemoryUsage());
    }
    
    // Frame rate (simplified)
    _recordMetric('frame_rate', _getCurrentFrameRate());
  }

  int _getCurrentMemoryUsage() {
    // Simplified memory usage calculation
    // In a real app, you'd use platform-specific APIs
    return Random().nextInt(100) + 50; // Mock value
  }

  int _getCurrentFrameRate() {
    // Simplified frame rate calculation
    return 60; // Mock value
  }

  void _recordMetric(String metricName, int value) {
    _performanceMetrics.putIfAbsent(metricName, () => []);
    _performanceMetrics[metricName]!.add(value);
    
    // Keep only last 12 readings (1 hour worth)
    if (_performanceMetrics[metricName]!.length > 12) {
      _performanceMetrics[metricName]!.removeAt(0);
    }
    
    // Track performance analytics
    _analytics.trackPerformance(
      operation: metricName,
      durationMs: value,
    );
  }

  // Manual error reporting
  void reportError(String error, {String? context, StackTrace? stackTrace}) {
    _logError(error, context: context);
    _analytics.trackError(error, context: context);
  }

  // Performance tracking for specific operations
  Future<T> trackOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await operation();
      stopwatch.stop();
      
      _analytics.trackPerformance(
        operation: operationName,
        durationMs: stopwatch.elapsedMilliseconds,
      );
      
      return result;
    } catch (error) {
      stopwatch.stop();
      
      reportError(
        error.toString(),
        context: operationName,
        stackTrace: StackTrace.current,
      );
      
      rethrow;
    }
  }

  // Get monitoring data
  List<String> getErrorLog() => List.unmodifiable(_errorLog);
  Map<String, int> getErrorCounts() => Map.unmodifiable(_errorCounts);
  Map<String, List<int>> getPerformanceMetrics() => Map.unmodifiable(_performanceMetrics);

  // Get error summary
  Map<String, dynamic> getErrorSummary() {
    return {
      'total_errors': _errorLog.length,
      'unique_errors': _errorCounts.length,
      'most_common_error': _errorCounts.isEmpty ? null : 
          _errorCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key,
      'error_counts': _errorCounts,
    };
  }

  // Get performance summary
  Map<String, dynamic> getPerformanceSummary() {
    final summary = <String, dynamic>{};
    
    for (final entry in _performanceMetrics.entries) {
      final values = entry.value;
      if (values.isNotEmpty) {
        summary[entry.key] = {
          'current': values.last,
          'average': values.reduce((a, b) => a + b) / values.length,
          'min': values.reduce((a, b) => a < b ? a : b),
          'max': values.reduce((a, b) => a > b ? a : b),
        };
      }
    }
    
    return summary;
  }

  void dispose() {
    _performanceTimer?.cancel();
    _errorLog.clear();
    _errorCounts.clear();
    _performanceMetrics.clear();
  }
}
