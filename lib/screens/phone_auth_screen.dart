import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:country_picker/country_picker.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../navigation/app_shell.dart';
import '../services/otp_guard_service.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  final _auth = FirebaseAuth.instance;

  String _countryCode = '+1';
  String? _verificationId;

  bool _otpSent = false;
  bool _loading = false;

  Timer? _uiTimer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _syncGuard();
  }

  /* ================= OTP GUARD ================= */

  void _syncGuard() {
    _uiTimer?.cancel();

    final state = OtpGuardService.status();
    _remaining = state.remaining;

    if (state.isBlocked) {
      _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        final s = OtpGuardService.status();
        setState(() => _remaining = s.remaining);
        if (!s.isBlocked) _uiTimer?.cancel();
      });
    }
  }

  /* ================= SEND OTP ================= */

  Future<void> _sendOtp({bool resend = false}) async {
    final guard = OtpGuardService.status();

    if (guard.isBlocked) {
      _show(OtpGuardService.message(guard.blockLevel));
      return;
    }

    if (_phoneCtrl.text.trim().isEmpty) {
      _show('Please enter phone number');
      return;
    }

    setState(() => _loading = true);

    await _auth.verifyPhoneNumber(
      phoneNumber: '$_countryCode${_phoneCtrl.text.trim()}',
      timeout: const Duration(seconds: 60),

      verificationCompleted: (cred) async {
        await _auth.signInWithCredential(cred);
        await _onLoginSuccess();
      },

      verificationFailed: (_) {
        OtpGuardService.recordFailure();
        _syncGuard();
        _show('Authentication service broken ⛓️‍💥');
      },

      codeSent: (id, _) {
        _verificationId = id;
        _otpSent = true;
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
    if (_otpCtrl.text.trim().isEmpty) {
      _show('Please enter OTP first');
      return;
    }

    if (_verificationId == null) return;

    setState(() => _loading = true);

    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpCtrl.text.trim(),
      );

      await _auth.signInWithCredential(cred);
      OtpGuardService.resetOnSuccess();
      await _onLoginSuccess();
    } catch (_) {
      OtpGuardService.recordFailure();
      _syncGuard();
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

  /* ================= HELPERS ================= */

  void _show(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  String _time(Duration d) =>
      '${d.inMinutes.remainder(60)}:${(d.inSeconds.remainder(60)).toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _uiTimer?.cancel();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    final guard = OtpGuardService.status();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Image.asset('assets/logo.png', height: 80),
              const SizedBox(height: 24),
              const Icon(Icons.lock_outline, size: 80),
              const SizedBox(height: 24),

              /// PHONE INPUT
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      showCountryPicker(
                        context: context,
                        showPhoneCode: true,
                        onSelect: (c) =>
                            setState(() => _countryCode = '+${c.phoneCode}'),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(_countryCode,
                          style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration:
                          const InputDecoration(hintText: 'Phone number'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              /// OTP BOX
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
                  ),
                  onChanged: (_) {},
                ),

              const SizedBox(height: 24),

              /// MAIN BUTTON
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

              /// RESEND
              TextButton(
                onPressed: guard.isBlocked
                    ? null
                    : () => _sendOtp(resend: true),
                child: Text(
                  guard.isBlocked
                      ? 'Try again after ${_time(_remaining)}'
                      : 'Resend OTP',
                  style: TextStyle(
                    color: guard.isBlocked ? Colors.grey : Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
