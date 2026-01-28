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
  @override
  void initState() {
    super.initState();

    // 🔔 Listen slow internet
    InternetService.isSlow.addListener(() {
      if (InternetService.isSlow.value) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Slow Internet Connection'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: InternetService.isConnected,
      builder: (_, connected, __) {
        if (!connected) {
          return const NoInternetScreen();
        }
        return widget.child;
      },
    );
  }
}
