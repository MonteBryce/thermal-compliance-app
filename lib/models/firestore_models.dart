import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../utils/timestamp_utils.dart';

/// Comprehensive Firestore data models for the thermal logging application
/// Structure: projects/{projectId}/logs/{yyyy-MM-dd}/entries/{hour}

// Enums for better type safety
enum LogCompletionStatus {
  notStarted,
  incomplete,
  complete,
  validated;

  String get displayName {
    switch (this) {
      case LogCompletionStatus.notStarted:
        return 'Not Started';
      case LogCompletionStatus.incomplete:
        return 'Incomplete';
      case LogCompletionStatus.complete:
        return 'Complete';
      case LogCompletionStatus.validated:
        return 'Validated';
    }
  }

  static LogCompletionStatus fromString(String value) {
    return LogCompletionStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => LogCompletionStatus.notStarted,
    );
  }
}

enum LogEntryType {
  thermal,
  system,
  maintenance;

  static LogEntryType fromString(String value) {
    return LogEntryType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => LogEntryType.thermal,
    );
  }
}

/// Project document model - stored at /projects/{projectId}
class ProjectDocument {
  final String projectId;
  final String projectName;
  final String projectNumber;
  final String location;
  final String unitNumber;
  final String workOrderNumber;
  final String tankType;
  final String facilityTarget;
  final String operatingTemperature;
  final String benzeneTarget;
  final bool h2sAmpRequired;
  final String product;
  final DateTime? projectStartDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final Map<String, dynamic> metadata;

  ProjectDocument({
    required this.projectId,
    required this.projectName,
    required this.projectNumber,
    required this.location,
    required this.unitNumber,
    this.workOrderNumber = '',
    this.tankType = '',
    this.facilityTarget = '',
    this.operatingTemperature = '',
    this.benzeneTarget = '',
    this.h2sAmpRequired = false,
    this.product = '',
    this.projectStartDate,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.metadata = const {},
  });

