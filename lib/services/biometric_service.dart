import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:crypto/crypto.dart';
import 'package:selfcheckoutapp/services/logging_service.dart';
import 'package:selfcheckoutapp/services/security_service.dart';

class BiometricService {
  static const String _biometricStorageKey = 'biometric_data';
  static const String _biometricAttemptsKey = 'biometric_attempts';
  
  static final Map<String, BiometricData> _registeredBiometrics = {};
  static final Map<String, List<BiometricAttempt>> _attemptHistory = {};
  
  static bool _isInitialized = false;
  static bool _isDeviceSupported = false;
  static List<BiometricType> _availableTypes = [];

  // Biometric service initialization
  static Future<bool> initialize() async {
    try {
      if (_isInitialized) return true;
      
      LoggingService.info('Initializing biometric service');
      
      // Check device capabilities
      await _checkDeviceSupport();
      
      if (!_isDeviceSupported) {
        LoggingService.warning('Biometric authentication not supported on this device');
        return false;
      }
      
      // Load registered biometrics
      await _loadRegisteredBiometrics();
      
      _isInitialized = true;
      
      LoggingService.info('Biometric service initialized successfully');
      return true;
    } catch (e) {
      LoggingService.error('Failed to initialize biometric service: $e');
      return false;
    }
  }

  // Device support check
  static Future<void> _checkDeviceSupport() async {
    try {
      // Mock device support check
      if (Platform.isIOS || Platform.isAndroid) {
        _isDeviceSupported = true;
        _availableTypes = [
          BiometricType.fingerprint,
          BiometricType.face,
          BiometricType.voice,
        ];
      } else {
        _isDeviceSupported = false;
        _availableTypes = [];
      }
      
      LoggingService.info('Device biometric support: $_isDeviceSupported');
      LoggingService.info('Available biometric types: $_availableTypes');
    } catch (e) {
      LoggingService.error('Failed to check device support: $e');
      _isDeviceSupported = false;
    }
  }

  // Biometric registration
  static Future<String> registerBiometric({
    required BiometricType type,
    required String userId,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      if (!_availableTypes.contains(type)) {
        throw Exception('Biometric type $type not supported on this device');
      }
      
      // Capture biometric data
      final biometricData = await _captureBiometricData(type);
      
      if (biometricData == null) {
        throw Exception('Failed to capture biometric data');
      }
      
      // Create biometric template
      final template = await _createBiometricTemplate(biometricData, type);
      
      final biometricId = _generateBiometricId();
      
      final registeredBiometric = BiometricData(
        id: biometricId,
        type: type,
        userId: userId,
        template: template,
        description: description,
        metadata: metadata ?? {},
        createdAt: DateTime.now(),
        lastUsed: null,
        isActive: true,
      );
      
      _registeredBiometrics[biometricId] = registeredBiometric;
      
      // Save to secure storage
      await _saveBiometricData(registeredBiometric);
      
      LoggingService.info('Registered biometric: $biometricId for user: $userId');
      return biometricId;
    } catch (e) {
      LoggingService.error('Failed to register biometric: $e');
      rethrow;
    }
  }

