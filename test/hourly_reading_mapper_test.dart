import 'package:flutter_test/flutter_test.dart';
import 'package:my_flutter_app/services/hourly_reading_mapper.dart';
import 'package:my_flutter_app/models/hive_models.dart';

void main() {
  group('HourlyReadingMapper', () {
    late Map<String, dynamic> sampleFormData;
    late DateTime testDate;
    const testProjectId = 'test_project_001';
    const testProjectName = 'Test Project';
    const testUserId = 'test_user_001';
    const testHour = 14;

    setUp(() {
      testDate = DateTime(2024, 1, 15);

      sampleFormData = {
        'inlet_reading': 120.5,
        'outlet_reading': 115.3,
        'to_inlet_reading_h2s': 8.2,
        'lel_inlet_reading': 18.5,
        'vapor_inlet_flow_rate_fpm': 550.0,
        'vapor_inlet_flow_rate_bbl': 1200.0,
        'tank_refill_flow_rate': 65.0,
        'combustion_air_flow_rate': 320.0,
        'vacuum_at_tank_vapor_outlet': -4.5,
        'exhaust_temperature': 950.0,
        'totalizer': 10500.0,
        'observations': 'Normal operation',
        'operator_id': 'OP001',
        'validated': true,
      };
    });

    group('mapToLogEntry', () {
      test('should create LogEntry with correct basic fields', () {
        final logEntry = HourlyReadingMapper.mapToLogEntry(
          projectId: testProjectId,
          projectName: testProjectName,
          date: testDate,
          hour: testHour,
          formData: sampleFormData,
          userId: testUserId,
        );

        expect(logEntry.projectId, equals(testProjectId));
        expect(logEntry.projectName, equals(testProjectName));
        expect(logEntry.date, equals('2024-01-15'));
        expect(logEntry.hour, equals('14'));
        expect(logEntry.createdBy, equals(testUserId));
        expect(logEntry.isSynced, isFalse);
      });

      test('should structure form data correctly', () {
        final logEntry = HourlyReadingMapper.mapToLogEntry(
          projectId: testProjectId,
          projectName: testProjectName,
          date: testDate,
          hour: testHour,
          formData: sampleFormData,
          userId: testUserId,
        );

        // Check structured data
        expect(logEntry.data['gas_readings'], isNotNull);
        expect(logEntry.data['gas_readings']['inlet_reading'], equals(120.5));
        expect(logEntry.data['gas_readings']['outlet_reading'], equals(115.3));

        expect(logEntry.data['flow_rates'], isNotNull);
        expect(logEntry.data['flow_rates']['vapor_inlet_flow_rate_fpm'], equals(550.0));

        expect(logEntry.data['system_metrics'], isNotNull);
        expect(logEntry.data['system_metrics']['exhaust_temperature'], equals(950.0));

        expect(logEntry.data['metadata'], isNotNull);
        expect(logEntry.data['metadata']['observations'], equals('Normal operation'));
        expect(logEntry.data['metadata']['validated'], isTrue);
      });

      test('should preserve flat structure for backward compatibility', () {
        final logEntry = HourlyReadingMapper.mapToLogEntry(
          projectId: testProjectId,
          projectName: testProjectName,
          date: testDate,
          hour: testHour,
          formData: sampleFormData,
          userId: testUserId,
        );

        // Check that original flat fields are preserved
        expect(logEntry.data['inlet_reading'], equals(120.5));
        expect(logEntry.data['outlet_reading'], equals(115.3));
        expect(logEntry.data['exhaust_temperature'], equals(950.0));
      });

      test('should determine status correctly', () {
        // Test completed status
        var logEntry = HourlyReadingMapper.mapToLogEntry(
          projectId: testProjectId,
          projectName: testProjectName,
          date: testDate,
          hour: testHour,
          formData: sampleFormData,
          userId: testUserId,
        );
        expect(logEntry.status, equals('completed'));

        // Test partial status
        final partialData = Map<String, dynamic>.from(sampleFormData);
        partialData['outlet_reading'] = null;
        logEntry = HourlyReadingMapper.mapToLogEntry(
          projectId: testProjectId,
          projectName: testProjectName,
          date: testDate,
          hour: testHour,
          formData: partialData,
          userId: testUserId,
        );
        expect(logEntry.status, equals('partial'));

        // Test pending status
        final emptyData = <String, dynamic>{};
        logEntry = HourlyReadingMapper.mapToLogEntry(
          projectId: testProjectId,
          projectName: testProjectName,
          date: testDate,
          hour: testHour,
          formData: emptyData,
          userId: testUserId,
        );
        expect(logEntry.status, equals('pending'));
      });

      test('should use existing ID when provided', () {
        const existingId = 'existing_entry_001';
        final logEntry = HourlyReadingMapper.mapToLogEntry(
          projectId: testProjectId,
          projectName: testProjectName,
          date: testDate,
          hour: testHour,
          formData: sampleFormData,
          userId: testUserId,
          existingId: existingId,
        );

        expect(logEntry.id, equals(existingId));
      });
    });

    group('mapToThermalReading', () {
      test('should convert LogEntry to ThermalReading correctly', () {
        final logEntry = HourlyReadingMapper.mapToLogEntry(
          projectId: testProjectId,
          projectName: testProjectName,
          date: testDate,
          hour: testHour,
          formData: sampleFormData,
          userId: testUserId,
        );

        final thermalReading = HourlyReadingMapper.mapToThermalReading(logEntry);

        expect(thermalReading.hour, equals(testHour));
        expect(thermalReading.timestamp, equals('2024-01-15 14:00'));
        expect(thermalReading.inletReading, equals(120.5));
        expect(thermalReading.outletReading, equals(115.3));
        expect(thermalReading.toInletReadingH2S, equals(8.2));
        expect(thermalReading.lelInletReading, equals(18.5));
        expect(thermalReading.exhaustTemperature, equals(950.0));
        expect(thermalReading.observations, equals('Normal operation'));
        expect(thermalReading.operatorId, equals('OP001'));
        expect(thermalReading.validated, isTrue);
      });

      test('should handle missing fields gracefully', () {
        final emptyData = <String, dynamic>{};
        final logEntry = HourlyReadingMapper.mapToLogEntry(
          projectId: testProjectId,
          projectName: testProjectName,
          date: testDate,
          hour: testHour,
          formData: emptyData,
          userId: testUserId,
        );

        final thermalReading = HourlyReadingMapper.mapToThermalReading(logEntry);

        expect(thermalReading.inletReading, isNull);
        expect(thermalReading.outletReading, isNull);
        expect(thermalReading.observations, equals(''));
        expect(thermalReading.validated, isFalse);
      });
    });

    group('mapToFirestore', () {
      test('should create Firestore-compatible map', () {
        final logEntry = HourlyReadingMapper.mapToLogEntry(
          projectId: testProjectId,
          projectName: testProjectName,
          date: testDate,
          hour: testHour,
          formData: sampleFormData,
          userId: testUserId,
        );

        final firestoreData = HourlyReadingMapper.mapToFirestore(logEntry);

        expect(firestoreData['id'], equals(logEntry.id));
        expect(firestoreData['projectId'], equals(testProjectId));
        expect(firestoreData['date'], equals('2024-01-15'));
        expect(firestoreData['hour'], equals('14'));
        expect(firestoreData['hourInt'], equals(14));
        expect(firestoreData['yearMonth'], equals('2024-01'));
        expect(firestoreData['isComplete'], isTrue);
        expect(firestoreData['hasWarnings'], isFalse);
        expect(firestoreData['hasErrors'], isFalse);
      });

      test('should include timestamp field', () {
        final logEntry = HourlyReadingMapper.mapToLogEntry(
          projectId: testProjectId,
          projectName: testProjectName,
          date: testDate,
          hour: testHour,
          formData: sampleFormData,
          userId: testUserId,
        );

        final firestoreData = HourlyReadingMapper.mapToFirestore(logEntry);
        final timestamp = firestoreData['timestamp'] as DateTime;

        expect(timestamp.year, equals(2024));
        expect(timestamp.month, equals(1));
        expect(timestamp.day, equals(15));
        expect(timestamp.hour, equals(14));
        expect(timestamp.minute, equals(0));
      });

      test('should calculate week number correctly', () {
        final logEntry = HourlyReadingMapper.mapToLogEntry(
          projectId: testProjectId,
          projectName: testProjectName,
          date: testDate,
          hour: testHour,
          formData: sampleFormData,
          userId: testUserId,
        );

        final firestoreData = HourlyReadingMapper.mapToFirestore(logEntry);
        expect(firestoreData['weekNumber'], isA<int>());
        expect(firestoreData['weekNumber'], greaterThan(0));
      });
    });

    group('mapFromFirestore', () {
      test('should convert Firestore data back to LogEntry', () {
        final firestoreData = {
          'id': 'test_id_001',
          'projectId': testProjectId,
          'projectName': testProjectName,
          'date': '2024-01-15',
          'hour': '14',
          'data': sampleFormData,
          'status': 'completed',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'createdBy': testUserId,
          'syncTimestamp': DateTime.now().toIso8601String(),
        };

        final logEntry = HourlyReadingMapper.mapFromFirestore(firestoreData);

        expect(logEntry.id, equals('test_id_001'));
        expect(logEntry.projectId, equals(testProjectId));
        expect(logEntry.projectName, equals(testProjectName));
        expect(logEntry.date, equals('2024-01-15'));
        expect(logEntry.hour, equals('14'));
        expect(logEntry.status, equals('completed'));
        expect(logEntry.createdBy, equals(testUserId));
        expect(logEntry.isSynced, isTrue);
      });

      test('should handle missing fields with defaults', () {
        final minimalData = {
          'id': 'test_id_001',
        };

        final logEntry = HourlyReadingMapper.mapFromFirestore(minimalData);

        expect(logEntry.id, equals('test_id_001'));
        expect(logEntry.projectId, equals(''));
        expect(logEntry.status, equals('pending'));
        expect(logEntry.data, isA<Map<String, dynamic>>());
      });
    });

    group('createDailyBatch', () {
      test('should create 24 hourly entries for a day', () {
        final entries = HourlyReadingMapper.createDailyBatch(
          projectId: testProjectId,
          projectName: testProjectName,
          date: testDate,
          userId: testUserId,
        );

        expect(entries.length, equals(24));

        for (int i = 0; i < 24; i++) {
          final entry = entries[i];
          expect(entry.projectId, equals(testProjectId));
          expect(entry.projectName, equals(testProjectName));
          expect(entry.date, equals('2024-01-15'));
          expect(entry.hour, equals(i.toString().padLeft(2, '0')));
          expect(entry.status, equals('pending'));
          expect(entry.createdBy, equals(testUserId));
        }
      });

      test('should include template name when provided', () {
        const templateName = 'methane_h2s_hourly';
        final entries = HourlyReadingMapper.createDailyBatch(
          projectId: testProjectId,
          projectName: testProjectName,
          date: testDate,
          userId: testUserId,
          templateName: templateName,
        );

        for (final entry in entries) {
          expect(entry.data['template'], equals(templateName));
        }
      });
    });

    group('Edge cases', () {
      test('should handle string numbers in form data', () {
        final stringData = {
          'inlet_reading': '120.5',
          'outlet_reading': '115.3',
          'exhaust_temperature': '950',
        };

        final logEntry = HourlyReadingMapper.mapToLogEntry(
          projectId: testProjectId,
          projectName: testProjectName,
          date: testDate,
          hour: testHour,
          formData: stringData,
          userId: testUserId,
        );

        final thermalReading = HourlyReadingMapper.mapToThermalReading(logEntry);

        // The mapper doesn't auto-convert strings to doubles in the current implementation
        // You might want to enhance this based on your needs
        expect(logEntry.data['inlet_reading'], equals('120.5'));
      });

      test('should detect warnings for out-of-range values', () {
        final warningData = {
          'inlet_reading': 1500.0, // Out of range
          'outlet_reading': 115.3,
          'exhaust_temperature': 950.0,
        };

        final logEntry = HourlyReadingMapper.mapToLogEntry(
          projectId: testProjectId,
          projectName: testProjectName,
          date: testDate,
          hour: testHour,
          formData: warningData,
          userId: testUserId,
        );

        final firestoreData = HourlyReadingMapper.mapToFirestore(logEntry);
        expect(firestoreData['hasWarnings'], isTrue);
      });

      test('should detect errors when validation flag is set', () {
        final errorData = {
          'inlet_reading': 120.5,
          'outlet_reading': 115.3,
          'exhaust_temperature': 950.0,
          'validation': {
            'has_errors': true,
            'error_messages': ['Validation error occurred'],
          },
        };

        final logEntry = HourlyReadingMapper.mapToLogEntry(
          projectId: testProjectId,
          projectName: testProjectName,
          date: testDate,
          hour: testHour,
          formData: errorData,
          userId: testUserId,
        );

        expect(logEntry.status, equals('error'));

        final firestoreData = HourlyReadingMapper.mapToFirestore(logEntry);
        expect(firestoreData['hasErrors'], isTrue);
      });

      test('should set pending status for missing all required fields', () {
        final incompleteData = {
          'observations': 'Test observation',
          // Missing all required fields
        };

        final logEntry = HourlyReadingMapper.mapToLogEntry(
          projectId: testProjectId,
          projectName: testProjectName,
          date: testDate,
          hour: testHour,
          formData: incompleteData,
          userId: testUserId,
        );

        expect(logEntry.status, equals('pending'));

        final firestoreData = HourlyReadingMapper.mapToFirestore(logEntry);
        expect(firestoreData['hasErrors'], isFalse); // No validation errors, just missing data
      });

      test('should set partial status for some missing required fields', () {
        final partialData = {
          'exhaust_temperature': 950.0,
          // Missing inlet_reading and outlet_reading
        };

        final logEntry = HourlyReadingMapper.mapToLogEntry(
          projectId: testProjectId,
          projectName: testProjectName,
          date: testDate,
          hour: testHour,
          formData: partialData,
          userId: testUserId,
        );

        expect(logEntry.status, equals('partial'));

        final firestoreData = HourlyReadingMapper.mapToFirestore(logEntry);
        expect(firestoreData['hasErrors'], isFalse); // No validation errors, just missing data
      });
    });
  });
}