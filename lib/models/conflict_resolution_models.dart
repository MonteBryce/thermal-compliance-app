/// Models and enums for conflict resolution in sync operations

import 'hive_models.dart';
import 'sync_models.dart';

/// Types of conflict resolution strategies
enum ConflictResolutionStrategy {
  /// Local changes take precedence (client wins)
  localWins,
  
  /// Remote changes take precedence (server wins)
  remoteWins,
  
  /// Timestamp-based resolution (last write wins)
  lastWriteWins,
  
  /// Merge compatible fields, fail on conflicts
  smartMerge,
  
  /// Manual resolution required
  manual,
}

/// Types of conflicts that can occur
enum ConflictType {
  /// No conflict detected
  none,
  
  /// Local record modified, remote unchanged
  localOnly,
  
  /// Remote record modified, local unchanged
  remoteOnly,
  
  /// Both local and remote records modified
  bothModified,
  
  /// Record exists locally but not remotely
  localExists,
  
  /// Record exists remotely but not locally
  remoteExists,
  
  /// Timestamp conflict (potential backdating)
  timestampViolation,
  
  /// Data type or structure mismatch
  structuralMismatch,
}

/// Represents a conflict between local and remote data
class DataConflict {
  final String recordId;
  final ConflictType type;
  final Map<String, dynamic>? localData;
  final Map<String, dynamic>? remoteData;
  final DateTime? localTimestamp;
  final DateTime? remoteTimestamp;
  final DateTime detectedAt;
  final String recordType;
  final List<String> conflictingFields;
  
  DataConflict({
    required this.recordId,
    required this.type,
    this.localData,
    this.remoteData,
    this.localTimestamp,
    this.remoteTimestamp,
    required this.detectedAt,
    required this.recordType,
    this.conflictingFields = const [],
  });
  
  /// Check if this conflict can be resolved automatically
  bool get canAutoResolve {
    switch (type) {
      case ConflictType.none:
      case ConflictType.localOnly:
      case ConflictType.remoteOnly:
      case ConflictType.localExists:
      case ConflictType.remoteExists:
        return true;
      case ConflictType.bothModified:
        return localTimestamp != null && remoteTimestamp != null;
      case ConflictType.timestampViolation:
      case ConflictType.structuralMismatch:
        return false;
    }
  }
  
  /// Check if local data is newer than remote
  bool get isLocalNewer {
    if (localTimestamp == null || remoteTimestamp == null) return false;
    return localTimestamp!.isAfter(remoteTimestamp!);
  }
  
  /// Check if remote data is newer than local
  bool get isRemoteNewer {
    if (localTimestamp == null || remoteTimestamp == null) return false;
    return remoteTimestamp!.isAfter(localTimestamp!);
  }
  
  /// Check if timestamps are equal
  bool get hasEqualTimestamps {
    if (localTimestamp == null || remoteTimestamp == null) return false;
    return localTimestamp!.isAtSameMomentAs(remoteTimestamp!);
  }
  
  /// Get human-readable conflict description
  String get description {
    switch (type) {
      case ConflictType.none:
        return 'No conflict - data is in sync';
      case ConflictType.localOnly:
        return 'Local changes only - safe to sync';
      case ConflictType.remoteOnly:
        return 'Remote changes only - safe to update local';
      case ConflictType.bothModified:
        return 'Both local and remote data modified - timestamp resolution required';
      case ConflictType.localExists:
        return 'Record exists locally but not on server';
      case ConflictType.remoteExists:
        return 'Record exists on server but not locally';
      case ConflictType.timestampViolation:
        return 'Timestamp violation detected - potential backdating attempt';
      case ConflictType.structuralMismatch:
        return 'Data structure mismatch between local and remote';
    }
  }
  
  Map<String, dynamic> toJson() {
    return {
      'recordId': recordId,
      'type': type.name,
      'localData': localData,
      'remoteData': remoteData,
      'localTimestamp': localTimestamp?.toIso8601String(),
      'remoteTimestamp': remoteTimestamp?.toIso8601String(),
      'detectedAt': detectedAt.toIso8601String(),
      'recordType': recordType,
      'conflictingFields': conflictingFields,
      'canAutoResolve': canAutoResolve,
      'description': description,
    };
  }
}

