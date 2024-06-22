import 'package:flutter/material.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  ThemeMode _themeMode = ThemeMode.light;
  bool _isDarkMode = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _themeMode = _isDarkMode ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _isDarkMode = mode == ThemeMode.dark;
    notifyListeners();
  }

  static ThemeData get lightTheme => ThemeData(
    primarySwatch: Colors.green,
    primaryColor: Color(0xff1faa00),
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xff1faa00),
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xff1faa00),
        foregroundColor: Colors.white,
      ),
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.green,
    primaryColor: Color(0xff1faa00),
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xff1a8800),
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xff1faa00),
        foregroundColor: Colors.white,
      ),
    ),
  );
}
