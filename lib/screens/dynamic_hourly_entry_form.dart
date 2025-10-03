import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/log_template_models.dart';
import '../services/log_template_service.dart';
import '../services/thermal_reading_service.dart';
import '../widgets/dynamic_field_builder.dart';

/// Dynamic Hourly Entry Form - Like a D&D character sheet that changes based on class
class DynamicHourlyEntryForm extends ConsumerStatefulWidget {
  final String projectId;
  final String jobId;
  final String logType;
  final int hour;
  final DateTime selectedDate;
  final Map<String, dynamic>? existingData;

  const DynamicHourlyEntryForm({
    Key? key,
    required this.projectId,
    required this.jobId,
    required this.logType,
    required this.hour,
    required this.selectedDate,
    this.existingData,
  }) : super(key: key);

  @override
  ConsumerState<DynamicHourlyEntryForm> createState() => _DynamicHourlyEntryFormState();
}

class _DynamicHourlyEntryFormState extends ConsumerState<DynamicHourlyEntryForm> {
  final LogTemplateService _templateService = LogTemplateService();
  final ThermalReadingService _readingService = ThermalReadingService();
  
  LogTemplate? _template;
  Map<String, dynamic> _formData = {};
  Map<String, String> _errors = {};
  bool _isLoading = true;
  bool _isSaving = false;
  bool _showOptionalFields = false;

  @override
  void initState() {
    super.initState();
    _loadTemplate();
    if (widget.existingData != null) {
      _formData = Map.from(widget.existingData!);
    }
  }

