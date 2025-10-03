/// Main entry point for Job Dashboard
library;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/main_job_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: JobDashboardApp()));
}

class JobDashboardApp extends StatelessWidget {
  const JobDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainJobDashboardScreen();
  }
}