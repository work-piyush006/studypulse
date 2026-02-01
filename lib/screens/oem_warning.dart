import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/oem_battery_helper.dart';

class OemWarningScreen extends StatelessWidget {
  const OemWarningScreen({super.key});

  Future<void> _done(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('oem_permission_done', true);

    if (context.mounted) {
      Navigator.of(context).pop(); // 🔥 ONLY POP
    }
  }

  Future<void> _openSettings(BuildContext context) async {
    try {
      await OemBatteryHelper.openBatterySettings();
    } catch (_) {}

    // 🔥 NEVER NAVIGATE AFTER OEM INTENT
    await _done(context);
  }

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
              const Icon(Icons.warning_amber_rounded,
                  size: 80, color: Colors.orange),
              const SizedBox(height: 20),
              const Text(
                'Enable Background Activity',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Some phones block notifications.\n\n'
                'Please allow:\n'
                '• Battery usage → Unrestricted\n'
                '• Background activity → Allowed',
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