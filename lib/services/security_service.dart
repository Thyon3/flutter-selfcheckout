import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:selfcheckoutapp/services/logging_service.dart';

class SecurityService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _encryptionKey = 'encryption_key';
  static const String _saltKey = 'salt_key';
  
  static String? _cachedEncryptionKey;
  static String? _cachedSalt;

  static Future<void> initialize() async {
    await _generateOrRetrieveKeys();
  }

  static Future<void> _generateOrRetrieveKeys() async {
    try {
      _cachedEncryptionKey = await _secureStorage.read(key: _encryptionKey);
      _cachedSalt = await _secureStorage.read(key: _saltKey);

      if (_cachedEncryptionKey == null || _cachedSalt == null) {
        await _generateNewKeys();
      }
    } catch (e) {
      LoggingService.error('Failed to initialize security keys', error: e);
      rethrow;
    }
  }

  static Future<void> _generateNewKeys() async {
    final random = Random.secure();
    final salt = List<int>.generate(32, (_) => random.nextInt(256));
    final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));

    _cachedSalt = base64.encode(salt);
    _cachedEncryptionKey = base64.encode(keyBytes);

    await _secureStorage.write(key: _saltKey, value: _cachedSalt!);
    await _secureStorage.write(key: _encryptionKey, value: _cachedEncryptionKey!);

    LoggingService.info('New security keys generated');
  }

  static String encrypt(String data) {
    if (_cachedEncryptionKey == null || _cachedSalt == null) {
      throw Exception('Security service not initialized');
    }

    try {
      final key = utf8.encode(_cachedEncryptionKey!);
      final salt = base64.decode(_cachedSalt!);
      final dataBytes = utf8.encode(data);

      // Simple XOR encryption (in production, use proper encryption like AES)
      final encrypted = List<int>.generate(dataBytes.length, (i) {
        return dataBytes[i] ^ key[i % key.length] ^ salt[i % salt.length];
      });

      return base64.encode(encrypted);
    } catch (e) {
      LoggingService.error('Failed to encrypt data', error: e);
      rethrow;
    }
  }

  static String decrypt(String encryptedData) {
    if (_cachedEncryptionKey == null || _cachedSalt == null) {
      throw Exception('Security service not initialized');
    }

    try {
      final key = utf8.encode(_cachedEncryptionKey!);
      final salt = base64.decode(_cachedSalt!);
      final encrypted = base64.decode(encryptedData);

      // Reverse XOR encryption
      final decrypted = List<int>.generate(encrypted.length, (i) {
        return encrypted[i] ^ key[i % key.length] ^ salt[i % salt.length];
      });

      return utf8.decode(decrypted);
    } catch (e) {
      LoggingService.error('Failed to decrypt data', error: e);
      rethrow;
    }
  }

  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static bool verifyPassword(String password, String hashedPassword) {
    return hashPassword(password) == hashedPassword;
  }

  static Future<void> storeSecureData(String key, String value) async {
    try {
      final encryptedValue = encrypt(value);
      await _secureStorage.write(key: key, value: encryptedValue);
      LoggingService.debug('Secure data stored for key: $key');
    } catch (e) {
      LoggingService.error('Failed to store secure data', error: e);
      rethrow;
    }
  }

  static Future<String?> getSecureData(String key) async {
    try {
      final encryptedValue = await _secureStorage.read(key: key);
      if (encryptedValue == null) return null;

      final decryptedValue = decrypt(encryptedValue);
      LoggingService.debug('Secure data retrieved for key: $key');
      return decryptedValue;
    } catch (e) {
      LoggingService.error('Failed to retrieve secure data', error: e);
      return null;
    }
  }

  static Future<void> deleteSecureData(String key) async {
    try {
      await _secureStorage.delete(key: key);
      LoggingService.debug('Secure data deleted for key: $key');
    } catch (e) {
      LoggingService.error('Failed to delete secure data', error: e);
    }
  }

  static Future<void> clearAllSecureData() async {
    try {
      await _secureStorage.deleteAll();
      LoggingService.warning('All secure data cleared');
    } catch (e) {
      LoggingService.error('Failed to clear secure data', error: e);
    }
  }

  static Future<bool> isSecureDataAvailable(String key) async {
    try {
      final value = await _secureStorage.read(key: key);
      return value != null;
    } catch (e) {
      LoggingService.error('Failed to check secure data availability', error: e);
      return false;
    }
  }

  static String generateSecureToken({int length = 32}) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return base64.encode(bytes);
  }

  static String maskSensitiveData(String data, {int visibleChars = 4}) {
    if (data.length <= visibleChars) {
      return '*' * data.length;
    }
    
    final visible = data.substring(0, visibleChars);
    final masked = '*' * (data.length - visibleChars);
    return visible + masked;
  }

  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  static bool isValidPassword(String password) {
    return password.length >= 8 && 
           password.contains(RegExp(r'[A-Z]')) &&
           password.contains(RegExp(r'[a-z]')) &&
           password.contains(RegExp(r'[0-9]'));
  }

  static String sanitizeInput(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'[^\w\s@.-]'), ''); // Keep only safe characters
  }

  static Future<void> rotateKeys() async {
    try {
      LoggingService.info('Rotating security keys');
      await _generateNewKeys();
      LoggingService.info('Security keys rotated successfully');
    } catch (e) {
      LoggingService.error('Failed to rotate security keys', error: e);
      rethrow;
    }
  }
}