/// Result of conflict resolution operation
class ConflictResolutionResult {
  final String recordId;
  final ConflictResolutionStrategy strategy;
  final bool wasResolved;
  final Map<String, dynamic>? resolvedData;
  final String? errorMessage;
  final DateTime resolvedAt;
  final ConflictType originalConflictType;
  
  ConflictResolutionResult({
    required this.recordId,
    required this.strategy,
    required this.wasResolved,
    this.resolvedData,
    this.errorMessage,
    required this.resolvedAt,
    required this.originalConflictType,
  });
  
  bool get isSuccess => wasResolved && errorMessage == null;
  bool get hasError => errorMessage != null;
  
  Map<String, dynamic> toJson() {
    return {
      'recordId': recordId,
      'strategy': strategy.name,
      'wasResolved': wasResolved,
      'resolvedData': resolvedData,
      'errorMessage': errorMessage,
      'resolvedAt': resolvedAt.toIso8601String(),
      'originalConflictType': originalConflictType.name,
      'isSuccess': isSuccess,
    };
  }
}

/// Configuration for conflict resolution
class ConflictResolutionConfig {
  final ConflictResolutionStrategy defaultStrategy;
  final bool allowTimestampViolations;
  final bool enableSmartMerge;
  final Duration maxTimestampDifference;
  final List<String> criticalFields; // Fields that require manual resolution
  
  const ConflictResolutionConfig({
    this.defaultStrategy = ConflictResolutionStrategy.lastWriteWins,
    this.allowTimestampViolations = false,
    this.enableSmartMerge = false,
    this.maxTimestampDifference = const Duration(minutes: 5),
    this.criticalFields = const [],
  });
  
  /// Check if a field is critical and requires manual resolution
  bool isCriticalField(String fieldName) {
    return criticalFields.contains(fieldName);
  }
  
  /// Check if timestamp difference is within acceptable range
  bool isTimestampDifferenceAcceptable(DateTime? timestamp1, DateTime? timestamp2) {
    if (timestamp1 == null || timestamp2 == null) return true;
    
    final difference = timestamp1.difference(timestamp2).abs();
    return difference <= maxTimestampDifference;
  }
  
  Map<String, dynamic> toJson() {
    return {
      'defaultStrategy': defaultStrategy.name,
      'allowTimestampViolations': allowTimestampViolations,
      'enableSmartMerge': enableSmartMerge,
      'maxTimestampDifferenceMs': maxTimestampDifference.inMilliseconds,
      'criticalFields': criticalFields,
    };
  }
}

/// Statistics about conflict resolution operations
class ConflictResolutionStats {
  int totalConflicts = 0;
  int resolvedConflicts = 0;
  int manualResolutionRequired = 0;
  int timestampViolations = 0;
  Map<ConflictType, int> conflictTypeCount = {};
  Map<ConflictResolutionStrategy, int> strategyUsageCount = {};
  DateTime? lastConflictTime;
  
  void recordConflict(DataConflict conflict, ConflictResolutionResult? result) {
    totalConflicts++;
    lastConflictTime = DateTime.now();
    
    // Track conflict type
    conflictTypeCount[conflict.type] = (conflictTypeCount[conflict.type] ?? 0) + 1;
    
    // Track timestamp violations
    if (conflict.type == ConflictType.timestampViolation) {
      timestampViolations++;
    }
    
    // Track resolution result
    if (result != null) {
      strategyUsageCount[result.strategy] = (strategyUsageCount[result.strategy] ?? 0) + 1;
      
      if (result.wasResolved) {
        resolvedConflicts++;
      } else {
        manualResolutionRequired++;
      }
    }
  }
  
  double get resolutionRate => totalConflicts > 0 
      ? (resolvedConflicts / totalConflicts) * 100 
      : 0;
  
  double get timestampViolationRate => totalConflicts > 0 
      ? (timestampViolations / totalConflicts) * 100 
      : 0;
  
  Map<String, dynamic> toJson() {
    return {
      'totalConflicts': totalConflicts,
      'resolvedConflicts': resolvedConflicts,
      'manualResolutionRequired': manualResolutionRequired,
      'timestampViolations': timestampViolations,
      'resolutionRate': resolutionRate,
      'timestampViolationRate': timestampViolationRate,
      'conflictTypeCount': conflictTypeCount.map((k, v) => MapEntry(k.name, v)),
      'strategyUsageCount': strategyUsageCount.map((k, v) => MapEntry(k.name, v)),
      'lastConflictTime': lastConflictTime?.toIso8601String(),
    };
  }
}