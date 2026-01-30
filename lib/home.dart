// lib/home.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

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
import 'state/exam_state.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  int index = 0;
  String dailyQuote = '';

  final pages = const [
    HomeMain(),
    AboutPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadNextQuote();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadNextQuote();
    }
  }

  Future<void> _loadNextQuote() async {
    try {
      final raw = await rootBundle.loadString('assets/quotes.txt');
      final quotes = raw
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      if (!mounted || quotes.isEmpty) return;

      quotes.shuffle();
      setState(() => dailyQuote = quotes.first);
    } catch (_) {}
  }

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
                      _loadNextQuote();
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
                          count.toString(),
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
        child: IndexedStack(index: index, children: pages),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) {
          if (i != index) {
            AdClickTracker.registerClick(); // ✅ legit navigation
            setState(() => index = i);
            _loadNextQuote();
          }
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
  const HomeMain({super.key});

  @override
  State<HomeMain> createState() => _HomeMainState();
}

class _HomeMainState extends State<HomeMain> {
  BannerAd? _bannerAd;
  bool _bannerLoaded = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
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
    super.dispose();
  }

  Color _dayColor(int days) {
    if (days >= 45) return Colors.green;
    if (days >= 30) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final home = context.findAncestorStateOfType<_HomeState>();
    final isKeyboardOpen =
        MediaQuery.of(context).viewInsets.bottom > 0;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (!isKeyboardOpen)
          SizedBox(
            height: 90,
            child: _bannerLoaded && _bannerAd != null
                ? AdWidget(ad: _bannerAd!)
                : const AdPlaceholder(),
          ),

        const SizedBox(height: 20),

        if (home != null && home.dailyQuote.isNotEmpty)
          Text(
            '“${home.dailyQuote}”',
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),

        const SizedBox(height: 20),

        ValueListenableBuilder<int>(
          valueListenable: ExamState.daysLeft,
          builder: (_, days, __) {
            if (days <= 0) return const SizedBox.shrink();

            final color = _dayColor(days);

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
        ),

        const SizedBox(height: 30),

        _tool(context, 'Percentage Calculator',
            'assets/percentage.png', const PercentagePage()),
        _tool(context, 'CGPA Calculator',
            'assets/cgpa.png', const CGPAPage()),
        _tool(context, 'Exam Countdown',
            'assets/exam.png', const ExamCountdownPage()),
      ],
    );
  }

  Widget _tool(
    BuildContext context,
    String title,
    String img,
    Widget page,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Image.asset(img, width: 40),
        title: Text(title),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () async {
          AdClickTracker.registerClick(); // ✅ real user intent
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
      ),
    );
  }
}