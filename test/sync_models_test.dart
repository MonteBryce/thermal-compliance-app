import 'package:flutter_test/flutter_test.dart';
import 'package:my_flutter_app/models/sync_models.dart';

void main() {
  group('Sync Models Tests', () {
    group('SyncResult', () {
      test('calculates success rate correctly', () {
        final result = SyncResult(
          totalRecords: 10,
          successCount: 8,
          failureCount: 2,
          skippedCount: 0,
          errors: [],
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(seconds: 30)),
          syncType: 'logEntries',
        );
        
        expect(result.successRate, 80.0);
        expect(result.isComplete, true);
        expect(result.hasErrors, false);
      });
      
      test('handles zero records gracefully', () {
        final result = SyncResult(
          totalRecords: 0,
          successCount: 0,
          failureCount: 0,
          skippedCount: 0,
          errors: [],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
          syncType: 'logEntries',
        );
        
        expect(result.successRate, 0.0);
        expect(result.isComplete, true);
      });
      
      test('correctly identifies when there are errors', () {
        final errors = [
          SyncError(
            recordId: 'test_1',
            errorMessage: 'Test error',
            timestamp: DateTime.now(),
            recordType: 'LogEntry',
          ),
        ];
        
        final result = SyncResult(
          totalRecords: 5,
          successCount: 4,
          failureCount: 1,
          skippedCount: 0,
          errors: errors,
          startTime: DateTime.now(),
          endTime: DateTime.now(),
          syncType: 'logEntries',
        );
        
        expect(result.hasErrors, true);
        expect(result.errors.length, 1);
      });
      
      test('serializes to JSON correctly', () {
        final startTime = DateTime(2025, 1, 10, 12, 0);
        final endTime = DateTime(2025, 1, 10, 12, 1);
        
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
        
        final json = result.toJson();
        
        expect(json['totalRecords'], 10);
        expect(json['successCount'], 8);
        expect(json['failureCount'], 2);
        expect(json['successRate'], 80.0);
        expect(json['durationMs'], 60000); // 1 minute
        expect(json['syncType'], 'logEntries');
      });
    });
    
    group('SyncError', () {
      test('creates error with all required fields', () {
        final timestamp = DateTime.now();
        final error = SyncError(
          recordId: 'test_record_1',
          errorMessage: 'Network timeout occurred',
          errorCode: 'NETWORK_TIMEOUT',
          timestamp: timestamp,
          recordType: 'LogEntry',
        );
        
        expect(error.recordId, 'test_record_1');
        expect(error.errorMessage, 'Network timeout occurred');
        expect(error.errorCode, 'NETWORK_TIMEOUT');
        expect(error.timestamp, timestamp);
        expect(error.recordType, 'LogEntry');
      });
      
      test('serializes to JSON correctly', () {
        final timestamp = DateTime(2025, 1, 10, 12, 0);
        final error = SyncError(
          recordId: 'test_record_1',
          errorMessage: 'Validation failed',
          errorCode: 'VALIDATION_ERROR',
          timestamp: timestamp,
          recordType: 'DailyMetric',
        );
        
        final json = error.toJson();
        
        expect(json['recordId'], 'test_record_1');
        expect(json['errorMessage'], 'Validation failed');
        expect(json['errorCode'], 'VALIDATION_ERROR');
        expect(json['timestamp'], '2025-01-10T12:00:00.000');
        expect(json['recordType'], 'DailyMetric');
      });
      
      test('handles null error code', () {
        final error = SyncError(
          recordId: 'test_record_1',
          errorMessage: 'Generic error',
          timestamp: DateTime.now(),
          recordType: 'LogEntry',
        );
        
        expect(error.errorCode, null);
        final json = error.toJson();
        expect(json['errorCode'], null);
      });
    });
    
    group('BatchSyncResult', () {
      test('correctly categorizes full success', () {
        final result = BatchSyncResult(
          batchNumber: 1,
          batchSize: 5,
          successCount: 5,
          failureCount: 0,
          successfulIds: ['1', '2', '3', '4', '5'],
          failedIds: {},
          timestamp: DateTime.now(),
        );
        
        expect(result.isFullySuccessful, true);
        expect(result.isPartiallySuccessful, false);
        expect(result.isFullyFailed, false);
      });
      
      test('correctly categorizes partial success', () {
        final result = BatchSyncResult(
          batchNumber: 1,
          batchSize: 5,
          successCount: 3,
          failureCount: 2,
          successfulIds: ['1', '2', '3'],
          failedIds: {'4': 'Error 1', '5': 'Error 2'},
          timestamp: DateTime.now(),
        );
        
        expect(result.isFullySuccessful, false);
        expect(result.isPartiallySuccessful, true);
        expect(result.isFullyFailed, false);
      });
      
      test('correctly categorizes full failure', () {
        final result = BatchSyncResult(
          batchNumber: 1,
          batchSize: 3,
          successCount: 0,
          failureCount: 3,
          successfulIds: [],
          failedIds: {'1': 'Error 1', '2': 'Error 2', '3': 'Error 3'},
          timestamp: DateTime.now(),
        );
        
        expect(result.isFullySuccessful, false);
        expect(result.isPartiallySuccessful, false);
        expect(result.isFullyFailed, true);
      });
      
      test('serializes to JSON correctly', () {
        final timestamp = DateTime(2025, 1, 10, 12, 0);
        final result = BatchSyncResult(
          batchNumber: 2,
          batchSize: 4,
          successCount: 2,
          failureCount: 2,
          successfulIds: ['a', 'b'],
          failedIds: {'c': 'Error C', 'd': 'Error D'},
          timestamp: timestamp,
        );
        
        final json = result.toJson();
        
        expect(json['batchNumber'], 2);
        expect(json['batchSize'], 4);
        expect(json['successCount'], 2);
        expect(json['failureCount'], 2);
        expect(json['successfulIds'], ['a', 'b']);
        expect(json['failedIds'], {'c': 'Error C', 'd': 'Error D'});
        expect(json['timestamp'], '2025-01-10T12:00:00.000');
      });
    });
    
    group('SyncMetrics', () {
      test('tracks basic sync statistics', () {
        final metrics = SyncMetrics();
        
        expect(metrics.totalSyncs, 0);
        expect(metrics.successfulSyncs, 0);
        expect(metrics.failedSyncs, 0);
        expect(metrics.overallSuccessRate, 0.0);
      });
      
      test('records successful sync', () {
        final metrics = SyncMetrics();
        
        final result = SyncResult(
          totalRecords: 10,
          successCount: 10,
          failureCount: 0,
          skippedCount: 0,
          errors: [],
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(seconds: 5)),
          syncType: 'logEntries',
        );
        
        metrics.recordSync(result);
        
        expect(metrics.totalSyncs, 1);
        expect(metrics.successfulSyncs, 1);
        expect(metrics.failedSyncs, 0);
        expect(metrics.totalRecordsSynced, 10);
        expect(metrics.totalRecordsFailed, 0);
        expect(metrics.overallSuccessRate, 100.0);
        expect(metrics.lastSuccessfulSyncTime, result.endTime);
      });
      
      test('records failed sync', () {
        final metrics = SyncMetrics();
        
        final result = SyncResult(
          totalRecords: 10,
          successCount: 0,
          failureCount: 10,
          skippedCount: 0,
          errors: [],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
          syncType: 'logEntries',
        );
        
        metrics.recordSync(result);
        
        expect(metrics.totalSyncs, 1);
        expect(metrics.successfulSyncs, 0);
        expect(metrics.failedSyncs, 1);
        expect(metrics.totalRecordsSynced, 0);
        expect(metrics.totalRecordsFailed, 10);
        expect(metrics.overallSuccessRate, 0.0);
        expect(metrics.lastSuccessfulSyncTime, null);
      });
      
      test('records partial success sync', () {
        final metrics = SyncMetrics();
        
        final result = SyncResult(
          totalRecords: 10,
          successCount: 7,
          failureCount: 3,
          skippedCount: 0,
          errors: [],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
          syncType: 'logEntries',
        );
        
        metrics.recordSync(result);
        
        expect(metrics.totalSyncs, 1);
        expect(metrics.successfulSyncs, 0); // Not fully successful
        expect(metrics.failedSyncs, 1); // Has failures
        expect(metrics.totalRecordsSynced, 7);
        expect(metrics.totalRecordsFailed, 3);
        expect(metrics.overallSuccessRate, 0.0);
      });
      
      test('calculates average sync time correctly', () {
        final metrics = SyncMetrics();
        
        // Add syncs with different durations
        final durations = [1000, 2000, 3000]; // milliseconds
        
        for (final duration in durations) {
          final startTime = DateTime.now();
          final endTime = startTime.add(Duration(milliseconds: duration));
          
          final result = SyncResult(
            totalRecords: 5,
            successCount: 5,
            failureCount: 0,
            skippedCount: 0,
            errors: [],
            startTime: startTime,
            endTime: endTime,
            syncType: 'test',
          );
          
          metrics.recordSync(result);
        }
        
        expect(metrics.averageSyncTime, 2000.0); // (1000 + 2000 + 3000) / 3
      });
      
      test('maintains recent results history with limit', () {
        final metrics = SyncMetrics();
        
        // Add more than 10 results
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
        expect(metrics.recentResults.first.syncType, 'test_5');
        expect(metrics.recentResults.last.syncType, 'test_14');
      });
      
      test('serializes to JSON correctly', () {
        final metrics = SyncMetrics();
        
        final result = SyncResult(
          totalRecords: 10,
          successCount: 8,
          failureCount: 2,
          skippedCount: 0,
          errors: [],
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(seconds: 5)),
          syncType: 'test',
        );
        
        metrics.recordSync(result);
        
        final json = metrics.toJson();
        
        expect(json['totalSyncs'], 1);
        expect(json['successfulSyncs'], 0); // Partial success
        expect(json['failedSyncs'], 1);
        expect(json['totalRecordsSynced'], 8);
        expect(json['totalRecordsFailed'], 2);
        expect(json['averageSyncTimeMs'], 5000.0);
        expect(json['overallSuccessRate'], 0.0);
        expect(json.containsKey('lastSyncTime'), true);
        expect(json['recentResults'], isA<List>());
      });
    });
  });
}