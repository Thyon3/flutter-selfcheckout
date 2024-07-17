import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:selfcheckoutapp/models/item.dart';
import 'package:selfcheckoutapp/services/firebase_services.dart';

class OfflineService {
  static const String _offlineQueueKey = 'offline_queue';
  static const String _offlineCartKey = 'offline_cart';
  static bool _isOnline = true;
  static final StreamController<bool> _connectivityController = 
      StreamController<bool>.broadcast();

  static Stream<bool> get connectivityStream => _connectivityController.stream;
  static bool get isOnline => _isOnline;

  static Future<void> initialize() async {
    // Check initial connectivity status
    await _checkConnectivity();
    
    // Process any pending operations when coming online
    connectivityStream.listen((isConnected) {
      if (isConnected) {
        _processOfflineQueue();
      }
    });
  }

  static Future<void> _checkConnectivity() async {
    try {
      // Simple connectivity check
      final firebaseServices = FirebaseServices();
      await firebaseServices.firestore.collection('test').limit(1).get();
      _setConnectivityStatus(true);
    } catch (e) {
      _setConnectivityStatus(false);
    }
  }

  static void _setConnectivityStatus(bool isOnline) {
    if (_isOnline != isOnline) {
      _isOnline = isOnline;
      _connectivityController.add(isOnline);
      print('Connectivity status changed: ${isOnline ? 'Online' : 'Offline'}');
    }
  }

  static Future<void> addToOfflineQueue({
    required String operation,
    required Map<String, dynamic> data,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueString = prefs.getString(_offlineQueueKey) ?? '[]';
      final queue = List<Map<String, dynamic>>.from(
        json.decode(queueString)
      );

      queue.add({
        'operation': operation,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      });

      await prefs.setString(_offlineQueueKey, json.encode(queue));
      print('Operation added to offline queue: $operation');
    } catch (e) {
      print('Failed to add to offline queue: $e');
    }
  }

  static Future<void> saveOfflineCart(List<Item> cartItems) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = cartItems.map((item) => item.toMap()).toList();
      await prefs.setString(_offlineCartKey, json.encode(cartData));
      print('Cart saved for offline use');
    } catch (e) {
      print('Failed to save offline cart: $e');
    }
  }

  static Future<List<Item>> getOfflineCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartString = prefs.getString(_offlineCartKey);
      
      if (cartString != null) {
        final cartData = List<Map<String, dynamic>>.from(
          json.decode(cartString)
        );
        return cartData.map((item) => Item.fromMap(item)).toList();
      }
      
      return [];
    } catch (e) {
      print('Failed to get offline cart: $e');
      return [];
    }
  }

  static Future<void> _processOfflineQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueString = prefs.getString(_offlineQueueKey) ?? '[]';
      final queue = List<Map<String, dynamic>>.from(
        json.decode(queueString)
      );

      if (queue.isEmpty) return;

      print('Processing offline queue: ${queue.length} operations');

      final firebaseServices = FirebaseServices();
      final processedOperations = <String>[];

      for (final operation in queue) {
        try {
          await _executeOperation(operation, firebaseServices);
          processedOperations.add(operation['id']);
        } catch (e) {
          print('Failed to execute operation ${operation['id']}: $e');
        }
      }

      // Remove processed operations from queue
      final remainingQueue = queue
          .where((op) => !processedOperations.contains(op['id']))
          .toList();

      await prefs.setString(_offlineQueueKey, json.encode(remainingQueue));
      print('Offline queue processed. Remaining: ${remainingQueue.length}');
    } catch (e) {
      print('Failed to process offline queue: $e');
    }
  }

  static Future<void> _executeOperation(
    Map<String, dynamic> operation,
    FirebaseServices firebaseServices,
  ) async {
    final opType = operation['operation'];
    final data = operation['data'];

    switch (opType) {
      case 'add_to_cart':
        await firebaseServices.usersCartRef
            .doc(firebaseServices.userId!)
            .collection('items')
            .add(data);
        break;
        
      case 'remove_from_cart':
        if (data['documentId'] != null) {
          await firebaseServices.usersCartRef
              .doc(firebaseServices.userId!)
              .collection('items')
              .doc(data['documentId'])
              .delete();
        }
        break;
        
      case 'save_purchase':
        await firebaseServices.usersCartHistoryRef
            .doc(firebaseServices.userId!)
            .collection('purchases')
            .add(data);
        break;
        
      case 'update_profile':
        await firebaseServices.usersRef
            .doc(firebaseServices.userId!)
            .update(data);
        break;
        
      default:
        print('Unknown operation type: $opType');
    }
  }

  static Future<void> clearOfflineData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_offlineQueueKey);
      await prefs.remove(_offlineCartKey);
      print('Offline data cleared');
    } catch (e) {
      print('Failed to clear offline data: $e');
    }
  }

  static Future<int> getOfflineQueueSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueString = prefs.getString(_offlineQueueKey) ?? '[]';
      final queue = List<Map<String, dynamic>>.from(
        json.decode(queueString)
      );
      return queue.length;
    } catch (e) {
      print('Failed to get offline queue size: $e');
      return 0;
    }
  }

  static void dispose() {
    _connectivityController.close();
  }
}
