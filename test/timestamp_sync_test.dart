import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:my_flutter_app/services/local_database_service.dart';
import 'package:my_flutter_app/models/hive_models.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

void main() {
  group('Timestamp and Sync Tests', () {
    setUpAll(() async {
      // Initialize Hive for testing with a temporary directory
      final tempDir = await Directory.systemTemp.createTemp('hive_test_');
      Hive.init(tempDir.path);
      
      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(LogEntryAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(DailyMetricAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(UserSessionAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(CachedProjectAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(SyncQueueEntryAdapter());
      }
    });
    
    setUp(() async {
      // Open test boxes
      await Hive.openBox<LogEntry>('logEntries');
      await Hive.openBox<DailyMetric>('dailyMetrics');
      await Hive.openBox<SyncQueueEntry>('syncQueue');
    });
    
    tearDown(() async {
      // Clear boxes
      await Hive.box<LogEntry>('logEntries').clear();
      await Hive.box<DailyMetric>('dailyMetrics').clear();
      await Hive.box<SyncQueueEntry>('syncQueue').clear();
    });
    
    group('Timestamp Validation', () {
      test('validateSyncTimestamp rejects backdated timestamps', () {
        final createdAt = DateTime(2025, 1, 10, 12, 0);
        final backdatedTimestamp = DateTime(2025, 1, 9, 12, 0);
        
        final isValid = LocalDatabaseService.validateSyncTimestamp(
          backdatedTimestamp,
          createdAt,
        );
        
        expect(isValid, false);
      });
      
      test('validateSyncTimestamp accepts current timestamps', () {
        final createdAt = DateTime.now().subtract(const Duration(hours: 1));
        final currentTimestamp = DateTime.now();
        
        final isValid = LocalDatabaseService.validateSyncTimestamp(
          currentTimestamp,
          createdAt,
        );
        
        expect(isValid, true);
      });
      
      test('validateSyncTimestamp rejects future timestamps', () {
        final createdAt = DateTime.now();
        final futureTimestamp = DateTime.now().add(const Duration(hours: 2));
        
        final isValid = LocalDatabaseService.validateSyncTimestamp(
          futureTimestamp,
          createdAt,
        );
        
        expect(isValid, false);
      });
      
      test('validateSyncTimestamp accepts timestamps within 1-minute tolerance', () {
        final createdAt = DateTime.now();
        final slightlyFutureTimestamp = DateTime.now().add(const Duration(seconds: 30));
        
        final isValid = LocalDatabaseService.validateSyncTimestamp(
          slightlyFutureTimestamp,
          createdAt,
        );
        
        expect(isValid, true);
      });
      
      test('validateSyncTimestamp rejects null timestamps', () {
        final createdAt = DateTime.now();
        
        final isValid = LocalDatabaseService.validateSyncTimestamp(
          null,
          createdAt,
        );
        
        expect(isValid, false);
      });
    });
    
    group('Batch Retrieval with Timestamping', () {
      test('getUnsyncedLogEntriesBatch adds syncTimestamp to entries', () async {
        // Create test entries
        final entry1 = LogEntry(
          id: 'test_1',
          projectId: 'project_1',
          projectName: 'Test Project',
          date: '2025-01-10',
          hour: '14:00',
          data: {'temp': 25.5},
          status: 'completed',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          updatedAt: DateTime.now(),
          createdBy: 'test_user',
          isSynced: false,
        );
        
        final entry2 = LogEntry(
          id: 'test_2',
          projectId: 'project_1',
          projectName: 'Test Project',
          date: '2025-01-10',
          hour: '15:00',
          data: {'temp': 26.0},
          status: 'completed',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          updatedAt: DateTime.now(),
          createdBy: 'test_user',
          isSynced: false,
        );
        
        await LocalDatabaseService.saveLogEntry(entry1);
        await LocalDatabaseService.saveLogEntry(entry2);
        
        // Get batch with timestamp preparation
        final batch = await LocalDatabaseService.getUnsyncedLogEntriesBatch(
          batchSize: 10,
          prepareForSync: true,
        );
        
        expect(batch.length, 2);
        expect(batch[0].syncTimestamp, isNotNull);
        expect(batch[1].syncTimestamp, isNotNull);
        
        // Verify timestamps are current
        final now = DateTime.now();
        expect(batch[0].syncTimestamp!.difference(now).inSeconds.abs(), lessThan(5));
        expect(batch[1].syncTimestamp!.difference(now).inSeconds.abs(), lessThan(5));
      });
      
      test('getUnsyncedLogEntriesBatch respects batch size', () async {
        // Create multiple test entries
        for (int i = 0; i < 10; i++) {
          final entry = LogEntry(
            id: 'test_$i',
            projectId: 'project_1',
            projectName: 'Test Project',
            date: '2025-01-10',
            hour: '${14 + i}:00',
            data: {'temp': 25.0 + i},
            status: 'completed',
            createdAt: DateTime.now().subtract(Duration(hours: 10 - i)),
            updatedAt: DateTime.now(),
            createdBy: 'test_user',
            isSynced: false,
          );
          await LocalDatabaseService.saveLogEntry(entry);
        }
        
        // Get batch with limit
        final batch = await LocalDatabaseService.getUnsyncedLogEntriesBatch(
          batchSize: 5,
          prepareForSync: false,
        );
        
        expect(batch.length, 5);
      });
      
      test('getUnsyncedDailyMetricsBatch adds syncTimestamp to metrics', () async {
        // Create test metric
        final metric = DailyMetric(
          id: 'metric_1',
          projectId: 'project_1',
          date: '2025-01-10',
          totalEntries: 24,
          completedEntries: 20,
          completionStatus: 'partial',
          summary: {'avgTemp': 25.5},
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          updatedAt: DateTime.now(),
          createdBy: 'test_user',
          isSynced: false,
        );
        
        await LocalDatabaseService.saveDailyMetric(metric);
        
        // Get batch with timestamp preparation
        final batch = await LocalDatabaseService.getUnsyncedDailyMetricsBatch(
          batchSize: 10,
          prepareForSync: true,
        );
        
        expect(batch.length, 1);
        expect(batch[0].syncTimestamp, isNotNull);
        
        // Verify timestamp is current
        final now = DateTime.now();
        expect(batch[0].syncTimestamp!.difference(now).inSeconds.abs(), lessThan(5));
      });
    });
    
    group('Sync Status Updates', () {
      test('updateLogEntrySyncStatus adds syncTimestamp when marking as synced', () async {
        // Create test entry
        final entry = LogEntry(
          id: 'test_sync_1',
          projectId: 'project_1',
          projectName: 'Test Project',
          date: '2025-01-10',
          hour: '14:00',
          data: {'temp': 25.5},
          status: 'completed',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          updatedAt: DateTime.now(),
          createdBy: 'test_user',
          isSynced: false,
        );
        
        await LocalDatabaseService.saveLogEntry(entry);
        
        // Mark as synced
        await LocalDatabaseService.updateLogEntrySyncStatus('test_sync_1', true);
        
        // Retrieve and verify
        final updatedEntry = await LocalDatabaseService.getLogEntry('test_sync_1');
        expect(updatedEntry?.isSynced, true);
        expect(updatedEntry?.syncTimestamp, isNotNull);
      });
      
      test('updateLogEntrySyncStatus preserves error message', () async {
        // Create test entry
        final entry = LogEntry(
          id: 'test_error_1',
          projectId: 'project_1',
          projectName: 'Test Project',
          date: '2025-01-10',
          hour: '14:00',
          data: {'temp': 25.5},
          status: 'completed',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          updatedAt: DateTime.now(),
          createdBy: 'test_user',
          isSynced: false,
        );
        
        await LocalDatabaseService.saveLogEntry(entry);
        
        // Mark as failed with error
        await LocalDatabaseService.updateLogEntrySyncStatus(
          'test_error_1',
          false,
          'Network error',
        );
        
        // Retrieve and verify
        final updatedEntry = await LocalDatabaseService.getLogEntry('test_error_1');
        expect(updatedEntry?.isSynced, false);
        expect(updatedEntry?.syncError, 'Network error');
      });
    });
    
    group('No Backdating Enforcement', () {
      test('Entries cannot have syncTimestamp before createdAt', () async {
        final createdAt = DateTime(2025, 1, 10, 12, 0);
        final entry = LogEntry(
          id: 'backdate_test_1',
          projectId: 'project_1',
          projectName: 'Test Project',
          date: '2025-01-10',
          hour: '12:00',
          data: {'temp': 25.5},
          status: 'completed',
          createdAt: createdAt,
          updatedAt: createdAt,
          createdBy: 'test_user',
          isSynced: false,
          syncTimestamp: DateTime(2025, 1, 9, 12, 0), // Backdated
        );
        
        // Validate timestamp
        final isValid = LocalDatabaseService.validateSyncTimestamp(
          entry.syncTimestamp,
          entry.createdAt,
        );
        
        expect(isValid, false);
      });
      
      test('Batch retrieval ensures all timestamps are current', () async {
        // Create entries with various creation times
        for (int i = 0; i < 5; i++) {
          final entry = LogEntry(
            id: 'batch_time_$i',
            projectId: 'project_1',
            projectName: 'Test Project',
            date: '2025-01-10',
            hour: '${14 + i}:00',
            data: {'temp': 25.0 + i},
            status: 'completed',
            createdAt: DateTime.now().subtract(Duration(days: i + 1)),
            updatedAt: DateTime.now(),
            createdBy: 'test_user',
            isSynced: false,
          );
          await LocalDatabaseService.saveLogEntry(entry);
        }
        
        // Get batch with timestamp preparation
        final beforeBatch = DateTime.now();
        final batch = await LocalDatabaseService.getUnsyncedLogEntriesBatch(
          batchSize: 10,
          prepareForSync: true,
        );
        final afterBatch = DateTime.now();
        
        // All timestamps should be between beforeBatch and afterBatch
        for (final entry in batch) {
          expect(entry.syncTimestamp, isNotNull);
          expect(entry.syncTimestamp!.isAfter(beforeBatch) || 
                 entry.syncTimestamp!.isAtSameMomentAs(beforeBatch), true);
          expect(entry.syncTimestamp!.isBefore(afterBatch) || 
                 entry.syncTimestamp!.isAtSameMomentAs(afterBatch), true);
          
          // And always after creation time
          expect(entry.syncTimestamp!.isAfter(entry.createdAt) || 
                 entry.syncTimestamp!.isAtSameMomentAs(entry.createdAt), true);
        }
      });
    });
  });
}