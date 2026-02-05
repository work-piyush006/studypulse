import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:country_picker/country_picker.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../navigation/app_shell.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _countryCode = '+91';
  String? _verificationId;

  bool _otpSent = false;
  bool _loading = false;

  int _triesLeft = 3;
  int _cooldown = 0;
  Timer? _timer;

  /* ================= SEND OTP ================= */

  Future<void> _sendOtp({bool resend = false}) async {
    if (_triesLeft <= 0) return;

    setState(() => _loading = true);

    await _auth.verifyPhoneNumber(
      phoneNumber: '$_countryCode${_phoneCtrl.text.trim()}',
      timeout: const Duration(seconds: 60),

      verificationCompleted: (cred) async {
        await _auth.signInWithCredential(cred);
        await _onLoginSuccess();
      },

      verificationFailed: (e) {
        _show(e.message ?? 'Verification failed');
      },

      codeSent: (verificationId, _) {
        _verificationId = verificationId;
        _otpSent = true;

        _triesLeft--;
        if (_triesLeft == 0) _startCooldown();

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
      await _onLoginSuccess();
    } catch (_) {
      _show('Invalid OTP');
    }

    setState(() => _loading = false);
  }

  /* ================= LOGIN SUCCESS ================= */

  Future<void> _onLoginSuccess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await FirebaseMessaging.instance.getToken();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({
      'uid': user.uid,
      'phone': user.phoneNumber,
      'provider': 'phone',
      'fcmToken': token,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AppShell()),
      (_) => false,
    );
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

  String _cooldownText() {
    final m = _cooldown ~/ 60;
    final s = _cooldown % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _show(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.lock_outline, size: 80),
            const SizedBox(height: 20),

            Row(
              children: [
                InkWell(
                  onTap: () {
                    showCountryPicker(
                      context: context,
                      showPhoneCode: true,
                      onSelect: (c) {
                        setState(() => _countryCode = '+${c.phoneCode}');
                      },
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _countryCode,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: 'Phone number',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            if (_otpSent)
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(10),
                  fieldHeight: 52,
                  fieldWidth: 44,
                  activeColor:
                      Theme.of(context).colorScheme.primary,
                  selectedColor:
                      Theme.of(context).colorScheme.primary,
                  inactiveColor: Colors.grey,
                ),
                onChanged: (_) {},
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
                onPressed:
                    _loading ? null : () => _sendOtp(resend: true),
                child: Text('Resend OTP ($_triesLeft tries left)'),
              ),

            if (_triesLeft == 0)
              Column(
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Too many attempts',
                    style: TextStyle(color: Colors.red),
                  ),
                  Text(
                    'Try again after ${_cooldownText()}',
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
