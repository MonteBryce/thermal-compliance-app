import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../../lib/models/thermal_log.dart';
import '../../lib/models/hive_models.dart';
import '../../lib/services/thermal_log_service.dart';
import '../../lib/services/offline_storage_service.dart';

// Mock path provider for testing
class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return './test_temp_integration';
  }
}

void main() {
  group('ThermalLogService Integration Tests', () {
    setUpAll(() async {
      // Set up mock path provider
      PathProviderPlatform.instance = MockPathProviderPlatform();
      
      // Initialize Hive
      await Hive.initFlutter('test_integration');
    });

    tearDownAll(() async {
      await ThermalLogService.close();
    });

    test('should work with OfflineStorageService initialization', () async {
      // Initialize OfflineStorageService (which registers all adapters)
      await OfflineStorageService.initialize();
      
      // Create a test thermal log
      final testLog = ThermalLog(
        id: 'integration-test-1',
        timestamp: DateTime.now(),
        temperature: 78.5,
        notes: 'Integration test log',
        projectId: 'integration-project',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Use ThermalLogService to save the log
      await ThermalLogService.save(testLog);
      
      // Verify the log was saved correctly
      final retrievedLog = await ThermalLogService.getById(testLog.id);
      expect(retrievedLog, isNotNull);
      expect(retrievedLog!.id, equals(testLog.id));
      expect(retrievedLog.temperature, equals(testLog.temperature));
      expect(retrievedLog.notes, equals(testLog.notes));

      // Clean up
      await ThermalLogService.delete(testLog.id);
    });

    test('should coexist with other Hive models', () async {
      // Initialize OfflineStorageService
      await OfflineStorageService.initialize();
      
      // Create a test thermal log
      final testLog = ThermalLog(
        id: 'coexist-test-1',
        timestamp: DateTime.now(),
        temperature: 82.0,
        notes: 'Coexistence test log',
        projectId: 'coexist-project',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Create a test LogEntry (from hive_models.dart)
      final testEntry = LogEntry(
        id: 'coexist-entry-1',
        projectId: 'coexist-project',
        projectName: 'Test Project',
        date: '2024-01-15',
        hour: '14',
        data: {'temperature': 82.0, 'notes': 'Entry test'},
        status: 'draft',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'test-user',
      );

      // Save both types
      await ThermalLogService.save(testLog);
      
      // Save LogEntry using its box directly (simulating OfflineStorageService usage)
      final logEntriesBox = Hive.box<LogEntry>('logEntries');
      await logEntriesBox.put(testEntry.id, testEntry);
      
      // Verify both were saved correctly
      final retrievedLog = await ThermalLogService.getById(testLog.id);
      expect(retrievedLog, isNotNull);
      expect(retrievedLog!.temperature, equals(82.0));
      
      final retrievedEntry = logEntriesBox.get(testEntry.id);
      expect(retrievedEntry, isNotNull);
      expect(retrievedEntry!.projectName, equals('Test Project'));

      // Clean up
      await ThermalLogService.delete(testLog.id);
      await logEntriesBox.delete(testEntry.id);
    });
  });
}