import 'package:flutter/material.dart';
import 'dart:async';
import 'package:internet_connection_checker/internet_connection_checker.dart';

/// 🌐 Global Internet Service (PRODUCTION SAFE)
class InternetService {
  static final InternetConnectionChecker _checker =
      InternetConnectionChecker.createInstance(
    checkInterval: const Duration(seconds: 3),
  );

  static StreamSubscription<InternetConnectionStatus>? _subscription;

  /// 🔌 Internet state
  static final ValueNotifier<bool> isConnected =
      ValueNotifier<bool>(true);

  /// 🐢 Slow internet hint (ads / api)
  static final ValueNotifier<bool> isSlow =
      ValueNotifier<bool>(false);

  /// 🚀 Call once in main.dart
  static void startMonitoring() {
    _subscription?.cancel();

    _subscription = _checker.onStatusChange.listen((status) async {
      final connected = status == InternetConnectionStatus.connected;
      isConnected.value = connected;

      if (!connected) {
        isSlow.value = false;
        return;
      }

      // Lightweight slow check
      final start = DateTime.now();
      await _checker.hasConnection;
      final diff = DateTime.now().difference(start).inMilliseconds;

      isSlow.value = diff > 2500; // >2.5s = slow
    });
  }

  static void stop() {
    _subscription?.cancel();
  }
}
