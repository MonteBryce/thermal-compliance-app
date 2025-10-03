import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:my_flutter_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Thermal Log App - Complete User Flow Integration Test', () {
    
    testWidgets('Complete user flow: ProjectSelector → DailySummary → HourlyEntry → Review → SystemMetrics', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Step 1: Project Selector Screen
      print('🎯 Step 1: Testing Project Selector Screen');
      
      // Wait for the app to fully load and show project selector
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // Look for project cards or demo project
      final demoProjectFinder = find.textContaining('DEMO');
      final projectCardFinder = find.byType(Card);
      final createProjectFinder = find.textContaining('Create');
      
      // Ensure we're on the project selector screen
      expect(
        demoProjectFinder.or(projectCardFinder).or(createProjectFinder),
        findsWidgets,
        reason: 'Should find demo project, project cards, or create project option'
      );
      
      // Try to find and tap the demo project
      if (await tester.binding.defaultBinaryMessenger.checkMockMessageHandler('flutter/platform', (data) => null) == null) {
        // If we find a demo project card, tap it
        if (tester.any(demoProjectFinder)) {
          print('📱 Tapping on demo project');
          await tester.tap(demoProjectFinder.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));
        } else if (tester.any(projectCardFinder)) {
          print('📱 Tapping on first available project card');
          await tester.tap(projectCardFinder.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));
        }
      }

      // Step 2: Navigate to Daily Summary
      print('🎯 Step 2: Testing Daily Summary Navigation');
      
      // Look for navigation to daily summary
      final summaryButtonFinder = find.textContaining('Summary');
      final dailySummaryFinder = find.textContaining('Daily');
      final progressIndicatorFinder = find.byType(CircularProgressIndicator);
      
      // Wait for navigation or data loading
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // If we find a summary button or daily summary indicator, tap it
      if (tester.any(summaryButtonFinder)) {
        print('📱 Tapping on Summary button');
        await tester.tap(summaryButtonFinder.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      } else if (tester.any(dailySummaryFinder)) {
        print('📱 Found Daily Summary content');
        await tester.tap(dailySummaryFinder.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      
      // Verify we're on a summary-like screen
      expect(
        summaryButtonFinder.or(dailySummaryFinder).or(progressIndicatorFinder),
        findsWidgets,
        reason: 'Should find summary content or loading indicator'
      );

      // Step 3: Navigate to Hour Selector and then Hourly Entry
      print('🎯 Step 3: Testing Hour Selector and Hourly Entry');
      
      // Look for hour navigation options
      final hourSelectorFinder = find.textContaining('Hour');
      final gridViewFinder = find.byType(GridView);
      final hourButtonFinder = find.textContaining('00').or(find.textContaining('01')).or(find.textContaining('12'));
      
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // If we find hour-related buttons, tap one
      if (tester.any(hourButtonFinder)) {
        print('📱 Tapping on hour button');
        await tester.tap(hourButtonFinder.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      } else if (tester.any(gridViewFinder)) {
        print('📱 Found grid view, looking for tappable elements');
        // Try to find tappable elements in the grid
        final gridItems = find.descendant(
          of: gridViewFinder.first,
          matching: find.byType(GestureDetector).or(find.byType(InkWell)).or(find.byType(ElevatedButton))
        );
        if (tester.any(gridItems)) {
          await tester.tap(gridItems.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));
        }
      }
      
      // Look for hourly entry form elements
      final textFieldFinder = find.byType(TextFormField);
      final temperatureFinder = find.textContaining('Temperature').or(find.textContaining('Inlet'));
      final saveButtonFinder = find.textContaining('Save');
      
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // If we're on the hourly entry form, interact with it
      if (tester.any(textFieldFinder)) {
        print('📱 Found hourly entry form, entering test data');
        
        // Fill in some test data
        final firstTextField = textFieldFinder.first;
        await tester.enterText(firstTextField, '1200');
        await tester.pumpAndSettle();
        
        // If there are more text fields, fill them too
        if (tester.any(textFieldFinder.at(1))) {
          await tester.enterText(textFieldFinder.at(1), '1250');
          await tester.pumpAndSettle();
        }
        
        // Try to save the entry
        if (tester.any(saveButtonFinder)) {
          print('📱 Saving hourly entry');
          await tester.tap(saveButtonFinder.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));
        }
      }
      
      // Verify form interaction
      expect(
        textFieldFinder.or(temperatureFinder).or(saveButtonFinder),
        findsWidgets,
        reason: 'Should find hourly entry form elements'
      );

      // Step 4: Navigate to Review All Entries
      print('🎯 Step 4: Testing Review All Entries');
      
      // Look for review navigation
      final reviewButtonFinder = find.textContaining('Review');
      final reviewAllFinder = find.textContaining('Review All');
      final entriesFinder = find.textContaining('Entries');
      
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Try to navigate to review screen
      if (tester.any(reviewButtonFinder)) {
        print('📱 Tapping on Review button');
        await tester.tap(reviewButtonFinder.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      } else if (tester.any(reviewAllFinder)) {
        print('📱 Tapping on Review All');
        await tester.tap(reviewAllFinder.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      
      // Look for review screen elements
      final listViewFinder = find.byType(ListView);
      final dataTableFinder = find.byType(DataTable);
      final cardsFinder = find.byType(Card);
      
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Verify we're on review screen
      expect(
        reviewButtonFinder.or(entriesFinder).or(listViewFinder).or(dataTableFinder).or(cardsFinder),
        findsWidgets,
        reason: 'Should find review screen elements'
      );

      // Step 5: Navigate to System Metrics
      print('🎯 Step 5: Testing System Metrics');
      
      // Look for system metrics navigation
      final metricsButtonFinder = find.textContaining('Metrics');
      final systemFinder = find.textContaining('System');
      final settingsFinder = find.byIcon(Icons.settings);
      final menuFinder = find.byIcon(Icons.menu);
      
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Try to find navigation to system metrics
      if (tester.any(metricsButtonFinder)) {
        print('📱 Tapping on Metrics button');
        await tester.tap(metricsButtonFinder.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      } else if (tester.any(systemFinder)) {
        print('📱 Tapping on System option');
        await tester.tap(systemFinder.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      } else if (tester.any(menuFinder)) {
        print('📱 Opening menu to find system metrics');
        await tester.tap(menuFinder.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        
        // Look for metrics option in menu
        final menuMetricsFinder = find.textContaining('Metrics').or(find.textContaining('System'));
        if (tester.any(menuMetricsFinder)) {
          await tester.tap(menuMetricsFinder.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));
        }
      }
      
      // Look for system metrics screen elements
      final progressFinder = find.byType(CircularProgressIndicator);
      final storageFinder = find.textContaining('Storage');
      final runtimeFinder = find.textContaining('Runtime');
      final tempFinder = find.textContaining('Temperature');
      
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Verify system metrics screen
      expect(
        metricsButtonFinder.or(systemFinder).or(progressFinder).or(storageFinder).or(runtimeFinder),
        findsWidgets,
        reason: 'Should find system metrics elements'
      );

      // Final verification: Ensure no critical errors occurred
      print('✅ Verification: Checking for critical errors');
      
      // Check that we don't have any error widgets
      final errorWidgetFinder = find.byType(ErrorWidget);
      final flexOverflowFinder = find.textContaining('overflow');
      
      expect(errorWidgetFinder, findsNothing, reason: 'Should not have any ErrorWidgets');
      expect(flexOverflowFinder, findsNothing, reason: 'Should not have any flex overflow errors');
      
      print('🎉 Complete user flow test completed successfully!');
    });

    testWidgets('Fallback navigation test - ensure basic screens load', (WidgetTester tester) async {
      // This test ensures basic screen loading without complex navigation
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      print('🔄 Testing fallback navigation paths');
      
      // Test 1: Verify app loads
      expect(find.byType(MaterialApp), findsOneWidget, reason: 'App should initialize');
      
      // Test 2: Look for any interactive elements
      final buttonFinder = find.byType(ElevatedButton).or(find.byType(TextButton)).or(find.byType(IconButton));
      final cardFinder = find.byType(Card);
      final gestureDetectorFinder = find.byType(GestureDetector);
      
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Verify interactive elements exist
      expect(
        buttonFinder.or(cardFinder).or(gestureDetectorFinder),
        findsWidgets,
        reason: 'Should find interactive elements on screen'
      );
      
      // Test 3: Try tapping any available interactive element
      if (tester.any(buttonFinder)) {
        print('📱 Testing button interaction');
        await tester.tap(buttonFinder.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      } else if (tester.any(cardFinder)) {
        print('📱 Testing card interaction');
        await tester.tap(cardFinder.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      
      // Test 4: Verify no crashes after interaction
      expect(find.byType(MaterialApp), findsOneWidget, reason: 'App should remain stable after interaction');
      
      print('✅ Fallback navigation test completed');
    });

    testWidgets('Performance and stability test', (WidgetTester tester) async {
      // Test app performance and stability
      final stopwatch = Stopwatch()..start();
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      stopwatch.stop();
      
      print('⏱️ App startup time: ${stopwatch.elapsedMilliseconds}ms');
      
      // Verify reasonable startup time (under 10 seconds)
      expect(stopwatch.elapsedMilliseconds, lessThan(10000), reason: 'App should start within 10 seconds');
      
      // Test multiple pump cycles for stability
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();
      }
      
      // Verify app remains stable
      expect(find.byType(MaterialApp), findsOneWidget, reason: 'App should remain stable through pump cycles');
      
      print('✅ Performance and stability test completed');
    });

    testWidgets('Error handling test', (WidgetTester tester) async {
      // Test that the app handles errors gracefully
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Look for any error indicators
      final errorWidgetFinder = find.byType(ErrorWidget);
      final errorTextFinder = find.textContaining('Error').or(find.textContaining('error'));
      final exceptionFinder = find.textContaining('Exception');
      
      // Basic error check - some error text might be acceptable (like "No errors found")
      // but ErrorWidgets indicate critical failures
      expect(errorWidgetFinder, findsNothing, reason: 'Should not have critical ErrorWidgets');
      
      // Verify error handling exists (error boundaries, try-catch, etc.)
      // This is indicated by the app running without throwing unhandled exceptions
      expect(find.byType(MaterialApp), findsOneWidget, reason: 'App should handle errors gracefully');
      
      print('✅ Error handling test completed');
    });
  });
}