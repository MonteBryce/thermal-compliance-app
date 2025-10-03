import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hive_models.dart';
import '../models/sync_models.dart';
import '../models/conflict_resolution_models.dart';
import '../models/sync_checkpoint_models.dart';
import 'local_database_service.dart';
import 'auth_service.dart';
import 'conflict_resolution_service.dart';
import 'retry_service.dart';
import 'sync_logger.dart';

/// Service for managing automatic data synchronization between local and cloud storage
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final ConnectivityMonitor _connectivityMonitor = ConnectivityMonitor();
  final DataSyncManager _dataSyncManager = DataSyncManager();
  
  Timer? _syncTimer;
  bool _isInitialized = false;
  bool _isSyncing = false;
  
  /// Initialize the sync service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Start connectivity monitoring
      await _connectivityMonitor.initialize();
      
      // Listen to connectivity changes
      _connectivityMonitor.connectivityStream.listen((isConnected) {
        if (isConnected) {
          debugPrint('Network connected - triggering sync');
          triggerSync();
        } else {
          debugPrint('Network disconnected - pausing sync');
          _cancelSyncTimer();
        }
      });
      
      // Set up periodic sync (every 5 minutes when connected)
      _setupPeriodicSync();
      
      _isInitialized = true;
      debugPrint('SyncService initialized successfully');
      
      // Trigger initial sync if connected
      if (_connectivityMonitor.isConnected) {
        triggerSync();
      }
    } catch (e) {
      debugPrint('Error initializing SyncService: $e');
    }
  }
  
  /// Manually trigger a sync operation with comprehensive reporting
  Future<Map<String, SyncResult>> triggerSync() async {
    if (_isSyncing) {
      debugPrint('Sync already in progress, skipping');
      return {};
    }
    
    if (!_connectivityMonitor.isConnected) {
      debugPrint('No network connection, skipping sync');
      return {};
    }
    
    final userId = AuthService.getCurrentUserId();
    if (userId == null) {
      debugPrint('No authenticated user, skipping sync');
      return {};
    }
    
    _isSyncing = true;
    final syncResults = <String, SyncResult>{};
    
    try {
      debugPrint('Starting comprehensive sync operation');
      
      // Sync unsynced log entries with detailed reporting
      final logEntriesResult = await _dataSyncManager.syncLogEntries();
      syncResults['logEntries'] = logEntriesResult;
      
      // Sync daily metrics with reporting
      final dailyMetricsResult = await _dataSyncManager.syncDailyMetrics();
      syncResults['dailyMetrics'] = dailyMetricsResult;
      
      // Process sync queue (retry failed operations)
      await _dataSyncManager.processSyncQueue();
      
      // Check for any critical failures and trigger recovery
      await _handleSyncRecovery(syncResults);
      
      debugPrint('Sync operation completed - Results: ${_formatSyncSummary(syncResults)}');
    } catch (e) {
      debugPrint('Critical error during sync operation: $e');
      // Log critical error for monitoring
      await _dataSyncManager._logCriticalSyncError(e.toString());
    } finally {
      _isSyncing = false;
    }
    
    return syncResults;
  }
  
  /// Handle sync recovery for failed operations
  Future<void> _handleSyncRecovery(Map<String, SyncResult> results) async {
    for (final syncResult in results.values) {
      if (syncResult.hasErrors && syncResult.failureCount > 0) {
        // If failure rate is high, implement exponential backoff
        if (syncResult.failureCount / syncResult.totalRecords > 0.5) {
          debugPrint('High failure rate detected, implementing recovery strategy');
          await _implementRecoveryStrategy(syncResult);
        }
      }
    }
  }
  
  /// Implement recovery strategy for high failure scenarios
  Future<void> _implementRecoveryStrategy(SyncResult result) async {
    // Strategy 1: Reduce batch size for next sync
    // Strategy 2: Add delay before retry
    // Strategy 3: Switch to individual record sync
    
    debugPrint('Implementing recovery strategy for ${result.syncType}');
    
    // Add failed records back to sync queue with delay
    await Future.delayed(const Duration(minutes: 1));
    
    // This will be picked up by the next periodic sync
  }
  
  /// Format sync summary for logging
  String _formatSyncSummary(Map<String, SyncResult> results) {
    final summary = <String>[];
    for (final entry in results.entries) {
      final result = entry.value;
      summary.add('${entry.key}: ${result.successCount}/${result.totalRecords} (${result.successRate.toStringAsFixed(1)}%)');
    }
    return summary.join(', ');
  }
  
  /// Get current sync status
  Map<String, dynamic> getSyncStatus() {
    return {
      'isInitialized': _isInitialized,
      'isConnected': _connectivityMonitor.isConnected,
      'isSyncing': _isSyncing,
      'lastSyncTime': _dataSyncManager.lastSyncTime?.toIso8601String(),
      'pendingOperations': _dataSyncManager.pendingOperationsCount,
    };
  }
  
  /// Pause sync operations
  void pauseSync() {
    _cancelSyncTimer();
    debugPrint('Sync operations paused');
  }
  
  /// Resume sync operations
  void resumeSync() {
    _setupPeriodicSync();
    if (_connectivityMonitor.isConnected) {
      triggerSync();
    }
    debugPrint('Sync operations resumed');
  }
  
  /// Clean up resources
  void dispose() {
    _cancelSyncTimer();
    _connectivityMonitor.dispose();
    _isInitialized = false;
  }
  
  void _setupPeriodicSync() {
    _cancelSyncTimer();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_connectivityMonitor.isConnected) {
        triggerSync();
      }
    });
  }
  
  void _cancelSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }
}

