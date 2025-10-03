import 'package:flutter/foundation.dart';
import '../models/thermal_log.dart';
import 'thermal_log_service.dart';
import 'thermal_log_firestore_service.dart';
import 'auth_service.dart';
import 'connection_service.dart';

/// Service for synchronizing ThermalLog data between Hive (local) and Firestore (cloud)
class ThermalLogSyncService {
  static bool _isSyncing = false;
  static DateTime? _lastSyncTime;

  /// Get the last sync timestamp
  static DateTime? get lastSyncTime => _lastSyncTime;

  /// Check if sync is currently running
  static bool get isSyncing => _isSyncing;

  /// Push all local data to Firestore (Task 17)
  static Future<SyncResult> pushToCloud() async {
    if (_isSyncing) {
      return SyncResult.failure('Sync already in progress');
    }

    if (!AuthService.isAuthenticated) {
      return SyncResult.failure('User not authenticated');
    }

    // Check connectivity
    final connectionService = ConnectionService();
    final hasConnection = await connectionService.checkConnectivity();
    if (!hasConnection) {
      return SyncResult.failure('No internet connection');
    }

    _isSyncing = true;

    try {
      debugPrint('🔄 Starting push sync (Hive → Firestore)');

      // Get all local data
      final localLogs = await ThermalLogService.getAll();
      debugPrint('📱 Found ${localLogs.length} local thermal logs');

      if (localLogs.isEmpty) {
        _isSyncing = false;
        _lastSyncTime = DateTime.now();
        return SyncResult.success(0, 0, 'No local data to sync');
      }

      // For MVP simplicity: push all local data to cloud
      // In production, you'd track sync status per record
      int successful = 0;
      int failed = 0;
      List<String> errors = [];

      for (final log in localLogs) {
        try {
          // Check if exists in cloud first
          final existingLog = await ThermalLogFirestoreService.getById(log.id);

          if (existingLog != null) {
            // Update if local is newer
            if (log.updatedAt.isAfter(existingLog.updatedAt)) {
              await ThermalLogFirestoreService.update(log);
              successful++;
              debugPrint('⬆️ Updated cloud log: ${log.id}');
            } else {
              debugPrint('⏭️ Skipped log (cloud is newer): ${log.id}');
            }
          } else {
            // Create new in cloud
            await ThermalLogFirestoreService.create(log);
            successful++;
            debugPrint('⬆️ Created cloud log: ${log.id}');
          }
        } catch (e) {
          failed++;
          errors.add('Log ${log.id}: $e');
          debugPrint('❌ Failed to sync log ${log.id}: $e');
        }
      }

      _lastSyncTime = DateTime.now();

      if (failed == 0) {
        debugPrint('✅ Push sync completed successfully: $successful synced');
        return SyncResult.success(successful, failed, 'All data synced to cloud');
      } else {
        debugPrint('⚠️ Push sync completed with errors: $successful synced, $failed failed');
        return SyncResult.partial(successful, failed, 'Some data failed to sync', errors);
      }

    } catch (e) {
      debugPrint('💥 Push sync failed: $e');
      return SyncResult.failure('Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Pull all cloud data to local storage (Task 18)
  static Future<SyncResult> pullFromCloud() async {
    if (_isSyncing) {
      return SyncResult.failure('Sync already in progress');
    }

    if (!AuthService.isAuthenticated) {
      return SyncResult.failure('User not authenticated');
    }

    // Check connectivity
    final connectionService = ConnectionService();
    final hasConnection = await connectionService.checkConnectivity();
    if (!hasConnection) {
      return SyncResult.failure('No internet connection');
    }

    _isSyncing = true;

    try {
      debugPrint('🔄 Starting pull sync (Firestore → Hive)');

      // Get all cloud data
      final cloudLogs = await ThermalLogFirestoreService.getAll();
      debugPrint('☁️ Found ${cloudLogs.length} cloud thermal logs');

      if (cloudLogs.isEmpty) {
        _isSyncing = false;
        _lastSyncTime = DateTime.now();
        return SyncResult.success(0, 0, 'No cloud data to sync');
      }

      int successful = 0;
      int failed = 0;
      List<String> errors = [];

      for (final cloudLog in cloudLogs) {
        try {
          // Check if exists locally
          final localLog = await ThermalLogService.getById(cloudLog.id);

          if (localLog != null) {
            // "Cloud always wins" strategy for MVP
            if (cloudLog.updatedAt.isAfter(localLog.updatedAt)) {
              await ThermalLogService.save(cloudLog);
              successful++;
              debugPrint('⬇️ Updated local log: ${cloudLog.id}');
            } else {
              debugPrint('⏭️ Skipped log (local is newer): ${cloudLog.id}');
            }
          } else {
            // Save new from cloud
            await ThermalLogService.save(cloudLog);
            successful++;
            debugPrint('⬇️ Created local log: ${cloudLog.id}');
          }
        } catch (e) {
          failed++;
          errors.add('Log ${cloudLog.id}: $e');
          debugPrint('❌ Failed to sync log ${cloudLog.id}: $e');
        }
      }

      _lastSyncTime = DateTime.now();

      if (failed == 0) {
        debugPrint('✅ Pull sync completed successfully: $successful synced');
        return SyncResult.success(successful, failed, 'All data synced from cloud');
      } else {
        debugPrint('⚠️ Pull sync completed with errors: $successful synced, $failed failed');
        return SyncResult.partial(successful, failed, 'Some data failed to sync', errors);
      }

    } catch (e) {
      debugPrint('💥 Pull sync failed: $e');
      return SyncResult.failure('Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Bi-directional sync (pull then push)
  static Future<SyncResult> fullSync() async {
    if (_isSyncing) {
      return SyncResult.failure('Sync already in progress');
    }

    try {
      debugPrint('🔄 Starting full sync (bi-directional)');

      // First pull from cloud (cloud always wins for conflicts)
      final pullResult = await pullFromCloud();
      if (!pullResult.isSuccess && !pullResult.isPartial) {
        return pullResult;
      }

      // Then push local changes to cloud
      final pushResult = await pushToCloud();
      if (!pushResult.isSuccess && !pushResult.isPartial) {
        return pushResult;
      }

      // Combine results
      final totalSynced = pullResult.successCount + pushResult.successCount;
      final totalFailed = pullResult.failureCount + pushResult.failureCount;

      if (totalFailed == 0) {
        return SyncResult.success(totalSynced, totalFailed, 'Full sync completed successfully');
      } else {
        final errors = [...pullResult.errors, ...pushResult.errors];
        return SyncResult.partial(totalSynced, totalFailed, 'Full sync completed with some errors', errors);
      }

    } catch (e) {
      debugPrint('💥 Full sync failed: $e');
      return SyncResult.failure('Full sync failed: $e');
    }
  }

  /// Get sync status for UI
  static Future<Map<String, dynamic>> getSyncStatus() async {
    final localCount = await ThermalLogService.getCount();

    int cloudCount = 0;
    if (AuthService.isAuthenticated) {
      try {
        final cloudLogs = await ThermalLogFirestoreService.getAll();
        cloudCount = cloudLogs.length;
      } catch (e) {
        debugPrint('Failed to get cloud count: $e');
      }
    }

    return {
      'localCount': localCount,
      'cloudCount': cloudCount,
      'lastSync': _lastSyncTime?.toIso8601String(),
      'isSyncing': _isSyncing,
      'isAuthenticated': AuthService.isAuthenticated,
    };
  }
}

/// Result of a sync operation
class SyncResult {
  final bool isSuccess;
  final bool isPartial;
  final int successCount;
  final int failureCount;
  final String message;
  final List<String> errors;

  SyncResult._({
    required this.isSuccess,
    required this.isPartial,
    required this.successCount,
    required this.failureCount,
    required this.message,
    required this.errors,
  });

  factory SyncResult.success(int successCount, int failureCount, String message) {
    return SyncResult._(
      isSuccess: true,
      isPartial: false,
      successCount: successCount,
      failureCount: failureCount,
      message: message,
      errors: [],
    );
  }

  factory SyncResult.partial(int successCount, int failureCount, String message, List<String> errors) {
    return SyncResult._(
      isSuccess: false,
      isPartial: true,
      successCount: successCount,
      failureCount: failureCount,
      message: message,
      errors: errors,
    );
  }

  factory SyncResult.failure(String message) {
    return SyncResult._(
      isSuccess: false,
      isPartial: false,
      successCount: 0,
      failureCount: 0,
      message: message,
      errors: [],
    );
  }

  @override
  String toString() {
    if (isSuccess) return 'SUCCESS: $message ($successCount synced)';
    if (isPartial) return 'PARTIAL: $message ($successCount synced, $failureCount failed)';
    return 'FAILURE: $message';
  }
}