import 'package:flutter/foundation.dart';

/// Centralized validation service for all form fields
/// Supports both LogFieldTemplate and DynamicFormField validation
class FormValidationService {
  static final FormValidationService _instance = FormValidationService._internal();
  factory FormValidationService() => _instance;
  FormValidationService._internal();

  /// Custom validators registry
  final Map<String, ValidationFunction> _customValidators = {};

  /// Register a custom validator function
  void registerValidator(String id, ValidationFunction validator) {
    _customValidators[id] = validator;
  }

  /// Core validation method that handles all validation types
  ValidationResult validateField({
    required dynamic value,
    required String fieldLabel,
    required ValidationRules rules,
    String? unit,
    Map<String, dynamic>? allFieldValues,
  }) {
    final errors = <String>[];
    final warnings = <String>[];
    
    // Convert value to string for processing
    final stringValue = value?.toString() ?? '';
    final isEmpty = stringValue.trim().isEmpty;
    
    // Required field validation
    if (rules.required && isEmpty) {
      if (rules.requiredIf != null && allFieldValues != null) {
        // Conditional requirement
        final dependentValue = allFieldValues[rules.requiredIf];
        if (_evaluateCondition(dependentValue, rules.requiredIfValue)) {
          errors.add('$fieldLabel is required when ${rules.requiredIf} is ${rules.requiredIfValue}');
        }
      } else {
        errors.add('$fieldLabel is required');
      }
    }
    
    // Skip further validation if field is empty and not required
    if (isEmpty && !rules.required) {
      return ValidationResult(isValid: true, errors: [], warnings: []);
    }
    
    // Data type validation
    if (!isEmpty) {
      switch (rules.dataType) {
        case ValidationDataType.number:
        case ValidationDataType.decimal:
        case ValidationDataType.temperature:
        case ValidationDataType.pressure:
        case ValidationDataType.percentage:
        case ValidationDataType.ppm:
        case ValidationDataType.flow:
          _validateNumericField(stringValue, fieldLabel, rules, unit, errors, warnings);
          break;
        case ValidationDataType.text:
          _validateTextField(stringValue, fieldLabel, rules, errors, warnings);
          break;
        case ValidationDataType.email:
          _validateEmailField(stringValue, fieldLabel, errors);
          break;
        case ValidationDataType.phone:
          _validatePhoneField(stringValue, fieldLabel, errors);
          break;
        case ValidationDataType.url:
          _validateUrlField(stringValue, fieldLabel, errors);
          break;
        default:
          break;
      }
    }
    
    // Pattern validation
    if (!isEmpty && rules.pattern != null) {
      _validatePattern(stringValue, fieldLabel, rules.pattern!, errors);
    }
    
    // Custom validator
    if (!isEmpty && rules.customValidator != null) {
      _validateCustom(stringValue, fieldLabel, rules.customValidator!, errors, allFieldValues);
    }
    
    // Length validation
    if (!isEmpty) {
      _validateLength(stringValue, fieldLabel, rules, errors);
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
  
  void _validateNumericField(String value, String fieldLabel, ValidationRules rules, String? unit, List<String> errors, List<String> warnings) {
    final numValue = double.tryParse(value);
    if (numValue == null) {
      errors.add('$fieldLabel must be a valid number');
      return;
    }
    
    // Min/max validation
    if (rules.min != null && numValue < rules.min!) {
      errors.add('$fieldLabel minimum value is ${rules.min}${unit != null ? ' $unit' : ''}');
    }
    
    if (rules.max != null && numValue > rules.max!) {
      errors.add('$fieldLabel maximum value is ${rules.max}${unit != null ? ' $unit' : ''}');
    }
    
    // Warning thresholds
    if (rules.warningMin != null && numValue < rules.warningMin!) {
      warnings.add(rules.warningMessage ?? 
          '⚠ $fieldLabel below recommended minimum (${rules.warningMin}${unit != null ? ' $unit' : ''})');
    }
    
    if (rules.warningMax != null && numValue > rules.warningMax!) {
      warnings.add(rules.warningMessage ?? 
          '⚠ $fieldLabel above recommended maximum (${rules.warningMax}${unit != null ? ' $unit' : ''})');
    }
    
    // Special percentage validation
    if (rules.dataType == ValidationDataType.percentage) {
      if (numValue < 0 || numValue > 100) {
        errors.add('$fieldLabel must be between 0 and 100%');
      }
    }
  }
  
  void _validateTextField(String value, String fieldLabel, ValidationRules rules, List<String> errors, List<String> warnings) {
    // Text-specific validations can be added here
    // For now, length validation is handled separately
  }
  
  void _validateEmailField(String value, String fieldLabel, List<String> errors) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      errors.add('$fieldLabel must be a valid email address');
    }
  }
  
