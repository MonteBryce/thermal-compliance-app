import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test helpers for Flutter integration tests
class TestHelpers {
  
  /// Wait for a specific widget to appear with retry logic
  static Future<void> waitForWidget(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
    Duration retryInterval = const Duration(milliseconds: 500),
    String? description,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    while (stopwatch.elapsed < timeout) {
      await tester.pumpAndSettle(retryInterval);
      
      if (tester.any(finder)) {
        print('✅ Found widget: ${description ?? finder.toString()}');
        return;
      }
    }
    
    throw TestFailure(
      'Widget not found within timeout: ${description ?? finder.toString()}'
    );
  }
  
  /// Safely tap a widget if it exists
  static Future<bool> safeTap(
    WidgetTester tester,
    Finder finder, {
    Duration settleDuration = const Duration(seconds: 2),
    String? description,
  }) async {
    if (tester.any(finder)) {
      print('📱 Tapping: ${description ?? finder.toString()}');
      await tester.tap(finder.first);
      await tester.pumpAndSettle(settleDuration);
      return true;
    } else {
      print('⚠️ Widget not found for tap: ${description ?? finder.toString()}');
      return false;
    }
  }
  
  /// Enter text in a field if it exists
  static Future<bool> safeEnterText(
    WidgetTester tester,
    Finder finder,
    String text, {
    Duration settleDuration = const Duration(milliseconds: 500),
    String? description,
  }) async {
    if (tester.any(finder)) {
      print('⌨️ Entering text "$text" in: ${description ?? finder.toString()}');
      await tester.enterText(finder.first, text);
      await tester.pumpAndSettle(settleDuration);
      return true;
    } else {
      print('⚠️ Text field not found: ${description ?? finder.toString()}');
      return false;
    }
  }
  
  /// Scroll to find a widget
  static Future<bool> scrollToWidget(
    WidgetTester tester,
    Finder scrollableFinder,
    Finder targetFinder, {
    double delta = 300.0,
    int maxScrolls = 10,
    String? description,
  }) async {
    if (!tester.any(scrollableFinder)) {
      return false;
    }
    
    for (int i = 0; i < maxScrolls; i++) {
      if (tester.any(targetFinder)) {
        print('✅ Found widget after ${i} scrolls: ${description ?? targetFinder.toString()}');
        return true;
      }
      
      await tester.drag(scrollableFinder.first, Offset(0, -delta));
      await tester.pumpAndSettle();
    }
    
    print('⚠️ Widget not found after scrolling: ${description ?? targetFinder.toString()}');
    return false;
  }
  
  /// Check if we're on a specific screen by looking for key indicators
  static bool isOnScreen(WidgetTester tester, List<Finder> indicators) {
    return indicators.any((finder) => tester.any(finder));
  }
  
  /// Wait for loading to complete
  static Future<void> waitForLoadingToComplete(
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 30),
    Duration checkInterval = const Duration(milliseconds: 500),
  }) async {
    final stopwatch = Stopwatch()..start();
    
    while (stopwatch.elapsed < timeout) {
      await tester.pumpAndSettle(checkInterval);
      
      // Check for common loading indicators
      final loadingIndicators = [
        find.byType(CircularProgressIndicator),
        find.byType(LinearProgressIndicator),
        find.textContaining('Loading'),
        find.textContaining('loading'),
      ];
      
      if (!loadingIndicators.any((finder) => tester.any(finder))) {
        print('✅ Loading completed');
        return;
      }
    }
    
    print('⚠️ Loading did not complete within timeout');
  }
  
  /// Print current screen state for debugging
  static void debugCurrentScreen(WidgetTester tester) {
    print('🔍 Current screen state:');
    
    // Common widget types to check
    final widgetChecks = {
      'AppBar': find.byType(AppBar),
      'Scaffold': find.byType(Scaffold),
      'Card': find.byType(Card),
      'ListView': find.byType(ListView),
      'GridView': find.byType(GridView),
      'TextFormField': find.byType(TextFormField),
      'ElevatedButton': find.byType(ElevatedButton),
      'FloatingActionButton': find.byType(FloatingActionButton),
    };
    
    widgetChecks.forEach((name, finder) {
      final count = tester.widgetList(finder).length;
      if (count > 0) {
        print('   $name: $count found');
      }
    });
    
    // Check for specific text patterns
    final textPatterns = [
      'Demo', 'Project', 'Summary', 'Hour', 'Entry', 'Review', 'Metrics', 'System'
    ];
    
    for (final pattern in textPatterns) {
      final finder = find.textContaining(pattern);
      if (tester.any(finder)) {
        print('   Text containing "$pattern": found');
      }
    }
  }
  
  /// Comprehensive screen detection
  static String detectCurrentScreen(WidgetTester tester) {
    final screenIndicators = {
      'ProjectSelector': [
        find.textContaining('DEMO'),
        find.textContaining('Project'),
        find.textContaining('Select'),
      ],
      'DailySummary': [
        find.textContaining('Daily'),
        find.textContaining('Summary'),
        find.byType(CircularProgressIndicator),
      ],
      'HourSelector': [
        find.textContaining('Hour'),
        find.byType(GridView),
        find.textContaining('00').or(find.textContaining('01')),
      ],
      'HourlyEntry': [
        find.byType(TextFormField),
        find.textContaining('Temperature'),
        find.textContaining('Save'),
      ],
      'ReviewEntries': [
        find.textContaining('Review'),
        find.textContaining('Entries'),
        find.byType(DataTable).or(find.byType(ListView)),
      ],
      'SystemMetrics': [
        find.textContaining('System'),
        find.textContaining('Metrics'),
        find.textContaining('Storage'),
      ],
    };
    
    for (final entry in screenIndicators.entries) {
      if (entry.value.any((finder) => tester.any(finder))) {
        return entry.key;
      }
    }
    
    return 'Unknown';
  }
  
  /// Navigate through the app with retry logic
  static Future<bool> navigateWithRetry(
    WidgetTester tester,
    String targetScreen,
    List<NavigationStep> steps, {
    int maxRetries = 3,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      print('🚀 Navigation attempt $attempt to $targetScreen');
      
      try {
        for (final step in steps) {
          await step.execute(tester);
          await tester.pumpAndSettle(const Duration(seconds: 1));
        }
        
        // Check if we reached the target
        final currentScreen = detectCurrentScreen(tester);
        if (currentScreen == targetScreen) {
          print('✅ Successfully navigated to $targetScreen');
          return true;
        } else {
          print('⚠️ Expected $targetScreen, but on $currentScreen');
        }
      } catch (e) {
        print('❌ Navigation attempt $attempt failed: $e');
      }
      
      if (attempt < maxRetries) {
        print('🔄 Retrying navigation...');
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
    }
    
    return false;
  }
}

