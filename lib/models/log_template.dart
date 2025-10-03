import 'package:flutter/services.dart';
import '../utils/validation_utils.dart';

enum LogType {
  thermal('Thermal', 'thermal'),
  marathonGbrCustom('Texas - BLANK Thermal Log - Marathon GBR - CUSTOM', 'marathon_gbr_custom'),
  environmental('Environmental', 'environmental'),
  safety('Safety', 'safety'),
  maintenance('Maintenance', 'maintenance'),
  hourlyReading('Hourly Reading', 'hourly_reading'),
  dailyMetrics('Daily System Metrics', 'daily_metrics');

  const LogType(this.displayName, this.id);
  final String displayName;
  final String id;
}

enum FieldType {
  number,
  text,
  dropdown,
  checkbox,
  dateTime,
}

class FieldValidationRule {
  final double? min;
  final double? max;
  final bool required;
  final String? pattern;
  final String? warningMessage;
  final double? warningMin;
  final double? warningMax;
  
  // Enhanced validation features
  final int? minLength;
  final int? maxLength;
  final String? customValidator;
  final String? requiredIf;
  final dynamic requiredIfValue;

  const FieldValidationRule({
    this.min,
    this.max,
    this.required = false,
    this.pattern,
    this.warningMessage,
    this.warningMin,
    this.warningMax,
    this.minLength,
    this.maxLength,
    this.customValidator,
    this.requiredIf,
    this.requiredIfValue,
  });
  
  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() => {
    'min': min,
    'max': max,
    'required': required,
    'pattern': pattern,
    'warningMessage': warningMessage,
    'warningMin': warningMin,
    'warningMax': warningMax,
    'minLength': minLength,
    'maxLength': maxLength,
    'customValidator': customValidator,
    'requiredIf': requiredIf,
    'requiredIfValue': requiredIfValue,
  };
  
  /// Create from JSON
  factory FieldValidationRule.fromJson(Map<String, dynamic> json) => 
      FieldValidationRule(
    min: json['min']?.toDouble(),
    max: json['max']?.toDouble(),
    required: json['required'] ?? false,
    pattern: json['pattern'],
    warningMessage: json['warningMessage'],
    warningMin: json['warningMin']?.toDouble(),
    warningMax: json['warningMax']?.toDouble(),
    minLength: json['minLength'],
    maxLength: json['maxLength'],
    customValidator: json['customValidator'],
    requiredIf: json['requiredIf'],
    requiredIfValue: json['requiredIfValue'],
  );
}

class LogFieldTemplate {
  final String id;
  final String label;
  final String? unit;
  final FieldType type;
  final FieldValidationRule validation;
  final List<String>? dropdownOptions;
  final String? section;
  final int order;
  final String? helpText;
  final bool isOptional;

  const LogFieldTemplate({
    required this.id,
    required this.label,
    this.unit,
    required this.type,
    this.validation = const FieldValidationRule(),
    this.dropdownOptions,
    this.section,
    required this.order,
    this.helpText,
    this.isOptional = false,
  });

  String? validate(String? value, [Map<String, dynamic>? allFieldValues]) {
    final result = ValidationUtils.validateLogField(
      field: this,
      value: value,
      allFieldValues: allFieldValues,
    );
    return result.firstError;
  }

  String? getWarning(String? value, [Map<String, dynamic>? allFieldValues]) {
    final result = ValidationUtils.validateLogField(
      field: this,
      value: value,
      allFieldValues: allFieldValues,
    );
    return result.firstWarning;
  }

  List<TextInputFormatter> get inputFormatters {
    switch (type) {
      case FieldType.number:
        return [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))];
      default:
        return [];
    }
  }
}

class LogTemplate {
  final LogType type;
  final String title;
  final String description;
  final List<LogFieldTemplate> fields;
  final Map<String, List<LogFieldTemplate>> sections;

  LogTemplate({
    required this.type,
    required this.title,
    required this.description,
    required this.fields,
  }) : sections = _groupFieldsBySection(fields);

  static Map<String, List<LogFieldTemplate>> _groupFieldsBySection(List<LogFieldTemplate> fields) {
    final Map<String, List<LogFieldTemplate>> sections = {};
    
    for (final field in fields) {
      final sectionName = field.section ?? 'General';
      sections.putIfAbsent(sectionName, () => []).add(field);
    }

    // Sort fields within each section by order
    for (final sectionFields in sections.values) {
      sectionFields.sort((a, b) => a.order.compareTo(b.order));
    }

    return sections;
  }
}

