import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'notification_store.dart';

class FCMService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static bool _initialized = false;

  /// Call ONLY after:
  /// - User authenticated
  /// - PermissionGate passed
  static Future<void> init() async {
    if (_initialized) return;

    // 🔐 Permission (Android 13+ safe)
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    log('🔔 FCM permission: ${settings.authorizationStatus}');

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      log('❌ FCM init aborted: user not logged in');
      return;
    }

    // 📲 Initial token
    final token = await _fcm.getToken();
    log('🔥 FCM TOKEN: $token');

    if (token != null) {
      await _saveToken(
        uid: user.uid,
        token: token,
        email: user.email,
        name: user.displayName,
      );
    }

    // 🔁 Token refresh
    _fcm.onTokenRefresh.listen((newToken) async {
      log('♻️ FCM TOKEN REFRESHED: $newToken');

      await _saveToken(
        uid: user.uid,
        token: newToken,
        email: user.email,
        name: user.displayName,
      );
    });

    // 📥 FOREGROUND MESSAGE
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      log('📩 Foreground FCM: ${message.data}');

      await _storeToInbox(message);
    });

    // 📲 BACKGROUND TAP
    FirebaseMessaging.onMessageOpenedApp
        .listen((RemoteMessage message) async {
      log('👉 Opened from notification (bg): ${message.data}');
      await _storeToInbox(message);
    });

    // 📲 TERMINATED TAP
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      log(
        '👉 Opened from notification (terminated): ${initialMessage.data}',
      );
      await _storeToInbox(initialMessage);
    }

    _initialized = true;
  }

  /* ================= INBOX ================= */

  static Future<void> _storeToInbox(RemoteMessage message) async {
    final data = message.data;

    final title =
        message.notification?.title ?? data['title'] ?? 'StudyPulse';
    final body =
        message.notification?.body ?? data['body'] ?? '';
    final route = data['route'] ?? '/';
    final type = data['type'] ?? 'normal';

    // 🔒 Silent / system messages
    if (type == 'silent') return;

    await NotificationStore.save(
      title: title,
      body: body,
      route: route,
      source: 'fcm',
    );
  }

  /* ================= FIRESTORE ================= */

  static Future<void> _saveToken({
    required String uid,
    required String token,
    String? email,
    String? name,
  }) async {
    await _db.collection('users').doc(uid).set(
      {
        'uid': uid,
        'email': email,
        'name': name,
        'fcmToken': token,
        'platform': Platform.operatingSystem,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /* ================= FUTURE HOOK ================= */

  /// Use this when:
  /// - Free tier exhausted
  /// - Notifications paused
  /// - Server down
  static Future<void> pushSystemBrokenNotice() async {
    await NotificationStore.save(
      title: 'Service temporarily unstable ⛓️‍💥',
      body:
          'We’re working hard to improve the system ❤️‍🩹',
      route: '/',
      source: 'system',
    );
  }
}
