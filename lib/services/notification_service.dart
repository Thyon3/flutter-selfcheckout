import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Request permission
    await _requestPermission();
    
    // Get token
    final token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');
    
    // Configure foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Configure background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> _requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    
    print('Permission granted: ${settings.authorizationStatus}');
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.notification?.title}');
    // Show in-app notification
  }

  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print('Background message received: ${message.notification?.title}');
  }
}
