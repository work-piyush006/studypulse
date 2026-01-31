import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/ads.dart';
import '../services/ad_click_tracker.dart';
import '../services/notification.dart';
import '../services/notification_manager.dart';
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
      initialDate:
          ExamState.examDate.value ?? DateTime.now().add(const Duration(days: 30)),
    );

    if (picked == null || !mounted) return;

    // 🔥 FIX 1: REAL SOURCE OF TRUTH
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = !prefs.containsKey('exam_date');

    final normalized =
        DateTime(picked.year, picked.month, picked.day);

    await prefs.setString('exam_date', normalized.toIso8601String());
    ExamState.update(normalized);

    final days = ExamState.daysLeft.value;
    final message = '$days days left\n${_quote()}';

    if (isFirstTime) {
      if (!await NotificationManager.canNotify()) {
        final granted = await NotificationManager.requestOnce();
        if (!granted && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Enable notifications to get reminders'),
              action: SnackBarAction(
                label: 'ALLOW',
                onPressed: NotificationManager.openSystemSettings,
              ),
            ),
          );
          return;
        }

        // 🔥 FIX 2: ANDROID 13–15 SAFETY DELAY
        await Future.delayed(const Duration(milliseconds: 300));
      }

      await NotificationService.instant(
        title: '📘 Exam Countdown',
        body: message,
        save: true,
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }

    await NotificationService.scheduleDaily(daysLeft: days);
  }

  Future<void> _cancelCountdown() async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Cancel Exam Countdown?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('All reminders will be removed.'),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('No'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Yes'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirm != true || !mounted) return;

    await ExamState.clear();
    await NotificationService.scheduleDaily(daysLeft: null);

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
                    final color = ExamState.colorForDays(days);
                    final progress =
                        days <= 0 ? 0.0 : ExamState.progress();

                    return Column(
                      children: [
                        const Text('Days Remaining',
                            style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 10),
                        Text(
                          days > 0 ? '$days Days' : 'No Exam Set',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        if (days > 0) ...[
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor:
                                color.withOpacity(0.2),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(color),
                          ),
                        ],
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