/// Represents a navigation step
abstract class NavigationStep {
  Future<void> execute(WidgetTester tester);
}

/// Tap a specific widget
class TapStep extends NavigationStep {
  final Finder finder;
  final String? description;
  
  TapStep(this.finder, {this.description});
  
  @override
  Future<void> execute(WidgetTester tester) async {
    await TestHelpers.safeTap(tester, finder, description: description);
  }
}

/// Enter text in a field
class EnterTextStep extends NavigationStep {
  final Finder finder;
  final String text;
  final String? description;
  
  EnterTextStep(this.finder, this.text, {this.description});
  
  @override
  Future<void> execute(WidgetTester tester) async {
    await TestHelpers.safeEnterText(tester, finder, text, description: description);
  }
}

/// Wait for a condition
class WaitStep extends NavigationStep {
  final Finder finder;
  final Duration timeout;
  final String? description;
  
  WaitStep(this.finder, {this.timeout = const Duration(seconds: 5), this.description});
  
  @override
  Future<void> execute(WidgetTester tester) async {
    await TestHelpers.waitForWidget(tester, finder, timeout: timeout, description: description);
  }
}

/// Custom action step
class ActionStep extends NavigationStep {
  final Future<void> Function(WidgetTester tester) action;
  
  ActionStep(this.action);
  
  @override
  Future<void> execute(WidgetTester tester) async {
    await action(tester);
  }
}

/// Predefined navigation paths
class NavigationPaths {
  
  /// Navigate to demo project
  static List<NavigationStep> toDemoProject() => [
    TapStep(
      find.textContaining('DEMO').or(find.byType(Card)),
      description: 'Demo project card'
    ),
  ];
  
  /// Navigate to daily summary
  static List<NavigationStep> toDailySummary() => [
    ...toDemoProject(),
    TapStep(
      find.textContaining('Summary').or(find.textContaining('Daily')),
      description: 'Daily summary option'
    ),
  ];
  
  /// Navigate to hourly entry
  static List<NavigationStep> toHourlyEntry() => [
    ...toDailySummary(),
    TapStep(
      find.textContaining('Hour').or(find.byType(GridView)),
      description: 'Hour selector'
    ),
    TapStep(
      find.textContaining('00').or(find.textContaining('12')),
      description: 'Specific hour'
    ),
  ];
  
  /// Navigate to review entries
  static List<NavigationStep> toReviewEntries() => [
    ...toHourlyEntry(),
    TapStep(
      find.textContaining('Review'),
      description: 'Review button'
    ),
  ];
  
  /// Navigate to system metrics
  static List<NavigationStep> toSystemMetrics() => [
    TapStep(
      find.textContaining('Metrics').or(find.byIcon(Icons.settings)),
      description: 'System metrics option'
    ),
  ];
}

/// Test data helpers
class TestData {
  static const Map<String, String> sampleThermalData = {
    'inletTemperature': '1200',
    'outletTemperature': '1250',
    'flowRate': '150',
    'pressure': '12.5',
  };
  
  static const List<String> demoProjectIds = [
    'DEMO-2025-001',
    'DEMO-001',
    'demo',
  ];
  
  static const Map<String, String> testCredentials = {
    'operatorId': 'TEST_OP_001',
    'operatorName': 'Test Operator',
  };
}

/// Widget finder extensions
extension FinderExtensions on Finder {
  /// Combine this finder with another using OR logic
  Finder or(Finder other) {
    return find.byWidgetPredicate((widget) {
      try {
        return evaluate().isNotEmpty;
      } catch (e) {
        try {
          return other.evaluate().isNotEmpty;
        } catch (e2) {
          return false;
        }
      }
    });
  }
  
  /// Check if this finder has any matches
  bool hasMatches(WidgetTester tester) {
    return tester.any(this);
  }
}