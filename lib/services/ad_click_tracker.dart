// lib/services/ad_click_tracker.dart

import 'ads.dart';

class AdClickTracker {
  static int _actionCount = 0;
  static DateTime? _lastAdTime;

  /// 🔁 Call ONLY after a meaningful completed action
  /// Examples:
  /// - Tool successfully used
  /// - Navigation to major screen
  static void registerClick() {
    _actionCount++;

    // 🔒 Safety: prevent infinite growth
    if (_actionCount > 1000) {
      _actionCount = _actionCount % 4;
    }

    // 🎯 Show interstitial on every 4th action
    if (_actionCount % 4 != 0) return;

    // ⏱ Cooldown: minimum 45 sec between ads
    final now = DateTime.now();
    if (_lastAdTime != null &&
        now.difference(_lastAdTime!).inSeconds < 45) {
      return;
    }

    // ✅ Show only if ad is ready
    if (AdsService.isInterstitialReady) {
      AdsService.showInterstitial();
      _lastAdTime = now;
    }
  }

  /// 🔄 Optional: reset on logout / major reset
  static void reset() {
    _actionCount = 0;
    _lastAdTime = null;
  }
}