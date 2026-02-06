import 'dart:async';

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
}

class OtpGuardService {
  static int _attempts = 0;
  static DateTime? _blockedUntil;
  static OtpBlockLevel _level = OtpBlockLevel.none;

  static const int _maxAttempts = 3;

  /// ================= CHECK =================

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
      triesLeft: _maxAttempts - _attempts,
      blockLevel: OtpBlockLevel.none,
      remaining: Duration.zero,
    );
  }

  /// ================= RECORD FAILURE =================

  static void recordFailure() {
    _attempts++;

    if (_attempts == 3) {
      _block(const Duration(minutes: 5), OtpBlockLevel.cooldown5);
    } else if (_attempts == 5) {
      _block(const Duration(minutes: 10), OtpBlockLevel.cooldown10);
    } else if (_attempts == 6) {
      _block(const Duration(minutes: 15), OtpBlockLevel.cooldown15);
    } else if (_attempts >= 7) {
      _block(const Duration(hours: 1), OtpBlockLevel.blocked1h);
    }
  }

  /// ================= SUCCESS =================

  static void resetOnSuccess() {
    _reset();
  }

  /// ================= INTERNAL =================

  static void _block(Duration duration, OtpBlockLevel level) {
    _blockedUntil = DateTime.now().add(duration);
    _level = level;
  }

  static void _reset() {
    _attempts = 0;
    _blockedUntil = null;
    _level = OtpBlockLevel.none;
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
