# Enhanced Navigation System

This directory contains a comprehensive navigation system built on top of go_router with enhanced features for better UX and developer experience.

## Overview

The navigation system provides:
- **Type-safe routing** with centralized route definitions
- **Navigation guards** and middleware for validation
- **Custom transitions** for different route types
- **Navigation context** with breadcrumbs and state management
- **Enhanced error handling** with user-friendly error screens
- **Offline support** indicators and handling

## Architecture

### Core Files

1. **`route_names.dart`** - Centralized route definitions and path builders
2. **`route_extensions.dart`** - Extension methods for type-safe navigation
3. **`navigation_guards.dart`** - Route protection and validation middleware
4. **`route_transitions.dart`** - Custom page transitions and loading states
5. **`app_router.dart`** - Main router configuration with nested routes

### Supporting Files

- **`navigation_context_widget.dart`** - Navigation UI components (breadcrumbs, contextual app bar)

## Usage Examples

### Basic Navigation

```dart
// Type-safe navigation with extensions
context.goToProjectSummary('project-123');
context.goToHourlyEntry('project-123', '2024-01-15', 14);

// Safe navigation with error handling
final result = await context.safeNavigate(
  'hourlyEntry',
  pathParameters: {'projectId': 'abc', 'logDate': '2024-01-15', 'hour': '14'},
  extra: {'existingData': thermalReading},
);
```

### Route Path Building

```dart
// Build paths with validation
final path = RouteNames.buildHourlyEntryPath('project-123', '2024-01-15', 14);
// Throws ArgumentError if parameters are invalid

// Get breadcrumbs for current route
final breadcrumbs = RouteNames.getBreadcrumbs(currentRoute);
// Returns: {'Projects': '/projects', 'Project ABC': '/projects/ABC/summary', ...}
```

### Navigation Context

```dart
// Use contextual app bar with breadcrumbs
return Scaffold(
  appBar: ContextualAppBar(
    title: 'Hourly Entry',
    showBreadcrumbs: true,
    backgroundColor: Colors.blue[800],
  ),
  body: NavigationContextWidget(
    showBreadcrumbs: true,
    child: YourContent(),
  ),
);
```

### Custom Transitions

The system automatically applies appropriate transitions based on route type:
- **Entry forms**: Slide up transition (modal-like)
- **System metrics**: Scale transition (emphasis)
- **Review screens**: Fade transition (smooth)
- **Project summary**: Rotation transition (special)
- **Default**: Slide transition (standard)

## Route Structure

```
/ (home)
├── /projects (project selector)
│   └── /:projectId
│       ├── /summary (project summary)
│       └── /logs/:logDate
│           ├── /daily-summary
│           ├── /hours (hour selector)
│           ├── /entry/:hour (hourly entry form)
│           └── /review (review entries)
├── /systemMetrics (standalone)
└── /finalReadings (standalone)
```

## Navigation Guards

The system includes comprehensive validation:

### Authentication
- Routes requiring authentication are protected
- Redirects to login if needed

### Parameter Validation
- Project ID format validation
- Log date format validation (YYYY-MM-DD)
- Hour parameter validation (0-23)

### Complex Object Handling
- Graceful handling of missing `extra` parameters
- Fallback routes for invalid navigation states
- Browser back button support

### Error Handling
- User-friendly error screens with retry options
- Automatic fallback to safe routes
- Debug information for developers

## Error Handling

### Enhanced Error Screen
```dart
EnhancedErrorScreen(
  error: 'Navigation failed',
  path: '/projects/invalid/summary',
  onRetry: () => context.go('/projects'),
)
```

### Route Error Widget
```dart
RouteErrorWidget(
  message: 'Missing required parameters',
)
```

## Best Practices

### 1. Use Type-Safe Navigation
```dart
// ✅ Good - type-safe with validation
context.goToHourlyEntry(projectId, logDate, hour);

// ❌ Avoid - manual route building
context.go('/projects/$projectId/logs/$logDate/entry/$hour');
```

### 2. Handle Navigation Errors
```dart
// ✅ Good - with error handling
final result = await context.safeNavigate('routeName');
if (result == null) {
  // Handle navigation failure
}

// ❌ Avoid - no error handling
context.pushNamed('routeName');
```

### 3. Use Route Constants
```dart
// ✅ Good - centralized constants
context.pushNamed(RouteNames.hourlyEntryName);

// ❌ Avoid - magic strings
context.pushNamed('hourlyEntry');
```

### 4. Validate Parameters
```dart
// ✅ Good - use built-in validation
try {
  final path = RouteNames.buildHourlyEntryPath(projectId, logDate, hour);
  context.go(path);
} catch (e) {
  // Handle invalid parameters
}
```

## Migration Guide

### From Basic go_router

1. **Replace route strings with constants**:
   ```dart
   // Old
   context.pushNamed('hourlyEntry');
   
   // New
   context.pushNamed(RouteNames.hourlyEntryName);
   ```

2. **Use navigation extensions**:
   ```dart
   // Old
   context.pushNamed('hourlyEntry', pathParameters: {...});
   
   // New
   context.goToHourlyEntry(projectId, logDate, hour);
   ```

3. **Add error handling**:
   ```dart
   // Old
   context.pushNamed('routeName');
   
   // New
   final result = await context.safeNavigate('routeName');
   ```

4. **Update AppBar to ContextualAppBar**:
   ```dart
   // Old
   AppBar(title: Text('Title'))
   
   // New
   ContextualAppBar(
     title: 'Title',
     showBreadcrumbs: true,
   )
   ```

## Performance Considerations

- **Route caching**: Routes are defined once and reused
- **Lazy loading**: Screens are built only when needed
- **Transition optimization**: Transitions are optimized for 60fps
- **Memory management**: Proper disposal of navigation state

## Testing

### Unit Tests
```dart
testWidgets('should navigate to hourly entry', (tester) async {
  final context = tester.element(find.byType(MaterialApp));
  context.goToHourlyEntry('project-123', '2024-01-15', 14);
  
  await tester.pumpAndSettle();
  expect(find.byType(HourlyEntryScreen), findsOneWidget);
});
```

### Integration Tests
```dart
testWidgets('should handle invalid navigation gracefully', (tester) async {
  // Test navigation guards and error handling
});
```

## Future Enhancements

- [ ] Deep link handling
- [ ] Navigation analytics
- [ ] Route preloading
- [ ] Advanced transition effects
- [ ] Navigation state persistence
- [ ] A/B testing support

## Troubleshooting

### Common Issues

1. **Missing route parameters**
   - Check parameter validation in navigation guards
   - Use route builders with proper error handling

2. **Navigation not working**
   - Verify route names match constants
   - Check for typos in path parameters

3. **Transitions not smooth**
   - Ensure 60fps performance
   - Check transition duration settings

4. **Breadcrumbs not showing**
   - Verify ContextualAppBar usage
   - Check route structure for proper nesting

For more specific issues, check the debug console for navigation logs and error messages.