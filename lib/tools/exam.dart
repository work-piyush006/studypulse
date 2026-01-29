import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/notification.dart';
import '../services/ads.dart';
import '../services/ad_click_tracker.dart';

class ExamCountdownPage extends StatefulWidget {
  const ExamCountdownPage({super.key});

  @override
  State<ExamCountdownPage> createState() => _ExamCountdownPageState();
}

class _ExamCountdownPageState extends State<ExamCountdownPage> {
  DateTime? examDate;
  List<String> quotes = [];

  late final BannerAd _bannerAd;
  bool _bannerLoaded = false;

  int get daysLeft =>
      examDate == null ? 0 : examDate!.difference(DateTime.now()).inDays;

  Color get dayColor {
    if (daysLeft > 30) return Colors.green;
    if (daysLeft > 15) return Colors.orange;
    return Colors.red;
  }

  @override
  void initState() {
    super.initState();
    _loadData();

    /// 🔥 TOOL BOTTOM BANNER
    _bannerAd = AdsService.createBanner()
      ..listener = BannerAdListener(
        onAdLoaded: (_) {
          setState(() => _bannerLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      );
  }

  /* ================= LOAD DATA ================= */

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('exam_date');

    if (saved != null) {
      examDate = DateTime.parse(saved);
    }

    final raw = await rootBundle.loadString('assets/quotes.txt');
    quotes = raw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    setState(() {});
  }

  /* ================= DATE PICKER ================= */

  Future<void> _pickDate() async {
    AdClickTracker.registerClick(); // 🔔 TOOL USE COUNT

    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 5),
      initialDate: examDate ?? DateTime.now().add(const Duration(days: 30)),
    );

    if (picked == null) return;

    final prefs = await SharedPreferences.getInstance();
    final oldDateStr = prefs.getString('exam_date');
    final oldDate =
        oldDateStr == null ? null : DateTime.parse(oldDateStr);

    final oldDaysLeft =
        oldDate == null ? null : oldDate.difference(DateTime.now()).inDays;

    final newDaysLeft =
        picked.difference(DateTime.now()).inDays;

    // SAVE DATE
    await prefs.setString('exam_date', picked.toIso8601String());
    setState(() => examDate = picked);

    // 🔥 SAME LOGIC (UNCHANGED)
    final shouldNotify =
        oldDaysLeft == null || oldDaysLeft != newDaysLeft;

    if (shouldNotify) {
      await _sendInstantNotification();
      await NotificationService.scheduleDaily(
        examDate: picked,
      );
    }
  }

  /* ================= INSTANT NOTIFICATION ================= */

  Future<void> _sendInstantNotification() async {
    if (quotes.isEmpty || examDate == null) return;

    final quote = quotes[Random().nextInt(quotes.length)];

    await NotificationService.showInstant(
      daysLeft: daysLeft,
      quote: quote,
    );
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exam Countdown')),
      body: Column(
        children: [
          /// ================= CONTENT =================
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Text(
                            'Days Remaining',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            examDate == null
                                ? '--'
                                : '$daysLeft Days',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: dayColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Select Exam Date'),
                    onPressed: _pickDate,
                  ),
                ],
              ),
            ),
          ),

          /// ================= BOTTOM BANNER =================
          if (_bannerLoaded)
            SafeArea(
              child: SizedBox(
                height: _bannerAd.size.height.toDouble(),
                width: _bannerAd.size.width.toDouble(),
                child: AdWidget(ad: _bannerAd),
              ),
            ),
        ],
      ),
    );
  }
}