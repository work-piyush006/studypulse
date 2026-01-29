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
  final TextEditingController cgpaCtrl = TextEditingController();

  String result = '';
  String message = '';
  bool calculated = false;

  BannerAd? _bannerAd;
  bool _bannerLoaded = false;

  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();

    /// 🔥 TOOL OPEN CLICK (once)
    AdClickTracker.registerClick();

    _confetti = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    _bannerAd = BannerAd(
      adUnitId: AdsService.bannerId,
      size: AdSize.mediumRectangle,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _bannerLoaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          setState(() => _bannerLoaded = false);
        },
      ),
    )..load();
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
    final cgpa = double.tryParse(cgpaCtrl.text.trim());

    if (cgpa == null) {
      _showError('Enter a valid CGPA number');
      return;
    }
    if (cgpa <= 0) {
      _showError('CGPA must be greater than 0');
      return;
    }
    if (cgpa > 10) {
      _showError('CGPA cannot be more than 10');
      return;
    }

    /// ✅ COUNT ONLY ON SUCCESS
    AdClickTracker.registerClick();

    final percent = cgpa * 9.5;
    final value = percent.toStringAsFixed(2);

    // 🧠 RESULT MESSAGE LOGIC
    String msg;
    if (cgpa >= 9) {
      msg = 'Excellent academic performance 🌟';
      _confetti.play();
    } else if (cgpa >= 8) {
      msg = 'Great result, well done 💪';
      _confetti.play();
    } else if (cgpa >= 7) {
      msg = 'Good score, keep improving 👍';
    } else if (cgpa >= 6) {
      msg = 'Average performance, you can do better 📘';
    } else {
      msg = 'Needs improvement, don’t lose hope 🚀';
    }

    setState(() {
      calculated = true;
      result = value;
      message = msg;
    });
  }

  @override
  void dispose() {
    cgpaCtrl.dispose();
    _bannerAd?.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen =
        MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      appBar: AppBar(title: const Text('CGPA Calculator')),
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
                          child: TextField(
                            controller: cgpaCtrl,
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

                      if (calculated)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.08),
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

              /// 🔔 BANNER OR PLACEHOLDER
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