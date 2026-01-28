import 'dart:async';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

/// 🔥 Global Internet Service
/// - Detects internet every second
/// - Shows NO INTERNET screen immediately
/// - Shows snackbar on SLOW connection
/// - Works while app is running (not only at launch)
class InternetService {
  static final InternetConnectionChecker _checker =
      InternetConnectionChecker.createInstance(
    checkInterval: const Duration(seconds: 1),
  );

  static StreamSubscription<InternetConnectionStatus>? _subscription;

  static final ValueNotifier<bool> isConnected =
      ValueNotifier<bool>(true);

  static final ValueNotifier<bool> isSlow =
      ValueNotifier<bool>(false);

  /// Start monitoring (call in main.dart)
  static void startMonitoring(BuildContext context) {
    _subscription?.cancel();

    _subscription = _checker.onStatusChange.listen((status) {
      final connected = status == InternetConnectionStatus.connected;

      if (!connected) {
        isConnected.value = false;
        isSlow.value = false;
        return;
      }

      isConnected.value = true;
      _checkSpeed(context);
    });
  }

  /// Stop monitoring (optional)
  static void stopMonitoring() {
    _subscription?.cancel();
  }

  /// 🔍 Detect slow internet (ads ke liye important)
  static Future<void> _checkSpeed(BuildContext context) async {
    final stopwatch = Stopwatch()..start();

    try {
      await InternetConnectionChecker().hasConnection;
      stopwatch.stop();

      // ⚠️ 2.5 sec se zyada = slow
      if (stopwatch.elapsedMilliseconds > 2500) {
        isSlow.value = true;
        _showSnack(context, '⚠️ Slow Internet Connection');
      } else {
        isSlow.value = false;
      }
    } catch (_) {
      isSlow.value = true;
    }
  }

  /// Snackbar (safe global)
  static void _showSnack(BuildContext context, String text) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
