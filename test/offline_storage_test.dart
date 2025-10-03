import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_flutter_app/models/hive_models.dart';
import 'package:my_flutter_app/services/local_database_service.dart';
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Offline Storage Tests', () {
    setUpAll(() async {
      // Initialize Hive for testing with a temporary directory
      final path = Directory.systemTemp.path;
      Hive.init(path);
      
      // Register adapters
      Hive.registerAdapter(LogEntryAdapter());
      Hive.registerAdapter(DailyMetricAdapter());
      Hive.registerAdapter(UserSessionAdapter());
      Hive.registerAdapter(CachedProjectAdapter());
      Hive.registerAdapter(SyncQueueEntryAdapter());
      
      // Open boxes
      await Hive.openBox<LogEntry>('logEntries');
      await Hive.openBox<DailyMetric>('dailyMetrics');
      await Hive.openBox<UserSession>('userSessions');
      await Hive.openBox<CachedProject>('cachedProjects');
      await Hive.openBox<SyncQueueEntry>('syncQueue');
    });
    
    tearDownAll(() async {
      await Hive.close();
    });
    
    tearDown(() async {
      // Clear all data after each test
      await LocalDatabaseService.clearAllData();
    });
    
    group('LogEntry CRUD Operations', () {
      test('Should save and retrieve a log entry', () async {
        final logEntry = LogEntry(
          id: 'test-log-1',
          projectId: 'project-1',
          projectName: 'Test Project',
          date: '2025-09-09',
          hour: '10:00',
          data: {'temperature': 75, 'pressure': 30},
          status: 'complete',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'test-user',
        );
        
        await LocalDatabaseService.saveLogEntry(logEntry);
        final retrieved = await LocalDatabaseService.getLogEntry('test-log-1');
        
        expect(retrieved, isNotNull);
        expect(retrieved!.id, equals('test-log-1'));
        expect(retrieved.projectId, equals('project-1'));
        expect(retrieved.data['temperature'], equals(75));
      });
      
      test('Should get all log entries for a project', () async {
        // Create multiple log entries
        for (int i = 0; i < 3; i++) {
          final logEntry = LogEntry(
            id: 'test-log-$i',
            projectId: 'project-1',
            projectName: 'Test Project',
            date: '2025-09-09',
            hour: '${10 + i}:00',
            data: {'temperature': 70 + i},
            status: 'complete',
            createdAt: DateTime.now().subtract(Duration(hours: i)),
            updatedAt: DateTime.now(),
            createdBy: 'test-user',
          );
          await LocalDatabaseService.saveLogEntry(logEntry);
        }
        
        final projectLogs = await LocalDatabaseService.getProjectLogEntries('project-1');
        expect(projectLogs.length, equals(3));
        expect(projectLogs.first.id, equals('test-log-0')); // Most recent first
      });
      
      test('Should get unsynced log entries', () async {
        // Create synced and unsynced entries
        final syncedEntry = LogEntry(
          id: 'synced-log',
          projectId: 'project-1',
          projectName: 'Test Project',
          date: '2025-09-09',
          hour: '10:00',
          data: {},
          status: 'complete',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'test-user',
          isSynced: true,
        );
        
        final unsyncedEntry = LogEntry(
          id: 'unsynced-log',
          projectId: 'project-1',
          projectName: 'Test Project',
          date: '2025-09-09',
          hour: '11:00',
          data: {},
          status: 'complete',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'test-user',
          isSynced: false,
        );
        
        await LocalDatabaseService.saveLogEntry(syncedEntry);
        await LocalDatabaseService.saveLogEntry(unsyncedEntry);
        
        final unsyncedLogs = await LocalDatabaseService.getUnsyncedLogEntries();
        expect(unsyncedLogs.length, equals(1));
        expect(unsyncedLogs.first.id, equals('unsynced-log'));
      });
      
      test('Should delete a log entry', () async {
        final logEntry = LogEntry(
          id: 'test-log-delete',
          projectId: 'project-1',
          projectName: 'Test Project',
          date: '2025-09-09',
          hour: '10:00',
          data: {},
          status: 'complete',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'test-user',
        );
        
        await LocalDatabaseService.saveLogEntry(logEntry);
        await LocalDatabaseService.deleteLogEntry('test-log-delete');
        
        final retrieved = await LocalDatabaseService.getLogEntry('test-log-delete');
        expect(retrieved, isNull);
      });
    });
    
    group('DailyMetric CRUD Operations', () {
      test('Should save and retrieve a daily metric', () async {
        final metric = DailyMetric(
          id: 'metric-1',
          projectId: 'project-1',
          date: '2025-09-09',
          totalEntries: 24,
          completedEntries: 12,
          completionStatus: 'incomplete',
          summary: {'average_temp': 72.5},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'test-user',
        );
        
        await LocalDatabaseService.saveDailyMetric(metric);
        final retrieved = await LocalDatabaseService.getDailyMetric('metric-1');
        
        expect(retrieved, isNotNull);
        expect(retrieved!.completionPercentage, equals(50.0));
        expect(retrieved.summary['average_temp'], equals(72.5));
      });
      
      test('Should lock and unlock daily metric', () async {
        final metric = DailyMetric(
          id: 'metric-lock',
          projectId: 'project-1',
          date: '2025-09-09',
          totalEntries: 24,
          completedEntries: 24,
          completionStatus: 'complete',
          summary: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'test-user',
          isLocked: false,
        );
        
        await LocalDatabaseService.saveDailyMetric(metric);
        await LocalDatabaseService.updateDailyMetricLock('metric-lock', true);
        
        final locked = await LocalDatabaseService.getDailyMetric('metric-lock');
        expect(locked!.isLocked, isTrue);
        
        await LocalDatabaseService.updateDailyMetricLock('metric-lock', false);
        final unlocked = await LocalDatabaseService.getDailyMetric('metric-lock');
        expect(unlocked!.isLocked, isFalse);
      });
    });
    
    group('CachedProject Operations', () {
      test('Should cache and retrieve a project', () async {
        final project = CachedProject(
          projectId: 'cached-project-1',
          projectName: 'Cached Test Project',
          projectNumber: 'PRJ-001',
          location: 'Test Location',
          unitNumber: 'UNIT-001',
          metadata: {'client': 'Test Client'},
          cachedAt: DateTime.now(),
          createdBy: 'test-user',
        );
        
        await LocalDatabaseService.cacheProject(project);
        final retrieved = await LocalDatabaseService.getCachedProject('cached-project-1');
        
        expect(retrieved, isNotNull);
        expect(retrieved!.projectName, equals('Cached Test Project'));
        expect(retrieved.metadata['client'], equals('Test Client'));
      });
    });
    
    group('SyncQueue Operations', () {
      test('Should add and retrieve sync queue entries', () async {
        final entry = SyncQueueEntry(
          id: 'sync-1',
          operation: 'create',
          collection: 'logs',
          documentId: 'log-1',
          data: {'field': 'value'},
          createdAt: DateTime.now(),
        );
        
        await LocalDatabaseService.addToSyncQueue(entry);
        final pending = await LocalDatabaseService.getPendingSyncOperations();
        
        expect(pending.length, equals(1));
        expect(pending.first.operation, equals('create'));
      });
      
      test('Should update sync queue entry with error', () async {
        final entry = SyncQueueEntry(
          id: 'sync-error',
          operation: 'update',
          collection: 'logs',
          documentId: 'log-2',
          data: {},
          createdAt: DateTime.now(),
        );
        
        await LocalDatabaseService.addToSyncQueue(entry);
        await LocalDatabaseService.updateSyncQueueEntry(
          'sync-error',
          error: 'Network error',
        );
        
        final updated = await LocalDatabaseService.getPendingSyncOperations();
        expect(updated.first.retryCount, equals(1));
        expect(updated.first.lastError, equals('Network error'));
        expect(updated.first.lastAttempt, isNotNull);
      });
      
      test('Should remove sync queue entry', () async {
        final entry = SyncQueueEntry(
          id: 'sync-remove',
          operation: 'delete',
          collection: 'logs',
          documentId: 'log-3',
          data: {},
          createdAt: DateTime.now(),
        );
        
        await LocalDatabaseService.addToSyncQueue(entry);
        await LocalDatabaseService.updateSyncQueueEntry('sync-remove', remove: true);
        
        final pending = await LocalDatabaseService.getPendingSyncOperations();
        expect(pending.isEmpty, isTrue);
      });
    });
    
    group('Database Statistics', () {
      test('Should get accurate database statistics', () async {
        // Add test data
        await LocalDatabaseService.saveLogEntry(LogEntry(
          id: 'stat-log-1',
          projectId: 'project-1',
          projectName: 'Test',
          date: '2025-09-09',
          hour: '10:00',
          data: {},
          status: 'complete',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'user',
          isSynced: false,
        ));
        
        await LocalDatabaseService.saveDailyMetric(DailyMetric(
          id: 'stat-metric-1',
          projectId: 'project-1',
          date: '2025-09-09',
          totalEntries: 24,
          completedEntries: 12,
          completionStatus: 'incomplete',
          summary: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'user',
        ));
        
        final stats = await LocalDatabaseService.getDatabaseStats();
        
        expect(stats['totalLogEntries'], equals(1));
        expect(stats['unsyncedLogEntries'], equals(1));
        expect(stats['totalDailyMetrics'], equals(1));
        expect(stats['lastUpdated'], isNotNull);
      });
    });
  });
}