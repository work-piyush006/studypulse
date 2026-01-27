// ==================== STUDYPULSE ====================
// FULL PRODUCTION main.dart (Single file app)
// ====================================================

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

/* ================= ADMOB IDS ================= */

const String admobAppId = 'ca-app-pub-2139593035914184~9894998746';

const String bannerAdId =
    'ca-app-pub-2139593035914184/9260573924';

const String interstitialAdId =
    'ca-app-pub-2139593035914184/1908697513';

/* ================= NOTIFICATION ================= */

final FlutterLocalNotificationsPlugin notifications =
    FlutterLocalNotificationsPlugin();

/* ================= MAIN ================= */

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();

  const androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  await notifications.initialize(
    const InitializationSettings(android: androidInit),
  );

  runApp(const StudyPulse());
}

/* ================= ROOT ================= */

class StudyPulse extends StatelessWidget {
  const StudyPulse({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyPulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: const InternetGuard(child: SplashScreen()),
    );
  }
}

/* ================= INTERNET GUARD ================= */

class InternetGuard extends StatefulWidget {
  final Widget child;
  const InternetGuard({super.key, required this.child});

  @override
  State<InternetGuard> createState() => _InternetGuardState();
}

class _InternetGuardState extends State<InternetGuard>
    with SingleTickerProviderStateMixin {
  bool connected = true;
  Timer? timer;
  late AnimationController anim;

  @override
  void initState() {
    super.initState();
    anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final ok = await InternetConnectionChecker().hasConnection;
      if (ok != connected) setState(() => connected = ok);
    });
  }

  @override
  void dispose() {
    anim.dispose();
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (connected) return widget.child;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedIcon(
              icon: AnimatedIcons.menu_close,
              progress: anim,
              size: 80,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Internet Connection',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text('Waiting for connection...'),
          ],
        ),
      ),
    );
  }
}

/* ================= SPLASH ================= */

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Home()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', height: 120),
            const SizedBox(height: 16),
            const Text(
              'StudyPulse',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text('Focus • Track • Succeed'),
          ],
        ),
      ),
    );
  }
}

/* ================= HOME ================= */

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int index = 0;

  final pages = const [
    Tools(),
    About(),
    Settings(),
  ];

  @override
  void initState() {
    super.initState();
    InterstitialManager.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StudyPulse'),
      ),
      body: pages[index],
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

/* ================= TOOLS ================= */

class Tools extends StatelessWidget {
  const Tools({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const BannerAdBox(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              tile(context, 'Percentage Calculator', const Percentage()),
              tile(context, 'CGPA Calculator', const CGPA()),
              tile(context, 'Exam Countdown', const ExamCountdown()),
            ],
          ),
        ),
      ],
    );
  }

  Widget tile(BuildContext c, String t, Widget p) {
    return Card(
      child: ListTile(
        title: Text(t),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () async {
          await UsageCounter.hit();
          Navigator.push(c, MaterialPageRoute(builder: (_) => p));
        },
      ),
    );
  }
}

/* ================= PERCENTAGE ================= */

class Percentage extends StatefulWidget {
  const Percentage({super.key});
  @override
  State<Percentage> createState() => _PercentageState();
}

class _PercentageState extends State<Percentage> {
  final o = TextEditingController();
  final t = TextEditingController();
  String r = '';

  void calc() {
    final a = double.tryParse(o.text);
    final b = double.tryParse(t.text);
    if (a == null || b == null || b <= 0) return;
    setState(() => r = '${((a / b) * 100).toStringAsFixed(2)} %');
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(title: const Text('Percentage')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: o, decoration: const InputDecoration(labelText: 'Obtained')),
            TextField(controller: t, decoration: const InputDecoration(labelText: 'Total')),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: calc, child: const Text('Calculate')),
            const SizedBox(height: 20),
            Text(r, style: const TextStyle(fontSize: 26)),
            const Spacer(),
            const BannerAdBox(),
          ],
        ),
      ),
    );
  }
}

/* ================= CGPA ================= */

