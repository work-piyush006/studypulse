import 'dart:io';

class OemDetector {
  static String get _info {
    if (!Platform.isAndroid) return '';
    return Platform.operatingSystemVersion.toLowerCase();
  }

  static bool get isXiaomi =>
      _info.contains('xiaomi') ||
      _info.contains('redmi') ||
      _info.contains('miui');

  static bool get isVivo => _info.contains('vivo');

  static bool get isOppo => _info.contains('oppo');

  static bool get isRealme => _info.contains('realme');

  static bool get isSamsung => _info.contains('samsung');

  /// Phones that ACTUALLY kill notifications
  static bool get needsAggressiveHelp =>
      isXiaomi || isVivo || isOppo || isRealme;
}