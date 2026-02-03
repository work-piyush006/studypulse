import 'dart:developer';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FCMService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    // 🔔 Android notification channel
    const androidChannel = AndroidNotificationChannel(
      'fcm_default',
      'FCM Notifications',
      description: 'StudyPulse notifications',
      importance: Importance.high,
    );

    const androidInit =
        AndroidInitializationSettings('ic_notification');

    await _local.initialize(
      const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: _onTap,
    );

    final androidImpl =
        _local.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImpl?.createNotificationChannel(androidChannel);

    // 🔐 Permission (Android 13+)
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    log('FCM permission: ${settings.authorizationStatus}');

    // 📲 TOKEN (proof FCM working)
    final token = await _fcm.getToken();
    log('🔥 FCM TOKEN: $token');

    // 📥 FOREGROUND MESSAGE → SHOW LOCAL NOTIFICATION
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final n = message.notification;
      if (n == null) return;

      _local.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        n.title,
        n.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'fcm_default',
            'FCM Notifications',
            importance: Importance.high,
            priority: Priority.high,
            icon: 'ic_notification',
          ),
        ),
        payload: jsonEncode(message.data),
      );
    });

    // 📲 TAP WHEN APP IN BACKGROUND
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      log('👉 Opened from notification');
    });

    _initialized = true;
  }

  static void _onTap(NotificationResponse response) {
    log('🔔 Notification tapped: ${response.payload}');
  }
}