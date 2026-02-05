import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'phone_auth_screen.dart';
import 'permission_gate.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // 🔒 Not logged in → Phone Auth
    if (user == null) {
      return const PhoneAuthScreen();
    }

    // ✅ Logged in → Permission flow → App
    return const PermissionGate();
  }
}
