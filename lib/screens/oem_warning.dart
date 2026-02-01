import 'package:flutter/material.dart';
import '../services/oem_battery_helper.dart';

class OemWarningScreen extends StatelessWidget {
  const OemWarningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Important')),
      body: Padding(
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
              'Your phone may block StudyPulse from sending reminders.\n\n'
              'To receive exam notifications reliably, please allow:\n'
              '• Battery usage → Unrestricted\n'
              '• Background activity → Allowed\n'
              '• Remove battery optimization',
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () async {
                await OemBatteryHelper.openBatterySettings();
              },
              child: const Text('Open Settings'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('I’ll do it later'),
            ),
          ],
        ),
      ),
    );
  }
}