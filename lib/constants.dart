import 'package:flutter/material.dart';

class Constants {
  static const Color primaryColor = Color(0xff1faa00);
  static const Color accentColor = Color(0xffD50000);
  static const Color backgroundColor = Color(0xfff5f5f5);
  static const Color cardColor = Colors.white;
  static const Color textColor = Colors.black87;
  static const Color hintTextColor = Colors.grey;

  // Text Styles
  static const TextStyle regularText = TextStyle(
    fontSize: 16.0,
    color: textColor,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle boldText = TextStyle(
    fontSize: 18.0,
    color: textColor,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle smallText = TextStyle(
    fontSize: 14.0,
    color: textColor,
    fontWeight: FontWeight.normal,
  );

  // AppBar Styles
  static const TextStyle boldHeadingAppBar = TextStyle(
    fontSize: 20.0,
    color: Colors.white,
    fontWeight: FontWeight.bold,
  );

  // Button Styles
  static const double buttonHeight = 50.0;
  static const double borderRadius = 12.0;
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0);

  // Spacing
  static const double smallPadding = 8.0;
  static const double mediumPadding = 16.0;
  static const double largePadding = 24.0;
  static const double extraLargePadding = 32.0;

  // Border Radius
  static const double cardBorderRadius = 15.0;
  static const double inputBorderRadius = 8.0;

  // Shadow
  static const BoxShadow cardShadow = BoxShadow(
    color: Colors.black12,
    spreadRadius: 1,
    blurRadius: 3,
    offset: Offset(0, 2),
  );

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Network
  static const Duration networkTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;

  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userPreferencesKey = 'user_preferences';
  static const String cartDataKey = 'cart_data';
  static const String shoppingListKey = 'shopping_list';

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 128;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;

  // Business Logic
  static const double taxRate = 8.0; // 8%
  static const int maxCartItems = 50;
  static const double deliveryFee = 50.0;
  static const double freeDeliveryThreshold = 1000.0;

  // Images
  static const String defaultImage = 'assets/image2.png';
  static const String defaultImageDark = 'assets/image2-dark.png';

  // Error Messages
  static const String networkError = 'Please check your internet connection';
  static const String serverError = 'Server is temporarily unavailable';
  static const String genericError = 'Something went wrong. Please try again';

  // Success Messages
  static const String loginSuccess = 'Login successful!';
  static const String registrationSuccess = 'Account created successfully!';
  static const String logoutSuccess = 'Logged out successfully!';
  static const String profileUpdateSuccess = 'Profile updated successfully!';

  // URLs
  static const String privacyPolicyUrl = 'https://scango.com/privacy';
  static const String termsOfServiceUrl = 'https://scango.com/terms';
  static const String supportEmail = 'support@scango.com';
}
