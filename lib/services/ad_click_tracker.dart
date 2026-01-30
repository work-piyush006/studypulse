// lib/services/ad_click_tracker.dart

import 'ads.dart';

class AdClickTracker {
  /// Counts ONLY meaningful user actions
  static int _count = 0;

  /// Call ONLY on real actions
  /// (bottom nav, tool open, successful calculate/set/cancel)
  static Future<void> registerClick() async {
    _count++;

    // 🔁 Always keep interstitial ready
    AdsService.preload();

    // 🎯 Show on every 4th VALID action
    if (_count < 4) return;

    if (AdsService.isReady) {
      final shown = await AdsService.showIfAllowed();

      // 🔥 RESET only if ad ACTUALLY shown
      if (shown) {
        _count = 0;
      }
    }
  }

  static void reset() {
    _count = 0;
  }
}