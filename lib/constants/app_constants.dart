class AppConstants {
  // App Information
  static const String appName = 'ScanGo';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Self-Checkout Mobile Application';
  
  // Colors
  static const int primaryColorValue = 0xff1faa00;
  static const int accentColorValue = 0xffD50000;
  static const Color backgroundColor = Color(0xfff5f5f5);
  static const Color cardColor = Colors.white;
  
  // Dimensions
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  
  // Animation Durations
  static const int shortAnimationMs = 200;
  static const int mediumAnimationMs = 300;
  static const int longAnimationMs = 500;
  
  // Text Styles
  static const double titleFontSize = 22.0;
  static const double subtitleFontSize = 18.0;
  static const double bodyFontSize = 16.0;
  static const double captionFontSize = 14.0;
  
  // API Configuration
  static const String apiBaseUrl = 'https://api.scango.com';
  static const Duration apiTimeout = Duration(seconds: 30);
  
  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userPreferencesKey = 'user_preferences';
  static const String cartDataKey = 'cart_data';
  
  // Validation Rules
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 128;
  static const int maxNameLength = 50;
  static const int maxEmailLength = 254;
  
  // Business Logic
  static const double taxRate = 8.0; // 8% tax
  static const int maxCartItems = 50;
  static const double maxItemPrice = 999999.99;
  
  // Session Management
  static const int sessionTimeoutMinutes = 30;
  static const int activityTimeoutMinutes = 5;
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // File Upload
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png', 'gif'];
  
  // Error Messages
  static const String genericErrorMessage = 'Something went wrong. Please try again.';
  static const String networkErrorMessage = 'Please check your internet connection.';
  static const String serverErrorMessage = 'Server is temporarily unavailable.';
  
  // Success Messages
  static const String loginSuccessMessage = 'Login successful!';
  static const String registrationSuccessMessage = 'Account created successfully!';
  static const String logoutSuccessMessage = 'Logged out successfully!';
  
  // Feature Flags
  static const bool enableBiometricAuth = true;
  static const bool enableDarkMode = true;
  static const bool enableNotifications = true;
  static const bool enableAnalytics = true;
}
