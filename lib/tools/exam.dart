import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/ads.dart';
import '../services/ad_click_tracker.dart';
import '../services/notification.dart';
import '../widgets/ad_placeholder.dart';
import '../state/exam_state.dart';

class ExamCountdownPage extends StatefulWidget {
  const ExamCountdownPage({super.key});

  @override
  State<ExamCountdownPage> createState() => _ExamCountdownPageState();
}

class _ExamCountdownPageState extends State<ExamCountdownPage> {
  DateTime? examDate;
  List<String> quotes = [];

  BannerAd? _bannerAd;
  bool _bannerLoaded = false;

  bool _notificationReady = false;

  @override
  void initState() {
    super.initState();
    _bootstrap(); // 🔥 SINGLE ENTRY
  }

  /* ================= BOOTSTRAP ================= */

  Future<void> _bootstrap() async {
    // 🔥 ABSOLUTE REQUIREMENT (OEM SAFE)
    await NotificationService.init();
    _notificationReady = true;

    await _loadData();
    _loadBanner();
  }

  /* ================= LOAD DATA ================= */

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('exam_date');

    if (saved != null) {
      examDate = DateTime.parse(saved);
      ExamState.update(examDate);
    }

    final raw = await rootBundle.loadString('assets/quotes.txt');
    quotes = raw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (mounted) setState(() {});
  }

  /* ================= BANNER ================= */

  void _loadBanner() {
    _bannerAd = BannerAd(
      adUnitId: AdsService.bannerId,
      size: AdSize.mediumRectangle,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _bannerLoaded = true);
        },
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    )..load();
  }

  /* ================= PICK DATE ================= */

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 5),
      initialDate:
          examDate ?? DateTime.now().add(const Duration(days: 30)),
    );

    if (picked == null) return;

    final normalized =
        DateTime(picked.year, picked.month, picked.day);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('exam_date', normalized.toIso8601String());

    // 🔥 SINGLE SOURCE OF TRUTH
    setState(() => examDate = normalized);
    ExamState.update(normalized);

    AdClickTracker.registerClick();

    // 🔥 GUARANTEED NOTIFICATION FIRE
    if (_notificationReady && quotes.isNotEmpty) {
      await NotificationService.showInstant(
        daysLeft: ExamState.daysLeft.value,
        quote: quotes[Random().nextInt(quotes.length)],
      );
    }

    // 🔔 DAILY (OEM SAFE)
    await NotificationService.scheduleDaily(examDate: normalized);

    if (mounted) Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen =
        MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Exam Countdown')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    children: [
                      const Text(
                        'Days Remaining',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      ValueListenableBuilder<int>(
                        valueListenable: ExamState.daysLeft,
                        builder: (_, d, __) {
                          return Text(
                            '$d Days',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: d >= 30
                                  ? Colors.orange
                                  : Colors.red,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today),
                label: const Text('Select Exam Date'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),

              const SizedBox(height: 20),

              if (!isKeyboardOpen)
                SizedBox(
                  height: 250,
                  child: _bannerLoaded && _bannerAd != null
                      ? AdWidget(ad: _bannerAd!)
                      : const AdPlaceholder(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}