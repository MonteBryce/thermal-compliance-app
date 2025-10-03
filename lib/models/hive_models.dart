import 'package:hive/hive.dart';

part 'hive_models.g.dart';

/// Log Entry model for Hive storage
@HiveType(typeId: 0)
class LogEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String projectId;

  @HiveField(2)
  String projectName;

  @HiveField(3)
  String date;

  @HiveField(4)
  String hour;

  @HiveField(5)
  Map<String, dynamic> data;

  @HiveField(6)
  String status;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  DateTime updatedAt;

  @HiveField(9)
  String createdBy;

  @HiveField(10)
  bool isSynced;

  @HiveField(11)
  String? syncError;

  @HiveField(12)
  DateTime? syncTimestamp;

  LogEntry({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.date,
    required this.hour,
    required this.data,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.isSynced = false,
    this.syncError,
    this.syncTimestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'projectName': projectName,
      'date': date,
      'hour': hour,
      'data': data,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
      'isSynced': isSynced,
      'syncError': syncError,
      'syncTimestamp': syncTimestamp?.toIso8601String(),
    };
  }

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      id: json['id'],
      projectId: json['projectId'],
      projectName: json['projectName'],
      date: json['date'],
      hour: json['hour'],
      data: Map<String, dynamic>.from(json['data']),
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      createdBy: json['createdBy'],
      isSynced: json['isSynced'] ?? false,
      syncError: json['syncError'],
      syncTimestamp: json['syncTimestamp'] != null 
          ? DateTime.parse(json['syncTimestamp']) 
          : null,
    );
  }
}

/// Daily Metric model for Hive storage
@HiveType(typeId: 1)
class DailyMetric extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String projectId;

  @HiveField(2)
  String date;

  @HiveField(3)
  int totalEntries;

  @HiveField(4)
  int completedEntries;

  @HiveField(5)
  String completionStatus;

  @HiveField(6)
  Map<String, dynamic> summary;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  DateTime updatedAt;

  @HiveField(9)
  String createdBy;

  @HiveField(10)
  bool isSynced;

  @HiveField(11)
  bool isLocked;

  @HiveField(12)
  DateTime? syncTimestamp;

  DailyMetric({
    required this.id,
    required this.projectId,
    required this.date,
    required this.totalEntries,
    required this.completedEntries,
    required this.completionStatus,
    required this.summary,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.isSynced = false,
    this.isLocked = false,
    this.syncTimestamp,
  });

  double get completionPercentage {
    if (totalEntries == 0) return 0;
    return (completedEntries / totalEntries) * 100;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'date': date,
      'totalEntries': totalEntries,
      'completedEntries': completedEntries,
      'completionStatus': completionStatus,
      'summary': summary,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
      'isSynced': isSynced,
      'isLocked': isLocked,
      'syncTimestamp': syncTimestamp?.toIso8601String(),
    };
  }

  factory DailyMetric.fromJson(Map<String, dynamic> json) {
    return DailyMetric(
      id: json['id'],
      projectId: json['projectId'],
      date: json['date'],
      totalEntries: json['totalEntries'],
      completedEntries: json['completedEntries'],
      completionStatus: json['completionStatus'],
      summary: Map<String, dynamic>.from(json['summary']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      createdBy: json['createdBy'],
      isSynced: json['isSynced'] ?? false,
      isLocked: json['isLocked'] ?? false,
      syncTimestamp: json['syncTimestamp'] != null 
          ? DateTime.parse(json['syncTimestamp']) 
          : null,
    );
  }
}

/// User Session model for Hive storage
@HiveType(typeId: 2)
class UserSession extends HiveObject {
  @HiveField(0)
  String userId;

  @HiveField(1)
  String email;

  @HiveField(2)
  String displayName;

  @HiveField(3)
  DateTime loginTime;

  @HiveField(4)
  DateTime? lastActivityTime;

  @HiveField(5)
  String? currentProjectId;

  @HiveField(6)
  String? currentProjectName;

