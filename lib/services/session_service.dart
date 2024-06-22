import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:selfcheckoutapp/services/secure_storage_service.dart';
import 'package:selfcheckoutapp/services/biometric_service.dart';
import 'package:selfcheckoutapp/services/user_behavior_service.dart';

class SessionService {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  final SecureStorageService _secureStorage = SecureStorageService();
  final BiometricService _biometricService = BiometricService();
  final UserBehaviorService _behaviorService = UserBehaviorService();

  User? _currentUser;
  DateTime? _sessionStart;
  Timer? _sessionTimer;
  Timer? _activityTimer;
  DateTime? _lastActivity;
  bool _isSessionActive = false;
  static const Duration _sessionTimeout = Duration(minutes: 30);
  static const Duration _activityTimeout = Duration(minutes: 5);

  // Session events
  final StreamController<SessionEvent> _sessionController = 
      StreamController<SessionEvent>.broadcast();
  Stream<SessionEvent> get sessionEvents => _sessionController.stream;

  // Initialize session service
  Future<void> initialize() async {
    await _checkExistingSession();
    _startSessionMonitoring();
  }

  // Check for existing session
  Future<void> _checkExistingSession() async {
    try {
      final sessionData = await _secureStorage.getSessionData();
      if (sessionData != null) {
        final timestamp = DateTime.parse(sessionData['timestamp']);
        final now = DateTime.now();
        
        // Check if session is still valid
        if (now.difference(timestamp).inHours < 24) {
          // Try to restore session
          final success = await _restoreSession(sessionData);
          if (success) {
            _sessionController.add(SessionEvent.sessionRestored());
          } else {
            await clearSession();
          }
        } else {
          await clearSession();
        }
      }
    } catch (e) {
      await clearSession();
    }
  }

  // Start new session
  Future<void> startSession(User user, {bool rememberMe = false}) async {
    try {
      _currentUser = user;
      _sessionStart = DateTime.now();
      _lastActivity = DateTime.now();
      _isSessionActive = true;

      // Store session data
      final sessionData = {
        'user_id': user.uid,
        'user_email': user.email,
        'display_name': user.displayName,
        'session_start': _sessionStart!.toIso8601String(),
        'remember_me': rememberMe,
        'last_activity': _lastActivity!.toIso8601String(),
      };

      await _secureStorage.storeSessionData(sessionData);
      await _behaviorService.initialize();

      // Start session timers
      _startSessionTimer();
      _startActivityTimer();

      _sessionController.add(SessionEvent.sessionStarted(user));
    } catch (e) {
      _sessionController.add(SessionEvent.sessionError('Failed to start session: $e'));
    }
  }

