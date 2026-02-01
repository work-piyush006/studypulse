import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class OemPermissionScreen extends StatelessWidget {
  const OemPermissionScreen({super.key});

  Future<void> _openSettings(BuildContext context) async {
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enable Background Notifications'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.notifications_active, size: 60),
            const SizedBox(height: 20),

            const Text(
              'Important Step',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            const Text(
              'Some phones (iQOO, Vivo, OnePlus, Samsung) block notifications '
              'in the background even after permission is granted.\n\n'
              'Please allow background activity & disable battery optimization '
              'for StudyPulse.',
              style: TextStyle(fontSize: 15),
            ),

            const SizedBox(height: 24),

            const Text(
              'What to enable:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            const Text('• Allow background activity'),
            const Text('• Disable battery optimization'),
            const Text('• Allow auto-start (if available)'),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _openSettings(context),
                child: const Text('OPEN SETTINGS'),
              ),
            ),

            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/home');
              },
              child: const Text('I’ll do it later'),
            ),
          ],
        ),
      ),
    );
  }
}