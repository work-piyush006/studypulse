import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  /* ================= BASIC BANNER (SAFE) ================= */

  /// ✅ BACKWARD-COMPATIBLE
  /// Used by Home, Percentage, CGPA, Exam
  static BannerAd? createBanner({
    VoidCallback? onLoaded,
    AdSize size = AdSize.mediumRectangle,
  }) {
    BannerAd? banner;

    banner = BannerAd(
      adUnitId: bannerId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (kDebugMode) debugPrint('✅ Banner loaded');
          onLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          if (kDebugMode) {
            debugPrint('❌ Banner failed: $error');
          }
          ad.dispose();
          banner = null;
        },
      ),
    );

    banner.load();
    return banner;
  }

  /* ================= ADAPTIVE BANNER (OPTIONAL) ================= */

  /// 🔥 HIGHER FILL RATE + RPM
  /// Use only where context is available
  static Future<BannerAd?> createAdaptiveBanner({
    required BuildContext context,
    required void Function(bool loaded) onState,
  }) async {
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
      if (kDebugMode) {
        debugPrint('❌ Adaptive size returned null');
      }
      onState(false);
      return null;
    }

    final banner = BannerAd(
      adUnitId: bannerId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (kDebugMode) debugPrint('✅ Adaptive banner loaded');
          onState(true);
        },
        onAdFailedToLoad: (ad, error) {
          if (kDebugMode) {
            debugPrint('❌ Adaptive banner failed: $error');
          }
          ad.dispose();
          onState(false);
        },
      ),
    );

    await banner.load();
    return banner;
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
          if (_loadAttempts < 3) loadInterstitial();
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