  // Restore existing session
  Future<bool> _restoreSession(Map<String, dynamic> sessionData) async {
    try {
      // Check if user is still authenticated with Firebase
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || currentUser.uid != sessionData['user_id']) {
        return false;
      }

      _currentUser = currentUser;
      _sessionStart = DateTime.parse(sessionData['session_start']);
      _lastActivity = DateTime.parse(sessionData['last_activity']);
      _isSessionActive = true;

      // Update last activity
      await updateLastActivity();

      // Restart timers
      _startSessionTimer();
      _startActivityTimer();

      return true;
    } catch (e) {
      return false;
    }
  }

  // Update last activity time
  Future<void> updateLastActivity() async {
    _lastActivity = DateTime.now();
    
    // Update session data
    final sessionData = await _secureStorage.getSessionData();
    if (sessionData != null) {
      sessionData['last_activity'] = _lastActivity!.toIso8601String();
      await _secureStorage.storeSessionData(sessionData);
    }

    // Reset activity timer
    _activityTimer?.cancel();
    _startActivityTimer();
  }

  // Start session timer
  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(Duration(minutes: 1), (_) {
      _checkSessionTimeout();
    });
  }

  // Start activity timer
  void _startActivityTimer() {
    _activityTimer?.cancel();
    _activityTimer = Timer(_activityTimeout, () {
      _handleActivityTimeout();
    });
  }

  // Check session timeout
  void _checkSessionTimeout() {
    if (!_isSessionActive || _lastActivity == null) return;

    final now = DateTime.now();
    final timeSinceLastActivity = now.difference(_lastActivity!);

    if (timeSinceLastActivity >= _sessionTimeout) {
      _handleSessionTimeout();
    }
  }

  // Handle session timeout
  void _handleSessionTimeout() {
    _sessionController.add(SessionEvent.sessionTimeout());
    endSession(reason: 'Session timeout');
  }

  // Handle activity timeout
  void _handleActivityTimeout() {
    _sessionController.add(SessionEvent.activityTimeout());
  }

  // End session
  Future<void> endSession({String? reason}) async {
    try {
      _isSessionActive = false;
      _sessionTimer?.cancel();
      _activityTimer?.cancel();

      final sessionDuration = _sessionStart != null 
          ? DateTime.now().difference(_sessionStart!).inSeconds 
          : 0;

      // Track session end
      await _behaviorService.trackUserEngagement();

      // Clear session data
      await _secureStorage.clearSessionData();

      // Clear current user
      _currentUser = null;
      _sessionStart = null;
      _lastActivity = null;

      _sessionController.add(SessionEvent.sessionEnded(reason ?? 'Manual logout'));
    } catch (e) {
      _sessionController.add(SessionEvent.sessionError('Failed to end session: $e'));
    }
  }

  // Extend session
  Future<void> extendSession() async {
    if (!_isSessionActive) return;

    await updateLastActivity();
    _sessionController.add(SessionEvent.sessionExtended());
  }

  // Check if session is active
  bool get isSessionActive => _isSessionActive;

  // Get current user
  User? get currentUser => _currentUser;

  // Get session info
  Map<String, dynamic>? getSessionInfo() {
    if (!_isSessionActive || _sessionStart == null) return null;

    return {
      'user_id': _currentUser?.uid,
      'user_email': _currentUser?.email,
      'display_name': _currentUser?.displayName,
      'session_start': _sessionStart!.toIso8601String(),
      'session_duration': DateTime.now().difference(_sessionStart!).inSeconds,
      'last_activity': _lastActivity?.toIso8601String(),
      'is_active': _isSessionActive,
    };
  }

  // Authenticate with biometric for session restoration
  Future<bool> authenticateForSessionRestore() async {
    if (!await _biometricService.isBiometricEnabled()) {
      return false;
    }

    final result = await _biometricService.authenticateWithBiometric();
    if (result.success) {
      await updateLastActivity();
      return true;
    }

    return false;
  }

  // Start session monitoring
  void _startSessionMonitoring() {
    // Monitor app lifecycle
    // This would integrate with app lifecycle callbacks
  }

  // Clear session
  Future<void> clearSession() async {
    await endSession(reason: 'Session cleared');
  }

  // Force session refresh
  Future<void> refreshSession() async {
    if (_currentUser != null) {
      await endSession(reason: 'Session refresh');
      await startSession(_currentUser!, rememberMe: true);
    }
  }

  // Get session statistics
  Map<String, dynamic> getSessionStatistics() {
    if (!_isSessionActive || _sessionStart == null) {
      return {
        'active': false,
        'duration': 0,
        'user_id': null,
      };
    }

    final duration = DateTime.now().difference(_sessionStart!);
    final idleTime = _lastActivity != null 
        ? DateTime.now().difference(_lastActivity!).inSeconds 
        : 0;

    return {
      'active': true,
      'duration': duration.inSeconds,
      'idle_time': idleTime,
      'user_id': _currentUser?.uid,
      'user_email': _currentUser?.email,
      'session_start': _sessionStart!.toIso8601String(),
      'last_activity': _lastActivity?.toIso8601String(),
    };
  }

  void dispose() {
    _sessionTimer?.cancel();
    _activityTimer?.cancel();
    _sessionController.close();
  }
}

// Session events
class SessionEvent {
  final SessionEventType type;
  final String? message;
  final User? user;

  SessionEvent._({required this.type, this.message, this.user});

  factory SessionEvent.sessionStarted(User user) => 
      SessionEvent._(type: SessionEventType.started, user: user);
  factory SessionEvent.sessionEnded(String reason) => 
      SessionEvent._(type: SessionEventType.ended, message: reason);
  factory SessionEvent.sessionRestored() => 
      SessionEvent._(type: SessionEventType.restored);
  factory SessionEvent.sessionTimeout() => 
      SessionEvent._(type: SessionEventType.timeout);
  factory SessionEvent.activityTimeout() => 
      SessionEvent._(type: SessionEventType.activityTimeout);
  factory SessionEvent.sessionExtended() => 
      SessionEvent._(type: SessionEventType.extended);
  factory SessionEvent.sessionError(String error) => 
      SessionEvent._(type: SessionEventType.error, message: error);
}

enum SessionEventType {
  started,
  ended,
  restored,
  timeout,
  activityTimeout,
  extended,
  error,
}
