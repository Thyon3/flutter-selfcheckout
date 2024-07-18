import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:selfcheckoutapp/models/item.dart';

class CacheService {
  static const String _cachePrefix = 'cache_';
  static const int _defaultTtl = 3600; // 1 hour in seconds
  static SharedPreferences? _prefs;

  static Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<void> set<T>({
    required String key,
    required T value,
    int? ttl,
  }) async {
    await initialize();
    
    final cacheKey = '$_cachePrefix$key';
    final expiryTime = DateTime.now().add(Duration(seconds: ttl ?? _defaultTtl));
    
    final cacheData = {
      'value': value,
      'expiry': expiryTime.toIso8601String(),
      'type': value.runtimeType.toString(),
    };
    
    await _prefs!.setString(cacheKey, json.encode(cacheData));
  }

  static Future<T?> get<T>(String key) async {
    await initialize();
    
    final cacheKey = '$_cachePrefix$key';
    final cacheString = _prefs!.getString(cacheKey);
    
    if (cacheString == null) return null;
    
    try {
      final cacheData = json.decode(cacheString);
      final expiry = DateTime.parse(cacheData['expiry']);
      
      if (DateTime.now().isAfter(expiry)) {
        await remove(key);
        return null;
      }
      
      return _deserialize<T>(cacheData['value'], cacheData['type']);
    } catch (e) {
      print('Error retrieving cache: $e');
      await remove(key);
      return null;
    }
  }

  static Future<void> remove(String key) async {
    await initialize();
    
    final cacheKey = '$_cachePrefix$key';
    await _prefs!.remove(cacheKey);
  }

  static Future<void> clear() async {
    await initialize();
    
    final keys = _prefs!.getKeys();
    for (final key in keys) {
      if (key.startsWith(_cachePrefix)) {
        await _prefs!.remove(key);
      }
    }
  }

  static Future<bool> exists(String key) async {
    await initialize();
    
    final cacheKey = '$_cachePrefix$key';
    return _prefs!.containsKey(cacheKey);
  }

  static Future<void> cacheCartItems(List<Item> items) async {
    await set(
      key: 'cart_items',
      value: items.map((item) => item.toMap()).toList(),
      ttl: 1800, // 30 minutes
    );
  }

  static Future<List<Item>> getCachedCartItems() async {
    final cachedData = await get<List<dynamic>>('cart_items');
    
    if (cachedData == null) return [];
    
    try {
      return cachedData
          .cast<Map<String, dynamic>>()
          .map((item) => Item.fromMap(item))
          .toList();
    } catch (e) {
      print('Error parsing cached cart items: $e');
      return [];
    }
  }

  static Future<void> cacheProductData(String barcode, Map<String, dynamic> productData) async {
    await set(
      key: 'product_$barcode',
      value: productData,
      ttl: 86400, // 24 hours
    );
  }

  static Future<Map<String, dynamic>?> getCachedProductData(String barcode) async {
    return await get<Map<String, dynamic>>('product_$barcode');
  }

  static Future<void> cacheUserPreferences(Map<String, dynamic> preferences) async {
    await set(
      key: 'user_preferences',
      value: preferences,
      ttl: 604800, // 7 days
    );
  }

  static Future<Map<String, dynamic>?> getCachedUserPreferences() async {
    return await get<Map<String, dynamic>>('user_preferences');
  }

  static Future<void> cacheSearchResults(String query, List<Map<String, dynamic>> results) async {
    await set(
      key: 'search_$query',
      value: results,
      ttl: 3600, // 1 hour
    );
  }

  static Future<List<Map<String, dynamic>>> getCachedSearchResults(String query) async {
    final cachedData = await get<List<dynamic>>('search_$query');
    
    if (cachedData == null) return [];
    
    try {
      return cachedData.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error parsing cached search results: $e');
      return [];
    }
  }

  static Future<void> cachePurchaseHistory(List<Map<String, dynamic>> history) async {
    await set(
      key: 'purchase_history',
      value: history,
      ttl: 1800, // 30 minutes
    );
  }

  static Future<List<Map<String, dynamic>>> getCachedPurchaseHistory() async {
    final cachedData = await get<List<dynamic>>('purchase_history');
    
    if (cachedData == null) return [];
    
    try {
      return cachedData.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error parsing cached purchase history: $e');
      return [];
    }
  }

  static Future<int> getCacheSize() async {
    await initialize();
    
    int size = 0;
    final keys = _prefs!.getKeys();
    
    for (final key in keys) {
      if (key.startsWith(_cachePrefix)) {
        final value = _prefs!.getString(key);
        if (value != null) {
          size += value.length;
        }
      }
    }
    
    return size;
  }

  static Future<void> cleanupExpiredCache() async {
    await initialize();
    
    final keys = _prefs!.getKeys();
    
    for (final key in keys) {
      if (key.startsWith(_cachePrefix)) {
        final cacheString = _prefs!.getString(key);
        if (cacheString != null) {
          try {
            final cacheData = json.decode(cacheString);
            final expiry = DateTime.parse(cacheData['expiry']);
            
            if (DateTime.now().isAfter(expiry)) {
              await _prefs!.remove(key);
            }
          } catch (e) {
            // Remove corrupted cache entries
            await _prefs!.remove(key);
          }
        }
      }
    }
  }

  static T _deserialize<T>(dynamic value, String type) {
    switch (type) {
      case 'String':
        return value as T;
      case 'int':
        return value as T;
      case 'double':
        return value as T;
      case 'bool':
        return value as T;
      case 'List<dynamic>':
        return value as T;
      case 'Map<String, dynamic>':
        return value as T;
      default:
        throw Exception('Unsupported type: $type');
    }
  }

  static Future<void> preloadCommonData() async {
    // Preload frequently accessed data
    await cleanupExpiredCache();
    
    // Cache empty search results to avoid repeated API calls
    await cacheSearchResults('', []);
    
    // Cache default user preferences
    await cacheUserPreferences({
      'theme': 'system',
      'notifications': true,
      'auto_backup': true,
    });
  }
}
