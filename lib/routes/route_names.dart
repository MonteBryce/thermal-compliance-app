/// Centralized route names and paths for type-safe navigation
///
/// This class provides a single source of truth for all route definitions,
/// making it easier to maintain and refactor navigation throughout the app.
class RouteNames {
  // Private constructor to prevent instantiation
  RouteNames._();

  // Root routes
  static const String home = '/';
  static const String homeName = 'home';

  // Project routes
  static const String projects = '/projects';
  static const String projectsName = 'projects';

  // Project-specific routes
  static const String projectSummary = 'summary';
  static const String projectSummaryName = 'projectSummary';

  // Log-based routes
  static const String dailySummary = 'daily-summary';
  static const String dailySummaryName = 'dailySummary';

  static const String hourSelector = 'hours';
  static const String hourSelectorName = 'hourSelector';

  static const String hourlyEntry = 'entry/:hour';
  static const String hourlyEntryName = 'hourlyEntry';

  // Thermal log routes
  static const String thermalLogs = 'thermal-logs';
  static const String thermalLogsName = 'thermalLogs';

  static const String thermalLogEntry = 'thermal-entry';
  static const String thermalLogEntryName = 'thermalLogEntry';

  static const String reviewAll = 'review';
  static const String reviewAllName = 'reviewAll';

  // Standalone routes
  static const String systemMetrics = '/systemMetrics';
  static const String systemMetricsName = 'systemMetrics';

  static const String finalReadings = '/finalReadings';
  static const String finalReadingsName = 'finalReadings';

  // OCR Demo route
  static const String ocrDemo = '/ocr-demo';
  static const String ocrDemoName = 'ocrDemo';

  // Route path builders with parameter validation
  static String buildProjectSummaryPath(String projectId) {
    if (projectId.isEmpty) throw ArgumentError('projectId cannot be empty');
    return '/projects/$projectId/summary';
  }

  static String buildDailySummaryPath(String projectId, String logDate) {
    if (projectId.isEmpty) throw ArgumentError('projectId cannot be empty');
    if (logDate.isEmpty) throw ArgumentError('logDate cannot be empty');
    return '/projects/$projectId/logs/$logDate/daily-summary';
  }

  static String buildHourSelectorPath(String projectId, String logDate) {
    if (projectId.isEmpty) throw ArgumentError('projectId cannot be empty');
    if (logDate.isEmpty) throw ArgumentError('logDate cannot be empty');
    return '/projects/$projectId/logs/$logDate/hours';
  }

  static String buildHourlyEntryPath(
      String projectId, String logDate, int hour) {
    if (projectId.isEmpty) throw ArgumentError('projectId cannot be empty');
    if (logDate.isEmpty) throw ArgumentError('logDate cannot be empty');
    if (hour < 0 || hour > 23) {
      throw ArgumentError('hour must be between 0 and 23');
    }
    return '/projects/$projectId/logs/$logDate/entry/$hour';
  }

  static String buildReviewAllPath(String projectId, String logDate) {
    if (projectId.isEmpty) throw ArgumentError('projectId cannot be empty');
    if (logDate.isEmpty) throw ArgumentError('logDate cannot be empty');
    return '/projects/$projectId/logs/$logDate/review';
  }

  // Parameter name constants
  static const String projectIdParam = 'projectId';
  static const String logDateParam = 'logDate';
  static const String hourParam = 'hour';

  // Navigation breadcrumb helpers
  static Map<String, String> getBreadcrumbs(String currentRoute) {
    final breadcrumbs = <String, String>{};

    if (currentRoute.startsWith('/projects')) {
      breadcrumbs['Projects'] = projects;

      final segments = currentRoute.split('/');
      if (segments.length > 2) {
        final projectId = segments[2];
        breadcrumbs['Project $projectId'] = buildProjectSummaryPath(projectId);

        if (segments.length > 4) {
          final logDate = segments[4];
          breadcrumbs['Log $logDate'] =
              buildHourSelectorPath(projectId, logDate);

          if (segments.length > 5) {
            final action = segments[5];
            switch (action) {
              case 'hours':
                breadcrumbs['Hour Selection'] = currentRoute;
                break;
              case 'entry':
                if (segments.length > 6) {
                  breadcrumbs['Hour ${segments[6]}'] = currentRoute;
                }
                break;
              case 'review':
                breadcrumbs['Review'] = currentRoute;
                break;
              case 'daily-summary':
                breadcrumbs['Daily Summary'] = currentRoute;
                break;
            }
          }
        }
      }
    }

    return breadcrumbs;
  }
}
