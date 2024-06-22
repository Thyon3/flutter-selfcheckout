import 'dart:async';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:selfcheckoutapp/services/secure_storage_service.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();
  final SecureStorageService _secureStorage = SecureStorageService();

  // Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      return canCheckBiometrics;
    } catch (e) {
      if (kDebugMode) print('Error checking biometrics: $e');
      return false;
    }
  }

  // Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      if (kDebugMode) print('Error getting available biometrics: $e');
      return [];
    }
  }

  // Check if device supports biometric authentication
  Future<bool> isDeviceSupported() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      final hasBiometrics = await isBiometricAvailable();
      return isSupported && hasBiometrics;
    } catch (e) {
      if (kDebugMode) print('Error checking device support: $e');
      return false;
    }
  }

  // Authenticate with biometrics
  Future<BiometricResult> authenticate({
    String localizedReason = 'Authenticate to access your account',
    bool useErrorDialogs = true,
    bool stickyAuth = false,
    bool biometricOnly = false,
  }) async {
    try {
      final isAuthenticated = await _auth.authenticate(
        localizedReason: localizedReason,
        useErrorDialogs: useErrorDialogs,
        stickyAuth: stickyAuth,
        biometricOnly: biometricOnly,
      );

      if (isAuthenticated) {
        return BiometricResult.success();
      } else {
        return BiometricResult.failure('Authentication failed');
      }
    } on PlatformException catch (e) {
      return _handlePlatformException(e);
    } catch (e) {
      return BiometricResult.failure('Unexpected error: $e');
    }
  }

  // Handle platform exceptions
  BiometricResult _handlePlatformException(PlatformException e) {
    switch (e.code) {
      case 'NotAvailable':
        return BiometricResult.notAvailable('Biometric authentication is not available on this device');
      case 'NotEnrolled':
        return BiometricResult.notEnrolled('No biometrics enrolled on this device');
      case 'LockedOut':
        return BiometricResult.lockedOut('Too many failed attempts. Biometric authentication is locked');
      case 'PermanentlyLockedOut':
        return BiometricResult.permanentlyLockedOut('Biometric authentication is permanently locked');
      case 'OtherOperatingSystem':
        return BiometricResult.notSupported('Biometric authentication is not supported on this platform');
      case 'passcode_not_set':
        return BiometricResult.passcodeNotSet('Device passcode is not set');
      case 'user_fallback':
        return BiometricResult.userFallback('User chose to use fallback authentication');
      default:
        return BiometricResult.failure('Authentication error: ${e.message}');
    }
  }

  // Enable biometric authentication for the user
  Future<BiometricResult> enableBiometric() async {
    if (!await isDeviceSupported()) {
      return BiometricResult.notSupported('Device does not support biometric authentication');
    }

    final result = await authenticate(
      localizedReason: 'Enable biometric authentication for quick access',
    );

    if (result.success) {
      try {
        await _secureStorage.setBiometricEnabled(true);
        return BiometricResult.success();
      } catch (e) {
        return BiometricResult.failure('Failed to save biometric setting: $e');
      }
    }

    return result;
  }

  // Disable biometric authentication
  Future<void> disableBiometric() async {
    await _secureStorage.setBiometricEnabled(false);
  }

  // Check if biometric is enabled
  Future<bool> isBiometricEnabled() async {
    return await _secureStorage.isBiometricEnabled();
  }

  // Authenticate with biometrics (for app access)
  Future<BiometricResult> authenticateWithBiometric() async {
    final isEnabled = await isBiometricEnabled();
    if (!isEnabled) {
      return BiometricResult.notEnabled('Biometric authentication is not enabled');
    }

    return await authenticate(
      localizedReason: 'Authenticate to access ScanGo',
    );
  }

  // Authenticate for sensitive operations (payments, etc.)
  Future<BiometricResult> authenticateForPayment() async {
    return await authenticate(
      localizedReason: 'Authenticate to complete payment',
      biometricOnly: true, // Require biometric only, no fallback
    );
  }

  // Authenticate for profile changes
  Future<BiometricResult> authenticateForProfileChange() async {
    return await authenticate(
      localizedReason: 'Authenticate to modify profile settings',
    );
  }

  // Get biometric type name for display
  String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.iris:
        return 'Iris Scanner';
      default:
        return 'Biometric';
    }
  }

  // Get user-friendly biometric status
  Future<String> getBiometricStatus() async {
    if (!await isDeviceSupported()) {
      return 'Not Supported';
    }

    final availableBiometrics = await getAvailableBiometrics();
    if (availableBiometrics.isEmpty) {
      return 'Not Available';
    }

    final isEnabled = await isBiometricEnabled();
    if (isEnabled) {
      final types = availableBiometrics.map(getBiometricTypeName).join(' & ');
      return 'Enabled ($types)';
    } else {
      return 'Available but not enabled';
    }
  }

  // Check if biometric authentication should be offered
  Future<bool> shouldOfferBiometric() async {
    return await isDeviceSupported() && !(await isBiometricEnabled());
  }

  // Get biometric setup instructions
  String getSetupInstructions() {
    return '''
To enable biometric authentication:

1. Go to your device Settings
2. Find "Security" or "Face ID & Passcode"
3. Set up your biometric authentication
4. Return to the app and enable biometric access

This will allow you to quickly and securely access your account.
    ''';
  }
}

// Biometric authentication result
class BiometricResult {
  final bool success;
  final String? message;
  final BiometricErrorType? errorType;

  BiometricResult._({required this.success, this.message, this.errorType});

  factory BiometricResult.success() => BiometricResult._(success: true);
  factory BiometricResult.failure(String message) => 
      BiometricResult._(success: false, message: message, errorType: BiometricErrorType.unknown);
  factory BiometricResult.notAvailable(String message) => 
      BiometricResult._(success: false, message: message, errorType: BiometricErrorType.notAvailable);
  factory BiometricResult.notEnrolled(String message) => 
      BiometricResult._(success: false, message: message, errorType: BiometricErrorType.notEnrolled);
  factory BiometricResult.lockedOut(String message) => 
      BiometricResult._(success: false, message: message, errorType: BiometricErrorType.lockedOut);
  factory BiometricResult.permanentlyLockedOut(String message) => 
      BiometricResult._(success: false, message: message, errorType: BiometricErrorType.permanentlyLockedOut);
  factory BiometricResult.notSupported(String message) => 
      BiometricResult._(success: false, message: message, errorType: BiometricErrorType.notSupported);
  factory BiometricResult.passcodeNotSet(String message) => 
      BiometricResult._(success: false, message: message, errorType: BiometricErrorType.passcodeNotSet);
  factory BiometricResult.userFallback(String message) => 
      BiometricResult._(success: false, message: message, errorType: BiometricErrorType.userFallback);
  factory BiometricResult.notEnabled(String message) => 
      BiometricResult._(success: false, message: message, errorType: BiometricErrorType.notEnabled);
}

enum BiometricErrorType {
  unknown,
  notAvailable,
  notEnrolled,
  lockedOut,
  permanentlyLockedOut,
  notSupported,
  passcodeNotSet,
  userFallback,
  notEnabled,
}
