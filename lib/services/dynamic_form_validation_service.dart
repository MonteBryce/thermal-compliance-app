import 'package:flutter/foundation.dart';
import '../models/dynamic_form_schema.dart';
import '../models/firestore_models.dart';

/// Service for handling advanced validation logic for dynamic forms
/// Supports custom validators, cross-field validation, and thermal-specific rules
class DynamicFormValidationService {
  
  /// Validate entire form with cross-field validation
  static FormValidationResult validateForm({
    required DynamicFormTemplate template,
    required Map<String, dynamic> formValues,
    ProjectDocument? project,
  }) {
    final errors = <String, String>{};
    final warnings = <String, String>{};
    final fieldResults = <String, FieldValidationResult>{};
    
    // Validate individual fields
    for (final field in template.fields) {
      final value = formValues[field.key];
      final result = validateField(field, value, formValues, project);
      
      fieldResults[field.key] = result;
      
      if (result.error != null) {
        errors[field.key] = result.error!;
      }
      
      if (result.warning != null) {
        warnings[field.key] = result.warning!;
      }
    }
    
    // Perform cross-field validation
    final crossFieldResults = _performCrossFieldValidation(
      template, formValues, project
    );
    
    errors.addAll(crossFieldResults.errors);
    warnings.addAll(crossFieldResults.warnings);
    
    // Perform thermal-specific validations
    final thermalResults = _performThermalValidations(
      template, formValues, project
    );
    
    errors.addAll(thermalResults.errors);
    warnings.addAll(thermalResults.warnings);
    
    return FormValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      fieldResults: fieldResults,
    );
  }
  
  /// Validate individual field
  static FieldValidationResult validateField(
    DynamicFormField field,
    dynamic value,
    Map<String, dynamic> formValues,
    ProjectDocument? project,
  ) {
    String? error;
    String? warning;
    
    // Basic validation
    error = _validateBasicRules(field, value);
    if (error != null) {
      return FieldValidationResult(error: error);
    }
    
    // Warning checks
    warning = _checkWarnings(field, value);
    
    // Conditional validation
    if (!_shouldValidateField(field, formValues)) {
      return FieldValidationResult(); // Skip validation if field is hidden
    }
    
    // Custom validation
    if (field.validation.customValidator != null) {
      final customResult = _performCustomValidation(
        field.validation.customValidator!,
        field,
        value,
        formValues,
        project,
      );
      
      error = customResult.error ?? error;
      warning = customResult.warning ?? warning;
    }
    
    // Project-specific validation
    if (project != null) {
      final projectResult = _performProjectSpecificValidation(
        field, value, project, formValues
      );
      
      error = projectResult.error ?? error;
      warning = projectResult.warning ?? warning;
    }
    
    return FieldValidationResult(
      error: error,
      warning: warning,
    );
  }
  
  /// Basic field validation rules
  static String? _validateBasicRules(DynamicFormField field, dynamic value) {
    final validation = field.validation;
    
    // Required field check
    if (validation.required && _isEmpty(value)) {
      return '${field.label} is required';
    }
    
    // Skip further validation if field is empty
    if (_isEmpty(value)) return null;
    
    // Type-specific validation
    switch (field.type) {
      case DynamicFieldType.number:
      case DynamicFieldType.decimal:
      case DynamicFieldType.temperature:
      case DynamicFieldType.pressure:
      case DynamicFieldType.percentage:
      case DynamicFieldType.ppm:
      case DynamicFieldType.flow:
        return _validateNumericField(field, value);
      
      case DynamicFieldType.text:
        return _validateTextField(field, value);
        
      case DynamicFieldType.select:
        return _validateSelectField(field, value);
        
      case DynamicFieldType.date:
      case DynamicFieldType.time:
      case DynamicFieldType.dateTime:
        return _validateDateTimeField(field, value);
        
      default:
        return null;
    }
  }
  
  /// Validate numeric fields
  static String? _validateNumericField(DynamicFormField field, dynamic value) {
    final numValue = _parseNumber(value);
    if (numValue == null) {
      return 'Please enter a valid number';
    }
    
    final validation = field.validation;
    
    if (validation.min != null && numValue < validation.min!) {
      return 'Minimum value is ${validation.min}${_getUnitSuffix(field)}';
    }
    
    if (validation.max != null && numValue > validation.max!) {
      return 'Maximum value is ${validation.max}${_getUnitSuffix(field)}';
    }
    
    // Percentage specific validation
    if (field.type == DynamicFieldType.percentage) {
      if (numValue < 0 || numValue > 100) {
        return 'Percentage must be between 0 and 100';
      }
    }
    
    return null;
  }
  
  /// Validate text fields
  static String? _validateTextField(DynamicFormField field, dynamic value) {
    final text = value?.toString() ?? '';
    final validation = field.validation;
    
    if (validation.minLength != null && text.length < validation.minLength!) {
      return 'Minimum ${validation.minLength} characters required';
    }
    
    if (validation.maxLength != null && text.length > validation.maxLength!) {
      return 'Maximum ${validation.maxLength} characters allowed';
    }
    
    if (validation.pattern != null) {
      final regex = RegExp(validation.pattern!);
      if (!regex.hasMatch(text)) {
        return 'Invalid format';
      }
    }
    
    return null;
  }
  
  /// Validate select fields
  static String? _validateSelectField(DynamicFormField field, dynamic value) {
    if (field.options == null || field.options!.isEmpty) {
      return null;
    }
    
    final validOptions = field.options!.map((o) => o.value).toList();
    if (!validOptions.contains(value)) {
      return 'Please select a valid option';
    }
    
    return null;
  }
  
  /// Validate date/time fields
  static String? _validateDateTimeField(DynamicFormField field, dynamic value) {
    if (value is DateTime) return null;
    
    if (value is String) {
      try {
        DateTime.parse(value);
        return null;
      } catch (e) {
        return 'Please enter a valid date/time';
      }
    }
    
    return 'Invalid date/time format';
  }
  
  /// Check for warning conditions
  static String? _checkWarnings(DynamicFormField field, dynamic value) {
    if (_isEmpty(value)) return null;
    
    final validation = field.validation;
    
    // Numeric warnings
    if (_isNumericType(field.type)) {
      final numValue = _parseNumber(value);
      if (numValue != null) {
        if (validation.warningMin != null && numValue < validation.warningMin!) {
          return validation.warningMessage ?? 
              '⚠ Below recommended minimum (${validation.warningMin}${_getUnitSuffix(field)})';
        }
        
        if (validation.warningMax != null && numValue > validation.warningMax!) {
          return validation.warningMessage ?? 
              '⚠ Above recommended maximum (${validation.warningMax}${_getUnitSuffix(field)})';
        }
      }
    }
    
    return null;
  }
  
  /// Check if field should be validated based on conditions
  static bool _shouldValidateField(
    DynamicFormField field,
    Map<String, dynamic> formValues,
  ) {
    if (field.conditions == null) return true;
    
    for (final condition in field.conditions!) {
      if (condition.action == 'hide' || condition.action == 'disable') {
        final dependentValue = formValues[condition.dependsOnField];
        if (_evaluateCondition(condition, dependentValue)) {
          return false; // Field should be hidden/disabled, skip validation
        }
      }
    }
    
    return true;
  }
  
  /// Perform custom validation
  static FieldValidationResult _performCustomValidation(
    String validatorId,
    DynamicFormField field,
    dynamic value,
    Map<String, dynamic> formValues,
    ProjectDocument? project,
  ) {
    switch (validatorId) {
      case 'thermal_efficiency_check':
        return _validateThermalEfficiency(field, value, formValues);
      
      case 'h2s_safety_check':
        return _validateH2SSafety(field, value, formValues, project);
      
      case 'lel_threshold_check':
        return _validateLELThreshold(field, value, formValues, project);
      
      case 'temperature_range_check':
        return _validateTemperatureRange(field, value, formValues, project);
      
      case 'flow_rate_consistency':
        return _validateFlowRateConsistency(field, value, formValues);
      
      default:
        debugPrint('Unknown custom validator: $validatorId');
        return FieldValidationResult();
    }
  }
  
  /// Perform project-specific validation
  static FieldValidationResult _performProjectSpecificValidation(
    DynamicFormField field,
    dynamic value,
    ProjectDocument project,
    Map<String, dynamic> formValues,
  ) {
    String? warning;
    
    // Tank type specific validations
    switch (project.tankType.toLowerCase()) {
      case 'thermal':
      case 'thermal oxidation':
        if (field.key == 'exhaustTemperature') {
          final temp = _parseNumber(value);
          if (temp != null && temp < 1200) {
            warning = '⚠ Below typical thermal oxidation range (>1200°F)';
          }
        }
        break;
        
      case 'ifr':
      case 'internal floating roof':
        if (field.key == 'exhaustTemperature') {
          final temp = _parseNumber(value);
          if (temp != null && (temp < 200 || temp > 400)) {
            warning = '⚠ Outside typical IFR operating range (200-400°F)';
          }
        }
        break;
    }
    
    // Product specific validations
    if (project.product.toLowerCase() == 'sour water') {
      if (field.key == 'toInletReadingH2S') {
        final h2s = _parseNumber(value);
        if (h2s != null && h2s > 100) {
          warning = '⚠ High H2S levels for sour water processing';
        }
      }
    }
    
    return FieldValidationResult(warning: warning);
  }
  
  /// Perform cross-field validation
  static CrossFieldValidationResult _performCrossFieldValidation(
    DynamicFormTemplate template,
    Map<String, dynamic> formValues,
    ProjectDocument? project,
  ) {
    final errors = <String, String>{};
    final warnings = <String, String>{};
    
    // Inlet vs Outlet validation
    final inlet = _parseNumber(formValues['inletReading']);
    final outlet = _parseNumber(formValues['outletReading']);
    
    if (inlet != null && outlet != null) {
      if (outlet > inlet) {
        warnings['outletReading'] = '⚠ Outlet reading higher than inlet - check system efficiency';
      }
      
      // Calculate destruction efficiency if thermal system
      if (template.logType.contains('thermal')) {
        final efficiency = inlet > 0 ? ((inlet - outlet) / inlet) * 100 : 0;
        if (efficiency < 98) {
          warnings['outletReading'] = '⚠ Destruction efficiency below 98% (${efficiency.toStringAsFixed(1)}%)';
        }
      }
    }
    
    // Temperature vs H2S safety check
    final temp = _parseNumber(formValues['exhaustTemperature']);
    final h2s = _parseNumber(formValues['toInletReadingH2S']);
    
    if (temp != null && h2s != null) {
      if (h2s > 50 && temp < 800) {
        warnings['exhaustTemperature'] = '⚠ Consider higher temperature for H2S destruction';
      }
    }
    
    // LEL vs VOC consistency
    final lel = _parseNumber(formValues['lelInletReading']);
    final voc = _parseNumber(formValues['vaporInletVOCPpm']);
    
    if (lel != null && voc != null) {
      if (lel > 5 && voc < 1000) {
        warnings['vaporInletVOCPpm'] = '⚠ LEL reading suggests higher VOC concentration expected';
      }
    }
    
    return CrossFieldValidationResult(errors: errors, warnings: warnings);
  }
  
  /// Perform thermal-specific validations
  static CrossFieldValidationResult _performThermalValidations(
    DynamicFormTemplate template,
    Map<String, dynamic> formValues,
    ProjectDocument? project,
  ) {
    final errors = <String, String>{};
    final warnings = <String, String>{};
    
    if (!template.logType.contains('thermal')) {
      return CrossFieldValidationResult(errors: errors, warnings: warnings);
    }
    
    // Combustion air vs vapor flow validation
    final airFlow = _parseNumber(formValues['combustionAirFlowRate']);
    final vaporFlow = _parseNumber(formValues['vaporInletFlowRateFpm']);
    
    if (airFlow != null && vaporFlow != null) {
      final ratio = airFlow / vaporFlow;
      if (ratio < 10) {
        warnings['combustionAirFlowRate'] = '⚠ Air to vapor ratio may be insufficient for complete combustion';
      }
    }
    
    // Vacuum check for thermal systems
    final vacuum = _parseNumber(formValues['vacuumAtTankVaporOutlet']);
    if (vacuum != null && vacuum < 2) {
      errors['vacuumAtTankVaporOutlet'] = 'Vacuum must be at least 2 Inch H₂O for proper operation';
    }
    
    return CrossFieldValidationResult(errors: errors, warnings: warnings);
  }
  
  // Custom validator implementations
  
  static FieldValidationResult _validateThermalEfficiency(
    DynamicFormField field,
    dynamic value,
    Map<String, dynamic> formValues,
  ) {
    if (field.key != 'outletReading') return FieldValidationResult();
    
    final inlet = _parseNumber(formValues['inletReading']);
    final outlet = _parseNumber(value);
    
    if (inlet != null && outlet != null && inlet > 0) {
      final efficiency = ((inlet - outlet) / inlet) * 100;
      if (efficiency < 95) {
        return FieldValidationResult(
          warning: '⚠ Thermal efficiency ${efficiency.toStringAsFixed(1)}% - consider system maintenance',
        );
      }
    }
    
    return FieldValidationResult();
  }
  
  static FieldValidationResult _validateH2SSafety(
    DynamicFormField field,
    dynamic value,
    Map<String, dynamic> formValues,
    ProjectDocument? project,
  ) {
    final h2s = _parseNumber(value);
    if (h2s == null) return FieldValidationResult();
    
    String? warning;
    String? error;
    
    if (h2s > 100) {
      error = 'H2S levels exceed safe operating limits (100 PPM)';
    } else if (h2s > 50) {
      warning = '⚠ H2S approaching safety threshold - monitor closely';
    }
    
    // Project-specific H2S checks
    if (project?.h2sAmpRequired == true && h2s > 10) {
      warning = '⚠ H2S amplifier required - levels above project threshold';
    }
    
    return FieldValidationResult(error: error, warning: warning);
  }
  
  static FieldValidationResult _validateLELThreshold(
    DynamicFormField field,
    dynamic value,
    Map<String, dynamic> formValues,
    ProjectDocument? project,
  ) {
    final lel = _parseNumber(value);
    if (lel == null) return FieldValidationResult();
    
    String? warning;
    String? error;
    
    if (lel > 25) {
      error = 'LEL exceeds safety limit (25%) - immediate action required';
    } else if (lel > 10) {
      warning = '⚠ LEL above typical operational range - monitor system';
    }
    
    // Project-specific LEL targets
    if (project?.facilityTarget.contains('LEL') == true) {
      final targetMatch = RegExp(r'(\d+)%?\s*LEL').firstMatch(project!.facilityTarget);
      if (targetMatch != null) {
        final target = double.tryParse(targetMatch.group(1) ?? '');
        if (target != null && lel > target) {
          warning = '⚠ Above project LEL target (${target.toInt()}%)';
        }
      }
    }
    
    return FieldValidationResult(error: error, warning: warning);
  }
  
  static FieldValidationResult _validateTemperatureRange(
    DynamicFormField field,
    dynamic value,
    Map<String, dynamic> formValues,
    ProjectDocument? project,
  ) {
    final temp = _parseNumber(value);
    if (temp == null) return FieldValidationResult();
    
    String? warning;
    
    // Project-specific temperature validation
    if (project?.operatingTemperature.isNotEmpty == true) {
      final operatingTemp = project!.operatingTemperature;
      
      if (operatingTemp.contains('>')) {
        final minTempMatch = RegExp(r'>(\d+)').firstMatch(operatingTemp);
        if (minTempMatch != null) {
          final minTemp = double.tryParse(minTempMatch.group(1) ?? '');
          if (minTemp != null && temp < minTemp) {
            warning = '⚠ Below project operating temperature target (>${minTemp.toInt()}°F)';
          }
        }
      } else if (operatingTemp.contains('-')) {
        final rangeMatch = RegExp(r'(\d+)-(\d+)').firstMatch(operatingTemp);
        if (rangeMatch != null) {
          final minTemp = double.tryParse(rangeMatch.group(1) ?? '');
          final maxTemp = double.tryParse(rangeMatch.group(2) ?? '');
          if (minTemp != null && maxTemp != null) {
            if (temp < minTemp || temp > maxTemp) {
              warning = '⚠ Outside project operating range ($operatingTemp)';
            }
          }
        }
      }
    }
    
    return FieldValidationResult(warning: warning);
  }
  
  static FieldValidationResult _validateFlowRateConsistency(
    DynamicFormField field,
    dynamic value,
    Map<String, dynamic> formValues,
  ) {
    // Implementation for flow rate consistency checks
    return FieldValidationResult();
  }
  
  // Utility methods
  
  static bool _isEmpty(dynamic value) {
    return value == null || value.toString().trim().isEmpty;
  }
  
  static double? _parseNumber(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
  
  static bool _isNumericType(DynamicFieldType type) {
    return [
      DynamicFieldType.number,
      DynamicFieldType.decimal,
      DynamicFieldType.temperature,
      DynamicFieldType.pressure,
      DynamicFieldType.percentage,
      DynamicFieldType.ppm,
      DynamicFieldType.flow,
    ].contains(type);
  }
  
  static String _getUnitSuffix(DynamicFormField field) {
    return field.unit != null ? ' ${field.unit}' : '';
  }
  
  static bool _evaluateCondition(DynamicFieldCondition condition, dynamic actualValue) {
    switch (condition.operator) {
      case 'eq':
        return actualValue == condition.value;
      case 'ne':
        return actualValue != condition.value;
      case 'gt':
        return (actualValue is num) && actualValue > condition.value;
      case 'lt':
        return (actualValue is num) && actualValue < condition.value;
      case 'gte':
        return (actualValue is num) && actualValue >= condition.value;
      case 'lte':
        return (actualValue is num) && actualValue <= condition.value;
      case 'in':
        return (condition.value is List) && condition.value.contains(actualValue);
      case 'contains':
        return actualValue?.toString().contains(condition.value.toString()) ?? false;
      default:
        return true;
    }
  }
}

/// Result of field validation
class FieldValidationResult {
  final String? error;
  final String? warning;
  
  const FieldValidationResult({
    this.error,
    this.warning,
  });
  
  bool get isValid => error == null;
  bool get hasWarning => warning != null;
}

/// Result of form validation
class FormValidationResult {
  final bool isValid;
  final Map<String, String> errors;
  final Map<String, String> warnings;
  final Map<String, FieldValidationResult> fieldResults;
  
  const FormValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.fieldResults,
  });
  
  bool get hasWarnings => warnings.isNotEmpty;
  int get errorCount => errors.length;
  int get warningCount => warnings.length;
}

/// Result of cross-field validation
class CrossFieldValidationResult {
  final Map<String, String> errors;
  final Map<String, String> warnings;
  
  const CrossFieldValidationResult({
    required this.errors,
    required this.warnings,
  });
}