  // Biometric authentication
  static Future<BiometricResult> authenticate({
    required String userId,
    BiometricType? preferredType,
    int maxAttempts = 3,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      // Get user's registered biometrics
      final userBiometrics = _registeredBiometrics.values
          .where((b) => b.userId == userId && b.isActive)
          .toList();
      
      if (userBiometrics.isEmpty) {
        return BiometricResult(
          success: false,
          error: 'No biometrics registered for user',
          attempts: 0,
          duration: Duration.zero,
        );
      }
      
      // Select biometric type
      BiometricType selectedType;
      if (preferredType != null && userBiometrics.any((b) => b.type == preferredType)) {
        selectedType = preferredType!;
      } else {
        selectedType = userBiometrics.first.type;
      }
      
      final startTime = DateTime.now();
      int attempts = 0;
      
      while (attempts < maxAttempts) {
        attempts++;
        
        // Check rate limiting
        if (!_canAttempt(userId)) {
          final waitTime = _getWaitTime(userId);
          return BiometricResult(
            success: false,
            error: 'Too many attempts. Please wait ${waitTime.inSeconds} seconds.',
            attempts: attempts,
            duration: DateTime.now().difference(startTime),
          );
        }
        
        // Capture biometric data for authentication
        final capturedData = await _captureBiometricData(selectedType);
        
        if (capturedData == null) {
          return BiometricResult(
            success: false,
            error: 'Failed to capture biometric data',
            attempts: attempts,
            duration: DateTime.now().difference(startTime),
          );
        }
        
        // Compare with registered templates
        final matchResult = await _compareBiometricData(
          capturedData,
          userBiometrics.where((b) => b.type == selectedType).toList(),
        );
        
        // Record attempt
        await _recordBiometricAttempt(userId, selectedType, matchResult.success);
        
        if (matchResult.success) {
          // Update last used timestamp
          for (final biometric in userBiometrics) {
            if (biometric.type == selectedType) {
              biometric.lastUsed = DateTime.now();
              await _saveBiometricData(biometric);
            }
          }
          
          return BiometricResult(
            success: true,
            biometricId: matchResult.biometricId,
            confidence: matchResult.confidence,
            attempts: attempts,
            duration: DateTime.now().difference(startTime),
          );
        } else {
          // Wait before next attempt
          await Future.delayed(Duration(milliseconds: 500));
        }
      }
      
      return BiometricResult(
        success: false,
        error: 'Authentication failed after $maxAttempts attempts',
        attempts: attempts,
        duration: DateTime.now().difference(startTime),
      );
    } catch (e) {
      LoggingService.error('Biometric authentication failed: $e');
      return BiometricResult(
        success: false,
        error: e.toString(),
        attempts: 0,
        duration: Duration.zero,
      );
    }
  }

  // Biometric management
  static Future<void> removeBiometric(String biometricId) async {
    try {
      final biometric = _registeredBiometrics[biometricId];
      if (biometric == null) {
        throw Exception('Biometric not found: $biometricId');
      }
      
      biometric.isActive = false;
      
      // Remove from secure storage
      await _removeBiometricData(biometricId);
      
      _registeredBiometrics.remove(biometricId);
      
      LoggingService.info('Removed biometric: $biometricId');
    } catch (e) {
      LoggingService.error('Failed to remove biometric: $e');
    }
  }

  static Future<void> updateBiometric({
    required String biometricId,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final biometric = _registeredBiometrics[biometricId];
      if (biometric == null) {
        throw Exception('Biometric not found: $biometricId');
      }
      
      biometric.description = description;
      if (metadata != null) {
        biometric.metadata.addAll(metadata);
      }
      biometric.updatedAt = DateTime.now();
      
      await _saveBiometricData(biometric);
      
      LoggingService.info('Updated biometric: $biometricId');
    } catch (e) {
      LoggingService.error('Failed to update biometric: $e');
    }
  }

  // Advanced biometric features
  static Future<BiometricLivenessResult> checkLiveness({
    required BiometricType type,
    Map<String, dynamic>? options,
  }) async {
    try {
      // Mock liveness detection
      await Future.delayed(Duration(milliseconds: 1500));
      
      final isLive = Random().nextDouble() > 0.1; // 90% success rate
      final confidence = 0.85 + Random().nextDouble() * 0.1;
      
      return BiometricLivenessResult(
        isLive: isLive,
        confidence: confidence,
        checks: [
          'blink_detection',
          'movement_analysis',
          'texture_analysis',
        ],
        timestamp: DateTime.now(),
      );
    } catch (e) {
      LoggingService.error('Liveness check failed: $e');
      return BiometricLivenessResult(
        isLive: false,
        confidence: 0.0,
        checks: [],
        timestamp: DateTime.now(),
      );
    }
  }

  static Future<BiometricQualityResult> assessQuality({
    required BiometricType type,
    required Uint8List biometricData,
  }) async {
    try {
      // Mock quality assessment
      await Future.delayed(Duration(milliseconds: 800));
      
      final quality = 0.7 + Random().nextDouble() * 0.3;
      final issues = <String>[];
      
      if (quality < 0.8) {
        issues.add('low_resolution');
      }
      if (quality < 0.7) {
        issues.add('poor_lighting');
      }
      if (quality < 0.6) {
        issues.add('partial_capture');
      }
      
      return BiometricQualityResult(
        quality: quality,
        isAcceptable: quality >= 0.7,
        issues: issues,
        recommendations: _getQualityRecommendations(issues),
        timestamp: DateTime.now(),
      );
    } catch (e) {
      LoggingService.error('Quality assessment failed: $e');
      return BiometricQualityResult(
        quality: 0.0,
        isAcceptable: false,
        issues: ['assessment_error'],
        recommendations: ['Try capturing biometric again'],
        timestamp: DateTime.now(),
      );
    }
  }

