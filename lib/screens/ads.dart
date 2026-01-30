// lib/services/ads.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdsService {
  AdsService._();

  static bool _initialized = false;

  /* ================= BANNER ================= */

  static const int _maxBannerRetry = 3;
  static int _bannerRetryCount = 0;

  /* ================= INTERSTITIAL ================= */

  static InterstitialAd? _interstitialAd;
  static bool _isLoading = false;

  /// 🚨 Release build me FALSE hi rahe
  static const bool useTestAds = false;

  /// ⏱️ Cooldown only for interstitial SHOW
  static const Duration _cooldown = Duration(minutes: 2);
  static const String _lastShownKey = 'last_interstitial_time';

  /* ================= AD IDS ================= */

  static String get bannerId => useTestAds
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-2139593035914184/9260573924';

  static String get interstitialId => useTestAds
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-2139593035914184/1908697513';

  /* ================= INIT ================= */

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      if (kDebugMode) debugPrint('✅ MobileAds initialized');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ MobileAds init failed: $e');
    }
  }

  /* ================= BANNER (WITH RETRY) ================= */

  static Future<BannerAd?> createAdaptiveBanner({
    required BuildContext context,
    required void Function(bool loaded) onState,
  }) async {
    if (!_initialized) await initialize();

    final hasInternet =
        await InternetConnectionChecker().hasConnection;
    if (!hasInternet) {
      onState(false);
      return null;
    }

    final width = MediaQuery.of(context).size.width.truncate();
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
        onAdLoaded: (_) {
          _bannerRetryCount = 0;
          onState(true);
          if (kDebugMode) debugPrint('✅ Banner loaded');
        },
        onAdFailedToLoad: (ad, error) async {
          ad.dispose();
          onState(false);

          if (kDebugMode) {
            debugPrint(
              '❌ Banner failed (${_bannerRetryCount + 1}/$_maxBannerRetry): '
              '${error.code} | ${error.message}',
            );
          }

          if (_bannerRetryCount < _maxBannerRetry - 1) {
            _bannerRetryCount++;

            // ⏳ exponential backoff (2s, 4s)
            await Future.delayed(
              Duration(seconds: 2 * _bannerRetryCount),
            );

            if (kDebugMode) {
              debugPrint('🔁 Retrying banner load...');
            }

            createAdaptiveBanner(
              context: context,
              onState: onState,
            );
          }
        },
      ),
    );

    banner.load();
    return banner;
  }

  /* ================= INTERSTITIAL ================= */

  static bool get isReady => _interstitialAd != null;

  static Future<bool> _cooldownPassed() async {
    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getInt(_lastShownKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    return now - lastShown >= _cooldown.inMilliseconds;
  }

  /// 🔁 Preload safe
  static Future<void> preload() async {
    if (!_initialized) await initialize();
    if (_interstitialAd != null || _isLoading) return;

    final hasInternet =
        await InternetConnectionChecker().hasConnection;
    if (!hasInternet) return;

    _isLoading = true;

    InterstitialAd.load(
      adUnitId: interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoading = false;
          ad.setImmersiveMode(true);
          if (kDebugMode) debugPrint('✅ Interstitial READY');
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          _interstitialAd = null;
          if (kDebugMode) {
            debugPrint(
              '❌ Interstitial failed: ${error.code} | ${error.message}',
            );
          }
        },
      ),
    );
  }

  /// 🎯 Safe show
  static Future<bool> showIfAllowed() async {
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
        preload();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _interstitialAd = null;
        preload();
      },
    );

    _interstitialAd!.show();
    _interstitialAd = null;
    return true;
  }
}