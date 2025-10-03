import 'package:flutter/material.dart';
import '../screens/project_selector_screen.dart';
import '../screens/project_summary_screen.dart';
import '../screens/hour_selector_screen.dart';
import '../screens/hourly_entry_form.dart';
import '../screens/review_all_entries_screen.dart';

class AppRoutes {
  static const home = '/';
  static const dailySummary = '/dailySummary';
  static const hourSelector = '/hourSelector';
  static const hourlyEntry = '/hourlyEntry';
  static const reviewAll = '/reviewAll';
  static const systemMetrics = '/systemMetrics';
}

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => const JobSelectorScreen(),
  '/project_selector': (context) => const JobSelectorScreen(),
  '/daily_summary': (context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ??
            {};
    return ProjectSummaryScreen(
      projectId: args['projectId'],
      logId: args['logId'],
    );
  },
  '/hour_selector': (context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ??
            {};
    return HourSelectorScreen(
      projectNumber: args['projectNumber'],
      logId: args['logId'],
      logType: args['logType'],
    );
  },
  '/hourly_entry': (context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ??
            {};
    return HourlyEntryFormScreen(
      projectId: args['projectId'],
      logId: args['logId'],
      hour: args['hour'],
      entryDocId: args['entryDocId'],
    );
  },
  '/review_all': (context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ??
            {};
    return ReviewAllEntriesScreen(
      projectId: args['projectId'],
      logId: args['logId'],
    );
  },
};