  void _validatePhoneField(String value, String fieldLabel, List<String> errors) {
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]+$');
    if (!phoneRegex.hasMatch(value) || value.length < 10) {
      errors.add('$fieldLabel must be a valid phone number');
    }
  }
  
  void _validateUrlField(String value, String fieldLabel, List<String> errors) {
    final urlRegex = RegExp(r'^https?://[^\s/$.?#].[^\s]*$');
    if (!urlRegex.hasMatch(value)) {
      errors.add('$fieldLabel must be a valid URL');
    }
  }
  
  void _validatePattern(String value, String fieldLabel, String pattern, List<String> errors) {
    try {
      final regex = RegExp(pattern);
      if (!regex.hasMatch(value)) {
        errors.add('$fieldLabel format is invalid');
      }
    } catch (e) {
      debugPrint('Invalid regex pattern: $pattern');
      errors.add('$fieldLabel format validation error');
    }
  }
  
  void _validateCustom(String value, String fieldLabel, String validatorId, List<String> errors, Map<String, dynamic>? allFieldValues) {
    final validator = _customValidators[validatorId];
    if (validator != null) {
      final result = validator(value, allFieldValues);
      if (result != null) {
        errors.add(result);
      }
    } else {
      debugPrint('Custom validator not found: $validatorId');
    }
  }
  
  void _validateLength(String value, String fieldLabel, ValidationRules rules, List<String> errors) {
    if (rules.minLength != null && value.length < rules.minLength!) {
      errors.add('$fieldLabel must be at least ${rules.minLength} characters');
    }
    
    if (rules.maxLength != null && value.length > rules.maxLength!) {
      errors.add('$fieldLabel must be no more than ${rules.maxLength} characters');
    }
  }
  
  bool _evaluateCondition(dynamic actualValue, dynamic expectedValue) {
    if (expectedValue is List) {
      return expectedValue.contains(actualValue);
    }
    return actualValue == expectedValue;
  }
  
  /// Validate multiple fields at once
  Map<String, ValidationResult> validateFields(Map<String, FieldValidationInput> fields) {
    final results = <String, ValidationResult>{};
    
    for (final entry in fields.entries) {
      final fieldKey = entry.key;
      final input = entry.value;
      
      results[fieldKey] = validateField(
        value: input.value,
        fieldLabel: input.label,
        rules: input.rules,
        unit: input.unit,
        allFieldValues: fields.map((k, v) => MapEntry(k, v.value)),
      );
    }
    
    return results;
  }
  
  /// Check if all fields in a form are valid
  bool isFormValid(Map<String, ValidationResult> results) {
    return results.values.every((result) => result.isValid);
  }
  
  /// Get all error messages from validation results
  List<String> getAllErrors(Map<String, ValidationResult> results) {
    final errors = <String>[];
    for (final result in results.values) {
      errors.addAll(result.errors);
    }
    return errors;
  }
  
  /// Get all warning messages from validation results
  List<String> getAllWarnings(Map<String, ValidationResult> results) {
    final warnings = <String>[];
    for (final result in results.values) {
      warnings.addAll(result.warnings);
    }
    return warnings;
  }
}

/// Data types supported by the validation engine
enum ValidationDataType {
  text,
  number,
  decimal,
  email,
  phone,
  url,
  date,
  time,
  dateTime,
  temperature,
  pressure,
  percentage,
  ppm,
  flow,
  coordinates,
}

/// Comprehensive validation rules
class ValidationRules {
  final ValidationDataType dataType;
  final bool required;
  final double? min;
  final double? max;
  final int? minLength;
  final int? maxLength;
  final String? pattern;
  final String? customValidator;
  
