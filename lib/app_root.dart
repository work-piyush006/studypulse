import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/internet_controller.dart';
import 'screens/splash.dart';
import 'screens/no_internet.dart';
import 'screens/auth_gate.dart';

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();

    // ⏳ Splash for fixed time
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (mounted) {
        setState(() => _showSplash = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final net = context.watch<InternetController>();

    return Stack(
      children: [
        // 🔹 Main app flow
        if (_showSplash)
          const SplashScreen()
        else
          const AuthGate(),

        // 🔹 Global no-internet overlay
        if (net.status == NetStatus.offline)
          const NoInternetScreen(),
      ],
    );
  }
}
