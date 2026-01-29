import 'ads.dart';

class AdClickTracker {
  static int _clickCount = 0;

  /// Call ONLY on successful tool use / real navigation
  static void registerClick() {
    _clickCount++;

    // 🔥 Show ad exactly on every 4th real action
    if (_clickCount % 4 == 0) {
      AdsService.showInterstitial();
    }

    // 🔒 Safety: never let counter grow infinitely
    if (_clickCount >= 1000) {
      _clickCount = _clickCount % 4;
    }
  }

  static void reset() {
    _clickCount = 0;
  }
}