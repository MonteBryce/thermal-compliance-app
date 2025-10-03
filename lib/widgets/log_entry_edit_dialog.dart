import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/hive_models.dart';
import '../providers/daily_summary_providers.dart';

class LogEntryEditDialog extends ConsumerStatefulWidget {
  final LogEntry entry;

  const LogEntryEditDialog({
    Key? key,
    required this.entry,
  }) : super(key: key);

  @override
  ConsumerState<LogEntryEditDialog> createState() => _LogEntryEditDialogState();
}

class _LogEntryEditDialogState extends ConsumerState<LogEntryEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = false;
  String _selectedStatus = 'pending';

  @override
  void initState() {
    super.initState();
    
    // Initialize edit state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(logEntryEditProvider.notifier).startEdit(widget.entry);
    });
    
    // Initialize controllers for all data fields
    _selectedStatus = widget.entry.status;
    for (final key in widget.entry.data.keys) {
      _controllers[key] = TextEditingController(
        text: _formatValueForEditing(widget.entry.data[key]),
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _formatValueForEditing(dynamic value) {
    if (value == null) return '';
    if (value is num) return value.toString();
    if (value is bool) return value.toString();
    return value.toString();
  }

  dynamic _parseValue(String text, dynamic originalValue) {
    if (text.isEmpty) return null;
    
    // Try to maintain the original type
    if (originalValue is int) {
      return int.tryParse(text) ?? text;
    } else if (originalValue is double) {
      return double.tryParse(text) ?? text;
    } else if (originalValue is bool) {
      return text.toLowerCase() == 'true';
    }
    
    // Auto-detect numeric values
    if (double.tryParse(text) != null) {
      final doubleValue = double.parse(text);
      if (doubleValue == doubleValue.toInt()) {
        return doubleValue.toInt();
      }
      return doubleValue;
    }
    
    return text;
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(logEntryEditProvider.notifier);
      
      // Update all field values
      for (final entry in _controllers.entries) {
        final key = entry.key;
        final text = entry.value.text;
        final originalValue = widget.entry.data[key];
        final newValue = _parseValue(text, originalValue);
        
        notifier.updateField(key, newValue);
      }
      
      // Update status if changed
      final currentEntry = ref.read(logEntryEditProvider);
      if (currentEntry != null && currentEntry.status != _selectedStatus) {
        notifier.updateField('status', _selectedStatus);
        // Update the entry's status field directly
        final updatedEntry = LogEntry(
          id: currentEntry.id,
          projectId: currentEntry.projectId,
          projectName: currentEntry.projectName,
          date: currentEntry.date,
          hour: currentEntry.hour,
          data: currentEntry.data,
          status: _selectedStatus,
          createdAt: currentEntry.createdAt,
          updatedAt: DateTime.now(),
          createdBy: currentEntry.createdBy,
          isSynced: false,
          syncError: currentEntry.syncError,
        );
        // Update state through proper method
        final notifier = ref.read(logEntryEditProvider.notifier);
        notifier.cancelEdit();
        notifier.startEdit(updatedEntry);
      }

      // Save the changes
      final success = await notifier.saveEdit();
      
      if (success) {
        if (mounted) {
          Navigator.of(context).pop(true); // Return true to indicate success
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Log entry updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save changes'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _cancelEdit() {
    ref.read(logEntryEditProvider.notifier).cancelEdit();
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = widget.entry;
    // Format entry information for display

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.edit,
                    color: theme.colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Log Entry',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${entry.projectName} - ${entry.hour}:00',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimary.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Form content
            Expanded(
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Status dropdown
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedStatus,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                                DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                                DropdownMenuItem(value: 'completed', child: Text('Completed')),
                                DropdownMenuItem(value: 'draft', child: Text('Draft')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedStatus = value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Data fields
                      Expanded(
                        child: ListView.builder(
                          itemCount: entry.data.length,
                          itemBuilder: (context, index) {
                            final key = entry.data.keys.elementAt(index);
                            final value = entry.data[key];
                            final controller = _controllers[key]!;
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: TextFormField(
                                controller: controller,
                                decoration: InputDecoration(
                                  labelText: _formatFieldName(key),
                                  border: const OutlineInputBorder(),
                                  helperText: 'Original type: ${value.runtimeType}',
                                ),
                                keyboardType: _getKeyboardType(value),
                                inputFormatters: _getInputFormatters(value),
                                validator: (text) {
                                  if (text == null || text.isEmpty) {
                                    return null; // Allow empty values
                                  }
                                  
                                  // Validate numeric fields
                                  if (value is num) {
                                    if (value is int && int.tryParse(text) == null) {
                                      return 'Must be a valid integer';
                                    } else if (value is double && double.tryParse(text) == null) {
                                      return 'Must be a valid number';
                                    }
                                  }
                                  
                                  return null;
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Footer buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : _cancelEdit,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Changes'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFieldName(String key) {
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ')
        .trim();
  }

  TextInputType _getKeyboardType(dynamic value) {
    if (value is int) return TextInputType.number;
    if (value is double) return const TextInputType.numberWithOptions(decimal: true);
    return TextInputType.text;
  }

  List<TextInputFormatter> _getInputFormatters(dynamic value) {
    if (value is int) {
      return [FilteringTextInputFormatter.digitsOnly];
    } else if (value is double) {
      return [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))];
    }
    return [];
  }
}