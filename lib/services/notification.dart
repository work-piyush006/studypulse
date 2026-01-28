import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_store.dart';

/// 🔔 GLOBAL NOTIFICATION SERVICE (STABLE)
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// 🚀 CALL ONCE IN main()
  static Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) async {
        // 🔔 System notification tapped
        // Navigation handled in main.dart via navigatorKey (next step)
        await NotificationStore.markAllRead();
      },
    );

    _initialized = true;
  }

  /* ============================================================
     🔥 INSTANT NOTIFICATION (Exam set hote hi)
  ============================================================ */

  static Future<void> showInstant({
    required int daysLeft,
    required String quote,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notifications') ?? true;
    if (!enabled) return;

    final title = '📘 Exam Countdown';
    final body = '$daysLeft days left\n$quote';

    // 🔔 Save to inbox (UNREAD)
    await NotificationStore.save(title: title, body: body);

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // unique id
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

  /* ============================================================
     🕘 DAILY NOTIFICATIONS (9:00 AM & 4:30 PM)
  ============================================================ */

  static Future<void> scheduleDaily({
    required DateTime examDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notifications') ?? true;
    if (!enabled) return;

    await cancelAll();

    final quotes = await _loadQuotes();
    final random = Random();

    final daysLeft = examDate.difference(DateTime.now()).inDays;
    if (daysLeft < 0) return;

    await _schedule(
      id: 1,
      hour: 9,
      minute: 0,
      daysLeft: daysLeft,
      quote: quotes[random.nextInt(quotes.length)],
    );

    await _schedule(
      id: 2,
      hour: 16,
      minute: 30,
      daysLeft: daysLeft,
      quote: quotes[random.nextInt(quotes.length)],
    );
  }

  /* ============================================================
     ⏰ INTERNAL SCHEDULER
  ============================================================ */

  static Future<void> _schedule({
    required int id,
    required int hour,
    required int minute,
    required int daysLeft,
    required String quote,
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    tz.TZDateTime scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final title = '📚 StudyPulse Reminder';
    final body = '$daysLeft days left\n$quote';

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
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
      payload: 'daily',
    );
  }

  /* ============================================================
     ❌ CANCEL
  ============================================================ */

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /* ============================================================
     📜 QUOTES
  ============================================================ */

  static Future<List<String>> _loadQuotes() async {
    try {
      final raw = await rootBundle.loadString('assets/quotes.txt');
      return raw
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (_) {
      return ['Stay focused. Success is near.'];
    }
  }
}
