class ApiEndpoints {
  static const String baseUrl = 'https://api.scango.com';
  
  // Authentication
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String logout = '$baseUrl/auth/logout';
  static const String refreshToken = '$baseUrl/auth/refresh';
  
  // User Management
  static const String getUserProfile = '$baseUrl/user/profile';
  static const String updateUserProfile = '$baseUrl/user/profile';
  static const String changePassword = '$baseUrl/user/change-password';
  
  // Products
  static const String getProducts = '$baseUrl/products';
  static const String getProductById = '$baseUrl/products';
  static const String searchProducts = '$baseUrl/products/search';
  static const String getProductByBarcode = '$baseUrl/products/barcode';
  
  // Shopping Cart
  static const String getCart = '$baseUrl/cart';
  static const String addToCart = '$baseUrl/cart/add';
  static const String updateCartItem = '$baseUrl/cart/update';
  static const String removeFromCart = '$baseUrl/cart/remove';
  static const String clearCart = '$baseUrl/cart/clear';
  
  // Shopping List
  static const String getShoppingLists = '$baseUrl/shopping-lists';
  static const String createShoppingList = '$baseUrl/shopping-lists';
  static const String updateShoppingList = '$baseUrl/shopping-lists';
  static const String deleteShoppingList = '$baseUrl/shopping-lists';
  
  // Orders
  static const String getOrders = '$baseUrl/orders';
  static const String createOrder = '$baseUrl/orders';
  static const String getOrderById = '$baseUrl/orders';
  
  // Payments
  static const String processPayment = '$baseUrl/payments/process';
  static const String getPaymentMethods = '$baseUrl/payments/methods';
  static const String addPaymentMethod = '$baseUrl/payments/methods';
  
  // Analytics
  static const String trackEvent = '$baseUrl/analytics/events';
  static const String trackUserActivity = '$baseUrl/analytics/activity';
  
  // Notifications
  static const String registerDevice = '$baseUrl/notifications/register';
  static const String unregisterDevice = '$baseUrl/notifications/unregister';
  static const String getNotifications = '$baseUrl/notifications';
  
  // Settings
  static const String getUserSettings = '$baseUrl/settings';
  static const String updateUserSettings = '$baseUrl/settings';
  
  // Support
  static const String submitFeedback = '$baseUrl/support/feedback';
  static const String reportIssue = '$baseUrl/support/issues';
  static const String getFAQ = '$baseUrl/support/faq';
}
