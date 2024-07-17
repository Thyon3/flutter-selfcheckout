import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:selfcheckoutapp/models/item.dart';
import 'package:selfcheckoutapp/services/firebase_services.dart';

class BackupService {
  static const String _backupKey = 'data_backup';
  static const String _lastBackupKey = 'last_backup_time';

  static Future<void> saveData({
    required List<Item> cartItems,
    required List<Map<String, dynamic>> purchaseHistory,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupData = {
        'cart_items': cartItems.map((item) => item.toMap()).toList(),
        'purchase_history': purchaseHistory,
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0.0',
      };

      await prefs.setString(_backupKey, json.encode(backupData));
      await prefs.setString(_lastBackupKey, DateTime.now().toIso8601String());
      
      print('Backup saved successfully');
    } catch (e) {
      print('Failed to save backup: $e');
    }
  }

  static Future<Map<String, dynamic>?> loadBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupString = prefs.getString(_backupKey);
      
      if (backupString != null) {
        return json.decode(backupString);
      }
      
      return null;
    } catch (e) {
      print('Failed to load backup: $e');
      return null;
    }
  }

  static Future<String?> getLastBackupTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastBackupKey);
    } catch (e) {
      print('Failed to get last backup time: $e');
      return null;
    }
  }

  static Future<void> restoreBackup({
    required Function(List<Item>) onCartRestored,
    required Function(List<Map<String, dynamic>>) onHistoryRestored,
  }) async {
    try {
      final backupData = await loadBackup();
      
      if (backupData != null) {
        final cartItems = (backupData['cart_items'] as List?)
            ?.map((item) => Item.fromMap(item))
            .toList() ?? [];
        
        final purchaseHistory = (backupData['purchase_history'] as List?)
            ?.cast<Map<String, dynamic>>()
            .toList() ?? [];

        onCartRestored(cartItems);
        onHistoryRestored(purchaseHistory);

        print('Backup restored successfully');
      } else {
        print('No backup found');
      }
    } catch (e) {
      print('Failed to restore backup: $e');
    }
  }

  static Future<void> syncWithFirebase({
    required List<Item> cartItems,
    required List<Map<String, dynamic>> purchaseHistory,
  }) async {
    try {
      final firebaseServices = FirebaseServices();
      
      // Save cart items to Firebase
      for (final item in cartItems) {
        await firebaseServices.usersCartRef
            .doc(firebaseServices.userId!)
            .collection('items')
            .add(item.toMap());
      }
      
      // Save purchase history to Firebase
      for (final purchase in purchaseHistory) {
        await firebaseServices.usersCartHistoryRef
            .doc(firebaseServices.userId!)
            .collection('purchases')
            .add({
              ...purchase,
              'timestamp': DateTime.now(),
            });
      }
      
      print('Data synchronized with Firebase');
    } catch (e) {
      print('Failed to sync with Firebase: $e');
    }
  }

  static Future<void> clearBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_backupKey);
      await prefs.remove(_lastBackupKey);
      
      print('Backup cleared');
    } catch (e) {
      print('Failed to clear backup: $e');
    }
  }

  static Future<bool> hasBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_backupKey);
    } catch (e) {
      print('Failed to check backup status: $e');
      return false;
    }
  }

  static Future<void> scheduleAutoBackup() async {
    final lastBackupTime = await getLastBackupTime();
    
    if (lastBackupTime != null) {
      final lastBackup = DateTime.parse(lastBackupTime);
      final now = DateTime.now();
      final daysSinceLastBackup = now.difference(lastBackup).inDays;
      
      // Auto-backup every 7 days
      if (daysSinceLastBackup >= 7) {
        await saveData(
          cartItems: [],
          purchaseHistory: [],
        );
      }
    }
  }
}
