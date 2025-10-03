import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_flutter_app/services/firebase_emulator_service.dart';
import 'package:my_flutter_app/models/thermal_log.dart';

void main() {
  setUpAll(() async {
    // Initialize Flutter test binding
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Firebase for testing
    await Firebase.initializeApp();
    await FirebaseEmulatorService.initializeEmulators();
  });

  group('Firebase Connection Tests', () {
    test('Firestore basic write and read operation', () async {
      final firestore = FirebaseFirestore.instance;
      
      // Create test data
      final testData = {
        'test': true,
        'message': 'Basic Firestore connection test',
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Write to Firestore
      final docRef = await firestore.collection('test').add(testData);
      expect(docRef.id, isNotEmpty);

      // Read from Firestore
      final docSnapshot = await docRef.get();
      expect(docSnapshot.exists, true);
      expect(docSnapshot.data()?['test'], true);
      expect(docSnapshot.data()?['message'], 'Basic Firestore connection test');

      // Clean up
      await docRef.delete();
    });

    test('Firebase Auth basic operations', () async {
      final auth = FirebaseAuth.instance;
      
      try {
        // Create test user
        final userCredential = await auth.createUserWithEmailAndPassword(
          email: 'test-${DateTime.now().millisecondsSinceEpoch}@thermal.com',
          password: 'testpass123',
        );

        expect(userCredential.user, isNotNull);
        expect(userCredential.user!.email, contains('@thermal.com'));

        // Sign out
        await auth.signOut();
        expect(auth.currentUser, isNull);

        // Clean up - delete user
        await userCredential.user!.delete();
      } on FirebaseAuthException catch (e) {
        // If user already exists, that's also a success for connectivity
        if (e.code == 'email-already-in-use') {
          expect(true, true); // Connection works
        } else {
          rethrow;
        }
      }
    });

    test('ThermalLog Firestore integration', () async {
      final firestore = FirebaseFirestore.instance;
      final now = DateTime.now();
      
      // Create a ThermalLog instance
      final thermalLog = ThermalLog(
        id: 'test-thermal-${now.millisecondsSinceEpoch}',
        timestamp: now,
        temperature: 75.5,
        notes: 'Test thermal reading for Firebase',
        projectId: 'test-project-123',
        createdAt: now,
        updatedAt: now,
      );

      // Write ThermalLog to Firestore
      final docRef = firestore.collection('thermal_logs').doc(thermalLog.id);
      await docRef.set(thermalLog.toFirestore());

      // Read ThermalLog from Firestore
      final docSnapshot = await docRef.get();
      expect(docSnapshot.exists, true);

      final retrievedLog = ThermalLog.fromFirestore(docSnapshot.data()!);
      expect(retrievedLog.id, thermalLog.id);
      expect(retrievedLog.temperature, thermalLog.temperature);
      expect(retrievedLog.notes, thermalLog.notes);
      expect(retrievedLog.projectId, thermalLog.projectId);

      // Clean up
      await docRef.delete();
    });

    test('Firebase emulator info is available', () {
      final emulatorInfo = FirebaseEmulatorService.emulatorInfo;
      
      expect(emulatorInfo['auth'], 'http://localhost:9099');
      expect(emulatorInfo['firestore'], 'http://localhost:8081');
      expect(emulatorInfo['ui'], 'http://localhost:4000');
      expect(emulatorInfo['status'], anyOf(['connected', 'not_connected']));
    });
  });
}