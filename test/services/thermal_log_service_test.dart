import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../../lib/models/thermal_log.dart';
import '../../lib/services/thermal_log_service.dart';

// Mock path provider for testing
class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return './test_temp';
  }
}

void main() {
  group('ThermalLogService CRUD Tests', () {
    late ThermalLog testLog1;
    late ThermalLog testLog2;

    setUpAll(() async {
      // Set up mock path provider
      PathProviderPlatform.instance = MockPathProviderPlatform();
      
      // Initialize Hive
      await Hive.initFlutter('test_db');
      
      // Register adapters
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(ThermalLogAdapter());
      }
    });

    setUp(() async {
      // Clear any existing data before each test
      await ThermalLogService.clear();

      final now = DateTime.now();
      testLog1 = ThermalLog(
        id: 'test-log-1',
        timestamp: now,
        temperature: 75.5,
        notes: 'Test temperature reading 1',
        projectId: 'project-123',
        createdAt: now,
        updatedAt: now,
      );

      testLog2 = ThermalLog(
        id: 'test-log-2',
        timestamp: now.add(const Duration(hours: 1)),
        temperature: 80.0,
        notes: 'Test temperature reading 2',
        projectId: 'project-456',
        createdAt: now,
        updatedAt: now,
      );
    });

    tearDown(() async {
      // Clean up after each test
      await ThermalLogService.clear();
    });

    tearDownAll(() async {
      // Close service and cleanup
      await ThermalLogService.close();
    });

    test('should initialize service successfully', () async {
      await ThermalLogService.initialize();
      final count = await ThermalLogService.getCount();
      expect(count, equals(0));
    });

    test('should save a thermal log successfully', () async {
      await ThermalLogService.save(testLog1);
      
      final count = await ThermalLogService.getCount();
      expect(count, equals(1));

      final exists = await ThermalLogService.exists(testLog1.id);
      expect(exists, isTrue);
    });

    test('should retrieve thermal log by ID', () async {
      await ThermalLogService.save(testLog1);
      
      final retrievedLog = await ThermalLogService.getById(testLog1.id);
      
      expect(retrievedLog, isNotNull);
      expect(retrievedLog!.id, equals(testLog1.id));
      expect(retrievedLog.temperature, equals(testLog1.temperature));
      expect(retrievedLog.notes, equals(testLog1.notes));
      expect(retrievedLog.projectId, equals(testLog1.projectId));
    });

    test('should return null for non-existent ID', () async {
      final retrievedLog = await ThermalLogService.getById('non-existent-id');
      expect(retrievedLog, isNull);
    });

    test('should retrieve all thermal logs', () async {
      await ThermalLogService.save(testLog1);
      await ThermalLogService.save(testLog2);
      
      final allLogs = await ThermalLogService.getAll();
      
      expect(allLogs.length, equals(2));
      expect(allLogs.any((log) => log.id == testLog1.id), isTrue);
      expect(allLogs.any((log) => log.id == testLog2.id), isTrue);
    });

    test('should update existing thermal log', () async {
      // Save initial log
      await ThermalLogService.save(testLog1);
      
      // Create updated version
      final updatedLog = testLog1.copyWith(
        temperature: 85.0,
        notes: 'Updated temperature reading',
        updatedAt: DateTime.now(),
      );
      
      // Update the log
      await ThermalLogService.update(updatedLog);
      
      // Verify update
      final retrievedLog = await ThermalLogService.getById(testLog1.id);
      expect(retrievedLog, isNotNull);
      expect(retrievedLog!.temperature, equals(85.0));
      expect(retrievedLog.notes, equals('Updated temperature reading'));
      expect(retrievedLog.id, equals(testLog1.id)); // ID should remain same
    });

    test('should throw error when updating non-existent log', () async {
      expect(
        () => ThermalLogService.update(testLog1),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Thermal log with ID test-log-1 not found'),
        )),
      );
    });

    test('should delete thermal log by ID', () async {
      // Save log
      await ThermalLogService.save(testLog1);
      expect(await ThermalLogService.exists(testLog1.id), isTrue);
      
      // Delete log
      await ThermalLogService.delete(testLog1.id);
      
      // Verify deletion
      expect(await ThermalLogService.exists(testLog1.id), isFalse);
      final retrievedLog = await ThermalLogService.getById(testLog1.id);
      expect(retrievedLog, isNull);
    });

    test('should throw error when deleting non-existent log', () async {
      expect(
        () => ThermalLogService.delete('non-existent-id'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Thermal log with ID non-existent-id not found'),
        )),
      );
    });

    test('should clear all thermal logs', () async {
      // Save multiple logs
      await ThermalLogService.save(testLog1);
      await ThermalLogService.save(testLog2);
      expect(await ThermalLogService.getCount(), equals(2));
      
      // Clear all logs
      await ThermalLogService.clear();
      
      // Verify all cleared
      expect(await ThermalLogService.getCount(), equals(0));
      final allLogs = await ThermalLogService.getAll();
      expect(allLogs, isEmpty);
    });

    test('should get thermal logs by project ID', () async {
      // Save logs with different project IDs
      await ThermalLogService.save(testLog1); // project-123
      await ThermalLogService.save(testLog2); // project-456
      
      // Create another log for project-123
      final testLog3 = ThermalLog(
        id: 'test-log-3',
        timestamp: DateTime.now(),
        temperature: 72.0,
        notes: 'Another reading for project 123',
        projectId: 'project-123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await ThermalLogService.save(testLog3);
      
      // Get logs for project-123
      final project123Logs = await ThermalLogService.getByProjectId('project-123');
      expect(project123Logs.length, equals(2));
      expect(project123Logs.every((log) => log.projectId == 'project-123'), isTrue);
      
      // Get logs for project-456
      final project456Logs = await ThermalLogService.getByProjectId('project-456');
      expect(project456Logs.length, equals(1));
      expect(project456Logs.first.projectId, equals('project-456'));
    });

    test('should get correct count of thermal logs', () async {
      expect(await ThermalLogService.getCount(), equals(0));
      
      await ThermalLogService.save(testLog1);
      expect(await ThermalLogService.getCount(), equals(1));
      
      await ThermalLogService.save(testLog2);
      expect(await ThermalLogService.getCount(), equals(2));
      
      await ThermalLogService.delete(testLog1.id);
      expect(await ThermalLogService.getCount(), equals(1));
    });

    test('should handle save operation that overwrites existing log', () async {
      // Save initial log
      await ThermalLogService.save(testLog1);
      expect(await ThermalLogService.getCount(), equals(1));
      
      // Save log with same ID (should overwrite)
      final updatedLog = testLog1.copyWith(temperature: 90.0);
      await ThermalLogService.save(updatedLog);
      
      // Should still have only one log, but with updated data
      expect(await ThermalLogService.getCount(), equals(1));
      final retrievedLog = await ThermalLogService.getById(testLog1.id);
      expect(retrievedLog!.temperature, equals(90.0));
    });

    test('should persist data between service reinitializations', () async {
      // Save data
      await ThermalLogService.save(testLog1);
      expect(await ThermalLogService.exists(testLog1.id), isTrue);
      
      // Close service
      await ThermalLogService.close();
      
      // Reinitialize service
      await ThermalLogService.initialize();
      
      // Data should still exist
      expect(await ThermalLogService.exists(testLog1.id), isTrue);
      final retrievedLog = await ThermalLogService.getById(testLog1.id);
      expect(retrievedLog, isNotNull);
      expect(retrievedLog!.temperature, equals(testLog1.temperature));
    });
  });
}