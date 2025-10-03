
import '../models/log_template.dart';

/// Job Template Configuration
class JobTemplateConfig {
  final LogType logType;
  final String? excelTemplateId;
  final String? excelTemplatePath;
  final String? mappingFilePath;
  final Map<String, dynamic> customSettings;
  final bool autoExportEnabled;
  final DateTime? configuredAt;

  const JobTemplateConfig({
    required this.logType,
    this.excelTemplateId,
    this.excelTemplatePath,
    this.mappingFilePath,
    this.customSettings = const {},
    this.autoExportEnabled = false,
    this.configuredAt,
  });

  factory JobTemplateConfig.fromMap(Map<String, dynamic> map) {
    return JobTemplateConfig(
      logType: LogType.values.firstWhere(
        (type) => type.id == map['logType'],
        orElse: () => LogType.thermal,
      ),
      excelTemplateId: map['excelTemplateId'],
      excelTemplatePath: map['excelTemplatePath'],
      mappingFilePath: map['mappingFilePath'],
      customSettings: Map<String, dynamic>.from(map['customSettings'] ?? {}),
      autoExportEnabled: map['autoExportEnabled'] ?? false,
      configuredAt: map['configuredAt'] != null
          ? DateTime.parse(map['configuredAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'logType': logType.id,
      'excelTemplateId': excelTemplateId,
      'excelTemplatePath': excelTemplatePath,
      'mappingFilePath': mappingFilePath,
      'customSettings': customSettings,
      'autoExportEnabled': autoExportEnabled,
      'configuredAt': configuredAt?.toIso8601String(),
    };
  }

  JobTemplateConfig copyWith({
    LogType? logType,
    String? excelTemplateId,
    String? excelTemplatePath,
    String? mappingFilePath,
    Map<String, dynamic>? customSettings,
    bool? autoExportEnabled,
    DateTime? configuredAt,
  }) {
    return JobTemplateConfig(
      logType: logType ?? this.logType,
      excelTemplateId: excelTemplateId ?? this.excelTemplateId,
      excelTemplatePath: excelTemplatePath ?? this.excelTemplatePath,
      mappingFilePath: mappingFilePath ?? this.mappingFilePath,
      customSettings: customSettings ?? this.customSettings,
      autoExportEnabled: autoExportEnabled ?? this.autoExportEnabled,
      configuredAt: configuredAt ?? this.configuredAt,
    );
  }
}

class Job {
  final String projectNumber;
  final String facilityName;
  final String tankId;
  final String logType;
  final JobTemplateConfig? templateConfig;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  Job({
    required this.projectNumber,
    required this.facilityName,
    required this.tankId,
    required this.logType,
    this.templateConfig,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  factory Job.fromMap(Map<String, dynamic> map) => Job(
    projectNumber: map['projectNumber'],
    facilityName: map['facilityName'],
    tankId: map['tankId'],
    logType: map['logType'],
    templateConfig: map['templateConfig'] != null
        ? JobTemplateConfig.fromMap(map['templateConfig'])
        : null,
    createdAt: map['createdAt'] != null
        ? DateTime.parse(map['createdAt'])
        : null,
    updatedAt: map['updatedAt'] != null
        ? DateTime.parse(map['updatedAt'])
        : null,
    createdBy: map['createdBy'],
  );

  Map<String, dynamic> toMap() {
    return {
      'projectNumber': projectNumber,
      'facilityName': facilityName,
      'tankId': tankId,
      'logType': logType,
      'templateConfig': templateConfig?.toMap(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  Job copyWith({
    String? projectNumber,
    String? facilityName,
    String? tankId,
    String? logType,
    JobTemplateConfig? templateConfig,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return Job(
      projectNumber: projectNumber ?? this.projectNumber,
      facilityName: facilityName ?? this.facilityName,
      tankId: tankId ?? this.tankId,
      logType: logType ?? this.logType,
      templateConfig: templateConfig ?? this.templateConfig,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  /// Check if job has Excel template configured
  bool get hasExcelTemplate => templateConfig?.excelTemplateId != null;

  /// Get Flutter log type enum
  LogType get logTypeEnum {
    return LogType.values.firstWhere(
      (type) => type.id == logType || type.displayName == logType,
      orElse: () => LogType.thermal,
    );
  }

  /// Get display name for the configured template
  String get templateDisplayName {
    if (templateConfig?.excelTemplateId != null) {
      return templateConfig!.excelTemplateId!;
    }
    return logTypeEnum.displayName;
  }
}

