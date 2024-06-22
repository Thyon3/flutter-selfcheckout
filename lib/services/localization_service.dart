import 'package:flutter/material.dart';

class LocalizationService {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  static const Map<String, Map<String, String>> _translations = {
    'en': {
      'app_name': 'ScanGo',
      'welcome': 'Welcome Shopper!',
      'login_to_account': 'Login to your account',
      'email': 'Email',
      'password': 'Password',
      'login': 'Login',
      'create_account': 'Create New Account',
      'shopping_list': 'Shopping List',
      'cart_history': 'Cart History',
      'start_shopping': "Let's Start Shopping!",
      'no_items_cart': 'No items in cart.\nScan items to start!',
      'total': 'Total',
      'proceed': 'Proceed',
      'payment': 'Payment',
      'logout': 'Logout',
      'profile': 'Profile',
      'about_app': 'About App',
    },
    'si': {
      'app_name': 'ස්කන්ගෝ',
      'welcome': 'සාදකරුවන් පිළිගන්න!',
      'login_to_account': 'ඔබගේ ගිණුමට පිවිසෙන්න',
      'email': 'වි-තැපෑල',
      'password': 'මුරපදබවන්',
      'login': 'පිවිසීම',
      'create_account': 'නව ගිණුමක් සාදනන්න',
      'shopping_list': 'ාදන ලැයිස්තුව',
      'cart_history': 'කරත්තු ඉතිහාසය',
      'start_shopping': 'ාදනය ආරම්භ කරන්න!',
      'no_items_cart': 'කරත්තුවේ අයිතම් නැත.\nඅයිතම් ස්කෑන් කරන්න!',
      'total': 'එකතුර',
      'proceed': 'ඉදිරිපත් කරන්න',
      'payment': 'ගෙවීම',
      'logout': 'පිටවීම',
      'profile': 'පැතිකඩ',
      'about_app': 'යෙදුම ගැන',
    },
  };

  String _currentLocale = 'en';

  String translate(String key) {
    return _translations[_currentLocale]?[key] ?? 
           _translations['en']?[key] ?? 
           key;
  }

  void setLocale(String locale) {
    if (_translations.containsKey(locale)) {
      _currentLocale = locale;
    }
  }

  String get currentLocale => _currentLocale;
  List<String> get supportedLocales => _translations.keys.toList();
}
