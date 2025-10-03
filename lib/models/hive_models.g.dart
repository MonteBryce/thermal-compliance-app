// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LogEntryAdapter extends TypeAdapter<LogEntry> {
  @override
  final int typeId = 0;

  @override
  LogEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LogEntry(
      id: fields[0] as String,
      projectId: fields[1] as String,
      projectName: fields[2] as String,
      date: fields[3] as String,
      hour: fields[4] as String,
      data: (fields[5] as Map).cast<String, dynamic>(),
      status: fields[6] as String,
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
      createdBy: fields[9] as String,
      isSynced: fields[10] as bool,
      syncError: fields[11] as String?,
      syncTimestamp: fields[12] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, LogEntry obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projectId)
      ..writeByte(2)
      ..write(obj.projectName)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.hour)
      ..writeByte(5)
      ..write(obj.data)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.createdBy)
      ..writeByte(10)
      ..write(obj.isSynced)
      ..writeByte(11)
      ..write(obj.syncError)
      ..writeByte(12)
      ..write(obj.syncTimestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DailyMetricAdapter extends TypeAdapter<DailyMetric> {
  @override
  final int typeId = 1;

  @override
  DailyMetric read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyMetric(
      id: fields[0] as String,
      projectId: fields[1] as String,
      date: fields[2] as String,
      totalEntries: fields[3] as int,
      completedEntries: fields[4] as int,
      completionStatus: fields[5] as String,
      summary: (fields[6] as Map).cast<String, dynamic>(),
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
      createdBy: fields[9] as String,
      isSynced: fields[10] as bool,
      isLocked: fields[11] as bool,
      syncTimestamp: fields[12] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, DailyMetric obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projectId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.totalEntries)
      ..writeByte(4)
      ..write(obj.completedEntries)
      ..writeByte(5)
      ..write(obj.completionStatus)
      ..writeByte(6)
      ..write(obj.summary)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.createdBy)
      ..writeByte(10)
      ..write(obj.isSynced)
      ..writeByte(11)
      ..write(obj.isLocked)
      ..writeByte(12)
      ..write(obj.syncTimestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyMetricAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserSessionAdapter extends TypeAdapter<UserSession> {
  @override
  final int typeId = 2;

  @override
  UserSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSession(
      userId: fields[0] as String,
      email: fields[1] as String,
      displayName: fields[2] as String,
      loginTime: fields[3] as DateTime,
      lastActivityTime: fields[4] as DateTime?,
      currentProjectId: fields[5] as String?,
      currentProjectName: fields[6] as String?,
      preferences: (fields[7] as Map).cast<String, dynamic>(),
      recentProjects: (fields[8] as List).cast<String>(),
      isActive: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UserSession obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.displayName)
      ..writeByte(3)
      ..write(obj.loginTime)
      ..writeByte(4)
      ..write(obj.lastActivityTime)
      ..writeByte(5)
      ..write(obj.currentProjectId)
      ..writeByte(6)
      ..write(obj.currentProjectName)
      ..writeByte(7)
      ..write(obj.preferences)
      ..writeByte(8)
      ..write(obj.recentProjects)
      ..writeByte(9)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CachedProjectAdapter extends TypeAdapter<CachedProject> {
  @override
  final int typeId = 3;

  @override
  CachedProject read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedProject(
      projectId: fields[0] as String,
      projectName: fields[1] as String,
      projectNumber: fields[2] as String,
      location: fields[3] as String,
      unitNumber: fields[4] as String,
      metadata: (fields[5] as Map).cast<String, dynamic>(),
      cachedAt: fields[6] as DateTime,
      createdBy: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CachedProject obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.projectId)
      ..writeByte(1)
      ..write(obj.projectName)
      ..writeByte(2)
      ..write(obj.projectNumber)
      ..writeByte(3)
      ..write(obj.location)
      ..writeByte(4)
      ..write(obj.unitNumber)
      ..writeByte(5)
      ..write(obj.metadata)
      ..writeByte(6)
      ..write(obj.cachedAt)
      ..writeByte(7)
      ..write(obj.createdBy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedProjectAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SyncQueueEntryAdapter extends TypeAdapter<SyncQueueEntry> {
  @override
  final int typeId = 4;

  @override
  SyncQueueEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncQueueEntry(
      id: fields[0] as String,
      operation: fields[1] as String,
      collection: fields[2] as String,
      documentId: fields[3] as String,
      data: (fields[4] as Map).cast<String, dynamic>(),
      createdAt: fields[5] as DateTime,
      retryCount: fields[6] as int,
      lastError: fields[7] as String?,
      lastAttempt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SyncQueueEntry obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.operation)
      ..writeByte(2)
      ..write(obj.collection)
      ..writeByte(3)
      ..write(obj.documentId)
      ..writeByte(4)
      ..write(obj.data)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.retryCount)
      ..writeByte(7)
      ..write(obj.lastError)
      ..writeByte(8)
      ..write(obj.lastAttempt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncQueueEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
