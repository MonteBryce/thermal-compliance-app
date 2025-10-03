import 'package:flutter/material.dart';
import '../models/log_template.dart';
import '../services/excel_template_selection_service.dart';

class ExcelTemplateSelector extends StatefulWidget {
  final LogType initialLogType;
  final ExcelTemplateConfig? initialTemplate;
  final Function(ExcelTemplateConfig?) onTemplateSelected;
  final Function(LogType) onLogTypeChanged;
  final bool showLogTypeSelector;

  const ExcelTemplateSelector({
    super.key,
    required this.initialLogType,
    this.initialTemplate,
    required this.onTemplateSelected,
    required this.onLogTypeChanged,
    this.showLogTypeSelector = true,
  });

  @override
  State<ExcelTemplateSelector> createState() => _ExcelTemplateSelectorState();
}

class _ExcelTemplateSelectorState extends State<ExcelTemplateSelector> {
  final ExcelTemplateSelectionService _templateService = ExcelTemplateSelectionService();
  
  LogType _selectedLogType = LogType.thermal;
  ExcelTemplateConfig? _selectedTemplate;
  List<ExcelTemplateConfig> _availableTemplates = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedLogType = widget.initialLogType;
    _selectedTemplate = widget.initialTemplate;
    _loadTemplatesForLogType();
  }

  Future<void> _loadTemplatesForLogType() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final templates = await _templateService.getTemplatesForLogType(_selectedLogType);
      setState(() {
        _availableTemplates = templates;
        _isLoading = false;
        
        // Auto-select recommended template if none selected
        if (_selectedTemplate == null && templates.isNotEmpty) {
          _selectedTemplate = templates.first;
          widget.onTemplateSelected(_selectedTemplate);
        }
        
        // Clear selection if current template is not compatible
        if (_selectedTemplate != null && 
            !templates.any((t) => t.id == _selectedTemplate!.id)) {
          _selectedTemplate = null;
          widget.onTemplateSelected(null);
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load templates: $e';
      });
    }
  }

  void _onLogTypeChanged(LogType? newLogType) {
    if (newLogType != null && newLogType != _selectedLogType) {
      setState(() {
        _selectedLogType = newLogType;
        _selectedTemplate = null;
      });
      widget.onLogTypeChanged(newLogType);
      widget.onTemplateSelected(null);
      _loadTemplatesForLogType();
    }
  }

  void _onTemplateChanged(ExcelTemplateConfig? template) {
    setState(() {
      _selectedTemplate = template;
    });
    widget.onTemplateSelected(template);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.article_outlined, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Excel Template Configuration',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Log Type Selector
            if (widget.showLogTypeSelector) ...[
              Text(
                'Log Type',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<LogType>(
                value: _selectedLogType,
                onChanged: _onLogTypeChanged,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: LogType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Template Selector
            Text(
              'Excel Export Template',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              )
            else if (_availableTemplates.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No Excel templates available for ${_selectedLogType.displayName}',
                        style: TextStyle(color: Colors.orange.shade700),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              DropdownButtonFormField<ExcelTemplateConfig>(
                value: _selectedTemplate,
                onChanged: _onTemplateChanged,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  hintText: 'Select an Excel template...',
                ),
                items: [
                  const DropdownMenuItem<ExcelTemplateConfig>(
                    value: null,
                    child: Text('No Excel export (Flutter forms only)'),
                  ),
                  ..._availableTemplates.map((template) {
                    return DropdownMenuItem(
                      value: template,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            template.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          if (template.description.isNotEmpty)
                            Text(
                              template.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),

              // Template Details
              if (_selectedTemplate != null) ...[
                const SizedBox(height: 16),
                _buildTemplateDetails(_selectedTemplate!),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateDetails(ExcelTemplateConfig template) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 16),
              const SizedBox(width: 6),
              Text(
                'Template Details',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          _buildDetailRow('Template File:', template.excelTemplatePath.split('/').last),
          _buildDetailRow('Required Fields:', '${template.requiredFields.length} fields'),
          _buildDetailRow('Compatible Types:', template.compatibleLogTypes.map((t) => t.displayName).join(', ')),
          
          if (template.validationRules.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Validation Rules:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.blue.shade700,
                fontSize: 12,
              ),
            ),
            ...template.validationRules.entries.map((entry) {
              final rules = entry.value as Map<String, dynamic>;
              final ruleText = [
                if (rules['min'] != null) 'min: ${rules['min']}',
                if (rules['max'] != null) 'max: ${rules['max']}',
              ].join(', ');
              
              return Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Text(
                  '• ${entry.key}: $ruleText',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue.shade600,
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.blue.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}