  Future<void> _loadTemplate() async {
    setState(() => _isLoading = true);
    
    try {
      final template = await _templateService.getTemplateForLogType(widget.logType);
      
      if (template == null) {
        throw Exception('No template found for log type: ${widget.logType}');
      }

      setState(() {
        _template = template;
        _isLoading = false;
        
        // Initialize form data with default values
        for (final field in template.fields) {
          if (field.defaultValue != null && !_formData.containsKey(field.key)) {
            _formData[field.key] = field.defaultValue;
          }
        }
      });
    } catch (e) {
      debugPrint('Error loading template: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load template: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  void _updateFieldValue(String fieldKey, dynamic value) {
    setState(() {
      _formData[fieldKey] = value;
      // Clear error when field is updated
      _errors.remove(fieldKey);
    });
  }

  bool _validateForm() {
    if (_template == null) return false;
    
    final newErrors = <String, String>{};
    
    for (final field in _template!.fields) {
      // Skip optional fields if they're hidden
      if (field.category == FieldCategory.optional && !_showOptionalFields) {
        continue;
      }
      
      // Skip fields with unmet dependencies
      if (!_isFieldVisible(field)) {
        continue;
      }
      
      final value = _formData[field.key];
      final error = _templateService.validateField(field, value);
      
      if (error != null) {
        newErrors[field.key] = error;
      }
    }
    
    setState(() => _errors = newErrors);
    return newErrors.isEmpty;
  }

  bool _isFieldVisible(TemplateField field) {
    if (field.dependsOn == null) return true;
    
    final dependencyValue = _formData[field.dependsOn];
    final condition = field.dependencyCondition;
    
    if (condition == null) return true;
    
    if (condition['equals'] != null) {
      return dependencyValue == condition['equals'];
    }
    if (condition['notEquals'] != null) {
      return dependencyValue != condition['notEquals'];
    }
    if (condition['greaterThan'] != null) {
      return dependencyValue != null && dependencyValue > condition['greaterThan'];
    }
    
    return true;
  }

  Future<void> _saveReading() async {
    if (!_validateForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the errors before saving'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Add metadata
      _formData['hour'] = widget.hour;
      _formData['date'] = widget.selectedDate.toIso8601String();
      _formData['timestamp'] = DateTime.now().toIso8601String();
      _formData['projectId'] = widget.projectId;
      _formData['jobId'] = widget.jobId;
      _formData['logType'] = widget.logType;
      _formData['templateVersion'] = _template!.version;

      await _readingService.saveReading(
        projectId: widget.projectId,
        date: widget.selectedDate,
        hour: widget.hour,
        data: _formData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hour ${widget.hour} saved successfully'),
            backgroundColor: Colors.green.shade600,
          ),
        );
        context.pop(true); // Return true to indicate success
      }
    } catch (e) {
      debugPrint('Error saving reading: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF111111),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.orange.shade600),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading template...',
                style: GoogleFonts.orbitron(
                  color: Colors.orange.shade300,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_template == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF111111),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade400, size: 64),
              const SizedBox(height: 16),
              Text(
                'No template found for ${widget.logType}',
                style: GoogleFonts.orbitron(
                  color: Colors.red.shade300,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hour ${widget.hour} Entry',
              style: GoogleFonts.orbitron(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              _template!.name,
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: Colors.orange.shade300,
              ),
            ),
          ],
        ),
        actions: [
          // Template info button
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white70),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1E1E1E),
                  title: Text(
                    _template!.name,
                    style: GoogleFonts.orbitron(color: Colors.white),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _template!.description,
                        style: GoogleFonts.roboto(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Version: ${_template!.version}',
                        style: GoogleFonts.robotoMono(color: Colors.orange.shade300),
                      ),
                      Text(
                        'Fields: ${_template!.fields.length}',
                        style: GoogleFonts.robotoMono(color: Colors.orange.shade300),
                      ),
                      Text(
                        'Log Type: ${_template!.logType}',
                        style: GoogleFonts.robotoMono(color: Colors.orange.shade300),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Close',
                        style: TextStyle(color: Colors.orange.shade600),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: _getCompletionProgress(),
            backgroundColor: Colors.grey.shade900,
            valueColor: AlwaysStoppedAnimation(
              _getCompletionProgress() == 1.0 
                  ? Colors.green.shade600 
                  : Colors.orange.shade600,
            ),
          ),
          
          // Form content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Render sections
                ..._template!.sections.map((section) {
                  final sectionFields = _template!.getFieldsForSection(section.id);
                  
                  // Skip empty sections
                  if (sectionFields.isEmpty) return const SizedBox.shrink();
                  
                  // Check if all fields in section are hidden
                  final visibleFields = sectionFields.where(_isFieldVisible).toList();
                  if (visibleFields.isEmpty && section.id != 'additional') {
                    return const SizedBox.shrink();
                  }
                  
                  return _buildSection(section, visibleFields);
                }).toList(),
                
                // Optional fields toggle
                if (_template!.getOptionalFields().isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Card(
                    color: const Color(0xFF1E1E1E),
                    child: ListTile(
                      leading: Icon(
                        _showOptionalFields ? Icons.expand_less : Icons.expand_more,
                        color: Colors.orange.shade600,
                      ),
                      title: Text(
                        'Optional Fields',
                        style: GoogleFonts.orbitron(
                          color: Colors.orange.shade300,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        'Like feats or multiclass features',
                        style: GoogleFonts.roboto(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _showOptionalFields = !_showOptionalFields;
                        });
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              border: Border(
                top: BorderSide(color: Colors.grey.shade800),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(color: Colors.grey.shade700),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.roboto(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveReading,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(
                            'Save Hour ${widget.hour}',
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(FieldSection section, List<TemplateField> fields) {
    if (fields.isEmpty && !_showOptionalFields) return const SizedBox.shrink();
    
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 16),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: section.defaultExpanded,
          title: Text(
            section.title,
            style: GoogleFonts.orbitron(
              color: Colors.orange.shade300,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: section.description != null
              ? Text(
                  section.description!,
                  style: GoogleFonts.roboto(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                )
              : null,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: fields.map((field) {
                  // Skip optional fields if not showing them
                  if (field.category == FieldCategory.optional && !_showOptionalFields) {
                    return const SizedBox.shrink();
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: DynamicFieldBuilder(
                      field: field,
                      value: _formData[field.key],
                      onChanged: (value) => _updateFieldValue(field.key, value),
                      errorText: _errors[field.key],
                      enabled: !_isSaving,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getCompletionProgress() {
    if (_template == null) return 0.0;
    
    int requiredFields = 0;
    int completedFields = 0;
    
    for (final field in _template!.fields) {
      if (field.validation.required && _isFieldVisible(field)) {
        requiredFields++;
        if (_formData[field.key] != null && 
            _formData[field.key].toString().isNotEmpty) {
          completedFields++;
        }
      }
    }
    
    if (requiredFields == 0) return 1.0;
    return completedFields / requiredFields;
  }
}