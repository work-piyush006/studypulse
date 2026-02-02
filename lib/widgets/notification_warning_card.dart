import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationWarningCard extends StatelessWidget {
  const NotificationWarningCard({super.key});

  Future<void> _openSettings() async {
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.withOpacity(0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(
          Icons.notifications_off_rounded,
          color: Colors.orange,
        ),
        title: const Text(
          'Notifications disabled',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text(
          'Enable notifications to receive exam reminders on time.',
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _openSettings,
      ),
    );
  }
}