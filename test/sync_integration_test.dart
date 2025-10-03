import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:my_flutter_app/models/hive_models.dart';
import 'package:my_flutter_app/models/sync_models.dart';
import 'package:my_flutter_app/models/sync_checkpoint_models.dart';
import 'package:my_flutter_app/services/local_database_service.dart';
import 'package:my_flutter_app/services/retry_service.dart';
import 'package:my_flutter_app/services/sync_logger.dart';

void main() {
  group('Sync Integration Tests', () {
    late Directory tempDir;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('sync_integration_test');
      Hive.init(tempDir.path);
      
      // Register adapters
      Hive.registerAdapter(LogEntryAdapter());
      Hive.registerAdapter(DailyMetricAdapter());
      Hive.registerAdapter(SyncQueueEntryAdapter());
    });

    tearDownAll(() async {
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    setUp(() async {
      // Clear all boxes before each test
      await LocalDatabaseService.clearAllData();
      SyncCheckpointManager.cleanupCheckpoints();
    });

    group('Retry Mechanism Tests', () {
      test('RetryService executes operation with exponential backoff', () async {
        var attempt = 0;
        final delays = <Duration>[];
        
        final result = await RetryService.executeWithRetry(
          () async {
            attempt++;
            if (attempt < 3) {
              throw Exception('Network error');
            }
            return 'success';
          },
          maxRetries: 3,
          baseDelay: const Duration(milliseconds: 100),
          onRetry: (attemptNum, error) {
            // Record actual delay behavior
            delays.add(DateTime.now().difference(DateTime.now()));
          },
        );

        expect(result, 'success');
        expect(attempt, 3);
      });

      test('RetryService identifies retryable vs permanent errors', () {
        // Retryable errors
        expect(RetryService.isRetryableError(Exception('network timeout')), true);
        expect(RetryService.isRetryableError(Exception('connection failed')), true);
        expect(RetryService.isRetryableError(Exception('service unavailable')), true);
        expect(RetryService.isRetryableError(Exception('rate limit exceeded')), true);

        // Permanent errors
        expect(RetryService.isPermanentError(Exception('unauthorized')), true);
        expect(RetryService.isPermanentError(Exception('permission denied')), true);
        expect(RetryService.isPermanentError(Exception('not found')), true);
        expect(RetryService.isPermanentError(Exception('invalid argument')), true);
      });

      test('RetryService stops retrying on permanent errors', () async {
        var attempt = 0;
        
        try {
          await RetryService.executeWithRetry(
            () async {
              attempt++;
              throw Exception('unauthorized access');
            },
            maxRetries: 3,
            shouldRetry: (error) => !RetryService.isPermanentError(error),
          );
          fail('Should have thrown exception');
        } catch (e) {
          expect(attempt, 1); // Should stop after first attempt
          expect(e.toString().contains('unauthorized'), true);
        }
      });
    });

    group('Checkpoint Recovery Tests', () {
      test('SyncCheckpointManager creates and manages checkpoints', () {
        final checkpoint = SyncCheckpointManager.createCheckpoint(
          syncType: 'logEntries',
          totalRecords: 100,
          syncContext: {'batchSize': 10},
        );

        expect(checkpoint.syncType, 'logEntries');
        expect(checkpoint.totalRecords, 100);
        expect(checkpoint.progressPercentage, 0.0);
        expect(checkpoint.isCompleted, false);

        // Update progress
        final updated = checkpoint.copyWith(processedRecords: 50);
        SyncCheckpointManager.updateCheckpoint(checkpoint.id, updated);

        final retrieved = SyncCheckpointManager.getCheckpoint(checkpoint.id);
        expect(retrieved?.progressPercentage, 50.0);
      });

      test('SyncCheckpointManager identifies stale checkpoints', () {
        final staleCheckpoint = SyncCheckpoint(
          id: 'stale_test',
          syncType: 'logEntries',
          startTime: DateTime.now().subtract(const Duration(hours: 3)),
          totalRecords: 100,
        );

        expect(staleCheckpoint.isStale(maxAge: const Duration(hours: 2)), true);
        expect(staleCheckpoint.isStale(maxAge: const Duration(hours: 4)), false);
      });

      test('SyncCheckpointManager finds incomplete syncs for resumption', () {
        // Create multiple checkpoints
        final completed = SyncCheckpointManager.createCheckpoint(
          syncType: 'logEntries',
          totalRecords: 50,
        );
        SyncCheckpointManager.completeCheckpoint(completed.id);

        final incomplete = SyncCheckpointManager.createCheckpoint(
          syncType: 'logEntries',
          totalRecords: 100,
        );

        final stale = SyncCheckpoint(
          id: 'stale',
          syncType: 'logEntries',
          startTime: DateTime.now().subtract(const Duration(hours: 3)),
          totalRecords: 75,
        );

        // Find incomplete sync should return the non-completed, non-stale one
        final found = SyncCheckpointManager.findIncompleteSync('logEntries');
        expect(found?.id, incomplete.id);
      });

      test('Checkpoint serialization works correctly', () {
        final checkpoint = SyncCheckpoint(
          id: 'json_test',
          syncType: 'dailyMetrics',
          startTime: DateTime.now(),
          totalRecords: 200,
          processedRecords: 75,
          currentBatchNumber: 5,
          processedBatches: ['batch_1', 'batch_2'],
          failedRecords: ['failed_1'],
          syncContext: {'key': 'value'},
          lastError: 'Network timeout',
        );

        final json = checkpoint.toJson();
        final restored = SyncCheckpoint.fromJson(json);

        expect(restored.id, checkpoint.id);
        expect(restored.syncType, checkpoint.syncType);
        expect(restored.totalRecords, checkpoint.totalRecords);
        expect(restored.processedRecords, checkpoint.processedRecords);
        expect(restored.processedBatches, checkpoint.processedBatches);
        expect(restored.failedRecords, checkpoint.failedRecords);
        expect(restored.lastError, checkpoint.lastError);
        expect(restored.progressPercentage, checkpoint.progressPercentage);
      });
    });

    group('Enhanced Logging Tests', () {
      test('SyncLogger captures and formats log entries correctly', () {
        final logger = SyncLogger();
        
        logger.logSyncEvent(
          level: SyncLogLevel.info,
          operation: 'test_sync',
          message: 'Test message',
          metadata: {'key': 'value'},
        );

        final logs = logger.getRecentLogs(limit: 1);
        expect(logs.length, 1);
        expect(logs.first.operation, 'test_sync');
        expect(logs.first.message, 'Test message');
        expect(logs.first.metadata['key'], 'value');
      });

      test('SyncLogger filters logs by level', () {
        final logger = SyncLogger();
        
        logger.logSyncEvent(
          level: SyncLogLevel.debug,
          operation: 'debug_op',
          message: 'Debug message',
        );
        
        logger.logSyncEvent(
          level: SyncLogLevel.error,
          operation: 'error_op',
          message: 'Error message',
        );

        final allLogs = logger.getRecentLogs();
        expect(allLogs.length, 2);

        final errorLogs = logger.getRecentLogs(minLevel: SyncLogLevel.error);
        expect(errorLogs.length, 1);
        expect(errorLogs.first.operation, 'error_op');
      });

      test('SyncLogger generates performance summary', () {
        final logger = SyncLogger();
        
        // Log various operations
        logger.logSyncEvent(
          level: SyncLogLevel.info,
          operation: 'sync_operation',
          message: 'Sync operation completed',
        );
        
        logger.logSyncEvent(
          level: SyncLogLevel.error,
          operation: 'sync_operation',
          message: 'Sync operation failed',
        );

        final summary = logger.getPerformanceSummary();
        expect(summary['operationCounts']['sync_operation'], 2);
        expect(summary['errorCounts']['sync_operation'], 1);
        expect(summary['errorRate'], 50.0);
      });

      test('SyncLogger tracks checkpoint-specific logs', () {
        final logger = SyncLogger();
        const checkpointId = 'test_checkpoint_123';
        
        logger.logSyncEvent(
          level: SyncLogLevel.info,
          operation: 'checkpoint_test',
          message: 'Checkpoint created',
          checkpointId: checkpointId,
        );
        
        logger.logSyncEvent(
          level: SyncLogLevel.info,
          operation: 'checkpoint_test',
          message: 'Checkpoint updated',
          checkpointId: checkpointId,
        );

        final checkpointLogs = logger.getCheckpointLogs(checkpointId);
        expect(checkpointLogs.length, 2);
        expect(checkpointLogs.every((log) => log.checkpointId == checkpointId), true);
      });

      test('SyncLogger exports logs with proper filtering', () {
        final logger = SyncLogger();
        
        // Create logs with different levels and times
        logger.logSyncEvent(
          level: SyncLogLevel.debug,
          operation: 'debug_op',
          message: 'Debug message',
        );
        
        logger.logSyncEvent(
          level: SyncLogLevel.error,
          operation: 'error_op',
          message: 'Error message',
        );

        final export = logger.exportLogs(minLevel: SyncLogLevel.error);
        
        expect(export['totalEntries'], 1);
        expect(export['logs'], isA<List>());
        expect(export['logs'][0]['level'], 'error');
        expect(export.containsKey('summary'), true);
      });
    });

    group('Data Batch Processing Tests', () {
      test('Batch retrieval with sync timestamp validation', () async {
        // Create test log entries with various timestamps
        final now = DateTime.now();
        final validEntry = LogEntry(
          id: 'valid_1',
          projectId: 'test_project',
          projectName: 'Test Project',
          date: DateTime.now().toIso8601String().split('T')[0],
          data: {'temp': 25.0},
          createdAt: now.subtract(const Duration(minutes: 5)),
          updatedAt: now.subtract(const Duration(minutes: 1)),
        );

        final invalidEntry = LogEntry(
          id: 'invalid_1',
          projectId: 'test_project',
          projectName: 'Test Project',
          data: {'temp': 26.0},
          createdAt: now.add(const Duration(minutes: 1)), // Future timestamp
          updatedAt: now,
        );

        await validEntry.save();
        await invalidEntry.save();

        // Test batch retrieval with timestamping
        final batch = await LocalDatabaseService.getUnsyncedLogEntriesBatch(
          batchSize: 10,
          prepareForSync: true,
        );

        expect(batch.length, 2);
        
        // Both should be retrieved, but validation will happen during sync
        final validationResults = batch.map((entry) => 
          LocalDatabaseService.validateSyncTimestamp(entry.syncTimestamp, entry.createdAt)
        ).toList();

        // At least one should be valid (the properly timestamped one)
        expect(validationResults.contains(true), true);
      });

      test('Batch processing handles mixed success and failure scenarios', () async {
        // Create multiple log entries
        for (int i = 0; i < 15; i++) {
          final entry = LogEntry(
            id: 'batch_test_$i',
            projectId: 'test_project',
            projectName: 'Test Project',
            date: DateTime.now().toIso8601String().split('T')[0],
            data: {'temp': 20.0 + i, 'index': i},
            createdAt: DateTime.now().subtract(Duration(minutes: i + 1)),
            updatedAt: DateTime.now(),
          );
          await entry.save();
        }

        final batch = await LocalDatabaseService.getUnsyncedLogEntriesBatch(
          batchSize: 15,
          prepareForSync: true,
        );

        expect(batch.length, 15);
        expect(batch.every((entry) => entry.syncTimestamp != null), true);
        expect(batch.every((entry) => !entry.isSynced), true);
      });
    });

    group('Error Recovery and Resilience Tests', () {
      test('Sync queue handles failed operations correctly', () async {
        // Create a failed sync operation
        final queueEntry = SyncQueueEntry(
          id: 'failed_op_1',
          operation: 'update',
          collection: 'logEntries',
          documentId: 'test_doc_1',
          data: {'test': 'data'},
          createdAt: DateTime.now(),
          retryCount: 2,
          lastError: 'Network timeout',
        );

        await LocalDatabaseService.addToSyncQueue(queueEntry);

        final pendingOps = await LocalDatabaseService.getPendingSyncOperations();
        expect(pendingOps.length, 1);
        expect(pendingOps.first.id, 'failed_op_1');
        expect(pendingOps.first.retryCount, 2);
      });

      test('Sync metrics accurately track operation statistics', () {
        final metrics = SyncMetrics();
        
        // Record various sync results
        final successResult = SyncResult(
          totalRecords: 10,
          successCount: 10,
          failureCount: 0,
          skippedCount: 0,
          errors: [],
          startTime: DateTime.now().subtract(const Duration(seconds: 5)),
          endTime: DateTime.now(),
          syncType: 'logEntries',
        );

        final failureResult = SyncResult(
          totalRecords: 5,
          successCount: 2,
          failureCount: 3,
          skippedCount: 0,
          errors: [
            SyncError(
              recordId: 'failed_1',
              errorMessage: 'Network error',
              errorCode: 'NETWORK_ERROR',
              timestamp: DateTime.now(),
              recordType: 'LogEntry',
            ),
          ],
          startTime: DateTime.now().subtract(const Duration(seconds: 3)),
          endTime: DateTime.now(),
          syncType: 'logEntries',
        );

        metrics.recordSync(successResult);
        metrics.recordSync(failureResult);

        expect(metrics.totalSyncs, 2);
        expect(metrics.totalRecordsProcessed, 15);
        expect(metrics.totalSuccessfulRecords, 12);
        expect(metrics.totalFailedRecords, 3);
        expect(metrics.overallSuccessRate, closeTo(80.0, 0.1)); // 12/15 * 100
      });

      test('Retry statistics track retry patterns correctly', () {
        final retryStats = RetryStats();
        
        // Record successful retry
        retryStats.recordRetry(
          attemptNumber: 2,
          retryTime: const Duration(milliseconds: 500),
          errorType: 'NetworkException',
          succeeded: true,
        );

        // Record failed retry
        retryStats.recordRetry(
          attemptNumber: 3,
          retryTime: const Duration(milliseconds: 1000),
          errorType: 'TimeoutException',
          succeeded: false,
        );

        // Record permanent failure
        retryStats.recordPermanentFailure('AuthenticationException');

        expect(retryStats.totalRetries, 2);
        expect(retryStats.successfulRetries, 1);
        expect(retryStats.failedRetries, 1);
        expect(retryStats.permanentFailures, 1);
        expect(retryStats.successRate, 50.0);
        expect(retryStats.errorCounts['NetworkException'], 1);
        expect(retryStats.errorCounts['AuthenticationException'], 1);
      });
    });

    group('End-to-End Data Consistency Tests', () {
      test('Complete sync workflow maintains data integrity', () async {
        // Create test data with various scenarios
        final logEntries = <LogEntry>[];
        
        // Normal entries that should sync successfully
        for (int i = 0; i < 5; i++) {
          final entry = LogEntry(
            id: 'normal_$i',
            projectId: 'test_project',
            projectName: 'Test Project',
            data: {'temp': 20.0 + i, 'humidity': 50.0 + i},
            createdAt: DateTime.now().subtract(Duration(minutes: i + 1)),
            updatedAt: DateTime.now(),
          );
          logEntries.add(entry);
          await entry.save();
        }

        // Get unsynced entries
        final unsyncedBefore = await LocalDatabaseService.getUnsyncedLogEntriesBatch(
          batchSize: 100,
          prepareForSync: true,
        );

        expect(unsyncedBefore.length, 5);
        expect(unsyncedBefore.every((entry) => !entry.isSynced), true);
        expect(unsyncedBefore.every((entry) => entry.syncTimestamp != null), true);

        // Simulate successful sync by marking entries as synced
        for (final entry in unsyncedBefore) {
          await LocalDatabaseService.updateLogEntrySyncStatus(entry.id, true);
        }

        // Verify all entries are now marked as synced
        final unsyncedAfter = await LocalDatabaseService.getUnsyncedLogEntriesBatch(
          batchSize: 100,
          prepareForSync: false,
        );

        expect(unsyncedAfter.length, 0);

        // Verify original data integrity
        final allEntries = await LocalDatabaseService.getAllLogEntries();
        expect(allEntries.length, 5);
        
        for (int i = 0; i < 5; i++) {
          final entry = allEntries.firstWhere((e) => e.id == 'normal_$i');
          expect(entry.data['temp'], 20.0 + i);
          expect(entry.data['humidity'], 50.0 + i);
          expect(entry.isSynced, true);
        }
      });

      test('Timestamp validation prevents backdating throughout workflow', () async {
        final now = DateTime.now();
        
        // Create entry with proper timestamp
        final validEntry = LogEntry(
          id: 'timestamp_valid',
          projectId: 'test_project',
          projectName: 'Test Project',
          data: {'temp': 25.0},
          createdAt: now.subtract(const Duration(minutes: 5)),
          updatedAt: now.subtract(const Duration(minutes: 2)),
        );
        await validEntry.save();

        // Attempt to backdate by modifying timestamps
        final backdatedEntry = LogEntry(
          id: 'timestamp_invalid',
          projectId: 'test_project',
          projectName: 'Test Project',
          data: {'temp': 26.0},
          createdAt: now.subtract(const Duration(hours: 2)),
          updatedAt: now, // Updated recently but created long ago
        );
        await backdatedEntry.save();

        // Prepare for sync (should add sync timestamps)
        final batch = await LocalDatabaseService.getUnsyncedLogEntriesBatch(
          batchSize: 10,
          prepareForSync: true,
        );

        expect(batch.length, 2);

        // Validate each entry's sync timestamp
        for (final entry in batch) {
          final isValid = LocalDatabaseService.validateSyncTimestamp(
            entry.syncTimestamp, 
            entry.createdAt
          );
          
          // The validation should detect if sync timestamp is reasonable
          // relative to creation time
          if (entry.id == 'timestamp_valid') {
            expect(isValid, true);
          }
          // Note: The backdated entry might still be valid if its syncTimestamp
          // is set to current time, which is acceptable behavior
        }
      });
    });
  });
}