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

  static const String _channelId = 'exam_channel_v1';
  static const String _groupKey = 'exam_group';
  static const String _channelResetKey =
      'notification_channel_reset_done_v1';

  static const int _id4pm = 4001;
  static const int _id11pm = 4002;

  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    _channelId,
    'Exam Notifications',
    description: 'Exam reminders & study alerts',
    importance: Importance.high,
  );

  /* ================= INIT ================= */

  static Future<void> init() async {
    if (_initialized) return;

    // 🔹 Timezone (MANDATORY for exact alarms)
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (r) async {
        if (r.payload == null) return;
        final data = jsonDecode(r.payload!);

        if (data['save'] == true) {
          await NotificationStore.save(
            title: data['title'],
            body: data['body'],
            route: data['route'],
            time: data['time'],
          );
        }
      },
    );

    // 🔥 ONE-TIME CHANNEL HARD RESET (OEM SAFE)
    final prefs = await SharedPreferences.getInstance();
    final alreadyReset = prefs.getBool(_channelResetKey) ?? false;

    final android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (android != null && !alreadyReset) {
      try {
        await android.deleteNotificationChannel(_channelId);
        await android.createNotificationChannel(_channel);
        await prefs.setBool(_channelResetKey, true);
      } catch (_) {
        // OEM may block delete → ignore safely
      }
    }

    _initialized = true;
  }

  /* ================= SYSTEM CHECK ================= */

  static Future<bool> _systemAllowsNotifications() async {
    // Runtime permission (Android 13+)
    if (!await Permission.notification.isGranted) return false;

    final android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (android == null) return true;

    // OEM notification toggle
    return await android.areNotificationsEnabled() ?? false;
  }

  static Future<int> _nextId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = (prefs.getInt('notification_id') ?? 5000) + 1;
    await prefs.setInt('notification_id', id);
    return id;
  }

  /* ================= INSTANT ================= */

  static Future<NotificationResult> instant({
    required String title,
    required String body,
    required bool save,
    String route = '/exam',
  }) async {
    await init();

    // ❌ System / OEM blocked
    if (!await _systemAllowsNotifications()) {
      return NotificationResult.disabled;
    }

    // 🔥 ANDROID 13–15 OEM SETTLE WINDOW
    await Future.delayed(const Duration(milliseconds: 450));

    final id = await _nextId();

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
          visibility: NotificationVisibility.public,
          icon: 'ic_notification',
          groupKey: _groupKey,
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

  static Future<void> scheduleDaily({int? daysLeft}) async {
    await init();
    if (!await _systemAllowsNotifications()) return;

    await _plugin.cancel(_id4pm);
    await _plugin.cancel(_id11pm);

    await _schedule(_id4pm, 16, daysLeft);
    await _schedule(_id11pm, 23, daysLeft);
  }

  static Future<void> _schedule(
      int id, int hour, int? daysLeft) async {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime time =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);

    if (time.isBefore(now)) {
      time = time.add(const Duration(days: 1));
    }

    final body = daysLeft == null
        ? 'Set your exam countdown\nStart preparing today 📘'
        : '$daysLeft days left\n${_quote()}';

    await _plugin.zonedSchedule(
      id,
      '📚 Study Reminder',
      body,
      time,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          visibility: NotificationVisibility.public,
          icon: 'ic_notification',
          groupKey: _groupKey,
        ),
      ),
      payload: jsonEncode({
        'save': true,
        'title': '📚 Study Reminder',
        'body': body,
        'route': '/exam',
        'time': DateTime.now().toIso8601String(),
      }),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode:
          AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static String _quote() {
    const q = [
      'Stay consistent 🚀',
      'Small steps daily 📘',
      'You are closer than you think 💪',
    ];
    return q[Random().nextInt(q.length)];
  }
}