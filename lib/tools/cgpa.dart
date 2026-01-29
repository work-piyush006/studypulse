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

    AdClickTracker.registerClick();

    _bannerAd = BannerAd(
      adUnitId: AdsService.bannerId,
      size: AdSize.mediumRectangle,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _bannerLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  void _calculate() {
    AdClickTracker.registerClick();

    final cgpa = double.tryParse(cgpaCtrl.text.trim());
    if (cgpa == null || cgpa <= 0 || cgpa > 10) return;

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
    return Scaffold(
      appBar: AppBar(title: const Text('CGPA Calculator')),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextField(
                    controller: cgpaCtrl,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Enter CGPA'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _calculate,
                    child: const Text('Convert'),
                  ),
                  if (calculated) Text('$result %'),
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