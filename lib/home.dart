// lib/home.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:permission_handler/permission_handler.dart';

import 'tools/percentage.dart';
import 'tools/cgpa.dart';
import 'tools/exam.dart';

import 'screens/about.dart';
import 'screens/settings.dart';
import 'screens/notification_inbox.dart';

import 'services/ads.dart';
import 'services/ad_click_tracker.dart';
import 'services/notification_store.dart';

import 'widgets/ad_placeholder.dart';
import 'widgets/notification_warning_card.dart';
import 'state/exam_state.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

/* ================= ROOT ================= */

class _HomeState extends State<Home> with WidgetsBindingObserver {
  int _index = 0;
  final ValueNotifier<String> _quote = ValueNotifier('');

  @override
  void initState() {
    super.initState();

    // 🔥 CRITICAL: restores exam countdown on relaunch
    ExamState.init();

    AdsService.initialize();
    WidgetsBinding.instance.addObserver(this);
    _loadQuote();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _quote.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadQuote();
    }
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
                      _loadQuote();
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

      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: [
            HomeMain(quote: _quote),
            const AboutPage(),
            const SettingsPage(),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) {
          if (i == _index) return;
          AdClickTracker.registerClick();
          setState(() => _index = i);
          _loadQuote();
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.info_outline), label: 'About'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

/* ================= HOME MAIN ================= */

class HomeMain extends StatefulWidget {
  final ValueNotifier<String> quote;
  const HomeMain({super.key, required this.quote});

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
    _loadBanner();

    Permission.notification.isGranted.then((v) {
      if (mounted) _canNotify.value = v;
    });
  }

  void _loadBanner() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _bannerAd?.dispose();
      _bannerAd = await AdsService.createAdaptiveBanner(
        context: context,
        onState: (loaded) {
          if (!mounted) return;
          setState(() => _bannerLoaded = loaded);
        },
      );
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _canNotify.dispose();
    super.dispose();
  }

  Color _colorForDays(int days) {
    if (days >= 45) return Colors.green;
    if (days >= 30) return Colors.orange;
    return Colors.red;
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

        /// 🔔 NOTIFICATION WARNING (STABLE)
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

        /// 💬 QUOTE
        ValueListenableBuilder<String>(
          valueListenable: widget.quote,
          builder: (_, q, __) {
            if (q.isEmpty) return const SizedBox.shrink();
            return Text(
              '“$q”',
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            );
          },
        ),

        const SizedBox(height: 20),

        /// 📆 EXAM STATUS
        ValueListenableBuilder<DateTime?>(
          valueListenable: ExamState.examDate,
          builder: (_, date, __) {
            return ValueListenableBuilder<int>(
              valueListenable: ExamState.daysLeft,
              builder: (_, days, __) {
                if (date == null) {
                  return _ctaCard(context);
                }

                if (days == 0) {
                  return const SizedBox.shrink();
                }

                final color = _colorForDays(days);

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer, color: color),
                      const SizedBox(width: 10),
                      Text(
                        '$days DAYS LEFT',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),

        const SizedBox(height: 30),

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

  Widget _ctaCard(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.flag_outlined),
        title: const Text('No exam set'),
        subtitle: const Text('Start preparing today'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () async {
          AdClickTracker.registerClick();
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ExamCountdownPage(),
            ),
          );
        },
      ),
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