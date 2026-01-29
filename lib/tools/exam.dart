import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification.dart';

class ExamCountdownPage extends StatefulWidget {
  const ExamCountdownPage({super.key});

  @override
  State<ExamCountdownPage> createState() => _ExamCountdownPageState();
}

class _ExamCountdownPageState extends State<ExamCountdownPage> {
  DateTime? examDate;
  List<String> quotes = [];

  int get daysLeft =>
      examDate == null ? 0 : examDate!.difference(DateTime.now()).inDays;

  Color get dayColor {
    if (daysLeft > 30) return Colors.green;
    if (daysLeft > 15) return Colors.orange;
    return Colors.red;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
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

    setState(() {});
  }

  /* ================= DATE PICKER ================= */

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

    final oldDaysLeft =
        oldDate == null ? null : oldDate.difference(DateTime.now()).inDays;

    final newDaysLeft =
        picked.difference(DateTime.now()).inDays;

    // SAVE DATE
    await prefs.setString('exam_date', picked.toIso8601String());
    setState(() => examDate = picked);

    // 🔥 REAL FIX: DAYS LEFT COMPARISON
    final shouldNotify =
        oldDaysLeft == null || oldDaysLeft != newDaysLeft;

    if (shouldNotify) {
      await _sendInstantNotification();
      await NotificationService.scheduleDaily(
        examDate: picked,
      );
    }
  }

  /* ================= INSTANT NOTIFICATION ================= */

  Future<void> _sendInstantNotification() async {
    if (quotes.isEmpty || examDate == null) return;

    final quote = quotes[Random().nextInt(quotes.length)];

    await NotificationService.showInstant(
      daysLeft: daysLeft,
      quote: quote,
    );
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exam Countdown')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      'Days Remaining',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
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
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: const Text('Select Exam Date'),
              onPressed: _pickDate,
            ),
          ],
        ),
      ),
    );
  }
}
