import 'dart:convert';
import 'dart:io';
import '../models/unified_thermal_log_model.dart';

/// Excel mapping validation service
/// Validates that all unified schema fields are properly mapped to Excel columns
class ExcelMappingValidator {
  static const String mappingFilePath = 'lib/models/complete_template_mappings.json';
  static const String schemaFilePath = 'lib/models/thermal_field_definitions.json';

}

/// Validation result structure
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final Map<String, dynamic> statistics;

  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.statistics,
  });
}

/// Excel mapping validator implementation
class ExcelMappingValidatorImpl {
  static const String mappingFilePath = 'lib/models/complete_template_mappings.json';
  static const String schemaFilePath = 'lib/models/thermal_field_definitions.json';

  /// Validate all template mappings
  static Future<ValidationResult> validateAllMappings() async {
    final List<String> errors = [];
    final List<String> warnings = [];
    final Map<String, dynamic> statistics = {
      'totalTemplates': 0,
      'validTemplates': 0,
      'totalFields': 0,
      'mappedFields': 0,
      'unmappedFields': 0,
      'templateCoverage': {},
    };

    try {
      // Load mapping data
      final mappingFile = File(mappingFilePath);
      final schemaFile = File(schemaFilePath);

      if (!mappingFile.existsSync()) {
        errors.add('Mapping file not found: $mappingFilePath');
        return ValidationResult(
          isValid: false,
          errors: errors,
          warnings: warnings,
          statistics: statistics,
        );
      }

      if (!schemaFile.existsSync()) {
        errors.add('Schema file not found: $schemaFilePath');
        return ValidationResult(
          isValid: false,
          errors: errors,
          warnings: warnings,
          statistics: statistics,
        );
      }

      final mappingData = json.decode(await mappingFile.readAsString());
      final schemaData = json.decode(await schemaFile.readAsString());

      // Extract template mappings and schema fields
      final templateMappings = mappingData['allTemplateMappings'] as Map<String, dynamic>;
      final universalFields = schemaData['universalFields'] as List<dynamic>;
      final conditionalFields = schemaData['conditionalFields'] as List<dynamic>;

      statistics['totalTemplates'] = templateMappings.length;

      // Create complete field reference
      final Map<String, dynamic> allSchemaFields = {};
      
      // Add universal fields
      for (final field in universalFields) {
        allSchemaFields[field['id']] = {
          'field': field,
          'type': 'universal',
          'required': field['required'] ?? false,
        };
      }

      // Add conditional fields
      for (final field in conditionalFields) {
        allSchemaFields[field['id']] = {
          'field': field,
          'type': 'conditional',
          'required': field['required'] ?? false,
          'enabledFor': field['conditionalDisplay']?['enabledFor'] ?? [],
        };
      }

      statistics['totalFields'] = allSchemaFields.length;

      // Validate each template
      int validTemplates = 0;
      int totalMappedFields = 0;

      for (final entry in templateMappings.entries) {
        final templateId = entry.key;
        final template = entry.value as Map<String, dynamic>;
        final fieldMappings = template['fieldMappings'] as Map<String, dynamic>? ?? {};

        final templateResult = _validateTemplate(
          templateId,
          template,
          fieldMappings,
          allSchemaFields,
        );

        errors.addAll(templateResult.errors.map((e) => '[$templateId] $e'));
        warnings.addAll(templateResult.warnings.map((w) => '[$templateId] $w'));

        statistics['templateCoverage'][templateId] = {
          'mappedFields': templateResult.mappedFields,
          'totalExpectedFields': templateResult.totalExpectedFields,
          'coverage': templateResult.coverage,
          'isValid': templateResult.isValid,
        };

        if (templateResult.isValid) {
          validTemplates++;
        }

        totalMappedFields += templateResult.mappedFields;
      }

      statistics['validTemplates'] = validTemplates;
      statistics['mappedFields'] = totalMappedFields;
      statistics['unmappedFields'] = statistics['totalFields'] * templateMappings.length - totalMappedFields;

      // Overall validation
      final bool isValid = errors.isEmpty && validTemplates == templateMappings.length;

      return ValidationResult(
        isValid: isValid,
        errors: errors,
        warnings: warnings,
        statistics: statistics,
      );
    } catch (e) {
      errors.add('Validation failed with exception: $e');
      return ValidationResult(
        isValid: false,
        errors: errors,
        warnings: warnings,
        statistics: statistics,
      );
    }
  }

