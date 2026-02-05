import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

enum NetStatus { online, offline }

class InternetController extends ChangeNotifier {
  NetStatus status = NetStatus.online;
  StreamSubscription? _sub;

  void start() {
    _sub = Connectivity().onConnectivityChanged.listen((result) {
      final next =
          result == ConnectivityResult.none ? NetStatus.offline : NetStatus.online;
      if (next != status) {
        status = next;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
