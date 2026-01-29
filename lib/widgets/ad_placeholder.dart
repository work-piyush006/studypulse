import 'dart:async';
import 'package:flutter/material.dart';

class AdPlaceholder extends StatefulWidget {
  const AdPlaceholder({super.key});

  @override
  State<AdPlaceholder> createState() => _AdPlaceholderState();
}

class _AdPlaceholderState extends State<AdPlaceholder> {
  int dots = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 450), (_) {
      if (!mounted) return;
      setState(() => dots = (dots + 1) % 4);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.ads_click, color: Colors.grey, size: 28),
          const SizedBox(height: 8),
          Text(
            'Sponsored content loading${'.' * dots}',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}