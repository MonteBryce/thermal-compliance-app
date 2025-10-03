import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/log_template.dart';

/// Excel Template Configuration
class ExcelTemplateConfig {
  final String id;
  final String displayName;
  final String description;
  final String excelTemplatePath;
  final String mappingFilePath;
  final List<String> requiredFields;
  final Map<String, String> fieldMapping; // flutter field -> excel column mapping
  final List<LogType> compatibleLogTypes;
  final Map<String, dynamic> validationRules;
  final bool isActive;

  const ExcelTemplateConfig({
    required this.id,
    required this.displayName,
    required this.description,
    required this.excelTemplatePath,
    required this.mappingFilePath,
    required this.requiredFields,
    required this.fieldMapping,
    required this.compatibleLogTypes,
    required this.validationRules,
    this.isActive = true,
  });

  factory ExcelTemplateConfig.fromJson(Map<String, dynamic> json) {
    return ExcelTemplateConfig(
      id: json['id'],
      displayName: json['displayName'],
      description: json['description'],
      excelTemplatePath: json['excelTemplatePath'],
      mappingFilePath: json['mappingFilePath'],
      requiredFields: List<String>.from(json['requiredFields'] ?? []),
      fieldMapping: Map<String, String>.from(json['fieldMapping'] ?? {}),
      compatibleLogTypes: (json['compatibleLogTypes'] as List?)
          ?.map((e) => LogType.values.firstWhere((type) => type.id == e))
          .toList() ?? [],
      validationRules: json['validationRules'] ?? {},
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'description': description,
      'excelTemplatePath': excelTemplatePath,
      'mappingFilePath': mappingFilePath,
      'requiredFields': requiredFields,
      'fieldMapping': fieldMapping,
      'compatibleLogTypes': compatibleLogTypes.map((e) => e.id).toList(),
      'validationRules': validationRules,
      'isActive': isActive,
    };
  }
}

/// Job Template Selection Result
class JobTemplateSelection {
  final LogType logType;
  final ExcelTemplateConfig excelTemplate;
  final Map<String, dynamic> customConfiguration;

  const JobTemplateSelection({
    required this.logType,
    required this.excelTemplate,
    this.customConfiguration = const {},
  });
}

/// Service for managing Excel template selection and configuration
class ExcelTemplateSelectionService {
  static const String _configAssetPath = 'assets/excel_templates_config.json';
  
  List<ExcelTemplateConfig>? _cachedTemplates;

  /// Load available Excel templates from configuration
  Future<List<ExcelTemplateConfig>> getAvailableTemplates() async {
    if (_cachedTemplates != null) {
      return _cachedTemplates!;
    }

    try {
      final configString = await rootBundle.loadString(_configAssetPath);
      final configJson = json.decode(configString);
      
      _cachedTemplates = (configJson['templates'] as List)
          .map((json) => ExcelTemplateConfig.fromJson(json))
          .where((template) => template.isActive)
          .toList();
      
      return _cachedTemplates!;
    } catch (e) {
      // Fallback to hardcoded templates if config file doesn't exist
      return _getHardcodedTemplates();
    }
  }

  /// Get templates compatible with a specific log type
  Future<List<ExcelTemplateConfig>> getTemplatesForLogType(LogType logType) async {
    final allTemplates = await getAvailableTemplates();
    return allTemplates
        .where((template) => template.compatibleLogTypes.contains(logType))
        .toList();
  }

  /// Get recommended template for a log type
  Future<ExcelTemplateConfig?> getRecommendedTemplate(LogType logType) async {
    final compatibleTemplates = await getTemplatesForLogType(logType);
    
    // Return the first active template that matches the log type
    if (compatibleTemplates.isNotEmpty) {
      return compatibleTemplates.first;
    }
    
    return null;
  }

  /// Validate that required fields are available in the Flutter template
  bool validateFieldMapping(LogType logType, ExcelTemplateConfig excelTemplate) {
    final flutterTemplate = LogTemplateRegistry.getTemplate(logType);
    final flutterFieldIds = flutterTemplate.fields.map((f) => f.id).toSet();
    
    // Check if all required Excel fields have corresponding Flutter fields
    for (final requiredField in excelTemplate.requiredFields) {
      final flutterField = excelTemplate.fieldMapping[requiredField];
      if (flutterField == null || !flutterFieldIds.contains(flutterField)) {
        return false;
      }
    }
    
    return true;
  }

  /// Create job template selection
  Future<JobTemplateSelection?> createJobTemplateSelection({
    required LogType logType,
    ExcelTemplateConfig? preferredExcelTemplate,
    Map<String, dynamic> customConfig = const {},
  }) async {
    ExcelTemplateConfig? excelTemplate = preferredExcelTemplate;
    
    // If no preferred template, get recommended one
    if (excelTemplate == null) {
      excelTemplate = await getRecommendedTemplate(logType);
    }
    
    if (excelTemplate == null) {
      return null;
    }
    
    // Validate field mapping
    if (!validateFieldMapping(logType, excelTemplate)) {
      throw Exception('Field mapping validation failed for template ${excelTemplate.id}');
    }
    
    return JobTemplateSelection(
      logType: logType,
      excelTemplate: excelTemplate,
      customConfiguration: customConfig,
    );
  }

  /// Get template by ID
  Future<ExcelTemplateConfig?> getTemplateById(String templateId) async {
    final templates = await getAvailableTemplates();
    try {
      return templates.firstWhere((t) => t.id == templateId);
    } catch (e) {
      return null;
    }
  }

