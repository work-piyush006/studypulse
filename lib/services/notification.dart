// lib/services/notification.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_manager.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static const int _dailyId1 = 4001;
  static const int _dailyId2 = 4002;
  static const int _instantBaseId = 5000;

  static const AndroidNotificationChannel _examChannel =
      AndroidNotificationChannel(
    'exam_channel',
    'Exam Notifications',
    description: 'Exam countdown & study reminders',
    importance: Importance.high,
  );

  /* ================= INIT ================= */

  static Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    await _plugin.initialize(
      const InitializationSettings(android: androidInit),
    );

    final android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await android?.createNotificationChannel(_examChannel);
    _initialized = true;
  }

  /* ================= INSTANT ================= */

  static Future<void> showInstant({
    required BuildContext context,
    required int daysLeft,
    required String quote,
  }) async {
    await init();

    if (!await NotificationManager.isUserEnabled()) {
      _snack(context, 'Notifications are turned OFF');
      return;
    }

    final allowed =
        await NotificationManager.requestPermissionIfNeeded();
    if (!allowed) {
      _snack(
        context,
        'Enable notification permission from system settings',
        error: true,
      );
      return;
    }

    final id =
        _instantBaseId + DateTime.now().millisecondsSinceEpoch % 1000;

    await _plugin.show(
      id,
      '📘 Exam Countdown',
      '$daysLeft days left\n$quote',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _examChannel.id,
          _examChannel.name,
          channelDescription: _examChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );

    _snack(context, 'Notification sent');
  }

  /* ================= DAILY ================= */

  static Future<void> scheduleDaily({
    required BuildContext context,
    required DateTime examDate,
  }) async {
    await init();

    if (!await NotificationManager.isUserEnabled()) {
      _snack(context, 'Notifications are OFF');
      return;
    }

    final allowed =
        await NotificationManager.requestPermissionIfNeeded();
    if (!allowed) {
      _snack(context, 'Permission required', error: true);
      return;
    }

    await cancelDaily();

    final now = tz.TZDateTime.now(tz.local);
    final today = DateTime(now.year, now.month, now.day);
    final daysLeft = examDate.difference(today).inDays;
    if (daysLeft < 0) return;

    final quotes = await _loadQuotes();
    if (quotes.isEmpty) return;

    await _scheduleAt(_dailyId1, 16, daysLeft, quotes);
    await _scheduleAt(_dailyId2, 23, daysLeft, quotes);

    _snack(context, 'Daily reminders scheduled');
  }

  static Future<void> _scheduleAt(
    int id,
    int hour,
    int daysLeft,
    List<String> quotes,
  ) async {
    final now = tz.TZDateTime.now(tz.local);
    var time = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
    );

    if (time.isBefore(now)) {
      time = time.add(const Duration(days: 1));
    }

    final quote = quotes[Random().nextInt(quotes.length)];

    await _plugin.zonedSchedule(
      id,
      '📚 Study Reminder',
      '$daysLeft days left\n$quote',
      time,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _examChannel.id,
          _examChannel.name,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelDaily() async {
    await _plugin.cancel(_dailyId1);
    await _plugin.cancel(_dailyId2);
  }

  static Future<List<String>> _loadQuotes() async {
    final raw = await rootBundle.loadString('assets/quotes.txt');
    return raw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static void _snack(
    BuildContext c,
    String msg, {
    bool error = false,
  }) {
    ScaffoldMessenger.of(c).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            error ? Colors.redAccent : Colors.green,
      ),
    );
  }
}