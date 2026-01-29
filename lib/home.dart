import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

/* ================= HOME ROOT ================= */

class _HomeState extends State<Home> {
  int index = 0;

  DateTime? examDate;
  String dailyQuote = '';

  final pages = const [
    _HomeMain(),
    AboutPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _reloadAll();
  }

  Future<void> _reloadAll() async {
    await _loadExamDate();
    await _loadDailyQuote();
  }

  Future<void> _loadExamDate() async {
    final prefs = await SharedPreferences.getInstance();
    final d = prefs.getString('exam_date');
    if (!mounted) return;
    setState(() {
      examDate = d == null ? null : DateTime.parse(d);
    });
  }

  Future<void> _loadDailyQuote() async {
    final data = await rootBundle.loadString('assets/quotes.txt');
    final quotes =
        data.split('\n').where((e) => e.trim().isNotEmpty).toList();

    if (!mounted || quotes.isEmpty) return;

    setState(() {
      dailyQuote = quotes[Random().nextInt(quotes.length)];
    });
  }

  int get daysLeft {
    if (examDate == null) return 0;

    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end =
        DateTime(examDate!.year, examDate!.month, examDate!.day);

    final diff = end.difference(start).inDays;
    return diff < 0 ? 0 : diff;
  }

  Color get dayColor {
    if (daysLeft >= 45) return Colors.green;
    if (daysLeft >= 30) return Colors.orange;
    return Colors.red;
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
            AdClickTracker.registerClick();
            setState(() => index = i);
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

class _HomeMain extends StatefulWidget {
  const _HomeMain();

  @override
  State<_HomeMain> createState() => _HomeMainState();
}

class _HomeMainState extends State<_HomeMain> {
  BannerAd? _bannerAd;
  bool _bannerLoaded = false;

  @override
  void initState() {
    super.initState();

    /// 🔔 SINGLE adaptive banner
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

  @override
  Widget build(BuildContext context) {
    final home = context.findAncestorStateOfType<_HomeState>();
    final isKeyboardOpen =
        MediaQuery.of(context).viewInsets.bottom > 0;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        /// 🔔 TOP BANNER
        if (!isKeyboardOpen)
          SizedBox(
            height: 90,
            child: _bannerLoaded && _bannerAd != null
                ? AdWidget(ad: _bannerAd!)
                : const AdPlaceholder(),
          ),

        if (!isKeyboardOpen) const SizedBox(height: 20),

        Row(
          children: [
            Image.asset('assets/logo.png', height: 48),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'StudyPulse',
                  style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Focus • Track • Succeed',
                  style:
                      TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16),

        if (home != null && home.dailyQuote.isNotEmpty)
          Text(
            '“${home.dailyQuote}”',
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),

        const SizedBox(height: 20),

        if (home != null && home.daysLeft > 0)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: home.dayColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.timer, color: home.dayColor),
                const SizedBox(width: 10),
                Text(
                  '${home.daysLeft} DAYS LEFT',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: home.dayColor,
                  ),
                ),
              ],
            ),
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

  /// 🔥 FINAL FIXED TOOL NAVIGATION
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
          AdClickTracker.registerClick();

          final changed = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );

          /// 🔥 Reload ONLY if exam date actually changed
          if (changed == true && mounted) {
            context
                .findAncestorStateOfType<_HomeState>()
                ?._reloadAll();
          }
        },
      ),
    );
  }
}