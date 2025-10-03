/// Models for sync operations and metrics

class SyncResult {
  final int totalRecords;
  final int successCount;
  final int failureCount;
  final int skippedCount;
  final List<SyncError> errors;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final String syncType;
  
  SyncResult({
    required this.totalRecords,
    required this.successCount,
    required this.failureCount,
    required this.skippedCount,
    required this.errors,
    required this.startTime,
    required this.endTime,
    required this.syncType,
  }) : duration = endTime.difference(startTime);
  
  double get successRate => totalRecords > 0 
      ? (successCount / totalRecords) * 100 
      : 0;
  
  bool get isComplete => successCount + failureCount + skippedCount == totalRecords;
  
  bool get hasErrors => errors.isNotEmpty;
  
  Map<String, dynamic> toJson() {
    return {
      'totalRecords': totalRecords,
      'successCount': successCount,
      'failureCount': failureCount,
      'skippedCount': skippedCount,
      'errors': errors.map((e) => e.toJson()).toList(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'durationMs': duration.inMilliseconds,
      'syncType': syncType,
      'successRate': successRate,
    };
  }
}

class SyncError {
  final String recordId;
  final String errorMessage;
  final String? errorCode;
  final DateTime timestamp;
  final String recordType;
  
  SyncError({
    required this.recordId,
    required this.errorMessage,
    this.errorCode,
    required this.timestamp,
    required this.recordType,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'recordId': recordId,
      'errorMessage': errorMessage,
      'errorCode': errorCode,
      'timestamp': timestamp.toIso8601String(),
      'recordType': recordType,
    };
  }
}

class BatchSyncResult {
  final int batchNumber;
  final int batchSize;
  final int successCount;
  final int failureCount;
  final List<String> successfulIds;
  final Map<String, String> failedIds; // id -> error message
  final DateTime timestamp;
  
  BatchSyncResult({
    required this.batchNumber,
    required this.batchSize,
    required this.successCount,
    required this.failureCount,
    required this.successfulIds,
    required this.failedIds,
    required this.timestamp,
  });
  
  bool get isFullySuccessful => failureCount == 0;
  bool get isPartiallySuccessful => successCount > 0 && failureCount > 0;
  bool get isFullyFailed => successCount == 0;
  
  Map<String, dynamic> toJson() {
    return {
      'batchNumber': batchNumber,
      'batchSize': batchSize,
      'successCount': successCount,
      'failureCount': failureCount,
      'successfulIds': successfulIds,
      'failedIds': failedIds,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class SyncMetrics {
  int totalSyncs = 0;
  int successfulSyncs = 0;
  int failedSyncs = 0;
  int totalRecordsSynced = 0;
  int totalRecordsFailed = 0;
  Duration totalSyncTime = Duration.zero;
  DateTime? lastSyncTime;
  DateTime? lastSuccessfulSyncTime;
  List<SyncResult> recentResults = [];
  
  void recordSync(SyncResult result) {
    totalSyncs++;
    totalRecordsSynced += result.successCount;
    totalRecordsFailed += result.failureCount;
    totalSyncTime += result.duration;
    lastSyncTime = result.endTime;
    
    if (result.failureCount == 0 && result.successCount > 0) {
      successfulSyncs++;
      lastSuccessfulSyncTime = result.endTime;
    } else if (result.failureCount > 0) {
      failedSyncs++;
    }
    
    recentResults.add(result);
    // Keep only last 10 results
    if (recentResults.length > 10) {
      recentResults.removeAt(0);
    }
  }
  
  double get averageSyncTime => totalSyncs > 0 
      ? totalSyncTime.inMilliseconds / totalSyncs 
      : 0;
  
  double get overallSuccessRate => totalSyncs > 0 
      ? (successfulSyncs / totalSyncs) * 100 
      : 0;
      
  int get totalRecordsProcessed => totalRecordsSynced + totalRecordsFailed;
  
  int get totalSuccessfulRecords => totalRecordsSynced;
  
  Map<String, dynamic> toJson() {
    return {
      'totalSyncs': totalSyncs,
      'successfulSyncs': successfulSyncs,
      'failedSyncs': failedSyncs,
      'totalRecordsSynced': totalRecordsSynced,
      'totalRecordsFailed': totalRecordsFailed,
      'totalSyncTimeMs': totalSyncTime.inMilliseconds,
      'averageSyncTimeMs': averageSyncTime,
      'overallSuccessRate': overallSuccessRate,
      'lastSyncTime': lastSyncTime?.toIso8601String(),
      'lastSuccessfulSyncTime': lastSuccessfulSyncTime?.toIso8601String(),
      'recentResults': recentResults.map((r) => r.toJson()).toList(),
    };
  }
}