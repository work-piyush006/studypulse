// lib/screens/oem_warning_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../home.dart';
import '../services/oem_battery_helper.dart';

class OemWarningScreen extends StatelessWidget {
  const OemWarningScreen({super.key});

  Future<void> _finish(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('oem_permission_done', true);

    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Home()),
      (_) => false,
    );
  }

  Future<void> _openSettingsAndExit(BuildContext context) async {
    try {
      await OemBatteryHelper.openBatterySettings();
    } catch (_) {
      // ❌ OEM intent failed — ignore silently
    }

    // 🔥 ALWAYS EXIT SCREEN AFTER ACTION
    await _finish(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Important'),
        automaticallyImplyLeading: false, // 🔥 NO BACK
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
              const Text(
                'Some phones aggressively block notifications.\n\n'
                'For reliable exam reminders, please allow:\n\n'
                '• Battery usage → Unrestricted\n'
                '• Background activity → Allowed\n'
                '• Disable battery optimization',
                textAlign: TextAlign.center,
              ),
              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _openSettingsAndExit(context),
                  child: const Text('Open Settings'),
                ),
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: () => _finish(context),
                child: const Text('I’ll do it later'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}