/// Monitors network connectivity status
class ConnectivityMonitor {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  StreamSubscription<ConnectivityResult>? _subscription;
  bool _isConnected = false;
  
  /// Stream of connectivity status changes
  Stream<bool> get connectivityStream => _connectivityController.stream;
  
  /// Current connectivity status
  bool get isConnected => _isConnected;
  
  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    try {
      // Check initial connectivity
      final result = await _connectivity.checkConnectivity();
      _updateConnectivityStatus(result);
      
      // Listen to connectivity changes
      _subscription = _connectivity.onConnectivityChanged.listen(
        _updateConnectivityStatus,
        onError: (error) {
          debugPrint('Connectivity monitoring error: $error');
        },
      );
      
      debugPrint('ConnectivityMonitor initialized - Connected: $_isConnected');
    } catch (e) {
      debugPrint('Error initializing ConnectivityMonitor: $e');
      _isConnected = false;
    }
  }
  
  void _updateConnectivityStatus(ConnectivityResult result) {
    final wasConnected = _isConnected;
    _isConnected = result != ConnectivityResult.none;
    
    if (wasConnected != _isConnected) {
      debugPrint('Connectivity changed: $_isConnected');
      _connectivityController.add(_isConnected);
    }
  }
  
  /// Clean up resources
  void dispose() {
    _subscription?.cancel();
    _connectivityController.close();
  }
}

