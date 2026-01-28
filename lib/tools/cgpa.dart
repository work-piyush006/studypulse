import 'package:flutter/material.dart';

class CGPAPage extends StatefulWidget {
  const CGPAPage({super.key});

  @override
  State<CGPAPage> createState() => _CGPAPageState();
}

class _CGPAPageState extends State<CGPAPage> {
  final TextEditingController cgpaCtrl = TextEditingController();
  String result = '';
  bool calculated = false;

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

    // ❌ Validation
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CGPA Calculator')),
      body: Padding(
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
    );
  }
}
