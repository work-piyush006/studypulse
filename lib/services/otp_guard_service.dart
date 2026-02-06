import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

enum OtpBlockLevel {
  none,
  cooldown5,
  cooldown10,
  cooldown15,
  blocked1h,
}

class OtpGuardState {
  final int triesLeft;
  final OtpBlockLevel blockLevel;
  final Duration remaining;

  const OtpGuardState({
    required this.triesLeft,
    required this.blockLevel,
    required this.remaining,
  });

  bool get isBlocked => blockLevel != OtpBlockLevel.none;

  String get remainingText {
    if (remaining.inSeconds <= 0) return '0:00';
    final m = remaining.inMinutes;
    final s = remaining.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class OtpGuardService {
  static const _keyAttempts = 'otp_attempts';
  static const _keyBlockedUntil = 'otp_blocked_until';
  static const _keyLevel = 'otp_block_level';

  static int _attempts = 0;
  static DateTime? _blockedUntil;
  static OtpBlockLevel _level = OtpBlockLevel.none;

  static const int _phase1 = 3;
  static const int _phase2 = 5;
  static const int _phase3 = 6;

  /// ================= INIT =================

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    _attempts = prefs.getInt(_keyAttempts) ?? 0;

    final until = prefs.getInt(_keyBlockedUntil);
    if (until != null) {
      _blockedUntil = DateTime.fromMillisecondsSinceEpoch(until);
    }

    final lvl = prefs.getInt(_keyLevel);
    if (lvl != null) {
      _level = OtpBlockLevel.values[lvl];
    }
  }

  /// ================= STATUS =================

  static OtpGuardState status() {
    if (_blockedUntil != null) {
      final diff = _blockedUntil!.difference(DateTime.now());

      if (diff.isNegative) {
        _reset();
      } else {
        return OtpGuardState(
          triesLeft: 0,
          blockLevel: _level,
          remaining: diff,
        );
      }
    }

    return OtpGuardState(
      triesLeft: _remainingTries(),
      blockLevel: OtpBlockLevel.none,
      remaining: Duration.zero,
    );
  }

  static bool canSendOtp() {
    return !status().isBlocked;
  }

  /// ================= FAILURE =================

  static Future<void> recordFailure() async {
    _attempts++;

    if (_attempts == _phase1) {
      await _block(const Duration(minutes: 5), OtpBlockLevel.cooldown5);
    } else if (_attempts == _phase2) {
      await _block(const Duration(minutes: 10), OtpBlockLevel.cooldown10);
    } else if (_attempts == _phase3) {
      await _block(const Duration(minutes: 15), OtpBlockLevel.cooldown15);
    } else if (_attempts >= _phase3 + 1) {
      await _block(const Duration(hours: 1), OtpBlockLevel.blocked1h);
    }

    await _persist();
  }

  /// ================= SUCCESS =================

  static Future<void> resetOnSuccess() async {
    await _reset();
  }

  /// ================= INTERNAL =================

  static int _remainingTries() {
    if (_attempts < _phase1) return _phase1 - _attempts;
    if (_attempts < _phase2) return _phase2 - _attempts;
    if (_attempts < _phase3) return _phase3 - _attempts;
    return 0;
  }

  static Future<void> _block(
      Duration duration, OtpBlockLevel level) async {
    _blockedUntil = DateTime.now().add(duration);
    _level = level;
    await _persist();
  }

  static Future<void> _reset() async {
    _attempts = 0;
    _blockedUntil = null;
    _level = OtpBlockLevel.none;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAttempts);
    await prefs.remove(_keyBlockedUntil);
    await prefs.remove(_keyLevel);
  }

  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAttempts, _attempts);

    if (_blockedUntil != null) {
      await prefs.setInt(
        _keyBlockedUntil,
        _blockedUntil!.millisecondsSinceEpoch,
      );
      await prefs.setInt(_keyLevel, _level.index);
    }
  }

  /// ================= USER MESSAGE =================

  static String message(OtpBlockLevel level) {
    switch (level) {
      case OtpBlockLevel.cooldown5:
      case OtpBlockLevel.cooldown10:
      case OtpBlockLevel.cooldown15:
        return 'Authentication service is temporarily unstable ⛓️‍💥\n'
            'We are working hard to improve the system ❤️‍🩹';

      case OtpBlockLevel.blocked1h:
        return 'System detected unusual activity ⛓️‍💥\n'
            'Please try again later';

      case OtpBlockLevel.none:
        return '';
    }
  }
}
