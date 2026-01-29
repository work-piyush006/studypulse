import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ads.dart';
import '../services/ad_click_tracker.dart';

class CGPAPage extends StatefulWidget {
  const CGPAPage({super.key});

  @override
  State<CGPAPage> createState() => _CGPAPageState();
}

class _CGPAPageState extends State<CGPAPage> {
  final TextEditingController cgpaCtrl = TextEditingController();
  String result = '';
  bool calculated = false;

  late final BannerAd _bannerAd;
  bool _bannerLoaded = false;

  @override
  void initState() {
    super.initState();

    /// 🔥 TOOL BOTTOM BANNER (SINGLE)
    _bannerAd = AdsService.createBanner()
      ..listener = BannerAdListener(
        onAdLoaded: (_) {
          setState(() => _bannerLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
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

  void _calculate() {
    AdClickTracker.registerClick(); // 🔔 COUNT TOOL USE

    final cgpa = double.tryParse(cgpaCtrl.text.trim());

    // ❌ Validation (UNCHANGED)
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

    final percentage = cgpa * 9.5;

    setState(() {
      calculated = true;
      result = percentage.toStringAsFixed(2);
    });
  }

  @override
  void dispose() {
    cgpaCtrl.dispose();
    _bannerAd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CGPA Calculator')),
      body: Column(
        children: [
          /// ================= CONTENT =================
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
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Equivalent Percentage',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$result %',
                            style: const TextStyle(
                              fontSize: 32,
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

          /// ================= BOTTOM BANNER =================
          if (_bannerLoaded)
            SafeArea(
              child: SizedBox(
                height: _bannerAd.size.height.toDouble(),
                width: _bannerAd.size.width.toDouble(),
                child: AdWidget(ad: _bannerAd),
              ),
            ),
        ],
      ),
    );
  }
}