class LogTemplateRegistry {
  static final Map<LogType, LogTemplate> _templates = {
    LogType.marathonGbrCustom: LogTemplate(
      type: LogType.marathonGbrCustom,
      title: 'Texas - BLANK Thermal Log - Marathon GBR - CUSTOM',
      description: 'Marathon GBR specific thermal log with LEL monitoring and optional fields',
      fields: [
        // Readings Section - Required Fields
        const LogFieldTemplate(
          id: 'inletReading',
          label: 'Inlet Reading',
          unit: 'PPM',
          type: FieldType.number,
          section: '🔍 Readings',
          order: 1,
          validation: FieldValidationRule(
            required: true,
            min: 0,
          ),
        ),
        const LogFieldTemplate(
          id: 'outletReading',
          label: 'Outlet Reading',
          unit: 'PPM',
          type: FieldType.number,
          section: '🔍 Readings',
          order: 2,
          validation: FieldValidationRule(
            required: true,
            min: 0,
          ),
        ),
        const LogFieldTemplate(
          id: 'exhaustTemperature',
          label: 'Exhaust Temperature',
          unit: '°F',
          type: FieldType.number,
          section: '🔍 Readings',
          order: 3,
          validation: FieldValidationRule(
            required: true,
            min: 0,
            max: 2000,
            warningMin: 1200,
            warningMax: 1400,
            warningMessage: '⚠ Marathon target >1250°F',
          ),
        ),
        // NEW: LEL Inlet Reading - positioned before vaporInletVOCPpm as requested
        const LogFieldTemplate(
          id: 'lelInletReading',
          label: '%LEL Inlet',
          unit: '%',
          type: FieldType.number,
          section: '🔍 Readings',
          order: 4,
          validation: FieldValidationRule(
            required: true,
            min: 0,
            max: 100,
            warningMax: 10,
            warningMessage: '⚠ Above Marathon target (10% LEL)',
            customValidator: 'marathon_lel',
          ),
          helpText: 'Marathon target: 10% LEL',
        ),
        const LogFieldTemplate(
          id: 'vaporInletVOCPpm',
          label: 'Vapor Inlet VOC',
          unit: 'PPM',
          type: FieldType.number,
          section: '🔍 Readings',
          order: 5,
          validation: FieldValidationRule(
            required: true,
            min: 0,
          ),
        ),
        const LogFieldTemplate(
          id: 'combustionAirFlowRate',
          label: 'Combustion Air Flow Rate',
          unit: 'FPM',
          type: FieldType.number,
          section: '🔍 Readings',
          order: 6,
          validation: FieldValidationRule(
            required: true,
            min: 0,
          ),
        ),
        const LogFieldTemplate(
          id: 'toInletReadingH2S',
          label: 'H₂S Reading',
          unit: 'PPM',
          type: FieldType.number,
          section: '🔍 Readings',
          order: 7,
          validation: FieldValidationRule(
            required: true,
            min: 0,
          ),
        ),

        // Optional Fields Section - Collapsible
        const LogFieldTemplate(
          id: 'vaporInletFlowRateFpm',
          label: 'Vapor Inlet Flow Rate',
          unit: 'FPM',
          type: FieldType.number,
          section: '⚙️ Optional Readings',
          order: 8,
          isOptional: true,
          validation: FieldValidationRule(
            required: false,
            min: 0,
          ),
        ),
        const LogFieldTemplate(
          id: 'tankRefillFlowRateBblHr',
          label: 'Tank Refill Flow Rate',
          unit: 'BBL/HR',
          type: FieldType.number,
          section: '⚙️ Optional Readings',
          order: 9,
          isOptional: true,
          validation: FieldValidationRule(
            required: false,
            min: 0,
          ),
        ),
        const LogFieldTemplate(
          id: 'vacuumAtTankVaporOutlet',
          label: 'Vacuum at Tank Vapor Outlet',
          unit: 'Inch H₂O',
          type: FieldType.number,
          section: '⚙️ Optional Readings',
          order: 10,
          isOptional: true,
          validation: FieldValidationRule(
            required: false,
            min: 0,
          ),
        ),

        // System Metrics
        const LogFieldTemplate(
          id: 'totalizer',
          label: 'Totalizer',
          unit: 'SCF',
          type: FieldType.number,
          section: '📊 System Metrics',
          order: 11,
          validation: FieldValidationRule(
            required: false,
            min: 0,
          ),
        ),

        // Notes Section
        const LogFieldTemplate(
          id: 'observations',
          label: 'Observations / Anomalies',
          type: FieldType.text,
          section: '📝 Notes',
          order: 12,
          helpText: 'Marathon GBR specific observations, sour water processing notes...',
        ),
      ],
    ),

    LogType.thermal: LogTemplate(
      type: LogType.thermal,
      title: 'Thermal Data Entry',
      description: 'Hourly thermal system readings and metrics',
      fields: [
        // Readings Section
        const LogFieldTemplate(
          id: 'inletReading',
          label: 'Inlet Reading',
          unit: 'PPM',
          type: FieldType.number,
          section: '🔍 Readings',
          order: 1,
          validation: FieldValidationRule(
            required: true,
            min: 0,
          ),
        ),
        const LogFieldTemplate(
          id: 'outletReading',
          label: 'Outlet Reading',
          unit: 'PPM',
          type: FieldType.number,
          section: '🔍 Readings',
          order: 2,
          validation: FieldValidationRule(
            required: true,
            min: 0,
          ),
        ),
        const LogFieldTemplate(
          id: 'toInletReadingH2S',
          label: 'T.O. Inlet Reading – PPM H₂S',
          unit: 'PPM',
          type: FieldType.number,
          section: '🔍 Readings',
          order: 3,
          validation: FieldValidationRule(
            required: true,
            min: 0,
          ),
        ),

        // Flow Rates Section
        const LogFieldTemplate(
          id: 'vaporInletFlowRateFPM',
          label: 'Vapor Inlet Flow Rate',
          unit: 'FPM',
          type: FieldType.number,
          section: '🌊 Flow Rates',
          order: 4,
          validation: FieldValidationRule(
            required: true,
            min: 0,
          ),
        ),
        const LogFieldTemplate(
          id: 'vaporInletFlowRateBBL',
          label: 'Vapor Inlet Flow Rate',
          unit: 'BBL/HR',
          type: FieldType.number,
          section: '🌊 Flow Rates',
          order: 5,
          validation: FieldValidationRule(
            required: true,
            min: 0,
          ),
        ),
        const LogFieldTemplate(
          id: 'tankRefillFlowRate',
          label: 'Tank Refill Flow Rate',
          unit: 'BBL/HR',
          type: FieldType.number,
          section: '🌊 Flow Rates',
          order: 6,
          validation: FieldValidationRule(
            required: true,
            min: 0,
          ),
        ),
        const LogFieldTemplate(
          id: 'combustionAirFlowRate',
          label: 'Combustion Air Flow Rate',
          unit: 'FPM',
          type: FieldType.number,
          section: '🌊 Flow Rates',
          order: 7,
          validation: FieldValidationRule(
            required: true,
            min: 0,
          ),
        ),

        // System Metrics Section
        const LogFieldTemplate(
          id: 'vacuumAtTankVaporOutlet',
          label: 'Vacuum at Tank Vapor Outlet',
          unit: 'Inch H₂O',
          type: FieldType.number,
          section: '🔥 System Metrics',
          order: 8,
          validation: FieldValidationRule(
            required: true,
            min: 2,
            warningMin: 2,
            warningMessage: '⚠ Below minimum requirement (2 Inch H₂O)',
          ),
          helpText: 'Minimum requirement: 2 Inch H₂O',
        ),
        const LogFieldTemplate(
          id: 'exhaustTemperature',
          label: 'Exhaust Temperature',
          unit: '°F',
          type: FieldType.number,
          section: '🔥 System Metrics',
          order: 9,
          validation: FieldValidationRule(
            required: true,
            min: 0,
            max: 2000,
            warningMin: 300,
            warningMax: 1200,
            warningMessage: '⚠ Outside normal range (300-1200°F)',
            customValidator: 'thermal_efficiency',
          ),
        ),
        const LogFieldTemplate(
          id: 'totalizer',
          label: 'Totalizer',
          unit: 'SCF',
          type: FieldType.number,
          section: '🔥 System Metrics',
          order: 10,
          validation: FieldValidationRule(
            required: true,
            min: 0,
          ),
        ),

        // Notes Section
        const LogFieldTemplate(
          id: 'observations',
          label: 'Observations / Anomalies',
          type: FieldType.text,
          section: '📝 Notes',
          order: 11,
          helpText: 'Enter any observations, anomalies, equipment issues, or maintenance notes...',
        ),
      ],
    ),

    LogType.environmental: LogTemplate(
      type: LogType.environmental,
      title: 'Environmental Monitoring',
      description: 'Environmental conditions and air quality readings',
      fields: [
        const LogFieldTemplate(
          id: 'ambientTemperature',
          label: 'Ambient Temperature',
          unit: '°F',
          type: FieldType.number,
          section: '🌡️ Temperature',
          order: 1,
          validation: FieldValidationRule(
            required: true,
            min: -50,
            max: 150,
          ),
        ),
        const LogFieldTemplate(
          id: 'humidity',
          label: 'Relative Humidity',
          unit: '%',
          type: FieldType.number,
          section: '🌡️ Temperature',
          order: 2,
          validation: FieldValidationRule(
            required: true,
            min: 0,
            max: 100,
          ),
        ),
        const LogFieldTemplate(
          id: 'windSpeed',
          label: 'Wind Speed',
          unit: 'mph',
          type: FieldType.number,
          section: '🌬️ Weather',
          order: 3,
          validation: FieldValidationRule(
            required: true,
            min: 0,
          ),
        ),
        const LogFieldTemplate(
          id: 'windDirection',
          label: 'Wind Direction',
          type: FieldType.dropdown,
          section: '🌬️ Weather',
          order: 4,
          dropdownOptions: ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'],
          validation: FieldValidationRule(required: true),
        ),
        const LogFieldTemplate(
          id: 'notes',
          label: 'Environmental Notes',
          type: FieldType.text,
          section: '📝 Notes',
          order: 5,
        ),
      ],
    ),

    LogType.safety: LogTemplate(
      type: LogType.safety,
      title: 'Safety Inspection',
      description: 'Safety equipment and protocol verification',
      fields: [
        const LogFieldTemplate(
          id: 'fireExtinguishers',
          label: 'Fire Extinguishers Check',
          type: FieldType.checkbox,
          section: '🚨 Safety Equipment',
          order: 1,
          validation: FieldValidationRule(required: true),
        ),
        const LogFieldTemplate(
          id: 'emergencyShutoff',
          label: 'Emergency Shutoff Systems',
          type: FieldType.checkbox,
          section: '🚨 Safety Equipment',
          order: 2,
          validation: FieldValidationRule(required: true),
        ),
        const LogFieldTemplate(
          id: 'gasDetectors',
          label: 'Gas Detectors Operational',
          type: FieldType.checkbox,
          section: '🚨 Safety Equipment',
          order: 3,
          validation: FieldValidationRule(required: true),
        ),
        const LogFieldTemplate(
          id: 'safetyNotes',
          label: 'Safety Observations',
          type: FieldType.text,
          section: '📝 Notes',
          order: 4,
        ),
      ],
    ),

    LogType.maintenance: LogTemplate(
      type: LogType.maintenance,
      title: 'Maintenance Log',
      description: 'Equipment maintenance and service records',
      fields: [
        const LogFieldTemplate(
          id: 'equipmentId',
          label: 'Equipment ID',
          type: FieldType.text,
          section: '🔧 Equipment',
          order: 1,
          validation: FieldValidationRule(required: true),
        ),
        const LogFieldTemplate(
          id: 'maintenanceType',
          label: 'Maintenance Type',
          type: FieldType.dropdown,
          section: '🔧 Equipment',
          order: 2,
          dropdownOptions: ['Preventive', 'Corrective', 'Emergency', 'Inspection'],
          validation: FieldValidationRule(required: true),
        ),
        const LogFieldTemplate(
          id: 'workPerformed',
          label: 'Work Performed',
          type: FieldType.text,
          section: '📋 Details',
          order: 3,
          validation: FieldValidationRule(required: true),
        ),
        const LogFieldTemplate(
          id: 'partsUsed',
          label: 'Parts Used',
          type: FieldType.text,
          section: '📋 Details',
          order: 4,
        ),
        const LogFieldTemplate(
          id: 'nextServiceDate',
          label: 'Next Service Date',
          type: FieldType.dateTime,
          section: '📅 Scheduling',
          order: 5,
        ),
      ],
    ),
  };

  static LogTemplate getTemplate(LogType type) {
    return _templates[type]!;
  }

  static List<LogType> get availableTypes => LogType.values;
}