import 'package:flutter/foundation.dart';

/// 🔥 Single source of truth for exam date
/// Home & Exam dono yahin se sync honge
class ExamState {
  static final ValueNotifier<DateTime?> examDate =
      ValueNotifier<DateTime?>(null);
}
