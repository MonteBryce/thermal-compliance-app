import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/log_template.dart';
import '../services/form_validation_service.dart';

/// Enhanced form field widget with validation, warnings, and rich UI
class EnhancedFormField extends StatelessWidget {
  final LogFieldTemplate field;
  final TextEditingController controller;
  final ValidationResult? validationResult;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  const EnhancedFormField({
    Key? key,
    required this.field,
    required this.controller,
    this.validationResult,
    this.onChanged,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (field.type) {
      case FieldType.number:
        return _buildNumberField(context);
      case FieldType.text:
        return _buildTextField(context);
      case FieldType.dropdown:
        return _buildDropdownField(context);
      case FieldType.checkbox:
        return _buildCheckboxField(context);
      case FieldType.dateTime:
        return _buildDateTimeField(context);
      default:
        return _buildTextField(context);
    }
  }

  Widget _buildNumberField(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: field.inputFormatters,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: _getFieldLabel(),
            hintText: _getHintText(),
            suffixText: field.unit,
            helperText: field.helpText,
            errorText: validationResult?.firstError,
            prefixIcon: _getFieldIcon(),
            filled: true,
            fillColor: _getFieldBackgroundColor(theme),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _getBorderColor(theme),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
          ),
          validator: (value) => field.validate(value),
        ),
        
        // Warning display
        if (validationResult?.warnings.isNotEmpty == true) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.orange[300]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  size: 16,
                  color: Colors.orange[700],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    validationResult!.firstWarning!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        // Field recommendations or range display
        if (field.validation.min != null || field.validation.max != null) ...[
          const SizedBox(height: 4),
          _buildRangeIndicator(theme),
        ],
      ],
    );
  }

  Widget _buildTextField(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          enabled: enabled,
          onChanged: onChanged,
          maxLines: field.id.contains('observation') || field.id.contains('note') ? 3 : 1,
          decoration: InputDecoration(
            labelText: _getFieldLabel(),
            hintText: _getHintText(),
            helperText: field.helpText,
            errorText: validationResult?.firstError,
            prefixIcon: _getFieldIcon(),
            filled: true,
            fillColor: _getFieldBackgroundColor(theme),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _getBorderColor(theme),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
          ),
          validator: (value) => field.validate(value),
        ),
        
        // Warning display
        if (validationResult?.warnings.isNotEmpty == true) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.orange[300]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  size: 16,
                  color: Colors.orange[700],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    validationResult!.firstWarning!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDropdownField(BuildContext context) {
    final theme = Theme.of(context);
    
    return DropdownButtonFormField<String>(
      value: controller.text.isEmpty ? null : controller.text,
      onChanged: enabled ? (value) {
        controller.text = value ?? '';
        onChanged?.call(value ?? '');
      } : null,
      decoration: InputDecoration(
        labelText: _getFieldLabel(),
        helperText: field.helpText,
        errorText: validationResult?.firstError,
        prefixIcon: _getFieldIcon(),
        filled: true,
        fillColor: _getFieldBackgroundColor(theme),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      items: field.dropdownOptions?.map((option) => DropdownMenuItem(
        value: option,
        child: Text(option),
      )).toList(),
      validator: (value) => field.validate(value),
    );
  }

  Widget _buildCheckboxField(BuildContext context) {
    final theme = Theme.of(context);
    final isChecked = controller.text.toLowerCase() == 'true';
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getFieldBackgroundColor(theme),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getBorderColor(theme)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            value: isChecked,
            onChanged: enabled ? (value) {
              controller.text = value.toString();
              onChanged?.call(value.toString());
            } : null,
            title: Text(
              _getFieldLabel(),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: field.helpText != null ? Text(
              field.helpText!,
              style: theme.textTheme.bodySmall,
            ) : null,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          
          if (validationResult?.firstError != null) ...[
            const SizedBox(height: 8),
            Text(
              validationResult!.firstError!,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateTimeField(BuildContext context) {
    final theme = Theme.of(context);
    
    return TextFormField(
      controller: controller,
      enabled: enabled,
      readOnly: true,
      onTap: enabled ? () => _selectDateTime(context) : null,
      decoration: InputDecoration(
        labelText: _getFieldLabel(),
        hintText: 'Tap to select date and time',
        helperText: field.helpText,
        errorText: validationResult?.firstError,
        prefixIcon: const Icon(Icons.calendar_today),
        suffixIcon: const Icon(Icons.arrow_drop_down),
        filled: true,
        fillColor: _getFieldBackgroundColor(theme),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      validator: (value) => field.validate(value),
    );
  }

  Widget _buildRangeIndicator(ThemeData theme) {
    final min = field.validation.min;
    final max = field.validation.max;
    final currentValue = double.tryParse(controller.text);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Range: ${min ?? '0'} - ${max ?? '∞'}${field.unit != null ? ' ${field.unit}' : ''}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (currentValue != null && min != null && max != null) ...[
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: ((currentValue - min) / (max - min)).clamp(0.0, 1.0),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getRangeColor(currentValue, min, max),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getRangeColor(double value, double min, double max) {
    if (value < min || value > max) {
      return Colors.red;
    } else if (value < (min + (max - min) * 0.2) || value > (min + (max - min) * 0.8)) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  String _getFieldLabel() {
    return field.label + (field.validation.required ? ' *' : '');
  }

  String? _getHintText() {
    switch (field.type) {
      case FieldType.number:
        if (field.validation.min != null && field.validation.max != null) {
          return 'Enter ${field.validation.min}-${field.validation.max}';
        }
        return 'Enter a number';
      case FieldType.text:
        return field.id.contains('observation') || field.id.contains('note')
            ? 'Enter observations or notes...'
            : 'Enter text';
      default:
        return null;
    }
  }

  Icon? _getFieldIcon() {
    switch (field.type) {
      case FieldType.number:
        if (field.unit?.contains('°F') == true) return const Icon(Icons.thermostat);
        if (field.unit?.contains('PPM') == true) return const Icon(Icons.science);
        if (field.unit?.contains('PSI') == true || field.unit?.contains('H₂O') == true) {
          return const Icon(Icons.compress);
        }
        return const Icon(Icons.tag);
      case FieldType.text:
        if (field.id.contains('observation') || field.id.contains('note')) {
          return const Icon(Icons.notes);
        }
        return const Icon(Icons.text_fields);
      case FieldType.dropdown:
        return const Icon(Icons.arrow_drop_down_circle);
      case FieldType.checkbox:
        return const Icon(Icons.check_box_outline_blank);
      case FieldType.dateTime:
        return const Icon(Icons.schedule);
      default:
        return null;
    }
  }

  Color _getFieldBackgroundColor(ThemeData theme) {
    if (validationResult?.isValid == false) {
      return Colors.red[50]!;
    }
    if (validationResult?.warnings.isNotEmpty == true) {
      return Colors.orange[50]!;
    }
    return theme.colorScheme.surface;
  }

  Color _getBorderColor(ThemeData theme) {
    if (validationResult?.isValid == false) {
      return Colors.red;
    }
    if (validationResult?.warnings.isNotEmpty == true) {
      return Colors.orange;
    }
    return Colors.grey[300]!;
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (date != null && context.mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      
      if (time != null) {
        final dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        
        controller.text = dateTime.toIso8601String();
        onChanged?.call(controller.text);
      }
    }
  }
}