  @HiveField(7)
  Map<String, dynamic> preferences;

  @HiveField(8)
  List<String> recentProjects;

  @HiveField(9)
  bool isActive;

  UserSession({
    required this.userId,
    required this.email,
    required this.displayName,
    required this.loginTime,
    this.lastActivityTime,
    this.currentProjectId,
    this.currentProjectName,
    this.preferences = const {},
    this.recentProjects = const [],
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'displayName': displayName,
      'loginTime': loginTime.toIso8601String(),
      'lastActivityTime': lastActivityTime?.toIso8601String(),
      'currentProjectId': currentProjectId,
      'currentProjectName': currentProjectName,
      'preferences': preferences,
      'recentProjects': recentProjects,
      'isActive': isActive,
    };
  }

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      userId: json['userId'],
      email: json['email'],
      displayName: json['displayName'],
      loginTime: DateTime.parse(json['loginTime']),
      lastActivityTime: json['lastActivityTime'] != null
          ? DateTime.parse(json['lastActivityTime'])
          : null,
      currentProjectId: json['currentProjectId'],
      currentProjectName: json['currentProjectName'],
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
      recentProjects: List<String>.from(json['recentProjects'] ?? []),
      isActive: json['isActive'] ?? true,
    );
  }

  void updateActivity() {
    lastActivityTime = DateTime.now();
  }
}

/// Project model for offline caching
@HiveType(typeId: 3)
class CachedProject extends HiveObject {
  @HiveField(0)
  String projectId;

  @HiveField(1)
  String projectName;

  @HiveField(2)
  String projectNumber;

  @HiveField(3)
  String location;

  @HiveField(4)
  String unitNumber;

  @HiveField(5)
  Map<String, dynamic> metadata;

  @HiveField(6)
  DateTime cachedAt;

  @HiveField(7)
  String createdBy;

  CachedProject({
    required this.projectId,
    required this.projectName,
    required this.projectNumber,
    required this.location,
    required this.unitNumber,
    required this.metadata,
    required this.cachedAt,
    required this.createdBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'projectName': projectName,
      'projectNumber': projectNumber,
      'location': location,
      'unitNumber': unitNumber,
      'metadata': metadata,
      'cachedAt': cachedAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  factory CachedProject.fromJson(Map<String, dynamic> json) {
    return CachedProject(
      projectId: json['projectId'],
      projectName: json['projectName'],
      projectNumber: json['projectNumber'],
      location: json['location'],
      unitNumber: json['unitNumber'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      cachedAt: DateTime.parse(json['cachedAt']),
      createdBy: json['createdBy'],
    );
  }
}

/// Sync Queue Entry for tracking pending sync operations
@HiveType(typeId: 4)
class SyncQueueEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String operation; // 'create', 'update', 'delete'

  @HiveField(2)
  String collection;

  @HiveField(3)
  String documentId;

  @HiveField(4)
  Map<String, dynamic> data;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  int retryCount;

  @HiveField(7)
  String? lastError;

  @HiveField(8)
  DateTime? lastAttempt;

  SyncQueueEntry({
    required this.id,
    required this.operation,
    required this.collection,
    required this.documentId,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
    this.lastError,
    this.lastAttempt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'operation': operation,
      'collection': collection,
      'documentId': documentId,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
      'lastError': lastError,
      'lastAttempt': lastAttempt?.toIso8601String(),
    };
  }

  factory SyncQueueEntry.fromJson(Map<String, dynamic> json) {
    return SyncQueueEntry(
      id: json['id'],
      operation: json['operation'],
      collection: json['collection'],
      documentId: json['documentId'],
      data: Map<String, dynamic>.from(json['data']),
      createdAt: DateTime.parse(json['createdAt']),
      retryCount: json['retryCount'] ?? 0,
      lastError: json['lastError'],
      lastAttempt: json['lastAttempt'] != null
          ? DateTime.parse(json['lastAttempt'])
          : null,
    );
  }
}