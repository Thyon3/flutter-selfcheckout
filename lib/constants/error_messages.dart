class ErrorMessages {
  // Authentication Errors
  static const String invalidEmail = 'Please enter a valid email address';
  static const String invalidPassword = 'Password must be at least 6 characters long';
  static const String emailAlreadyExists = 'An account with this email already exists';
  static const String invalidCredentials = 'Invalid email or password';
  static const String accountNotFound = 'Account not found';
  static const String accountDisabled = 'Your account has been disabled';
  static const String tooManyAttempts = 'Too many failed attempts. Please try again later';
  
  // Network Errors
  static const String networkError = 'Please check your internet connection';
  static const String serverError = 'Server is temporarily unavailable';
  static const String timeoutError = 'Request timed out. Please try again';
  static const String unknownError = 'Something went wrong. Please try again';
  
  // Validation Errors
  static const String requiredField = 'This field is required';
  static const String invalidFormat = 'Invalid format';
  static const String tooShort = 'Too short';
  static const String tooLong = 'Too long';
  static const String invalidNumber = 'Please enter a valid number';
  static const String invalidPrice = 'Please enter a valid price';
  static const String invalidQuantity = 'Please enter a valid quantity';
  static const String invalidBarcode = 'Please enter a valid barcode';
  static const String invalidWeight = 'Please enter a valid weight';
  
  // Payment Errors
  static const String paymentFailed = 'Payment failed. Please try again';
  static const String paymentCancelled = 'Payment was cancelled';
  static const String invalidPaymentMethod = 'Invalid payment method';
  static const String insufficientFunds = 'Insufficient funds';
  static const String cardDeclined = 'Card was declined';
  
  // Cart Errors
  static const String cartEmpty = 'Your cart is empty';
  static const String itemNotFound = 'Item not found';
  static const String outOfStock = 'Item is out of stock';
  static const String quantityExceeded = 'Quantity exceeds available stock';
  static const String cartLimitExceeded = 'Cart limit exceeded';
  
  // Barcode Scanning Errors
  static const String barcodeNotFound = 'Product not found for this barcode';
  static const String scanFailed = 'Failed to scan barcode';
  static const String cameraPermissionDenied = 'Camera permission denied';
  static const String scanTimeout = 'Scanning timed out';
  
  // General Errors
  static const String operationFailed = 'Operation failed';
  static const String accessDenied = 'Access denied';
  static const String forbidden = 'You don\'t have permission to perform this action';
  static const String notFound = 'Resource not found';
  static const String methodNotAllowed = 'Method not allowed';
  
  // Success Messages
  static const String loginSuccess = 'Login successful!';
  static const String registrationSuccess = 'Account created successfully!';
  static const String logoutSuccess = 'Logged out successfully!';
  static const String paymentSuccess = 'Payment successful!';
  static const String itemAdded = 'Item added to cart';
  static const String itemRemoved = 'Item removed from cart';
  static const String profileUpdated = 'Profile updated successfully!';
  static const String passwordChanged = 'Password changed successfully!';
  static const String settingsSaved = 'Settings saved successfully!';
  
  // Warning Messages
  static const String unsavedChanges = 'You have unsaved changes';
  static const String confirmDelete = 'Are you sure you want to delete?';
  static const String confirmLogout = 'Are you sure you want to logout?';
  static const String confirmClearCart = 'Are you sure you want to clear your cart?';
  static const String sessionExpiring = 'Your session is about to expire';
  
  // Info Messages
  static const String loading = 'Loading...';
  static const String processing = 'Processing...';
  static const String noData = 'No data available';
  static const String noResults = 'No results found';
  static const String emptyCart = 'Your cart is empty';
  static const String emptyList = 'No items in list';
}
