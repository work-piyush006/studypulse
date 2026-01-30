// lib/services/ad_click_tracker.dart

import 'ads.dart';

class AdClickTracker {
  /// Counts ONLY valid user actions
  static int _count = 0;

  /// Call this on REAL, meaningful actions only
  /// (bottom nav, tool open, successful set/cancel, calculate button)
  static void registerClick() {
    _count++;

    // 🔄 Always try preload (safe to call many times)
    AdsService.preload();

    // 🎯 We want interstitial on every 4th VALID action
    if (_count < 4) return;

    // ❗ Show ONLY if ad is actually ready
    if (AdsService.isReady) {
      AdsService.show();

      // 🔥 RESET only after show attempt
      _count = 0;
    }
    // else:
    // ad not ready → DO NOT reset count
    // next valid click will retry
  }

  /// Optional hard reset (logout / app reset)
  static void reset() {
    _count = 0;
  }
}