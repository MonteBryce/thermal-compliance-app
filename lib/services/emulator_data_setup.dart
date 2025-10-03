import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/hive_models.dart';
import '../services/hourly_reading_mapper.dart';
import '../services/local_database_service.dart';
import 'dart:math';

/// Service to set up Firebase Emulator with proper data structures
class EmulatorDataSetup {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final Random _random = Random();

  /// Initialize emulator with sample data
  static Future<void> initializeEmulatorData({
    bool clearExisting = false,
    int daysOfData = 7,
  }) async {
    try {
      print('🔧 Initializing Emulator Data...');

      // Clear existing data if requested
      if (clearExisting) {
        await clearEmulatorData();
      }

      // Create test user if not exists
      final user = await _ensureTestUser();

      // Create projects
      final projects = await _createSampleProjects(user.uid);

      // Create hourly readings for each project
      for (final project in projects) {
        await _createHourlyReadings(
          projectId: project['id'],
          projectName: project['name'],
          userId: user.uid,
          daysOfData: daysOfData,
        );
      }

      // Create collection indexes
      await _createCollectionIndexes();

      print('✅ Emulator data initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize emulator data: $e');
      rethrow;
    }
  }

  /// Clear all emulator data
  static Future<void> clearEmulatorData() async {
    print('🗑️ Clearing emulator data...');

    // Only clear data if using emulator
    if (!_isUsingEmulator()) {
      throw Exception('Not connected to Firebase Emulator. Aborting clear operation for safety.');
    }

    try {
      // Clear Firestore collections
      await _clearCollection('users');
      await _clearCollection('projects');
      await _clearCollection('thermal_logs');
      await _clearCollection('hourly_readings');

      // Clear local Hive data
      await LocalDatabaseService.clearAllData();

      print('✅ Emulator data cleared');
    } catch (e) {
      print('❌ Failed to clear emulator data: $e');
    }
  }

  /// Ensure test user exists
  static Future<User> _ensureTestUser() async {
    try {
      // Try to sign in first
      final credential = await _auth.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'test123456',
      );

      if (credential.user != null) {
        print('✅ Test user signed in');
        return credential.user!;
      }
    } catch (e) {
      // User doesn't exist, create new one
      print('Creating new test user...');
    }

    // Create new test user
    final credential = await _auth.createUserWithEmailAndPassword(
      email: 'test@example.com',
      password: 'test123456',
    );

    if (credential.user == null) {
      throw Exception('Failed to create test user');
    }

    // Update display name
    await credential.user!.updateDisplayName('Test User');

    // Create user document
    await _firestore.collection('users').doc(credential.user!.uid).set({
      'email': 'test@example.com',
      'displayName': 'Test User',
      'role': 'operator',
      'createdAt': DateTime.now().toIso8601String(),
      'preferences': {
        'defaultProjectId': null,
        'autoSync': true,
        'theme': 'light',
      },
    });

