import 'dart:async';
import 'dart:convert';
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
import 'services/ads.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int index = 0;
  int _toolOpenCount = 0;

  DateTime? examDate;
  String dailyQuote = '';
  int unreadCount = 0;

  final pages = const [
    _HomeMain(),
    AboutPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadExamDate();
    _loadDailyQuote();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('notifications');
    if (raw == null) {
      unreadCount = 0;
      return;
    }
    final list = jsonDecode(raw) as List;
    unreadCount = list.where((n) => n['read'] == false).length;
    setState(() {});
  }

  Future<void> _markAllRead() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('notifications');
    if (raw == null) return;

    final List list = jsonDecode(raw);
    for (final n in list) {
      n['read'] = true;
    }
    await prefs.setString('notifications', jsonEncode(list));
    setState(() => unreadCount = 0);
  }

  Future<void> _loadExamDate() async {
    final prefs = await SharedPreferences.getInstance();
    final d = prefs.getString('exam');
    if (d != null) examDate = DateTime.parse(d);
  }

  Future<void> _loadDailyQuote() async {
    final data = await rootBundle.loadString('assets/quotes.txt');
    final quotes =
        data.split('\n').where((e) => e.trim().isNotEmpty).toList();
    dailyQuote = quotes[Random().nextInt(quotes.length)];
    setState(() {});
  }

  int get daysLeft =>
      examDate == null ? 0 : examDate!.difference(DateTime.now()).inDays;

  Color get dayColor {
    if (daysLeft >= 30) return Colors.green;
    if (daysLeft >= 15) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StudyPulse'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationInbox()),
                  );
                  _markAllRead();
                },
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'About'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
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
  final PageController _adController =
      PageController(viewportFraction: 0.92);
  Timer? _timer;

  static const int _adCount = 5;
  late final List<BannerAd> _banners;

  @override
  void initState() {
    super.initState();

    _banners = List.generate(_adCount, (_) {
      final ad = AdsService.createBannerAd();
      ad.load();
      return ad;
    });

    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_adController.hasClients) {
        final next = (_adController.page?.round() ?? 0) + 1;
        _adController.animateToPage(
          next % _adCount,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    for (final ad in _banners) {
      ad.dispose();
    }
    _timer?.cancel();
    _adController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final home = context.findAncestorStateOfType<_HomeState>();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SizedBox(
          height: 60,
          child: PageView.builder(
            controller: _adController,
            itemCount: _adCount,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AdWidget(ad: _banners[i]),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        Row(
          children: [
            Image.asset('assets/logo.png', height: 48),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('StudyPulse',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text('Focus • Track • Succeed',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ],
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
                Text('${home.daysLeft} DAYS LEFT',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: home.dayColor)),
              ],
            ),
          ),

        const SizedBox(height: 30),

        _tool(context, 'Percentage Calculator', 'assets/percentage.png',
            const PercentagePage()),
        _tool(context, 'CGPA Calculator', 'assets/cgpa.png',
            const CGPAPage()),
        _tool(context, 'Exam Countdown', 'assets/exam.png',
            const ExamCountdownPage()),
      ],
    );
  }

  Widget _tool(
      BuildContext context, String title, String img, Widget page) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Image.asset(img, width: 40),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          final home = context.findAncestorStateOfType<_HomeState>();
          if (home != null) {
            home._toolOpenCount++;
            if (home._toolOpenCount % 3 == 0) {
              AdsService.showInterstitial();
            }
          }
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => page));
        },
      ),
    );
  }
}

/* ================= NOTIFICATION INBOX ================= */

class NotificationInbox extends StatelessWidget {
  const NotificationInbox({super.key});

  Future<List<Map<String, dynamic>>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('notifications');
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(raw));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: FutureBuilder(
        future: _load(),
        builder: (_, snap) {
          if (!snap.hasData || (snap.data as List).isEmpty) {
            return const Center(child: Text('No notifications yet'));
          }
          final list = snap.data as List<Map<String, dynamic>>;
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) {
              final n = list[i];
              return ListTile(
                leading: const Icon(Icons.notifications),
                title: Text(n['title']),
                subtitle: Text(n['body']),
              );
            },
          );
        },
      ),
    );
  }
}
