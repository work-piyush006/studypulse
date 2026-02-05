import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/internet_controller.dart';
import 'screens/splash.dart';
import 'widgets/no_internet.dart'; // ← existing widget

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final net = context.watch<InternetController>();

    return Stack(
      children: [
        const SplashScreen(),
        if (net.status == NetStatus.offline)
          const NoInternetScreen(),
      ],
    );
  }
}
