import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  static const String _themeKey = 'theme_mode';
  static const String _languageKey = 'language';
  static const String _biometricKey = 'biometric_enabled';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _autoLoginKey = 'auto_login';
  static const String _cartAutoSaveKey = 'cart_auto_save';

  Future<void> setThemeMode(String themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, themeMode);
  }

  Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? 'light';
  }

  Future<void> setLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language);
  }

  Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'en';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricKey, enabled);
  }

  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricKey) ?? false;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, enabled);
  }

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsKey) ?? true;
  }

  Future<void> setAutoLogin(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoLoginKey, enabled);
  }

  Future<bool> isAutoLoginEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoLoginKey) ?? false;
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
