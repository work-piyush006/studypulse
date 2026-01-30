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

  /// 🚨 MUST BE FALSE FOR PLAY STORE RELEASE
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

  /// ✅ SAFE INIT (NO AD LOAD, NO CRASH)
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      await MobileAds.instance.initialize();
      _initialized = true;
    } catch (_) {
      // 🔥 Ads must NEVER crash app
    }
  }

  /* ================= BASIC BANNER ================= */

  /// ✅ RELEASE SAFE BANNER
  static BannerAd createBanner({
    required void Function(bool loaded) onState,
    AdSize size = AdSize.mediumRectangle,
  }) {
    final banner = BannerAd(
      adUnitId: bannerId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (kDebugMode) debugPrint('✅ Banner loaded');
          onState(true);
        },
        onAdFailedToLoad: (ad, error) {
          if (kDebugMode) {
            debugPrint('❌ Banner failed: $error');
          }
          ad.dispose();
          onState(false);
        },
      ),
    );

    banner.load();
    return banner;
  }

  /* ================= ADAPTIVE BANNER ================= */

  /// ✅ BEST RPM + SAFE
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
        debugPrint('❌ Adaptive banner size null');
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

    banner.load();
    return banner;
  }

  /* ================= INTERSTITIAL ================= */

  static bool get isInterstitialReady =>
      _isInterstitialReady && _interstitialAd != null;

  /// ✅ PRELOAD ONLY AFTER USER ACTION
  static Future<void> loadInterstitial() async {
    final hasInternet =
        await InternetConnectionChecker().hasConnection;

    if (!hasInternet || _isInterstitialReady) return;

    InterstitialAd.load(
      adUnitId: interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialReady = true;
          _loadAttempts = 0;
          ad.setImmersiveMode(true);

          if (kDebugMode) {
            debugPrint('✅ Interstitial loaded');
          }
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isInterstitialReady = false;
          _loadAttempts++;

          if (kDebugMode) {
            debugPrint('❌ Interstitial failed: $error');
          }

          if (_loadAttempts < 3) {
            loadInterstitial();
          }
        },
      ),
    );
  }

  /// ✅ SHOW ONLY WHEN READY
  static void showInterstitial() {
    if (!isInterstitialReady) return;

    _interstitialAd!.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _resetInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _resetInterstitial();
      },
    );

    _interstitialAd!.show();
    _resetInterstitial();
  }

  static void _resetInterstitial() {
    _interstitialAd = null;
    _isInterstitialReady = false;
  }
}