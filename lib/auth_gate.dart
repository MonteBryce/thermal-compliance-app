import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'screens/project_selector_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  // DEV MODE: Set to true to bypass authentication
  static const bool _devBypassAuth = true;

  @override
  Widget build(BuildContext context) {
    // Development bypass - skip authentication entirely
    if (_devBypassAuth) {
      return const JobSelectorScreen();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const JobSelectorScreen(); // ✅ go straight to job selector
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
