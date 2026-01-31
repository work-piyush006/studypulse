// lib/services/notification.dart

import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_manager.dart';

/// ✅ Explicit result → UI can react correctly
enum NotificationResult {
  success,
  disabledByUser,
  permissionDenied,
  invalidDate,
  failed,
}

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static const int _dailyId1 = 4001; // 4:00 PM
  static const int _dailyId2 = 4002; // 11:00 PM
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

  static Future<NotificationResult> showInstant({
    required int daysLeft,
    required String quote,
  }) async {
    await init();

    // 🔕 User toggle OFF
    if (!await NotificationManager.isUserEnabled()) {
      return NotificationResult.disabledByUser;
    }

    // 🔐 Permission
    final allowed =
        await NotificationManager.requestPermissionIfNeeded();
    if (!allowed) {
      return NotificationResult.permissionDenied;
    }

    final id =
        _instantBaseId + DateTime.now().millisecondsSinceEpoch % 1000;

    final body = '$daysLeft days left\n$quote';

    try {
      await _plugin.show(
        id,
        '📘 Exam Countdown',
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _examChannel.id,
            _examChannel.name,
            channelDescription: _examChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            styleInformation: BigTextStyleInformation(
              body,
              contentTitle: '📘 Exam Countdown',
            ),
          ),
        ),
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

    if (!await NotificationManager.isUserEnabled()) {
      return NotificationResult.disabledByUser;
    }

    final allowed =
        await NotificationManager.requestPermissionIfNeeded();
    if (!allowed) {
      return NotificationResult.permissionDenied;
    }

    final now = tz.TZDateTime.now(tz.local);
    final today = DateTime(now.year, now.month, now.day);
    final daysLeft = examDate.difference(today).inDays;

    if (daysLeft < 0) {
      return NotificationResult.invalidDate;
    }

    final quotes = await _loadQuotes();
    if (quotes.isEmpty) {
      return NotificationResult.failed;
    }

    await cancelDaily();

    try {
      await _scheduleAt(_dailyId1, 16, daysLeft, quotes);
      await _scheduleAt(_dailyId2, 23, daysLeft, quotes);
      return NotificationResult.success;
    } catch (_) {
      return NotificationResult.failed;
    }
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
    final body = '$daysLeft days left\n$quote';

    await _plugin.zonedSchedule(
      id,
      '📚 Study Reminder',
      body,
      time,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _examChannel.id,
          _examChannel.name,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(
            body,
            contentTitle: '📚 Study Reminder',
          ),
        ),
      ),
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