import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/ads.dart';
import '../services/ad_click_tracker.dart';
import '../services/notification.dart';
import '../widgets/ad_placeholder.dart';
import '../state/exam_state.dart'; // ✅ NEW

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

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadBanner();
  }

  /* ================= LOAD DATA ================= */

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('exam_date');

    if (saved != null) {
      examDate = DateTime.parse(saved);
      ExamState.examDate.value = examDate; // 🔥 sync on open
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

  /* ================= DAYS LOGIC ================= */

  int _daysLeftFrom(DateTime date) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(date.year, date.month, date.day);
    final diff = end.difference(start).inDays;
    return diff < 0 ? 0 : diff;
  }

  int get daysLeft =>
      examDate == null ? 0 : _daysLeftFrom(examDate!);

  Color get dayColor {
    if (daysLeft >= 45) return Colors.green;
    if (daysLeft >= 30) return Colors.orange;
    return Colors.red;
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

    /// ✅ ALWAYS SAVE (NO COMPARISON)
    await prefs.setString('exam_date', normalized.toIso8601String());

    setState(() => examDate = normalized);

    /// 🔥 LIVE SYNC (CORE FIX)
    ExamState.examDate.value = normalized;

    AdClickTracker.registerClick();

    final freshDaysLeft = _daysLeftFrom(normalized);

    /// 🔔 ALWAYS FIRE NOTIFICATION
    if (quotes.isNotEmpty) {
      await NotificationService.showInstant(
        daysLeft: freshDaysLeft,
        quote: quotes[Random().nextInt(quotes.length)],
      );
    }

    /// 🔔 DAILY RESCHEDULE
    await NotificationService.scheduleDaily(examDate: normalized);

    /// 🔥 tell home
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
                      Text(
                        examDate == null ? '--' : '$daysLeft Days',
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