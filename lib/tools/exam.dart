// lib/tools/exam.dart

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
  // 🔒 Quotes cached once for app lifetime
  static List<String>? _cachedQuotes;

  BannerAd? _bannerAd;
  bool _bannerLoaded = false;

  @override
  void initState() {
    super.initState();

    // ✅ Tool open = valid ad action
    AdClickTracker.registerClick();

    _loadQuotesIfNeeded();
    _loadBanner();
  }

  /* ================= QUOTES ================= */

  Future<void> _loadQuotesIfNeeded() async {
    if (_cachedQuotes != null) return;

    try {
      final raw = await rootBundle.loadString('assets/quotes.txt');
      _cachedQuotes = raw
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (_) {
      _cachedQuotes = [];
    }
  }

  String _randomQuote() {
    if (_cachedQuotes == null || _cachedQuotes!.isEmpty) return '';
    return _cachedQuotes![Random().nextInt(_cachedQuotes!.length)];
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
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 5),
      initialDate:
          ExamState.examDate.value ??
              DateTime.now().add(const Duration(days: 30)),
    );

    if (picked == null || !mounted) return;

    final normalized =
        DateTime(picked.year, picked.month, picked.day);

    final prefs = await SharedPreferences.getInstance();
    final wasAlreadySet = ExamState.examDate.value != null;

    await prefs.setString('exam_date', normalized.toIso8601String());
    ExamState.update(normalized);

    // ✅ Valid meaningful action
    AdClickTracker.registerClick();

    final days = ExamState.daysLeft.value;
    final quote = _randomQuote();

    // 🔔 INSTANT notification (first time only)
    if (!wasAlreadySet) {
      await NotificationService.showInstant(
        daysLeft: days,
        quote: quote,
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          content: Text('$days days left\n$quote'),
        ),
      );
    }

    // ⏰ DAILY reminders (4 PM & 11 PM)
    await NotificationService.scheduleDaily(
      examDate: normalized,
    );
  }

  /* ================= CANCEL ================= */

  Future<void> _cancelCountdown() async {
    // ✅ Cancel intent = valid ad action
    AdClickTracker.registerClick();

    final confirm = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20 + MediaQuery.of(ctx).viewPadding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning,
                    size: 40, color: Colors.red),
                const SizedBox(height: 12),
                const Text(
                  'Cancel Exam Countdown?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'This will remove the exam date and all reminders.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('No'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Yes'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirm != true || !mounted) return;

    await ExamState.clear();
    await NotificationService.cancelDaily();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Exam countdown cancelled'),
        action: SnackBarAction(
          label: 'Set new date',
          onPressed: _pickDate,
        ),
      ),
    );
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
      appBar: AppBar(
        title: const Text('Exam Countdown'),
        leading: BackButton(
          // ❌ No ad count on back (Play Store safe)
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ValueListenableBuilder<int>(
                    valueListenable: ExamState.daysLeft,
                    builder: (_, days, __) {
                      final color =
                          ExamState.colorForDays(days);
                      final progress =
                          ExamState.progress();

                      return Column(
                        children: [
                          const Text(
                            'Days Remaining',
                            style:
                                TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            days > 0
                                ? '$days Days'
                                : 'No Exam Set',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor:
                                color.withOpacity(0.2),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(
                                    color),
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
                icon:
                    const Icon(Icons.calendar_today_rounded),
                label: const Text('Select Exam Date'),
              ),

              const SizedBox(height: 12),

              ValueListenableBuilder<DateTime?>(
                valueListenable: ExamState.examDate,
                builder: (_, date, __) {
                  return OutlinedButton.icon(
                    onPressed:
                        date == null ? null : _cancelCountdown,
                    icon: const Icon(Icons.close),
                    label:
                        const Text('Cancel Countdown'),
                  );
                },
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
      ),
    );
  }
}