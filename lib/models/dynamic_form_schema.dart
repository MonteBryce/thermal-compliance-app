import 'package:cloud_firestore/cloud_firestore.dart';

/// Comprehensive Form Template Schema for Dynamic Form Generation
/// 
/// This schema supports the thermal logging MVP requirements for:
/// - Job logType-based form generation
/// - Project-specific field customization
/// - Validation and conditional field logic
/// - Offline-first template caching

/// Enhanced field types supporting thermal logging requirements
enum DynamicFieldType {
  text,
  number,
  decimal,
  select,
  multiSelect,
  checkbox,
  date,
  time,
  dateTime,
  temperature,     // Special handling for temperature units
  pressure,        // Special handling for pressure units
  percentage,      // 0-100% validation
  ppm,            // Parts per million
  flow,           // Flow rate handling
  coordinates,    // GPS coordinates
  signature,      // Digital signature field
  photo,          // Photo attachment
  file,           // File attachment
  calculation,    // Auto-calculated field
}

/// Field categories for organization and conditional logic
enum DynamicFieldCategory {
  core,           // Always required (project info, timestamps)
  readings,       // Measurement readings
  conditions,     // Environmental/operational conditions  
  safety,         // Safety-related fields
  optional,       // Optional/additional fields
  calculated,     // Auto-calculated from other fields
  metadata,       // System metadata fields
}

/// Comprehensive validation rules
class DynamicFieldValidation {
  final double? min;
  final double? max;
  final String? pattern;           // Regex pattern
  final int? maxLength;
  final int? minLength;
  final bool required;
  final String? customValidator;   // Custom validation logic ID
  
  // Warning thresholds (non-blocking)
  final double? warningMin;
  final double? warningMax;
  final String? warningMessage;
  
  // Conditional validation
  final String? requiredIf;        // Field ID that makes this required
  final dynamic requiredIfValue;   // Value that triggers requirement
  
  const DynamicFieldValidation({
    this.min,
    this.max,
    this.pattern,
    this.maxLength,
    this.minLength,
    this.required = false,
    this.customValidator,
    this.warningMin,
    this.warningMax,
    this.warningMessage,
    this.requiredIf,
    this.requiredIfValue,
  });

  Map<String, dynamic> toJson() => {
    'min': min,
    'max': max,
    'pattern': pattern,
    'maxLength': maxLength,
    'minLength': minLength,
    'required': required,
    'customValidator': customValidator,
    'warningMin': warningMin,
    'warningMax': warningMax,
    'warningMessage': warningMessage,
    'requiredIf': requiredIf,
    'requiredIfValue': requiredIfValue,
  };

  factory DynamicFieldValidation.fromJson(Map<String, dynamic> json) => 
      DynamicFieldValidation(
    min: json['min']?.toDouble(),
    max: json['max']?.toDouble(),
    pattern: json['pattern'],
    maxLength: json['maxLength'],
    minLength: json['minLength'],
    required: json['required'] ?? false,
    customValidator: json['customValidator'],
    warningMin: json['warningMin']?.toDouble(),
    warningMax: json['warningMax']?.toDouble(),
    warningMessage: json['warningMessage'],
    requiredIf: json['requiredIf'],
    requiredIfValue: json['requiredIfValue'],
  );
}

/// Select field option
class DynamicSelectOption {
  final String value;
  final String label;
  final String? description;
  final bool isDefault;
  final bool isDisabled;
  final Map<String, dynamic>? metadata;

  const DynamicSelectOption({
    required this.value,
    required this.label,
    this.description,
    this.isDefault = false,
    this.isDisabled = false,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'value': value,
    'label': label,
    'description': description,
    'isDefault': isDefault,
    'isDisabled': isDisabled,
    'metadata': metadata,
  };

  factory DynamicSelectOption.fromJson(Map<String, dynamic> json) => 
      DynamicSelectOption(
    value: json['value'],
    label: json['label'],
    description: json['description'],
    isDefault: json['isDefault'] ?? false,
    isDisabled: json['isDisabled'] ?? false,
    metadata: json['metadata'],
  );
}

/// Conditional display/behavior rules
class DynamicFieldCondition {
  final String dependsOnField;     // Field ID this depends on
  final String operator;           // eq, ne, gt, lt, gte, lte, in, contains
  final dynamic value;             // Value to compare against
  final String action;             // show, hide, enable, disable, calculate

  const DynamicFieldCondition({
    required this.dependsOnField,
    required this.operator,
    required this.value,
    required this.action,
  });

  Map<String, dynamic> toJson() => {
    'dependsOnField': dependsOnField,
    'operator': operator,
    'value': value,
    'action': action,
  };

