// lib/services/ads.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdsService {
  AdsService._();

  /* ================= FLAGS ================= */

  static bool _initialized = false;
  static bool _isLoadingInterstitial = false;
  static InterstitialAd? _interstitialAd;

  /// 🚨 Release build me FALSE hi rahe
  static const bool useTestAds = false;

  /* ================= IDS ================= */

  static String get bannerId => useTestAds
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-2139593035914184/9260573924';

  static String get interstitialId => useTestAds
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-2139593035914184/1908697513';

  /* ================= INTERSTITIAL RULES ================= */

  static const Duration _cooldown = Duration(minutes: 2);
  static const String _lastShownKey = 'last_interstitial_time';

  /* ================= INIT ================= */

  static Future<void> initialize() async {
    if (_initialized) return;

    await MobileAds.instance.initialize();
    _initialized = true;

    if (kDebugMode) {
      debugPrint('✅ MobileAds initialized');
    }
  }

  /* ================= BANNER (SAFE + ADAPTIVE) ================= */

  static Future<BannerAd?> createAdaptiveBanner({
    required BuildContext context,
    required void Function(bool loaded) onState,
  }) async {
    await initialize();

    final hasInternet =
        await InternetConnectionChecker().hasConnection;
    if (!hasInternet) {
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
        onAdLoaded: (_) {
          onState(true);
          if (kDebugMode) debugPrint('✅ Banner loaded');
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          onState(false);
          if (kDebugMode) {
            debugPrint(
              '❌ Banner failed: ${error.code} | ${error.message}',
            );
          }
        },
      ),
    );

    await banner.load();
    return banner;
  }

  /* ================= INTERSTITIAL ================= */

  static Future<bool> _cooldownPassed() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_lastShownKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    return now - last >= _cooldown.inMilliseconds;
  }

  /// 🔁 PRELOAD (CALL ON APP START)
  static Future<void> preloadInterstitial() async {
    await initialize();

    if (_interstitialAd != null || _isLoadingInterstitial) return;

    final hasInternet =
        await InternetConnectionChecker().hasConnection;
    if (!hasInternet) return;

    _isLoadingInterstitial = true;

    InterstitialAd.load(
      adUnitId: interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoadingInterstitial = false;

          ad.setImmersiveMode(true);

          if (kDebugMode) {
            debugPrint('✅ Interstitial READY');
          }
        },
        onAdFailedToLoad: (error) {
          _isLoadingInterstitial = false;
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

  /// 🎯 SAFE SHOW
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