  factory ProjectDocument.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProjectDocument(
      projectId: doc.id,
      projectName: data['projectName'] ?? '',
      projectNumber: data['projectNumber'] ?? '',
      location: data['location'] ?? '',
      unitNumber: data['unitNumber'] ?? '',
      workOrderNumber: data['workOrderNumber'] ?? '',
      tankType: data['tankType'] ?? '',
      facilityTarget: data['facilityTarget'] ?? '',
      operatingTemperature: data['operatingTemperature'] ?? '',
      benzeneTarget: data['benzeneTarget'] ?? '',
      h2sAmpRequired: data['h2sAmpRequired'] ?? false,
      product: data['product'] ?? '',
      projectStartDate: (data['projectStartDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      metadata: data['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'projectName': projectName,
      'projectNumber': projectNumber,
      'location': location,
      'unitNumber': unitNumber,
      'workOrderNumber': workOrderNumber,
      'tankType': tankType,
      'facilityTarget': facilityTarget,
      'operatingTemperature': operatingTemperature,
      'benzeneTarget': benzeneTarget,
      'h2sAmpRequired': h2sAmpRequired,
      'product': product,
      'projectStartDate': projectStartDate != null
          ? Timestamp.fromDate(projectStartDate!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'metadata': metadata,
    };
  }
}

/// Log document model - stored at /projects/{projectId}/logs/{yyyy-MM-dd}
class LogDocument {
  final String logId; // Format: yyyy-MM-dd
  final DateTime date;
  final String projectId;
  final LogCompletionStatus completionStatus;
  final int totalEntries;
  final int completedHours;
  final int validatedHours;
  final DateTime? firstEntryAt;
  final DateTime? lastEntryAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final Map<String, dynamic> dailyMetrics;
  final List<String> operatorIds;
  final String notes;

  LogDocument({
    required this.logId,
    required this.date,
    required this.projectId,
    this.completionStatus = LogCompletionStatus.notStarted,
    this.totalEntries = 0,
    this.completedHours = 0,
    this.validatedHours = 0,
    this.firstEntryAt,
    this.lastEntryAt,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.dailyMetrics = const {},
    this.operatorIds = const [],
    this.notes = '',
  });

  factory LogDocument.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LogDocument(
      logId: doc.id,
      date: DateTime.parse(doc.id), // Parse date from document ID
      projectId: data['projectId'] ?? '',
      completionStatus: LogCompletionStatus.fromString(
          data['completionStatus'] ?? 'notStarted'),
      totalEntries: data['totalEntries'] ?? 0,
      completedHours: data['completedHours'] ?? 0,
      validatedHours: data['validatedHours'] ?? 0,
      firstEntryAt: (data['firstEntryAt'] as Timestamp?)?.toDate(),
      lastEntryAt: (data['lastEntryAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      dailyMetrics: data['dailyMetrics'] ?? {},
      operatorIds: List<String>.from(data['operatorIds'] ?? []),
      notes: data['notes'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date': logId, // Keep date as string for consistency
      'projectId': projectId,
      'completionStatus': completionStatus.name,
      'totalEntries': totalEntries,
      'completedHours': completedHours,
      'validatedHours': validatedHours,
      'firstEntryAt':
          firstEntryAt != null ? Timestamp.fromDate(firstEntryAt!) : null,
      'lastEntryAt':
          lastEntryAt != null ? Timestamp.fromDate(lastEntryAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'dailyMetrics': dailyMetrics,
      'operatorIds': operatorIds,
      'notes': notes,
    };
  }

  double get completionPercentage {
    if (totalEntries == 0) return 0.0;
    return completedHours / 24.0; // 24 hours in a day
  }

  String get formattedDate => DateFormat('EEEE, MMMM d, yyyy').format(date);
  String get shortDate => DateFormat('MMM d').format(date);
}

/// Entry document model - stored at /projects/{projectId}/logs/{yyyy-MM-dd}/entries/{hour}
class LogEntryDocument {
  final String entryId; // Format: "01", "02", etc. (hour padded)
  final int hour;
  final DateTime timestamp;
  final LogEntryType entryType;
  final Map<String, dynamic> readings;
  final String observations;
  final String operatorId;
  final bool validated;
  final DateTime? validatedAt;
  final String? validatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final bool synced;
  final Map<String, dynamic> metadata;

  LogEntryDocument({
    required this.entryId,
    required this.hour,
    required this.timestamp,
    this.entryType = LogEntryType.thermal,
    this.readings = const {},
    this.observations = '',
    this.operatorId = '',
    this.validated = false,
    this.validatedAt,
    this.validatedBy,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.synced = true,
    this.metadata = const {},
  });

  factory LogEntryDocument.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LogEntryDocument(
      entryId: doc.id,
      hour: data['hour'] ?? 0,
      timestamp: TimestampUtils.toDateTimeOrNow(data['timestamp']),
      entryType: LogEntryType.fromString(data['entryType'] ?? 'thermal'),
      readings: data['readings'] ?? _extractReadingsFromLegacyFormat(data),
      observations: data['observations'] ?? '',
      operatorId: data['operatorId'] ?? '',
      validated: data['validated'] ?? false,
      validatedAt: (data['validatedAt'] as Timestamp?)?.toDate(),
      validatedBy: data['validatedBy'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      synced: data['synced'] ?? true,
      metadata: data['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'hour': hour,
      'timestamp': Timestamp.fromDate(timestamp),
      'entryType': entryType.name,
      'readings': readings,
      'observations': observations,
      'operatorId': operatorId,
      'validated': validated,
      'validatedAt':
          validatedAt != null ? Timestamp.fromDate(validatedAt!) : null,
      'validatedBy': validatedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'synced': synced,
      'metadata': metadata,
    };
  }

  /// Helper method to extract readings from legacy flat format
  static Map<String, dynamic> _extractReadingsFromLegacyFormat(
      Map<String, dynamic> data) {
    final readings = <String, dynamic>{};

    // List of known reading fields from the existing ThermalReading model
    final readingFields = [
      'inletReading',
      'outletReading',
      'toInletReadingH2S',
      'vaporInletFlowRateFPM',
      'vaporInletFlowRateBBL',
      'tankRefillFlowRate',
      'combustionAirFlowRate',
      'vacuumAtTankVaporOutlet',
      'exhaustTemperature',
      'totalizer',
    ];

    for (final field in readingFields) {
      if (data.containsKey(field) && data[field] != null) {
        readings[field] = data[field];
      }
    }

    return readings;
  }

  /// Convert to legacy ThermalReading format for backwards compatibility
  Map<String, dynamic> toLegacyThermalReading() {
    final legacy = <String, dynamic>{
      'hour': hour,
      'timestamp': timestamp.toIso8601String(),
      'observations': observations,
      'operatorId': operatorId,
      'validated': validated,
    };

    // Add all readings to the flat structure
    legacy.addAll(readings);

    return legacy;
  }
}

/// Helper class for Firestore queries and operations
class FirestoreQueries {
  static const String projectsCollection = 'projects';
  static const String logsCollection = 'logs';
  static const String entriesCollection = 'entries';

  /// Build collection reference for project logs
  static CollectionReference<Map<String, dynamic>> projectLogs(
      String projectId) {
    return FirebaseFirestore.instance
        .collection(projectsCollection)
        .doc(projectId)
        .collection(logsCollection);
  }

  /// Build collection reference for log entries
  static CollectionReference<Map<String, dynamic>> logEntries(
      String projectId, String logId) {
    return FirebaseFirestore.instance
        .collection(projectsCollection)
        .doc(projectId)
        .collection(logsCollection)
        .doc(logId)
        .collection(entriesCollection);
  }

  /// Build document reference for a specific entry
  static DocumentReference<Map<String, dynamic>> logEntry(
    String projectId,
    String logId,
    String entryId,
  ) {
    return logEntries(projectId, logId).doc(entryId);
  }
}

/// Index requirements for optimal Firestore performance
class FirestoreIndexes {
  static const List<Map<String, dynamic>> requiredIndexes = [
    {
      'collection': 'projects',
      'fields': [
        {'field': 'createdBy', 'order': 'ASCENDING'},
        {'field': 'updatedAt', 'order': 'DESCENDING'},
      ],
    },
    {
      'collection': 'projects/{projectId}/logs',
      'fields': [
        {'field': 'date', 'order': 'DESCENDING'},
        {'field': 'completionStatus', 'order': 'ASCENDING'},
      ],
    },
    {
      'collection': 'projects/{projectId}/logs',
      'fields': [
        {'field': 'projectId', 'order': 'ASCENDING'},
        {'field': 'date', 'order': 'DESCENDING'},
      ],
    },
    {
      'collection': 'projects/{projectId}/logs/{logId}/entries',
      'fields': [
        {'field': 'hour', 'order': 'ASCENDING'},
        {'field': 'validated', 'order': 'ASCENDING'},
      ],
    },
    {
      'collection': 'projects/{projectId}/logs/{logId}/entries',
      'fields': [
        {'field': 'operatorId', 'order': 'ASCENDING'},
        {'field': 'createdAt', 'order': 'DESCENDING'},
      ],
    },
  ];

  static String getIndexCreationInstructions() {
    return '''
Firestore Indexes Required:

To create these indexes, either:
1. Use the Firebase Console to create composite indexes
2. Use the Firebase CLI: firebase firestore:indexes:add
3. Deploy using firestore.indexes.json file

Required indexes:
${requiredIndexes.map((index) => '- Collection: ${index['collection']}\n  Fields: ${index['fields']}\n').join('\n')}
    ''';
  }
}
