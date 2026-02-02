import 'dart:convert';
import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_store.dart';

enum NotificationResult { success, permissionDenied }

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static const String _channelId = 'exam_channel_v3';

  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    _channelId,
    'Exam Notifications',
    description: 'Exam reminders & study alerts',
    importance: Importance.high,
  );

  static const int _id4pm = 4001;
  static const int _id11pm = 4002;
  static const int _examMorningId = 8001;
  static const int _examCompletedId = 8002;

  /* ================= INIT ================= */

  static Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const androidInit =
        AndroidInitializationSettings('ic_notification');

    await _plugin.initialize(
      const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: _onTap,
    );

    final android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      await android.createNotificationChannel(_channel);
    }

    _initialized = true;
  }

  /* ================= TAP ================= */

  static Future<void> _onTap(NotificationResponse response) async {
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
      await prefs.setString('notification_route', data['route']);
    }
  }

  /* ================= PERMISSIONS ================= */

  static Future<bool> _ensureNotifyPermission() async {
    final status = await Permission.notification.status;
    if (status.isGranted) return true;

    final result = await Permission.notification.request();
    return result.isGranted;
  }

  static Future<bool> _ensureExactAlarmPermission() async {
    final status = await Permission.scheduleExactAlarm.status;
    if (status.isGranted) return true;

    final result = await Permission.scheduleExactAlarm.request();
    return result.isGranted;
  }

  /* ================= INSTANT ================= */

  static Future<NotificationResult> instant({
    required String title,
    required String body,
    required bool save,
    String route = '/exam',
  }) async {
    await init();

    if (!await _ensureNotifyPermission()) {
      return NotificationResult.permissionDenied;
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

    return NotificationResult.success;
  }

  /* ================= DAILY ================= */

  static Future<void> scheduleDaily({required int daysLeft}) async {
    await init();

    final canNotify = await _ensureNotifyPermission();
    final canExact = await _ensureExactAlarmPermission();
    if (!canNotify || !canExact) return;

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
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /* ================= EXAM DAY 6 AM ================= */

  static Future<void> scheduleExamMorning(DateTime examDate) async {
    await init();

    final canNotify = await _ensureNotifyPermission();
    final canExact = await _ensureExactAlarmPermission();
    if (!canNotify || !canExact) return;

    final time = tz.TZDateTime(
      tz.local,
      examDate.year,
      examDate.month,
      examDate.day,
      6,
    );

    if (time.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      _examMorningId,
      '🤞 Best of Luck!',
      'Today is your exam.\nYou’ve got this 💪📘',
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
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /* ================= EXAM COMPLETED ================= */

  static Future<void> examCompleted() async {
    await init();
    if (!await _ensureNotifyPermission()) return;

    await _plugin.show(
      _examCompletedId,
      '🎉 Exam Completed',
      'Any next exam left?\nStart preparing today 📘',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channel.name,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification',
        ),
      ),
    );
  }

  /* ================= CANCEL ================= */

  static Future<void> cancelDaily() async {
    await init();
    await _plugin.cancel(_id4pm);
    await _plugin.cancel(_id11pm);
    await _plugin.cancel(_examMorningId);
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