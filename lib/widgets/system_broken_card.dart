import 'package:flutter/material.dart';
import '../services/system_status_service.dart';

class SystemBrokenCard extends StatelessWidget {
  final SystemStatus status;

  const SystemBrokenCard({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    if (!status.broken) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.55),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Material(
            borderRadius: BorderRadius.circular(20),
            elevation: 12,
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 32,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// 🔝 LOGO
                  Image.asset(
                    'assets/logo.png',
                    height: 80,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.school_rounded,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// 🔒 ICON
                  Icon(
                    status.icon,
                    size: 48,
                    color: Colors.redAccent,
                  ),

                  const SizedBox(height: 16),

                  /// 🧠 TITLE
                  Text(
                    status.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// ❤️‍🩹 MESSAGE
                  Text(
                    status.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// ✅ OK BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