  // Multi-factor biometric authentication
  static Future<MultiFactorResult> authenticateMultiFactor({
    required String userId,
    required List<BiometricType> requiredTypes,
    int maxAttemptsPerType = 3,
  }) async {
    try {
      final startTime = DateTime.now();
      final results = <BiometricResult>[];
      int totalAttempts = 0;
      
      for (final type in requiredTypes) {
        final result = await authenticate(
          userId: userId,
          preferredType: type,
          maxAttempts: maxAttemptsPerType,
        );
        
        results.add(result);
        totalAttempts += result.attempts;
        
        if (!result.success) {
          return MultiFactorResult(
            success: false,
            results: results,
            totalAttempts: totalAttempts,
            duration: DateTime.now().difference(startTime),
            failedAt: type,
          );
        }
      }
      
      return MultiFactorResult(
        success: true,
        results: results,
        totalAttempts: totalAttempts,
        duration: DateTime.now().difference(startTime),
      );
    } catch (e) {
      LoggingService.error('Multi-factor authentication failed: $e');
      return MultiFactorResult(
        success: false,
        results: [],
        totalAttempts: 0,
        duration: Duration.zero,
      );
    }
  }

  // Biometric analytics
  static Future<BiometricAnalytics> getAnalytics({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final attempts = _getAllAttempts(userId, startDate, endDate);
      
      final successRate = attempts.isEmpty ? 0.0 : 
          attempts.where((a) => a.success).length / attempts.length;
      
      final averageDuration = attempts.isEmpty ? Duration.zero :
          Duration(milliseconds: attempts
              .map((a) => a.duration.inMilliseconds)
              .reduce((a, b) => a + b) ~/ attempts.length);
      
      final typeDistribution = <BiometricType, int>{};
      for (final attempt in attempts) {
        typeDistribution[attempt.type] = (typeDistribution[attempt.type] ?? 0) + 1;
      }
      
      return BiometricAnalytics(
        userId: userId,
        totalAttempts: attempts.length,
        successRate: successRate,
        averageDuration: averageDuration,
        typeDistribution: typeDistribution,
        startDate: startDate ?? DateTime.now().subtract(Duration(days: 30)),
        endDate: endDate ?? DateTime.now(),
      );
    } catch (e) {
      LoggingService.error('Failed to get biometric analytics: $e');
      rethrow;
    }
  }

  // Utility methods
  static Future<Uint8List?> _captureBiometricData(BiometricType type) async {
    try {
      // Mock biometric data capture
      await Future.delayed(Duration(milliseconds: 1000));
      
      switch (type) {
        case BiometricType.fingerprint:
          return _generateMockFingerprintData();
        case BiometricType.face:
          return _generateMockFaceData();
        case BiometricType.voice:
          return _generateMockVoiceData();
        case BiometricType.iris:
          return _generateMockIrisData();
        case BiometricType.palm:
          return _generateMockPalmData();
      }
    } catch (e) {
      LoggingService.error('Failed to capture biometric data: $e');
      return null;
    }
  }

  static Future<String> _createBiometricTemplate(Uint8List data, BiometricType type) async {
    try {
      // Create biometric template (mock implementation)
      final hash = sha256.convert(data);
      final typePrefix = type.name.substring(0, 2).toUpperCase();
      return '$typePrefix${hash.toString().substring(0, 30)}';
    } catch (e) {
      LoggingService.error('Failed to create biometric template: $e');
      rethrow;
    }
  }

  static Future<BiometricMatchResult> _compareBiometricData(
    Uint8List capturedData,
    List<BiometricData> registeredTemplates,
  ) async {
    try {
      // Mock biometric comparison
      await Future.delayed(Duration(milliseconds: 500));
      
      for (final template in registeredTemplates) {
        final similarity = Random().nextDouble();
        
        if (similarity > 0.8) {
          return BiometricMatchResult(
            success: true,
            biometricId: template.id,
            confidence: similarity,
            matchScore: similarity,
          );
        }
      }
      
      return BiometricMatchResult(
        success: false,
        confidence: 0.0,
        matchScore: 0.0,
      );
    } catch (e) {
      LoggingService.error('Biometric comparison failed: $e');
      return BiometricMatchResult(
        success: false,
        confidence: 0.0,
        matchScore: 0.0,
      );
    }
  }

