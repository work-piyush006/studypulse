import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class AdsService {
  AdsService._();

  static bool _initialized = false;
  static InterstitialAd? _interstitialAd;
  static int _interstitialLoadAttempts = 0;

  /// 🔥 CHANGE THIS TO false WHEN YOU PUBLISH
  static const bool useTestAds = true;

  /* ===================== AD IDS ===================== */

  static String get _bannerId {
    if (useTestAds) {
      return Platform.isAndroid
          ? BannerAd.testAdUnitId
          : BannerAd.testAdUnitId;
    }
    return 'ca-app-pub-2139593035914184/9260573924';
  }

  static String get _interstitialId {
    if (useTestAds) {
      return Platform.isAndroid
          ? InterstitialAd.testAdUnitId
          : InterstitialAd.testAdUnitId;
    }
    return 'ca-app-pub-2139593035914184/1908697513';
  }

  /* ===================== INIT ===================== */

  static Future<void> initialize() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
    loadInterstitial();
  }

  /* ===================== BANNER ===================== */

  static BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: _bannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (kDebugMode) {
            debugPrint('❌ Banner failed: $error');
          }
        },
      ),
    );
  }

  /* ===================== INTERSTITIAL ===================== */

  static void loadInterstitial() async {
    final hasInternet = await InternetConnectionChecker().hasConnection;
    if (!hasInternet) return;

    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _interstitialLoadAttempts = 0;

          ad.setImmersiveMode(true);

          if (kDebugMode) {
            debugPrint('✅ Interstitial loaded');
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          _interstitialLoadAttempts++;
          _interstitialAd = null;

          if (kDebugMode) {
            debugPrint('❌ Interstitial failed: $error');
          }

          if (_interstitialLoadAttempts < 3) {
            loadInterstitial();
          }
        },
      ),
    );
  }

  static void showInterstitial() {
    if (_interstitialAd == null) return;

    _interstitialAd!.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitial();
      },
    );

    _interstitialAd!.show();
    _interstitialAd = null;
  }
}
