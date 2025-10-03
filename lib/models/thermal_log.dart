import 'package:hive/hive.dart';

part 'thermal_log.g.dart';

@HiveType(typeId: 5)
class ThermalLog extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime timestamp;

  @HiveField(2)
  double temperature;

  @HiveField(3)
  String notes;

  @HiveField(4)
  String projectId;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime updatedAt;

  ThermalLog({
    required this.id,
    required this.timestamp,
    required this.temperature,
    required this.notes,
    required this.projectId,
    required this.createdAt,
    required this.updatedAt,
  });

  // Firestore serialization
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'temperature': temperature,
      'notes': notes,
      'projectId': projectId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Firestore deserialization
  factory ThermalLog.fromFirestore(Map<String, dynamic> data) {
    return ThermalLog(
      id: data['id'] ?? '',
      timestamp: DateTime.parse(data['timestamp'] ?? DateTime.now().toIso8601String()),
      temperature: (data['temperature'] ?? 0.0).toDouble(),
      notes: data['notes'] ?? '',
      projectId: data['projectId'] ?? '',
      createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(data['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // JSON serialization for general use
  Map<String, dynamic> toJson() => toFirestore();

  factory ThermalLog.fromJson(Map<String, dynamic> json) => ThermalLog.fromFirestore(json);

  // Helper method to create a copy with updated fields
  ThermalLog copyWith({
    String? id,
    DateTime? timestamp,
    double? temperature,
    String? notes,
    String? projectId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ThermalLog(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      temperature: temperature ?? this.temperature,
      notes: notes ?? this.notes,
      projectId: projectId ?? this.projectId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ThermalLog(id: $id, timestamp: $timestamp, temperature: $temperature, notes: $notes, projectId: $projectId)';
  }
}