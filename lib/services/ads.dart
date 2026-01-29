import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class AdsService {
  AdsService._();

  static bool _initialized = false;

  static InterstitialAd? _interstitialAd;
  static int _interstitialLoadAttempts = 0;

  /// 🚨 MUST BE FALSE FOR PLAY STORE
  static const bool useTestAds = false;

  /* ===================== AD UNIT IDS ===================== */

  static String get _bannerId {
    return useTestAds
        ? 'ca-app-pub-3940256099942544/6300978111'
        : 'ca-app-pub-2139593035914184/9260573924';
  }

  static String get _interstitialId {
    return useTestAds
        ? 'ca-app-pub-3940256099942544/1033173712'
        : 'ca-app-pub-2139593035914184/1908697513';
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
    final banner = BannerAd(
      adUnitId: _bannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (kDebugMode) debugPrint('Banner loaded');
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );

    banner.load();
    return banner;
  }

  /* ===================== INTERSTITIAL ===================== */

  static Future<void> loadInterstitial() async {
    final hasInternet = await InternetConnectionChecker().hasConnection;
    if (!hasInternet) return;

    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialLoadAttempts = 0;
          ad.setImmersiveMode(true);
        },
        onAdFailedToLoad: (error) {
          _interstitialLoadAttempts++;
          _interstitialAd = null;
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
