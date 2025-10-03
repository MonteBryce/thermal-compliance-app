import 'package:flutter_test/flutter_test.dart';
import 'package:my_flutter_app/models/thermal_log.dart';

void main() {
  group('ThermalLog Model Tests', () {
    late ThermalLog testLog;
    late DateTime testTime;

    setUp(() {
      testTime = DateTime.now();
      testLog = ThermalLog(
        id: 'test-123',
        timestamp: testTime,
        temperature: 75.5,
        notes: 'Test thermal reading',
        projectId: 'project-456',
        createdAt: testTime,
        updatedAt: testTime,
      );
    });

    test('creates ThermalLog with all required fields', () {
      expect(testLog.id, 'test-123');
      expect(testLog.timestamp, testTime);
      expect(testLog.temperature, 75.5);
      expect(testLog.notes, 'Test thermal reading');
      expect(testLog.projectId, 'project-456');
      expect(testLog.createdAt, testTime);
      expect(testLog.updatedAt, testTime);
    });

    test('converts to Firestore format correctly', () {
      final firestoreData = testLog.toFirestore();
      
      expect(firestoreData['id'], 'test-123');
      expect(firestoreData['timestamp'], testTime.toIso8601String());
      expect(firestoreData['temperature'], 75.5);
      expect(firestoreData['notes'], 'Test thermal reading');
      expect(firestoreData['projectId'], 'project-456');
      expect(firestoreData['createdAt'], testTime.toIso8601String());
      expect(firestoreData['updatedAt'], testTime.toIso8601String());
    });

    test('creates from Firestore format correctly', () {
      final firestoreData = {
        'id': 'firestore-789',
        'timestamp': testTime.toIso8601String(),
        'temperature': 80.0,
        'notes': 'Firestore test reading',
        'projectId': 'firestore-project',
        'createdAt': testTime.toIso8601String(),
        'updatedAt': testTime.toIso8601String(),
      };

      final logFromFirestore = ThermalLog.fromFirestore(firestoreData);

      expect(logFromFirestore.id, 'firestore-789');
      expect(logFromFirestore.timestamp, testTime);
      expect(logFromFirestore.temperature, 80.0);
      expect(logFromFirestore.notes, 'Firestore test reading');
      expect(logFromFirestore.projectId, 'firestore-project');
    });

    test('JSON serialization roundtrip works', () {
      final json = testLog.toJson();
      final logFromJson = ThermalLog.fromJson(json);

      expect(logFromJson.id, testLog.id);
      expect(logFromJson.timestamp, testLog.timestamp);
      expect(logFromJson.temperature, testLog.temperature);
      expect(logFromJson.notes, testLog.notes);
      expect(logFromJson.projectId, testLog.projectId);
    });

    test('copyWith creates modified copy', () {
      final updatedLog = testLog.copyWith(
        temperature: 90.0,
        notes: 'Updated notes',
      );

      expect(updatedLog.id, testLog.id);
      expect(updatedLog.temperature, 90.0);
      expect(updatedLog.notes, 'Updated notes');
      expect(updatedLog.projectId, testLog.projectId);
    });

    test('toString provides readable output', () {
      final stringOutput = testLog.toString();
      expect(stringOutput.contains('ThermalLog'), true);
      expect(stringOutput.contains(testLog.id), true);
      expect(stringOutput.contains(testLog.temperature.toString()), true);
    });
  });
}