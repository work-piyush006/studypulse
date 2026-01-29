import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class AdsService {
  AdsService._();

  static bool _initialized = false;

  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialReady = false;
  static int _loadAttempts = 0;

  /// 🚨 MUST BE FALSE FOR PLAY STORE
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
  /// UI must decide what to show if ad fails
  static BannerAd createBanner({
    required VoidCallback onLoaded,
    required VoidCallback onFailed,
  }) {
    final ad = BannerAd(
      adUnitId: bannerId,
      size: AdSize.mediumRectangle,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (kDebugMode) debugPrint('✅ Banner loaded');
          onLoaded();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (kDebugMode) debugPrint('❌ Banner failed: $error');
          onFailed();
        },
      ),
    );

    ad.load();
    return ad;
  }

  /* ================= INTERSTITIAL ================= */

  static bool get isInterstitialReady =>
      _isInterstitialReady && _interstitialAd != null;

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
          _isInterstitialReady = true;
          _loadAttempts = 0;
          ad.setImmersiveMode(true);

          if (kDebugMode) debugPrint('✅ Interstitial loaded');
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isInterstitialReady = false;
          _loadAttempts++;

          if (kDebugMode) debugPrint('❌ Interstitial failed: $error');

          if (_loadAttempts < 3) {
            loadInterstitial();
          }
        },
      ),
    );
  }

  static void showInterstitial() {
    if (!isInterstitialReady) return;

    _interstitialAd!.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _isInterstitialReady = false;
        loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _interstitialAd = null;
        _isInterstitialReady = false;
        loadInterstitial();
      },
    );

    _interstitialAd!.show();
    _interstitialAd = null;
    _isInterstitialReady = false;
  }
}