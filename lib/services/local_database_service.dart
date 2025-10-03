import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/hive_models.dart';
import '../models/thermal_reading.dart';
import '../services/auth_service.dart';

/// Service for managing local database operations using Hive
class LocalDatabaseService {
  static const String _logEntriesBox = 'logEntries';
  static const String _dailyMetricsBox = 'dailyMetrics';
  static const String _userSessionsBox = 'userSessions';
  static const String _cachedProjectsBox = 'cachedProjects';
  static const String _syncQueueBox = 'syncQueue';

  // ============ LOG ENTRY OPERATIONS ============

  /// Create or update a log entry
  static Future<void> saveLogEntry(LogEntry entry) async {
    try {
      final box = Hive.box<LogEntry>(_logEntriesBox);
      await box.put(entry.id, entry);
      debugPrint('Log entry saved: ${entry.id}');
    } catch (e) {
      debugPrint('Error saving log entry: $e');
      throw Exception('Failed to save log entry');
    }
  }

  /// Get a specific log entry by ID
  static Future<LogEntry?> getLogEntry(String id) async {
    try {
      final box = Hive.box<LogEntry>(_logEntriesBox);
      return box.get(id);
    } catch (e) {
      debugPrint('Error getting log entry: $e');
      return null;
    }
  }

  /// Get all log entries for a specific project
  static Future<List<LogEntry>> getProjectLogEntries(String projectId) async {
    try {
      final box = Hive.box<LogEntry>(_logEntriesBox);
      return box.values
          .where((entry) => entry.projectId == projectId)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('Error getting project log entries: $e');
      return [];
    }
  }

  /// Get all log entries for a specific date
  static Future<List<LogEntry>> getDateLogEntries(String date) async {
    try {
      final box = Hive.box<LogEntry>(_logEntriesBox);
      return box.values
          .where((entry) => entry.date == date)
          .toList()
        ..sort((a, b) => a.hour.compareTo(b.hour));
    } catch (e) {
      debugPrint('Error getting date log entries: $e');
      return [];
    }
  }