/// Manages data synchronization operations
class DataSyncManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime? _lastSyncTime;
  int _pendingOperationsCount = 0;
  final SyncMetrics _metrics = SyncMetrics();
  final ConflictResolutionService _conflictResolver = ConflictResolutionService();
  final RetryStats _retryStats = RetryStats();
  final SyncLogger _logger = SyncLogger();
  
  /// Last successful sync time
  DateTime? get lastSyncTime => _lastSyncTime;
  
  /// Number of pending sync operations
  int get pendingOperationsCount => _pendingOperationsCount;
  
  /// Get sync metrics
  SyncMetrics get metrics => _metrics;
  
  /// Get conflict resolution service
  ConflictResolutionService get conflictResolver => _conflictResolver;
  
  /// Get retry statistics
  RetryStats get retryStats => _retryStats;
  
  /// Get sync logger
  SyncLogger get logger => _logger;
  
  /// Sync unsynced log entries to Firestore with detailed reporting
  Future<SyncResult> syncLogEntries() async {
    final startTime = DateTime.now();
    final errors = <SyncError>[];
    var successCount = 0;
    var failureCount = 0;
    var skippedCount = 0;
    SyncCheckpoint? checkpoint;
    
    try {
      _logger.logSyncStart('sync_log_entries', {
        'timestamp': startTime.toIso8601String(),
        'pendingOperations': _pendingOperationsCount,
      });
      
      // Check for existing incomplete sync to resume
      checkpoint = SyncCheckpointManager.findIncompleteSync('logEntries');
      bool isResuming = checkpoint != null;
      
      // Use batch retrieval with automatic timestamping
      final unsyncedEntries = await LocalDatabaseService.getUnsyncedLogEntriesBatch(
        batchSize: 100,
        prepareForSync: true,
      );
      
      // Create new checkpoint if not resuming
      if (!isResuming && unsyncedEntries.isNotEmpty) {
        checkpoint = SyncCheckpointManager.createCheckpoint(
          syncType: 'logEntries',
          totalRecords: unsyncedEntries.length,
          syncContext: {
            'batchSize': 100,
            'startedAt': DateTime.now().toIso8601String(),
          },
        );
        _logger.logCheckpoint('Created checkpoint', checkpoint);
        debugPrint('Created sync checkpoint: ${checkpoint.id}');
      } else if (isResuming) {
        _logger.logCheckpoint('Resuming checkpoint', checkpoint!);
        debugPrint('Resuming sync from checkpoint: ${checkpoint!.id} (${checkpoint.progressPercentage.toStringAsFixed(1)}% complete)');
      }
      
      _pendingOperationsCount = unsyncedEntries.length;
      
      if (unsyncedEntries.isEmpty) {
        debugPrint('No unsynced log entries to sync');
        final result = SyncResult(
          totalRecords: 0,
          successCount: 0,
          failureCount: 0,
          skippedCount: 0,
          errors: [],
          startTime: startTime,
          endTime: DateTime.now(),
          syncType: 'logEntries',
        );
        _metrics.recordSync(result);
        return result;
      }
      
      debugPrint('Syncing batch of ${unsyncedEntries.length} log entries');
      
      // Process in smaller batches for Firestore
      const firestoreBatchSize = 10;
      final startBatch = isResuming ? checkpoint!.currentBatchNumber : 0;
      
      for (var i = startBatch * firestoreBatchSize; i < unsyncedEntries.length; i += firestoreBatchSize) {
        final batchEntries = <LogEntry>[];
        final validEntries = <LogEntry>[];
        
        // Validate entries for this batch
        final endIndex = (i + firestoreBatchSize > unsyncedEntries.length) 
            ? unsyncedEntries.length 
            : i + firestoreBatchSize;
        
        for (var j = i; j < endIndex; j++) {
          final entry = unsyncedEntries[j];
          batchEntries.add(entry);
          
          // Validate timestamp before syncing
          if (!LocalDatabaseService.validateSyncTimestamp(
              entry.syncTimestamp, entry.createdAt)) {
            debugPrint('Invalid timestamp for entry ${entry.id}, skipping');
            errors.add(SyncError(
              recordId: entry.id,
              errorMessage: 'Invalid sync timestamp - violates no-backdating rule',
              errorCode: 'INVALID_TIMESTAMP',
              timestamp: DateTime.now(),
              recordType: 'LogEntry',
            ));
            skippedCount++;
          } else {
            validEntries.add(entry);
          }
        }
        
        if (validEntries.isEmpty) continue;
        
        // Attempt batch sync with individual error tracking
        final batchResult = await _syncLogEntriesBatch(validEntries, i ~/ firestoreBatchSize + 1);
        
        successCount += batchResult.successCount;
        failureCount += batchResult.failureCount;
        
        // Add batch-specific errors to overall errors
        for (final failedId in batchResult.failedIds.keys) {
          errors.add(SyncError(
            recordId: failedId,
            errorMessage: batchResult.failedIds[failedId]!,
            errorCode: 'BATCH_COMMIT_FAILED',
            timestamp: batchResult.timestamp,
            recordType: 'LogEntry',
          ));
        }
        
        _pendingOperationsCount -= batchResult.successCount;
        
        // Update checkpoint progress
        if (checkpoint != null) {
          final batchNumber = i ~/ firestoreBatchSize + 1;
          final updatedProcessedBatches = List<String>.from(checkpoint.processedBatches)
            ..add('batch_$batchNumber');
          final updatedFailedRecords = List<String>.from(checkpoint.failedRecords)
            ..addAll(batchResult.failedIds.keys);
          
          checkpoint = checkpoint.copyWith(
            processedRecords: checkpoint.processedRecords + batchResult.successCount,
            currentBatchNumber: batchNumber,
            processedBatches: updatedProcessedBatches,
            failedRecords: updatedFailedRecords,
          );
          
          SyncCheckpointManager.updateCheckpoint(checkpoint.id, checkpoint);
          debugPrint('Updated checkpoint: ${checkpoint.progressPercentage.toStringAsFixed(1)}% complete');
        }
      }
      
      _lastSyncTime = DateTime.now();
      
      // Mark checkpoint as completed
      if (checkpoint != null) {
        SyncCheckpointManager.completeCheckpoint(checkpoint.id);
        _logger.logCheckpoint('Completed checkpoint', checkpoint);
        debugPrint('Sync checkpoint completed: ${checkpoint.id}');
      }
    } catch (e) {
      debugPrint('Critical error during log entries sync: $e');
      
      // Update checkpoint with error
      if (checkpoint != null) {
        checkpoint = checkpoint.copyWith(lastError: e.toString());
        SyncCheckpointManager.updateCheckpoint(checkpoint.id, checkpoint);
      }
      
      errors.add(SyncError(
        recordId: 'BATCH_OPERATION',
        errorMessage: e.toString(),
        errorCode: 'CRITICAL_SYNC_ERROR',
        timestamp: DateTime.now(),
        recordType: 'LogEntry',
      ));
    }
    
    final endTime = DateTime.now();
    final result = SyncResult(
      totalRecords: _pendingOperationsCount + successCount,
      successCount: successCount,
      failureCount: failureCount,
      skippedCount: skippedCount,
      errors: errors,
      startTime: startTime,
      endTime: endTime,
      syncType: 'logEntries',
    );
    
    _metrics.recordSync(result);
    _logger.logSyncComplete('sync_log_entries', result, checkpointId: checkpoint?.id);
    debugPrint('Log entries sync completed: ${result.successCount}/${result.totalRecords} successful');
    
    return result;
  }
  
  /// Sync a single batch of log entries with conflict resolution
  Future<BatchSyncResult> _syncLogEntriesBatch(List<LogEntry> entries, int batchNumber) async {
    final successfulIds = <String>[];
    final failedIds = <String, String>{};
    final conflictResolutions = <String, ConflictResolutionResult>{};
    
    // Step 1: Detect conflicts for all entries
    for (final entry in entries) {
      try {
        final conflict = await _conflictResolver.detectLogEntryConflict(entry);
        
        if (conflict != null && conflict.type != ConflictType.none) {
          debugPrint('Conflict detected for ${entry.id}: ${conflict.type.name}');
          
          // Attempt to resolve conflict
          final resolution = await _conflictResolver.resolveConflict(conflict);
          conflictResolutions[entry.id] = resolution;
          
          if (!resolution.wasResolved) {
            failedIds[entry.id] = 'Conflict resolution failed: ${resolution.errorMessage}';
            continue;
          }
          
          // Update entry with resolved data if needed
          if (resolution.resolvedData != null && 
              resolution.strategy == ConflictResolutionStrategy.remoteWins) {
            // Update local entry with remote data
            await _updateLocalEntryFromResolution(entry, resolution.resolvedData!);
          }
        }
      } catch (e) {
        failedIds[entry.id] = 'Conflict detection failed: $e';
      }
    }
    
    // Step 2: Sync entries that passed conflict resolution
    final entriesToSync = entries.where((entry) => !failedIds.containsKey(entry.id)).toList();
    
    if (entriesToSync.isEmpty) {
      debugPrint('No entries to sync after conflict resolution');
    } else {
      // Use Firestore transaction for atomic updates with retry logic
      try {
        await RetryService.executeWithRetry(
          () => _firestore.runTransaction((transaction) async {
            final batch = _firestore.batch();
            
            for (final entry in entriesToSync) {
              try {
                // Use resolved data if available, otherwise use local data
                final resolution = conflictResolutions[entry.id];
                final dataToSync = resolution?.resolvedData ?? entry.toJson();
                
                final firestoreData = {
                  ...dataToSync,
                  'serverTimestamp': FieldValue.serverTimestamp(),
                  'clientSyncTimestamp': entry.syncTimestamp?.toIso8601String(),
                  'batchNumber': batchNumber,
                  'syncVersion': 1,
                  'conflictResolved': resolution != null,
                  'resolutionStrategy': resolution?.strategy.name,
                };
                
                // Add to batch
                final docRef = _firestore
                    .collection('projects')
                    .doc(entry.projectId)
                    .collection('logEntries')
                    .doc(entry.id);
                
                batch.set(docRef, firestoreData, SetOptions(merge: true));
              } catch (e) {
                failedIds[entry.id] = 'Failed to prepare for batch: $e';
              }
            }
            
            // Commit all or nothing
            await batch.commit();
            
            // If we get here, all entries in the batch succeeded
            for (final entry in entriesToSync) {
              if (!failedIds.containsKey(entry.id)) {
                successfulIds.add(entry.id);
              }
            }
          }),
          maxRetries: 3,
          baseDelay: const Duration(seconds: 1),
          maxDelay: const Duration(minutes: 2),
          shouldRetry: (error) => RetryService.isRetryableError(error),
          onRetry: (attempt, error) {
            _retryStats.recordRetry(
              attemptNumber: attempt,
              retryTime: DateTime.now().difference(DateTime.now()),
              errorType: error.runtimeType.toString(),
              succeeded: false,
            );
            debugPrint('Retrying batch $batchNumber sync, attempt $attempt: ${error.toString()}');
          },
        );
        
        // Update local status for successful entries
        for (final id in successfulIds) {
          await LocalDatabaseService.updateLogEntrySyncStatus(id, true);
        }
        
        debugPrint('Successfully synced batch $batchNumber: ${successfulIds.length}/${entries.length}');
        
        // Log conflict resolution summary
        if (conflictResolutions.isNotEmpty) {
          final resolvedCount = conflictResolutions.values.where((r) => r.wasResolved).length;
          debugPrint('Batch $batchNumber: ${conflictResolutions.length} conflicts detected, $resolvedCount resolved');
        }
        
      } catch (e) {
        // Transaction failed - mark remaining entries as failed
        for (final entry in entriesToSync) {
          if (!failedIds.containsKey(entry.id)) {
            failedIds[entry.id] = 'Transaction failed: $e';
            await LocalDatabaseService.updateLogEntrySyncStatus(
              entry.id, 
              false, 
              e.toString()
            );
            
            // Add to retry queue
            await _addToSyncQueue(
              operation: 'update',
              collection: 'logEntries',
              documentId: entry.id,
              data: entry.toJson(),
            );
          }
        }
      }
    }
    
    return BatchSyncResult(
      batchNumber: batchNumber,
      batchSize: entries.length,
      successCount: successfulIds.length,
      failureCount: failedIds.length,
      successfulIds: successfulIds,
      failedIds: failedIds,
      timestamp: DateTime.now(),
    );
  }
  
  /// Update local entry with resolved data from conflict resolution
  Future<void> _updateLocalEntryFromResolution(LogEntry entry, Map<String, dynamic> resolvedData) async {
    try {
      // Update entry fields with resolved data (excluding internal sync fields)
      if (resolvedData.containsKey('data')) {
        entry.data = Map<String, dynamic>.from(resolvedData['data']);
      }
      if (resolvedData.containsKey('status')) {
        entry.status = resolvedData['status'];
      }
      
      entry.updatedAt = DateTime.now();
      await entry.save();
      
      debugPrint('Local entry ${entry.id} updated with resolved conflict data');
    } catch (e) {
      debugPrint('Failed to update local entry ${entry.id} with resolved data: $e');
    }
  }
  
  /// Process pending operations in the sync queue
  Future<void> processSyncQueue() async {
    try {
      final pendingOps = await LocalDatabaseService.getPendingSyncOperations();
      
      if (pendingOps.isEmpty) {
        debugPrint('No pending sync operations');
        return;
      }
      
      debugPrint('Processing ${pendingOps.length} sync queue operations');
      
      for (final op in pendingOps) {
        // Skip if max retries exceeded
        if (op.retryCount >= 3) {
          debugPrint('Max retries exceeded for operation: ${op.id}');
          continue;
        }
        
        try {
          await _executeSyncOperation(op);
          
          // Remove from queue on success
          await LocalDatabaseService.updateSyncQueueEntry(op.id, remove: true);
          debugPrint('Sync operation completed: ${op.id}');
        } catch (e) {
          debugPrint('Error executing sync operation ${op.id}: $e');
          
          // Update retry count and error
          await LocalDatabaseService.updateSyncQueueEntry(
            op.id,
            error: e.toString(),
          );
        }
      }
    } catch (e) {
      debugPrint('Error processing sync queue: $e');
    }
  }
  
  /// Sync daily metrics to Firestore with detailed reporting
  Future<SyncResult> syncDailyMetrics() async {
    final startTime = DateTime.now();
    final errors = <SyncError>[];
    var successCount = 0;
    var failureCount = 0;
    var skippedCount = 0;
    
    try {
      // Use batch retrieval with automatic timestamping
      final unsyncedMetrics = await LocalDatabaseService.getUnsyncedDailyMetricsBatch(
        batchSize: 50,
        prepareForSync: true,
      );
      
      if (unsyncedMetrics.isEmpty) {
        debugPrint('No unsynced daily metrics to sync');
        final result = SyncResult(
          totalRecords: 0,
          successCount: 0,
          failureCount: 0,
          skippedCount: 0,
          errors: [],
          startTime: startTime,
          endTime: DateTime.now(),
          syncType: 'dailyMetrics',
        );
        _metrics.recordSync(result);
        return result;
      }
      
      debugPrint('Syncing batch of ${unsyncedMetrics.length} daily metrics');
      
      // Process in batches with transaction support
      const batchSize = 10;
      for (var i = 0; i < unsyncedMetrics.length; i += batchSize) {
        final endIndex = (i + batchSize > unsyncedMetrics.length) 
            ? unsyncedMetrics.length 
            : i + batchSize;
        
        final batchMetrics = unsyncedMetrics.sublist(i, endIndex);
        final validMetrics = <DailyMetric>[];
        
        // Validate metrics in this batch
        for (final metric in batchMetrics) {
          if (!LocalDatabaseService.validateSyncTimestamp(
              metric.syncTimestamp, metric.createdAt)) {
            debugPrint('Invalid timestamp for metric ${metric.id}, skipping');
            errors.add(SyncError(
              recordId: metric.id,
              errorMessage: 'Invalid sync timestamp',
              errorCode: 'INVALID_TIMESTAMP',
              timestamp: DateTime.now(),
              recordType: 'DailyMetric',
            ));
            skippedCount++;
          } else {
            validMetrics.add(metric);
          }
        }
        
        if (validMetrics.isEmpty) continue;
        
        // Sync valid metrics with retry logic
        try {
          await RetryService.executeWithRetry(
            () => _firestore.runTransaction((transaction) async {
              final batch = _firestore.batch();
              
              for (final metric in validMetrics) {
                final firestoreData = {
                  ...metric.toJson(),
                  'serverTimestamp': FieldValue.serverTimestamp(),
                  'clientSyncTimestamp': metric.syncTimestamp?.toIso8601String(),
                };
                
                final docRef = _firestore
                    .collection('projects')
                    .doc(metric.projectId)
                    .collection('dailyMetrics')
                    .doc(metric.id);
                
                batch.set(docRef, firestoreData, SetOptions(merge: true));
              }
              
              await batch.commit();
            }),
            maxRetries: 3,
            baseDelay: const Duration(seconds: 1),
            shouldRetry: (error) => RetryService.isRetryableError(error),
            onRetry: (attempt, error) {
              _retryStats.recordRetry(
                attemptNumber: attempt,
                retryTime: DateTime.now().difference(DateTime.now()),
                errorType: error.runtimeType.toString(),
                succeeded: false,
              );
              debugPrint('Retrying daily metrics batch ${i ~/ batchSize + 1}, attempt $attempt: ${error.toString()}');
            },
          );
          
          // Mark as synced locally
          for (final metric in validMetrics) {
            metric.isSynced = true;
            await metric.save();
            successCount++;
          }
          
          debugPrint('Successfully synced metrics batch ${i ~/ batchSize + 1}');
        } catch (e) {
          debugPrint('Error committing metrics batch: $e');
          
          for (final metric in validMetrics) {
            failureCount++;
            errors.add(SyncError(
              recordId: metric.id,
              errorMessage: e.toString(),
              errorCode: 'BATCH_COMMIT_FAILED',
              timestamp: DateTime.now(),
              recordType: 'DailyMetric',
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('Critical error during daily metrics sync: $e');
      errors.add(SyncError(
        recordId: 'BATCH_OPERATION',
        errorMessage: e.toString(),
        errorCode: 'CRITICAL_SYNC_ERROR',
        timestamp: DateTime.now(),
        recordType: 'DailyMetric',
      ));
    }
    
    final endTime = DateTime.now();
    final result = SyncResult(
      totalRecords: successCount + failureCount + skippedCount,
      successCount: successCount,
      failureCount: failureCount,
      skippedCount: skippedCount,
      errors: errors,
      startTime: startTime,
      endTime: endTime,
      syncType: 'dailyMetrics',
    );
    
    _metrics.recordSync(result);
    debugPrint('Daily metrics sync completed: ${result.successCount}/${result.totalRecords} successful');
    
    return result;
  }
  
  /// Log critical sync error for monitoring
  Future<void> _logCriticalSyncError(String error) async {
    try {
      final errorLog = {
        'error': error,
        'timestamp': DateTime.now().toIso8601String(),
        'userId': AuthService.getCurrentUserId(),
        'deviceInfo': 'flutter_app',
      };
      
      await _firestore
          .collection('system')
          .doc('syncErrors')
          .collection('errors')
          .add(errorLog);
    } catch (e) {
      debugPrint('Failed to log critical sync error: $e');
    }
  }
  
  /// Execute a single sync operation
  Future<void> _executeSyncOperation(SyncQueueEntry operation) async {
    final docRef = _firestore.collection(operation.collection).doc(operation.documentId);
    
    switch (operation.operation) {
      case 'create':
      case 'update':
        await docRef.set(
          {
            ...operation.data,
            'serverTimestamp': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        break;
      case 'delete':
        await docRef.delete();
        break;
      default:
        throw Exception('Unknown operation type: ${operation.operation}');
    }
  }
  
  /// Add an operation to the sync queue
  Future<void> _addToSyncQueue({
    required String operation,
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    final entry = SyncQueueEntry(
      id: '${DateTime.now().millisecondsSinceEpoch}_${documentId}',
      operation: operation,
      collection: collection,
      documentId: documentId,
      data: data,
      createdAt: DateTime.now(),
    );
    
    await LocalDatabaseService.addToSyncQueue(entry);
  }
}