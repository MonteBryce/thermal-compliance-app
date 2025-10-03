import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'route_names.dart';

/// Navigation guards and middleware for route protection and validation
class NavigationGuards {
  
  /// Central redirect handler for all navigation guards
  static String? handleRedirect(BuildContext context, GoRouterState state) {
    // Check for authentication requirements
    final authRedirect = _checkAuthRequirement(context, state);
    if (authRedirect != null) return authRedirect;
    
    // Handle complex object requirements
    final objectRedirect = _handleComplexObjectRoutes(context, state);
    if (objectRedirect != null) return objectRedirect;
    
    // Validate route parameters
    final paramRedirect = _validateRouteParameters(context, state);
    if (paramRedirect != null) return paramRedirect;
    
    // Handle browser back button edge cases
    final backButtonRedirect = _handleBrowserBackButton(context, state);
    if (backButtonRedirect != null) return backButtonRedirect;
    
    return null; // No redirect needed
  }
  
  /// Check if route requires authentication
  static String? _checkAuthRequirement(BuildContext context, GoRouterState state) {
    // List of routes that require authentication
    final protectedRoutes = [
      '/projects',
      '/systemMetrics',
      '/finalReadings',
    ];
    
    final requiresAuth = protectedRoutes.any((route) => 
      state.matchedLocation.startsWith(route)
    );
    
    if (requiresAuth) {
      // TODO: Implement actual authentication check
      // For now, we assume user is authenticated
      // if (!AuthService.isAuthenticated) {
      //   return RouteNames.home;
      // }
    }
    
    return null;
  }
  
  /// Handle routes that require complex objects in extra parameter
  static String? _handleComplexObjectRoutes(BuildContext context, GoRouterState state) {
    final location = state.matchedLocation;
    
    // Project summary and nested routes work better with JobData object
    if (location.contains('/projects/') && location.contains('/summary') && state.extra == null) {
      debugPrint('⚠️ Project summary accessed without JobData object - this is OK but some features may be limited');
      // Allow navigation - the screen can handle null JobData by using projectId
      return null;
    }
    
    // For nested routes under a project, we don't require JobData as they work with projectId
    if (location.contains('/projects/') && (location.contains('/logs/') || location.contains('/entry/') || location.contains('/review'))) {
      // These routes work fine with just path parameters
      return null;
    }
    
    // Daily summary requires selectedDate
    if (location.contains('/daily-summary') && state.extra == null) {
      debugPrint('⚠️ Daily summary accessed without selectedDate');
      // Redirect to hour selector as fallback
      final pathSegments = location.split('/');
      if (pathSegments.length >= 5) {
        final projectId = pathSegments[2];
        final logDate = pathSegments[4];
        return RouteNames.buildHourSelectorPath(projectId, logDate);
      }
    }
    
    // Final readings requires specific arguments
    if (location.contains('/finalReadings') && state.extra == null) {
      debugPrint('⚠️ Final readings accessed without required arguments');
      return RouteNames.projects;
    }
    
    return null;
  }
  
  /// Validate route parameters for correct format and values
  static String? _validateRouteParameters(BuildContext context, GoRouterState state) {
    final pathParams = state.pathParameters;
    
    // Validate project ID format
    final projectId = pathParams[RouteNames.projectIdParam];
    if (projectId != null && !_isValidProjectId(projectId)) {
      debugPrint('⚠️ Invalid project ID format: $projectId');
      return RouteNames.projects;
    }
    
    // Validate log date format
    final logDate = pathParams[RouteNames.logDateParam];
    if (logDate != null && !_isValidLogDate(logDate)) {
      debugPrint('⚠️ Invalid log date format: $logDate');
      if (projectId != null) {
        return RouteNames.buildProjectSummaryPath(projectId);
      }
      return RouteNames.projects;
    }
    
    // Validate hour parameter
    final hourStr = pathParams[RouteNames.hourParam];
    if (hourStr != null) {
      final hour = int.tryParse(hourStr);
      if (hour == null || hour < 0 || hour > 23) {
        debugPrint('⚠️ Invalid hour parameter: $hourStr');
        if (projectId != null && logDate != null) {
          return RouteNames.buildHourSelectorPath(projectId, logDate);
        }
        return RouteNames.projects;
      }
    }
    
    return null;
  }
  
  /// Handle browser back button edge cases
  static String? _handleBrowserBackButton(BuildContext context, GoRouterState state) {
    // For entry routes, allow path-only navigation since we have parameters
    if (state.matchedLocation.contains('/entry/') && state.extra == null) {
      // This is fine - the route builder can handle missing extra data
      return null;
    }
    
    // For review routes, allow path-only navigation
    if (state.matchedLocation.contains('/review') && state.extra == null) {
      // This is fine - the route builder can handle missing extra data
      return null;
    }
    
    return null;
  }
  
  /// Validate project ID format (customize based on your requirements)
  static bool _isValidProjectId(String projectId) {
    // Example: Project IDs should be alphanumeric and not empty
    if (projectId.isEmpty) return false;
    
    // Add more specific validation rules as needed
    // For example: specific length, format, etc.
    return RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(projectId);
  }
  
  /// Validate log date format (expecting YYYY-MM-DD format)
  static bool _isValidLogDate(String logDate) {
    try {
      // Try to parse as DateTime to validate format
      final date = DateTime.parse(logDate);
      
      // Additional validation: ensure it's not too far in the future
      final now = DateTime.now();
      final maxFutureDate = now.add(const Duration(days: 365));
      
      return date.isBefore(maxFutureDate) && date.isAfter(DateTime(2020));
    } catch (e) {
      return false;
    }
  }
  
  /// Check if user has permission to access specific project
  static bool hasProjectAccess(String projectId) {
    // TODO: Implement actual permission checking
    // For now, assume all authenticated users have access
    return true;
  }
  
  /// Log navigation events for analytics
  static void logNavigation(String from, String to) {
    debugPrint('🧭 Navigation: $from → $to');
    // TODO: Send to analytics service
  }
}

/// Middleware for handling navigation state
class NavigationMiddleware {
  
  /// Pre-navigation hook
  static Future<bool> beforeNavigation(BuildContext context, String route) async {
    // Check network connectivity for data-dependent routes
    if (_isDataDependentRoute(route)) {
      // TODO: Check connectivity and show offline warning if needed
    }
    
    // Check for unsaved changes
    if (_hasUnsavedChanges(context)) {
      final shouldContinue = await _showUnsavedChangesDialog(context);
      return shouldContinue;
    }
    
    return true; // Allow navigation
  }
  
  /// Post-navigation hook
  static void afterNavigation(BuildContext context, String route) {
    // Clear temporary state
    _clearTemporaryState(context);
    
    // Update navigation history
    _updateNavigationHistory(route);
    
    // Log navigation event
    NavigationGuards.logNavigation('previous', route);
  }
  
  static bool _isDataDependentRoute(String route) {
    return route.contains('/entry/') || 
           route.contains('/review') || 
           route.contains('/summary');
  }
  
  static bool _hasUnsavedChanges(BuildContext context) {
    // TODO: Check for unsaved form data or pending operations
    return false;
  }
  
  static Future<bool> _showUnsavedChangesDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Are you sure you want to leave?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    ) ?? false;
  }
  
  static void _clearTemporaryState(BuildContext context) {
    // Clear any temporary UI state
  }
  
  static void _updateNavigationHistory(String route) {
    // Update navigation history for analytics
  }
}