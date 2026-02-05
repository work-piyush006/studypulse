import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _verificationId;
  bool _otpSent = false;
  bool _loading = false;

  int _triesLeft = 3;
  int _cooldown = 0;
  Timer? _timer;

  /* ================= SEND OTP ================= */

  Future<void> _sendOtp({bool resend = false}) async {
    if (_triesLeft <= 0) return;

    setState(() {
      _loading = true;
    });

    await _auth.verifyPhoneNumber(
      phoneNumber: _phoneCtrl.text.trim(),
      timeout: const Duration(seconds: 60),

      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },

      verificationFailed: (FirebaseAuthException e) {
        _show(e.message ?? 'Verification failed');
      },

      codeSent: (verificationId, _) {
        _verificationId = verificationId;
        _otpSent = true;

        _triesLeft--;
        if (_triesLeft == 0) {
          _startCooldown();
        }

        _show(resend ? 'OTP resent' : 'OTP sent');
      },

      codeAutoRetrievalTimeout: (id) {
        _verificationId = id;
      },
    );

    setState(() => _loading = false);
  }

  /* ================= VERIFY OTP ================= */

  Future<void> _verifyOtp() async {
    if (_verificationId == null) return;

    setState(() => _loading = true);

    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpCtrl.text.trim(),
      );

      await _auth.signInWithCredential(cred);

      _show('Login successful');

    } catch (_) {
      _show('Invalid OTP');
    }

    setState(() => _loading = false);
  }

  /* ================= COOLDOWN ================= */

  void _startCooldown() {
    _cooldown = 299; // 4:59 minutes

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_cooldown == 0) {
        t.cancel();
        _triesLeft = 3;
        setState(() {});
      } else {
        setState(() => _cooldown--);
      }
    });
  }

  /* ================= UI HELPERS ================= */

  void _show(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  String _cooldownText() {
    final m = _cooldown ~/ 60;
    final s = _cooldown % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phone Login')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone (+91XXXXXXXXXX)',
              ),
            ),

            if (_otpSent)
              TextField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Enter OTP',
                ),
              ),

            const SizedBox(height: 24),

            if (_triesLeft > 0)
              ElevatedButton(
                onPressed: _loading
                    ? null
                    : _otpSent
                        ? _verifyOtp
                        : _sendOtp,
                child: _loading
                    ? const CircularProgressIndicator()
                    : Text(_otpSent ? 'Verify OTP' : 'Send OTP'),
              ),

            if (_otpSent && _triesLeft > 0)
              TextButton(
                onPressed: _loading ? null : () => _sendOtp(resend: true),
                child: Text('Resend OTP ($_triesLeft tries left)'),
              ),

            if (_triesLeft == 0)
              Column(
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Too many attempts',
                    style: TextStyle(color: Colors.red),
                  ),
                  Text(
                    'OTP will be received after $_cooldownText()',
                    style: const TextStyle(color: Colors.orange),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
