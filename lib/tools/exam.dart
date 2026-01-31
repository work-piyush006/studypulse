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
  static List<String>? _quotes;
  BannerAd? _bannerAd;
  bool _bannerLoaded = false;

  @override
  void initState() {
    super.initState();
    AdClickTracker.registerClick();
    _loadQuotes();
    _loadBanner();
  }

  Future<void> _loadQuotes() async {
    if (_quotes != null) return;
    try {
      final raw = await rootBundle.loadString('assets/quotes.txt');
      _quotes = raw
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (_) {
      _quotes = [];
    }
  }

  String _quote() =>
      (_quotes == null || _quotes!.isEmpty)
          ? 'Stay focused 📘'
          : _quotes![Random().nextInt(_quotes!.length)];

  void _loadBanner() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _bannerAd?.dispose();
      _bannerAd = await AdsService.createAdaptiveBanner(
        context: context,
        onState: (loaded) {
          if (!mounted) return;
          setState(() => _bannerLoaded = loaded);
        },
      );
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 5),
      initialDate: ExamState.examDate.value ??
          DateTime.now().add(const Duration(days: 30)),
    );
    if (picked == null) return;

    final wasSet = ExamState.examDate.value != null;
    final normalized = DateTime(picked.year, picked.month, picked.day);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('exam_date', normalized.toIso8601String());

    ExamState.update(normalized);
    final days = ExamState.daysLeft.value;
    final text = '$days days left\n${_quote()}';

    if (!wasSet) {
      await NotificationService.instant(
        title: '📘 Exam Countdown',
        body: text,
        save: true,
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(text)));
    }

    await NotificationService.scheduleDaily(daysLeft: days);
  }

  Future<void> _cancelCountdown() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel countdown?'),
        content: const Text('All reminders will be removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes')),
        ],
      ),
    );

    if (ok != true) return;

    await ExamState.clear();
    await NotificationService.scheduleDaily(daysLeft: null);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Countdown cancelled'),
        action: SnackBarAction(
          label: 'Set again',
          onPressed: _pickDate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Exam Countdown')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ValueListenableBuilder<int>(
                  valueListenable: ExamState.daysLeft,
                  builder: (_, d, __) {
                    return Column(
                      children: [
                        const Text('Days Remaining'),
                        const SizedBox(height: 8),
                        Text(
                          d > 0 ? '$d Days' : 'No Exam Set',
                          style: const TextStyle(
                              fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today),
              label: const Text('Select Exam Date'),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<DateTime?>(
              valueListenable: ExamState.examDate,
              builder: (_, d, __) => OutlinedButton.icon(
                onPressed: d == null ? null : _cancelCountdown,
                icon: const Icon(Icons.close),
                label: const Text('Cancel Countdown'),
              ),
            ),
            const SizedBox(height: 24),
            if (!kb)
              SizedBox(
                height: 90,
                child: _bannerLoaded && _bannerAd != null
                    ? AdWidget(ad: _bannerAd!)
                    : const AdPlaceholder(),
              ),
          ],
        ),
      ),
    );
  }
}