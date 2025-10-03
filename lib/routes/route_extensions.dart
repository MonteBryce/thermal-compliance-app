import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'route_names.dart';

/// Extension methods for enhanced navigation with type safety and convenience
extension AppRouterExtensions on BuildContext {
  
  // Project navigation methods
  void goToProjects() {
    go(RouteNames.projects);
  }
  
  Future<T?> goToProjectSummary<T extends Object?>(String projectId, {Object? extra}) {
    return pushNamed<T>(
      RouteNames.projectSummaryName,
      pathParameters: {RouteNames.projectIdParam: projectId},
      extra: extra,
    );
  }
  
  Future<T?> goToDailySummary<T extends Object?>(String projectId, String logDate, {Object? extra}) {
    return pushNamed<T>(
      RouteNames.dailySummaryName,
      pathParameters: {
        RouteNames.projectIdParam: projectId,
        RouteNames.logDateParam: logDate,
      },
      extra: extra,
    );
  }
  
  Future<T?> goToHourSelector<T extends Object?>(String projectId, String logDate, {Object? extra}) {
    return pushNamed<T>(
      RouteNames.hourSelectorName,
      pathParameters: {
        RouteNames.projectIdParam: projectId,
        RouteNames.logDateParam: logDate,
      },
      extra: extra,
    );
  }
  
  Future<T?> goToHourlyEntry<T extends Object?>(String projectId, String logDate, int hour, {Object? extra}) {
    return pushNamed<T>(
      RouteNames.hourlyEntryName,
      pathParameters: {
        RouteNames.projectIdParam: projectId,
        RouteNames.logDateParam: logDate,
        RouteNames.hourParam: hour.toString(),
      },
      extra: extra,
    );
  }
  
  Future<T?> goToReviewAll<T extends Object?>(String projectId, String logDate, {Object? extra}) {
    return pushNamed<T>(
      RouteNames.reviewAllName,
      pathParameters: {
        RouteNames.projectIdParam: projectId,
        RouteNames.logDateParam: logDate,
      },
      extra: extra,
    );
  }
  
  Future<T?> goToSystemMetrics<T extends Object?>({Object? extra}) {
    return pushNamed<T>(RouteNames.systemMetricsName, extra: extra);
  }
  
  Future<T?> goToFinalReadings<T extends Object?>({required Object extra}) {
    return pushNamed<T>(RouteNames.finalReadingsName, extra: extra);
  }
  
  /// Navigate to OCR scan screen with optional configuration
  Future<Map<String, dynamic>?> goToOcrScan({
    String? title,
    String? instructions,
    Function(Map<String, dynamic>)? onDataExtracted,
  }) {
    return pushNamed<Map<String, dynamic>>(
      'ocrScan',
      extra: {
        if (title != null) 'title': title,
        if (instructions != null) 'instructions': instructions,
        if (onDataExtracted != null) 'onDataExtracted': onDataExtracted,
      },
    );
  }
  
  // Safe navigation with error handling
  Future<T?> safeNavigate<T extends Object?>(
    String routeName, {
    Map<String, String>? pathParameters,
    Object? extra,
  }) async {
    try {
      return await pushNamed<T>(
        routeName,
        pathParameters: pathParameters ?? {},
        extra: extra,
      );
    } catch (e) {
      debugPrint('Navigation error to $routeName: $e');
      // Show error snackbar or handle gracefully
      ScaffoldMessenger.of(this).showSnackBar(
        SnackBar(
          content: Text('Navigation failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }
  
  // Breadcrumb navigation
  Map<String, String> getCurrentBreadcrumbs() {
    final location = GoRouterState.of(this).matchedLocation;
    return RouteNames.getBreadcrumbs(location);
  }
  
  // Route validation helpers
  bool isValidProjectRoute() {
    final location = GoRouterState.of(this).matchedLocation;
    return location.startsWith('/projects/') && location.split('/').length >= 3;
  }
  
  bool isValidLogRoute() {
    final location = GoRouterState.of(this).matchedLocation;
    return location.contains('/logs/') && location.split('/').length >= 5;
  }
  
  // Parameter extraction helpers
  String? getCurrentProjectId() {
    return GoRouterState.of(this).pathParameters[RouteNames.projectIdParam];
  }
  
  String? getCurrentLogDate() {
    return GoRouterState.of(this).pathParameters[RouteNames.logDateParam];
  }
  
  int? getCurrentHour() {
    final hourStr = GoRouterState.of(this).pathParameters[RouteNames.hourParam];
    return hourStr != null ? int.tryParse(hourStr) : null;
  }
}

/// Extension for GoRouter to add custom navigation methods
extension GoRouterExtensions on GoRouter {
  
  // Batch navigation operations
  void navigateToProjectWorkflow(String projectId, String logDate) {
    go(RouteNames.buildHourSelectorPath(projectId, logDate));
  }
  
  // Deep link handling
  void handleDeepLink(String deepLink) {
    try {
      // Parse and validate deep link
      final uri = Uri.parse(deepLink);
      if (uri.pathSegments.isNotEmpty) {
        go(uri.path);
      }
    } catch (e) {
      debugPrint('Invalid deep link: $deepLink');
      go(RouteNames.projects);
    }
  }
  
  // Navigation stack utilities
  bool canNavigateBack() {
    return routerDelegate.currentConfiguration.matches.length > 1;
  }
}