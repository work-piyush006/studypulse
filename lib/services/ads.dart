import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class AdsService {
  AdsService._();

  static bool _initialized = false;

  static InterstitialAd? _interstitialAd;
  static int _loadAttempts = 0;

  /// 🚨 PLAY STORE KE LIYE HAMESHA FALSE
  static const bool useTestAds = false;

  /* ================= AD UNIT IDS ================= */

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

    await MobileAds.instance.initialize();
    _initialized = true;

    loadInterstitial();
  }

  /* ================= BANNER ================= */

  static BannerAd createBanner() {
    final ad = BannerAd(
      adUnitId: bannerId,
      size: AdSize.mediumRectangle, // 🔥 Square banner
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    );

    ad.load();
    return ad;
  }

  /* ================= INTERSTITIAL ================= */

  static Future<void> loadInterstitial() async {
    final hasInternet =
        await InternetConnectionChecker().hasConnection;
    if (!hasInternet) return;

    InterstitialAd.load(
      adUnitId: interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _loadAttempts = 0;
          ad.setImmersiveMode(true);
        },
        onAdFailedToLoad: (_) {
          _loadAttempts++;
          _interstitialAd = null;
          if (_loadAttempts < 3) loadInterstitial();
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
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitial();
      },
    );

    _interstitialAd!.show();
    _interstitialAd = null;
  }
}