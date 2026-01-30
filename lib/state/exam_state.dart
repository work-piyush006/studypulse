import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExamState {
  /// 🔥 SINGLE SOURCE OF TRUTH
  static final ValueNotifier<DateTime?> examDate =
      ValueNotifier<DateTime?>(null);

  static final ValueNotifier<int> daysLeft =
      ValueNotifier<int>(0);

  /// 🔥 APP START PAR CALL HONA ZARURI
  /// (main.dart me)
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('exam_date');

    if (saved != null) {
      update(DateTime.parse(saved));
    } else {
      examDate.value = null;
      daysLeft.value = 0;
    }
  }

  /// 🔥 CENTRAL UPDATE METHOD (EVERYWHERE USE THIS)
  static void update(DateTime? date) {
    examDate.value = date;

    if (date == null) {
      daysLeft.value = 0;
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    final diff = target.difference(today).inDays;
    daysLeft.value = diff < 0 ? 0 : diff;
  }

  /// 🎨 COLOR LOGIC (USED BY HOME & EXAM)
  static Color colorForDays(int days) {
    if (days >= 45) return Colors.green;
    if (days >= 30) return Colors.orange;
    return Colors.red;
  }
}