class CGPA extends StatefulWidget {
  const CGPA({super.key});
  @override
  State<CGPA> createState() => _CGPAState();
}

class _CGPAState extends State<CGPA> {
  final c = TextEditingController();
  String r = '';

  void calc() {
    final v = double.tryParse(c.text);
    if (v == null) return;
    setState(() => r = 'Percentage: ${(v * 9.5).toStringAsFixed(2)} %');
  }

  @override
  Widget build(BuildContext cxt) {
    return Scaffold(
      appBar: AppBar(title: const Text('CGPA')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: c, decoration: const InputDecoration(labelText: 'CGPA')),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: calc, child: const Text('Convert')),
            const SizedBox(height: 20),
            Text(r, style: const TextStyle(fontSize: 24)),
            const Spacer(),
            const BannerAdBox(),
          ],
        ),
      ),
    );
  }
}

/* ================= EXAM COUNTDOWN ================= */

class ExamCountdown extends StatefulWidget {
  const ExamCountdown({super.key});
  @override
  State<ExamCountdown> createState() => _ExamCountdownState();
}

class _ExamCountdownState extends State<ExamCountdown> {
  DateTime? date;
  List<String> quotes = [];

  int get days => date == null ? 0 : date!.difference(DateTime.now()).inDays;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final d = p.getString('exam');
    if (d != null) date = DateTime.parse(d);
    quotes = (await rootBundle.loadString('assets/quotes.txt')).split('\n');
    setState(() {});
  }

  Future<void> pick() async {
    final p = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 5),
      initialDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (p == null) return;
    final sp = await SharedPreferences.getInstance();
    await sp.setString('exam', p.toIso8601String());
    setState(() => date = p);
    notify();
  }

  Future<void> notify() async {
    final q = quotes.isEmpty ? '' : quotes[Random().nextInt(quotes.length)];
    await notifications.show(
      0,
      '📘 Exam Countdown',
      '$days days left\n$q',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'exam',
          'Exam',
          importance: Importance.high,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exam Countdown')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              date == null ? 'Select exam date' : '$days Days Left',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: pick, child: const Text('Select Date')),
            const Spacer(),
            const BannerAdBox(),
          ],
        ),
      ),
    );
  }
}

/* ================= ADS ================= */

class BannerAdBox extends StatefulWidget {
  const BannerAdBox({super.key});
  @override
  State<BannerAdBox> createState() => _BannerAdBoxState();
}

class _BannerAdBoxState extends State<BannerAdBox> {
  BannerAd? ad;

  @override
  void initState() {
    super.initState();
    ad = BannerAd(
      adUnitId: bannerAdId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(),
    )..load();
  }

  @override
  Widget build(BuildContext c) {
    if (ad == null) return const SizedBox();
    return SizedBox(height: ad!.size.height.toDouble(), child: AdWidget(ad: ad!));
  }

  @override
  void dispose() {
    ad?.dispose();
    super.dispose();
  }
}

class InterstitialManager {
  static InterstitialAd? ad;

  static void load() {
    InterstitialAd.load(
      adUnitId: interstitialAdId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (a) => ad = a,
        onAdFailedToLoad: (_) => ad = null,
      ),
    );
  }

  static void show() {
    ad?.show();
    ad = null;
    load();
  }
}

class UsageCounter {
  static Future<void> hit() async {
    final p = await SharedPreferences.getInstance();
    int c = p.getInt('use') ?? 0;
    p.setInt('use', ++c);
    if (c % 3 == 0) InterstitialManager.show();
  }
}

/* ================= ABOUT & SETTINGS ================= */

class About extends StatelessWidget {
  const About({super.key});
  @override
  Widget build(BuildContext c) {
    return Column(
      children: const [
        Expanded(
          child: Center(
            child: Text(
              'StudyPulse\nBuilt for students',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        BannerAdBox(),
      ],
    );
  }
}

class Settings extends StatelessWidget {
  const Settings({super.key});
  @override
  Widget build(BuildContext c) {
    return const Center(child: Text('Settings'));
  }
}