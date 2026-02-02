// lib/services/notification.dart
import 'dart:convert';
import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_store.dart';

enum NotificationResult { success, disabled }

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static const String _channelId = 'exam_channel_stable_v1';
  static const String _groupKey = 'exam_group';

  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    _channelId,
    'Exam Notifications',
    description: 'Exam reminders & study alerts',
    importance: Importance.high,
  );

  static const int _id4pm = 4001;
  static const int _id11pm = 4002;

  /* ================= INIT ================= */

  static Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
      ),
      onDidReceiveNotificationResponse: (response) async {
        if (response.payload == null) return;

        final data = jsonDecode(response.payload!);
        final prefs = await SharedPreferences.getInstance();

        if (data['save'] == true) {
          await NotificationStore.save(
            title: data['title'],
            body: data['body'],
            route: data['route'],
            time: data['time'],
          );
        }

        if (data['route'] != null) {
          await prefs.setString(
            'notification_route',
            data['route'],
          );
        }
      },
    );

    final android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      await android.createNotificationChannel(_channel);

      // ✅ Android 12+ exact alarm safety (NULL-SAFE)
      final bool canExact =
          await android.canScheduleExactNotifications() ?? false;

      if (!canExact) {
        await android.requestExactAlarmsPermission();
      }
    }

    _initialized = true;
  }

  /* ================= PERMISSION ================= */

  static Future<bool> _canNotify() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /* ================= INSTANT ================= */

  static Future<NotificationResult> instant({
    required String title,
    required String body,
    required bool save,
    String route = '/exam',
  }) async {
    await init();
    if (!await _canNotify()) {
      return NotificationResult.disabled;
    }

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          groupKey: _groupKey,
          icon: 'ic_notification',
        ),
      ),
      payload: jsonEncode({
        'save': save,
        'title': title,
        'body': body,
        'route': route,
        'time': DateTime.now().toIso8601String(),
      }),
    );

    if (save) {
      await NotificationStore.save(
        title: title,
        body: body,
        route: route,
        time: DateTime.now().toIso8601String(),
      );
    }

    return NotificationResult.success;
  }

  /* ================= DAILY ================= */

  static Future<void> scheduleDaily({required int daysLeft}) async {
    await init();
    if (!await _canNotify()) return;

    await cancelDaily();
    await _schedule(_id4pm, 16, daysLeft);
    await _schedule(_id11pm, 23, daysLeft);
  }

  static Future<void> _schedule(
    int id,
    int hour,
    int daysLeft,
  ) async {
    final now = tz.TZDateTime.now(tz.local);
    var time =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);

    if (time.isBefore(now)) {
      time = time.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      '📚 Study Reminder',
      '$daysLeft days left\n${_quote()}',
      time,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channel.name,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification',
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode:
          AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /* ================= EXAM DAY ================= */

  static Future<void> examDayMorning() async {
    await init();
    if (!await _canNotify()) return;

    await _plugin.cancel(9001);

    final now = tz.TZDateTime.now(tz.local);
    var time =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 6);

    if (time.isBefore(now)) {
      time = now.add(const Duration(seconds: 2));
    }

    await _plugin.zonedSchedule(
      9001,
      '🤞🏼 Best of Luck!',
      'Your exam is today.\nYou’ve got this 💪📘',
      time,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channel.name,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification',
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode:
          AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /* ================= CANCEL ================= */

  static Future<void> cancelDaily() async {
    await init();
    await _plugin.cancel(_id4pm);
    await _plugin.cancel(_id11pm);
  }

  static String _quote() {
    const quotes = [
      'Stay consistent 🚀',
      'Small steps daily 📘',
      'You are closer than you think 💪',
    ];
    return quotes[Random().nextInt(quotes.length)];
  }
}