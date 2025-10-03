import '../services/form_validation_service.dart';
import '../models/dynamic_form_schema.dart';
import '../models/log_template.dart';

/// Utility functions to integrate the validation service with existing form systems
class ValidationUtils {
  static final _service = FormValidationService();
  
  /// Convert DynamicFieldType to ValidationDataType
  static ValidationDataType _mapDynamicFieldType(DynamicFieldType type) {
    switch (type) {
      case DynamicFieldType.text:
        return ValidationDataType.text;
      case DynamicFieldType.number:
        return ValidationDataType.number;
      case DynamicFieldType.decimal:
        return ValidationDataType.decimal;
      case DynamicFieldType.temperature:
        return ValidationDataType.temperature;
      case DynamicFieldType.pressure:
        return ValidationDataType.pressure;
      case DynamicFieldType.percentage:
        return ValidationDataType.percentage;
      case DynamicFieldType.ppm:
        return ValidationDataType.ppm;
      case DynamicFieldType.flow:
        return ValidationDataType.flow;
      case DynamicFieldType.date:
        return ValidationDataType.date;
      case DynamicFieldType.time:
        return ValidationDataType.time;
      case DynamicFieldType.dateTime:
        return ValidationDataType.dateTime;
      case DynamicFieldType.coordinates:
        return ValidationDataType.coordinates;
      default:
        return ValidationDataType.text;
    }
  }
  
  /// Convert FieldType to ValidationDataType
  static ValidationDataType _mapFieldType(FieldType type) {
    switch (type) {
      case FieldType.number:
        return ValidationDataType.number;
      case FieldType.text:
        return ValidationDataType.text;
      case FieldType.dateTime:
        return ValidationDataType.dateTime;
      default:
        return ValidationDataType.text;
    }
  }
  
  /// Validate a DynamicFormField using the centralized service
  static ValidationResult validateDynamicField({
    required DynamicFormField field,
    required dynamic value,
    Map<String, dynamic>? allFieldValues,
  }) {
    final dataType = _mapDynamicFieldType(field.type);
    final rules = ValidationRules.fromDynamicValidation(field.validation, dataType);
    
    return _service.validateField(
      value: value,
      fieldLabel: field.label,
      rules: rules,
      unit: field.unit,
      allFieldValues: allFieldValues,
    );
  }
  
  /// Validate a LogFieldTemplate using the centralized service
  static ValidationResult validateLogField({
    required LogFieldTemplate field,
    required dynamic value,
    Map<String, dynamic>? allFieldValues,
  }) {
    final dataType = _mapFieldType(field.type);
    final rules = ValidationRules.fromFieldValidation(field.validation, dataType);
    
    return _service.validateField(
      value: value,
      fieldLabel: field.label,
      rules: rules,
      unit: field.unit,
      allFieldValues: allFieldValues,
    );
  }
  
  /// Create a Flutter validator function for DynamicFormField
  static String? Function(String?) createDynamicFieldValidator(
    DynamicFormField field,
    Map<String, dynamic>? allFieldValues,
  ) {
    return (String? value) {
      final result = validateDynamicField(
        field: field,
        value: value,
        allFieldValues: allFieldValues,
      );
      return result.firstError;
    };
  }
  
  /// Create a Flutter validator function for LogFieldTemplate
  static String? Function(String?) createLogFieldValidator(
    LogFieldTemplate field,
    Map<String, dynamic>? allFieldValues,
  ) {
    return (String? value) {
      final result = validateLogField(
        field: field,
        value: value,
        allFieldValues: allFieldValues,
      );
      return result.firstError;
    };
  }
  
  /// Get warning message for a field (used for non-blocking warnings)
  static String? getFieldWarning({
    required dynamic field,
    required dynamic value,
    Map<String, dynamic>? allFieldValues,
  }) {
    ValidationResult result;
    
    if (field is DynamicFormField) {
      result = validateDynamicField(
        field: field,
        value: value,
        allFieldValues: allFieldValues,
      );
    } else if (field is LogFieldTemplate) {
      result = validateLogField(
        field: field,
        value: value,
        allFieldValues: allFieldValues,
      );
    } else {
      return null;
    }
    
    return result.firstWarning;
  }
  
