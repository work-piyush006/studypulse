import 'package:flutter/material.dart';
import '../services/internet.dart';
import '../screens/no_internet.dart';

class InternetGuard extends StatefulWidget {
  final Widget child;
  const InternetGuard({super.key, required this.child});

  @override
  State<InternetGuard> createState() => _InternetGuardState();
}

class _InternetGuardState extends State<InternetGuard> {
  late VoidCallback _slowListener;

  @override
  void initState() {
    super.initState();

    _slowListener = () {
      if (InternetService.isSlow.value && mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Slow Internet Connection'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    };

    InternetService.isSlow.addListener(_slowListener);
  }

  @override
  void dispose() {
    InternetService.isSlow.removeListener(_slowListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: InternetService.isConnected,
      builder: (_, connected, __) {
        if (!connected) {
          // ❌ Full app blocked
          return const NoInternetScreen();
        }

        // ✅ Internet OK
        return widget.child;
      },
    );
  }
}
