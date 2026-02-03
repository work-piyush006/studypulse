// lib/services/notification.dart
import 'dart:convert';
import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_store.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static const String _channelId = 'exam_channel_v2';

  static const int _id4pm = 4001;
  static const int _id11pm = 4002;
  static const int _examMorningId = 8001;
  static const int _examCompletedId = 8002;

  /* ================= PERMISSION ================= */

  static Future<bool> isGranted() async =>
      await Permission.notification.isGranted;

  /* ================= INIT ================= */

  static Future<void> init() async {
  if (_initialized) return;

  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

  const androidInit =
      AndroidInitializationSettings('ic_notification');

  await _plugin.initialize(
    const InitializationSettings(android: androidInit),
    onDidReceiveNotificationResponse: _onTap,
  );

  final android =
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  await android?.requestPermission(); // 🔥 MUST

  await android?.createNotificationChannel(
    const AndroidNotificationChannel(
      _channelId,
      'Exam Notifications',
      description: 'Exam reminders & alerts',
      importance: Importance.high,
    ),
  );

  _initialized = true;
}
  /* ================= TAP HANDLER ================= */

  static Future<void> _onTap(NotificationResponse r) async {
    if (r.payload == null) return;

    final data = jsonDecode(r.payload!);
    final prefs = await SharedPreferences.getInstance();

    if (data['save'] == true) {
      await NotificationStore.save(
        title: data['title'],
        body: data['body'],
        route: data['route'],
        time: data['time'],
      );
    }

    if (data['route'] != null) {
      await prefs.setString('notification_route', data['route']);
    }
  }

  /* ================= INSTANT ================= */

  static Future<void> instant({
    required String title,
    required String body,
    bool save = false,
    String? route,
  }) async {
    await init();
    if (!await isGranted()) return;

    final payload = jsonEncode({
      'title': title,
      'body': body,
      'route': route,
      'save': save,
      'time': DateTime.now().toIso8601String(),
    });

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Exam Notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification',
        ),
      ),
      payload: payload,
    );
  }

  /* ================= DAILY REMINDERS ================= */

  static Future<void> scheduleDaily(int daysLeft) async {
    await init();
    if (!await isGranted()) return;

    await cancelDaily();
    await _schedule(_id4pm, 16, daysLeft);
    await _schedule(_id11pm, 23, daysLeft);
  }

  static Future<void> _schedule(
    int id,
    int hour,
    int days,
  ) async {
    final now = tz.TZDateTime.now(tz.local);
    var t =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);

    if (t.isBefore(now)) {
      t = t.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      '📚 Study Reminder',
      '$days days left\n${_quote()}',
      t,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Exam Notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification',
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /* ================= EXAM DAY ================= */

  static Future<void> scheduleExamMorning(DateTime d) async {
    await init();
    if (!await isGranted()) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('exam_morning_done') == true) return;

    final t =
        tz.TZDateTime(tz.local, d.year, d.month, d.day, 6);

    if (t.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      _examMorningId,
      '🤞 Best of Luck!',
      'Today is your exam 💪📘',
      t,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Exam Notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification',
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    await prefs.setBool('exam_morning_done', true);
  }

  static Future<void> examCompleted() async {
    await init();
    if (!await isGranted()) return;

    await _plugin.show(
      _examCompletedId,
      '🎉 Exam Completed',
      'Any next exam left?\nStart preparing today 📘',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Exam Notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification',
        ),
      ),
    );
  }

  /* ================= CANCEL ================= */

  static Future<void> cancelDaily() async {
    if (!_initialized) return;
    await _plugin.cancel(_id4pm);
    await _plugin.cancel(_id11pm);
  }

  static Future<void> cancelAll() async {
    if (!_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('exam_morning_done');

    await cancelDaily();
    await _plugin.cancel(_examMorningId);
  }

  /* ================= UTIL ================= */

  static String _quote() {
    const q = [
      'Stay consistent 🚀',
      'Small steps daily 📘',
      'You are closer than you think 💪',
    ];
    return q[Random().nextInt(q.length)];
  }
}