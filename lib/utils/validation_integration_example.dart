// Example of how to integrate the new validation system
// This file shows usage patterns and can be used as reference

import 'package:flutter/material.dart';
import '../models/log_template.dart';
import '../models/dynamic_form_schema.dart';
import '../services/validation_initialization.dart';
import 'validation_utils.dart';
import 'form_validation_manager.dart';

/// Example of how to use the validation system in a form
class ValidationIntegrationExample {
  
  /// Initialize validation system (call once at app startup)
  static void initializeApp() {
    ValidationInitialization.initialize();
  }
  
  /// Example: Using validation with LogFieldTemplate
  static void exampleLogFieldValidation() {
    const field = LogFieldTemplate(
      id: 'temperature',
      label: 'Temperature',
      unit: '°F',
      type: FieldType.number,
      order: 1,
      validation: FieldValidationRule(
        required: true,
        min: 0,
        max: 2000,
        warningMin: 1200,
        warningMax: 1400,
        customValidator: 'thermal_efficiency',
      ),
    );
    
    // Validate a value
    final result = field.validate('1300', {'inletReading': '100', 'outletReading': '95'});
    print('Validation result: $result');
    
    // Get warning
    final warning = field.getWarning('1100', {'inletReading': '100'});
    print('Warning: $warning');
    
    // Create Flutter validator function
    final validator = field.getValidator({'inletReading': '100'});
    final error = validator('invalid');
    print('Validator error: $error');
  }
  
  /// Example: Using form validation manager
  static void exampleFormValidationManager() {
    // Sample fields
    final fields = [
      const LogFieldTemplate(
        id: 'inlet',
        label: 'Inlet Reading',
        type: FieldType.number,
        order: 1,
        validation: FieldValidationRule(required: true, min: 0),
      ),
      const LogFieldTemplate(
        id: 'outlet',
        label: 'Outlet Reading',
        type: FieldType.number,
        order: 2,
        validation: FieldValidationRule(required: true, min: 0),
      ),
    ];
    
    // Sample form values
    final formValues = <String, dynamic>{
      'inlet': '100',
      'outlet': '105', // Invalid - outlet > inlet
    };
    
    // Create validation manager
    final manager = FormValidationManager(
      fields: fields,
      formValues: formValues,
    );
    
    // Validate all fields
    final results = manager.validateAllFields();
    print('Validation results: $results');
    
    // Check form state
    print('Form valid: ${manager.isFormValid}');
    print('Has errors: ${manager.hasErrors}');
    print('Has warnings: ${manager.hasWarnings}');
    
    // Attempt submission
    final submissionResult = manager.attemptSubmit();
    print('Submission result: $submissionResult');
    
    // Get summary
    print('Summary: ${manager.summary}');
    
    // Clean up
    manager.dispose();
  }
  
  /// Example: Flutter widget integration
  static Widget exampleValidatedTextField(LogFieldTemplate field) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: field.label + (field.validation.required ? ' *' : ''),
        suffixText: field.unit,
        helperText: field.helpText,
      ),
      validator: field.getValidator(),
      keyboardType: field.type == FieldType.number 
          ? TextInputType.number 
          : TextInputType.text,
      inputFormatters: field.inputFormatters,
    );
  }
  
  /// Example: Real-time validation in StatefulWidget
  static Widget exampleRealtimeValidation() {
    return _RealtimeValidationExample();
  }
}

class _RealtimeValidationExample extends StatefulWidget {
  @override
  State<_RealtimeValidationExample> createState() => 
      _RealtimeValidationExampleState();
}

class _RealtimeValidationExampleState extends State<_RealtimeValidationExample> 
    implements FormValidationListener {
  
  late FormValidationManager _validationManager;
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  final _formValues = <String, dynamic>{};
  
  final _fields = [
    const LogFieldTemplate(
      id: 'temperature',
      label: 'Temperature',
      unit: '°F',
      type: FieldType.number,
      order: 1,
      validation: FieldValidationRule(
        required: true,
        min: 0,
        max: 2000,
        warningMin: 1200,
        warningMax: 1400,
      ),
    ),
    const LogFieldTemplate(
      id: 'pressure',
      label: 'Pressure',
      unit: 'PSI',
      type: FieldType.number,
      order: 2,
      validation: FieldValidationRule(
        required: true,
        min: 0,
        max: 100,
      ),
    ),
  ];
  
  @override
  void initState() {
    super.initState();
    
    // Initialize controllers
    for (final field in _fields) {
      _controllers[field.id] = TextEditingController();
      _controllers[field.id]!.addListener(() {
        _onFieldChanged(field.id, _controllers[field.id]!.text);
      });
    }
    
    // Initialize validation manager
    _validationManager = FormValidationManager(
      fields: _fields,
      formValues: _formValues,
    );
    _validationManager.addListener(this);
  }
  
  @override
  void dispose() {
    _validationManager.removeListener(this);
    _validationManager.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
  
  void _onFieldChanged(String fieldKey, String value) {
    setState(() {
      _formValues[fieldKey] = value;
      _validationManager.updateFieldValue(fieldKey, value);
    });
  }
  
  @override
  void onValidationStateChanged(Map<String, ValidationResult> results) {
    // React to validation state changes
    setState(() {
      // UI will rebuild with updated validation state
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Validation Example')),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Build form fields
              ..._fields.map((field) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: _controllers[field.id],
                  decoration: InputDecoration(
                    labelText: field.label + (field.validation.required ? ' *' : ''),
                    suffixText: field.unit,
                    helperText: field.helpText,
                    errorText: _validationManager.getFieldValidation(field.id)?.firstError,
                  ),
                  validator: field.getValidator(_formValues),
                  keyboardType: field.type == FieldType.number 
                      ? TextInputType.number 
                      : TextInputType.text,
                ),
              )),
              
              const SizedBox(height: 20),
              
              // Validation summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Validation Summary', 
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('Form Valid: ${_validationManager.isFormValid}'),
                      Text('Has Errors: ${_validationManager.hasErrors}'),
                      Text('Has Warnings: ${_validationManager.hasWarnings}'),
                      if (_validationManager.allErrors.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Errors:', style: TextStyle(color: Colors.red[700])),
                        ..._validationManager.allErrors.map(
                          (error) => Text('• $error', style: TextStyle(color: Colors.red[600])),
                        ),
                      ],
                      if (_validationManager.allWarnings.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Warnings:', style: TextStyle(color: Colors.orange[700])),
                        ..._validationManager.allWarnings.map(
                          (warning) => Text('• $warning', style: TextStyle(color: Colors.orange[600])),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Submit button
              ElevatedButton(
                onPressed: _validationManager.isFormValid ? () {
                  final result = _validationManager.attemptSubmit();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result.message)),
                  );
                } : null,
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}