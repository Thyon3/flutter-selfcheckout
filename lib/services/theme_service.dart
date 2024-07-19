import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:selfcheckoutapp/constants.dart';

class ThemeService {
  static const String _themeKey = 'selected_theme';
  static ThemeMode _currentThemeMode = ThemeMode.system;
  static final ValueNotifier<ThemeMode> _themeNotifier = ValueNotifier(ThemeMode.system);

  static ValueNotifier<ThemeMode> get themeNotifier => _themeNotifier;
  static ThemeMode get currentThemeMode => _currentThemeMode;

  static Future<void> initialize() async {
    final savedTheme = await getSavedTheme();
    _currentThemeMode = savedTheme ?? ThemeMode.system;
    _themeNotifier.value = _currentThemeMode;
  }

  static Future<ThemeMode?> getSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey);
      
      if (themeIndex != null) {
        return ThemeMode.values[themeIndex];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> setTheme(ThemeMode themeMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, themeMode.index);
      _currentThemeMode = themeMode;
      _themeNotifier.value = themeMode;
    } catch (e) {
      // Handle error
    }
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primarySwatch: Colors.green,
      primaryColor: Constants.primaryColor,
      scaffoldBackgroundColor: Constants.backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: Constants.primaryColor,
        titleTextStyle: Constants.boldHeadingAppBar.copyWith(color: Colors.white),
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 2,
      ),
      cardTheme: CardTheme(
        color: Constants.cardColor,
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Constants.cardBorderRadius),
        ),
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Constants.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Constants.borderRadius),
          ),
          padding: Constants.buttonPadding,
          minimumSize: Size(0, Constants.buttonHeight),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Constants.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Constants.borderRadius),
          ),
          padding: Constants.buttonPadding,
          minimumSize: Size(0, Constants.buttonHeight),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Constants.primaryColor,
          side: BorderSide(color: Constants.primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Constants.borderRadius),
          ),
          padding: Constants.buttonPadding,
          minimumSize: Size(0, Constants.buttonHeight),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Constants.inputBorderRadius),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Constants.inputBorderRadius),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Constants.inputBorderRadius),
          borderSide: BorderSide(color: Constants.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Constants.inputBorderRadius),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      textTheme: TextTheme(
        displayLarge: Constants.boldText.copyWith(fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: Constants.boldText.copyWith(fontSize: 28, fontWeight: FontWeight.bold),
        displaySmall: Constants.boldText.copyWith(fontSize: 24, fontWeight: FontWeight.bold),
        headlineLarge: Constants.boldText.copyWith(fontSize: 22, fontWeight: FontWeight.bold),
        headlineMedium: Constants.boldText.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
        headlineSmall: Constants.boldText.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
        titleLarge: Constants.boldText.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
        titleMedium: Constants.regularText.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
        titleSmall: Constants.regularText.copyWith(fontSize: 12, fontWeight: FontWeight.w500),
        bodyLarge: Constants.regularText.copyWith(fontSize: 16),
        bodyMedium: Constants.regularText.copyWith(fontSize: 14),
        bodySmall: Constants.smallText.copyWith(fontSize: 12),
        labelLarge: Constants.regularText.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
        labelMedium: Constants.smallText.copyWith(fontSize: 12, fontWeight: FontWeight.w500),
        labelSmall: Constants.smallText.copyWith(fontSize: 10, fontWeight: FontWeight.w500),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: Constants.primaryColor,
        brightness: Brightness.light,
        primary: Constants.primaryColor,
        secondary: Constants.accentColor,
        surface: Constants.cardColor,
        background: Constants.backgroundColor,
        error: Colors.red,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Constants.textColor,
        onBackground: Constants.textColor,
        onError: Colors.white,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Constants.cardColor,
        selectedItemColor: Constants.primaryColor,
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Constants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Constants.primaryColor;
          }
          return Colors.grey[400];
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Constants.primaryColor.withOpacity(0.3);
          }
          return Colors.grey[300];
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Constants.primaryColor;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Constants.primaryColor;
          }
          return Colors.grey[600];
        }),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primarySwatch: Colors.green,
      primaryColor: Constants.primaryColor,
      scaffoldBackgroundColor: Color(0xff121212),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xff1e1e1e),
        titleTextStyle: Constants.boldHeadingAppBar.copyWith(color: Colors.white),
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 2,
      ),
      cardTheme: CardTheme(
        color: Color(0xff1e1e1e),
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Constants.cardBorderRadius),
        ),
        shadowColor: Colors.black.withOpacity(0.3),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Constants.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Constants.borderRadius),
          ),
          padding: Constants.buttonPadding,
          minimumSize: Size(0, Constants.buttonHeight),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Constants.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Constants.borderRadius),
          ),
          padding: Constants.buttonPadding,
          minimumSize: Size(0, Constants.buttonHeight),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Constants.primaryColor,
          side: BorderSide(color: Constants.primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Constants.borderRadius),
          ),
          padding: Constants.buttonPadding,
          minimumSize: Size(0, Constants.buttonHeight),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xff2a2a2a),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Constants.inputBorderRadius),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Constants.inputBorderRadius),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Constants.inputBorderRadius),
          borderSide: BorderSide(color: Constants.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Constants.inputBorderRadius),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: TextStyle(color: Colors.grey[300]),
        hintStyle: TextStyle(color: Colors.grey[400]),
      ),
      textTheme: TextTheme(
        displayLarge: Constants.boldText.copyWith(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        displayMedium: Constants.boldText.copyWith(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        displaySmall: Constants.boldText.copyWith(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        headlineLarge: Constants.boldText.copyWith(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        headlineMedium: Constants.boldText.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        headlineSmall: Constants.boldText.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        titleLarge: Constants.boldText.copyWith(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        titleMedium: Constants.regularText.copyWith(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
        titleSmall: Constants.regularText.copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
        bodyLarge: Constants.regularText.copyWith(fontSize: 16, color: Colors.white),
        bodyMedium: Constants.regularText.copyWith(fontSize: 14, color: Colors.white),
        bodySmall: Constants.smallText.copyWith(fontSize: 12, color: Colors.grey[300]),
        labelLarge: Constants.regularText.copyWith(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
        labelMedium: Constants.smallText.copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
        labelSmall: Constants.smallText.copyWith(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: Constants.primaryColor,
        brightness: Brightness.dark,
        primary: Constants.primaryColor,
        secondary: Constants.accentColor,
        surface: Color(0xff1e1e1e),
        background: Color(0xff121212),
        error: Colors.red,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onBackground: Colors.white,
        onError: Colors.white,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Color(0xff1e1e1e),
        selectedItemColor: Constants.primaryColor,
        unselectedItemColor: Colors.grey[400],
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Constants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Constants.primaryColor;
          }
          return Colors.grey[400];
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Constants.primaryColor.withOpacity(0.3);
          }
          return Colors.grey[600];
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Constants.primaryColor;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Constants.primaryColor;
          }
          return Colors.grey[400];
        }),
      ),
    );
  }

  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static String getThemeName(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  static ThemeMode getThemeModeFromName(String name) {
    switch (name.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  static Future<void> resetToDefault() async {
    await setTheme(ThemeMode.system);
  }

  static void dispose() {
    _themeNotifier.dispose();
  }
}
