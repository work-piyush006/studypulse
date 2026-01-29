import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_store.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /* ================= CHANNELS ================= */

  static const AndroidNotificationChannel _instantChannel =
      AndroidNotificationChannel(
    'exam_now',
    'Exam Alerts',
    description: 'Instant exam countdown alerts',
    importance: Importance.high,
  );

  static const AndroidNotificationChannel _dailyChannel =
      AndroidNotificationChannel(
    'exam_daily',
    'Daily Exam Reminders',
    description: 'Daily study reminders',
    importance: Importance.high,
  );

  /* ================= INIT ================= */

  static Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) async {
        if (response.payload == null) return;

        try {
          final data = jsonDecode(response.payload!);
          await NotificationStore.save(
            title: data['title'],
            body: data['body'],
          );
        } catch (_) {}
      },
    );

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(_instantChannel);
    await androidPlugin?.createNotificationChannel(_dailyChannel);

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

    // save to inbox
    await NotificationStore.save(title: title, body: body);

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _instantChannel.id,
          _instantChannel.name,
          channelDescription: _instantChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  /* ================= DAILY SCHEDULE ================= */

  /// 🔔 DAILY NOTIFICATIONS
  /// ⏰ 3:30 PM & 8:30 PM
  static Future<void> scheduleDaily({
    required DateTime examDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('notifications') ?? true)) return;

    // 🔥 remove old schedules
    await cancelAll();

    // ✅ 3:30 PM
    await _schedule(
      id: 15,
      hour: 15,
      minute: 30,
      examDate: examDate,
    );

    // ✅ 8:30 PM
    await _schedule(
      id: 20,
      hour: 20,
      minute: 30,
      examDate: examDate,
    );
  }

  static Future<void> _schedule({
    required int id,
    required int hour,
    required int minute,
    required DateTime examDate,
  }) async {
    final daysLeft = examDate.difference(DateTime.now()).inDays;
    if (daysLeft < 0) return;

    final quotes = await _loadQuotes();
    if (quotes.isEmpty) return;

    final quote = quotes[Random().nextInt(quotes.length)];

    final title = '📚 StudyPulse Reminder';
    final body = '$daysLeft days left\n$quote';

    final payload = jsonEncode({
      'title': title,
      'body': body,
    });

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // if time already passed → next day
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _dailyChannel.id,
          _dailyChannel.name,
          channelDescription: _dailyChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // 🔥 DAILY
    );
  }

  /* ================= UTIL ================= */

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static Future<List<String>> _loadQuotes() async {
    final raw = await rootBundle.loadString('assets/quotes.txt');
    return raw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}