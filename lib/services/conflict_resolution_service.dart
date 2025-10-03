import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hive_models.dart';
import '../models/conflict_resolution_models.dart';
import 'local_database_service.dart';

/// Service for detecting and resolving conflicts during data synchronization
class ConflictResolutionService {
  static final ConflictResolutionService _instance = ConflictResolutionService._internal();
  factory ConflictResolutionService() => _instance;
  ConflictResolutionService._internal();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConflictResolutionStats _stats = ConflictResolutionStats();
  
  ConflictResolutionConfig _config = const ConflictResolutionConfig();
  
  /// Get current configuration
  ConflictResolutionConfig get config => _config;
  
  /// Get conflict resolution statistics
  ConflictResolutionStats get stats => _stats;
  
  /// Update conflict resolution configuration
  void updateConfig(ConflictResolutionConfig newConfig) {
    _config = newConfig;
    debugPrint('Conflict resolution config updated: ${newConfig.defaultStrategy.name}');
  }
  
  /// Detect conflicts for a log entry before sync
  Future<DataConflict?> detectLogEntryConflict(LogEntry localEntry) async {
    try {
      // Fetch remote document
      final remoteDoc = await _firestore
          .collection('projects')
          .doc(localEntry.projectId)
          .collection('logEntries')
          .doc(localEntry.id)
          .get();
      
      return _analyzeLogEntryConflict(localEntry, remoteDoc);
    } catch (e) {
      debugPrint('Error detecting log entry conflict for ${localEntry.id}: $e');
      return null;
    }
  }
  
  /// Detect conflicts for a daily metric before sync
  Future<DataConflict?> detectDailyMetricConflict(DailyMetric localMetric) async {
    try {
      // Fetch remote document
      final remoteDoc = await _firestore
          .collection('projects')
          .doc(localMetric.projectId)
          .collection('dailyMetrics')
          .doc(localMetric.id)
          .get();
      
      return _analyzeDailyMetricConflict(localMetric, remoteDoc);
    } catch (e) {
      debugPrint('Error detecting daily metric conflict for ${localMetric.id}: $e');
      return null;
    }
  }
  
  /// Analyze conflict between local log entry and remote document
  DataConflict? _analyzeLogEntryConflict(LogEntry localEntry, DocumentSnapshot remoteDoc) {
    final now = DateTime.now();
    
    // Case 1: Remote document doesn't exist
    if (!remoteDoc.exists) {
      return DataConflict(
        recordId: localEntry.id,
        type: ConflictType.localExists,
        localData: localEntry.toJson(),
        remoteData: null,
        localTimestamp: localEntry.syncTimestamp ?? localEntry.updatedAt,
        remoteTimestamp: null,
        detectedAt: now,
        recordType: 'LogEntry',
      );
    }
    
    final remoteData = remoteDoc.data() as Map<String, dynamic>;
    final remoteTimestamp = _extractTimestamp(remoteData);
    final localTimestamp = localEntry.syncTimestamp ?? localEntry.updatedAt;
    
    // Case 2: Check for timestamp violations (backdating)
    if (localTimestamp != null && remoteTimestamp != null) {
      if (!LocalDatabaseService.validateSyncTimestamp(localTimestamp, DateTime.parse(remoteData['createdAt']))) {
        return DataConflict(
          recordId: localEntry.id,
          type: ConflictType.timestampViolation,
          localData: localEntry.toJson(),
          remoteData: remoteData,
          localTimestamp: localTimestamp,
          remoteTimestamp: remoteTimestamp,
          detectedAt: now,
          recordType: 'LogEntry',
        );
      }
    }
    
    // Case 3: Compare data for modifications
    final localDataNormalized = _normalizeDataForComparison(localEntry.toJson());
    final remoteDataNormalized = _normalizeDataForComparison(remoteData);
    final conflictingFields = _findConflictingFields(localDataNormalized, remoteDataNormalized);
    
    // Case 4: No conflicts detected
    if (conflictingFields.isEmpty) {
      return DataConflict(
        recordId: localEntry.id,
        type: ConflictType.none,
        localData: localEntry.toJson(),
        remoteData: remoteData,
        localTimestamp: localTimestamp,
        remoteTimestamp: remoteTimestamp,
        detectedAt: now,
        recordType: 'LogEntry',
      );
    }
    
    // Case 5: Both modified - requires resolution
    return DataConflict(
      recordId: localEntry.id,
      type: ConflictType.bothModified,
      localData: localEntry.toJson(),
      remoteData: remoteData,
      localTimestamp: localTimestamp,
      remoteTimestamp: remoteTimestamp,
      detectedAt: now,
      recordType: 'LogEntry',
      conflictingFields: conflictingFields,
    );
  }
  
