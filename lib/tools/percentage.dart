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

    /// 🔔 Adaptive banner (correct API)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _bannerAd = await AdsService.createAdaptiveBanner(
        context: context,
        onState: (loaded) {
          if (!mounted) return;
          setState(() => _bannerLoaded = loaded);
        },
      );
    });
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
    if (total <= 0 || obtained < 0 || obtained > total) {
      _showError('Invalid marks entered');
      return;
    }

    AdClickTracker.registerClick();

    final percent = (obtained / total) * 100;
    final value = percent.toStringAsFixed(2);

    String msg;
    if (percent >= 75) {
      msg = 'Great job! 🎉';
      _confetti.play();
    } else if (percent >= 60) {
      msg = 'Good effort 👍';
    } else {
      msg = 'Keep practicing 💪';
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
          ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
          ),

          Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextField(
                        controller: obtainedCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Obtained Marks'),
                      ),
                      TextField(
                        controller: totalCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Total Marks'),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _calculatePercentage,
                        child: const Text('Calculate'),
                      ),
                      if (calculated)
                        Text('$result %\n$message',
                            textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),

              if (!isKeyboardOpen)
                SizedBox(
                  height: 90,
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