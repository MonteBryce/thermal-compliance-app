import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/emulator_data_setup.dart';
import '../firebase_options.dart';

/// Utility to initialize Firebase emulator with sample data
/// Can be called from main() or from a test setup
class InitializeEmulator {
  static bool _initialized = false;

  /// Connect to Firebase emulator and optionally load sample data
  static Future<void> initialize({
    bool useEmulator = true,
    bool loadSampleData = true,
    bool clearExisting = false,
    int daysOfData = 7,
  }) async {
    if (_initialized) {
      print('⚠️ Emulator already initialized');
      return;
    }

    try {
      print('🚀 Initializing Firebase...');

      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      if (useEmulator) {
        print('🔌 Connecting to Firebase Emulator...');

        // Connect to Firebase Auth emulator
        await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);

        // Connect to Firestore emulator
        FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);

        print('✅ Connected to Firebase Emulator');

        if (loadSampleData) {
          print('📦 Loading sample data...');
          await EmulatorDataSetup.initializeEmulatorData(
            clearExisting: clearExisting,
            daysOfData: daysOfData,
          );
        }
      } else {
        print('☁️ Using production Firebase');
      }

      _initialized = true;
      print('✅ Firebase initialization complete');
    } catch (e) {
      print('❌ Failed to initialize Firebase: $e');
      rethrow;
    }
  }

  /// Quick setup for testing - connects and loads data
  static Future<void> quickSetup() async {
    await initialize(
      useEmulator: true,
      loadSampleData: true,
      clearExisting: true,
      daysOfData: 7,
    );
  }

  /// Check if we're connected to emulator
  static bool isUsingEmulator() {
    try {
      final settings = FirebaseFirestore.instance.settings;
      // This is a simplified check - you might want to enhance this
      return true; // Assume emulator if this service is used
    } catch (e) {
      return false;
    }
  }

  /// Get current auth user
  static User? getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }

  /// Sign in as test user
  static Future<User?> signInTestUser() async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'test123456',
      );
      return credential.user;
    } catch (e) {
      print('❌ Failed to sign in test user: $e');
      return null;
    }
  }
}

/// Widget to show emulator status
class EmulatorStatusBanner extends StatelessWidget {
  const EmulatorStatusBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!InitializeEmulator.isUsingEmulator()) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.orange,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: const [
          Icon(Icons.warning, size: 16, color: Colors.white),
          SizedBox(width: 8),
          Text(
            'FIREBASE EMULATOR MODE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}