  factory DynamicFieldCondition.fromJson(Map<String, dynamic> json) => 
      DynamicFieldCondition(
    dependsOnField: json['dependsOnField'],
    operator: json['operator'],
    value: json['value'],
    action: json['action'],
  );
}

/// Complete field definition for dynamic forms
class DynamicFormField {
  final String id;
  final String key;                     // Database field name
  final String label;                   // Display label
  final DynamicFieldType type;
  final DynamicFieldCategory category;
  final String? unit;                   // Display unit (°F, PPM, etc.)
  final String? placeholder;
  final String? helpText;
  final dynamic defaultValue;
  final DynamicFieldValidation validation;
  final List<DynamicSelectOption>? options;
  final List<DynamicFieldCondition>? conditions;
  final bool showInSummary;
  final int sortOrder;
  final Map<String, dynamic>? metadata;
  
  // Project-specific overrides
  final String? projectSpecificUnit;    // Override unit for specific projects
  final dynamic projectSpecificDefault; // Override default for specific projects

  const DynamicFormField({
    required this.id,
    required this.key,
    required this.label,
    required this.type,
    this.category = DynamicFieldCategory.readings,
    this.unit,
    this.placeholder,
    this.helpText,
    this.defaultValue,
    this.validation = const DynamicFieldValidation(),
    this.options,
    this.conditions,
    this.showInSummary = false,
    this.sortOrder = 999,
    this.metadata,
    this.projectSpecificUnit,
    this.projectSpecificDefault,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'key': key,
    'label': label,
    'type': type.name,
    'category': category.name,
    'unit': unit,
    'placeholder': placeholder,
    'helpText': helpText,
    'defaultValue': defaultValue,
    'validation': validation.toJson(),
    'options': options?.map((o) => o.toJson()).toList(),
    'conditions': conditions?.map((c) => c.toJson()).toList(),
    'showInSummary': showInSummary,
    'sortOrder': sortOrder,
    'metadata': metadata,
    'projectSpecificUnit': projectSpecificUnit,
    'projectSpecificDefault': projectSpecificDefault,
  };

  factory DynamicFormField.fromJson(Map<String, dynamic> json) => 
      DynamicFormField(
    id: json['id'],
    key: json['key'],
    label: json['label'],
    type: DynamicFieldType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => DynamicFieldType.text,
    ),
    category: DynamicFieldCategory.values.firstWhere(
      (e) => e.name == json['category'],
      orElse: () => DynamicFieldCategory.readings,
    ),
    unit: json['unit'],
    placeholder: json['placeholder'],
    helpText: json['helpText'],
    defaultValue: json['defaultValue'],
    validation: DynamicFieldValidation.fromJson(json['validation'] ?? {}),
    options: json['options'] != null
        ? (json['options'] as List).map((o) => DynamicSelectOption.fromJson(o)).toList()
        : null,
    conditions: json['conditions'] != null
        ? (json['conditions'] as List).map((c) => DynamicFieldCondition.fromJson(c)).toList()
        : null,
    showInSummary: json['showInSummary'] ?? false,
    sortOrder: json['sortOrder'] ?? 999,
    metadata: json['metadata'],
    projectSpecificUnit: json['projectSpecificUnit'],
    projectSpecificDefault: json['projectSpecificDefault'],
  );
}

/// Form section for organizing fields
class DynamicFormSection {
  final String id;
  final String title;
  final String? description;
  final String? icon;               // Icon identifier
  final List<String> fieldIds;     // References to DynamicFormField IDs
  final bool collapsible;
  final bool defaultExpanded;
  final int sortOrder;
  final List<DynamicFieldCondition>? conditions; // Section-level conditions

  const DynamicFormSection({
    required this.id,
    required this.title,
    this.description,
    this.icon,
    required this.fieldIds,
    this.collapsible = false,
    this.defaultExpanded = true,
    this.sortOrder = 0,
    this.conditions,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'icon': icon,
    'fieldIds': fieldIds,
    'collapsible': collapsible,
    'defaultExpanded': defaultExpanded,
    'sortOrder': sortOrder,
    'conditions': conditions?.map((c) => c.toJson()).toList(),
  };

  factory DynamicFormSection.fromJson(Map<String, dynamic> json) => 
      DynamicFormSection(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    icon: json['icon'],
    fieldIds: List<String>.from(json['fieldIds']),
    collapsible: json['collapsible'] ?? false,
    defaultExpanded: json['defaultExpanded'] ?? true,
    sortOrder: json['sortOrder'] ?? 0,
    conditions: json['conditions'] != null
        ? (json['conditions'] as List).map((c) => DynamicFieldCondition.fromJson(c)).toList()
        : null,
  );
}

/// Complete form template definition
class DynamicFormTemplate {
  final String id;
  final String name;
  final String logType;               // Corresponds to job logType
  final String description;
  final List<DynamicFormField> fields;
  final List<DynamicFormSection> sections;
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int version;
  final bool active;
  final String? projectId;            // Optional project-specific template
  final List<String>? supportedTankTypes; // Tank types this template supports
  final Map<String, dynamic>? projectOverrides; // Project-specific field overrides

  const DynamicFormTemplate({
    required this.id,
    required this.name,
    required this.logType,
    required this.description,
    required this.fields,
    required this.sections,
    this.metadata,
    this.createdAt,
    this.updatedAt,
    this.version = 1,
    this.active = true,
    this.projectId,
    this.supportedTankTypes,
    this.projectOverrides,
  });

