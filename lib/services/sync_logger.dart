import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/sync_models.dart';
import '../models/conflict_resolution_models.dart';
import '../models/sync_checkpoint_models.dart';
import 'retry_service.dart';

/// Log levels for different types of sync events
enum SyncLogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

/// Enhanced logging service for sync operations with detailed monitoring
class SyncLogger {
  static final SyncLogger _instance = SyncLogger._internal();
  factory SyncLogger() => _instance;
  SyncLogger._internal();

  final List<SyncLogEntry> _logEntries = [];
  final Map<String, SyncSessionMetrics> _sessionMetrics = {};

  /// Log a sync operation event
  void logSyncEvent({
    required SyncLogLevel level,
    required String operation,
    required String message,
    Map<String, dynamic>? metadata,
    Exception? error,
    String? checkpointId,
  }) {
    final entry = SyncLogEntry(
      timestamp: DateTime.now(),
      level: level,
      operation: operation,
      message: message,
      metadata: metadata ?? {},
      error: error?.toString(),
      checkpointId: checkpointId,
    );

    _logEntries.add(entry);
    
    // Also print to debug console with appropriate formatting
    _printToConsole(entry);

    // Keep only recent entries to prevent memory growth
    if (_logEntries.length > 1000) {
      _logEntries.removeRange(0, _logEntries.length - 1000);
    }
  }

