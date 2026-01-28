import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_store.dart';
import '../screens/notification_inbox.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static late GlobalKey<NavigatorState> _navKey;
  static bool _initialized = false;

  /// 🚀 INIT (ONLY ONCE)
  static Future<void> init(GlobalKey<NavigatorState> navKey) async {
    if (_initialized) return;
    _navKey = navKey;

    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (res) async {
        final payload = res.payload;

        // ✅ SAVE SCHEDULED NOTIFICATION WHEN IT FIRES
        if (payload != null) {
          final parts = payload.split('|');
          await NotificationStore.save(
            title: parts[0],
            body: parts[1],
          );

          // 🔥 FLAG → OPEN INBOX AFTER SPLASH
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('open_inbox', true);
        }

        _navKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const NotificationInboxScreen(),
          ),
          (_) => false,
        );
      },
    );

    _initialized = true;
  }

  /* ================= IMMEDIATE ================= */

  static Future<void> showInstant({
    required int daysLeft,
    required String quote,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('notifications') ?? true)) return;

    final title = '📘 Exam Countdown';
    final body = '$daysLeft days left\n$quote';

    // ✅ SAVE IMMEDIATELY
    await NotificationStore.save(title: title, body: body);

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'exam_now',
          'Exam Alerts',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  /* ================= SCHEDULED ================= */

  static Future<void> scheduleDaily({
    required DateTime examDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('notifications') ?? true)) return;

    await cancelAll();

    await _schedule(hour: 9, minute: 0, examDate: examDate);
    await _schedule(hour: 19, minute: 0, examDate: examDate);
  }

  static Future<void> _schedule({
    required int hour,
    required int minute,
    required DateTime examDate,
  }) async {
    final daysLeft = examDate.difference(DateTime.now()).inDays;
    if (daysLeft < 0) return;

    final quotes = await _loadQuotes();
    final quote = quotes[Random().nextInt(quotes.length)];

    final title = '📚 StudyPulse Reminder';
    final body = '$daysLeft days left\n$quote';

    final now = tz.TZDateTime.now(tz.local);
    var time =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (time.isBefore(now)) {
      time = time.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      hour,
      title,
      body,
      time,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'exam_daily',
          'Daily Exam Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: '$title|$body',
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /* ================= CANCEL ================= */

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /* ================= QUOTES ================= */

  static Future<List<String>> _loadQuotes() async {
    final raw = await rootBundle.loadString('assets/quotes.txt');
    return raw.split('\n').where((e) => e.trim().isNotEmpty).toList();
  }
}
