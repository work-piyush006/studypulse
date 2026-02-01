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

  /* ================= CORE ================= */

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /* ================= CHANNEL ================= */

  static const String _channelId = 'exam_channel_stable_v1';
  static const String _groupKey = 'exam_group';

  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    _channelId,
    'Exam Notifications',
    description: 'Exam reminders & study alerts',
    importance: Importance.high,
  );

  /* ================= IDS ================= */

  static const int _id4pm = 4001;
  static const int _id11pm = 4002;

  /* ================= INIT (CRITICAL FIX HERE) ================= */

  static Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const androidInit = AndroidInitializationSettings('ic_notification');

    await _plugin.initialize(
      const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: (response) async {
        if (response.payload == null) return;

        final data = jsonDecode(response.payload!);
        final prefs = await SharedPreferences.getInstance();

        // Save to inbox
        if (data['save'] == true) {
          await NotificationStore.save(
            title: data['title'],
            body: data['body'],
            route: data['route'],
            time: data['time'],
          );
        }

        // Deep-link support
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
      // 🔥🔥🔥 ANDROID 13+ FIX (THIS WAS MISSING) 🔥🔥🔥
      await android.requestPermission();

      await android.createNotificationChannel(_channel);
    }

    _initialized = true;
  }

  /* ================= PERMISSION CHECK ================= */

  static Future<bool> _canNotify() async {
    final granted = await Permission.notification.isGranted;
    if (!granted) return false;

    final android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }

    return true;
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
          styleInformation: BigTextStyleInformation(body),
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

  /* ================= DAILY SCHEDULE ================= */

  static Future<void> scheduleDaily({required int daysLeft}) async {
    await init();
    if (!await _canNotify()) return;

    // Clear old notifications first
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

    final body = '$daysLeft days left\n${_quote()}';

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
          groupKey: _groupKey,
          icon: 'ic_notification',
          styleInformation: BigTextStyleInformation(body),
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

  /* ================= CANCEL ================= */

  static Future<void> cancelDaily() async {
    await init();
    await _plugin.cancel(_id4pm);
    await _plugin.cancel(_id11pm);
  }

  /* ================= HELPERS ================= */

  static String _quote() {
    const quotes = [
      'Stay consistent 🚀',
      'Small steps daily 📘',
      'You are closer than you think 💪',
    ];
    return quotes[Random().nextInt(quotes.length)];
  }
}