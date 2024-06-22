import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BackupService {
  static const String _cartKey = 'shopping_cart_backup';
  static const String _historyKey = 'purchase_history_backup';

  static Future<void> backupCart(List<Map<String, dynamic>> cartItems) async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = jsonEncode(cartItems);
    await prefs.setString(_cartKey, cartJson);
  }

  static Future<void> backupHistory(List<Map<String, dynamic>> historyItems) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = jsonEncode(historyItems);
    await prefs.setString(_historyKey, historyJson);
  }

  static Future<List<Map<String, dynamic>>? restoreCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = prefs.getString(_cartKey);
    if (cartJson != null) {
      final List<dynamic> cartList = jsonDecode(cartJson);
      return cartList.cast<Map<String, dynamic>>();
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>? restoreHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey);
    if (historyJson != null) {
      final List<dynamic> historyList = jsonDecode(historyJson);
      return historyList.cast<Map<String, dynamic>>();
    }
    return null;
  }

  static Future<void> clearBackup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartKey);
    await prefs.remove(_historyKey);
  }
}
