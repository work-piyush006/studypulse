import 'ads.dart';

class AdClickTracker {
  static int _clickCount = 0;

  static void registerClick() {
    _clickCount++;

    // 🔥 Every 4th click → try interstitial
    if (_clickCount % 4 == 0) {
      if (AdsService.isInterstitialReady) {
        AdsService.showInterstitial();
      }
    }
  }

  static void reset() {
    _clickCount = 0;
  }
}