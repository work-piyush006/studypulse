import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/oem_battery_helper.dart';
import '../services/oem_detector.dart';

class OemWarningScreen extends StatelessWidget {
  const OemWarningScreen({super.key});

  /* ================= MESSAGE ================= */

  String _message() {
    if (OemDetector.isXiaomi) {
      return 'Xiaomi phones aggressively block notifications.\n\n'
          'Please do ALL of these:\n'
          '• Battery → No restrictions\n'
          '• Auto-start → ON\n'
          '• Lock app in recent apps';
    }

    if (OemDetector.isVivo ||
        OemDetector.isOppo ||
        OemDetector.isRealme) {
      return 'Your phone may stop notifications in background.\n\n'
          'Please allow:\n'
          '• Battery usage → Unrestricted\n'
          '• Background activity → Allowed';
    }

    if (OemDetector.isSamsung) {
      return 'Samsung may limit background apps.\n\n'
          'Please:\n'
          '• Battery → No limits\n'
          '• Disable “Put app to sleep”';
    }

    return 'Please allow background activity\n'
        'to receive exam reminders on time.';
  }

  /* ================= ACTIONS ================= */

  Future<void> _done(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('oem_permission_done', true);

    if (context.mounted) {
      Navigator.of(context).pop(); // ✅ ONLY POP
    }
  }

  Future<void> _openSettings(BuildContext context) async {
    try {
      await OemBatteryHelper.openBatterySettings();
    } catch (_) {}

    // 🚫 NEVER navigate after OEM intent
    await _done(context);
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Important'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 80,
                color: Colors.orange,
              ),
              const SizedBox(height: 20),
              const Text(
                'Enable Background Activity',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // 🔥 OEM-SPECIFIC MESSAGE
              Text(
                _message(),
                textAlign: TextAlign.center,
              ),

              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _openSettings(context),
                  child: const Text('Open Settings'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _done(context),
                child: const Text('I’ll do it later'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}