  /// Analyze conflict between local daily metric and remote document
  DataConflict? _analyzeDailyMetricConflict(DailyMetric localMetric, DocumentSnapshot remoteDoc) {
    final now = DateTime.now();
    
    if (!remoteDoc.exists) {
      return DataConflict(
        recordId: localMetric.id,
        type: ConflictType.localExists,
        localData: localMetric.toJson(),
        remoteData: null,
        localTimestamp: localMetric.syncTimestamp ?? localMetric.updatedAt,
        remoteTimestamp: null,
        detectedAt: now,
        recordType: 'DailyMetric',
      );
    }
    
    final remoteData = remoteDoc.data() as Map<String, dynamic>;
    final remoteTimestamp = _extractTimestamp(remoteData);
    final localTimestamp = localMetric.syncTimestamp ?? localMetric.updatedAt;
    
    // Similar analysis as log entry but for daily metric structure
    final localDataNormalized = _normalizeDataForComparison(localMetric.toJson());
    final remoteDataNormalized = _normalizeDataForComparison(remoteData);
    final conflictingFields = _findConflictingFields(localDataNormalized, remoteDataNormalized);
    
    if (conflictingFields.isEmpty) {
      return DataConflict(
        recordId: localMetric.id,
        type: ConflictType.none,
        localData: localMetric.toJson(),
        remoteData: remoteData,
        localTimestamp: localTimestamp,
        remoteTimestamp: remoteTimestamp,
        detectedAt: now,
        recordType: 'DailyMetric',
      );
    }
    
    return DataConflict(
      recordId: localMetric.id,
      type: ConflictType.bothModified,
      localData: localMetric.toJson(),
      remoteData: remoteData,
      localTimestamp: localTimestamp,
      remoteTimestamp: remoteTimestamp,
      detectedAt: now,
      recordType: 'DailyMetric',
      conflictingFields: conflictingFields,
    );
  }
  
  /// Resolve a detected conflict using configured strategy
  Future<ConflictResolutionResult> resolveConflict(DataConflict conflict) async {
    final strategy = _selectResolutionStrategy(conflict);
    
    try {
      final resolvedData = await _applyResolutionStrategy(conflict, strategy);
      
      final result = ConflictResolutionResult(
        recordId: conflict.recordId,
        strategy: strategy,
        wasResolved: resolvedData != null,
        resolvedData: resolvedData,
        errorMessage: resolvedData == null ? 'Could not resolve conflict automatically' : null,
        resolvedAt: DateTime.now(),
        originalConflictType: conflict.type,
      );
      
      _stats.recordConflict(conflict, result);
      debugPrint('Conflict resolved for ${conflict.recordId} using ${strategy.name}');
      
      return result;
    } catch (e) {
      final result = ConflictResolutionResult(
        recordId: conflict.recordId,
        strategy: strategy,
        wasResolved: false,
        resolvedData: null,
        errorMessage: e.toString(),
        resolvedAt: DateTime.now(),
        originalConflictType: conflict.type,
      );
      
      _stats.recordConflict(conflict, result);
      debugPrint('Failed to resolve conflict for ${conflict.recordId}: $e');
      
      return result;
    }
  }
  
  /// Select appropriate resolution strategy for a conflict
  ConflictResolutionStrategy _selectResolutionStrategy(DataConflict conflict) {
    // Handle special cases first
    switch (conflict.type) {
      case ConflictType.none:
      case ConflictType.localOnly:
      case ConflictType.localExists:
        return ConflictResolutionStrategy.localWins;
      
      case ConflictType.remoteOnly:
      case ConflictType.remoteExists:
        return ConflictResolutionStrategy.remoteWins;
      
      case ConflictType.timestampViolation:
        return ConflictResolutionStrategy.manual; // Always require manual resolution
      
      case ConflictType.structuralMismatch:
        return ConflictResolutionStrategy.manual;
      
      case ConflictType.bothModified:
        // Check if any conflicting fields are critical
        if (conflict.conflictingFields.any((field) => _config.isCriticalField(field))) {
          return ConflictResolutionStrategy.manual;
        }
        
        // Use configured default strategy
        return _config.defaultStrategy;
    }
  }
  
