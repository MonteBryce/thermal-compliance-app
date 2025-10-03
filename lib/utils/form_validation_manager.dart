import 'package:flutter/foundation.dart';
import '../services/form_validation_service.dart';
import '../utils/validation_utils.dart';
import '../models/dynamic_form_schema.dart';

/// Manages form-level validation state and submission prevention
class FormValidationManager {
  final List<dynamic> _fields;
  final Map<String, dynamic> _formValues;
  final Map<String, ValidationResult> _validationResults = {};
  final List<FormValidationListener> _listeners = [];
  
  FormValidationManager({
    required List<dynamic> fields,
    required Map<String, dynamic> formValues,
  }) : _fields = fields, _formValues = formValues;
  
  /// Add a listener for validation state changes
  void addListener(FormValidationListener listener) {
    _listeners.add(listener);
  }
  
  /// Remove a listener
  void removeListener(FormValidationListener listener) {
    _listeners.remove(listener);
  }
  
  /// Notify all listeners of validation state changes
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener.onValidationStateChanged(_validationResults);
    }
  }
  
  /// Validate a specific field
  ValidationResult validateField(String fieldKey, dynamic value) {
    final field = _getField(fieldKey);
    if (field == null) {
      return const ValidationResult(isValid: true, errors: [], warnings: []);
    }
    
    ValidationResult result;
    if (field is DynamicFormField) {
      result = ValidationUtils.validateDynamicField(
        field: field,
        value: value,
        allFieldValues: _formValues,
      );
    } else {
      result = ValidationUtils.validateLogField(
        field: field,
        value: value,
        allFieldValues: _formValues,
      );
    }
    
    _validationResults[fieldKey] = result;
    _notifyListeners();
    return result;
  }
  
  /// Validate all fields in the form
  Map<String, ValidationResult> validateAllFields() {
    _validationResults.clear();
    
    for (final field in _fields) {
      String fieldKey;
      dynamic value;
      
      if (field is DynamicFormField) {
        fieldKey = field.key;
      } else {
        fieldKey = field.id;
      }
      
      value = _formValues[fieldKey];
      validateField(fieldKey, value);
    }
    
    return Map.from(_validationResults);
  }
  
  /// Check if the entire form is valid (no errors)
  bool get isFormValid {
    return _validationResults.values.every((result) => result.isValid);
  }
  
  /// Check if the form has any validation errors
  bool get hasErrors {
    return _validationResults.values.any((result) => !result.isValid);
  }
  
  /// Check if the form has any warnings
  bool get hasWarnings {
    return _validationResults.values.any((result) => result.warnings.isNotEmpty);
  }
  
  /// Get all error messages from the form
  List<String> get allErrors {
    final errors = <String>[];
    for (final result in _validationResults.values) {
      errors.addAll(result.errors);
    }
    return errors;
  }
  
  /// Get all warning messages from the form
  List<String> get allWarnings {
    final warnings = <String>[];
    for (final result in _validationResults.values) {
      warnings.addAll(result.warnings);
    }
    return warnings;
  }
  
  /// Get validation result for a specific field
  ValidationResult? getFieldValidation(String fieldKey) {
    return _validationResults[fieldKey];
  }
  
  /// Get all fields with errors
  List<String> get fieldsWithErrors {
    return _validationResults.entries
        .where((entry) => !entry.value.isValid)
        .map((entry) => entry.key)
        .toList();
  }
  
  /// Get all fields with warnings
  List<String> get fieldsWithWarnings {
    return _validationResults.entries
        .where((entry) => entry.value.warnings.isNotEmpty)
        .map((entry) => entry.key)
        .toList();
  }
  
  /// Clear validation results
  void clearValidation() {
    _validationResults.clear();
    _notifyListeners();
  }
  
  /// Update form values and revalidate
  void updateFormValues(Map<String, dynamic> newValues) {
    _formValues.clear();
    _formValues.addAll(newValues);
    validateAllFields();
  }
  
  /// Update a single field value and validate
  void updateFieldValue(String fieldKey, dynamic value) {
    _formValues[fieldKey] = value;
    validateField(fieldKey, value);
  }
  
  /// Check if form can be submitted
  FormSubmissionState checkSubmissionState() {
    validateAllFields();
    
    if (hasErrors) {
      return FormSubmissionState.blocked;
    } else if (hasWarnings) {
      return FormSubmissionState.warningButAllowed;
    } else {
      return FormSubmissionState.allowed;
    }
  }
  
  /// Attempt to submit the form
  FormSubmissionResult attemptSubmit({
    bool allowSubmissionWithWarnings = true,
  }) {
    final submissionState = checkSubmissionState();
    
    switch (submissionState) {
      case FormSubmissionState.blocked:
        return FormSubmissionResult(
          success: false,
          message: 'Form has validation errors that must be fixed',
          errors: allErrors,
          warnings: allWarnings,
        );
      case FormSubmissionState.warningButAllowed:
        if (allowSubmissionWithWarnings) {
          return FormSubmissionResult(
            success: true,
            message: 'Form submitted successfully with warnings',
            errors: [],
            warnings: allWarnings,
          );
        } else {
          return FormSubmissionResult(
            success: false,
            message: 'Form has warnings - review before submitting',
            errors: [],
            warnings: allWarnings,
          );
        }
      case FormSubmissionState.allowed:
        return FormSubmissionResult(
          success: true,
          message: 'Form submitted successfully',
          errors: [],
          warnings: [],
        );
    }
  }
  
  /// Get field by key
  dynamic _getField(String fieldKey) {
    try {
      return _fields.firstWhere((field) {
        if (field is DynamicFormField) {
          return field.key == fieldKey;
        } else {
          return field.id == fieldKey;
        }
      });
    } catch (e) {
      debugPrint('Field not found: $fieldKey');
      return null;
    }
  }
  
  /// Get validation summary
  FormValidationSummary get summary {
    return FormValidationSummary(
      totalFields: _fields.length,
      validatedFields: _validationResults.length,
      fieldsWithErrors: fieldsWithErrors.length,
      fieldsWithWarnings: fieldsWithWarnings.length,
      isFormValid: isFormValid,
      canSubmit: checkSubmissionState() != FormSubmissionState.blocked,
    );
  }
  
  /// Dispose resources
  void dispose() {
    _listeners.clear();
    _validationResults.clear();
  }
}

/// Listener interface for validation state changes
abstract class FormValidationListener {
  void onValidationStateChanged(Map<String, ValidationResult> results);
}

/// Form submission states
enum FormSubmissionState {
  allowed,
  warningButAllowed,
  blocked,
}

/// Result of form submission attempt
class FormSubmissionResult {
  final bool success;
  final String message;
  final List<String> errors;
  final List<String> warnings;
  
  const FormSubmissionResult({
    required this.success,
    required this.message,
    required this.errors,
    required this.warnings,
  });
  
  @override
  String toString() => 'FormSubmissionResult(success: $success, message: $message)';
}

/// Summary of form validation state
class FormValidationSummary {
  final int totalFields;
  final int validatedFields;
  final int fieldsWithErrors;
  final int fieldsWithWarnings;
  final bool isFormValid;
  final bool canSubmit;
  
  const FormValidationSummary({
    required this.totalFields,
    required this.validatedFields,
    required this.fieldsWithErrors,
    required this.fieldsWithWarnings,
    required this.isFormValid,
    required this.canSubmit,
  });
  
  @override
  String toString() => 
      'FormValidationSummary(fields: $totalFields, errors: $fieldsWithErrors, warnings: $fieldsWithWarnings, valid: $isFormValid)';
}