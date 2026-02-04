import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static Future<void> init() async {
    await _fcm.requestPermission();
  }

  /// FCM se aane wali notification
  static void handleRemote(RemoteMessage message) {
    // abhi sirf receive
    // future: routing / analytics / inbox
  }

  // ---- EXISTING CALLS KE LIYE SAFE METHODS ----
  static Future<void> instant({
    required String title,
    required String body,
  }) async {}

  static Future<void> cancelAll() async {}
  static Future<void> cancelDaily() async {}
  static Future<void> scheduleDaily(Duration diff) async {}
  static Future<void> scheduleExamMorning(DateTime d) async {}
  static Future<void> examCompleted() async {}
}
