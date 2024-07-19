import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService {
  static const String _localeKey = 'selected_locale';
  static Locale? _currentLocale;
  static final Map<String, Map<String, String>> _translations = {
    'en': {
      'app_title': 'ScanGo',
      'login': 'Login',
      'register': 'Register',
      'email': 'Email',
      'password': 'Password',
      'confirm_password': 'Confirm Password',
      'forgot_password': 'Forgot Password?',
      'create_account': 'Create Account',
      'already_have_account': 'Already have an account?',
      'shopping_cart': 'Shopping Cart',
      'scan_barcode': 'Scan Barcode',
      'add_to_cart': 'Add to Cart',
      'remove_from_cart': 'Remove from Cart',
      'total': 'Total',
      'checkout': 'Checkout',
      'payment': 'Payment',
      'history': 'History',
      'shopping_list': 'Shopping List',
      'profile': 'Profile',
      'settings': 'Settings',
      'logout': 'Logout',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'search': 'Search',
      'filter': 'Filter',
      'sort': 'Sort',
      'no_items_found': 'No items found',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'warning': 'Warning',
      'info': 'Information',
      'ok': 'OK',
      'yes': 'Yes',
      'no': 'No',
      'close': 'Close',
      'back': 'Back',
      'next': 'Next',
      'previous': 'Previous',
      'home': 'Home',
      'menu': 'Menu',
      'notifications': 'Notifications',
      'help': 'Help',
      'about': 'About',
      'version': 'Version',
      'language': 'Language',
      'theme': 'Theme',
      'light_theme': 'Light Theme',
      'dark_theme': 'Dark Theme',
      'system_theme': 'System Theme',
      'auto_backup': 'Auto Backup',
      'notifications_enabled': 'Notifications Enabled',
      'biometric_login': 'Biometric Login',
      'change_password': 'Change Password',
      'update_profile': 'Update Profile',
      'cart_empty': 'Your cart is empty',
      'scan_product': 'Scan a product to add to cart',
      'total_items': 'Total Items',
      'total_price': 'Total Price',
      'proceed_to_payment': 'Proceed to Payment',
      'payment_method': 'Payment Method',
      'new_card': 'New Card',
      'saved_cards': 'Saved Cards',
      'cash_on_delivery': 'Cash on Delivery',
      'order_placed': 'Order placed successfully!',
      'order_failed': 'Failed to place order',
      'invalid_email': 'Please enter a valid email',
      'password_too_short': 'Password must be at least 6 characters',
      'passwords_do_not_match': 'Passwords do not match',
      'login_failed': 'Login failed',
      'registration_failed': 'Registration failed',
      'network_error': 'Network error. Please try again.',
      'server_error': 'Server error. Please try again later.',
      'unknown_error': 'An unknown error occurred',
    },
    'si': {
      'app_title': 'ස්කෑන්ගෝ',
      'login': 'පිවිසෙන්න',
      'register': 'ලියාපදිංචි වන්න',
      'email': 'විද්යුත් තැපැල්',
      'password': 'මුරපදය',
      'confirm_password': 'මුරපදය තහවුරු කරන්න',
      'forgot_password': 'මුරපදය අමතකද?',
      'create_account': 'ගිණුමක් සාදන්න',
      'already_have_account': 'දැනටමත් ගිණුමක් තිබේද?',
      'shopping_cart': 'මිලදී ගැනීමේ කරත්තය',
      'scan_barcode': 'බාර්කෝඩ් ස්කෑන් කරන්න',
      'add_to_cart': 'කරත්තයට එකතු කරන්න',
      'remove_from_cart': 'කරත්තයෙන් ඉවත් කරන්න',
      'total': 'එකතුව',
      'checkout': 'ගෙවීම',
      'payment': 'ගෙවීම',
      'history': 'ඉතිහාසය',
      'shopping_list': 'මිලදී ගැනීමේ ලැයිස්තුව',
      'profile': 'පැතිකඩ',
      'settings': 'සැකසීම්',
      'logout': 'පිටවීම',
      'cancel': 'අවලංගු කරන්න',
      'save': 'සුරකින්න',
      'delete': 'මකන්න',
      'edit': 'සංස්කරණය',
      'search': 'සෙවීම',
      'filter': 'පෙරහන',
      'sort': 'වර්ග කරන්න',
      'no_items_found': 'අයිතම හමු වූයේ නැත',
      'loading': 'පූරණය වෙමින්...',
      'error': 'දෝෂය',
      'success': 'සාර්ථකයි',
      'warning': 'අවවාදය',
      'info': 'තොරතුරු',
      'ok': 'හරි',
      'yes': 'ඔව්',
      'no': 'නෑ',
      'close': 'වහන්න',
      'back': 'ආපසු',
      'next': 'ඊළඟ',
      'previous': 'පෙර',
      'home': 'මුල',
      'menu': 'මෙනුව',
      'notifications': 'දැනුම්දීම්',
      'help': 'උපකාර',
      'about': 'පිළිබඳව',
      'version': 'අනුවාදය',
      'language': 'භාෂාව',
      'theme': 'තේමාව',
      'light_theme': 'ලා තේමාව',
      'dark_theme': 'අඳුරු තේමාව',
      'system_theme': 'පද්ධති තේමාව',
      'auto_backup': 'ස්වයං උපසුර',
      'notifications_enabled': 'දැනුම්දීම් සබලයි',
      'biometric_login': 'ජෛවමිතික පිවිසීම',
      'change_password': 'මුරපදය වෙනස් කරන්න',
      'update_profile': 'පැතිකඩ යාවත්කාලීන කරන්න',
      'cart_empty': 'ඔබගේ කරත්තය හිස්ය',
      'scan_product': 'කරත්තයට එකතු කිරීමට නිෂ්පාදනය ස්කෑන් කරන්න',
      'total_items': 'එකතු අයිතම',
      'total_price': 'එකතු මිල',
      'proceed_to_payment': 'ගෙවීමට පෙරටවන්න',
      'payment_method': 'ගෙවීම් ක්රමය',
      'new_card': 'නව කාඩ්පත',
      'saved_cards': 'සුරකින ලද කාඩ්පත්',
      'cash_on_delivery': 'බෙදාහැරීමේදී මුදල්',
      'order_placed': 'ඇණවුම සාර්ථකව තැබුණි!',
      'order_failed': 'ඇණවුම තැබීම අසාර්ථකයි',
      'invalid_email': 'වලංගු විද්යුත් තැපැල් ලිපිනයක් ඇතුළත් කරන්න',
      'password_too_short': 'මුරපදය අවම වශයෙන් අක්ෂර 6 ක් විය යුතුය',
      'passwords_do_not_match': 'මුරපද නොගැලපේ',
      'login_failed': 'පිවිසීම අසාර්ථකයි',
      'registration_failed': 'ලියාපදිංචිය අසාර්ථකයි',
      'network_error': 'ජාල දෝෂය. කරුණාකර නැවත උත්සාහ කරන්න.',
      'server_error': 'සේවාදායක දෝෂය. කරුණාකර පසුව උත්සාහ කරන්න.',
      'unknown_error': 'නොදන්නා දෝෂයක් සිදුවිය',
    },
  };

  static Future<void> initialize() async {
    final savedLocale = await getSavedLocale();
    _currentLocale = savedLocale ?? const Locale('en');
  }

  static Future<Locale?> getSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localeCode = prefs.getString(_localeKey);
      
      if (localeCode != null) {
        return Locale(localeCode);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> setLocale(Locale locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, locale.languageCode);
      _currentLocale = locale;
    } catch (e) {
      // Handle error
    }
  }

  static Locale get currentLocale => _currentLocale ?? const Locale('en');

  static List<Locale> get supportedLocales => [
    const Locale('en'),
    const Locale('si'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static String translate(String key) {
    final locale = _currentLocale?.languageCode ?? 'en';
    final translations = _translations[locale] ?? _translations['en']!;
    return translations[key] ?? key;
  }

  static bool isRTL() {
    return false; // Both English and Sinhala are LTR
  }

  static String get currentLanguageCode => _currentLocale?.languageCode ?? 'en';

  static Future<void> resetToDefault() async {
    await setLocale(const Locale('en'));
  }
}

class AppLocalizations {
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  // Convenience getters
  String get appTitle => LocalizationService.translate('app_title');
  String get login => LocalizationService.translate('login');
  String get register => LocalizationService.translate('register');
  String get email => LocalizationService.translate('email');
  String get password => LocalizationService.translate('password');
  String get confirmPassword => LocalizationService.translate('confirm_password');
  String get forgotPassword => LocalizationService.translate('forgot_password');
  String get createAccount => LocalizationService.translate('create_account');
  String get alreadyHaveAccount => LocalizationService.translate('already_have_account');
  String get shoppingCart => LocalizationService.translate('shopping_cart');
  String get scanBarcode => LocalizationService.translate('scan_barcode');
  String get addToCart => LocalizationService.translate('add_to_cart');
  String get removeFromCart => LocalizationService.translate('remove_from_cart');
  String get total => LocalizationService.translate('total');
  String get checkout => LocalizationService.translate('checkout');
  String get payment => LocalizationService.translate('payment');
  String get history => LocalizationService.translate('history');
  String get shoppingList => LocalizationService.translate('shopping_list');
  String get profile => LocalizationService.translate('profile');
  String get settings => LocalizationService.translate('settings');
  String get logout => LocalizationService.translate('logout');
  String get cancel => LocalizationService.translate('cancel');
  String get save => LocalizationService.translate('save');
  String get delete => LocalizationService.translate('delete');
  String get edit => LocalizationService.translate('edit');
  String get search => LocalizationService.translate('search');
  String get filter => LocalizationService.translate('filter');
  String get sort => LocalizationService.translate('sort');
  String get noItemsFound => LocalizationService.translate('no_items_found');
  String get loading => LocalizationService.translate('loading');
  String get error => LocalizationService.translate('error');
  String get success => LocalizationService.translate('success');
  String get warning => LocalizationService.translate('warning');
  String get info => LocalizationService.translate('info');
  String get ok => LocalizationService.translate('ok');
  String get yes => LocalizationService.translate('yes');
  String get no => LocalizationService.translate('no');
  String get close => LocalizationService.translate('close');
  String get back => LocalizationService.translate('back');
  String get next => LocalizationService.translate('next');
  String get previous => LocalizationService.translate('previous');
  String get home => LocalizationService.translate('home');
  String get menu => LocalizationService.translate('menu');
  String get notifications => LocalizationService.translate('notifications');
  String get help => LocalizationService.translate('help');
  String get about => LocalizationService.translate('about');
  String get version => LocalizationService.translate('version');
  String get language => LocalizationService.translate('language');
  String get theme => LocalizationService.translate('theme');
  String get lightTheme => LocalizationService.translate('light_theme');
  String get darkTheme => LocalizationService.translate('dark_theme');
  String get systemTheme => LocalizationService.translate('system_theme');
  String get autoBackup => LocalizationService.translate('auto_backup');
  String get notificationsEnabled => LocalizationService.translate('notifications_enabled');
  String get biometricLogin => LocalizationService.translate('biometric_login');
  String get changePassword => LocalizationService.translate('change_password');
  String get updateProfile => LocalizationService.translate('update_profile');
  String get cartEmpty => LocalizationService.translate('cart_empty');
  String get scanProduct => LocalizationService.translate('scan_product');
  String get totalItems => LocalizationService.translate('total_items');
  String get totalPrice => LocalizationService.translate('total_price');
  String get proceedToPayment => LocalizationService.translate('proceed_to_payment');
  String get paymentMethod => LocalizationService.translate('payment_method');
  String get newCard => LocalizationService.translate('new_card');
  String get savedCards => LocalizationService.translate('saved_cards');
  String get cashOnDelivery => LocalizationService.translate('cash_on_delivery');
  String get orderPlaced => LocalizationService.translate('order_placed');
  String get orderFailed => LocalizationService.translate('order_failed');
  String get invalidEmail => LocalizationService.translate('invalid_email');
  String get passwordTooShort => LocalizationService.translate('password_too_short');
  String get passwordsDoNotMatch => LocalizationService.translate('passwords_do_not_match');
  String get loginFailed => LocalizationService.translate('login_failed');
  String get registrationFailed => LocalizationService.translate('registration_failed');
  String get networkError => LocalizationService.translate('network_error');
  String get serverError => LocalizationService.translate('server_error');
  String get unknownError => LocalizationService.translate('unknown_error');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return LocalizationService.supportedLocales
        .any((supportedLocale) => supportedLocale.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    await LocalizationService.setLocale(locale);
    return AppLocalizations();
  }

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) => false;
}
