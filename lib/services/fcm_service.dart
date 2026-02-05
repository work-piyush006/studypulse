import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FCMService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static bool _initialized = false;

  /// Call ONLY after:
  /// - User authenticated (Google)
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

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      log('❌ FCM init aborted: user not logged in');
      return;
    }

    // 📲 Initial token
    final token = await _fcm.getToken();
    log('🔥 FCM TOKEN: $token');

    if (token != null) {
      await _saveTokenToFirestore(
        uid: user.uid,
        token: token,
        email: user.email,
        name: user.displayName,
      );
    }

    // 🔁 Token refresh (CRITICAL)
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      log('♻️ FCM TOKEN REFRESHED: $newToken');

      await _saveTokenToFirestore(
        uid: user.uid,
        token: newToken,
        email: user.email,
        name: user.displayName,
      );
    });

    // 📥 Foreground message (NO local notification)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('📩 Foreground FCM: ${message.data}');
      // in-app handling only
    });

    // 📲 Notification tap (background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('👉 Opened from notification (bg): ${message.data}');
      // TODO: navigation by payload
    });

    // 📲 Notification tap (terminated)
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      log(
        '👉 Opened from notification (terminated): ${initialMessage.data}',
      );
      // TODO: navigation by payload
    }

    _initialized = true;
  }

  /* ================= FIRESTORE ================= */

  static Future<void> _saveTokenToFirestore({
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
}