  /// Validate a single template mapping
  static _TemplateValidationResult _validateTemplate(
    String templateId,
    Map<String, dynamic> template,
    Map<String, dynamic> fieldMappings,
    Map<String, dynamic> allSchemaFields,
  ) {
    final List<String> errors = [];
    final List<String> warnings = [];
    int mappedFields = 0;
    int totalExpectedFields = 0;

    // Get template properties
    final List<String> monitoringTypes = 
        (template['monitoringTypes'] as List<dynamic>?)?.cast<String>() ?? [];
    final String capacity = template['capacity'] ?? '';
    final String fuelType = template['fuelType'] ?? '';
    final String? processStage = template['processStage'];

    // Determine which fields should be present for this template
    final Set<String> expectedFields = {};

    // Add universal fields (should be in every template)
    for (final entry in allSchemaFields.entries) {
      final fieldId = entry.key;
      final fieldData = entry.value;
      
      if (fieldData['type'] == 'universal') {
        expectedFields.add(fieldId);
      } else if (fieldData['type'] == 'conditional') {
        final List<String> enabledFor = 
            (fieldData['enabledFor'] as List<dynamic>?)?.cast<String>() ?? [];
        
        // Check if field should be enabled for this template
        if (enabledFor.contains('*') || enabledFor.contains(templateId)) {
          expectedFields.add(fieldId);
        }
      }
    }

    totalExpectedFields = expectedFields.length;

    // Validate each expected field has a mapping
    for (final fieldId in expectedFields) {
      if (fieldMappings.containsKey(fieldId)) {
        final mapping = fieldMappings[fieldId] as Map<String, dynamic>;
        
        // Validate mapping structure
        if (!mapping.containsKey('column')) {
          errors.add('Field $fieldId missing column specification');
        } else {
          mappedFields++;
        }

        if (!mapping.containsKey('header')) {
          warnings.add('Field $fieldId missing header specification');
        }
      } else {
        final fieldData = allSchemaFields[fieldId];
        if (fieldData['required'] == true) {
          errors.add('Required field $fieldId not mapped');
        } else {
          warnings.add('Optional field $fieldId not mapped');
        }
      }
    }

    // Check for unmapped fields in template
    for (final fieldId in fieldMappings.keys) {
      if (!expectedFields.contains(fieldId)) {
        warnings.add('Mapped field $fieldId not expected for this template type');
      }
    }

    // Check column uniqueness
    final Set<String> usedColumns = {};
    for (final mapping in fieldMappings.values) {
      final column = mapping['column'];
      if (usedColumns.contains(column)) {
        errors.add('Duplicate column assignment: $column');
      } else {
        usedColumns.add(column);
      }
    }

    // Calculate coverage
    final double coverage = totalExpectedFields > 0 
        ? (mappedFields / totalExpectedFields) * 100 
        : 0;

    final bool isValid = errors.isEmpty && coverage >= 90; // 90% minimum coverage

    return _TemplateValidationResult(
      templateId: templateId,
      isValid: isValid,
      errors: errors,
      warnings: warnings,
      mappedFields: mappedFields,
      totalExpectedFields: totalExpectedFields,
      coverage: coverage,
    );
  }

  /// Generate validation report
  static String generateValidationReport(ValidationResult result) {
    final buffer = StringBuffer();
    
    buffer.writeln('# Excel Column Mapping Validation Report');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln();

    // Overall status
    buffer.writeln('## Overall Status: ${result.isValid ? "✅ PASSED" : "❌ FAILED"}');
    buffer.writeln();

    // Statistics
    final stats = result.statistics;
    buffer.writeln('## Statistics');
    buffer.writeln('- Total Templates: ${stats['totalTemplates']}');
    buffer.writeln('- Valid Templates: ${stats['validTemplates']}');
    buffer.writeln('- Total Schema Fields: ${stats['totalFields']}');
    buffer.writeln('- Mapped Fields: ${stats['mappedFields']}');
    buffer.writeln('- Unmapped Fields: ${stats['unmappedFields']}');
    buffer.writeln();

    // Template coverage
    if (stats['templateCoverage'] != null) {
      buffer.writeln('## Template Coverage');
      final coverage = stats['templateCoverage'] as Map<String, dynamic>;
      for (final entry in coverage.entries) {
        final templateId = entry.key;
        final templateStats = entry.value as Map<String, dynamic>;
        final coveragePercent = templateStats['coverage'].toStringAsFixed(1);
        final status = templateStats['isValid'] ? '✅' : '❌';
        
        buffer.writeln('- **$templateId** $status: ${templateStats['mappedFields']}/${templateStats['totalExpectedFields']} fields ($coveragePercent%)');
      }
      buffer.writeln();
    }

    // Errors
    if (result.errors.isNotEmpty) {
      buffer.writeln('## ❌ Errors (${result.errors.length})');
      for (final error in result.errors) {
        buffer.writeln('- $error');
      }
      buffer.writeln();
    }

    // Warnings
    if (result.warnings.isNotEmpty) {
      buffer.writeln('## ⚠️ Warnings (${result.warnings.length})');
      for (final warning in result.warnings) {
        buffer.writeln('- $warning');
      }
      buffer.writeln();
    }

    // Recommendations
    buffer.writeln('## Recommendations');
    if (result.isValid) {
      buffer.writeln('- ✅ All mappings are valid and complete');
      buffer.writeln('- Consider reviewing warnings to improve mapping quality');
    } else {
      buffer.writeln('- ❌ Address all errors before proceeding with implementation');
      buffer.writeln('- Review field mappings for failed templates');
      buffer.writeln('- Ensure all required fields are mapped');
    }

    return buffer.toString();
  }
}

/// Internal validation result for single template
class _TemplateValidationResult {
  final String templateId;
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final int mappedFields;
  final int totalExpectedFields;
  final double coverage;

  _TemplateValidationResult({
    required this.templateId,
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.mappedFields,
    required this.totalExpectedFields,
    required this.coverage,
  });
}