import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/thermal_log.dart';
import '../services/thermal_log_service.dart';
import '../services/thermal_log_firestore_service.dart';
import '../services/auth_service.dart';

class ThermalLogEntryScreen extends StatefulWidget {
  final String projectId;
  final ThermalLog? existingLog;

  const ThermalLogEntryScreen({
    super.key,
    required this.projectId,
    this.existingLog,
  });

  @override
  State<ThermalLogEntryScreen> createState() => _ThermalLogEntryScreenState();
}

class _ThermalLogEntryScreenState extends State<ThermalLogEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _temperatureController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  late DateTime _selectedTimestamp;

  @override
  void initState() {
    super.initState();
    _selectedTimestamp = DateTime.now();

    // Pre-fill form if editing existing log
    if (widget.existingLog != null) {
      _temperatureController.text = widget.existingLog!.temperature.toString();
      _notesController.text = widget.existingLog!.notes;
      _selectedTimestamp = widget.existingLog!.timestamp;
    }
  }

  @override
  void dispose() {
    _temperatureController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedTimestamp,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedTimestamp),
      );

      if (time != null && mounted) {
        setState(() {
          _selectedTimestamp = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _saveThermalLog() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final temperature = double.parse(_temperatureController.text);
      final notes = _notesController.text.trim();
      final now = DateTime.now();

      final thermalLog = widget.existingLog?.copyWith(
        temperature: temperature,
        notes: notes,
        timestamp: _selectedTimestamp,
        updatedAt: now,
      ) ?? ThermalLog(
        id: 'thermal_${now.millisecondsSinceEpoch}',
        timestamp: _selectedTimestamp,
        temperature: temperature,
        notes: notes,
        projectId: widget.projectId,
        createdAt: now,
        updatedAt: now,
      );

      // Save locally (Hive)
      await ThermalLogService.save(thermalLog);

      // Save to cloud (Firestore) if authenticated
      if (AuthService.isAuthenticated) {
        try {
          if (widget.existingLog != null) {
            await ThermalLogFirestoreService.update(thermalLog);
          } else {
            await ThermalLogFirestoreService.create(thermalLog);
          }
        } catch (e) {
          // Firestore save failed, but local save succeeded
          print('Firestore save failed (offline?): $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Saved locally - will sync when online'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingLog != null
                ? 'Thermal log updated successfully'
                : 'Thermal log saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(thermalLog);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving thermal log: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingLog != null
            ? 'Edit Thermal Log'
            : 'New Thermal Log'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Project Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Project Information',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('Project ID: ${widget.projectId}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Timestamp Selection
              Card(
                child: ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('Reading Time'),
                  subtitle: Text(
                    '${_selectedTimestamp.toLocal().toString().split('.')[0]}',
                  ),
                  trailing: const Icon(Icons.edit),
                  onTap: _selectDateTime,
                ),
              ),
              const SizedBox(height: 16),

              // Temperature Input
              TextFormField(
                controller: _temperatureController,
                decoration: const InputDecoration(
                  labelText: 'Temperature (°F)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.thermostat),
                  helperText: 'Enter temperature reading in Fahrenheit',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a temperature';
                  }
                  final temp = double.tryParse(value);
                  if (temp == null) {
                    return 'Please enter a valid number';
                  }
                  if (temp < -100 || temp > 1000) {
                    return 'Temperature must be between -100°F and 1000°F';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Notes Input
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                  helperText: 'Additional observations or comments',
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _isSaving ? null : _saveThermalLog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSaving
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Saving...'),
                        ],
                      )
                    : Text(widget.existingLog != null
                        ? 'Update Thermal Log'
                        : 'Save Thermal Log'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}