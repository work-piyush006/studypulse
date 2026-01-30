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
  List<String> quotes = [];

  BannerAd? _bannerAd;
  bool _bannerLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadQuotes();
    _loadBanner();
  }

  /* ================= LOAD QUOTES ================= */

  Future<void> _loadQuotes() async {
    final raw = await rootBundle.loadString('assets/quotes.txt');
    quotes = raw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /* ================= ADS ================= */

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
          ExamState.examDate.value ??
          DateTime.now().add(const Duration(days: 30)),
    );

    if (picked == null) return;

    final normalized =
        DateTime(picked.year, picked.month, picked.day);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('exam_date', normalized.toIso8601String());

    // 🔥 SINGLE SOURCE OF TRUTH
    ExamState.update(normalized);

    AdClickTracker.registerClick();

    final days = ExamState.daysLeft.value;
    final quote = quotes.isNotEmpty
        ? quotes[Random().nextInt(quotes.length)]
        : '';

    final firstTime =
        !(prefs.getBool('exam_first_notification_done') ?? false);

    // 🟢 FIRST TIME → SYSTEM NOTIFICATION
    if (firstTime) {
      await NotificationService.showInstant(
        daysLeft: days,
        quote: quote,
      );
      await prefs.setBool('exam_first_notification_done', true);
    }
    // 🟡 AFTER THAT → SNACKBAR ONLY
    else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 3),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$days Days Left',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (quote.isNotEmpty)
                  Text(
                    quote,
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
          ),
        );
      }
    }

    // ⏰ DAILY REMINDERS
    await NotificationService.scheduleDaily(examDate: normalized);

    if (mounted) Navigator.pop(context);
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

                      /// 🔥 LIVE REACTIVE VALUE (NO DELAY, NO RESTART)
                      ValueListenableBuilder<int>(
                        valueListenable: ExamState.daysLeft,
                        builder: (_, days, __) {
                          final color =
                              ExamState.colorForDays(days);

                          return Text(
                            days > 0 ? '$days Days' : '--',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: color,
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