  /// Get all log entries for a specific project and date
  static Future<List<LogEntry>> getLogEntriesByProjectAndDate(String projectId, DateTime date) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      final box = Hive.box<LogEntry>(_logEntriesBox);
      return box.values
          .where((entry) => entry.projectId == projectId && entry.date == dateString)
          .toList()
        ..sort((a, b) => a.hour.compareTo(b.hour));
    } catch (e) {
      debugPrint('Error getting log entries by project and date: $e');
      return [];
    }
  }

  /// Get all log entries
  static Future<List<LogEntry>> getAllLogEntries() async {
    try {
      final box = Hive.box<LogEntry>(_logEntriesBox);
      return box.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('Error getting all log entries: $e');
      return [];
    }
  }

  /// Get all unsynced log entries
  static Future<List<LogEntry>> getUnsyncedLogEntries() async {
    try {
      final box = Hive.box<LogEntry>(_logEntriesBox);
      return box.values
          .where((entry) => !entry.isSynced)
          .toList();
    } catch (e) {
      debugPrint('Error getting unsynced log entries: $e');
      return [];
    }
  }

  /// Get unsynced log entries in batches with timestamp preparation
  static Future<List<LogEntry>> getUnsyncedLogEntriesBatch({
    int batchSize = 50,
    bool prepareForSync = true,
  }) async {
    try {
      final box = Hive.box<LogEntry>(_logEntriesBox);
      final currentTime = DateTime.now();
      
      final unsyncedEntries = box.values
          .where((entry) => !entry.isSynced)
          .take(batchSize)
          .toList();
      
      if (prepareForSync) {
        // Add sync timestamp to each entry with validation
        for (final entry in unsyncedEntries) {
          final proposedSyncTime = currentTime;

          // Validate timestamp to prevent backdating attacks
          if (!validateSyncTimestamp(proposedSyncTime, entry.createdAt)) {
            debugPrint('❌ Sync timestamp validation failed for entry ${entry.id}');
            throw Exception('Invalid sync timestamp: potential backdating attack detected');
          }

          entry.syncTimestamp = proposedSyncTime;
          await entry.save();
        }
      }
      
      return unsyncedEntries;
    } catch (e) {
      debugPrint('Error getting unsynced log entries batch: $e');
      return [];
    }
  }

  /// Validate timestamp to ensure no backdating or future timestamps
  static bool validateSyncTimestamp(DateTime? timestamp, DateTime? originalCreatedAt) {
    if (timestamp == null) {
      debugPrint('❌ Sync timestamp validation failed: timestamp is null');
      return false;
    }

    final now = DateTime.now();

    // Sync timestamp must be after or equal to the creation time
    if (originalCreatedAt != null && timestamp.isBefore(originalCreatedAt)) {
      debugPrint('❌ Sync timestamp validation failed: attempting to backdate from ${originalCreatedAt} to ${timestamp}');
      return false;
    }

    // Sync timestamp cannot be more than 5 minutes in the future (clock drift tolerance)
    final fiveMinutesFromNow = now.add(const Duration(minutes: 5));
    if (timestamp.isAfter(fiveMinutesFromNow)) {
      debugPrint('❌ Sync timestamp validation failed: timestamp ${timestamp} is too far in the future (current: ${now})');
      return false;
    }

    // Sync timestamp cannot be more than 24 hours in the past (reasonable sync delay)
    final oneDayAgo = now.subtract(const Duration(days: 1));
    if (timestamp.isBefore(oneDayAgo)) {
      debugPrint('❌ Sync timestamp validation failed: timestamp ${timestamp} is too old (current: ${now})');
      return false;
    }

    debugPrint('✅ Sync timestamp validation passed for ${timestamp}');
    return true;
  }

  /// Update log entry sync status
  static Future<void> updateLogEntrySyncStatus(String id, bool isSynced, [String? syncError]) async {
    try {
      final box = Hive.box<LogEntry>(_logEntriesBox);
      final entry = box.get(id);
      if (entry != null) {
        entry.isSynced = isSynced;
        entry.syncError = syncError;
        entry.updatedAt = DateTime.now();
        
        // If marking as synced and no syncTimestamp, add it now
        if (isSynced && entry.syncTimestamp == null) {
          final proposedSyncTime = DateTime.now();

          // Validate timestamp before setting
          if (!validateSyncTimestamp(proposedSyncTime, entry.createdAt)) {
            debugPrint('❌ Sync timestamp validation failed for entry ${entry.id}');
            throw Exception('Invalid sync timestamp: cannot backdate entry');
          }

          entry.syncTimestamp = proposedSyncTime;
        }
        
        await entry.save();
        debugPrint('Log entry sync status updated: $id');
      }
    } catch (e) {
      debugPrint('Error updating log entry sync status: $e');
    }
  }

  /// Delete a log entry
  static Future<void> deleteLogEntry(String id) async {
    try {
      final box = Hive.box<LogEntry>(_logEntriesBox);
      await box.delete(id);
      debugPrint('Log entry deleted: $id');
    } catch (e) {
      debugPrint('Error deleting log entry: $e');
      throw Exception('Failed to delete log entry');
    }
  }

  /// Clear all log entries
  static Future<void> clearAllLogEntries() async {
    try {
      final box = Hive.box<LogEntry>(_logEntriesBox);
      await box.clear();
      debugPrint('All log entries cleared');
    } catch (e) {
      debugPrint('Error clearing log entries: $e');
    }
  }

  // ============ DAILY METRIC OPERATIONS ============

  /// Save or update a daily metric
  static Future<void> saveDailyMetric(DailyMetric metric) async {
    try {
      final box = Hive.box<DailyMetric>(_dailyMetricsBox);
      await box.put(metric.id, metric);
      debugPrint('Daily metric saved: ${metric.id}');
    } catch (e) {
      debugPrint('Error saving daily metric: $e');
      throw Exception('Failed to save daily metric');
    }
  }

  /// Get a specific daily metric
  static Future<DailyMetric?> getDailyMetric(String id) async {
    try {
      final box = Hive.box<DailyMetric>(_dailyMetricsBox);
      return box.get(id);
    } catch (e) {
      debugPrint('Error getting daily metric: $e');
      return null;
    }
  }

  /// Get daily metric for a specific project and date
  static Future<DailyMetric?> getProjectDailyMetric(String projectId, String date) async {
    try {
      final box = Hive.box<DailyMetric>(_dailyMetricsBox);
      return box.values.firstWhere(
        (metric) => metric.projectId == projectId && metric.date == date,
        orElse: () => null as DailyMetric,
      );
    } catch (e) {
      debugPrint('Error getting project daily metric: $e');
      return null;
    }
  }

  /// Get all daily metrics for a project
  static Future<List<DailyMetric>> getProjectDailyMetrics(String projectId) async {
    try {
      final box = Hive.box<DailyMetric>(_dailyMetricsBox);
      return box.values
          .where((metric) => metric.projectId == projectId)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      debugPrint('Error getting project daily metrics: $e');
      return [];
    }
  }

  /// Get all daily metrics
  static Future<List<DailyMetric>> getAllDailyMetrics() async {
    try {
      final box = Hive.box<DailyMetric>(_dailyMetricsBox);
      return box.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      debugPrint('Error getting all daily metrics: $e');
      return [];
    }
  }

  /// Get unsynced daily metrics in batches with timestamp preparation
  static Future<List<DailyMetric>> getUnsyncedDailyMetricsBatch({
    int batchSize = 50,
    bool prepareForSync = true,
  }) async {
    try {
      final box = Hive.box<DailyMetric>(_dailyMetricsBox);
      final currentTime = DateTime.now();
      
      final unsyncedMetrics = box.values
          .where((metric) => !metric.isSynced)
          .take(batchSize)
          .toList();
      
      if (prepareForSync) {
        // Add sync timestamp to each metric with validation
        for (final metric in unsyncedMetrics) {
          final proposedSyncTime = currentTime;

          // Validate timestamp to prevent backdating attacks
          if (!validateSyncTimestamp(proposedSyncTime, metric.createdAt)) {
            debugPrint('❌ Sync timestamp validation failed for metric ${metric.id}');
            throw Exception('Invalid sync timestamp: potential backdating attack detected');
          }

          metric.syncTimestamp = proposedSyncTime;
          await metric.save();
        }
      }
      
      return unsyncedMetrics;
    } catch (e) {
      debugPrint('Error getting unsynced daily metrics batch: $e');
      return [];
    }
  }

  /// Update daily metric completion status
  static Future<void> updateDailyMetricStatus(String id, String status, int completedEntries) async {
    try {
      final box = Hive.box<DailyMetric>(_dailyMetricsBox);
      final metric = box.get(id);
      if (metric != null) {
        metric.completionStatus = status;
        metric.completedEntries = completedEntries;
        metric.updatedAt = DateTime.now();
        await metric.save();
        debugPrint('Daily metric status updated: $id');
      }
    } catch (e) {
      debugPrint('Error updating daily metric status: $e');
    }
  }

  /// Lock/unlock a daily metric
  static Future<void> updateDailyMetricLock(String id, bool isLocked) async {
    try {
      final box = Hive.box<DailyMetric>(_dailyMetricsBox);
      final metric = box.get(id);
      if (metric != null) {
        metric.isLocked = isLocked;
        metric.updatedAt = DateTime.now();
        await metric.save();
        debugPrint('Daily metric lock updated: $id');
      }
    } catch (e) {
      debugPrint('Error updating daily metric lock: $e');
    }
  }

  // ============ USER SESSION OPERATIONS ============

  /// Save or update user session
  static Future<void> saveUserSession(UserSession session) async {
    try {
      final box = Hive.box<UserSession>(_userSessionsBox);
      await box.put(session.userId, session);
      debugPrint('User session saved: ${session.userId}');
    } catch (e) {
      debugPrint('Error saving user session: $e');
      throw Exception('Failed to save user session');
    }
  }

  /// Get current user session
  static Future<UserSession?> getCurrentUserSession() async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) return null;
      
      final box = Hive.box<UserSession>(_userSessionsBox);
      return box.get(userId);
    } catch (e) {
      debugPrint('Error getting current user session: $e');
      return null;
    }
  }

  /// Update user session activity
  static Future<void> updateSessionActivity() async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) return;
      
      final box = Hive.box<UserSession>(_userSessionsBox);
      final session = box.get(userId);
      if (session != null) {
        session.updateActivity();
        await session.save();
      }
    } catch (e) {
      debugPrint('Error updating session activity: $e');
    }
  }

  /// Update current project in session
  static Future<void> updateCurrentProject(String projectId, String projectName) async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) return;
      
      final box = Hive.box<UserSession>(_userSessionsBox);
      final session = box.get(userId);
      if (session != null) {
        session.currentProjectId = projectId;
        session.currentProjectName = projectName;
        
        // Add to recent projects if not already there
        if (!session.recentProjects.contains(projectId)) {
          session.recentProjects = [
            projectId,
            ...session.recentProjects.take(4),
          ];
        }
        
        session.updateActivity();
        await session.save();
      }
    } catch (e) {
      debugPrint('Error updating current project: $e');
    }
  }

  /// Clear user session
  static Future<void> clearUserSession() async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) return;
      
      final box = Hive.box<UserSession>(_userSessionsBox);
      await box.delete(userId);
      debugPrint('User session cleared');
    } catch (e) {
      debugPrint('Error clearing user session: $e');
    }
  }

  // ============ CACHED PROJECT OPERATIONS ============

  /// Cache a project for offline use
  static Future<void> cacheProject(CachedProject project) async {
    try {
      final box = Hive.box<CachedProject>(_cachedProjectsBox);
      await box.put(project.projectId, project);
      debugPrint('Project cached: ${project.projectId}');
    } catch (e) {
      debugPrint('Error caching project: $e');
      throw Exception('Failed to cache project');
    }
  }

  /// Get a cached project
  static Future<CachedProject?> getCachedProject(String projectId) async {
    try {
      final box = Hive.box<CachedProject>(_cachedProjectsBox);
      return box.get(projectId);
    } catch (e) {
      debugPrint('Error getting cached project: $e');
      return null;
    }
  }

  /// Get all cached projects for the current user
  static Future<List<CachedProject>> getUserCachedProjects() async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) return [];
      
      final box = Hive.box<CachedProject>(_cachedProjectsBox);
      return box.values
          .where((project) => project.createdBy == userId)
          .toList()
        ..sort((a, b) => b.cachedAt.compareTo(a.cachedAt));
    } catch (e) {
      debugPrint('Error getting user cached projects: $e');
      return [];
    }
  }

  /// Clear all cached projects
  static Future<void> clearCachedProjects() async {
    try {
      final box = Hive.box<CachedProject>(_cachedProjectsBox);
      await box.clear();
      debugPrint('All cached projects cleared');
    } catch (e) {
      debugPrint('Error clearing cached projects: $e');
    }
  }

  // ============ THERMAL READING OPERATIONS ============

  /// Save thermal reading to Hive
  static Future<void> saveThermalReading(String projectId, String logDate, ThermalReading reading) async {
    try {
      final box = Hive.box<ThermalReading>('thermalReadings');
      final key = '${projectId}_${logDate}_${reading.hour}';
      await box.put(key, reading);
      debugPrint('Thermal reading saved: $key');
    } catch (e) {
      debugPrint('Error saving thermal reading: $e');
      throw Exception('Failed to save thermal reading');
    }
  }

  /// Get thermal reading for specific hour
  static Future<ThermalReading?> getThermalReading(String projectId, String logDate, int hour) async {
    try {
      final box = Hive.box<ThermalReading>('thermalReadings');
      final key = '${projectId}_${logDate}_$hour';
      return box.get(key);
    } catch (e) {
      debugPrint('Error getting thermal reading: $e');
      return null;
    }
  }

  /// Get all thermal readings for a specific day
  static Future<List<ThermalReading>> getThermalReadingsForDay(String projectId, String logDate) async {
    try {
      final box = Hive.box<ThermalReading>('thermalReadings');
      final keyPrefix = '${projectId}_$logDate';
      
      return box.keys
          .where((key) => key.toString().startsWith(keyPrefix))
          .map((key) => box.get(key))
          .where((reading) => reading != null)
          .cast<ThermalReading>()
          .toList()
        ..sort((a, b) => a.hour.compareTo(b.hour));
    } catch (e) {
      debugPrint('Error getting thermal readings for day: $e');
      return [];
    }
  }

  /// Get completed hours for a specific project and date
  static Future<Set<int>> getCompletedHours(String projectId, String logDate) async {
    try {
      final readings = await getThermalReadingsForDay(projectId, logDate);
      return readings
          .where((reading) => reading.validated)
          .map((reading) => reading.hour)
          .toSet();
    } catch (e) {
      debugPrint('Error getting completed hours: $e');
      return <int>{};
    }
  }

  // ============ SYNC QUEUE OPERATIONS ============

  /// Add operation to sync queue
  static Future<void> addToSyncQueue(SyncQueueEntry entry) async {
    try {
      final box = Hive.box<SyncQueueEntry>(_syncQueueBox);
      await box.put(entry.id, entry);
      debugPrint('Added to sync queue: ${entry.id}');
    } catch (e) {
      debugPrint('Error adding to sync queue: $e');
      throw Exception('Failed to add to sync queue');
    }
  }

  /// Get all pending sync operations
  static Future<List<SyncQueueEntry>> getPendingSyncOperations() async {
    try {
      final box = Hive.box<SyncQueueEntry>(_syncQueueBox);
      return box.values.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } catch (e) {
      debugPrint('Error getting pending sync operations: $e');
      return [];
    }
  }

  /// Update sync queue entry after attempt
  static Future<void> updateSyncQueueEntry(String id, {String? error, bool remove = false}) async {
    try {
      final box = Hive.box<SyncQueueEntry>(_syncQueueBox);
      
      if (remove) {
        await box.delete(id);
        debugPrint('Sync queue entry removed: $id');
      } else {
        final entry = box.get(id);
        if (entry != null) {
          entry.retryCount++;
          entry.lastError = error;
          entry.lastAttempt = DateTime.now();
          await entry.save();
          debugPrint('Sync queue entry updated: $id');
        }
      }
    } catch (e) {
      debugPrint('Error updating sync queue entry: $e');
    }
  }

  /// Clear sync queue
  static Future<void> clearSyncQueue() async {
    try {
      final box = Hive.box<SyncQueueEntry>(_syncQueueBox);
      await box.clear();
      debugPrint('Sync queue cleared');
    } catch (e) {
      debugPrint('Error clearing sync queue: $e');
    }
  }

  // ============ UTILITY OPERATIONS ============

  /// Get database statistics
  static Future<Map<String, dynamic>> getDatabaseStats() async {
    try {
      final logBox = Hive.box<LogEntry>(_logEntriesBox);
      final metricsBox = Hive.box<DailyMetric>(_dailyMetricsBox);
      final projectsBox = Hive.box<CachedProject>(_cachedProjectsBox);
      final syncBox = Hive.box<SyncQueueEntry>(_syncQueueBox);
      
      final unsyncedLogs = logBox.values.where((e) => !e.isSynced).length;
      final pendingSyncs = syncBox.length;
      
      return {
        'totalLogEntries': logBox.length,
        'unsyncedLogEntries': unsyncedLogs,
        'totalDailyMetrics': metricsBox.length,
        'cachedProjects': projectsBox.length,
        'pendingSyncOperations': pendingSyncs,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error getting database stats: $e');
      return {};
    }
  }

  /// Clear all local data (use with caution)
  static Future<void> clearAllData() async {
    try {
      await clearAllLogEntries();
      await clearCachedProjects();
      await clearSyncQueue();
      
      final metricsBox = Hive.box<DailyMetric>(_dailyMetricsBox);
      await metricsBox.clear();
      
      debugPrint('All local data cleared');
    } catch (e) {
      debugPrint('Error clearing all data: $e');
    }
  }
}