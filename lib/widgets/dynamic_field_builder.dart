import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/log_template_models.dart';

/// Builds form fields dynamically based on template field definitions
/// Like rendering the right character sheet section based on class
class DynamicFieldBuilder extends StatelessWidget {
  final TemplateField field;
  final dynamic value;
  final Function(dynamic) onChanged;
  final String? errorText;
  final bool enabled;
  final bool showLabel;

  const DynamicFieldBuilder({
    Key? key,
    required this.field,
    this.value,
    required this.onChanged,
    this.errorText,
    this.enabled = true,
    this.showLabel = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (field.type) {
      case FieldType.text:
        return _buildTextField(context);
      case FieldType.number:
      case FieldType.decimal:
        return _buildNumberField(context);
      case FieldType.temperature:
      case FieldType.pressure:
      case FieldType.percentage:
      case FieldType.ppm:
      case FieldType.flow:
        return _buildMeasurementField(context);
      case FieldType.select:
        return _buildSelectField(context);
      case FieldType.checkbox:
        return _buildCheckboxField(context);
      case FieldType.date:
        return _buildDateField(context);
      case FieldType.time:
        return _buildTimeField(context);
      default:
        return _buildTextField(context);
    }
  }

  Widget _buildTextField(BuildContext context) {
    return TextFormField(
      initialValue: value?.toString() ?? field.defaultValue?.toString(),
      enabled: enabled,
      maxLength: field.validation.maxLength,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: showLabel ? field.label : null,
        hintText: field.placeholder,
        helperText: field.helpText,
        errorText: errorText,
        suffixText: field.unit,
        filled: true,
        fillColor: Colors.grey.shade900,
        labelStyle: GoogleFonts.orbitron(
          color: Colors.orange.shade300,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.roboto(
          color: Colors.grey.shade600,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.orange.shade600, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      style: GoogleFonts.robotoMono(
        color: Colors.white,
        fontSize: 16,
      ),
    );
  }

  Widget _buildNumberField(BuildContext context) {
    return TextFormField(
      initialValue: value?.toString() ?? field.defaultValue?.toString(),
      enabled: enabled,
      keyboardType: TextInputType.numberWithOptions(
        decimal: field.type == FieldType.decimal,
      ),
      inputFormatters: [
        if (field.type == FieldType.number)
          FilteringTextInputFormatter.digitsOnly
        else
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      onChanged: (val) {
        if (val.isEmpty) {
          onChanged(null);
        } else {
          final parsed = field.type == FieldType.number
              ? int.tryParse(val)
              : double.tryParse(val);
          onChanged(parsed);
        }
      },
      decoration: InputDecoration(
        labelText: showLabel ? field.label : null,
        hintText: field.placeholder ?? 'Enter value',
        helperText: field.helpText,
        errorText: errorText,
        suffixText: field.unit,
        filled: true,
        fillColor: Colors.grey.shade900,
        labelStyle: GoogleFonts.orbitron(
          color: Colors.orange.shade300,
          fontSize: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.orange.shade600, width: 2),
        ),
      ),
      style: GoogleFonts.robotoMono(
        color: Colors.white,
        fontSize: 16,
      ),
    );
  }

  Widget _buildMeasurementField(BuildContext context) {
    // Get icon based on measurement type
    IconData icon = _getMeasurementIcon();
    Color iconColor = _getMeasurementColor();
    
    return TextFormField(
      initialValue: value?.toString() ?? field.defaultValue?.toString(),
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      onChanged: (val) {
        if (val.isEmpty) {
          onChanged(null);
        } else {
          onChanged(double.tryParse(val));
        }
      },
      decoration: InputDecoration(
        labelText: showLabel ? field.label : null,
        hintText: field.placeholder ?? _getPlaceholderForType(),
        helperText: field.helpText,
        errorText: errorText,
        prefixIcon: Icon(icon, color: iconColor, size: 20),
        suffixText: field.unit,
        filled: true,
        fillColor: Colors.grey.shade900,
        labelStyle: GoogleFonts.orbitron(
          color: Colors.orange.shade300,
          fontSize: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: iconColor, width: 2),
        ),
      ),
      style: GoogleFonts.robotoMono(
        color: Colors.white,
        fontSize: 16,
      ),
    );
  }

  Widget _buildSelectField(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value ?? field.defaultValue ?? 
             field.options?.firstWhere((o) => o.isDefault, orElse: () => field.options!.first).value,
      enabled: enabled,
      items: field.options?.map((option) {
        return DropdownMenuItem(
          value: option.value,
          child: Text(
            option.label,
            style: GoogleFonts.roboto(color: Colors.white),
          ),
        );
      }).toList() ?? [],
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(
        labelText: showLabel ? field.label : null,
        helperText: field.helpText,
        errorText: errorText,
        filled: true,
        fillColor: Colors.grey.shade900,
        labelStyle: GoogleFonts.orbitron(
          color: Colors.orange.shade300,
          fontSize: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.orange.shade600, width: 2),
        ),
      ),
      dropdownColor: Colors.grey.shade900,
      style: GoogleFonts.roboto(
        color: Colors.white,
        fontSize: 16,
      ),
    );
  }

