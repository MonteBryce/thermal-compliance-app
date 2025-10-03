/// Main entry point for Compliance Dashboard
library;
import 'package:flutter/material.dart';
import 'screens/compliance_dashboard_screen.dart';

void main() {
  runApp(const ComplianceApp());
}

class ComplianceApp extends StatelessWidget {
  const ComplianceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComplianceDashboardScreen();
  }
}