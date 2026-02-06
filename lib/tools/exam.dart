// lib/tools/exam.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ads.dart';
import '../services/ad_click_tracker.dart';
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

  late final VoidCallback _eventListener;

  @override
  void initState() {
    super.initState();
    AdClickTracker.registerClick();
    _loadQuotes();
    _loadBanner();

    /// 🔔 LISTEN TO EXAM EVENTS (NOT FLAGS)
    _eventListener = () {
      final e = ExamState.event.value;

      if (e == ExamEvent.examCompleted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                const Text('Exam completed 🎉 Any next exam left?'),
            action: SnackBarAction(
              label: 'Set new',
              onPressed: _pickDate,
            ),
          ),
        );
      }
    };

    ExamState.event.addListener(_eventListener);
  }

  @override
  void dispose() {
    ExamState.event.removeListener(_eventListener);
    _bannerAd?.dispose();
    super.dispose();
  }

  /* ================= QUOTES ================= */

  Future<void> _loadQuotes() async {
    if (_quotes != null) return;
    try {
      final raw =
          await rootBundle.loadString('assets/quotes.txt');
      _quotes = raw
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (_) {
      _quotes = [];
    }
  }

  String _quote() {
    if (_quotes == null || _quotes!.isEmpty) {
      return 'Stay focused 📘';
    }
    return _quotes![Random().nextInt(_quotes!.length)];
  }

  /* ================= ADS ================= */

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

  /* ================= DATE PICK ================= */

  Future<void> _pickDate() async {
    final current = ExamState.examDate.value;

    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 5),
      initialDate:
          current ?? DateTime.now().add(const Duration(days: 30)),
    );

    if (picked == null || !mounted) return;

    final normalized =
        DateTime(picked.year, picked.month, picked.day);

    /// 🛑 SAME DATE → NO RE-TRIGGER
    if (current != null && current == normalized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Same exam date selected')),
      );
      return;
    }

    await ExamState.update(normalized);

    final days = ExamState.daysLeft.value;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exam set • $days days remaining')),
    );
  }

  /* ================= CANCEL ================= */

  Future<void> _cancelCountdown() async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Material(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Cancel Exam Countdown?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Countdown data will be cleared.'),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.pop(ctx, false),
                        child: const Text('No'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.pop(ctx, true),
                        child: const Text('Yes'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirm != true || !mounted) return;

    await ExamState.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Exam countdown cancelled'),
        action: SnackBarAction(
          label: 'Set again',
          onPressed: _pickDate,
        ),
      ),
    );
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen =
        MediaQuery.of(context).viewInsets.bottom > 0;

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
                  builder: (_, days, __) {
                    final isExamDay =
                        ExamState.isExamDay.value;
                    final hasExam = ExamState.hasExam;
                    final color =
                        ExamState.colorForDays(days);

                    if (!hasExam) {
                      return const Text(
                        'No exam set',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold),
                      );
                    }

                    if (isExamDay) {
                      return Column(
                        children: [
                          const Text(
                            'Today is your exam 💪',
                            style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _quote(),
                            textAlign: TextAlign.center,
                            style:
                                const TextStyle(color: Colors.grey),
                          ),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        Text(
                          '$days Days',
                          style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: color),
                        ),
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: ExamState.progress(),
                          minHeight: 8,
                          backgroundColor:
                              color.withOpacity(0.2),
                          valueColor:
                              AlwaysStoppedAnimation(color),
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
            if (!isKeyboardOpen)
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
