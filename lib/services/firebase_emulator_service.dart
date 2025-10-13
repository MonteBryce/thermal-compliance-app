import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service to configure Firebase emulators for local development
/// Automatically detects development environment and connects to emulators
class FirebaseEmulatorService {
  static bool _isInitialized = false;

  /// Initialize Firebase emulators for local development
  /// Should be called in main() before runApp() in debug mode
  static Future<void> initializeEmulators() async {
    if (_isInitialized) return;

    // Only connect to emulators in debug mode (not in production)
    if (kDebugMode) {
      try {
        debugPrint('🔥 Configuring Firebase Emulators for local development');

        // Connect Auth emulator
        await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
        debugPrint('✅ Firebase Auth Emulator connected: http://localhost:9099');

        // Connect Firestore emulator
        FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
        debugPrint(
            '✅ Firebase Firestore Emulator connected: http://localhost:8080');

        debugPrint(
            '🎯 Firebase Emulator UI available at: http://localhost:4000');
        debugPrint('📊 All Firebase services now using LOCAL emulators');

        _isInitialized = true;
      } catch (e) {
        debugPrint('⚠️ Failed to connect to Firebase emulators: $e');
        debugPrint(
            '💡 Make sure emulators are running: firebase emulators:start');
      }
    } else {
      debugPrint('🔥 Running in release mode - using production Firebase');
    }
  }

  /// Check if emulators are configured and running
  static bool get isUsingEmulators => kDebugMode && _isInitialized;

  /// Get emulator connection info for debugging
  static Map<String, String> get emulatorInfo => {
        'auth': 'http://localhost:9099',
        'firestore': 'http://localhost:8080',
        'ui': 'http://localhost:4000',
        'status': isUsingEmulators ? 'connected' : 'not_connected'
      };

  /// Create test user in Auth emulator for development
  static Future<void> createTestUser({
    String email = 'test@thermal-app.com',
    String password = 'testpass123',
  }) async {
    if (!isUsingEmulators) {
      debugPrint('⚠️ createTestUser() only available in emulator mode');
      return;
    }

    try {
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('✅ Test user created: ${userCredential.user?.email}');
      debugPrint('🔑 Login: $email / $password');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        debugPrint('✅ Test user already exists: $email');
      } else {
        debugPrint('❌ Failed to create test user: ${e.message}');
      }
    }
  }

  /// Seed test data in Firestore emulator
  static Future<void> seedTestData() async {
    if (!isUsingEmulators) {
      debugPrint('⚠️ seedTestData() only available in emulator mode');
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;

      final project1Ref =
          firestore.collection('projects').doc('test-project-1');
      await project1Ref.set({
        'projectName': 'Test Project Alpha',
        'projectNumber': 'TPA001',
        'location': 'Demo Facility',
        'unitNumber': 'Unit-42',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': 'emulator-seed',
      }, SetOptions(merge: true));

      final project2Ref =
          firestore.collection('projects').doc('test-project-2');
      await project2Ref.set({
        'projectName': 'Test Project Beta',
        'projectNumber': 'TPB002',
        'location': 'Demo Facility',
        'unitNumber': 'Unit-17',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': 'emulator-seed',
      }, SetOptions(merge: true));

      const logDate = '2025-09-11';
      final logRef = project1Ref.collection('logs').doc(logDate);
      await logRef.set({
        'projectId': 'test-project-1',
        'date': logDate,
        'completionStatus': 'complete',
        'totalEntries': 1,
        'completedHours': 1,
        'validatedHours': 0,
        'operatorIds': ['test-user-123'],
        'dailyMetrics': <String, dynamic>{},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await logRef.collection('entries').doc('14').set({
        'hour': 14,
        'timestamp': Timestamp.fromDate(DateTime(2025, 9, 11, 14)),
        'logType': 'thermal',
        'operatorId': 'test-user-123',
        'observations': 'Seed data from emulator',
        'validated': false,
        'readings': {
          'exhaustTemperature': 550,
          'inletReading': 68.5,
          'outletReading': 71.2,
        },
        'createdBy': 'emulator-seed',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'synced': true,
      }, SetOptions(merge: true));

      debugPrint('✅ Test data seeded successfully');
      debugPrint('📊 Projects: 2, Logs: 1, Entries: 1');
    } catch (e) {
      debugPrint('❌ Failed to seed test data: $e');
    }
  }
}
