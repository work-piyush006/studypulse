import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_store.dart';

enum NotificationResult {
  granted,
  denied,
  scheduled,
  cancelled,
  failed,
}

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /* ================= CONSTANTS ================= */

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

    // ✅ Timezone FIX (India-safe)
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

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

  static Future<bool> ensurePermission() async {
    final android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (android == null) return false;

    final enabled = await android.areNotificationsEnabled();
    if (enabled == true) return true;

    // Android 13+ explicit request
    final granted = await android.requestPermission();
    return granted ?? false;
  }

  /* ================= INSTANT ================= */

  static Future<NotificationResult> showInstant({
    required BuildContext context,
    required int daysLeft,
    required String quote,
  }) async {
    await init();

    if (!await ensurePermission()) {
      _showSnack(
        context,
        'Notification permission denied',
        'Enable it from Settings → Notifications',
        isError: true,
      );
      return NotificationResult.denied;
    }

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

    _showSnack(
      context,
      'Countdown notification sent',
      'You will get daily reminders too',
    );

    return NotificationResult.granted;
  }

  /* ================= DAILY (2 TIMES) ================= */

  static Future<NotificationResult> scheduleDaily({
    required BuildContext context,
    required DateTime examDate,
  }) async {
    await init();

    if (!await ensurePermission()) {
      _showSnack(
        context,
        'Notifications disabled',
        'Enable them to get exam reminders',
        isError: true,
      );
      return NotificationResult.denied;
    }

    await cancelDaily();

    final now = tz.TZDateTime.now(tz.local);
    final today = DateTime(now.year, now.month, now.day);
    final daysLeft = examDate.difference(today).inDays;

    if (daysLeft < 0) {
      _showSnack(
        context,
        'Invalid exam date',
        'Please select a future date',
        isError: true,
      );
      return NotificationResult.failed;
    }

    final quotes = await _loadQuotes();
    if (quotes.isEmpty) return NotificationResult.failed;

    await _scheduleAt(
      id: _dailyId1,
      hour: 16,
      minute: 0,
      daysLeft: daysLeft,
      quotes: quotes,
    );

    await _scheduleAt(
      id: _dailyId2,
      hour: 23,
      minute: 0,
      daysLeft: daysLeft,
      quotes: quotes,
    );

    _showSnack(
      context,
      'Exam reminders set',
      'Daily alerts at 4:00 PM & 11:00 PM',
    );

    return NotificationResult.scheduled;
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

  static Future<NotificationResult> cancelDaily() async {
    await _plugin.cancel(_dailyId1);
    await _plugin.cancel(_dailyId2);
    return NotificationResult.cancelled;
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

  static void _showSnack(
    BuildContext context,
    String title,
    String msg, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title\n$msg'),
        backgroundColor:
            isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}