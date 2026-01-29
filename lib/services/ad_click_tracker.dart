import 'ads.dart';

class AdClickTracker {
  static int _clickCount = 0;

  /// Call ONLY on successful tool use / real navigation
  static void registerClick() {
    _clickCount++;

    // 🔥 Exactly every 4th real click
    if (_clickCount >= 4) {
      if (AdsService.isInterstitialReady) {
        AdsService.showInterstitial();
        _clickCount = 0; // reset ONLY after ad shown
      }
    }
  }

  static void reset() {
    _clickCount = 0;
  }
}