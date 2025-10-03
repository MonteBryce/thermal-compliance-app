import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth_gate.dart';
import '../screens/enhanced_project_selector_screen.dart';
import '../screens/project_summary_screen.dart';
import '../screens/hour_selector_screen.dart';
import '../screens/hourly_entry_form.dart' show HourlyEntryScreen;
import '../screens/review_all_entries_screen.dart';
import '../screens/system_metrics_screen.dart';
import '../screens/final_readings_screen.dart';
import '../screens/daily_summary_screen.dart';
import '../screens/web_ocr_scan_screen.dart';
import '../screens/ocr_demo_screen.dart';
import '../screens/seed_data_screen.dart';
// import '../screens/enhanced_ocr_scan_screen.dart';
import '../model/job_data.dart';
import 'route_names.dart';
import 'navigation_guards.dart';
import 'route_transitions.dart';
import 'route_parameter_validator.dart';

// Global router instance with enhanced configuration
final GoRouter appRouter = GoRouter(
  initialLocation: RouteNames.home,
  debugLogDiagnostics: true,

  // Enhanced error handling
  errorPageBuilder: (context, state) => MaterialPage(
    key: state.pageKey,
    child: EnhancedErrorScreen(
      error: state.error?.toString() ?? 'Unknown routing error',
      path: state.matchedLocation,
      onRetry: () => context.go(RouteNames.projects),
    ),
  ),

  // Centralized navigation guards and redirects
  redirect: (context, state) => NavigationGuards.handleRedirect(context, state),

  routes: [
    // Root route with authentication
    GoRoute(
      path: RouteNames.home,
      name: RouteNames.homeName,
      builder: (context, state) => const AuthGate(),
    ),

    // Project management routes
    GoRoute(
      path: RouteNames.projects,
      name: RouteNames.projectsName,
      builder: (context, state) => const EnhancedProjectSelectorScreen(),
      routes: [
        // Project-specific nested routes
        GoRoute(
          path: ':projectId',
          builder: (context, state) {
            // If accessed directly without a specific sub-route, show project summary
            final projectId = state.pathParameters['projectId'];
            if (projectId == null) {
              return const RouteErrorWidget(
                  message: 'Missing project ID in URL');
            }
            return _buildProjectSummary(context, state);
          },
          routes: [
            // Project summary
            GoRoute(
              path: 'summary',
              name: RouteNames.projectSummaryName,
              pageBuilder: (context, state) =>
                  RouteTransitions.rotationTransition(
                context,
                state,
                _buildProjectSummary(context, state),
              ),
            ),

            // Log-based nested routes
            GoRoute(
              path: 'logs/:logDate',
              builder: (context, state) {
                // If accessed directly without a specific sub-route, show hour selector
                return _buildHourSelector(context, state);
              },
              routes: [
                // Daily summary
                GoRoute(
                  path: 'daily-summary',
                  name: RouteNames.dailySummaryName,
                  pageBuilder: (context, state) =>
                      RouteTransitions.fadeTransition(
                    context,
                    state,
                    _buildDailySummary(context, state),
                  ),
                ),

                // Hour selector
                GoRoute(
                  path: 'hours',
                  name: RouteNames.hourSelectorName,
                  pageBuilder: (context, state) =>
                      RouteTransitions.slideTransition(
                    context,
                    state,
                    _buildHourSelector(context, state),
                  ),
                ),

                // Hourly entry
                GoRoute(
                  path: 'entry/:hour',
                  name: RouteNames.hourlyEntryName,
                  pageBuilder: (context, state) =>
                      RouteTransitions.slideUpTransition(
                    context,
                    state,
                    _buildHourlyEntry(context, state),
                  ),
                ),

                // Review entries
                GoRoute(
                  path: 'review',
                  name: RouteNames.reviewAllName,
                  pageBuilder: (context, state) =>
                      RouteTransitions.fadeTransition(
                    context,
                    state,
                    _buildReviewEntries(context, state),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),

    // Standalone routes
    GoRoute(
      path: RouteNames.systemMetrics,
      name: RouteNames.systemMetricsName,
      pageBuilder: (context, state) => RouteTransitions.scaleTransition(
        context,
        state,
        const SystemMetricsScreen(),
      ),
    ),

    GoRoute(
      path: RouteNames.finalReadings,
      name: RouteNames.finalReadingsName,
      pageBuilder: (context, state) => RouteTransitions.scaleTransition(
        context,
        state,
        _buildFinalReadings(context, state),
      ),
    ),

    // OCR Scanner route
    GoRoute(
      path: '/ocr-scan',
      name: 'ocrScan',
      pageBuilder: (context, state) => RouteTransitions.slideUpTransition(
        context,
        state,
        _buildOcrScan(context, state),
      ),
    ),

    // Data Seeding route (for screenshots)
    GoRoute(
      path: '/seed-data',
      name: 'seedData',
      builder: (context, state) => const SeedDataScreen(),
    ),

    // OCR Demo route
    GoRoute(
      path: RouteNames.ocrDemo,
      name: RouteNames.ocrDemoName,
      pageBuilder: (context, state) => RouteTransitions.slideUpTransition(
        context,
        state,
        const OcrDemoScreen(),
      ),
    ),

    // Enhanced OCR Scanner route
    GoRoute(
      path: '/enhanced-ocr-scan',
      name: 'enhancedOcrScan',
      pageBuilder: (context, state) => RouteTransitions.slideUpTransition(
        context,
        state,
        _buildEnhancedOcrScan(context, state),
      ),
    ),
  ],
);

// Enhanced route builders with proper error handling
Widget _buildProjectSummary(BuildContext context, GoRouterState state) {
  try {
    final projectId = state.pathParameters['projectId'];
    if (projectId == null) {
      return const RouteErrorWidget(message: 'Missing project ID in URL');
    }

    final extra = state.extra as Map<String, dynamic>?;
    JobData? initialJob;

    if (extra != null && extra['initialJob'] != null) {
      final jobData = extra['initialJob'];
      if (jobData is JobData) {
        initialJob = jobData;
      } else if (jobData is Map<String, dynamic>) {
        initialJob = JobData.fromJson(jobData);
      }
    }

    return ProjectSummaryScreen(
      initialJob: initialJob,
      projectId: projectId,
    );
  } catch (e) {
    return RouteErrorWidget(
        message: 'Failed to load project summary: ${e.toString()}');
  }
}

Widget _buildDailySummary(BuildContext context, GoRouterState state) {
  try {
    final projectId = state.pathParameters['projectId'];
    final logDate = state.pathParameters['logDate'];

    if (projectId == null || logDate == null) {
      return const RouteErrorWidget(
          message: 'Missing required path parameters for Daily Summary');
    }

    final args = RouteParameterValidator.validateRouteExtra(state.extra);
    final selectedDate = RouteParameterValidator.extractDateTimeParam(args, 'selectedDate', DateTime.now());

    return DailySummaryScreen(
      projectId: projectId,
      logId: logDate,
      selectedDate: selectedDate,
    );
  } catch (e) {
    return RouteErrorWidget(message: 'Daily summary error: ${e.toString()}');
  }
}

Widget _buildHourSelector(BuildContext context, GoRouterState state) {
  try {
    final projectId = state.pathParameters['projectId'];
    final logDate = state.pathParameters['logDate'];

    if (projectId == null || logDate == null) {
      return const RouteErrorWidget(
          message: 'Missing required path parameters for Hour Selector');
    }

    final args = RouteParameterValidator.validateRouteExtra(state.extra);
    final logType = RouteParameterValidator.extractNonNullStringParam(args, 'logType', 'thermal');

    return HourSelectorScreen(
      projectNumber: projectId,
      logId: logDate,
      logType: logType,
    );
  } catch (e) {
    return RouteErrorWidget(message: 'Hour selector error: ${e.toString()}');
  }
}

Widget _buildHourlyEntry(BuildContext context, GoRouterState state) {
  try {
    final projectId = state.pathParameters['projectId'];
    final logDate = state.pathParameters['logDate'];
    final hourStr = state.pathParameters['hour'];

    debugPrint(
        '🔍 Building hourly entry: projectId=$projectId, logDate=$logDate, hour=$hourStr');

    if (projectId == null || logDate == null || hourStr == null) {
      debugPrint('❌ Missing path parameters for hourly entry');
      return const RouteErrorWidget(
          message: 'Missing required path parameters for Hourly Entry');
    }

    final hour = RouteParameterValidator.validateHour(hourStr);
    if (hour == null) {
      debugPrint('❌ Invalid hour parameter: $hourStr');
      return const RouteErrorWidget(
          message: 'Invalid hour parameter. Must be 0-23.');
    }

    final args = RouteParameterValidator.validateRouteExtra(state.extra);
    final logType = RouteParameterValidator.extractNonNullStringParam(args, 'logType', 'thermal');

    // Handle existingData safely using validator
    final existingData = RouteParameterValidator.validateThermalReading(
      args?['existingData'],
      hour,
    );

    debugPrint(
        '✅ Creating HourlyEntryScreen with hour=$hour, projectId=$projectId, logDate=$logDate');

    return HourlyEntryScreen(
      hour: hour,
      existingData: existingData,
      projectId: projectId,
      logId: logDate,
      logType: logType,
      enteredHours: RouteParameterValidator.extractIntSetParam(args, 'enteredHours'),
      selectedDate: RouteParameterValidator.extractDateTimeParam(args, 'selectedDate'),
    );
  } catch (e) {
    debugPrint('❌ Error building hourly entry: $e');
    return RouteErrorWidget(message: 'Route error: ${e.toString()}');
  }
}

Widget _buildReviewEntries(BuildContext context, GoRouterState state) {
  final projectId = state.pathParameters['projectId'];
  final logDate = state.pathParameters['logDate'];

  debugPrint(
      '🔍 Building review entries: projectId=$projectId, logDate=$logDate');

  if (projectId == null || logDate == null) {
    debugPrint('❌ Missing path parameters for review entries');
    return const RouteErrorWidget(
        message: 'Missing required path parameters for Review');
  }

  debugPrint(
      '✅ Creating ReviewEntriesView with projectId=$projectId, logId=$logDate');

  return ReviewEntriesView(
    projectId: projectId,
    logId: logDate,
  );
}

Widget _buildFinalReadings(BuildContext context, GoRouterState state) {
  try {
    final args = RouteParameterValidator.validateRouteExtra(state.extra);

    final projectId = RouteParameterValidator.extractRequiredStringParam(args, 'projectId');
    final logId = RouteParameterValidator.extractRequiredStringParam(args, 'logId');
    final logType = RouteParameterValidator.extractRequiredStringParam(args, 'logType');

    return FinalReadingsScreen(
      projectId: projectId,
      logId: logId,
      logType: logType,
    );
  } catch (e) {
    debugPrint('❌ Error building Final Readings screen: $e');
    return RouteErrorWidget(
        message: 'Missing required arguments for Final Readings: ${e.toString()}');
  }
}

Widget _buildOcrScan(BuildContext context, GoRouterState state) {
  try {
    final args = RouteParameterValidator.validateRouteExtra(state.extra);

    // Extract optional configuration parameters
    final title = RouteParameterValidator.extractNonNullStringParam(args, 'title', 'Scan Field Log');
    final instructions = RouteParameterValidator.extractNonNullStringParam(args, 'instructions',
        'Take a photo of your paper log or control panel to extract data automatically.');
    final onDataExtracted = RouteParameterValidator.extractFunctionParam<Function(Map<String, dynamic>)>(
        args, 'onDataExtracted');

    return WebOcrScanScreen(
      title: title,
      instructions: instructions,
      onDataExtracted: onDataExtracted,
    );
  } catch (e) {
    debugPrint('❌ Error building OCR scan screen: $e');
    return RouteErrorWidget(message: 'OCR scan error: ${e.toString()}');
  }
}

Widget _buildEnhancedOcrScan(BuildContext context, GoRouterState state) {
  try {
    final args = RouteParameterValidator.validateRouteExtra(state.extra);

    // Extract optional configuration parameters
    final title = RouteParameterValidator.extractNonNullStringParam(args, 'title', 'Enhanced OCR Scan');
    final instructions = RouteParameterValidator.extractNonNullStringParam(args, 'instructions',
        'Take a photo of your thermal log to extract data with anti-hallucination protection.');
    final onDataExtracted = RouteParameterValidator.extractFunctionParam<Function(Map<String, dynamic>)>(
        args, 'onDataExtracted');
    final targetHour = RouteParameterValidator.extractStringParam(args, 'targetHour');

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(
        child: Text('Enhanced OCR Feature Coming Soon'),
      ),
    );
  } catch (e) {
    debugPrint('❌ Error building enhanced OCR scan screen: $e');
    return RouteErrorWidget(
        message: 'Enhanced OCR scan error: ${e.toString()}');
  }
}

// Enhanced error handling widgets
class EnhancedErrorScreen extends StatelessWidget {
  final String error;
  final String path;
  final VoidCallback? onRetry;

  const EnhancedErrorScreen({
    super.key,
    required this.error,
    required this.path,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      appBar: AppBar(
        title: const Text(
          'Navigation Error',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0B132B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Error Details:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.red[300],
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Path: $path',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[400],
                          fontFamily: 'monospace',
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => context.go(RouteNames.projects),
                  icon: const Icon(Icons.home),
                  label: const Text('Go Home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                if (onRetry != null)
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RouteErrorWidget extends StatelessWidget {
  final String message;

  const RouteErrorWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      appBar: AppBar(
        title: const Text('Route Error', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0B132B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(RouteNames.projects),
                child: const Text('Return Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