  /// Validate an entire form and return field-specific results
  static Map<String, ValidationResult> validateForm({
    required List<dynamic> fields,
    required Map<String, dynamic> formValues,
  }) {
    final results = <String, ValidationResult>{};
    
    for (final field in fields) {
      String fieldKey;
      ValidationResult result;
      
      if (field is DynamicFormField) {
        fieldKey = field.key;
        result = validateDynamicField(
          field: field,
          value: formValues[fieldKey],
          allFieldValues: formValues,
        );
      } else if (field is LogFieldTemplate) {
        fieldKey = field.id;
        result = validateLogField(
          field: field,
          value: formValues[fieldKey],
          allFieldValues: formValues,
        );
      } else {
        continue;
      }
      
      results[fieldKey] = result;
    }
    
    return results;
  }
  
  /// Check if a form is valid (no errors in any field)
  static bool isFormValid(Map<String, ValidationResult> results) {
    return _service.isFormValid(results);
  }
  
  /// Get all error messages from a form validation
  static List<String> getFormErrors(Map<String, ValidationResult> results) {
    return _service.getAllErrors(results);
  }
  
  /// Get all warning messages from a form validation
  static List<String> getFormWarnings(Map<String, ValidationResult> results) {
    return _service.getAllWarnings(results);
  }
  
  /// Register custom validators for thermal logging
  static void registerThermalValidators() {
    CustomValidators.registerBuiltInValidators();
    
    final service = FormValidationService();
    
    // Additional thermal-specific validators
    service.registerValidator('thermal_efficiency', (value, allFields) {
      final temp = double.tryParse(value);
      if (temp == null || allFields == null) return null;
      
      final inlet = double.tryParse(allFields['inletReading']?.toString() ?? '');
      final outlet = double.tryParse(allFields['outletReading']?.toString() ?? '');
      
      if (inlet != null && outlet != null && outlet > inlet) {
        return 'Outlet reading cannot exceed inlet reading';
      }
      return null;
    });
    
    service.registerValidator('vacuum_check', (value, allFields) {
      final vacuum = double.tryParse(value);
      if (vacuum == null) return null;
      
      if (vacuum < 2.0) {
        return 'Vacuum below minimum requirement (2 Inch H₂O)';
      }
      return null;
    });
  }
  
  /// Initialize validation system
  static void initialize() {
    registerThermalValidators();
  }
}

/// Extension methods for easier validation integration
extension DynamicFormFieldValidation on DynamicFormField {
  /// Validate this field with a given value
  ValidationResult validate(dynamic value, [Map<String, dynamic>? allValues]) {
    return ValidationUtils.validateDynamicField(
      field: this,
      value: value,
      allFieldValues: allValues,
    );
  }
  
  /// Get a Flutter validator function for this field
  String? Function(String?) getValidator([Map<String, dynamic>? allValues]) {
    return ValidationUtils.createDynamicFieldValidator(this, allValues);
  }
  
  /// Get warning message for this field
  String? getWarning(dynamic value, [Map<String, dynamic>? allValues]) {
    return ValidationUtils.getFieldWarning(
      field: this,
      value: value,
      allFieldValues: allValues,
    );
  }
}

extension LogFieldTemplateValidation on LogFieldTemplate {
  /// Validate this field with a given value
  ValidationResult validate(dynamic value, [Map<String, dynamic>? allValues]) {
    return ValidationUtils.validateLogField(
      field: this,
      value: value,
      allFieldValues: allValues,
    );
  }
  
  /// Get a Flutter validator function for this field
  String? Function(String?) getValidator([Map<String, dynamic>? allValues]) {
    return ValidationUtils.createLogFieldValidator(this, allValues);
  }
  
  /// Get warning message for this field
  String? getWarning(dynamic value, [Map<String, dynamic>? allValues]) {
    return ValidationUtils.getFieldWarning(
      field: this,
      value: value,
      allFieldValues: allValues,
    );
  }
}