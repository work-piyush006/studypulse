// lib/services/ad_click_tracker.dart

import 'ads.dart';

class AdClickTracker {
  static int _count = 0;

  /// Call ONLY on meaningful user actions
  static Future<void> registerClick() async {
    _count++;

    // Always keep ad ready
    await AdsService.preloadInterstitial();

    // Show on every 4th meaningful click
    if (_count < 4) return;

    final shown = await AdsService.showInterstitialIfAllowed();

    // Reset ONLY if ad actually shown
    if (shown) {
      _count = 0;
    }
  }

  static void reset() {
    _count = 0;
  }
}