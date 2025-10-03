import 'package:cloud_firestore/cloud_firestore.dart';

enum FieldType {
  text,
  number,
  decimal,
  select,
  checkbox,
  date,
  time,
  temperature,
  pressure,
  percentage,
  ppm,
  flow,
}

enum FieldCategory {
  core,           // Always required (like D&D base stats)
  common,         // Common fields most logs use
  specialized,    // Class-specific (like spell slots for wizards)
  optional,       // Feats/optional features
  calculated,     // Auto-calculated from other fields
}

class FieldValidation {
  final double? min;
  final double? max;
  final String? pattern;
  final int? maxLength;
  final bool required;
  final String? customValidator;

  const FieldValidation({
    this.min,
    this.max,
    this.pattern,
    this.maxLength,
    this.required = false,
    this.customValidator,
  });

  Map<String, dynamic> toJson() => {
    'min': min,
    'max': max,
    'pattern': pattern,
    'maxLength': maxLength,
    'required': required,
    'customValidator': customValidator,
  };

  factory FieldValidation.fromJson(Map<String, dynamic> json) => FieldValidation(
    min: json['min']?.toDouble(),
    max: json['max']?.toDouble(),
    pattern: json['pattern'],
    maxLength: json['maxLength'],
    required: json['required'] ?? false,
    customValidator: json['customValidator'],
  );
}

class TemplateField {
  final String id;
  final String key;           // Database field name
  final String label;         // Display name
  final FieldType type;
  final FieldCategory category;
  final String? unit;
  final String? placeholder;
  final String? helpText;
  final dynamic defaultValue;
  final FieldValidation validation;
  final List<SelectOption>? options;  // For select fields
  final bool showInSummary;
  final int sortOrder;
  final String? dependsOn;    // Field ID this depends on
  final Map<String, dynamic>? dependencyCondition;

  const TemplateField({
    required this.id,
    required this.key,
    required this.label,
    required this.type,
    this.category = FieldCategory.common,
    this.unit,
    this.placeholder,
    this.helpText,
    this.defaultValue,
    this.validation = const FieldValidation(),
    this.options,
    this.showInSummary = false,
    this.sortOrder = 999,
    this.dependsOn,
    this.dependencyCondition,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'key': key,
    'label': label,
    'type': type.toString(),
    'category': category.toString(),
    'unit': unit,
    'placeholder': placeholder,
    'helpText': helpText,
    'defaultValue': defaultValue,
    'validation': validation.toJson(),
    'options': options?.map((o) => o.toJson()).toList(),
    'showInSummary': showInSummary,
    'sortOrder': sortOrder,
    'dependsOn': dependsOn,
    'dependencyCondition': dependencyCondition,
  };

  factory TemplateField.fromJson(Map<String, dynamic> json) => TemplateField(
    id: json['id'],
    key: json['key'],
    label: json['label'],
    type: FieldType.values.firstWhere(
      (e) => e.toString() == json['type'],
      orElse: () => FieldType.text,
    ),
    category: FieldCategory.values.firstWhere(
      (e) => e.toString() == json['category'],
      orElse: () => FieldCategory.common,
    ),
    unit: json['unit'],
    placeholder: json['placeholder'],
    helpText: json['helpText'],
    defaultValue: json['defaultValue'],
    validation: FieldValidation.fromJson(json['validation'] ?? {}),
    options: json['options'] != null
      ? (json['options'] as List).map((o) => SelectOption.fromJson(o)).toList()
      : null,
    showInSummary: json['showInSummary'] ?? false,
    sortOrder: json['sortOrder'] ?? 999,
    dependsOn: json['dependsOn'],
    dependencyCondition: json['dependencyCondition'],
  );
}

class SelectOption {
  final String value;
  final String label;
  final bool isDefault;

  const SelectOption({
    required this.value,
    required this.label,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {
    'value': value,
    'label': label,
    'isDefault': isDefault,
  };

  factory SelectOption.fromJson(Map<String, dynamic> json) => SelectOption(
    value: json['value'],
    label: json['label'],
    isDefault: json['isDefault'] ?? false,
  );
}

class FieldSection {
  final String id;
  final String title;
  final String? description;
  final List<String> fieldIds;  // References to TemplateField IDs
  final bool collapsible;
  final bool defaultExpanded;
  final int sortOrder;

  const FieldSection({
    required this.id,
    required this.title,
    this.description,
    required this.fieldIds,
    this.collapsible = false,
    this.defaultExpanded = true,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'fieldIds': fieldIds,
    'collapsible': collapsible,
    'defaultExpanded': defaultExpanded,
    'sortOrder': sortOrder,
  };

  factory FieldSection.fromJson(Map<String, dynamic> json) => FieldSection(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    fieldIds: List<String>.from(json['fieldIds']),
    collapsible: json['collapsible'] ?? false,
    defaultExpanded: json['defaultExpanded'] ?? true,
    sortOrder: json['sortOrder'] ?? 0,
  );
}

class LogTemplate {
  final String id;
  final String name;
  final String logType;
  final String description;
  final List<TemplateField> fields;
  final List<FieldSection> sections;
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int version;
  final bool active;

  const LogTemplate({
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
  });

  TemplateField? getField(String fieldId) {
    try {
      return fields.firstWhere((f) => f.id == fieldId);
    } catch (e) {
      return null;
    }
  }

  List<TemplateField> getFieldsForSection(String sectionId) {
    final section = sections.firstWhere((s) => s.id == sectionId);
    return section.fieldIds
        .map((id) => getField(id))
        .where((field) => field != null)
        .cast<TemplateField>()
        .toList();
  }

  List<TemplateField> getCoreFields() {
    return fields.where((f) => f.category == FieldCategory.core).toList();
  }

  List<TemplateField> getOptionalFields() {
    return fields.where((f) => f.category == FieldCategory.optional).toList();
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
  };

  factory LogTemplate.fromJson(Map<String, dynamic> json) => LogTemplate(
    id: json['id'],
    name: json['name'],
    logType: json['logType'],
    description: json['description'],
    fields: (json['fields'] as List).map((f) => TemplateField.fromJson(f)).toList(),
    sections: (json['sections'] as List).map((s) => FieldSection.fromJson(s)).toList(),
    metadata: json['metadata'],
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    version: json['version'] ?? 1,
    active: json['active'] ?? true,
  );

  factory LogTemplate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LogTemplate(
      id: doc.id,
      name: data['name'],
      logType: data['logType'],
      description: data['description'],
      fields: (data['fields'] as List).map((f) => TemplateField.fromJson(f)).toList(),
      sections: (data['sections'] as List).map((s) => FieldSection.fromJson(s)).toList(),
      metadata: data['metadata'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      version: data['version'] ?? 1,
      active: data['active'] ?? true,
    );
  }
}