// lib/services/ads.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdsService {
  AdsService._();

  static bool _initialized = false;

  /* ================= INTERSTITIAL ================= */

  static InterstitialAd? _interstitialAd;
  static bool _isLoading = false;

  /// 🚨 MUST stay FALSE for Play Store
  static const bool useTestAds = false;

  /// ⏱️ Play-Store safe cooldown
  static const Duration _cooldown = Duration(minutes: 2);
  static const String _lastShownKey = 'last_interstitial_time';

  /* ================= AD IDS ================= */

  static String get bannerId =>
      useTestAds
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-2139593035914184/9260573924';

  static String get interstitialId =>
      useTestAds
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-2139593035914184/1908697513';

  /* ================= INIT ================= */

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
    } catch (_) {
      // Ads must NEVER crash app
    }
  }

  /* ================= BANNER ================= */

  /// 🔥 Adaptive banner (highest fill-rate)
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
          onState(true);
          if (kDebugMode) debugPrint('✅ Banner loaded');
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          onState(false);
          if (kDebugMode) {
            debugPrint('❌ Banner failed: $error');
          }
        },
      ),
    );

    banner.load();
    return banner;
  }

  /* ================= INTERSTITIAL ================= */

  static bool get isReady => _interstitialAd != null;

  /// 🔁 Safe preload (call on every valid click)
  static Future<void> preload() async {
    if (!_initialized) await initialize();
    if (_interstitialAd != null || _isLoading) return;

    final hasInternet =
        await InternetConnectionChecker().hasConnection;
    if (!hasInternet) return;

    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getInt(_lastShownKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (now - lastShown < _cooldown.inMilliseconds) return;

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
        onAdFailedToLoad: (_) {
          _isLoading = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  /// 🎯 Show + auto-reload
  static Future<void> show() async {
    if (_interstitialAd == null) return;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(_lastShownKey, now);

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
  }
}