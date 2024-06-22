import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationHandler {
  static final PushNotificationHandler _instance = PushNotificationHandler._internal();
  factory PushNotificationHandler() => _instance;
  PushNotificationHandler._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  void handleNotification(RemoteMessage message) {
    final notification = message.notification;
    
    if (notification != null) {
      switch (notification.title) {
        case 'New Item Added':
          _navigateToCart();
          break;
        case 'Payment Reminder':
          _navigateToPayment();
          break;
        case 'Shopping List Update':
          _navigateToShoppingList();
          break;
        default:
          _navigateToHome();
      }
    }
  }

  void _navigateToCart() {
    navigatorKey.currentState?.pushNamed('/cart');
  }

  void _navigateToPayment() {
    navigatorKey.currentState?.pushNamed('/payment');
  }

  void _navigateToShoppingList() {
    navigatorKey.currentState?.pushNamed('/shopping-list');
  }

  void _navigateToHome() {
    navigatorKey.currentState?.pushNamed('/home');
  }
}
