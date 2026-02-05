import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'google_sign_in_screen.dart';
import 'permission_gate.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const GoogleSignInScreen();
    }

    return const PermissionGate();
  }
}
