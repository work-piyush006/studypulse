import 'package:flutter/material.dart';

class ThemeState {
  static final ValueNotifier<ThemeMode> mode =
      ValueNotifier(ThemeMode.system);
}