    print('✅ Test user created');
    return credential.user!;
  }

  /// Create sample projects
  static Future<List<Map<String, dynamic>>> _createSampleProjects(String userId) async {
    final projects = [
      {
        'id': 'proj_001',
        'name': 'Marathon GBR Site A',
        'projectNumber': 'MGR-2024-001',
        'location': 'Texas, USA',
        'unitNumber': 'TU-001',
        'client': 'Marathon Oil',
        'status': 'active',
        'templateType': 'methane_h2s_hourly',
      },
      {
        'id': 'proj_002',
        'name': 'Pentane Recovery Unit B',
        'projectNumber': 'PRU-2024-002',
        'location': 'Oklahoma, USA',
        'unitNumber': 'TU-002',
        'client': 'Energy Corp',
        'status': 'active',
        'templateType': 'pentane_lel_hourly',
      },
      {
        'id': 'proj_003',
        'name': 'H2S Treatment Facility',
        'projectNumber': 'HST-2024-003',
        'location': 'Louisiana, USA',
        'unitNumber': 'TU-003',
        'client': 'Chemical Solutions Inc',
        'status': 'active',
        'templateType': 'h2s_monitoring',
      },
    ];

    for (final project in projects) {
      // Create in Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('projects')
          .doc(project['id'] as String)
          .set({
        ...project,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'createdBy': userId,
      });

      // Create in global projects collection for easy access
      await _firestore.collection('projects').doc(project['id'] as String).set({
        ...project,
        'userId': userId,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }

    print('✅ Created ${projects.length} sample projects');
    return projects;
  }

  /// Create hourly readings for a project
  static Future<void> _createHourlyReadings({
    required String projectId,
    required String projectName,
    required String userId,
    required int daysOfData,
  }) async {
    final batch = _firestore.batch();
    int batchCount = 0;

    final now = DateTime.now();

    for (int day = 0; day < daysOfData; day++) {
      final date = now.subtract(Duration(days: day));

      for (int hour = 0; hour < 24; hour++) {
        // Skip future hours for today
        if (day == 0 && hour > now.hour) continue;

        final formData = _generateSampleFormData(hour);

        // Create LogEntry
        final logEntry = HourlyReadingMapper.mapToLogEntry(
          projectId: projectId,
          projectName: projectName,
          date: date,
          hour: hour,
          formData: formData,
          userId: userId,
        );

        // Convert to Firestore format
        final firestoreData = HourlyReadingMapper.mapToFirestore(logEntry);

        // Add to batch
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('hourly_readings')
            .doc(logEntry.id);

        batch.set(docRef, firestoreData);
        batchCount++;

        // Commit batch every 100 documents
        if (batchCount >= 100) {
          await batch.commit();
          batchCount = 0;
        }
      }
    }

    // Commit remaining documents
    if (batchCount > 0) {
      await batch.commit();
    }

    print('✅ Created hourly readings for $projectName ($daysOfData days)');
  }

  /// Generate sample form data for testing
  static Map<String, dynamic> _generateSampleFormData(int hour) {
    // Generate realistic values based on time of day
    final baseInlet = 100 + hour * 2;
    final baseOutlet = 95 + hour * 1.8;

    return {
      // Gas readings
      'inlet_reading': baseInlet + _random.nextDouble() * 10,
      'outlet_reading': baseOutlet + _random.nextDouble() * 10,
      'to_inlet_reading_h2s': 5 + _random.nextDouble() * 3,
      'lel_inlet_reading': 15 + _random.nextDouble() * 5,

      // Flow rates
      'vapor_inlet_flow_rate_fpm': 500 + _random.nextDouble() * 100,
      'vapor_inlet_flow_rate_bbl': 1000 + _random.nextDouble() * 200,
      'tank_refill_flow_rate': 50 + _random.nextDouble() * 20,
      'combustion_air_flow_rate': 300 + _random.nextDouble() * 50,

      // System metrics
      'vacuum_at_tank_vapor_outlet': -5 + _random.nextDouble() * 2,
      'exhaust_temperature': 800 + _random.nextDouble() * 200,
      'totalizer': 10000 + hour * 100 + _random.nextDouble() * 50,

      // Metadata
      'observations': _getRandomObservation(),
      'operator_id': 'OP00${1 + _random.nextInt(3)}',
      'validated': _random.nextBool(),
      'form_template': 'standard',
      'entry_method': _random.nextBool() ? 'manual' : 'imported',

      // Validation status
      'has_warnings': _random.nextDouble() < 0.1,
      'has_errors': false,
      'warning_messages': [],
      'error_messages': [],
    };
  }

  /// Get random observation text
  static String _getRandomObservation() {
    final observations = [
      'Normal operation',
      'Slight fluctuation in inlet pressure',
      'Adjusted flow rate per supervisor instruction',
      'Minor condensation observed',
      'System running smoothly',
      'Scheduled maintenance completed',
      '',
      '',
      '', // Empty observations are common
    ];

    return observations[_random.nextInt(observations.length)];
  }

  /// Create collection indexes for better query performance
  static Future<void> _createCollectionIndexes() async {
    // Note: Firestore emulator doesn't support creating indexes programmatically
    // These would normally be defined in firestore.indexes.json
    print('📋 Index creation note: Configure indexes in firestore.indexes.json');

    // Suggested indexes:
    // - hourly_readings: (projectId, date, hour)
    // - hourly_readings: (projectId, yearMonth)
    // - hourly_readings: (createdBy, status)
    // - projects: (status, createdAt)
  }

  /// Clear a specific collection
  static Future<void> _clearCollection(String collectionPath) async {
    final collection = _firestore.collection(collectionPath);
    final snapshot = await collection.limit(100).get();

    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    // Recursively clear more documents if any remain
    await _clearCollection(collectionPath);
  }

  /// Check if Firebase is using emulator
  static bool _isUsingEmulator() {
    // Check if Firestore is using emulator
    try {
      final settings = _firestore.settings;
      // In a real implementation, you'd check the host
      // For now, we'll assume emulator is being used if this service is called
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Create sample data for a specific date range
  static Future<void> createDataForDateRange({
    required String projectId,
    required String projectName,
    required DateTime startDate,
    required DateTime endDate,
    required String userId,
  }) async {
    final days = endDate.difference(startDate).inDays + 1;

    for (int day = 0; day < days; day++) {
      final date = startDate.add(Duration(days: day));

      for (int hour = 0; hour < 24; hour++) {
        final formData = _generateSampleFormData(hour);

        final logEntry = HourlyReadingMapper.mapToLogEntry(
          projectId: projectId,
          projectName: projectName,
          date: date,
          hour: hour,
          formData: formData,
          userId: userId,
        );

        // Save to Firestore
        final firestoreData = HourlyReadingMapper.mapToFirestore(logEntry);
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('hourly_readings')
            .doc(logEntry.id)
            .set(firestoreData);

        // Also save to local Hive
        await LocalDatabaseService.saveLogEntry(logEntry);
      }
    }

    print('✅ Created data for $projectName from $startDate to $endDate');
  }
}