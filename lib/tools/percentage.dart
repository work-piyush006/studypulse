// lib/tools/percentage.dart

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
  final TextEditingController _obtainedCtrl =
      TextEditingController();
  final TextEditingController _totalCtrl =
      TextEditingController();

  String _result = '';
  String _message = '';
  bool _calculated = false;

  BannerAd? _bannerAd;
  bool _bannerLoaded = false;

  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();

    /// 🔥 Tool opened = real intent
    AdClickTracker.registerClick();

    _confetti = ConfettiController(
      duration: const Duration(seconds: 2),
    );

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
    final obtained =
        double.tryParse(_obtainedCtrl.text.trim());
    final total =
        double.tryParse(_totalCtrl.text.trim());

    if (obtained == null || total == null) {
      _showError('Please enter valid numbers');
      return;
    }

    if (total <= 0 || obtained < 0 || obtained > total) {
      _showError('Invalid marks entered');
      return;
    }

    /// ✅ Count ONLY on valid success
    AdClickTracker.registerClick();

    final percent = (obtained / total) * 100;
    final value = percent.toStringAsFixed(2);

    String msg;
    if (percent >= 75) {
      msg = 'Excellent result 🎉';
      _confetti.play();
    } else if (percent >= 60) {
      msg = 'Good effort 👍';
    } else {
      msg = 'Keep practicing 💪';
    }

    setState(() {
      _calculated = true;
      _result = value;
      _message = msg;
    });
  }

  @override
  void dispose() {
    _obtainedCtrl.dispose();
    _totalCtrl.dispose();
    _bannerAd?.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen =
        MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Percentage Calculator'),
        leading: BackButton(
          onPressed: () {
            AdClickTracker.registerClick();
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality:
                BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 25,
          ),
          Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _obtainedCtrl,
                        keyboardType:
                            TextInputType.number,
                        decoration:
                            const InputDecoration(
                          labelText: 'Obtained Marks',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _totalCtrl,
                        keyboardType:
                            TextInputType.number,
                        decoration:
                            const InputDecoration(
                          labelText: 'Total Marks',
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _calculatePercentage,
                        child:
                            const Text('Calculate'),
                      ),
                      const SizedBox(height: 24),
                      if (_calculated)
                        Text(
                          '$_result %\n$_message',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              /// 🔔 Banner or Placeholder
              if (!isKeyboardOpen)
                SizedBox(
                  height: 90,
                  child: _bannerLoaded &&
                          _bannerAd != null
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