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

    AdClickTracker.registerClick();

    _loadData();

    _bannerAd = BannerAd(
      adUnitId: AdsService.bannerId,
      size: AdSize.mediumRectangle,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _bannerLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  int get daysLeft =>
      examDate == null ? 0 : examDate!.difference(DateTime.now()).inDays;

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('exam_date');
    if (saved != null) examDate = DateTime.parse(saved);

    final raw = await rootBundle.loadString('assets/quotes.txt');
    quotes = raw.split('\n').where((e) => e.trim().isNotEmpty).toList();
    setState(() {});
  }

  Future<void> _pickDate() async {
    AdClickTracker.registerClick();

    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 5),
      initialDate: examDate ?? DateTime.now(),
    );
    if (picked == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('exam_date', picked.toIso8601String());

    setState(() => examDate = picked);

    await NotificationService.showInstant(
      daysLeft: daysLeft,
      quote: quotes[Random().nextInt(quotes.length)],
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exam Countdown')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Text(
                examDate == null ? '--' : '$daysLeft Days Left',
                style: const TextStyle(fontSize: 30),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _pickDate,
            child: const Text('Select Exam Date'),
          ),
          if (_bannerLoaded && _bannerAd != null)
            SafeArea(
              child: SizedBox(
                height: _bannerAd!.size.height.toDouble(),
                width: _bannerAd!.size.width.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
        ],
      ),
    );
  }
}