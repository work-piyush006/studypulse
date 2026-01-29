import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/ads.dart';
import '../services/ad_click_tracker.dart';
import '../services/notification.dart';

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

    /// 🔔 Ensure notification system is ready
    NotificationService.init();

    _loadData();
    _loadBanner();
  }

  /* ================= BANNER ================= */

  void _loadBanner() {
    _bannerAd = BannerAd(
      adUnitId: AdsService.bannerId,
      size: AdSize.mediumRectangle,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            setState(() => _bannerLoaded = true);
          }
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
        },
      ),
    )..load();
  }

  /* ================= DAYS LOGIC ================= */

  int get daysLeft {
    if (examDate == null) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target =
        DateTime(examDate!.year, examDate!.month, examDate!.day);

    final diff = target.difference(today).inDays;
    return diff < 0 ? 0 : diff;
  }

  Color get dayColor {
    if (daysLeft >= 45) return Colors.green;
    if (daysLeft >= 30) return Colors.orange;
    return Colors.red;
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

    if (mounted) setState(() {});
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

    final prefs = await SharedPreferences.getInstance();
    final oldDateStr = prefs.getString('exam_date');
    final oldDate =
        oldDateStr == null ? null : DateTime.parse(oldDateStr);

    final normalizedPicked =
        DateTime(picked.year, picked.month, picked.day);
    final normalizedOld = oldDate == null
        ? null
        : DateTime(oldDate.year, oldDate.month, oldDate.day);

    final isDateChanged =
        normalizedOld == null || normalizedOld != normalizedPicked;

    if (!isDateChanged) return;

    await prefs.setString(
      'exam_date',
      normalizedPicked.toIso8601String(),
    );

    setState(() => examDate = normalizedPicked);

    /// 🔥 Count ONLY real success
    AdClickTracker.registerClick();

    /// 🔔 Instant notification
    if (quotes.isNotEmpty) {
      await NotificationService.showInstant(
        daysLeft: daysLeft,
        quote: quotes[Random().nextInt(quotes.length)],
      );
    }

    /// 🔔 Daily notifications (3:30 PM & 8:30 PM)
    await NotificationService.scheduleDaily(
      examDate: normalizedPicked,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exam date saved successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
              /// ================= MAIN CARD =================
              Card(
                elevation: 2,
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

              /// ================= SELECT DATE =================
              ElevatedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today),
                label: const Text('Select Exam Date'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),

              const SizedBox(height: 20),

              /// ================= BANNER =================
              if (!isKeyboardOpen)
                _bannerLoaded && _bannerAd != null
                    ? SizedBox(
                        height: _bannerAd!.size.height.toDouble(),
                        width: _bannerAd!.size.width.toDouble(),
                        child: AdWidget(ad: _bannerAd!),
                      )
                    : const SizedBox(
                        height: 250,
                        child: Center(
                          child: Text(
                            'Sponsor content loading…',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
            ],
          ),
        ),
      ),
    );
  }
}