  Widget _buildCheckboxField(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: errorText != null ? Colors.red : Colors.grey.shade700,
        ),
      ),
      child: CheckboxListTile(
        title: Text(
          field.label,
          style: GoogleFonts.orbitron(
            color: Colors.orange.shade300,
            fontSize: 14,
          ),
        ),
        subtitle: field.helpText != null
            ? Text(
                field.helpText!,
                style: GoogleFonts.roboto(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                ),
              )
            : null,
        value: value ?? field.defaultValue ?? false,
        onChanged: enabled ? onChanged : null,
        activeColor: Colors.orange.shade600,
        checkColor: Colors.black,
      ),
    );
  }

  Widget _buildDateField(BuildContext context) {
    return InkWell(
      onTap: enabled
          ? () async {
              final date = await showDatePicker(
                context: context,
                initialDate: value ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: ColorScheme.dark(
                        primary: Colors.orange.shade600,
                        onPrimary: Colors.black,
                        surface: Colors.grey.shade900,
                        onSurface: Colors.white,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (date != null) {
                onChanged(date);
              }
            }
          : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: showLabel ? field.label : null,
          helperText: field.helpText,
          errorText: errorText,
          filled: true,
          fillColor: Colors.grey.shade900,
          labelStyle: GoogleFonts.orbitron(
            color: Colors.orange.shade300,
            fontSize: 14,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade700),
          ),
        ),
        child: Text(
          value != null
              ? '${value.day}/${value.month}/${value.year}'
              : 'Select date',
          style: GoogleFonts.robotoMono(
            color: value != null ? Colors.white : Colors.grey.shade600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeField(BuildContext context) {
    return InkWell(
      onTap: enabled
          ? () async {
              final time = await showTimePicker(
                context: context,
                initialTime: value ?? TimeOfDay.now(),
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: ColorScheme.dark(
                        primary: Colors.orange.shade600,
                        onPrimary: Colors.black,
                        surface: Colors.grey.shade900,
                        onSurface: Colors.white,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (time != null) {
                onChanged(time);
              }
            }
          : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: showLabel ? field.label : null,
          helperText: field.helpText,
          errorText: errorText,
          filled: true,
          fillColor: Colors.grey.shade900,
          labelStyle: GoogleFonts.orbitron(
            color: Colors.orange.shade300,
            fontSize: 14,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade700),
          ),
        ),
        child: Text(
          value != null ? value.format(context) : 'Select time',
          style: GoogleFonts.robotoMono(
            color: value != null ? Colors.white : Colors.grey.shade600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  IconData _getMeasurementIcon() {
    switch (field.type) {
      case FieldType.temperature:
        return Icons.thermostat;
      case FieldType.pressure:
        return Icons.speed;
      case FieldType.percentage:
        return Icons.percent;
      case FieldType.ppm:
        return Icons.bubble_chart;
      case FieldType.flow:
        return Icons.air;
      default:
        return Icons.straighten;
    }
  }

  Color _getMeasurementColor() {
    switch (field.type) {
      case FieldType.temperature:
        return Colors.red.shade400;
      case FieldType.pressure:
        return Colors.blue.shade400;
      case FieldType.percentage:
        return Colors.green.shade400;
      case FieldType.ppm:
        return Colors.purple.shade400;
      case FieldType.flow:
        return Colors.cyan.shade400;
      default:
        return Colors.orange.shade400;
    }
  }

  String _getPlaceholderForType() {
    switch (field.type) {
      case FieldType.temperature:
        return 'Enter temperature';
      case FieldType.pressure:
        return 'Enter pressure';
      case FieldType.percentage:
        return 'Enter percentage';
      case FieldType.ppm:
        return 'Enter PPM value';
      case FieldType.flow:
        return 'Enter flow rate';
      default:
        return 'Enter value';
    }
  }
}