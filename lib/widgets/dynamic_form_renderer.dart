import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/dynamic_form_schema.dart';
import '../utils/validation_utils.dart';

/// Dynamic form rendering engine that creates forms from templates
/// Supports all field types, validation, and conditional logic
class DynamicFormRenderer extends StatefulWidget {
  final DynamicFormTemplate template;
  final Map<String, dynamic>? initialValues;
  final Function(Map<String, dynamic>) onFormChanged;
  final Function(Map<String, dynamic>)? onFormSubmitted;
  final bool readonly;

  const DynamicFormRenderer({
    super.key,
    required this.template,
    this.initialValues,
    required this.onFormChanged,
    this.onFormSubmitted,
    this.readonly = false,
  });

  @override
  State<DynamicFormRenderer> createState() => _DynamicFormRendererState();
}

class _DynamicFormRendererState extends State<DynamicFormRenderer> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _formValues = {};
  final Map<String, String?> _fieldErrors = {};
  final Map<String, String?> _fieldWarnings = {};
  final Map<String, bool> _sectionExpanded = {};

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeForm() {
    // Initialize form values with defaults and initial values
    for (final field in widget.template.fields) {
      final initialValue = widget.initialValues?[field.key] ?? field.defaultValue;
      _formValues[field.key] = initialValue;
      
      // Create text controllers for text-based fields
      if (_requiresTextController(field.type)) {
        _controllers[field.key] = TextEditingController(
          text: initialValue?.toString() ?? '',
        );
        
        _controllers[field.key]!.addListener(() {
          _updateFieldValue(field.key, _controllers[field.key]!.text);
        });
      }
    }
    
    // Initialize section expansion states
    for (final section in widget.template.sections) {
      _sectionExpanded[section.id] = section.defaultExpanded;
    }
    
    // Initial validation pass
    _validateForm();
  }

  bool _requiresTextController(DynamicFieldType type) {
    return [
      DynamicFieldType.text,
      DynamicFieldType.number,
      DynamicFieldType.decimal,
      DynamicFieldType.temperature,
      DynamicFieldType.pressure,
      DynamicFieldType.percentage,
      DynamicFieldType.ppm,
      DynamicFieldType.flow,
    ].contains(type);
  }

  void _updateFieldValue(String fieldKey, dynamic value) {
    setState(() {
      _formValues[fieldKey] = value;
    });
    
    _validateField(fieldKey);
    widget.onFormChanged(_formValues);
  }

  void _validateField(String fieldKey) {
    final field = widget.template.fields.firstWhere((f) => f.key == fieldKey);
    final value = _formValues[fieldKey];
    
    // Clear previous errors/warnings
    _fieldErrors.remove(fieldKey);
    _fieldWarnings.remove(fieldKey);
    
    // Use centralized validation service
    final result = ValidationUtils.validateDynamicField(
      field: field,
      value: value,
      allFieldValues: _formValues,
    );
    
    // Set error if validation failed
    if (!result.isValid && result.errors.isNotEmpty) {
      _fieldErrors[fieldKey] = result.firstError;
    }
    
    // Set warning if present
    if (result.warnings.isNotEmpty) {
      _fieldWarnings[fieldKey] = result.firstWarning;
    }
  }

  String? _validateFieldValue(DynamicFormField field, dynamic value) {
    // Use centralized validation service
    final result = ValidationUtils.validateDynamicField(
      field: field,
      value: value,
      allFieldValues: _formValues,
    );
    return result.firstError;
  }

  String? _checkFieldWarnings(DynamicFormField field, dynamic value) {
    // Use centralized validation service for warnings
    final result = ValidationUtils.validateDynamicField(
      field: field,
      value: value,
      allFieldValues: _formValues,
    );
    return result.firstWarning;
  }

  bool _isNumericField(DynamicFieldType type) {
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

  void _validateForm() {
    for (final field in widget.template.fields) {
      _validateField(field.key);
    }
  }

  bool _shouldShowField(DynamicFormField field) {
    // Check field conditions
    if (field.conditions != null) {
      for (final condition in field.conditions!) {
        final dependentValue = _formValues[condition.dependsOnField];
        if (!_evaluateCondition(condition, dependentValue)) {
          return false;
        }
      }
    }
    
    return true;
  }

  bool _shouldShowSection(DynamicFormSection section) {
    // Check section conditions
    if (section.conditions != null) {
      for (final condition in section.conditions!) {
        final dependentValue = _formValues[condition.dependsOnField];
        if (!_evaluateCondition(condition, dependentValue)) {
          return false;
        }
      }
    }
    
    return true;
  }

  bool _evaluateCondition(DynamicFieldCondition condition, dynamic actualValue) {
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

  List<TextInputFormatter> _getInputFormatters(DynamicFieldType type) {
    switch (type) {
      case DynamicFieldType.number:
      case DynamicFieldType.temperature:
      case DynamicFieldType.pressure:
      case DynamicFieldType.ppm:
      case DynamicFieldType.flow:
        return [FilteringTextInputFormatter.allow(RegExp(r'^\d*'))];
      case DynamicFieldType.decimal:
      case DynamicFieldType.percentage:
        return [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Form header
          _buildFormHeader(),
          const SizedBox(height: 16),
          
          // Form sections
          ...widget.template.sections
              .where(_shouldShowSection)
              .map((section) => _buildSection(section)),
          
          const SizedBox(height: 24),
          
          // Form actions
          if (!widget.readonly) _buildFormActions(),
        ],
      ),
    );
  }

  Widget _buildFormHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B132B), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.template.name,
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.template.description,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(DynamicFormSection section) {
    final sectionFields = widget.template.getFieldsForSection(section.id)
        .where(_shouldShowField)
        .toList();
    
    if (sectionFields.isEmpty) return const SizedBox.shrink();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF152042),
      child: Column(
        children: [
          // Section header
          InkWell(
            onTap: section.collapsible ? () {
              setState(() {
                _sectionExpanded[section.id] = !(_sectionExpanded[section.id] ?? true);
              });
            } : null,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (section.icon != null) ...[
                    Text(section.icon!, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      section.title,
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (section.collapsible)
                    Icon(
                      (_sectionExpanded[section.id] ?? true) 
                          ? Icons.expand_less 
                          : Icons.expand_more,
                      color: Colors.white70,
                    ),
                ],
              ),
            ),
          ),
          
          // Section fields
          if (_sectionExpanded[section.id] ?? true)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: sectionFields
                    .map((field) => _buildField(field))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildField(DynamicFormField field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldWidget(field),
          if (_fieldWarnings[field.key] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _fieldWarnings[field.key]!,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: Colors.orange[300],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFieldWidget(DynamicFormField field) {
    switch (field.type) {
      case DynamicFieldType.text:
        return _buildTextFieldWidget(field);
      case DynamicFieldType.number:
      case DynamicFieldType.decimal:
      case DynamicFieldType.temperature:
      case DynamicFieldType.pressure:
      case DynamicFieldType.percentage:
      case DynamicFieldType.ppm:
      case DynamicFieldType.flow:
        return _buildNumberFieldWidget(field);
      case DynamicFieldType.select:
        return _buildSelectFieldWidget(field);
      case DynamicFieldType.multiSelect:
        return _buildMultiSelectFieldWidget(field);
      case DynamicFieldType.checkbox:
        return _buildCheckboxFieldWidget(field);
      case DynamicFieldType.date:
        return _buildDateFieldWidget(field);
      case DynamicFieldType.time:
        return _buildTimeFieldWidget(field);
      case DynamicFieldType.dateTime:
        return _buildDateTimeFieldWidget(field);
      default:
        return _buildTextFieldWidget(field);
    }
  }

  Widget _buildTextFieldWidget(DynamicFormField field) {
    return TextFormField(
      controller: _controllers[field.key],
      enabled: !widget.readonly,
      style: GoogleFonts.nunito(color: Colors.white),
      maxLength: field.validation.maxLength,
      decoration: InputDecoration(
        labelText: field.label + (field.validation.required ? ' *' : ''),
        labelStyle: GoogleFonts.nunito(color: Colors.grey[400]),
        hintText: field.placeholder,
        hintStyle: GoogleFonts.nunito(color: Colors.grey[600]),
        helperText: field.helpText,
        helperStyle: GoogleFonts.nunito(color: Colors.grey[500], fontSize: 12),
        errorText: _fieldErrors[field.key],
        filled: true,
        fillColor: const Color(0xFF0B132B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3B82F6)),
        ),
      ),
      validator: (value) => _validateFieldValue(field, value),
    );
  }

  Widget _buildNumberFieldWidget(DynamicFormField field) {
    return TextFormField(
      controller: _controllers[field.key],
      enabled: !widget.readonly,
      style: GoogleFonts.nunito(color: Colors.white),
      keyboardType: TextInputType.number,
      inputFormatters: _getInputFormatters(field.type),
      decoration: InputDecoration(
        labelText: field.label + (field.validation.required ? ' *' : ''),
        labelStyle: GoogleFonts.nunito(color: Colors.grey[400]),
        hintText: field.placeholder,
        hintStyle: GoogleFonts.nunito(color: Colors.grey[600]),
        helperText: field.helpText,
        helperStyle: GoogleFonts.nunito(color: Colors.grey[500], fontSize: 12),
        suffixText: field.unit,
        suffixStyle: GoogleFonts.nunito(color: Colors.grey[400]),
        errorText: _fieldErrors[field.key],
        filled: true,
        fillColor: const Color(0xFF0B132B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3B82F6)),
        ),
      ),
      validator: (value) => _validateFieldValue(field, value),
    );
  }

  Widget _buildSelectFieldWidget(DynamicFormField field) {
    return DropdownButtonFormField<String>(
      value: _formValues[field.key],
      onChanged: widget.readonly ? null : (value) => _updateFieldValue(field.key, value),
      style: GoogleFonts.nunito(color: Colors.white),
      decoration: InputDecoration(
        labelText: field.label + (field.validation.required ? ' *' : ''),
        labelStyle: GoogleFonts.nunito(color: Colors.grey[400]),
        helperText: field.helpText,
        helperStyle: GoogleFonts.nunito(color: Colors.grey[500], fontSize: 12),
        errorText: _fieldErrors[field.key],
        filled: true,
        fillColor: const Color(0xFF0B132B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3B82F6)),
        ),
      ),
      dropdownColor: const Color(0xFF152042),
      items: field.options?.map((option) => DropdownMenuItem(
        value: option.value,
        child: Text(
          option.label,
          style: GoogleFonts.nunito(color: Colors.white),
        ),
      )).toList(),
      validator: (value) => _validateFieldValue(field, value),
    );
  }

  Widget _buildMultiSelectFieldWidget(DynamicFormField field) {
    // Multi-select implementation would go here
    return _buildTextFieldWidget(field);
  }

  Widget _buildCheckboxFieldWidget(DynamicFormField field) {
    return FormField<bool>(
      initialValue: _formValues[field.key] ?? false,
      validator: (value) => _validateFieldValue(field, value),
      builder: (state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            title: Text(
              field.label + (field.validation.required ? ' *' : ''),
              style: GoogleFonts.nunito(color: Colors.white),
            ),
            subtitle: field.helpText != null ? Text(
              field.helpText!,
              style: GoogleFonts.nunito(color: Colors.grey[500], fontSize: 12),
            ) : null,
            value: _formValues[field.key] ?? false,
            onChanged: widget.readonly ? null : (value) {
              _updateFieldValue(field.key, value);
              state.didChange(value);
            },
            activeColor: const Color(0xFF3B82F6),
            contentPadding: EdgeInsets.zero,
          ),
          if (state.hasError)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Text(
                state.errorText!,
                style: GoogleFonts.nunito(
                  color: Colors.red[300],
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateFieldWidget(DynamicFormField field) {
    // Date picker implementation would go here
    return _buildTextFieldWidget(field);
  }

  Widget _buildTimeFieldWidget(DynamicFormField field) {
    // Time picker implementation would go here
    return _buildTextFieldWidget(field);
  }

  Widget _buildDateTimeFieldWidget(DynamicFormField field) {
    // DateTime picker implementation would go here
    return _buildTextFieldWidget(field);
  }

  Widget _buildFormActions() {
    // Check if form has validation errors
    final hasErrors = _fieldErrors.isNotEmpty;
    final hasWarnings = _fieldWarnings.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Show validation summary if there are issues
        if (hasErrors || hasWarnings) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: hasErrors ? Colors.red[50] : Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasErrors ? Colors.red[300]! : Colors.orange[300]!,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      hasErrors ? Icons.error : Icons.warning,
                      color: hasErrors ? Colors.red[600] : Colors.orange[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hasErrors ? 'Form has errors' : 'Form has warnings',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w600,
                        color: hasErrors ? Colors.red[800] : Colors.orange[800],
                      ),
                    ),
                  ],
                ),
                if (hasErrors) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Please fix the errors above before submitting.',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: Colors.red[700],
                    ),
                  ),
                ],
                if (hasWarnings && !hasErrors) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Review warnings above. You can still submit if needed.',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: Colors.orange[700],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (hasWarnings || hasErrors)
              TextButton.icon(
                onPressed: () {
                  _validateForm();
                  setState(() {}); // Refresh validation display
                },
                icon: const Icon(Icons.refresh),
                label: Text(
                  'Revalidate',
                  style: GoogleFonts.nunito(),
                ),
              ),
            if (hasWarnings || hasErrors) const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: hasErrors ? null : () {
                // Perform final validation before submission
                _validateForm();
                
                if (_fieldErrors.isEmpty) {
                  widget.onFormSubmitted?.call(_formValues);
                }
              },
              icon: const Icon(Icons.save),
              label: Text(
                'Save Entry',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: hasErrors ? Colors.grey : const Color(0xFF3B82F6),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }
}