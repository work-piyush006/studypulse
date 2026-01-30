import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_store.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // 🔥 OEM-safe spam guard
  static const String _lastInstantKey =
      'last_instant_notification_time';

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

    const android =
        AndroidInitializationSettings('ic_notification');

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

    // Android 13+ permission
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }

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
    await init();

    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('notifications') ?? true)) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final lastMs = prefs.getInt(_lastInstantKey) ?? 0;

    final title = '📘 Exam Countdown';
    final body = '$daysLeft days left\n$quote';

    // Always save to inbox
    await NotificationStore.save(title: title, body: body);

    // OEM safe window
    if (nowMs - lastMs < 30000) return;

    await prefs.setInt(_lastInstantKey, nowMs);

    final id = nowMs & 0x7fffffff;

    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'exam_now',
          'Exam Alerts',
          channelDescription: 'Instant exam countdown alerts',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification', // ✅ CORRECT PARAMETER
        ),
      ),
    );
  }

  /* ================= DAILY ================= */

  static Future<void> scheduleDaily({
    required DateTime examDate,
  }) async {
    await init();

    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('notifications') ?? true)) return;

    await _plugin.cancel(1530);
    await _plugin.cancel(2030);

    await _schedule(
      id: 1530,
      hour: 15,
      minute: 30,
      examDate: examDate,
    );

    await _schedule(
      id: 2030,
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
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end =
        DateTime(examDate.year, examDate.month, examDate.day);

    final daysLeft = end.difference(start).inDays;
    if (daysLeft < 0) return;

    final quotes = await _loadQuotes();
    if (quotes.isEmpty) return;

    final quote = quotes[Random().nextInt(quotes.length)];
    final title = '📚 StudyPulse Reminder';
    final body = '$daysLeft days left\n$quote';
    final payload = jsonEncode({'title': title, 'body': body});

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final examEnd = tz.TZDateTime(
      tz.local,
      examDate.year,
      examDate.month,
      examDate.day,
      23,
      59,
    );

    if (scheduled.isAfter(examEnd)) return;

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
          icon: 'ic_notification', // ✅ CORRECT PARAMETER
        ),
      ),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /* ================= UTIL ================= */

  static Future<List<String>> _loadQuotes() async {
    final raw = await rootBundle.loadString('assets/quotes.txt');
    return raw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}