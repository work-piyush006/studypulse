// lib/services/internet.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class InternetService {
  static final InternetConnectionChecker _checker =
      InternetConnectionChecker.createInstance(
    checkInterval: const Duration(seconds: 3),
  );

  static StreamSubscription<InternetConnectionStatus>? _sub;

  static final ValueNotifier<bool> isConnected =
      ValueNotifier<bool>(true);

  static final ValueNotifier<bool> isSlow =
      ValueNotifier<bool>(false);

  /// Call ONCE from main.dart
  static void startMonitoring() {
    _sub?.cancel();

    _sub = _checker.onStatusChange.listen((status) async {
      final connected =
          status == InternetConnectionStatus.connected;
      isConnected.value = connected;

      if (!connected) {
        isSlow.value = false;
        return;
      }

      final start = DateTime.now();
      await _checker.hasConnection;
      final ms =
          DateTime.now().difference(start).inMilliseconds;

      isSlow.value = ms > 2500; // >2.5s = slow
    });
  }

  static void stop() {
    _sub?.cancel();
    _sub = null;
  }
}