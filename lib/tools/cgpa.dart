// lib/tools/cgpa.dart

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:confetti/confetti.dart';

import '../services/ads.dart';
import '../services/ad_click_tracker.dart';
import '../widgets/ad_placeholder.dart';

class CGPAPage extends StatefulWidget {
  const CGPAPage({super.key});

  @override
  State<CGPAPage> createState() => _CGPAPageState();
}

class _CGPAPageState extends State<CGPAPage> {
  final TextEditingController _cgpaCtrl = TextEditingController();

  String _result = '';
  String _message = '';
  bool _calculated = false;

  BannerAd? _bannerAd;
  bool _bannerLoaded = false;

  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();

    // ✅ Tool open = valid user intent
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

  void _calculate() {
    final value = double.tryParse(_cgpaCtrl.text.trim());

    if (value == null || value <= 0 || value > 10) {
      _showError('Enter a valid CGPA between 0 and 10');
      return;
    }

    // ✅ Count ONLY on successful calculation
    AdClickTracker.registerClick();

    final percent = value * 9.5;
    final formatted = percent.toStringAsFixed(2);

    String msg;
    if (value >= 9) {
      msg = 'Excellent academic performance 🌟';
      _confetti.play();
    } else if (value >= 8) {
      msg = 'Great result, well done 💪';
      _confetti.play();
    } else if (value >= 7) {
      msg = 'Good score, keep improving 👍';
    } else if (value >= 6) {
      msg = 'Average performance, you can do better 📘';
    } else {
      msg = 'Needs improvement, don’t lose hope 🚀';
    }

    setState(() {
      _calculated = true;
      _result = formatted;
      _message = msg;
    });
  }

  @override
  void dispose() {
    _cgpaCtrl.dispose();
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
        title: const Text('CGPA Calculator'),
        leading: const BackButton(), // ❌ NO ad count on back
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
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
                          child: TextField(
                            controller: _cgpaCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Enter CGPA (0 – 10)',
                              prefixIcon: Icon(Icons.school),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: _calculate,
                        child: const Text('Convert to Percentage'),
                      ),

                      const SizedBox(height: 30),

                      if (_calculated)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                _message,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '$_result %',
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
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