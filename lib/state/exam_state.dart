import 'package:flutter/material.dart';

class ExamState {
  static final ValueNotifier<DateTime?> examDate =
      ValueNotifier<DateTime?>(null);

  static final ValueNotifier<int> daysLeft =
      ValueNotifier<int>(0);

  static void update(DateTime? date) {
    examDate.value = date;

    if (date == null) {
      daysLeft.value = 0;
      return;
    }

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(date.year, date.month, date.day);

    final diff = end.difference(start).inDays;
    daysLeft.value = diff < 0 ? 0 : diff;
  }
}
