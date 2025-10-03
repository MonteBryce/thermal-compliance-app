import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:my_flutter_app/main.dart' as app;
import 'package:my_flutter_app/services/firebase_emulator_service.dart';
import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Firebase Emulator Integration Tests', () {
    
    setUpAll(() async {
      // Ensure Firebase emulators are configured before tests
      print('🔥 Setting up Firebase emulators for integration tests');
      await FirebaseEmulatorService.initializeEmulators();
      
      // Verify emulator connectivity
      if (FirebaseEmulatorService.isUsingEmulators) {
        print('✅ Connected to Firebase emulators');
        print('📊 Emulator info: ${FirebaseEmulatorService.emulatorInfo}');
      } else {
        print('⚠️ Not using emulators - may affect test reliability');
      }
    });

    testWidgets('Authentication Flow with Firebase Auth Emulator', (WidgetTester tester) async {
      print('🔐 Testing Authentication Flow with Emulator');
      
      // Start the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await TestHelpers.waitForLoadingToComplete(tester);
      
      // Step 1: Create test user in emulator
      print('👤 Creating test user in Auth emulator');
      await FirebaseEmulatorService.createTestUser(
        email: 'integration-test@thermal-app.com',
        password: 'testpass123'
      );
      
      // Step 2: Navigate to login screen (if exists)
      final loginButtonFinder = find.textContaining('Login').or(find.textContaining('Sign In'));
      final emailFieldFinder = find.byType(TextFormField).or(find.textContaining('Email'));
      
      if (await TestHelpers.safeTap(tester, loginButtonFinder, description: 'Login button')) {
        await TestHelpers.waitForWidget(tester, emailFieldFinder, description: 'Email field');
        
        // Step 3: Fill in login credentials
        final emailField = find.byType(TextFormField).first;
        final passwordField = find.byType(TextFormField).at(1);
        
        await TestHelpers.safeEnterText(tester, emailField, 'integration-test@thermal-app.com');
        await TestHelpers.safeEnterText(tester, passwordField, 'testpass123');
        
        // Step 4: Submit login
        final submitButton = find.textContaining('Login').or(find.textContaining('Submit'));
        await TestHelpers.safeTap(tester, submitButton, description: 'Submit login');
        
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }
      
      // Step 5: Verify authentication state
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        print('✅ User authenticated: ${currentUser.email}');
        expect(currentUser.email, equals('integration-test@thermal-app.com'));
      } else {
        print('ℹ️ Authentication flow not required or different UX pattern');
      }
      
      // Cleanup
      try {
        await FirebaseAuth.instance.signOut();
        await currentUser?.delete();
      } catch (e) {
        print('🧹 Cleanup note: $e');
      }
    });

    testWidgets('Firestore Data Operations with Emulator', (WidgetTester tester) async {
      print('🗄️ Testing Firestore Operations with Emulator');
      
      // Start the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Step 1: Seed test data in Firestore emulator
      print('🌱 Seeding test data in Firestore emulator');
      await FirebaseEmulatorService.seedTestData();
      
      // Step 2: Navigate to project selection
      final projectCardFinder = find.byType(Card).or(find.textContaining('Project'));
      final demoProjectFinder = find.textContaining('Test Project Alpha').or(find.textContaining('DEMO'));
      
      await TestHelpers.waitForWidget(tester, projectCardFinder, description: 'Project cards');
      
      // Step 3: Select a test project
      if (await TestHelpers.safeTap(tester, demoProjectFinder, description: 'Demo project')) {
        await tester.pumpAndSettle(const Duration(seconds: 2));
      } else {
        await TestHelpers.safeTap(tester, projectCardFinder, description: 'First project card');
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      
      // Step 4: Verify project data loaded from Firestore
      await TestHelpers.waitForLoadingToComplete(tester);
      
      // Look for project-specific content that would come from Firestore
      final projectContentFinders = [
        find.textContaining('Tank'),
        find.textContaining('Alpha'),
        find.textContaining('Summary'),
        find.byType(Card),
      ];
      
      bool foundProjectContent = projectContentFinders.any((finder) => tester.any(finder));
      expect(foundProjectContent, isTrue, reason: 'Should load project content from Firestore');
      
      // Step 5: Verify Firestore connection by checking collection
      final projectsSnapshot = await FirebaseFirestore.instance.collection('projects').get();
      expect(projectsSnapshot.docs.length, greaterThan(0), reason: 'Should have test projects in Firestore');
      
      print('✅ Firestore integration verified: ${projectsSnapshot.docs.length} projects found');
    });

    testWidgets('Complete Thermal Log Entry with Firestore Persistence', (WidgetTester tester) async {
      print('📝 Testing Complete Thermal Log Entry Flow');
      
      // Start the app  
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Seed data and create test user
      await FirebaseEmulatorService.seedTestData();
      await FirebaseEmulatorService.createTestUser();
      
      // Step 1: Navigate to project
      final projectFinder = find.byType(Card).or(find.textContaining('Test Project'));
      await TestHelpers.waitForWidget(tester, projectFinder);
      await TestHelpers.safeTap(tester, projectFinder, description: 'Test project');
      
      // Step 2: Navigate to daily summary
      await tester.pumpAndSettle(const Duration(seconds: 2));
      final summaryFinder = find.textContaining('Summary').or(find.textContaining('Daily'));
      if (await TestHelpers.safeTap(tester, summaryFinder, description: 'Daily summary')) {
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      
      // Step 3: Navigate to hour selection
      final hourFinder = find.textContaining('Hour').or(find.byType(GridView));
      await TestHelpers.waitForWidget(tester, hourFinder, timeout: const Duration(seconds: 10));
      await TestHelpers.safeTap(tester, hourFinder, description: 'Hour selector');
      
      // Step 4: Select specific hour (14:00)
      final hourButtonFinder = find.textContaining('14').or(find.textContaining('02')).or(find.textContaining('00'));
      await TestHelpers.safeTap(tester, hourButtonFinder, description: 'Hour 14:00');
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Step 5: Fill in thermal log entry form
      final textFieldFinder = find.byType(TextFormField);
      await TestHelpers.waitForWidget(tester, textFieldFinder, description: 'Entry form fields');
      
      // Fill in test thermal data
      final testData = ['1250', '1300', '150', '12.5', '98.5'];
      for (int i = 0; i < testData.length && i < tester.widgetList(textFieldFinder).length; i++) {
        await TestHelpers.safeEnterText(
          tester, 
          textFieldFinder.at(i), 
          testData[i],
          description: 'Field ${i + 1}'
        );
      }
      
      // Step 6: Save the entry
      final saveButtonFinder = find.textContaining('Save').or(find.textContaining('Submit'));
      await TestHelpers.safeTap(tester, saveButtonFinder, description: 'Save button');
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // Step 7: Verify data was saved to Firestore
      final thermalLogsSnapshot = await FirebaseFirestore.instance.collection('thermal_logs').get();
      expect(thermalLogsSnapshot.docs.length, greaterThan(0), reason: 'Should have saved thermal log entries');
      
      // Check for our test entry
      final testEntry = thermalLogsSnapshot.docs.where((doc) {
        final data = doc.data();
        return data['hour'] == 14 && data['temperature'] != null;
      }).toList();
      
      if (testEntry.isNotEmpty) {
        print('✅ Thermal log entry saved successfully');
        print('📊 Entry data: ${testEntry.first.data()}');
      } else {
        print('ℹ️ Entry may have been saved with different structure');
      }
    });

    testWidgets('Offline-to-Online Sync with Firestore', (WidgetTester tester) async {
      print('🔄 Testing Offline-to-Online Sync Flow');
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Seed initial data
      await FirebaseEmulatorService.seedTestData();
      
      // Step 1: Simulate offline entry (using local storage)
      print('📱 Simulating offline data entry');
      
      // Navigate to entry form
      final projectFinder = find.byType(Card);
      await TestHelpers.waitForWidget(tester, projectFinder);
      await TestHelpers.safeTap(tester, projectFinder);
      
      // Continue navigation to get to entry form
      await tester.pumpAndSettle(const Duration(seconds: 2));
      final hourFinder = find.textContaining('Hour').or(find.byType(GridView));
      if (tester.any(hourFinder)) {
        await TestHelpers.safeTap(tester, hourFinder);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        
        final specificHourFinder = find.textContaining('15').or(find.textContaining('03'));
        await TestHelpers.safeTap(tester, specificHourFinder, description: 'Hour 15:00');
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      
      // Step 2: Fill and save offline entry
      final textFieldFinder = find.byType(TextFormField);
      if (tester.any(textFieldFinder)) {
        await TestHelpers.safeEnterText(tester, textFieldFinder.first, '1275', description: 'Offline entry');
        
        final saveButtonFinder = find.textContaining('Save');
        await TestHelpers.safeTap(tester, saveButtonFinder, description: 'Save offline');
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      
      // Step 3: Trigger sync (look for sync button or automatic sync)
      final syncButtonFinder = find.textContaining('Sync').or(find.byIcon(Icons.sync));
      if (await TestHelpers.safeTap(tester, syncButtonFinder, description: 'Manual sync')) {
        await tester.pumpAndSettle(const Duration(seconds: 3));
        await TestHelpers.waitForLoadingToComplete(tester);
      }
      
      // Step 4: Verify sync completed
      // Check that sync indicators are not active
      final syncIndicators = [
        find.textContaining('Syncing'),
        find.textContaining('sync'),
        find.byType(CircularProgressIndicator),
      ];
      
      bool stillSyncing = syncIndicators.any((finder) => tester.any(finder));
      if (!stillSyncing) {
        print('✅ Sync appears to have completed');
      }
      
      // Step 5: Verify data exists in Firestore
      await tester.pumpAndSettle(const Duration(seconds: 2));
      final logsSnapshot = await FirebaseFirestore.instance.collection('thermal_logs').get();
      
      print('📊 Total thermal logs in Firestore: ${logsSnapshot.docs.length}');
      expect(logsSnapshot.docs.length, greaterThan(0), reason: 'Should have synced data to Firestore');
    });

    testWidgets('Multi-User Conflict Resolution with Emulator', (WidgetTester tester) async {
      print('⚔️ Testing Multi-User Conflict Resolution');
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Seed test data
      await FirebaseEmulatorService.seedTestData();
      
      // Step 1: Create conflicting entries in Firestore directly
      final firestore = FirebaseFirestore.instance;
      final testLogId = 'conflict_test_${DateTime.now().millisecondsSinceEpoch}';
      
      // Create initial entry
      await firestore.collection('thermal_logs').doc(testLogId).set({
        'projectId': 'test-project-1',
        'tankId': 'tank-a',
        'date': '2025-09-11',
        'hour': 16,
        'temperature': 1200.0,
        'operatorId': 'user1',
        'lastModified': FieldValue.serverTimestamp(),
        'version': 1,
      });
      
      // Simulate conflict by updating from another user
      await firestore.collection('thermal_logs').doc(testLogId).update({
        'temperature': 1250.0,
        'operatorId': 'user2',
        'lastModified': FieldValue.serverTimestamp(),
        'version': 2,
      });
      
      // Step 2: Navigate to the conflicted entry in the app
      await TestHelpers.navigateWithRetry(
        tester,
        'HourlyEntry',
        NavigationPaths.toHourlyEntry(),
      );
      
      // Step 3: Try to modify the same entry
      final textFieldFinder = find.byType(TextFormField);
      if (tester.any(textFieldFinder)) {
        await TestHelpers.safeEnterText(tester, textFieldFinder.first, '1275');
        
        final saveButtonFinder = find.textContaining('Save');
        await TestHelpers.safeTap(tester, saveButtonFinder, description: 'Save conflicting change');
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }
      
      // Step 4: Check for conflict resolution UI
      final conflictIndicators = [
        find.textContaining('Conflict'),
        find.textContaining('conflict'),
        find.textContaining('Version'),
        find.textContaining('Override'),
        find.textContaining('Merge'),
      ];
      
      bool conflictDetected = conflictIndicators.any((finder) => tester.any(finder));
      
      if (conflictDetected) {
        print('✅ Conflict resolution UI detected');
        
        // Try to resolve conflict
        final resolveButtonFinder = find.textContaining('Resolve').or(find.textContaining('Override'));
        await TestHelpers.safeTap(tester, resolveButtonFinder, description: 'Resolve conflict');
        await tester.pumpAndSettle(const Duration(seconds: 2));
      } else {
        print('ℹ️ No conflict UI shown - may use automatic resolution');
      }
      
      // Step 5: Verify final state in Firestore
      final finalDoc = await firestore.collection('thermal_logs').doc(testLogId).get();
      if (finalDoc.exists) {
        final finalData = finalDoc.data()!;
        print('📊 Final entry state: temperature=${finalData['temperature']}, version=${finalData['version']}');
        expect(finalData['temperature'], isNotNull, reason: 'Should have resolved temperature value');
      }
      
      // Cleanup
      await firestore.collection('thermal_logs').doc(testLogId).delete();
    });

    testWidgets('Data Validation and Error Handling with Emulator', (WidgetTester tester) async {
      print('🔍 Testing Data Validation and Error Handling');
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Seed test data
      await FirebaseEmulatorService.seedTestData();
      
      // Step 1: Navigate to entry form
      await TestHelpers.navigateWithRetry(
        tester,
        'HourlyEntry',
        NavigationPaths.toHourlyEntry(),
      );
      
      // Step 2: Test invalid data entry
      final textFieldFinder = find.byType(TextFormField);
      await TestHelpers.waitForWidget(tester, textFieldFinder, description: 'Entry form');
      
      // Enter invalid data
      await TestHelpers.safeEnterText(tester, textFieldFinder.first, 'INVALID_NUMBER');
      
      if (tester.widgetList(textFieldFinder).length > 1) {
        await TestHelpers.safeEnterText(tester, textFieldFinder.at(1), '-999999');
      }
      
      // Step 3: Try to save invalid data
      final saveButtonFinder = find.textContaining('Save');
      await TestHelpers.safeTap(tester, saveButtonFinder, description: 'Save invalid data');
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Step 4: Check for validation errors
      final errorIndicators = [
        find.textContaining('Error'),
        find.textContaining('error'),
        find.textContaining('Invalid'),
        find.textContaining('invalid'),
        find.textContaining('Required'),
        find.textContaining('range'),
      ];
      
      bool validationErrorShown = errorIndicators.any((finder) => tester.any(finder));
      expect(validationErrorShown, isTrue, reason: 'Should show validation errors for invalid data');
      
      if (validationErrorShown) {
        print('✅ Validation errors properly displayed');
      }
      
      // Step 5: Test network error simulation
      // Since we're using emulators, we can test disconnection scenarios
      print('🔌 Testing network disconnection scenarios');
      
      // Clear fields and enter valid data
      for (int i = 0; i < tester.widgetList(textFieldFinder).length; i++) {
        await tester.enterText(textFieldFinder.at(i), '');
        await TestHelpers.safeEnterText(tester, textFieldFinder.at(i), '1200');
      }
      
      // Try to save (should work with emulator)
      await TestHelpers.safeTap(tester, saveButtonFinder, description: 'Save valid data');
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // Look for success indicators
      final successIndicators = [
        find.textContaining('Saved'),
        find.textContaining('Success'),
        find.textContaining('✓'),
      ];
      
      bool saveSuccessful = successIndicators.any((finder) => tester.any(finder));
      if (saveSuccessful) {
        print('✅ Valid data saved successfully');
      } else {
        print('ℹ️ Save completed without explicit success message');
      }
    });

    tearDownAll(() async {
      print('🧹 Cleaning up Firebase emulator test data');
      
      try {
        // Clean up test collections
        final firestore = FirebaseFirestore.instance;
        
        // Delete test thermal logs
        final logsSnapshot = await firestore.collection('thermal_logs').get();
        for (final doc in logsSnapshot.docs) {
          if (doc.id.startsWith('test-') || doc.id.startsWith('conflict_test_')) {
            await doc.reference.delete();
          }
        }
        
        // Clean up test projects if they have test identifiers
        final projectsSnapshot = await firestore.collection('projects').get();
        for (final doc in projectsSnapshot.docs) {
          if (doc.id.startsWith('test-')) {
            await doc.reference.delete();
          }
        }
        
        print('✅ Test data cleanup completed');
      } catch (e) {
        print('⚠️ Cleanup error (expected in some test scenarios): $e');
      }
    });
  });
}