  /// Get field by ID
  DynamicFormField? getField(String fieldId) {
    try {
      return fields.firstWhere((f) => f.id == fieldId);
    } catch (e) {
      return null;
    }
  }

  /// Get fields for a specific section
  List<DynamicFormField> getFieldsForSection(String sectionId) {
    final section = sections.firstWhere((s) => s.id == sectionId);
    return section.fieldIds
        .map((id) => getField(id))
        .where((field) => field != null)
        .cast<DynamicFormField>()
        .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// Get all core/required fields
  List<DynamicFormField> getCoreFields() {
    return fields.where((f) => f.category == DynamicFieldCategory.core).toList();
  }

  /// Get all optional fields
  List<DynamicFormField> getOptionalFields() {
    return fields.where((f) => f.category == DynamicFieldCategory.optional).toList();
  }

  /// Apply project-specific overrides to template
  DynamicFormTemplate applyProjectOverrides(String projectId, Map<String, dynamic>? overrides) {
    if (overrides == null || overrides.isEmpty) return this;

    final updatedFields = fields.map((field) {
      final fieldOverrides = overrides[field.id] as Map<String, dynamic>?;
      if (fieldOverrides == null) return field;

      return DynamicFormField(
        id: field.id,
        key: field.key,
        label: fieldOverrides['label'] ?? field.label,
        type: field.type,
        category: field.category,
        unit: fieldOverrides['unit'] ?? field.unit,
        placeholder: fieldOverrides['placeholder'] ?? field.placeholder,
        helpText: fieldOverrides['helpText'] ?? field.helpText,
        defaultValue: fieldOverrides['defaultValue'] ?? field.defaultValue,
        validation: fieldOverrides['validation'] != null 
            ? DynamicFieldValidation.fromJson(fieldOverrides['validation'])
            : field.validation,
        options: field.options,
        conditions: field.conditions,
        showInSummary: fieldOverrides['showInSummary'] ?? field.showInSummary,
        sortOrder: fieldOverrides['sortOrder'] ?? field.sortOrder,
        metadata: {...(field.metadata ?? {}), ...(fieldOverrides['metadata'] ?? {})},
      );
    }).toList();

    return DynamicFormTemplate(
      id: id,
      name: name,
      logType: logType,
      description: description,
      fields: updatedFields,
      sections: sections,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
      version: version,
      active: active,
      projectId: projectId,
      supportedTankTypes: supportedTankTypes,
      projectOverrides: overrides,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'logType': logType,
    'description': description,
    'fields': fields.map((f) => f.toJson()).toList(),
    'sections': sections.map((s) => s.toJson()).toList(),
    'metadata': metadata,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'version': version,
    'active': active,
    'projectId': projectId,
    'supportedTankTypes': supportedTankTypes,
    'projectOverrides': projectOverrides,
  };

  factory DynamicFormTemplate.fromJson(Map<String, dynamic> json) => 
      DynamicFormTemplate(
    id: json['id'],
    name: json['name'],
    logType: json['logType'],
    description: json['description'],
    fields: (json['fields'] as List).map((f) => DynamicFormField.fromJson(f)).toList(),
    sections: (json['sections'] as List).map((s) => DynamicFormSection.fromJson(s)).toList(),
    metadata: json['metadata'],
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    version: json['version'] ?? 1,
    active: json['active'] ?? true,
    projectId: json['projectId'],
    supportedTankTypes: json['supportedTankTypes'] != null 
        ? List<String>.from(json['supportedTankTypes']) 
        : null,
    projectOverrides: json['projectOverrides'],
  );

  factory DynamicFormTemplate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DynamicFormTemplate(
      id: doc.id,
      name: data['name'],
      logType: data['logType'],
      description: data['description'],
      fields: (data['fields'] as List).map((f) => DynamicFormField.fromJson(f)).toList(),
      sections: (data['sections'] as List).map((s) => DynamicFormSection.fromJson(s)).toList(),
      metadata: data['metadata'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      version: data['version'] ?? 1,
      active: data['active'] ?? true,
      projectId: data['projectId'],
      supportedTankTypes: data['supportedTankTypes'] != null 
          ? List<String>.from(data['supportedTankTypes']) 
          : null,
      projectOverrides: data['projectOverrides'],
    );
  }
}

/// Firestore collection paths for dynamic form templates
class DynamicFormTemplateCollections {
  static const String templates = 'formTemplates';
  static const String projectTemplates = 'projectFormTemplates';
  static const String templateVersions = 'templateVersions';
}

/// Template metadata keys for consistent usage
class DynamicFormTemplateMetadata {
  static const String clientName = 'clientName';
  static const String location = 'location';
  static const String industry = 'industry';
  static const String equipmentType = 'equipmentType';
  static const String complianceStandards = 'complianceStandards';
  static const String requiredFrequency = 'requiredFrequency';
  static const String autoCalculations = 'autoCalculations';
}