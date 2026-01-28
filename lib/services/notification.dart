import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// 🔔 INIT (call once in main.dart)
  static Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(settings);
    _initialized = true;
  }

  /// 🔐 Ask permission ONLY ONCE (Android 13+)
  static Future<void> requestPermissionOnce() async {
    final prefs = await SharedPreferences.getInstance();
    final asked = prefs.getBool('notif_permission_asked') ?? false;

    if (asked) return;

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await android?.requestPermission();
    await prefs.setBool('notif_permission_asked', true);
  }

  /// ⚡ Immediate notification (exam set)
  static Future<void> showInstant({
    required int daysLeft,
    required String quote,
  }) async {
    await _plugin.show(
      0,
      '📘 Exam Countdown',
      '$daysLeft days left\n$quote',
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

  /// ⏰ Daily reminders
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

    await _plugin.zonedSchedule(
      id,
      '📚 StudyPulse Reminder',
      '$daysLeft days left\n$quote',
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
