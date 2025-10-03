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
        debugPrint('✅ Firebase Firestore Emulator connected: http://localhost:8080');
        
        debugPrint('🎯 Firebase Emulator UI available at: http://localhost:4000');
        debugPrint('📊 All Firebase services now using LOCAL emulators');
        
        _isInitialized = true;
      } catch (e) {
        debugPrint('⚠️ Failed to connect to Firebase emulators: $e');
        debugPrint('💡 Make sure emulators are running: firebase emulators:start');
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
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
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
      
      // Create test project data
      await firestore.collection('projects').doc('test-project-1').set({
        'name': 'Test Project Alpha',
        'code': 'TPA001',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'tanks': [
          {'id': 'tank-a', 'name': 'Tank A', 'capacity': 10000},
          {'id': 'tank-b', 'name': 'Tank B', 'capacity': 15000},
        ]
      });
      
      await firestore.collection('projects').doc('test-project-2').set({
        'name': 'Test Project Beta',
        'code': 'TPB002', 
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'tanks': [
          {'id': 'tank-c', 'name': 'Tank C', 'capacity': 8000},
        ]
      });
      
      // Create test thermal log entries
      await firestore.collection('thermal_logs').doc('test-log-1').set({
        'projectId': 'test-project-1',
        'tankId': 'tank-a',
        'operatorId': 'test-user-123',
        'date': '2025-09-11',
        'hour': 14,
        'temperature': 72.5,
        'isLocked': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ Test data seeded successfully');
      debugPrint('📊 Projects: 2, Thermal Logs: 1');
    } catch (e) {
      debugPrint('❌ Failed to seed test data: $e');
    }
  }
}