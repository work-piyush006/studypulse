import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_store.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// 🚀 INIT (call once from main.dart)
  static Future<void> init(GlobalKey<NavigatorState> navKey) async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (_) async {
        // 🔔 Notification TAP hua
        // Sirf inbox open karo (save yahan nahi)
        const channel = MethodChannel('studypulse/notifications');
        await channel.invokeMethod('openInbox');
      },
    );

    _initialized = true;
  }

  /* =========================================================
     🔥 IMMEDIATE NOTIFICATION
     → APP ACTIVE → SAVE + SHOW (100% guaranteed)
  ========================================================= */

  static Future<void> showInstant({
    required int daysLeft,
    required String quote,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('notifications') ?? true)) return;

    final title = '📘 Exam Countdown';
    final body = '$daysLeft days left\n$quote';

    // ✅ GUARANTEED SAVE (app is running)
    await NotificationStore.save(
      title: title,
      body: body,
    );

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

  /* =========================================================
     🕘 SCHEDULED NOTIFICATIONS
     → SAVE ONLY WHEN USER TAPS (REALISTIC)
  ========================================================= */

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
    tz.TZDateTime time =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (time.isBefore(now)) {
      time = time.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      hour, // unique ID
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
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // ❌ YAHAN SAVE NAHI
    // Scheduled notification → save only on TAP
  }

  /* =========================================================
     ❌ CANCEL ALL
  ========================================================= */

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /* =========================================================
     📜 QUOTES
  ========================================================= */

  static Future<List<String>> _loadQuotes() async {
    final raw = await rootBundle.loadString('assets/quotes.txt');
    return raw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}
