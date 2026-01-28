import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../screens/notification_inbox.dart';
import 'notification_store.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static late GlobalKey<NavigatorState> _navKey;

  /// 🚀 INIT ONCE (with navigatorKey)
  static Future<void> init(GlobalKey<NavigatorState> navKey) async {
    if (_initialized) return;
    _navKey = navKey;

    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (_) async {
        // 🔔 USER TAPPED NOTIFICATION
        await NotificationStore.markAllRead();

        // ⏩ FORCE OPEN INBOX
        _navKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => const NotificationInboxScreen(),
          ),
        );
      },
    );

    _initialized = true;
  }

  /* ================= INSTANT ================= */

  static Future<void> showInstant({
    required int daysLeft,
    required String quote,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('notifications') ?? true)) return;

    final title = '📘 Exam Countdown';
    final body = '$daysLeft days left\n$quote';

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

  /* ================= DAILY ================= */

  static Future<void> scheduleDaily({
    required DateTime examDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('notifications') ?? true)) return;

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
      hour: 19, // 🔥 7:00 PM FIXED
      minute: 0,
      daysLeft: daysLeft,
      quote: quotes[random.nextInt(quotes.length)],
    );
  }

  static Future<void> _schedule({
    required int id,
    required int hour,
    required int minute,
    required int daysLeft,
    required String quote,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final title = '📚 StudyPulse Reminder';
    final body = '$daysLeft days left\n$quote';

    await NotificationStore.save(title: title, body: body);

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
    );
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

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
