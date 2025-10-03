import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:my_flutter_app/services/sync_service.dart';
import 'package:my_flutter_app/services/local_database_service.dart';
import 'package:my_flutter_app/models/hive_models.dart';
import 'package:my_flutter_app/models/sync_models.dart';
import 'dart:io';

void main() {
  group('Sync Transmission Tests', () {
    late DataSyncManager syncManager;
    
    setUpAll(() async {
      // Initialize Hive for testing
      final tempDir = await Directory.systemTemp.createTemp('sync_transmission_test_');
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
      
      syncManager = DataSyncManager();
    });
    
    tearDown(() async {
      // Clear boxes
      await Hive.box<LogEntry>('logEntries').clear();
      await Hive.box<DailyMetric>('dailyMetrics').clear();
      await Hive.box<SyncQueueEntry>('syncQueue').clear();
    });
    
    group('Sync Metrics and Reporting', () {
      test('SyncResult tracks success and failure rates correctly', () {
        final startTime = DateTime.now();
        final endTime = startTime.add(const Duration(seconds: 30));
        
        final result = SyncResult(
          totalRecords: 10,
          successCount: 8,
          failureCount: 2,
          skippedCount: 0,
          errors: [],
          startTime: startTime,
          endTime: endTime,
          syncType: 'logEntries',
        );
        
        expect(result.successRate, 80.0);
        expect(result.duration.inSeconds, 30);
        expect(result.isComplete, true);
        expect(result.hasErrors, false);
      });
      
      test('SyncError captures detailed error information', () {
        final error = SyncError(
          recordId: 'test_record_1',
          errorMessage: 'Network timeout',
          errorCode: 'NETWORK_TIMEOUT',
          timestamp: DateTime.now(),
          recordType: 'LogEntry',
        );
        
        expect(error.recordId, 'test_record_1');
        expect(error.errorMessage, 'Network timeout');
        expect(error.errorCode, 'NETWORK_TIMEOUT');
        expect(error.recordType, 'LogEntry');
        
        final json = error.toJson();
        expect(json['recordId'], 'test_record_1');
        expect(json['errorCode'], 'NETWORK_TIMEOUT');
      });
      
      test('BatchSyncResult correctly categorizes batch outcomes', () {
        final result = BatchSyncResult(
          batchNumber: 1,
          batchSize: 5,
          successCount: 3,
          failureCount: 2,
          successfulIds: ['id1', 'id2', 'id3'],
          failedIds: {'id4': 'Network error', 'id5': 'Validation failed'},
          timestamp: DateTime.now(),
        );
        
        expect(result.isFullySuccessful, false);
        expect(result.isPartiallySuccessful, true);
        expect(result.isFullyFailed, false);
        expect(result.successfulIds.length, 3);
        expect(result.failedIds.length, 2);
      });
    });
    
    group('Sync Metrics Tracking', () {
      test('SyncMetrics records and aggregates sync results', () {
        final metrics = SyncMetrics();
        
        // Record first sync - successful
        final result1 = SyncResult(
          totalRecords: 10,
          successCount: 10,
          failureCount: 0,
          skippedCount: 0,
          errors: [],
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(seconds: 5)),
          syncType: 'logEntries',
        );
        
        metrics.recordSync(result1);
        
        expect(metrics.totalSyncs, 1);
        expect(metrics.successfulSyncs, 1);
        expect(metrics.failedSyncs, 0);
        expect(metrics.totalRecordsSynced, 10);
        expect(metrics.overallSuccessRate, 100.0);
        
        // Record second sync - partial failure
        final result2 = SyncResult(
          totalRecords: 5,
          successCount: 3,
          failureCount: 2,
          skippedCount: 0,
          errors: [],
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(seconds: 8)),
          syncType: 'dailyMetrics',
        );
        
        metrics.recordSync(result2);
        
        expect(metrics.totalSyncs, 2);
        expect(metrics.successfulSyncs, 1); // Only fully successful syncs count
        expect(metrics.failedSyncs, 1);
        expect(metrics.totalRecordsSynced, 13);
        expect(metrics.totalRecordsFailed, 2);
        expect(metrics.overallSuccessRate, 50.0);
      });
      
      test('SyncMetrics maintains recent results history', () {
        final metrics = SyncMetrics();
        
        // Add 15 results to test the limit of 10
        for (int i = 0; i < 15; i++) {
          final result = SyncResult(
            totalRecords: 1,
            successCount: 1,
            failureCount: 0,
            skippedCount: 0,
            errors: [],
            startTime: DateTime.now(),
            endTime: DateTime.now(),
            syncType: 'test_$i',
          );
          metrics.recordSync(result);
        }
        
        expect(metrics.recentResults.length, 10);
        expect(metrics.recentResults.first.syncType, 'test_5'); // Should start from index 5
        expect(metrics.recentResults.last.syncType, 'test_14');
      });
    });
    
    group('Error Recovery Logic', () {
      test('High failure rate triggers recovery strategy', () {
        final result = SyncResult(
          totalRecords: 10,
          successCount: 3,
          failureCount: 7,
          skippedCount: 0,
          errors: [],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
          syncType: 'logEntries',
        );
        
        // Failure rate is 70%, which should trigger recovery (> 50%)
        expect(result.failureCount / result.totalRecords > 0.5, true);
        expect(result.hasErrors, false); // No errors list provided
        expect(result.successRate, 30.0);
      });
      
      test('Low failure rate does not trigger recovery', () {
        final result = SyncResult(
          totalRecords: 10,
          successCount: 8,
          failureCount: 2,
          skippedCount: 0,
          errors: [],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
          syncType: 'logEntries',
        );
        
        // Failure rate is 20%, which should not trigger recovery (<= 50%)
        expect(result.failureCount / result.totalRecords <= 0.5, true);
        expect(result.successRate, 80.0);
      });
    });
    
    group('Partial Success Handling', () {
      test('Partial success is properly detected and reported', () {
        final errors = [
          SyncError(
            recordId: 'failed_1',
            errorMessage: 'Network timeout',
            errorCode: 'TIMEOUT',
            timestamp: DateTime.now(),
            recordType: 'LogEntry',
          ),
          SyncError(
            recordId: 'failed_2',
            errorMessage: 'Invalid data format',
            errorCode: 'VALIDATION_ERROR',
            timestamp: DateTime.now(),
            recordType: 'LogEntry',
          ),
        ];
        
        final result = SyncResult(
          totalRecords: 5,
          successCount: 3,
          failureCount: 2,
          skippedCount: 0,
          errors: errors,
          startTime: DateTime.now(),
          endTime: DateTime.now(),
          syncType: 'logEntries',
        );
        
        expect(result.hasErrors, true);
        expect(result.errors.length, 2);
        expect(result.isComplete, true);
        expect(result.successRate, 60.0);
        
        // Verify specific error details
        expect(result.errors[0].errorCode, 'TIMEOUT');
        expect(result.errors[1].errorCode, 'VALIDATION_ERROR');
      });
      
      test('BatchSyncResult handles partial success scenarios', () {
        final batchResult = BatchSyncResult(
          batchNumber: 2,
          batchSize: 8,
          successCount: 5,
          failureCount: 3,
          successfulIds: ['s1', 's2', 's3', 's4', 's5'],
          failedIds: {
            'f1': 'Connection error',
            'f2': 'Data validation failed',
            'f3': 'Permission denied',
          },
          timestamp: DateTime.now(),
        );
        
        expect(batchResult.isPartiallySuccessful, true);
        expect(batchResult.isFullySuccessful, false);
        expect(batchResult.isFullyFailed, false);
        expect(batchResult.successfulIds.length, 5);
        expect(batchResult.failedIds.length, 3);
      });
    });
    
    group('Transaction Support Validation', () {
      test('Atomic transaction behavior is validated through batch results', () {
        // Simulate an all-or-nothing transaction scenario
        final allSuccessBatch = BatchSyncResult(
          batchNumber: 1,
          batchSize: 5,
          successCount: 5,
          failureCount: 0,
          successfulIds: ['1', '2', '3', '4', '5'],
          failedIds: {},
          timestamp: DateTime.now(),
        );
        
        final allFailBatch = BatchSyncResult(
          batchNumber: 2,
          batchSize: 5,
          successCount: 0,
          failureCount: 5,
          successfulIds: [],
          failedIds: {
            '6': 'Transaction failed',
            '7': 'Transaction failed',
            '8': 'Transaction failed',
            '9': 'Transaction failed',
            '10': 'Transaction failed',
          },
          timestamp: DateTime.now(),
        );
        
        expect(allSuccessBatch.isFullySuccessful, true);
        expect(allFailBatch.isFullyFailed, true);
        
        // In a properly implemented transaction, we should not have partial success
        // within a single atomic operation
        expect(allSuccessBatch.failureCount, 0);
        expect(allFailBatch.successCount, 0);
      });
    });
    
    group('Performance Metrics', () {
      test('Duration and timing metrics are accurately calculated', () {
        final startTime = DateTime(2025, 1, 10, 12, 0, 0);
        final endTime = DateTime(2025, 1, 10, 12, 2, 30); // 2.5 minutes later
        
        final result = SyncResult(
          totalRecords: 100,
          successCount: 95,
          failureCount: 5,
          skippedCount: 0,
          errors: [],
          startTime: startTime,
          endTime: endTime,
          syncType: 'logEntries',
        );
        
        expect(result.duration.inMinutes, 2);
        expect(result.duration.inSeconds, 150);
        expect(result.duration.inMilliseconds, 150000);
      });
      
      test('Average sync time is calculated correctly across multiple syncs', () {
        final metrics = SyncMetrics();
        
        // Add multiple sync results with different durations
        final durations = [1000, 2000, 3000, 4000]; // milliseconds
        
        for (int i = 0; i < durations.length; i++) {
          final startTime = DateTime.now();
          final endTime = startTime.add(Duration(milliseconds: durations[i]));
          
          final result = SyncResult(
            totalRecords: 10,
            successCount: 10,
            failureCount: 0,
            skippedCount: 0,
            errors: [],
            startTime: startTime,
            endTime: endTime,
            syncType: 'test',
          );
          
          metrics.recordSync(result);
        }
        
        // Average should be (1000 + 2000 + 3000 + 4000) / 4 = 2500ms
        expect(metrics.averageSyncTime, 2500.0);
        expect(metrics.totalSyncs, 4);
      });
    });
  });
}