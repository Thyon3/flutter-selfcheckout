import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Keys for sensitive data
  static const String _authTokenKey = 'auth_token';
  static const String _userCredentialsKey = 'user_credentials';
  static const String _paymentInfoKey = 'payment_info';
  static const String _sessionKey = 'session_data';
  static const String _biometricKey = 'biometric_enabled';

  // Store authentication token
  Future<void> storeAuthToken(String token) async {
    try {
      final encryptedToken = _encryptData(token);
      await _storage.write(key: _authTokenKey, value: encryptedToken);
    } catch (e) {
      throw Exception('Failed to store auth token: $e');
    }
  }

  // Retrieve authentication token
  Future<String?> getAuthToken() async {
    try {
      final encryptedToken = await _storage.read(key: _authTokenKey);
      if (encryptedToken == null) return null;
      
      return _decryptData(encryptedToken);
    } catch (e) {
      throw Exception('Failed to retrieve auth token: $e');
    }
  }

  // Store user credentials (for auto-login)
  Future<void> storeUserCredentials({
    required String email,
    required String password,
  }) async {
    try {
      final credentials = {
        'email': email,
        'password': password,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      final encryptedCredentials = _encryptData(jsonEncode(credentials));
      await _storage.write(key: _userCredentialsKey, value: encryptedCredentials);
    } catch (e) {
      throw Exception('Failed to store user credentials: $e');
    }
  }

  // Retrieve user credentials
  Future<Map<String, String>?> getUserCredentials() async {
    try {
      final encryptedCredentials = await _storage.read(key: _userCredentialsKey);
      if (encryptedCredentials == null) return null;
      
      final decryptedData = _decryptData(encryptedCredentials);
      final credentials = jsonDecode(decryptedData) as Map<String, dynamic>;
      
      // Check if credentials are not too old (30 days)
      final timestamp = DateTime.parse(credentials['timestamp']);
      if (DateTime.now().difference(timestamp).inDays > 30) {
        await clearUserCredentials();
        return null;
      }
      
      return {
        'email': credentials['email'],
        'password': credentials['password'],
      };
    } catch (e) {
      throw Exception('Failed to retrieve user credentials: $e');
    }
  }

  // Store payment information
  Future<void> storePaymentInfo(Map<String, dynamic> paymentInfo) async {
    try {
      final encryptedPaymentInfo = _encryptData(jsonEncode(paymentInfo));
      await _storage.write(key: _paymentInfoKey, value: encryptedPaymentInfo);
    } catch (e) {
      throw Exception('Failed to store payment info: $e');
    }
  }

  // Retrieve payment information
  Future<Map<String, dynamic>?> getPaymentInfo() async {
    try {
      final encryptedPaymentInfo = await _storage.read(key: _paymentInfoKey);
      if (encryptedPaymentInfo == null) return null;
      
      final decryptedData = _decryptData(encryptedPaymentInfo);
      return jsonDecode(decryptedData) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to retrieve payment info: $e');
    }
  }

  // Store session data
  Future<void> storeSessionData(Map<String, dynamic> sessionData) async {
    try {
      sessionData['timestamp'] = DateTime.now().toIso8601String();
      final encryptedSessionData = _encryptData(jsonEncode(sessionData));
      await _storage.write(key: _sessionKey, value: encryptedSessionData);
    } catch (e) {
      throw Exception('Failed to store session data: $e');
    }
  }

  // Retrieve session data
  Future<Map<String, dynamic>?> getSessionData() async {
    try {
      final encryptedSessionData = await _storage.read(key: _sessionKey);
      if (encryptedSessionData == null) return null;
      
      final decryptedData = _decryptData(encryptedSessionData);
      final sessionData = jsonDecode(decryptedData) as Map<String, dynamic>;
      
      // Check if session is still valid (24 hours)
      final timestamp = DateTime.parse(sessionData['timestamp']);
      if (DateTime.now().difference(timestamp).inHours > 24) {
        await clearSessionData();
        return null;
      }
      
      return sessionData;
    } catch (e) {
      throw Exception('Failed to retrieve session data: $e');
    }
  }

  // Biometric settings
  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _storage.write(key: _biometricKey, value: enabled.toString());
    } catch (e) {
      throw Exception('Failed to set biometric setting: $e');
    }
  }

  Future<bool> isBiometricEnabled() async {
    try {
      final value = await _storage.read(key: _biometricKey);
      return value == 'true';
    } catch (e) {
      return false;
    }
  }

  // Encryption helpers
  String _encryptData(String data) {
    final key = utf8.encode('selfcheckout_secure_key_2024');
    final bytes = utf8.encode(data);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    
    // Simple XOR encryption for demonstration
    // In production, use proper encryption libraries
    final encrypted = <int>[];
    for (int i = 0; i < bytes.length; i++) {
      encrypted.add(bytes[i] ^ digest.bytes[i % digest.bytes.length]);
    }
    
    return base64.encode(encrypted);
  }

  String _decryptData(String encryptedData) {
    final key = utf8.encode('selfcheckout_secure_key_2024');
    final encrypted = base64.decode(encryptedData);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(encrypted);
    
    // Reverse XOR encryption
    final decrypted = <int>[];
    for (int i = 0; i < encrypted.length; i++) {
      decrypted.add(encrypted[i] ^ digest.bytes[i % digest.bytes.length]);
    }
    
    return utf8.decode(decrypted);
  }

  // Clear methods
  Future<void> clearAuthToken() async {
    await _storage.delete(key: _authTokenKey);
  }

  Future<void> clearUserCredentials() async {
    await _storage.delete(key: _userCredentialsKey);
  }

  Future<void> clearPaymentInfo() async {
    await _storage.delete(key: _paymentInfoKey);
  }

  Future<void> clearSessionData() async {
    await _storage.delete(key: _sessionKey);
  }

  Future<void> clearAllData() async {
    await _storage.deleteAll();
  }

  // Check if secure storage is available
  Future<bool> isSecureStorageAvailable() async {
    try {
      await _storage.write(key: 'test', value: 'test');
      await _storage.delete(key: 'test');
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get storage info
  Future<Map<String, dynamic>> getStorageInfo() async {
    final info = <String, dynamic>{};
    
    try {
      info['auth_token'] = await _storage.read(key: _authTokenKey) != null;
      info['user_credentials'] = await _storage.read(key: _userCredentialsKey) != null;
      info['payment_info'] = await _storage.read(key: _paymentInfoKey) != null;
      info['session_data'] = await _storage.read(key: _sessionKey) != null;
      info['biometric_enabled'] = await isBiometricEnabled();
      info['secure_storage_available'] = await isSecureStorageAvailable();
    } catch (e) {
      info['error'] = e.toString();
    }
    
    return info;
  }
}
