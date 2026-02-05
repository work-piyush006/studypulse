import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:permission_handler/permission_handler.dart';

import 'tools/percentage.dart';
import 'tools/cgpa.dart';
import 'tools/exam.dart';

import 'services/ads.dart';
import 'services/ad_click_tracker.dart';
import 'services/notification_store.dart';
import 'services/fcm_service.dart';

import 'widgets/ad_placeholder.dart';
import 'widgets/notification_warning_card.dart';
import 'state/exam_state.dart';
import 'screens/notification_inbox.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final ValueNotifier<String> _quote = ValueNotifier('');

  bool _fcmInitDone = false; // 🔒 CRITICAL GUARD

  @override
  void initState() {
    super.initState();

    // 🔥 Restore exam data (safe – idempotent)
    ExamState.init();

    // 🔔 Init FCM ONCE only
    if (!_fcmInitDone) {
      FCMService.init();
      _fcmInitDone = true;
    }

    // 📢 Ads
    AdsService.initialize();

    _loadQuote();
  }

  @override
  void dispose() {
    _quote.dispose();
    super.dispose();
  }

  /* ================= QUOTE ================= */

  Future<void> _loadQuote() async {
    try {
      final raw = await rootBundle.loadString('assets/quotes.txt');
      final quotes = raw
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      if (!mounted || quotes.isEmpty) return;
      quotes.shuffle();
      _quote.value = quotes.first;
    } catch (_) {}
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StudyPulse'),
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: NotificationStore.unreadNotifier,
            builder: (_, count, __) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const NotificationInboxScreen(),
                        ),
                      );
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: const SafeArea(
        child: HomeMain(),
      ),
    );
  }
}

/* ================= HOME MAIN ================= */

class HomeMain extends StatefulWidget {
  const HomeMain({super.key});

  @override
  State<HomeMain> createState() => _HomeMainState();
}

class _HomeMainState extends State<HomeMain>
    with AutomaticKeepAliveClientMixin {
  BannerAd? _bannerAd;
  bool _bannerLoaded = false;

  final ValueNotifier<bool> _canNotify = ValueNotifier(true);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    // 🔔 Permission state
    Permission.notification.isGranted.then((v) {
      if (mounted) _canNotify.value = v;
    });

    // 📢 Banner after first frame (SAFE)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBanner();
    });
  }

  void _loadBanner() async {
    _bannerAd?.dispose();

    _bannerAd = await AdsService.createAdaptiveBanner(
      context: context,
      onState: (loaded) {
        if (!mounted) return;
        setState(() => _bannerLoaded = loaded);
      },
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _canNotify.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final keyboardOpen =
        MediaQuery.of(context).viewInsets.bottom > 0;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (!keyboardOpen)
          SizedBox(
            height: 90,
            child: _bannerLoaded && _bannerAd != null
                ? AdWidget(ad: _bannerAd!)
                : const AdPlaceholder(),
          ),

        const SizedBox(height: 20),

        /// 🔔 Notification warning
        ValueListenableBuilder<bool>(
          valueListenable: _canNotify,
          builder: (_, ok, __) {
            if (!ok) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: NotificationWarningCard(),
              );
            }
            return const SizedBox.shrink();
          },
        ),

        const SizedBox(height: 20),

        _tool(
          context,
          'Percentage Calculator',
          'assets/percentage.png',
          const PercentagePage(),
        ),
        _tool(
          context,
          'CGPA Calculator',
          'assets/cgpa.png',
          const CGPAPage(),
        ),
        _tool(
          context,
          'Exam Countdown',
          'assets/exam.png',
          const ExamCountdownPage(),
        ),
      ],
    );
  }

  Widget _tool(
    BuildContext context,
    String title,
    String asset,
    Widget page,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Image.asset(asset, width: 40),
        title: Text(title),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () async {
          AdClickTracker.registerClick();
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
      ),
    );
  }
}
