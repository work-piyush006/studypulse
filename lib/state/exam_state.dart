import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification.dart';

class ExamState {
  static final examDate = ValueNotifier<DateTime?>(null);
  static final daysLeft = ValueNotifier<int>(0);
  static final isExamDay = ValueNotifier(false);
  static final isExamCompleted = ValueNotifier(false);

  static Timer? _timer;
  static bool _initialized = false;

  static const _dateKey = 'exam_date';
  static const _startKey = 'exam_start_date';
  static const _completedKey = 'exam_completed_notified';

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();

    final rawDate = prefs.getString(_dateKey);
    if (rawDate != null) {
      final d = DateTime.tryParse(rawDate);
      if (d != null) {
        examDate.value = d;
        await _recalculate(d, fromUser: false);
      }
    }

    _scheduleMidnight();
  }

  static Future<void> update(DateTime d) async {
    final prefs = await SharedPreferences.getInstance();

    final normalized = DateTime(d.year, d.month, d.day);
    await prefs.setString(_dateKey, normalized.toIso8601String());
    await prefs.setString(
      _startKey,
      DateTime.now().toIso8601String(),
    );
    await prefs.remove(_completedKey);

    examDate.value = normalized;
    await _recalculate(normalized, fromUser: true);
  }

  static Future<void> _recalculate(
    DateTime d, {
    required bool fromUser,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final today = DateTime.now();
    final now = DateTime(today.year, today.month, today.day);
    final diff = d.difference(now).inDays;

    if (diff < 0) {
      daysLeft.value = 0;
      isExamDay.value = false;
      isExamCompleted.value = true;

      if (!(prefs.getBool(_completedKey) ?? false)) {
        await NotificationService.examCompleted();
        await prefs.setBool(_completedKey, true);
      }
      return;
    }

    if (diff == 0) {
      daysLeft.value = 0;
      isExamDay.value = true;
      isExamCompleted.value = false;

      if (fromUser) {
        await NotificationService.instant(
          title: '🤞 Best of Luck!',
          body: 'Your exam is today 💪📘',
          save: true,
          route: '/exam',
        );
      }

      await NotificationService.scheduleExamMorning(d);
      await NotificationService.cancelDaily();
      return;
    }

    isExamDay.value = false;
    isExamCompleted.value = false;
    daysLeft.value = diff;

    if (fromUser) {
      await NotificationService.scheduleDaily(diff);
      await NotificationService.scheduleExamMorning(d);
    }
  }

  static void _scheduleMidnight() {
    _timer?.cancel();
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1);

    _timer = Timer(next.difference(now), () async {
      if (examDate.value != null) {
        await _recalculate(examDate.value!, fromUser: false);
      }
      _scheduleMidnight();
    });
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dateKey);
    await prefs.remove(_startKey);
    await prefs.remove(_completedKey);

    await NotificationService.cancelAll();

    examDate.value = null;
    daysLeft.value = 0;
    isExamDay.value = false;
    isExamCompleted.value = false;
  }
}