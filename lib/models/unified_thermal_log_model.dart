import 'dart:convert';

/// Unified thermal log model that can dynamically generate forms
/// based on JSON schema definitions for all 17 Texas thermal log templates
class UnifiedThermalLogModel {
  final String schemaVersion;
  final TemplateMetadata templateMetadata;
  final List<FormSection> sections;
  final List<FieldDefinition> fields;

  UnifiedThermalLogModel({
    required this.schemaVersion,
    required this.templateMetadata,
    required this.sections,
    required this.fields,
  });

  /// Factory constructor to create from JSON schema
  factory UnifiedThermalLogModel.fromJson(Map<String, dynamic> json) {
    return UnifiedThermalLogModel(
      schemaVersion: json['schemaVersion'],
      templateMetadata: TemplateMetadata.fromJson(json['templateMetadata']),
      sections: (json['sections'] as List)
          .map((section) => FormSection.fromJson(section))
          .toList(),
      fields: (json['fields'] as List)
          .map((field) => FieldDefinition.fromJson(field))
          .toList(),
    );
  }

  /// Get fields enabled for a specific template
  List<FieldDefinition> getEnabledFields(String templateId) {
    return fields.where((field) {
      final enabledFor = field.conditionalDisplay?.enabledFor ?? [];
      return enabledFor.contains('*') || enabledFor.contains(templateId);
    }).toList();
  }

  /// Get fields organized by sections for a specific template
  Map<String, List<FieldDefinition>> getFieldsBySection(String templateId) {
    final enabledFields = getEnabledFields(templateId);
    final Map<String, List<FieldDefinition>> sectionedFields = {};

    for (final field in enabledFields) {
      sectionedFields.putIfAbsent(field.section, () => []).add(field);
    }

    // Sort fields within each section by order
    for (final sectionFields in sectionedFields.values) {
      sectionFields.sort((a, b) => a.order.compareTo(b.order));
    }

    return sectionedFields;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'templateMetadata': templateMetadata.toJson(),
        'sections': sections.map((s) => s.toJson()).toList(),
        'fields': fields.map((f) => f.toJson()).toList(),
      };
}

/// Template metadata containing identifying information
class TemplateMetadata {
  final String id;
  final String displayName;
  final String capacity;
  final String fuelType;
  final List<String> monitoringTypes;
  final String? frequency;
  final String? processStage;
  final String? excelTemplatePath;
  final String? regulatoryVersion;

  TemplateMetadata({
    required this.id,
    required this.displayName,
    required this.capacity,
    required this.fuelType,
    this.monitoringTypes = const [],
    this.frequency,
    this.processStage,
    this.excelTemplatePath,
    this.regulatoryVersion,
  });

