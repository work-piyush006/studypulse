import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';

class FCMService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static bool _initialized = false;

  /// Call this ONLY after:
  /// - App UI loaded
  /// - User authenticated
  /// - PermissionGate passed
  static Future<void> init() async {
    if (_initialized) return;

    // 🔐 Ask notification permission (Android 13+ safe)
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    log('🔔 FCM permission: ${settings.authorizationStatus}');

    // 📲 Get FCM token
    final token = await _fcm.getToken();
    log('🔥 FCM TOKEN: $token');

    // TODO: send token to backend with UID

    // 📥 Foreground message (NO local notification)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('📩 Foreground FCM: ${message.data}');
      // UI decide karegi kya karna hai
    });

    // 📲 Notification tap (background / terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('👉 Opened from notification: ${message.data}');
    });

    _initialized = true;
  }
}