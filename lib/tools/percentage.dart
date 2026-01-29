import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:confetti/confetti.dart';

import '../services/ads.dart';
import '../services/ad_click_tracker.dart';
import '../widgets/ad_placeholder.dart';

class PercentagePage extends StatefulWidget {
  const PercentagePage({super.key});

  @override
  State<PercentagePage> createState() => _PercentagePageState();
}

class _PercentagePageState extends State<PercentagePage> {
  final TextEditingController obtainedCtrl = TextEditingController();
  final TextEditingController totalCtrl = TextEditingController();

  String result = '';
  String message = '';
  bool calculated = false;

  BannerAd? _bannerAd;
  bool _bannerLoaded = false;

  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();

    /// 🔥 Tool open = one click
    AdClickTracker.registerClick();

    _confetti = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    /// 🔔 Banner via AdsService (single source of truth)
    _bannerAd = AdsService.createBanner(
      onState: (loaded) {
        if (!mounted) return;
        setState(() => _bannerLoaded = loaded);
      },
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _calculatePercentage() {
    final obtained = double.tryParse(obtainedCtrl.text.trim());
    final total = double.tryParse(totalCtrl.text.trim());

    if (obtained == null || total == null) {
      _showError('Please enter valid numbers');
      return;
    }
    if (total <= 0) {
      _showError('Total marks must be greater than 0');
      return;
    }
    if (obtained < 0) {
      _showError('Obtained marks cannot be negative');
      return;
    }
    if (obtained > total) {
      _showError('Obtained marks cannot exceed total marks');
      return;
    }

    /// ✅ Count click ONLY on success
    AdClickTracker.registerClick();

    final percent = (obtained / total) * 100;
    final value = percent.toStringAsFixed(2);

    /// 🧠 Result-based messaging + confetti
    String msg;
    if (percent >= 90) {
      msg = 'Outstanding performance! 🔥';
      _confetti.play();
    } else if (percent >= 75) {
      msg = 'Great job, keep pushing 💪';
      _confetti.play();
    } else if (percent >= 60) {
      msg = 'Good effort, you can do better 👍';
    } else if (percent >= 40) {
      msg = 'Needs improvement, don’t give up 📚';
    } else {
      msg = 'Tough result, but this is not the end 🚀';
    }

    setState(() {
      calculated = true;
      result = value;
      message = msg;
    });
  }

  @override
  void dispose() {
    obtainedCtrl.dispose();
    totalCtrl.dispose();
    _bannerAd?.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen =
        MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Percentage Calculator')),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          /// 🎉 CONFETTI
          ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 25,
          ),

          Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              TextField(
                                controller: obtainedCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Obtained Marks',
                                  prefixIcon: Icon(Icons.edit),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: totalCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Total Marks',
                                  prefixIcon:
                                      Icon(Icons.assignment),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: _calculatePercentage,
                        child: const Text('Calculate Percentage'),
                      ),

                      const SizedBox(height: 30),

                      if (calculated)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color:
                                Colors.blue.withOpacity(0.08),
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                message,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '$result %',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              /// 🔔 Banner OR Placeholder
              if (!isKeyboardOpen)
                SizedBox(
                  height: 250,
                  child: _bannerLoaded && _bannerAd != null
                      ? AdWidget(ad: _bannerAd!)
                      : const AdPlaceholder(),
                ),
            ],
          ),
        ],
      ),
    );
  }
}