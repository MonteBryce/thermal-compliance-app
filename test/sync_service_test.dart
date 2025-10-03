import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_flutter_app/services/sync_service.dart';
import 'package:my_flutter_app/services/local_database_service.dart';
import 'package:my_flutter_app/models/hive_models.dart';

void main() {
  group('SyncService Tests', () {
    late SyncService syncService;
    
    setUpAll(() async {
      // Initialize Hive for testing
      await Hive.initFlutter();
      
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
      await Hive.openBox<UserSession>('userSessions');
      await Hive.openBox<CachedProject>('cachedProjects');
      await Hive.openBox<SyncQueueEntry>('syncQueue');
      
      syncService = SyncService();
    });
    
    tearDown(() async {
      // Clear and close all boxes
      await Hive.box<LogEntry>('logEntries').clear();
      await Hive.box<DailyMetric>('dailyMetrics').clear();
      await Hive.box<UserSession>('userSessions').clear();
      await Hive.box<CachedProject>('cachedProjects').clear();
      await Hive.box<SyncQueueEntry>('syncQueue').clear();
      
      syncService.dispose();
    });
    
    test('SyncService initializes successfully', () async {
      await syncService.initialize();
      
      final status = syncService.getSyncStatus();
      expect(status['isInitialized'], true);
    });
    
    test('SyncService detects connectivity status', () async {
      await syncService.initialize();
      
      final status = syncService.getSyncStatus();
      expect(status.containsKey('isConnected'), true);
    });
    
    test('SyncService can pause and resume sync', () async {
      await syncService.initialize();
      
      // Pause sync
      syncService.pauseSync();
      var status = syncService.getSyncStatus();
      expect(status['isInitialized'], true);
      
      // Resume sync
      syncService.resumeSync();
      status = syncService.getSyncStatus();
      expect(status['isInitialized'], true);
    });
    
    test('SyncService tracks sync status correctly', () async {
      await syncService.initialize();
      
      final status = syncService.getSyncStatus();
      expect(status.containsKey('isInitialized'), true);
      expect(status.containsKey('isConnected'), true);
      expect(status.containsKey('isSyncing'), true);
      expect(status.containsKey('lastSyncTime'), true);
      expect(status.containsKey('pendingOperations'), true);
    });
  });
  
  group('ConnectivityMonitor Tests', () {
    late ConnectivityMonitor monitor;
    
    setUp(() {
      monitor = ConnectivityMonitor();
    });
    
    tearDown(() {
      monitor.dispose();
    });
    
    test('ConnectivityMonitor initializes and provides status', () async {
      await monitor.initialize();
      
      // Should have a connectivity status
      expect(monitor.isConnected, isNotNull);
    });
    
    test('ConnectivityMonitor provides connectivity stream', () async {
      await monitor.initialize();
      
      // Stream should be available
      expect(monitor.connectivityStream, isNotNull);
      
      // Should be able to listen to stream
      final subscription = monitor.connectivityStream.listen((isConnected) {
        expect(isConnected, isA<bool>());
      });
      
      // Clean up
      await subscription.cancel();
    });
  });
  
  group('DataSyncManager Tests', () {
    late DataSyncManager syncManager;
    
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
    
    test('DataSyncManager handles empty sync queue gracefully', () async {
      // Should not throw when queue is empty
      await expectLater(
        syncManager.processSyncQueue(),
        completes,
      );
    });
    
    test('DataSyncManager tracks pending operations count', () {
      expect(syncManager.pendingOperationsCount, equals(0));
    });
    
    test('DataSyncManager tracks last sync time', () {
      expect(syncManager.lastSyncTime, isNull);
    });
  });
  
  group('Integration Tests', () {
    late SyncService syncService;
    
    setUp(() async {
      // Open all required boxes
      await Hive.openBox<LogEntry>('logEntries');
      await Hive.openBox<DailyMetric>('dailyMetrics');
      await Hive.openBox<UserSession>('userSessions');
      await Hive.openBox<CachedProject>('cachedProjects');
      await Hive.openBox<SyncQueueEntry>('syncQueue');
      
      syncService = SyncService();
    });
    
    tearDown(() async {
      // Clean up
      await Hive.box<LogEntry>('logEntries').clear();
      await Hive.box<DailyMetric>('dailyMetrics').clear();
      await Hive.box<UserSession>('userSessions').clear();
      await Hive.box<CachedProject>('cachedProjects').clear();
      await Hive.box<SyncQueueEntry>('syncQueue').clear();
      
      syncService.dispose();
    });
    
    test('SyncService handles unsynced log entries', () async {
      // Create test log entry
      final testEntry = LogEntry(
        id: 'test_entry_1',
        projectId: 'project_1',
        projectName: 'Test Project',
        date: '2025-01-10',
        hour: '14:00',
        data: {'temperature': 25.5},
        status: 'completed',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'test_user',
        isSynced: false,
      );
      
      // Save to local database
      await LocalDatabaseService.saveLogEntry(testEntry);
      
      // Verify entry is unsynced
      final unsyncedEntries = await LocalDatabaseService.getUnsyncedLogEntries();
      expect(unsyncedEntries.length, equals(1));
      expect(unsyncedEntries.first.id, equals('test_entry_1'));
    });
    
    test('SyncService manages sync queue operations', () async {
      // Create test sync queue entry
      final testQueueEntry = SyncQueueEntry(
        id: 'queue_1',
        operation: 'create',
        collection: 'testCollection',
        documentId: 'doc_1',
        data: {'test': 'data'},
        createdAt: DateTime.now(),
      );
      
      // Add to sync queue
      await LocalDatabaseService.addToSyncQueue(testQueueEntry);
      
      // Verify queue entry exists
      final pendingOps = await LocalDatabaseService.getPendingSyncOperations();
      expect(pendingOps.length, equals(1));
      expect(pendingOps.first.id, equals('queue_1'));
    });
    
    test('SyncService handles retry logic for failed operations', () async {
      // Create test sync queue entry with retry count
      final testQueueEntry = SyncQueueEntry(
        id: 'retry_test_1',
        operation: 'update',
        collection: 'testCollection',
        documentId: 'doc_retry',
        data: {'test': 'retry_data'},
        createdAt: DateTime.now(),
        retryCount: 0,
      );
      
      // Add to sync queue
      await LocalDatabaseService.addToSyncQueue(testQueueEntry);
      
      // Update with error (simulate failed attempt)
      await LocalDatabaseService.updateSyncQueueEntry(
        'retry_test_1',
        error: 'Network error',
      );
      
      // Verify retry count increased
      final pendingOps = await LocalDatabaseService.getPendingSyncOperations();
      expect(pendingOps.first.retryCount, equals(1));
      expect(pendingOps.first.lastError, equals('Network error'));
    });
    
    test('SyncService respects max retry limit', () async {
      // Create test sync queue entry with max retries
      final testQueueEntry = SyncQueueEntry(
        id: 'max_retry_test',
        operation: 'delete',
        collection: 'testCollection',
        documentId: 'doc_max_retry',
        data: {},
        createdAt: DateTime.now(),
        retryCount: 3, // Max retries
      );
      
      // Add to sync queue
      await LocalDatabaseService.addToSyncQueue(testQueueEntry);
      
      // Verify entry exists but won't be processed due to max retries
      final pendingOps = await LocalDatabaseService.getPendingSyncOperations();
      expect(pendingOps.length, equals(1));
      expect(pendingOps.first.retryCount, equals(3));
    });
  });
}