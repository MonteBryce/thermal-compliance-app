import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/log_template.dart';
import '../models/hive_models.dart';
import '../services/local_database_service.dart';
import '../services/auth_service.dart';
import '../services/validation_initialization.dart';
import '../services/form_state_service.dart';
import '../widgets/enhanced_form_field.dart';

class DailyMetricsFormScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String projectName;
  final DateTime selectedDate;
  final String? existingEntryId;

  const DailyMetricsFormScreen({
    Key? key,
    required this.projectId,
    required this.projectName,
    required this.selectedDate,
    this.existingEntryId,
  }) : super(key: key);

  @override
  ConsumerState<DailyMetricsFormScreen> createState() => _DailyMetricsFormScreenState();
}

class _DailyMetricsFormScreenState extends ConsumerState<DailyMetricsFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  final _formValues = <String, dynamic>{};
  final _validationResults = <String, ValidationResult>{};
  
  LogTemplate? _template;
  LogEntry? _existingEntry;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _initializeValidation();
    _loadTemplate();
    if (widget.existingEntryId != null) {
      _loadExistingEntry();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeValidation() {
    ValidationInitialization.initialize();
  }

  Future<void> _loadTemplate() async {
    try {
      setState(() => _isLoading = true);
      
      // For daily metrics, use a specialized template
      final template = LogTemplateRegistry.getTemplate(LogType.dailyMetrics);
      setState(() {
        _template = template;
        _initializeFormData();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _saveError = 'Failed to load daily metrics template: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadExistingEntry() async {
    if (widget.existingEntryId == null) return;
    
    try {
      final entry = await LocalDatabaseService.getLogEntry(widget.existingEntryId!);
      if (entry != null) {
        setState(() {
          _existingEntry = entry;
          _populateFormWithEntry(entry);
        });
      }
    } catch (e) {
      setState(() => _saveError = 'Failed to load existing entry: $e');
    }
  }

  void _initializeFormData() {
    if (_template == null) return;
    
    for (final field in _template!.fields) {
      _controllers[field.id] = TextEditingController();
      _controllers[field.id]!.addListener(() => _onFieldChanged(field.id));
      _formValues[field.id] = field.defaultValue ?? '';
    }
  }

  void _populateFormWithEntry(LogEntry entry) {
    for (final fieldId in entry.data.keys) {
      final value = entry.data[fieldId];
      if (_controllers.containsKey(fieldId)) {
        _controllers[fieldId]!.text = value?.toString() ?? '';
        _formValues[fieldId] = value;
      }
    }
    _validateAllFields();
  }

  void _onFieldChanged(String fieldId) {
    final value = _controllers[fieldId]?.text ?? '';
    setState(() {
      _formValues[fieldId] = value;
      _hasUnsavedChanges = true;
    });
    _validateField(fieldId);
    _autoSaveProgress();
  }

  void _validateField(String fieldId) {
    final field = _template?.fields.firstWhere((f) => f.id == fieldId);
    if (field == null) return;

    final result = field.validate(_formValues[fieldId], _formValues);
    setState(() {
      _validationResults[fieldId] = ValidationResult(
        isValid: result == null,
        errors: result != null ? [result] : [],
        warnings: _getFieldWarnings(field, _formValues[fieldId]),
      );
    });
  }

  List<String> _getFieldWarnings(LogFieldTemplate field, dynamic value) {
    final warning = field.getWarning(value, _formValues);
    return warning != null ? [warning] : [];
  }

  void _validateAllFields() {
    if (_template == null) return;
    
    for (final field in _template!.fields) {
      _validateField(field.id);
    }
  }

  bool get _isFormValid {
    return _validationResults.values.every((result) => result.isValid);
  }

  bool get _hasWarnings {
    return _validationResults.values.any((result) => result.warnings.isNotEmpty);
  }

  Future<void> _autoSaveProgress() async {
    if (_hasUnsavedChanges && _isFormValid) {
      try {
        await _saveFormProgress();
      } catch (e) {
        debugPrint('Auto-save failed: $e');
      }
    }
  }

  Future<void> _saveFormProgress() async {
    final dateString = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
    
    await FormStateService.saveFormProgress(
      projectId: widget.projectId,
      projectName: widget.projectName,
      date: dateString,
      formType: 'dailymetrics',
      formData: _formValues,
      userId: AuthService.getCurrentUserId() ?? 'unknown',
      existingEntryId: widget.existingEntryId,
    );
  }

  Future<void> _submitForm() async {
    if (!_isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix validation errors before submitting'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    
    try {
      final dateString = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
      final entryId = widget.existingEntryId ?? 
          'daily_metrics_${widget.projectId}_$dateString';
      
      final logEntry = LogEntry(
        id: entryId,
        projectId: widget.projectId,
        projectName: widget.projectName,
        date: dateString,
        hour: '0', // Daily metrics use hour 0
        data: Map.from(_formValues),
        status: 'completed',
        createdAt: _existingEntry?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: AuthService.getCurrentUserId() ?? 'unknown',
        isSynced: false,
      );
      
      await LocalDatabaseService.saveLogEntry(logEntry);
      
      setState(() {
        _hasUnsavedChanges = false;
        _isSaving = false;
      });
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Daily metrics saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        context.pop();
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _saveError = 'Failed to save daily metrics: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMMM d, yyyy');
    
    return WillPopScope(
      onWillPop: () async {
        if (_hasUnsavedChanges) {
          final shouldPop = await _showUnsavedChangesDialog();
          return shouldPop ?? false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daily System Metrics',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              Text(
                '${widget.projectName} - ${dateFormat.format(widget.selectedDate)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimary.withOpacity(0.8),
                ),
              ),
            ],
          ),
          backgroundColor: theme.colorScheme.secondary,
          foregroundColor: theme.colorScheme.onSecondary,
          actions: [
            if (_hasUnsavedChanges)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Unsaved',
                      style: TextStyle(
                        color: Colors.orange[100],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildFormBody(),
        bottomNavigationBar: _buildBottomActions(),
      ),
    );
  }

  Widget _buildFormBody() {
    if (_template == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Failed to load daily metrics template', 
                style: Theme.of(context).textTheme.titleLarge),
            if (_saveError != null) ...[ 
              const SizedBox(height: 8),
              Text(_saveError!, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ],
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMetricsHeader(),
          const SizedBox(height: 16),
          
          if (!_isFormValid || _hasWarnings) _buildValidationSummary(),
          
          ..._template!.sections.entries.map((section) => 
            _buildFormSection(section.key, section.value)),
          
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildMetricsHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'System Overview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Record daily system metrics including total runtime, energy consumption, maintenance activities, and overall system performance.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationSummary() {
    final errorCount = _validationResults.values
        .where((result) => !result.isValid)
        .length;
    final warningCount = _validationResults.values
        .where((result) => result.warnings.isNotEmpty)
        .length;

    if (errorCount == 0 && warningCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: errorCount > 0 ? Colors.red[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: errorCount > 0 ? Colors.red[300]! : Colors.orange[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                errorCount > 0 ? Icons.error : Icons.warning,
                color: errorCount > 0 ? Colors.red[600] : Colors.orange[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                errorCount > 0 
                    ? '$errorCount field${errorCount == 1 ? '' : 's'} need${errorCount == 1 ? 's' : ''} attention'
                    : '$warningCount warning${warningCount == 1 ? '' : 's'}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: errorCount > 0 ? Colors.red[800] : Colors.orange[800],
                ),
              ),
            ],
          ),
          if (errorCount > 0) ...[ 
            const SizedBox(height: 8),
            Text(
              'Please fix the errors below before submitting.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red[700],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormSection(String sectionName, List<LogFieldTemplate> fields) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sectionName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...fields.map((field) => _buildFormField(field)),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField(LogFieldTemplate field) {
    final validationResult = _validationResults[field.id];
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: EnhancedFormField(
        field: field,
        controller: _controllers[field.id]!,
        validationResult: validationResult,
        onChanged: (value) => _onFieldChanged(field.id),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isSaving ? null : () => _saveFormProgress(),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Draft'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: (_isSaving || !_isFormValid) ? null : _submitForm,
              icon: _isSaving 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle),
              label: Text(_isSaving ? 'Saving...' : 'Submit Daily Metrics'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFormValid 
                    ? Theme.of(context).colorScheme.secondary 
                    : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showUnsavedChangesDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes in your daily metrics. Do you want to save them before leaving?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(false);
              await _saveFormProgress();
            },
            child: const Text('Save Draft'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continue Editing'),
          ),
        ],
      ),
    );
  }
}