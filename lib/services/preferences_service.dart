import 'package:shared_preferences/shared_preferences.dart';
import 'package:selfcheckoutapp/services/theme_service.dart';
import 'package:selfcheckoutapp/services/localization_service.dart';

class PreferencesService {
  static SharedPreferences? _prefs;
  static const String _firstLaunchKey = 'first_launch';
  static const String _autoBackupKey = 'auto_backup';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _lastSyncTimeKey = 'last_sync_time';
  static const String _cartReminderTimeKey = 'cart_reminder_time';
  static const String _defaultLanguageKey = 'default_language';
  static const String _searchHistoryKey = 'search_history';
  static const String _favoriteProductsKey = 'favorite_products';
  static const String _recentlyViewedKey = 'recently_viewed';

  static Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<bool> isFirstLaunch() async {
    await initialize();
    final isFirst = _prefs!.getBool(_firstLaunchKey) ?? true;
    if (isFirst) {
      await _prefs!.setBool(_firstLaunchKey, false);
    }
    return isFirst;
  }

  static Future<void> setAutoBackup(bool enabled) async {
    await initialize();
    await _prefs!.setBool(_autoBackupKey, enabled);
  }

  static Future<bool> isAutoBackupEnabled() async {
    await initialize();
    return _prefs!.getBool(_autoBackupKey) ?? true;
  }

  static Future<void> setNotificationsEnabled(bool enabled) async {
    await initialize();
    await _prefs!.setBool(_notificationsEnabledKey, enabled);
  }

  static Future<bool> areNotificationsEnabled() async {
    await initialize();
    return _prefs!.getBool(_notificationsEnabledKey) ?? true;
  }

  static Future<void> setBiometricEnabled(bool enabled) async {
    await initialize();
    await _prefs!.setBool(_biometricEnabledKey, enabled);
  }

  static Future<bool> isBiometricEnabled() async {
    await initialize();
    return _prefs!.getBool(_biometricEnabledKey) ?? false;
  }

  static Future<void> setLastSyncTime(DateTime time) async {
    await initialize();
    await _prefs!.setString(_lastSyncTimeKey, time.toIso8601String());
  }

  static Future<DateTime?> getLastSyncTime() async {
    await initialize();
    final timeString = _prefs!.getString(_lastSyncTimeKey);
    if (timeString != null) {
      return DateTime.parse(timeString);
    }
    return null;
  }

  Future<void> setCartAutoSave(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cartAutoSaveKey, enabled);
  }

  Future<bool> isCartAutoSaveEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_cartAutoSaveKey) ?? true;
  }

  Future<void> clearAllPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
