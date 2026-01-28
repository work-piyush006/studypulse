import 'package:flutter/material.dart';

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
    final obtained = double.tryParse(obtainedCtrl.text.trim());
    final total = double.tryParse(totalCtrl.text.trim());

    // ❌ Validation
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Percentage Calculator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // INPUT CARD
            Card(
              elevation: 1,
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

            // CALCULATE BUTTON
            ElevatedButton(
              onPressed: _calculatePercentage,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Calculate Percentage',
                style: TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 30),

            // RESULT
            if (calculated)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Your Percentage',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$result %',
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
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
