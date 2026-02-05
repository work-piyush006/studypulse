import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'permission_gate.dart';
import 'google_sign_in_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // ❌ Not logged in → Google Sign-In screen
    if (user == null) {
      return const GoogleSignInScreen();
    }

    // ✅ Logged in → continue app flow
    return const PermissionGate();
  }
}
