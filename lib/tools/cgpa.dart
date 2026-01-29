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

  BannerAd? _bannerAd;
  bool _bannerLoaded = false;

  @override
  void initState() {
    super.initState();

    /// 🔥 TOOL OPEN CLICK
    AdClickTracker.registerClick();

    _bannerAd = BannerAd(
      adUnitId: AdsService.bannerId,
      size: AdSize.mediumRectangle,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _bannerLoaded = true);
        },
        onAdFailedToLoad: (ad, _) => ad.dispose(),
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

    setState(() {
      calculated = true;
      result = (cgpa * 9.5).toStringAsFixed(2);
    });
  }

  @override
  void dispose() {
    cgpaCtrl.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen =
        MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      appBar: AppBar(title: const Text('CGPA Calculator')),
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

          if (_bannerLoaded && _bannerAd != null && !isKeyboardOpen)
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