  static Future<void> _saveBiometricData(BiometricData biometric) async {
    try {
      // Save to secure storage (mock implementation)
      final data = json.encode(biometric.toJson());
      await SecurityService.secureStore(_biometricStorageKey, data);
    } catch (e) {
      LoggingService.error('Failed to save biometric data: $e');
    }
  }

  static Future<void> _removeBiometricData(String biometricId) async {
    try {
      // Remove from secure storage (mock implementation)
      await SecurityService.secureDelete(_biometricStorageKey);
    } catch (e) {
      LoggingService.error('Failed to remove biometric data: $e');
    }
  }

  static Future<void> _loadRegisteredBiometrics() async {
    try {
      // Load from secure storage (mock implementation)
      final data = await SecurityService.secureRetrieve(_biometricStorageKey);
      if (data != null) {
        final biometricsData = json.decode(data);
        // Parse and load biometrics
      }
    } catch (e) {
      LoggingService.error('Failed to load registered biometrics: $e');
    }
  }

  static Future<void> _recordBiometricAttempt(
    String userId,
    BiometricType type,
    bool success,
  ) async {
    try {
      final attempt = BiometricAttempt(
        userId: userId,
        type: type,
        success: success,
        timestamp: DateTime.now(),
        duration: Duration(milliseconds: 1000), // Mock duration
      );
      
      if (_attemptHistory[userId] == null) {
        _attemptHistory[userId] = [];
      }
      
      _attemptHistory[userId]!.add(attempt);
      
      // Keep only last 100 attempts per user
      if (_attemptHistory[userId]!.length > 100) {
        _attemptHistory[userId]!.removeAt(0);
      }
    } catch (e) {
      LoggingService.error('Failed to record biometric attempt: $e');
    }
  }

  static bool _canAttempt(String userId) {
    final attempts = _attemptHistory[userId] ?? [];
    if (attempts.isEmpty) return true;
    
    final lastAttempt = attempts.last;
    final now = DateTime.now();
    
    // Allow one attempt per second after failure
    if (!lastAttempt.success && now.difference(lastAttempt.timestamp).inSeconds < 1) {
      return false;
    }
    
    // Rate limiting after multiple failures
    final recentFailures = attempts
        .where((a) => !a.success && now.difference(a.timestamp).inMinutes < 5)
        .length;
    
    if (recentFailures >= 5) {
      return now.difference(lastAttempt.timestamp).inMinutes >= 5;
    }
    
    return true;
  }

  static Duration _getWaitTime(String userId) {
    final attempts = _attemptHistory[userId] ?? [];
    if (attempts.isEmpty) return Duration.zero;
    
    final lastAttempt = attempts.last;
    final now = DateTime.now();
    
    if (!lastAttempt.success) {
      final timeSinceLastAttempt = now.difference(lastAttempt.timestamp);
      if (timeSinceLastAttempt.inSeconds < 1) {
        return Duration(seconds: 1 - timeSinceLastAttempt.inSeconds);
      }
    }
    
    return Duration.zero;
  }

  static List<BiometricAttempt> _getAllAttempts(
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    List<BiometricAttempt> allAttempts = [];
    
    if (userId != null) {
      allAttempts.addAll(_attemptHistory[userId] ?? []);
    } else {
      for (final attempts in _attemptHistory.values) {
        allAttempts.addAll(attempts);
      }
    }
    
    if (startDate != null) {
      allAttempts = allAttempts.where((a) => a.timestamp.isAfter(startDate)).toList();
    }
    
    if (endDate != null) {
      allAttempts = allAttempts.where((a) => a.timestamp.isBefore(endDate)).toList();
    }
    
    return allAttempts;
  }

  static List<String> _getQualityRecommendations(List<String> issues) {
    final recommendations = <String>[];
    
    if (issues.contains('low_resolution')) {
      recommendations.add('Use a higher resolution camera');
    }
    
    if (issues.contains('poor_lighting')) {
      recommendations.add('Improve lighting conditions');
    }
    
    if (issues.contains('partial_capture')) {
      recommendations.add('Ensure full biometric is captured');
    }
    
    if (issues.contains('motion_blur')) {
      recommendations.add('Keep still during capture');
    }
    
    return recommendations;
  }

