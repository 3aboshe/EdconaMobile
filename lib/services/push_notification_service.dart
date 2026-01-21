import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'api_service.dart';

// Top-level background message handler (required for background notifications)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) print('Handling background message: ${message.messageId}');
}

class PushNotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'edcona_notifications', // Same as in AndroidManifest.xml
    'EdCona Notifications',
    description: 'Educational notifications from EdCona',
    importance: Importance.max,
    playSound: true,
  );

  static Future<void> initialize() async {
    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // 1. Request Permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: true,
      carPlay: false,
      criticalAlert: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) print('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      if (kDebugMode) print('User granted provisional permission');
    } else {
      if (kDebugMode) print('User declined or has not accepted permission');
      // Even if declined, we continue initialization so the app doesn't crash
    }

    // 2. Initialize Local Notifications (for Foreground)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS setup with permissions requested during initialization
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (kDebugMode) print('Notification clicked with payload: ${response.payload}');
        // Handle notification tap logic here
      },
    );

    // Create Android notification channel
    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Set foreground notification presentation options for iOS
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3. Listen for Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) print('Foreground message received: ${message.notification?.title}');
      
      // If the message has a notification payload, show it locally
      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) print('Notification clicked (background/terminated): ${message.data}');
      // Handle navigation here if needed
    });
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    // Android specifics
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    
    // iOS specifics
    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    await _localNotificationsPlugin.show(
      message.hashCode, // Unique ID for notification
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }

  static Future<void> updateToken({String? language}) async {
    try {
      // For iOS, we need to ensure APNs token is available before getting FCM token
      if (Platform.isIOS) {
        String? apnsToken = await _fcm.getAPNSToken();
        if (apnsToken == null) {
          if (kDebugMode) print('Wait for APNs token...');
          await Future.delayed(const Duration(seconds: 1));
          apnsToken = await _fcm.getAPNSToken();
        }
        if (kDebugMode) print('APNs Token: $apnsToken');
      }

      String? token = await _fcm.getToken();
      if (token != null) {
        if (kDebugMode) print('FCM Token: $token');
        await ApiService.dio.post('/api/auth/fcm-token', data: {
          'token': token,
          'language': language ?? 'en',
        });
      } else {
        if (kDebugMode) print('Failed to get FCM token');
      }
    } catch (e) {
      if (kDebugMode) print('Error updating FCM token: $e');
    }
  }
}
