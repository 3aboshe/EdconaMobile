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

  // Store language for token refresh callback
  static String? _currentLanguage;

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
    // Store language for token refresh callback
    _currentLanguage = language;

    try {
      // For iOS, we need to ensure APNs token is available before getting FCM token
      if (Platform.isIOS) {
        String? apnsToken = await _fcm.getAPNSToken();

        // Wait up to 30 seconds for APNs token with exponential backoff
        if (apnsToken == null) {
          if (kDebugMode) print('⏳ Waiting for APNs token...');
          int attempts = 0;
          const maxAttempts = 10;

          while (apnsToken == null && attempts < maxAttempts) {
            await Future.delayed(Duration(seconds: 3));
            apnsToken = await _fcm.getAPNSToken();
            attempts++;

            if (kDebugMode) {
              print('   Attempt $attempts/$maxAttempts: APNs Token ${apnsToken != null ? "✅ received" : "⏳ still waiting..."}');
            }

            if (apnsToken != null) break;
          }

          if (apnsToken == null) {
            if (kDebugMode) {
              print('❌ APNs Token not received after $maxAttempts attempts');
              print('   Possible causes:');
              print('   - Device is offline (check internet connection)');
              print('   - APNs certificate mismatch (development vs production)');
              print('   - App notification permission denied');
              print('   - Check Xcode console for detailed error logs');
            }
            return; // Exit gracefully - token may arrive later via onTokenRefresh
          }
        }

        if (kDebugMode) print('✅ APNs Token received: ${apnsToken.substring(0, 8)}...');
      }

      String? token = await _fcm.getToken();
      if (token != null) {
        if (kDebugMode) print('✅ FCM Token: ${token.substring(0, 20)}...');
        await ApiService.dio.post('/api/auth/fcm-token', data: {
          'token': token,
          'language': language ?? 'en',
        });
        if (kDebugMode) print('✅ Token registered with backend');
      } else {
        if (kDebugMode) print('❌ Failed to get FCM token');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error updating FCM token: $e');
    }
  }

  /// Set up token refresh listener for iOS APNs token arrival
  static void listenToTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      if (kDebugMode) print('🔄 FCM Token refreshed: ${newToken.substring(0, 20)}...');
      // Send new token to backend with stored language
      ApiService.dio.post('/api/auth/fcm-token', data: {
        'token': newToken,
        'language': _currentLanguage ?? 'en',
      }).catchError((e) {
        if (kDebugMode) print('❌ Error sending refreshed token: $e');
      });
    });
  }

  /// Update the stored language for token refresh callback
  static void updateLanguage(String language) {
    _currentLanguage = language;
  }
}
