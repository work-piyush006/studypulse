import 'package:flutter/material.dart';

/// 🔥 SINGLE SOURCE OF TRUTH
/// Home, Exam, Notifications — sab yahin se sync hote hain
class ExamState {
  /// Current exam date
  static final ValueNotifier<DateTime?> examDate =
      ValueNotifier<DateTime?>(null);

  /// Days left (always derived, never manually set elsewhere)
  static final ValueNotifier<int> daysLeft =
      ValueNotifier<int>(0);

  /// 🔒 Internal guard to avoid duplicate updates
  static DateTime? _lastUpdatedDate;

  /// 🔥 ONLY ENTRY POINT to update exam date
  static void update(DateTime? date) {
    // ❌ Same date → do nothing (prevents rebuild spam)
    if (_lastUpdatedDate != null &&
        date != null &&
        _isSameDay(_lastUpdatedDate!, date)) {
      return;
    }

    _lastUpdatedDate = date;

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

  /// 🔥 Hard reset (use only if user clears data)
  static void clear() {
    _lastUpdatedDate = null;
    examDate.value = null;
    daysLeft.value = 0;
  }

  /// Utility: same calendar day check
  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }
}