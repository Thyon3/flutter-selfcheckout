import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class OfflineService {
  static Future<bool> hasConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult.contains(ConnectivityResult.mobile) ||
           connectivityResult.contains(ConnectivityResult.wifi);
  }

  static Future<void> cacheDataForOffline() async {
    // Implementation would cache necessary data for offline use
    // Store user preferences, cart items, etc.
  }

  static Future<void> syncWhenOnline() async {
    // Implementation would sync cached data when connection is restored
    while (await hasConnection()) {
      // Sync logic here
      await Future.delayed(Duration(seconds: 2));
    }
  }
}
