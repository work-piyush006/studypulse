import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

import 'tools/percentage.dart';
import 'tools/cgpa.dart';
import 'tools/exam.dart';
import 'screens/about.dart';
import 'screens/settings.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int index = 0;
  DateTime? examDate;
  String dailyQuote = '';

  final pages = const [
    _HomeMain(),
    AboutScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadExamDate();
    _loadDailyQuote();
  }

  Future<void> _loadExamDate() async {
    final prefs = await SharedPreferences.getInstance();
    final d = prefs.getString('exam');
    if (d != null) {
      setState(() => examDate = DateTime.parse(d));
    }
  }

  Future<void> _loadDailyQuote() async {
    final data = await rootBundle.loadString('assets/quotes.txt');
    final quotes = data.split('\n').where((e) => e.trim().isNotEmpty).toList();
    setState(() {
      dailyQuote = quotes[Random().nextInt(quotes.length)];
    });
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
      ),
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.info_outline), label: 'About'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

/* ================= HOME MAIN UI ================= */

class _HomeMain extends StatelessWidget {
  const _HomeMain();

  @override
  Widget build(BuildContext context) {
    final homeState = context.findAncestorStateOfType<_HomeState>();
    final days = homeState?.daysLeft ?? 0;
    final color = homeState?.dayColor ?? Colors.grey;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // HEADER
        Row(
          children: [
            Image.asset('assets/logo.png', height: 48),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'StudyPulse',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Focus • Track • Succeed',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 20),

        // QUOTE
        Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              homeState?.dailyQuote ?? '',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // DAYS LEFT
        if (days > 0)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
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
          ),

        const SizedBox(height: 30),

        // FEATURES
        _toolCard(
          context,
          title: 'Percentage Calculator',
          image: 'assets/percentage.png',
          page: const PercentagePage(),
        ),
        _toolCard(
          context,
          title: 'CGPA Calculator',
          image: 'assets/cgpa.png',
          page: const CGPAPage(),
        ),
        _toolCard(
          context,
          title: 'Exam Countdown',
          image: 'assets/exam.png',
          page: const ExamCountdownPage(),
        ),
      ],
    );
  }

  Widget _toolCard(
    BuildContext context, {
    required String title,
    required String image,
    required Widget page,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Image.asset(image, width: 40),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
      ),
    );
  }
}