  // Mock data generators
  static Uint8List _generateMockFingerprintData() {
    final data = List<int>.generate(1024, (_) => Random().nextInt(256));
    return Uint8List.fromList(data);
  }

  static Uint8List _generateMockFaceData() {
    final data = List<int>.generate(4096, (_) => Random().nextInt(256));
    return Uint8List.fromList(data);
  }

  static Uint8List _generateMockVoiceData() {
    final data = List<int>.generate(2048, (_) => Random().nextInt(256));
    return Uint8List.fromList(data);
  }

  static Uint8List _generateMockIrisData() {
    final data = List<int>.generate(512, (_) => Random().nextInt(256));
    return Uint8List.fromList(data);
  }

  static Uint8List _generateMockPalmData() {
    final data = List<int>.generate(1536, (_) => Random().nextInt(256));
    return Uint8List.fromList(data);
  }

  static String _generateBiometricId() {
    return 'bio_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Getters
  static bool get isInitialized => _isInitialized;
  static bool get isDeviceSupported => _isDeviceSupported;
  static List<BiometricType> get availableTypes => List.from(_availableTypes);
  static List<BiometricData> get registeredBiometrics => _registeredBiometrics.values.toList();
}

// Data models
class BiometricData {
  final String id;
  final BiometricType type;
  final String userId;
  final String template;
  final String? description;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastUsed;
  bool isActive;

  BiometricData({
    required this.id,
    required this.type,
    required this.userId,
    required this.template,
    this.description,
    required this.metadata,
    required this.createdAt,
    this.updatedAt,
    this.lastUsed,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'userId': userId,
      'template': template,
      'description': description,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastUsed': lastUsed?.toIso8601String(),
      'isActive': isActive,
    };
  }
}

class BiometricResult {
  final bool success;
  final String? biometricId;
  final String? error;
  final double? confidence;
  final int attempts;
  final Duration duration;

  BiometricResult({
    required this.success,
    this.biometricId,
    this.error,
    this.confidence,
    required this.attempts,
    required this.duration,
  });
}

class BiometricMatchResult {
  final bool success;
  final String biometricId;
  final double confidence;
  final double matchScore;

  BiometricMatchResult({
    required this.success,
    required this.biometricId,
    required this.confidence,
    required this.matchScore,
  });
}

class BiometricLivenessResult {
  final bool isLive;
  final double confidence;
  final List<String> checks;
  final DateTime timestamp;

  BiometricLivenessResult({
    required this.isLive,
    required this.confidence,
    required this.checks,
    required this.timestamp,
  });
}

class BiometricQualityResult {
  final double quality;
  final bool isAcceptable;
  final List<String> issues;
  final List<String> recommendations;
  final DateTime timestamp;

  BiometricQualityResult({
    required this.quality,
    required this.isAcceptable,
    required this.issues,
    required this.recommendations,
    required this.timestamp,
  });
}

class MultiFactorResult {
  final bool success;
  final List<BiometricResult> results;
  final int totalAttempts;
  final Duration duration;
  final BiometricType? failedAt;

  MultiFactorResult({
    required this.success,
    required this.results,
    required this.totalAttempts,
    required this.duration,
    this.failedAt,
  });
}

class BiometricAttempt {
  final String userId;
  final BiometricType type;
  final bool success;
  final DateTime timestamp;
  final Duration duration;

  BiometricAttempt({
    required this.userId,
    required this.type,
    required this.success,
    required this.timestamp,
    required this.duration,
  });
}

class BiometricAnalytics {
  final String? userId;
  final int totalAttempts;
  final double successRate;
  final Duration averageDuration;
  final Map<BiometricType, int> typeDistribution;
  final DateTime startDate;
  final DateTime endDate;

  BiometricAnalytics({
    this.userId,
    required this.totalAttempts,
    required this.successRate,
    required this.averageDuration,
    required this.typeDistribution,
    required this.startDate,
    required this.endDate,
  });
}

enum BiometricType {
  fingerprint,
  face,
  voice,
  iris,
  palm,
}
