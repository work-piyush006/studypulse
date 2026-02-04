import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static Future<void> init() async {
    await _fcm.requestPermission();
  }

  static Future<void> instant({
    required String title,
    required String body,
    bool save = false,
  }) async {
    // FCM-only: server decide karega
  }

  static Future<void> cancelAll() async {}

  static Future<void> cancelDaily() async {}

  static Future<void> scheduleDaily(dynamic diff) async {}

  static Future<void> scheduleExamMorning(dynamic d) async {}

  static Future<void> examCompleted() async {}
}
