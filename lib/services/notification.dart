// lib/services/notification.dart
import 'dart:convert';
import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_store.dart';

enum NotificationResult { success, disabled }

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // 🔥 STABLE CHANNEL (DO NOT CHANGE)
  static const String _channelId = 'exam_channel_stable_v1';
  static const String _groupKey = 'exam_group';

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

    final android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      await android.createNotificationChannel(_channel);
    }

    _initialized = true;
  }

  /* ================= PERMISSION CHECK ================= */

  static Future<bool> _canNotify() async {
    return await Permission.notification.isGranted;
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

    // 🔥 FIX #1: SAVE IMMEDIATELY (not only on tap)
    if (save) {
      await NotificationStore.save(
        title: title,
        body: body,
        route: route,
        time: DateTime.now().toIso8601String(),
      );
    }

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channel.name,
          channelDescription: _channel.description,

          // 🔥 FIX #2: FULL EXPANDED NOTIFICATION
          styleInformation: BigTextStyleInformation(
            body,
            contentTitle: title,
          ),

          importance: Importance.high,
          priority: Priority.high,

          // 🔥 FIX #3: PROPER NOTIFICATION ICON
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
    if (!await _canNotify()) return;

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

          styleInformation: BigTextStyleInformation(body),

          importance: Importance.high,
          priority: Priority.high,
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
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
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