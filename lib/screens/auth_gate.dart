import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'permission_gate.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    // 🔒 Not signed in → sign in anonymously
    if (user == null) {
      auth.signInAnonymously().catchError((e) {
        debugPrint('Auth error: $e');
      });

      // ⏳ While signing in
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // ✅ Signed in → go next
    return const PermissionGate();
  }
}
