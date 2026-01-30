import 'ads.dart';

class AdClickTracker {
  static int _count = 0;

  /// Call on REAL actions only
  static void registerClick() {
    _count++;

    // 🔥 Always try preload in background
    AdsService.preload();

    // 🎯 Show on every 4th action
    if (_count % 4 == 0) {
      AdsService.show();
    }

    if (_count > 1000) {
      _count = _count % 4;
    }
  }

  static void reset() {
    _count = 0;
  }
}