  /// Apply the selected resolution strategy
  Future<Map<String, dynamic>?> _applyResolutionStrategy(
    DataConflict conflict,
    ConflictResolutionStrategy strategy,
  ) async {
    switch (strategy) {
      case ConflictResolutionStrategy.localWins:
        return conflict.localData;
      
      case ConflictResolutionStrategy.remoteWins:
        return conflict.remoteData;
      
      case ConflictResolutionStrategy.lastWriteWins:
        if (conflict.isLocalNewer) {
          return conflict.localData;
        } else if (conflict.isRemoteNewer) {
          return conflict.remoteData;
        } else if (conflict.hasEqualTimestamps) {
          // Tie-breaker: prefer local changes
          return conflict.localData;
        }
        return null;
      
      case ConflictResolutionStrategy.smartMerge:
        return _performSmartMerge(conflict);
      
      case ConflictResolutionStrategy.manual:
        return null; // Manual resolution required
    }
  }
  
  /// Perform smart merge of conflicting data
  Map<String, dynamic>? _performSmartMerge(DataConflict conflict) {
    if (!_config.enableSmartMerge || conflict.localData == null || conflict.remoteData == null) {
      return null;
    }
    
    final mergedData = Map<String, dynamic>.from(conflict.remoteData!);
    
    // Apply non-conflicting local changes
    for (final entry in conflict.localData!.entries) {
      if (!conflict.conflictingFields.contains(entry.key)) {
        mergedData[entry.key] = entry.value;
      }
    }
    
    // For conflicting fields, use timestamp-based resolution
    for (final field in conflict.conflictingFields) {
      if (conflict.isLocalNewer) {
        mergedData[field] = conflict.localData![field];
      }
      // Otherwise keep remote value
    }
    
    return mergedData;
  }
  
  /// Extract timestamp from document data
  DateTime? _extractTimestamp(Map<String, dynamic> data) {
    // Try different timestamp fields
    final timestampFields = ['clientSyncTimestamp', 'syncTimestamp', 'updatedAt', 'serverTimestamp'];
    
    for (final field in timestampFields) {
      if (data.containsKey(field) && data[field] != null) {
        if (data[field] is String) {
          try {
            return DateTime.parse(data[field]);
          } catch (e) {
            continue;
          }
        } else if (data[field] is Timestamp) {
          return (data[field] as Timestamp).toDate();
        }
      }
    }
    
    return null;
  }
  
  /// Normalize data for comparison by removing sync-specific fields
  Map<String, dynamic> _normalizeDataForComparison(Map<String, dynamic> data) {
    final normalized = Map<String, dynamic>.from(data);
    
    // Remove fields that shouldn't be compared
    normalized.remove('serverTimestamp');
    normalized.remove('clientSyncTimestamp');
    normalized.remove('syncTimestamp');
    normalized.remove('isSynced');
    normalized.remove('syncError');
    normalized.remove('batchNumber');
    normalized.remove('syncVersion');
    
    return normalized;
  }
  
  /// Find fields that have different values between local and remote data
  List<String> _findConflictingFields(Map<String, dynamic> local, Map<String, dynamic> remote) {
    final conflictingFields = <String>[];
    final allKeys = {...local.keys, ...remote.keys};
    
    for (final key in allKeys) {
      final localValue = local[key];
      final remoteValue = remote[key];
      
      // Skip if values are equal
      if (localValue == remoteValue) continue;
      
      // Handle null comparisons
      if (localValue == null || remoteValue == null) {
        conflictingFields.add(key);
        continue;
      }
      
      // Handle different types or values
      if (localValue.runtimeType != remoteValue.runtimeType ||
          localValue.toString() != remoteValue.toString()) {
        conflictingFields.add(key);
      }
    }
    
    return conflictingFields;
  }
  
  /// Get detailed conflict report
  Map<String, dynamic> getConflictReport() {
    return {
      'stats': _stats.toJson(),
      'config': _config.toJson(),
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }
}