  // Warning thresholds
  final double? warningMin;
  final double? warningMax;
  final String? warningMessage;
  
  // Conditional validation
  final String? requiredIf;
  final dynamic requiredIfValue;
  
  const ValidationRules({
    this.dataType = ValidationDataType.text,
    this.required = false,
    this.min,
    this.max,
    this.minLength,
    this.maxLength,
    this.pattern,
    this.customValidator,
    this.warningMin,
    this.warningMax,
    this.warningMessage,
    this.requiredIf,
    this.requiredIfValue,
  });
  
  /// Create ValidationRules from DynamicFieldValidation
  factory ValidationRules.fromDynamicValidation(dynamic validation, ValidationDataType dataType) {
    return ValidationRules(
      dataType: dataType,
      required: validation.required ?? false,
      min: validation.min,
      max: validation.max,
      minLength: validation.minLength,
      maxLength: validation.maxLength,
      pattern: validation.pattern,
      customValidator: validation.customValidator,
      warningMin: validation.warningMin,
      warningMax: validation.warningMax,
      warningMessage: validation.warningMessage,
      requiredIf: validation.requiredIf,
      requiredIfValue: validation.requiredIfValue,
    );
  }
  
  /// Create ValidationRules from FieldValidationRule
  factory ValidationRules.fromFieldValidation(dynamic validation, ValidationDataType dataType) {
    return ValidationRules(
      dataType: dataType,
      required: validation.required ?? false,
      min: validation.min,
      max: validation.max,
      pattern: validation.pattern,
      warningMin: validation.warningMin,
      warningMax: validation.warningMax,
      warningMessage: validation.warningMessage,
    );
  }
}

/// Input for field validation
class FieldValidationInput {
  final dynamic value;
  final String label;
  final ValidationRules rules;
  final String? unit;
  
  const FieldValidationInput({
    required this.value,
    required this.label,
    required this.rules,
    this.unit,
  });
}

/// Result of field validation
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  
  const ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });
  
  /// Check if field has any issues (errors or warnings)
  bool get hasIssues => errors.isNotEmpty || warnings.isNotEmpty;
  
  /// Get the first error message (for display in UI)
  String? get firstError => errors.isNotEmpty ? errors.first : null;
  
  /// Get the first warning message (for display in UI)
  String? get firstWarning => warnings.isNotEmpty ? warnings.first : null;
  
  @override
  String toString() => 'ValidationResult(isValid: $isValid, errors: $errors, warnings: $warnings)';
}

/// Custom validation function type
typedef ValidationFunction = String? Function(String value, Map<String, dynamic>? allFieldValues);

/// Pre-built custom validators
class CustomValidators {
  /// Register all built-in custom validators
  static void registerBuiltInValidators() {
    final service = FormValidationService();
    
    // Temperature range validator
    service.registerValidator('temperature_range', (value, allFields) {
      final temp = double.tryParse(value);
      if (temp == null) return null;
      
      if (temp < -50 || temp > 2000) {
        return 'Temperature must be between -50°F and 2000°F';
      }
      return null;
    });
    
    // PPM safety validator
    service.registerValidator('ppm_safety', (value, allFields) {
      final ppm = double.tryParse(value);
      if (ppm == null) return null;
      
      if (ppm > 10000) {
        return 'PPM reading above safety threshold (10,000)';
      }
      return null;
    });
    
    // Flow rate consistency validator
    service.registerValidator('flow_consistency', (value, allFields) {
      final flow = double.tryParse(value);
      if (flow == null || allFields == null) return null;
      
      // Example: Check if vapor inlet flow matches expectations
      final inletPPM = double.tryParse(allFields['inletReading']?.toString() ?? '');
      if (inletPPM != null && flow > 0 && inletPPM == 0) {
        return 'Flow detected but no inlet reading - check equipment';
      }
      return null;
    });
    
    // Marathon GBR specific validators
    service.registerValidator('marathon_lel', (value, allFields) {
      final lel = double.tryParse(value);
      if (lel == null) return null;
      
      if (lel > 25) {
        return 'LEL reading above Marathon safety limit (25%)';
      }
      return null;
    });
  }
}