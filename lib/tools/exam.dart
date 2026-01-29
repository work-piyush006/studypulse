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
    _loadData();

    /// 🔔 Bottom banner
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

  int get daysLeft =>
      examDate == null ? 0 : examDate!.difference(DateTime.now()).inDays;

  Color get dayColor {
    if (daysLeft >= 45) return Colors.green;
    if (daysLeft >= 30) return Colors.orange;
    return Colors.red;
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('exam_date');
    if (saved != null) {
      examDate = DateTime.parse(saved);
    }

    final raw = await rootBundle.loadString('assets/quotes.txt');
    quotes = raw.split('\n').where((e) => e.trim().isNotEmpty).toList();

    setState(() {});
  }

  Future<void> _pickDate() async {
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

    final oldDays =
        oldDate == null ? null : oldDate.difference(DateTime.now()).inDays;
    final newDays = picked.difference(DateTime.now()).inDays;

    await prefs.setString('exam_date', picked.toIso8601String());
    setState(() => examDate = picked);

    /// 🔥 Count click ONLY if date actually changed
    if (oldDays == null || oldDays != newDays) {
      AdClickTracker.registerClick();

      if (quotes.isNotEmpty) {
        await NotificationService.showInstant(
          daysLeft: daysLeft,
          quote: quotes[Random().nextInt(quotes.length)],
        );
      }

      await NotificationService.scheduleDaily(
        examDate: picked,
      );
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen =
        MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Exam Countdown')),
      body: SafeArea(
        child: Column(
          children: [
            /// ================= MAIN CARD =================
            Expanded(
              child: Center(
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
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
              ),
            ),

            /// ================= SELECT DATE BUTTON =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today),
                label: const Text('Select Exam Date'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ),

            const SizedBox(height: 12),

            /// ================= BANNER =================
            if (_bannerLoaded && _bannerAd != null && !isKeyboardOpen)
              SizedBox(
                height: _bannerAd!.size.height.toDouble(),
                width: _bannerAd!.size.width.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
          ],
        ),
      ),
    );
  }
}