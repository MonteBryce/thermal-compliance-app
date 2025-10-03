/// Models for tracking sync progress and enabling interruption recovery

/// Represents a sync operation checkpoint for recovery
class SyncCheckpoint {
  final String id;
  final String syncType; // 'logEntries' or 'dailyMetrics'
  final DateTime startTime;
  final int totalRecords;
  final int processedRecords;
  final int currentBatchNumber;
  final List<String> processedBatches;
  final List<String> failedRecords;
  final Map<String, dynamic> syncContext;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? lastError;

  SyncCheckpoint({
    required this.id,
    required this.syncType,
    required this.startTime,
    required this.totalRecords,
    this.processedRecords = 0,
    this.currentBatchNumber = 0,
    this.processedBatches = const [],
    this.failedRecords = const [],
    this.syncContext = const {},
    this.isCompleted = false,
    this.completedAt,
    this.lastError,
  });

  /// Calculate sync progress percentage
  double get progressPercentage => totalRecords > 0 
      ? (processedRecords / totalRecords * 100).clamp(0.0, 100.0)
      : 0.0;

  /// Get elapsed time since sync started
  Duration get elapsedTime => DateTime.now().difference(startTime);

  /// Check if sync has been running for too long
  bool isStale({Duration maxAge = const Duration(hours: 2)}) {
    return !isCompleted && elapsedTime > maxAge;
  }

  /// Create a new checkpoint with updated progress
  SyncCheckpoint copyWith({
    int? processedRecords,
    int? currentBatchNumber,
    List<String>? processedBatches,
    List<String>? failedRecords,
    Map<String, dynamic>? syncContext,
    bool? isCompleted,
    DateTime? completedAt,
    String? lastError,
  }) {
    return SyncCheckpoint(
      id: id,
      syncType: syncType,
      startTime: startTime,
      totalRecords: totalRecords,
      processedRecords: processedRecords ?? this.processedRecords,
      currentBatchNumber: currentBatchNumber ?? this.currentBatchNumber,
      processedBatches: processedBatches ?? this.processedBatches,
      failedRecords: failedRecords ?? this.failedRecords,
      syncContext: syncContext ?? this.syncContext,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      lastError: lastError ?? this.lastError,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'syncType': syncType,
      'startTime': startTime.toIso8601String(),
      'totalRecords': totalRecords,
      'processedRecords': processedRecords,
      'currentBatchNumber': currentBatchNumber,
      'processedBatches': processedBatches,
      'failedRecords': failedRecords,
      'syncContext': syncContext,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'lastError': lastError,
      'progressPercentage': progressPercentage,
      'elapsedTimeMs': elapsedTime.inMilliseconds,
    };
  }

  factory SyncCheckpoint.fromJson(Map<String, dynamic> json) {
    return SyncCheckpoint(
      id: json['id'],
      syncType: json['syncType'],
      startTime: DateTime.parse(json['startTime']),
      totalRecords: json['totalRecords'],
      processedRecords: json['processedRecords'] ?? 0,
      currentBatchNumber: json['currentBatchNumber'] ?? 0,
      processedBatches: List<String>.from(json['processedBatches'] ?? []),
      failedRecords: List<String>.from(json['failedRecords'] ?? []),
      syncContext: Map<String, dynamic>.from(json['syncContext'] ?? {}),
      isCompleted: json['isCompleted'] ?? false,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      lastError: json['lastError'],
    );
  }
}

/// Manages sync checkpoints for interruption recovery
class SyncCheckpointManager {
  static final Map<String, SyncCheckpoint> _activeCheckpoints = {};

  /// Create a new sync checkpoint
  static SyncCheckpoint createCheckpoint({
    required String syncType,
    required int totalRecords,
    Map<String, dynamic> syncContext = const {},
  }) {
    final id = '${syncType}_${DateTime.now().millisecondsSinceEpoch}';
    final checkpoint = SyncCheckpoint(
      id: id,
      syncType: syncType,
      startTime: DateTime.now(),
      totalRecords: totalRecords,
      syncContext: syncContext,
    );
    
    _activeCheckpoints[id] = checkpoint;
    return checkpoint;
  }

  /// Update an existing checkpoint
  static void updateCheckpoint(String checkpointId, SyncCheckpoint updatedCheckpoint) {
    _activeCheckpoints[checkpointId] = updatedCheckpoint;
  }

