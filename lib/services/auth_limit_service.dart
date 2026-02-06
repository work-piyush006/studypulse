import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthBlockType {
  none,
  cooldown,
  blocked,
}

class AuthLimitState {
  final AuthBlockType type;
  final int secondsLeft;
  final String message;

  const AuthLimitState({
    required this.type,
    required this.secondsLeft,
    required this.message,
  });
}

class AuthLimitService {
  static const _triesKey = 'auth_tries';
  static const _blockedUntilKey = 'auth_blocked_until';

  static const List<_Stage> _stages = [
    _Stage(tries: 3, cooldownSeconds: 5 * 60),
    _Stage(tries: 2, cooldownSeconds: 10 * 60),
    _Stage(tries: 1, cooldownSeconds: 15 * 60),
    _Stage(tries: 1, cooldownSeconds: 60 * 60),
  ];

  static Future<void> registerAttempt() async {
    final prefs = await SharedPreferences.getInstance();

    int tries = prefs.getInt(_triesKey) ?? 0;
    tries++;

    final stage = _currentStage(tries);
    if (stage != null) {
      final until =
          DateTime.now().add(Duration(seconds: stage.cooldownSeconds));
      await prefs.setInt(_blockedUntilKey, until.millisecondsSinceEpoch);
    }

    await prefs.setInt(_triesKey, tries);
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_triesKey);
    await prefs.remove(_blockedUntilKey);
  }

  static Future<AuthLimitState> getState() async {
    final prefs = await SharedPreferences.getInstance();

    final tries = prefs.getInt(_triesKey) ?? 0;
    final blockedUntilMs = prefs.getInt(_blockedUntilKey);

    if (blockedUntilMs == null) {
      return const AuthLimitState(
        type: AuthBlockType.none,
        secondsLeft: 0,
        message: '',
      );
    }

    final now = DateTime.now();
    final until =
        DateTime.fromMillisecondsSinceEpoch(blockedUntilMs);

    if (now.isAfter(until)) {
      return const AuthLimitState(
        type: AuthBlockType.none,
        secondsLeft: 0,
        message: '',
      );
    }

    final secondsLeft = until.difference(now).inSeconds;
    final isHardBlock = tries >= 7;

    return AuthLimitState(
      type:
          isHardBlock ? AuthBlockType.blocked : AuthBlockType.cooldown,
      secondsLeft: secondsLeft,
      message: isHardBlock
          ? 'System detected unusual activity.\nYou are blocked for 1 hour.'
          : 'Too many attempts.\nPlease try again later.',
    );
  }

  static String formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  static _Stage? _currentStage(int tries) {
    int used = 0;
    for (final stage in _stages) {
      used += stage.tries;
      if (tries == used) return stage;
    }
    return null;
  }
}

class _Stage {
  final int tries;
  final int cooldownSeconds;

  const _Stage({
    required this.tries,
    required this.cooldownSeconds,
  });
}
