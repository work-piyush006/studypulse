// lib/services/ad_click_tracker.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'ads.dart';

class AdClickTracker {
  static const String _key = 'ad_click_count';
  static const int _threshold = 4;

  /// Call ONLY on meaningful user actions
  static Future<void> registerClick() async {
    final prefs = await SharedPreferences.getInstance();
    int count = prefs.getInt(_key) ?? 0;

    count++;
    await prefs.setInt(_key, count);

    // 🔥 Keep interstitial ready (NON-BLOCKING)
    AdsService.preloadInterstitial();

    // Show on every 4th meaningful click
    if (count < _threshold) return;

    final shown = await AdsService.showInterstitialIfAllowed();

    // Reset ONLY if ad actually shown
    if (shown) {
      await prefs.setInt(_key, 0);
    }
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, 0);
  }
}