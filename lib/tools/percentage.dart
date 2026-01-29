import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ads.dart';
import '../services/ad_click_tracker.dart';

class PercentagePage extends StatefulWidget {
  const PercentagePage({super.key});

  @override
  State<PercentagePage> createState() => _PercentagePageState();
}

class _PercentagePageState extends State<PercentagePage> {
  final TextEditingController obtainedCtrl = TextEditingController();
  final TextEditingController totalCtrl = TextEditingController();

  String result = '';
  bool calculated = false;

  BannerAd? _bannerAd;
  bool _bannerLoaded = false;

  @override
  void initState() {
    super.initState();

    /// 🔥 TOOL OPEN CLICK
    AdClickTracker.registerClick();

    /// 🔔 BOTTOM BANNER
    _bannerAd = BannerAd(
      adUnitId: AdsService.bannerId,
      size: AdSize.mediumRectangle,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            setState(() => _bannerLoaded = true);
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _calculatePercentage() {
    /// 🔥 TOOL USE CLICK
    AdClickTracker.registerClick();

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

    final percent = (obtained / total) * 100;

    setState(() {
      calculated = true;
      result = percent.toStringAsFixed(2);
    });
  }

  @override
  void dispose() {
    obtainedCtrl.dispose();
    totalCtrl.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Percentage Calculator')),
      body: Column(
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
                              prefixIcon: Icon(Icons.assignment),
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
                        color: Colors.blue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text('Your Percentage'),
                          const SizedBox(height: 8),
                          Text(
                            '$result %',
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_bannerLoaded && _bannerAd != null)
            SafeArea(
              child: SizedBox(
                height: _bannerAd!.size.height.toDouble(),
                width: _bannerAd!.size.width.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
        ],
      ),
    );
  }
}