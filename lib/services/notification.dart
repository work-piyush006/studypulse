// lib/services/notification.dart

import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_store.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /* ================= CONSTANTS ================= */

  static const int _dailyId1 = 4001; // 4:00 PM
  static const int _dailyId2 = 11001; // 11:00 PM
  static const int _instantBaseId = 5000;

  static const AndroidNotificationChannel _examChannel =
      AndroidNotificationChannel(
    'exam_channel',
    'Exam Notifications',
    description: 'Exam countdown & daily reminders',
    importance: Importance.high,
  );

  /* ================= INIT ================= */

  static Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidInit =
        AndroidInitializationSettings('ic_notification');

    await _plugin.initialize(
      const InitializationSettings(android: androidInit),
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

    final android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await android?.createNotificationChannel(_examChannel);

    _initialized = true;
  }

  /* ================= PERMISSION ================= */

  static Future<bool> _hasPermission() async {
    final android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return false;
    return await android.areNotificationsEnabled() ?? false;
  }

  /* ================= INSTANT ================= */

  static Future<void> showInstant({
    required int daysLeft,
    required String quote,
  }) async {
    await init();
    if (!await _hasPermission()) return;

    final title = '📘 Exam Countdown';
    final body = '$daysLeft days left\n$quote';

    await NotificationStore.save(title: title, body: body);

    final id =
        _instantBaseId + DateTime.now().millisecondsSinceEpoch % 1000;

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _examChannel.id,
          _examChannel.name,
          channelDescription: _examChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification',
        ),
      ),
    );
  }

  /* ================= DAILY (2 TIMES) ================= */

  static Future<void> scheduleDaily({
    required DateTime examDate,
  }) async {
    await init();
    if (!await _hasPermission()) return;

    await cancelDaily();

    final now = tz.TZDateTime.now(tz.local);
    final today = DateTime(now.year, now.month, now.day);
    final daysLeft = examDate.difference(today).inDays;

    if (daysLeft < 0) return;

    final quotes = await _loadQuotes();
    if (quotes.isEmpty) return;

    // Schedule 4:00 PM
    await _scheduleAt(
      id: _dailyId1,
      hour: 16,
      minute: 0,
      daysLeft: daysLeft,
      quotes: quotes,
    );

    // Schedule 11:00 PM
    await _scheduleAt(
      id: _dailyId2,
      hour: 23,
      minute: 0,
      daysLeft: daysLeft,
      quotes: quotes,
    );
  }

  static Future<void> _scheduleAt({
    required int id,
    required int hour,
    required int minute,
    required int daysLeft,
    required List<String> quotes,
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    final scheduledToday = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    final scheduled = scheduledToday.isBefore(now)
        ? scheduledToday.add(const Duration(days: 1))
        : scheduledToday;

    final quote = quotes[Random().nextInt(quotes.length)];
    final title = '📚 Study Reminder';
    final body = '$daysLeft days left\n$quote';
    final payload = jsonEncode({'title': title, 'body': body});

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _examChannel.id,
          _examChannel.name,
          channelDescription: _examChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification',
        ),
      ),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /* ================= CANCEL ================= */

  static Future<void> cancelDaily() async {
    await _plugin.cancel(_dailyId1);
    await _plugin.cancel(_dailyId2);
  }

  static Future<void> cancelAllExamNotifications() async {
    await _plugin.cancelAll();
  }

  /* ================= HELPERS ================= */

  static Future<List<String>> _loadQuotes() async {
    final raw = await rootBundle.loadString('assets/quotes.txt');
    return raw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}