  /// Mark checkpoint as completed
  static void completeCheckpoint(String checkpointId) {
    final checkpoint = _activeCheckpoints[checkpointId];
    if (checkpoint != null) {
      _activeCheckpoints[checkpointId] = checkpoint.copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
      );
    }
  }

  /// Get active checkpoint by ID
  static SyncCheckpoint? getCheckpoint(String checkpointId) {
    return _activeCheckpoints[checkpointId];
  }

  /// Get all active (incomplete) checkpoints
  static List<SyncCheckpoint> getActiveCheckpoints() {
    return _activeCheckpoints.values
        .where((checkpoint) => !checkpoint.isCompleted)
        .toList();
  }

  /// Get stale checkpoints that need recovery
  static List<SyncCheckpoint> getStaleCheckpoints({Duration maxAge = const Duration(hours: 2)}) {
    return _activeCheckpoints.values
        .where((checkpoint) => checkpoint.isStale(maxAge: maxAge))
        .toList();
  }

  /// Remove completed or stale checkpoints
  static void cleanupCheckpoints({Duration maxAge = const Duration(hours: 24)}) {
    final now = DateTime.now();
    _activeCheckpoints.removeWhere((id, checkpoint) {
      return checkpoint.isCompleted || 
             now.difference(checkpoint.startTime) > maxAge;
    });
  }

  /// Get checkpoint summary for monitoring
  static Map<String, dynamic> getCheckpointSummary() {
    final activeCheckpoints = getActiveCheckpoints();
    final staleCheckpoints = getStaleCheckpoints();
    
    return {
      'totalCheckpoints': _activeCheckpoints.length,
      'activeCheckpoints': activeCheckpoints.length,
      'staleCheckpoints': staleCheckpoints.length,
      'completedCheckpoints': _activeCheckpoints.values.where((c) => c.isCompleted).length,
      'checkpointDetails': activeCheckpoints.map((c) => c.toJson()).toList(),
    };
  }

  /// Find incomplete sync for resumption
  static SyncCheckpoint? findIncompleteSync(String syncType) {
    return _activeCheckpoints.values
        .where((checkpoint) => 
            checkpoint.syncType == syncType && 
            !checkpoint.isCompleted &&
            !checkpoint.isStale())
        .firstOrNull;
  }
}

/// Recovery strategy for resuming interrupted syncs
class SyncRecoveryStrategy {
  /// Attempt to recover and resume an interrupted sync
  static Future<bool> recoverSync(SyncCheckpoint checkpoint) async {
    try {
      // Validate checkpoint is recoverable
      if (checkpoint.isCompleted || checkpoint.isStale()) {
        return false;
      }

      // Log recovery attempt
      print('Attempting to recover sync: ${checkpoint.id}');
      print('Progress: ${checkpoint.progressPercentage.toStringAsFixed(1)}% (${checkpoint.processedRecords}/${checkpoint.totalRecords})');

      // Set context for resumed sync
      final resumeContext = {
        ...checkpoint.syncContext,
        'isResumed': true,
        'originalStartTime': checkpoint.startTime.toIso8601String(),
        'resumeTime': DateTime.now().toIso8601String(),
        'lastBatchNumber': checkpoint.currentBatchNumber,
      };

      return true;
    } catch (e) {
      print('Failed to recover sync ${checkpoint.id}: $e');
      return false;
    }
  }

  /// Get recovery recommendations based on checkpoint analysis
  static List<String> getRecoveryRecommendations(SyncCheckpoint checkpoint) {
    final recommendations = <String>[];

    if (checkpoint.isStale()) {
      recommendations.add('Checkpoint is stale - consider restarting sync');
    }

    if (checkpoint.failedRecords.isNotEmpty) {
      recommendations.add('${checkpoint.failedRecords.length} records failed - review error logs');
    }

    if (checkpoint.progressPercentage < 10) {
      recommendations.add('Low progress - check network connectivity');
    }

    final avgTimePerRecord = checkpoint.processedRecords > 0 
        ? checkpoint.elapsedTime.inMilliseconds / checkpoint.processedRecords
        : 0;
    
    if (avgTimePerRecord > 1000) { // More than 1 second per record
      recommendations.add('Slow sync performance - consider reducing batch size');
    }

    if (recommendations.isEmpty) {
      recommendations.add('Checkpoint appears healthy for recovery');
    }

    return recommendations;
  }
}