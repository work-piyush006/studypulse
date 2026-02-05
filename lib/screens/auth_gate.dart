import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'permission_gate.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _handleAuth();
  }

  Future<void> _handleAuth() async {
    final auth = FirebaseAuth.instance;

    if (auth.currentUser == null) {
      try {
        await auth.signInAnonymously();
      } catch (e) {
        debugPrint('Auth error: $e');
      }
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PermissionGate()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
