// lib/services/ads.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdsService {
  AdsService._();

  /* ================= FLAGS ================= */

  static bool _initialized = false;

  /// 🚨 Release build me FALSE hi rahe
  static const bool useTestAds = false;

  /* ================= IDS ================= */

  static String get bannerId => useTestAds
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-2139593035914184/9260573924';

  static String get interstitialId => useTestAds
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-2139593035914184/1908697513';

  /* ================= BANNER RETRY RULES ================= */

  static const int _maxBannerRetry = 3;
  static const Duration _retryGap = Duration(seconds: 2);
  static const Duration _cooldown = Duration(minutes: 3);

  static const String _retryCountKey = 'banner_retry_count';
  static const String _cooldownUntilKey = 'banner_cooldown_until';

  static Timer? _retryTimer;

  /* ================= INIT ================= */

  static Future<void> initialize() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;

    if (kDebugMode) {
      debugPrint('✅ MobileAds initialized');
    }

    // 🔥 Preload interstitial early
    preloadInterstitial();
  }

  /* ================= BANNER (RETRY SAFE) ================= */

  static Future<BannerAd?> createAdaptiveBanner({
    required BuildContext context,
    required void Function(bool loaded) onState,
  }) async {
    await initialize();

    final prefs = await SharedPreferences.getInstance();

    // ⛔ Cooldown active?
    final cooldownUntil = prefs.getInt(_cooldownUntilKey) ?? 0;
    if (DateTime.now().millisecondsSinceEpoch < cooldownUntil) {
      onState(false);
      return null;
    }

    final width = MediaQuery.of(context).size.width.truncate();
    if (width <= 0) {
      onState(false);
      return null;
    }

    final size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      width,
    );

    if (size == null) {
      onState(false);
      return null;
    }

    final banner = BannerAd(
      adUnitId: bannerId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) async {
          _retryTimer?.cancel();
          await prefs.setInt(_retryCountKey, 0);
          onState(true);
        },
        onAdFailedToLoad: (ad, _) async {
          ad.dispose();

          int retry = prefs.getInt(_retryCountKey) ?? 0;
          retry++;

          if (retry >= _maxBannerRetry) {
            await prefs.setInt(_retryCountKey, 0);
            await prefs.setInt(
              _cooldownUntilKey,
              DateTime.now()
                  .add(_cooldown)
                  .millisecondsSinceEpoch,
            );
            onState(false);
            return;
          }

          await prefs.setInt(_retryCountKey, retry);

          _retryTimer?.cancel();
          _retryTimer = Timer(_retryGap, () {
            createAdaptiveBanner(
              context: context,
              onState: onState,
            );
          });
        },
      ),
    );

    await banner.load();
    return banner;
  }

  /* ================= INTERSTITIAL ================= */

  static InterstitialAd? _interstitialAd;
  static bool _isLoadingInterstitial = false;

  static const Duration _interstitialCooldown =
      Duration(minutes: 2);
  static const String _lastShownKey = 'last_interstitial_time';

  static Future<bool> _cooldownPassed() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_lastShownKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    return now - last >= _interstitialCooldown.inMilliseconds;
  }

  static Future<void> preloadInterstitial() async {
    if (_interstitialAd != null || _isLoadingInterstitial) return;

    _isLoadingInterstitial = true;

    InterstitialAd.load(
      adUnitId: interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoadingInterstitial = false;
          ad.setImmersiveMode(true);
        },
        onAdFailedToLoad: (_) {
          _isLoadingInterstitial = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  static Future<bool> showInterstitialIfAllowed() async {
    if (_interstitialAd == null) return false;
    if (!await _cooldownPassed()) return false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _lastShownKey,
      DateTime.now().millisecondsSinceEpoch,
    );

    _interstitialAd!.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        preloadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _interstitialAd = null;
        preloadInterstitial();
      },
    );

    _interstitialAd!.show();
    _interstitialAd = null;
    return true;
  }
}