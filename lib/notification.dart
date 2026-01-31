// lib/services/notification.dart

import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_manager.dart';
import 'notification_store.dart';

enum NotificationResult {
  success,
  disabled,
  failed,
}

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static const int _dailyId1 = 4001;
  static const int _dailyId2 = 4002;

  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    'exam_channel',
    'Exam Notifications',
    description: 'Exam reminders & study alerts',
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

      // ✅ ONLY SAVE — NO NAVIGATION HERE
      onDidReceiveNotificationResponse: (response) async {
        final payload = response.payload;
        if (payload == null) return;

        final data = jsonDecode(payload);

        if (data['type'] == 'SAVE') {
          await NotificationStore.save(
            title: data['title'],
            body: data['body'],
            route: data['route'],
            time: data['time'],
          );
        }
      },
    );

    final android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await android?.createNotificationChannel(_channel);

    _initialized = true;
  }

  /* ================= INSTANT ================= */

  static Future<NotificationResult> showInstant({
    required int daysLeft,
    required String quote,
    bool saveToInbox = true,
  }) async {
    await init();

    if (!await NotificationManager.canNotify()) {
      return NotificationResult.disabled;
    }

    final id =
        DateTime.now().millisecondsSinceEpoch.remainder(100000);

    final body = '$daysLeft days left\n$quote';

    final payload = jsonEncode({
      'type': saveToInbox ? 'SAVE' : 'TEST',
      'title': '📘 Exam Countdown',
      'body': body,
      'route': '/exam',
      'time': DateTime.now().toIso8601String(),
    });

    try {
      await _plugin.show(
        id,
        '📘 Exam Countdown',
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: 'ic_notification',
            styleInformation: BigTextStyleInformation(
              body,
              contentTitle: '📘 Exam Countdown',
            ),
          ),
        ),
        payload: payload,
      );

      return NotificationResult.success;
    } catch (_) {
      return NotificationResult.failed;
    }
  }

  /* ================= DAILY ================= */

  static Future<NotificationResult> scheduleDaily({
    required DateTime examDate,
  }) async {
    await init();

    if (!await NotificationManager.canNotify()) {
      return NotificationResult.disabled;
    }

    await cancelDaily();

    final now = tz.TZDateTime.now(tz.local);
    final today = DateTime(now.year, now.month, now.day);
    final daysLeft = examDate.difference(today).inDays;

    if (daysLeft < 0) return NotificationResult.failed;

    final quotes = await _loadQuotes();
    if (quotes.isEmpty) return NotificationResult.failed;

    await _scheduleAt(_dailyId1, 16, daysLeft, quotes);
    await _scheduleAt(_dailyId2, 23, daysLeft, quotes);

    return NotificationResult.success;
  }

  static Future<void> _scheduleAt(
    int id,
    int hour,
    int daysLeft,
    List<String> quotes,
  ) async {
    final now = tz.TZDateTime.now(tz.local);

    var time =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);

    if (time.isBefore(now)) {
      time = time.add(const Duration(days: 1));
    }

    final quote = quotes[Random().nextInt(quotes.length)];
    final body = '$daysLeft days left\n$quote';

    final payload = jsonEncode({
      'type': 'SAVE',
      'title': '📚 Study Reminder',
      'body': body,
      'route': '/exam',
      'time': DateTime.now().toIso8601String(),
    });

    await _plugin.zonedSchedule(
      id,
      '📚 Study Reminder',
      body,
      time,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification',
          styleInformation:
              BigTextStyleInformation(body, contentTitle: '📚 Study Reminder'),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
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
}