  factory TemplateMetadata.fromJson(Map<String, dynamic> json) {
    return TemplateMetadata(
      id: json['id'],
      displayName: json['displayName'],
      capacity: json['capacity'],
      fuelType: json['fuelType'],
      monitoringTypes: (json['monitoringTypes'] as List?)
          ?.map((e) => e as String)
          .toList() ?? [],
      frequency: json['frequency'],
      processStage: json['processStage'],
      excelTemplatePath: json['excelTemplatePath'],
      regulatoryVersion: json['regulatoryVersion'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'capacity': capacity,
        'fuelType': fuelType,
        'monitoringTypes': monitoringTypes,
        'frequency': frequency,
        'processStage': processStage,
        'excelTemplatePath': excelTemplatePath,
        'regulatoryVersion': regulatoryVersion,
      };
}

/// Form section containing display and organizational information
class FormSection {
  final String id;
  final String displayName;
  final int order;
  final bool collapsible;
  final bool collapsed;

  FormSection({
    required this.id,
    required this.displayName,
    required this.order,
    this.collapsible = false,
    this.collapsed = false,
  });

  factory FormSection.fromJson(Map<String, dynamic> json) {
    return FormSection(
      id: json['id'],
      displayName: json['displayName'],
      order: json['order'],
      collapsible: json['collapsible'] ?? false,
      collapsed: json['collapsed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'order': order,
        'collapsible': collapsible,
        'collapsed': collapsed,
      };
}

/// Individual field definition with validation and display logic
class FieldDefinition {
  final String id;
  final String label;
  final String? unit;
  final String type;
  final String section;
  final int order;
  final bool required;
  final bool isOptional;
  final String? helpText;
  final List<String>? dropdownOptions;
  final ValidationRule? validation;
  final ConditionalDisplay? conditionalDisplay;
  final ExcelMapping? excelMapping;

  FieldDefinition({
    required this.id,
    required this.label,
    this.unit,
    required this.type,
    required this.section,
    required this.order,
    this.required = false,
    this.isOptional = false,
    this.helpText,
    this.dropdownOptions,
    this.validation,
    this.conditionalDisplay,
    this.excelMapping,
  });

  factory FieldDefinition.fromJson(Map<String, dynamic> json) {
    return FieldDefinition(
      id: json['id'],
      label: json['label'],
      unit: json['unit'],
      type: json['type'],
      section: json['section'],
      order: json['order'],
      required: json['required'] ?? false,
      isOptional: json['isOptional'] ?? false,
      helpText: json['helpText'],
      dropdownOptions: (json['dropdownOptions'] as List?)
          ?.map((e) => e as String)
          .toList(),
      validation: json['validation'] != null
          ? ValidationRule.fromJson(json['validation'])
          : null,
      conditionalDisplay: json['conditionalDisplay'] != null
          ? ConditionalDisplay.fromJson(json['conditionalDisplay'])
          : null,
      excelMapping: json['excelMapping'] != null
          ? ExcelMapping.fromJson(json['excelMapping'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'unit': unit,
        'type': type,
        'section': section,
        'order': order,
        'required': required,
        'isOptional': isOptional,
        'helpText': helpText,
        'dropdownOptions': dropdownOptions,
        'validation': validation?.toJson(),
        'conditionalDisplay': conditionalDisplay?.toJson(),
        'excelMapping': excelMapping?.toJson(),
      };
}

/// Validation rules for field input
class ValidationRule {
  final double? min;
  final double? max;
  final double? warningMin;
  final double? warningMax;
  final String? warningMessage;
  final String? pattern;
  final int? minLength;
  final int? maxLength;
  final String? customValidator;
  final String? requiredIf;
  final dynamic requiredIfValue;

  ValidationRule({
    this.min,
    this.max,
    this.warningMin,
    this.warningMax,
    this.warningMessage,
    this.pattern,
    this.minLength,
    this.maxLength,
    this.customValidator,
    this.requiredIf,
    this.requiredIfValue,
  });

  factory ValidationRule.fromJson(Map<String, dynamic> json) {
    return ValidationRule(
      min: json['min']?.toDouble(),
      max: json['max']?.toDouble(),
      warningMin: json['warningMin']?.toDouble(),
      warningMax: json['warningMax']?.toDouble(),
      warningMessage: json['warningMessage'],
      pattern: json['pattern'],
      minLength: json['minLength'],
      maxLength: json['maxLength'],
      customValidator: json['customValidator'],
      requiredIf: json['requiredIf'],
      requiredIfValue: json['requiredIfValue'],
    );
  }

  Map<String, dynamic> toJson() => {
        'min': min,
        'max': max,
        'warningMin': warningMin,
        'warningMax': warningMax,
        'warningMessage': warningMessage,
        'pattern': pattern,
        'minLength': minLength,
        'maxLength': maxLength,
        'customValidator': customValidator,
        'requiredIf': requiredIf,
        'requiredIfValue': requiredIfValue,
      };
}

/// Conditional display logic for fields
class ConditionalDisplay {
  final List<String>? dependsOn;
  final String? condition;
  final List<String>? enabledFor;

  ConditionalDisplay({
    this.dependsOn,
    this.condition,
    this.enabledFor,
  });

  factory ConditionalDisplay.fromJson(Map<String, dynamic> json) {
    return ConditionalDisplay(
      dependsOn: (json['dependsOn'] as List?)
          ?.map((e) => e as String)
          .toList(),
      condition: json['condition'],
      enabledFor: (json['enabledFor'] as List?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'dependsOn': dependsOn,
        'condition': condition,
        'enabledFor': enabledFor,
      };
}

/// Excel column mapping information
class ExcelMapping {
  final Map<String, ColumnMapping>? columnMappings;

  ExcelMapping({this.columnMappings});

  factory ExcelMapping.fromJson(Map<String, dynamic> json) {
    final mappings = json['columnMappings'] as Map<String, dynamic>?;
    return ExcelMapping(
      columnMappings: mappings?.map(
        (key, value) => MapEntry(key, ColumnMapping.fromJson(value)),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'columnMappings': columnMappings?.map(
          (key, value) => MapEntry(key, value.toJson()),
        ),
      };
}

/// Excel column mapping for specific template
class ColumnMapping {
  final int columnIndex;
  final String? columnLetter;
  final int headerRow;
  final int dataStartRow;

  ColumnMapping({
    required this.columnIndex,
    this.columnLetter,
    this.headerRow = 8,
    this.dataStartRow = 9,
  });

  factory ColumnMapping.fromJson(Map<String, dynamic> json) {
    return ColumnMapping(
      columnIndex: json['columnIndex'],
      columnLetter: json['columnLetter'],
      headerRow: json['headerRow'] ?? 8,
      dataStartRow: json['dataStartRow'] ?? 9,
    );
  }

  Map<String, dynamic> toJson() => {
        'columnIndex': columnIndex,
        'columnLetter': columnLetter,
        'headerRow': headerRow,
        'dataStartRow': dataStartRow,
      };
}

/// Template registry for dynamic template loading
class UnifiedThermalLogRegistry {
  static Map<String, UnifiedThermalLogModel> _templates = {};

  /// Clear all templates (for testing)
  static void clearTemplates() {
    _templates.clear();
  }

  /// Register a template from JSON
  static void registerTemplate(String templateId, Map<String, dynamic> json) {
    _templates[templateId] = UnifiedThermalLogModel.fromJson(json);
  }

  /// Get template by ID
  static UnifiedThermalLogModel? getTemplate(String templateId) {
    return _templates[templateId];
  }

  /// Get all available template IDs
  static List<String> get availableTemplateIds => _templates.keys.toList();

  /// Load templates from JSON file
  static Future<void> loadTemplatesFromAssets() async {
    // This would load from assets/thermal_templates.json
    // Implementation depends on asset loading strategy
  }
}