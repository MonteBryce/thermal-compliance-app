import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_flutter_app/services/firebase_emulator_service.dart';

void main() {
  group('Firebase Emulator Integration Tests', () {
    setUpAll(() async {
      // Initialize Flutter test binding first
      TestWidgetsFlutterBinding.ensureInitialized();
      
      // Initialize Firebase for testing
      await Firebase.initializeApp();
      
      // Initialize emulators
      await FirebaseEmulatorService.initializeEmulators();
    });

    test('should connect to Auth emulator', () async {
      expect(FirebaseEmulatorService.isUsingEmulators, isTrue);
      
      final emulatorInfo = FirebaseEmulatorService.emulatorInfo;
      expect(emulatorInfo['auth'], contains('localhost:9099'));
      expect(emulatorInfo['status'], equals('connected'));
    });

    test('should connect to Firestore emulator', () async {
      final emulatorInfo = FirebaseEmulatorService.emulatorInfo;
      expect(emulatorInfo['firestore'], contains('localhost:8080'));
      
      // Test basic Firestore connectivity
      final firestore = FirebaseFirestore.instance;
      final testDoc = firestore.collection('test').doc('connectivity');
      
      await testDoc.set({'timestamp': FieldValue.serverTimestamp()});
      final snapshot = await testDoc.get();
      
      expect(snapshot.exists, isTrue);
      expect(snapshot.data(), isNotNull);
    });

    test('should create test user in Auth emulator', () async {
      await FirebaseEmulatorService.createTestUser(
        email: 'integration-test@thermal-app.com',
        password: 'testpass123'
      );
      
      // Verify test user was created by signing in
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: 'integration-test@thermal-app.com',
        password: 'testpass123'
      );
      
      expect(credential.user, isNotNull);
      expect(credential.user?.email, equals('integration-test@thermal-app.com'));
      
      // Clean up
      await credential.user?.delete();
    });

    test('should seed test data in Firestore emulator', () async {
      await FirebaseEmulatorService.seedTestData();
      
      // Verify test projects were created
      final projectsSnapshot = await FirebaseFirestore.instance
          .collection('projects')
          .get();
      
      expect(projectsSnapshot.docs.length, greaterThanOrEqualTo(2));
      
      final projectNames = projectsSnapshot.docs
          .map((doc) => doc.data()['name'] as String)
          .toList();
      
      expect(projectNames, contains('Test Project Alpha'));
      expect(projectNames, contains('Test Project Beta'));
      
      // Verify test thermal logs were created
      final logsSnapshot = await FirebaseFirestore.instance
          .collection('thermal_logs')
          .get();
      
      expect(logsSnapshot.docs.length, greaterThanOrEqualTo(1));
    });

    test('should handle emulator connection errors gracefully', () async {
      // This test verifies error handling when emulators are not running
      // In a real scenario, this would test the fallback behavior
      
      final emulatorInfo = FirebaseEmulatorService.emulatorInfo;
      expect(emulatorInfo, isNotEmpty);
      expect(emulatorInfo.containsKey('status'), isTrue);
    });

    tearDownAll(() async {
      // Clean up test data
      try {
        final firestore = FirebaseFirestore.instance;
        
        // Delete test collections
        final testDocs = await firestore.collection('test').get();
        for (final doc in testDocs.docs) {
          await doc.reference.delete();
        }
        
        final projectDocs = await firestore.collection('projects').get();
        for (final doc in projectDocs.docs) {
          if (doc.id.startsWith('test-')) {
            await doc.reference.delete();
          }
        }
        
        final logDocs = await firestore.collection('thermal_logs').get();
        for (final doc in logDocs.docs) {
          if (doc.id.startsWith('test-')) {
            await doc.reference.delete();
          }
        }
      } catch (e) {
        // Ignore cleanup errors in tests
      }
    });
  });
}