  /// Log sync operation start
  void logSyncStart(String operation, Map<String, dynamic> context) {
    logSyncEvent(
      level: SyncLogLevel.info,
      operation: operation,
      message: 'Sync operation started',
      metadata: {
        'context': context,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Log sync operation completion
  void logSyncComplete(String operation, SyncResult result, {String? checkpointId}) {
    final level = result.hasErrors ? SyncLogLevel.warning : SyncLogLevel.info;
    
    logSyncEvent(
      level: level,
      operation: operation,
      message: 'Sync operation completed',
      metadata: {
        'result': result.toJson(),
        'duration': result.duration.inMilliseconds,
        'successRate': result.successRate,
      },
      checkpointId: checkpointId,
    );
  }

  /// Log sync operation error
  void logSyncError(String operation, Exception error, {String? checkpointId, Map<String, dynamic>? context}) {
    logSyncEvent(
      level: SyncLogLevel.error,
      operation: operation,
      message: 'Sync operation failed',
      metadata: context,
      error: error,
      checkpointId: checkpointId,
    );
  }

  /// Log conflict resolution
  void logConflictResolution(DataConflict conflict, ConflictResolutionResult? result) {
    final level = result?.wasResolved == true ? SyncLogLevel.info : SyncLogLevel.warning;
    
    logSyncEvent(
      level: level,
      operation: 'conflict_resolution',
      message: 'Conflict ${result?.wasResolved == true ? 'resolved' : 'failed to resolve'}',
      metadata: {
        'conflictType': conflict.type.name,
        'recordId': conflict.recordId,
        'strategy': result?.strategy.name,
        'wasResolved': result?.wasResolved,
        'errorMessage': result?.errorMessage,
      },
    );
  }

  /// Log retry attempt
  void logRetryAttempt(String operation, int attempt, Exception error, Duration delay) {
    logSyncEvent(
      level: SyncLogLevel.warning,
      operation: operation,
      message: 'Retry attempt $attempt',
      metadata: {
        'attempt': attempt,
        'delayMs': delay.inMilliseconds,
        'error': error.toString(),
      },
      error: error,
    );
  }

  /// Log checkpoint operations
  void logCheckpoint(String operation, SyncCheckpoint checkpoint) {
    logSyncEvent(
      level: SyncLogLevel.info,
      operation: 'checkpoint',
      message: operation,
      metadata: {
        'checkpointId': checkpoint.id,
        'syncType': checkpoint.syncType,
        'progress': checkpoint.progressPercentage,
        'processedRecords': checkpoint.processedRecords,
        'totalRecords': checkpoint.totalRecords,
        'elapsedTime': checkpoint.elapsedTime.inMilliseconds,
      },
      checkpointId: checkpoint.id,
    );
  }

  /// Log network connectivity changes
  void logConnectivityChange(bool isConnected) {
    logSyncEvent(
      level: SyncLogLevel.info,
      operation: 'connectivity',
      message: 'Network connectivity ${isConnected ? 'restored' : 'lost'}',
      metadata: {
        'isConnected': isConnected,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Print log entry to console with appropriate formatting
  void _printToConsole(SyncLogEntry entry) {
    final timestamp = entry.timestamp.toIso8601String();
    final level = entry.level.name.toUpperCase();
    final operation = entry.operation.toUpperCase();
    
    String logLine = '[$timestamp] $level [$operation] ${entry.message}';
    
    if (entry.metadata.isNotEmpty) {
      final metadataStr = json.encode(entry.metadata);
      logLine += ' | Metadata: $metadataStr';
    }
    
    if (entry.error != null) {
      logLine += ' | Error: ${entry.error}';
    }

    // Use appropriate print method based on log level
    switch (entry.level) {
      case SyncLogLevel.debug:
        debugPrint('🔍 $logLine');
        break;
      case SyncLogLevel.info:
        debugPrint('ℹ️ $logLine');
        break;
      case SyncLogLevel.warning:
        debugPrint('⚠️ $logLine');
        break;
      case SyncLogLevel.error:
        debugPrint('❌ $logLine');
        break;
      case SyncLogLevel.critical:
        debugPrint('🚨 $logLine');
        break;
    }
  }

  /// Get recent log entries
  List<SyncLogEntry> getRecentLogs({int limit = 100, SyncLogLevel? minLevel}) {
    var logs = _logEntries.toList();
    
    if (minLevel != null) {
      logs = logs.where((log) => log.level.index >= minLevel.index).toList();
    }
    
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return logs.take(limit).toList();
  }

  /// Get logs for a specific operation
  List<SyncLogEntry> getOperationLogs(String operation, {int limit = 50}) {
    return _logEntries
        .where((log) => log.operation == operation)
        .toList()
        .reversed
        .take(limit)
        .toList();
  }

  /// Get logs for a specific checkpoint
  List<SyncLogEntry> getCheckpointLogs(String checkpointId) {
    return _logEntries
        .where((log) => log.checkpointId == checkpointId)
        .toList();
  }

  /// Get sync performance summary
  Map<String, dynamic> getPerformanceSummary({Duration? timeWindow}) {
    final cutoff = timeWindow != null 
        ? DateTime.now().subtract(timeWindow)
        : DateTime.now().subtract(const Duration(hours: 24));
    
    final recentLogs = _logEntries.where((log) => log.timestamp.isAfter(cutoff)).toList();
    
    final operationCounts = <String, int>{};
    final errorCounts = <String, int>{};
    final successCounts = <String, int>{};
    
    for (final log in recentLogs) {
      operationCounts[log.operation] = (operationCounts[log.operation] ?? 0) + 1;
      
      if (log.level == SyncLogLevel.error || log.level == SyncLogLevel.critical) {
        errorCounts[log.operation] = (errorCounts[log.operation] ?? 0) + 1;
      } else if (log.level == SyncLogLevel.info && log.message.contains('completed')) {
        successCounts[log.operation] = (successCounts[log.operation] ?? 0) + 1;
      }
    }
    
    return {
      'timeWindow': timeWindow?.inHours ?? 24,
      'totalLogEntries': recentLogs.length,
      'operationCounts': operationCounts,
      'errorCounts': errorCounts,
      'successCounts': successCounts,
      'errorRate': recentLogs.isNotEmpty 
          ? (recentLogs.where((l) => l.level.index >= SyncLogLevel.error.index).length / recentLogs.length * 100)
          : 0,
    };
  }

  /// Export logs for analysis
  Map<String, dynamic> exportLogs({SyncLogLevel? minLevel, Duration? timeWindow}) {
    final logs = getRecentLogs(
      limit: 10000,
      minLevel: minLevel,
    );
    
    final filtered = timeWindow != null
        ? logs.where((log) => 
            log.timestamp.isAfter(DateTime.now().subtract(timeWindow))).toList()
        : logs;
    
    return {
      'exportTime': DateTime.now().toIso8601String(),
      'filters': {
        'minLevel': minLevel?.name,
        'timeWindowHours': timeWindow?.inHours,
      },
      'totalEntries': filtered.length,
      'logs': filtered.map((log) => log.toJson()).toList(),
      'summary': getPerformanceSummary(timeWindow: timeWindow),
    };
  }

  /// Clear old log entries
  void clearOldLogs({Duration maxAge = const Duration(days: 7)}) {
    final cutoff = DateTime.now().subtract(maxAge);
    _logEntries.removeWhere((log) => log.timestamp.isBefore(cutoff));
  }
}

/// Individual sync log entry
class SyncLogEntry {
  final DateTime timestamp;
  final SyncLogLevel level;
  final String operation;
  final String message;
  final Map<String, dynamic> metadata;
  final String? error;
  final String? checkpointId;

  SyncLogEntry({
    required this.timestamp,
    required this.level,
    required this.operation,
    required this.message,
    this.metadata = const {},
    this.error,
    this.checkpointId,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'operation': operation,
      'message': message,
      'metadata': metadata,
      'error': error,
      'checkpointId': checkpointId,
    };
  }
}

/// Metrics for tracking sync session performance
class SyncSessionMetrics {
  final String sessionId;
  final DateTime startTime;
  final Map<String, int> operationCounts = {};
  final Map<String, Duration> operationDurations = {};
  final Map<String, int> errorCounts = {};
  final List<String> checkpointIds = [];

  SyncSessionMetrics({
    required this.sessionId,
    required this.startTime,
  });

  void recordOperation(String operation, Duration duration, bool success) {
    operationCounts[operation] = (operationCounts[operation] ?? 0) + 1;
    operationDurations[operation] = 
        (operationDurations[operation] ?? Duration.zero) + duration;
    
    if (!success) {
      errorCounts[operation] = (errorCounts[operation] ?? 0) + 1;
    }
  }

  void addCheckpoint(String checkpointId) {
    checkpointIds.add(checkpointId);
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'startTime': startTime.toIso8601String(),
      'duration': DateTime.now().difference(startTime).inMilliseconds,
      'operationCounts': operationCounts,
      'operationDurations': operationDurations.map((k, v) => MapEntry(k, v.inMilliseconds)),
      'errorCounts': errorCounts,
      'checkpointIds': checkpointIds,
    };
  }
}