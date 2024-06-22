import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final StreamController<ConnectivityResult> _connectivityController = 
      StreamController<ConnectivityResult>.broadcast();
  Stream<ConnectivityResult> get connectivityStream => 
      _connectivityController.stream;

  ConnectivityResult _currentResult = ConnectivityResult.none;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _currentResult = await Connectivity().checkConnectivity();
      _connectivityController.add(_currentResult);
      
      Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
        _currentResult = result;
        _connectivityController.add(result);
      });
      
      _isInitialized = true;
    } catch (e) {
      print('Error initializing connectivity service: $e');
    }
  }

  bool get isConnected {
    return _currentResult != ConnectivityResult.none;
  }

  bool get isWifiConnected {
    return _currentResult == ConnectivityResult.wifi;
  }

  bool get isMobileConnected {
    return _currentResult == ConnectivityResult.mobile;
  }

  String get connectionStatus {
    switch (_currentResult) {
      case ConnectivityResult.wifi:
        return 'Connected to WiFi';
      case ConnectivityResult.mobile:
        return 'Connected to Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Connected to Ethernet';
      case ConnectivityResult.bluetooth:
        return 'Connected to Bluetooth';
      case ConnectivityResult.none:
        return 'No Internet Connection';
      default:
        return 'Unknown Connection Status';
    }
  }

  Future<bool> waitForConnection({Duration timeout = const Duration(seconds: 10)}) async {
    if (isConnected) return true;

    final completer = Completer<bool>();
    late StreamSubscription subscription;

    subscription = connectivityStream.listen((result) {
      if (result != ConnectivityResult.none) {
        subscription.cancel();
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      }
    });

    // Set timeout
    Timer(timeout, () {
      subscription.cancel();
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });

    return completer.future;
  }

  void dispose() {
    _connectivityController.close();
  }

  static void showConnectivityError(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.red),
            SizedBox(width: 8),
            Text('No Internet Connection'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please check your internet connection and try again.'),
            SizedBox(height: 16),
            Text('Current Status: ${ConnectivityService().connectionStatus}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