  /// Hardcoded fallback templates based on your existing report pipeline
  List<ExcelTemplateConfig> _getHardcodedTemplates() {
    return [
      const ExcelTemplateConfig(
        id: 'texas_methane_h2s_benzene',
        displayName: 'Texas Methane H2S & Benzene (10-60MMBTU)',
        description: 'Texas thermal log template for methane monitoring with H2S and benzene tracking',
        excelTemplatePath: 'reports/templates/Texas - BLANK Thermal Log - 10-60MMBTU (METHANE) 8.14.17 H2S & Benzene.xlsx',
        mappingFilePath: 'reports/mapping/methane_hourly.map.json',
        requiredFields: [
          'vaporInletFlowRateFPM',
          'vaporInletFlowRateBBLHR',
          'exhaustTempF',
          'h2sInletReading',
          'methaneInletReading'
        ],
        fieldMapping: {
          'vaporInletFlowRateFPM': 'vaporInletFlowRateFpm',
          'vaporInletFlowRateBBLHR': 'vaporInletFlowRateBBL',
          'exhaustTempF': 'exhaustTemperature',
          'h2sInletReading': 'toInletReadingH2S',
          'methaneInletReading': 'inletReading',
          'methaneOutletReading': 'outletReading',
          'combustionAirFlowRate': 'combustionAirFlowRate',
          'tankRefillFlowRate': 'tankRefillFlowRateBblHr',
          'vacuumAtTank': 'vacuumAtTankVaporOutlet',
        },
        compatibleLogTypes: [LogType.thermal, LogType.marathonGbrCustom],
        validationRules: {
          'exhaustTempF': {'min': 1200, 'max': 1800},
          'h2sInletReading': {'max': 20},
          'methaneInletReading': {'max': 100},
        },
      ),
      
      const ExcelTemplateConfig(
        id: 'texas_methane_standard',
        displayName: 'Texas Methane Standard (10-60MMBTU)',
        description: 'Standard Texas thermal log template for basic methane monitoring',
        excelTemplatePath: 'reports/templates/Texas - BLANK Thermal Log - 10-60MMBTU (METHANE) 8.14.17.xlsx',
        mappingFilePath: 'reports/mapping/methane_standard.map.json',
        requiredFields: [
          'vaporInletFlowRateFPM',
          'exhaustTempF',
          'methaneInletReading'
        ],
        fieldMapping: {
          'vaporInletFlowRateFPM': 'vaporInletFlowRateFpm',
          'exhaustTempF': 'exhaustTemperature',
          'methaneInletReading': 'inletReading',
          'methaneOutletReading': 'outletReading',
          'combustionAirFlowRate': 'combustionAirFlowRate',
        },
        compatibleLogTypes: [LogType.thermal],
        validationRules: {
          'exhaustTempF': {'min': 1200, 'max': 1800},
          'methaneInletReading': {'max': 100},
        },
      ),
      
      const ExcelTemplateConfig(
        id: 'texas_pentane_h2s_benzene',
        displayName: 'Texas Pentane H2S & Benzene (10-60MMBTU)',
        description: 'Texas thermal log template for pentane with H2S and benzene monitoring',
        excelTemplatePath: 'reports/templates/Texas - BLANK Thermal Log - 10-60MMBTU (PENTANE) 8.14.17 - H2S Hourly & Benzene.xlsx',
        mappingFilePath: 'reports/mapping/pentane_hourly.map.json',
        requiredFields: [
          'vaporInletFlowRateFPM',
          'exhaustTempF',
          'h2sInletReading'
        ],
        fieldMapping: {
          'vaporInletFlowRateFPM': 'vaporInletFlowRateFpm',
          'exhaustTempF': 'exhaustTemperature',
          'h2sInletReading': 'toInletReadingH2S',
          'combustionAirFlowRate': 'combustionAirFlowRate',
        },
        compatibleLogTypes: [LogType.thermal],
        validationRules: {
          'exhaustTempF': {'min': 1200, 'max': 1800},
          'h2sInletReading': {'max': 20},
        },
      ),
      
      const ExcelTemplateConfig(
        id: 'texas_methane_small',
        displayName: 'Texas Methane Small Unit (1.5MMBTU)',
        description: 'Texas thermal log template for smaller methane units',
        excelTemplatePath: 'reports/templates/Texas - BLANK Thermal Log - 1.5MMBTU (METHANE) 8.14.17.xlsx',
        mappingFilePath: 'reports/mapping/methane_small.map.json',
        requiredFields: [
          'vaporInletFlowRateFPM',
          'exhaustTempF',
          'methaneInletReading'
        ],
        fieldMapping: {
          'vaporInletFlowRateFPM': 'vaporInletFlowRateFpm',
          'exhaustTempF': 'exhaustTemperature',
          'methaneInletReading': 'inletReading',
          'methaneOutletReading': 'outletReading',
        },
        compatibleLogTypes: [LogType.thermal],
        validationRules: {
          'exhaustTempF': {'min': 1200, 'max': 1800},
          'methaneInletReading': {'max': 100},
        },
      ),
    ];
  }

  /// Clear cached templates (useful for testing or config updates)
  void clearCache() {
    _cachedTemplates = null;
  }
}

/// Extensions to make template selection easier
extension JobTemplateSelectionExtensions on JobTemplateSelection {
  /// Get mapped field value for Excel export
  String? getMappedFieldId(String excelFieldId) {
    return excelTemplate.fieldMapping[excelFieldId];
  }
  
  /// Check if a field is required for this template
  bool isFieldRequired(String excelFieldId) {
    return excelTemplate.requiredFields.contains(excelFieldId);
  }
  
  /// Get validation rules for a field
  Map<String, dynamic>? getFieldValidationRules(String excelFieldId) {
    return excelTemplate.validationRules[excelFieldId];
  }
}