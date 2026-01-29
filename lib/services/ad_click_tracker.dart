import 'ads.dart';

class AdClickTracker {
  static int _clickCount = 0;

  static void registerClick() {
    _clickCount++;

    // 🔥 Har 4th click par
    if (_clickCount % 4 == 0) {
      AdsService.showInterstitial(); // safe call
    }
  }

  static void reset() {
    _clickCount = 0;
  }
}