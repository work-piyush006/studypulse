import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class OemBatteryHelper {
  OemBatteryHelper._();

  /// Detect OEMs that aggressively kill background apps
  static Future<bool> isAggressiveOem() async {
    if (!Platform.isAndroid) return false;

    final info = await DeviceInfoPlugin().androidInfo;
    final brand = info.manufacturer.toLowerCase();

    return brand.contains('vivo') ||
        brand.contains('iqoo') ||
        brand.contains('xiaomi') ||
        brand.contains('redmi') ||
        brand.contains('oppo') ||
        brand.contains('realme') ||
        brand.contains('oneplus') ||
        brand.contains('samsung');
  }

  /// Opens best possible system settings screen
  static Future<void> openBatterySettings() async {
    // Universal safe fallback
    await openAppSettings();
  }

  /// Human-readable OEM name
  static Future<String> deviceName() async {
    final info = await DeviceInfoPlugin().androidInfo;
    return info.manufacturer;
  }
}