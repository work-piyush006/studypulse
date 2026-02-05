import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> syncUserToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    await _db.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'name': user.displayName,
      'fcmToken': token,
      'platform': Platform.operatingSystem,
      'lastLogin': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
