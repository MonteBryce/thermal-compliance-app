import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

// Data Model
class SystemMetrics {
  final String date;
  final String systemStartTime;
  final String systemStopTime;
  final double totalRuntime;
  final double? avgTemperature;
  final double? maxTemperature;
  final double? minTemperature;
  final double? avgPressure;
  final double? fuelConsumption;
  final double? powerConsumption;
  final bool maintenancePerformed;
  final String maintenanceNotes;
  final SystemStatus systemStatus;
  final String operatorSignature;
  final bool supervisorApproval;

  SystemMetrics({
    required this.date,
    required this.systemStartTime,
    required this.systemStopTime,
    required this.totalRuntime,
    this.avgTemperature,
    this.maxTemperature,
    this.minTemperature,
    this.avgPressure,
    this.fuelConsumption,
    this.powerConsumption,
    this.maintenancePerformed = false,
    this.maintenanceNotes = '',
    this.systemStatus = SystemStatus.optimal,
    this.operatorSignature = '',
    this.supervisorApproval = false,
  });

  factory SystemMetrics.fromJson(Map<String, dynamic> json) {
    return SystemMetrics(
      date: json['date'],
      systemStartTime: json['systemStartTime'],
      systemStopTime: json['systemStopTime'],
      totalRuntime: json['totalRuntime'].toDouble(),
      avgTemperature: json['avgTemperature']?.toDouble(),
      maxTemperature: json['maxTemperature']?.toDouble(),
      minTemperature: json['minTemperature']?.toDouble(),
      avgPressure: json['avgPressure']?.toDouble(),
      fuelConsumption: json['fuelConsumption']?.toDouble(),
      powerConsumption: json['powerConsumption']?.toDouble(),
      maintenancePerformed: json['maintenancePerformed'] ?? false,
      maintenanceNotes: json['maintenanceNotes'] ?? '',
      systemStatus: SystemStatus.values.firstWhere(
        (e) => e.name == json['systemStatus'],
        orElse: () => SystemStatus.optimal,
      ),
      operatorSignature: json['operatorSignature'] ?? '',
      supervisorApproval: json['supervisorApproval'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'systemStartTime': systemStartTime,
      'systemStopTime': systemStopTime,
      'totalRuntime': totalRuntime,
      'avgTemperature': avgTemperature,
      'maxTemperature': maxTemperature,
      'minTemperature': minTemperature,
      'avgPressure': avgPressure,
      'fuelConsumption': fuelConsumption,
      'powerConsumption': powerConsumption,
      'maintenancePerformed': maintenancePerformed,
      'maintenanceNotes': maintenanceNotes,
      'systemStatus': systemStatus.name,
      'operatorSignature': operatorSignature,
      'supervisorApproval': supervisorApproval,
    };
  }
}

enum SystemStatus {
  optimal('Optimal - All systems normal'),
  warning('Warning - Minor issues detected'),
  critical('Critical - Immediate attention required');

  const SystemStatus(this.displayName);
  final String displayName;
}

class SystemMetricsScreen extends StatefulWidget {
  const SystemMetricsScreen({super.key});

  @override
  State<SystemMetricsScreen> createState() => _SystemMetricsScreenState();
}

class _SystemMetricsScreenState extends State<SystemMetricsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Controllers for form fields
  late TextEditingController _systemStartTimeController;
  late TextEditingController _systemStopTimeController;
  late TextEditingController _totalRuntimeController;
  late TextEditingController _avgTemperatureController;
  late TextEditingController _maxTemperatureController;
  late TextEditingController _minTemperatureController;
  late TextEditingController _avgPressureController;
  late TextEditingController _fuelConsumptionController;
  late TextEditingController _powerConsumptionController;
  late TextEditingController _maintenanceNotesController;
  late TextEditingController _operatorSignatureController;

  // Form state variables
  SystemStatus _systemStatus = SystemStatus.optimal;
  bool _maintenancePerformed = false;
  bool _supervisorApproval = false;
  String _selectedDate = '';

  SystemMetrics? existingData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    existingData = args?['existingData'] as SystemMetrics?;
    _initializeControllers();
    _setInitialDate();
  }

  void _initializeControllers() {
    final data = existingData;

    _systemStartTimeController = TextEditingController(
      text: data?.systemStartTime ?? '',
    );
    _systemStopTimeController = TextEditingController(
      text: data?.systemStopTime ?? '',
    );
    _totalRuntimeController = TextEditingController(
      text: data?.totalRuntime.toString() ?? '0',
    );
    _avgTemperatureController = TextEditingController(
      text: data?.avgTemperature?.toString() ?? '',
    );
    _maxTemperatureController = TextEditingController(
      text: data?.maxTemperature?.toString() ?? '',
    );
    _minTemperatureController = TextEditingController(
      text: data?.minTemperature?.toString() ?? '',
    );
    _avgPressureController = TextEditingController(
      text: data?.avgPressure?.toString() ?? '',
    );
    _fuelConsumptionController = TextEditingController(
      text: data?.fuelConsumption?.toString() ?? '',
    );
    _powerConsumptionController = TextEditingController(
      text: data?.powerConsumption?.toString() ?? '',
    );
    _maintenanceNotesController = TextEditingController(
      text: data?.maintenanceNotes ?? '',
    );
    _operatorSignatureController = TextEditingController(
      text: data?.operatorSignature ?? '',
    );

    // Set initial state
    if (data != null) {
      _systemStatus = data.systemStatus;
      _maintenancePerformed = data.maintenancePerformed;
      _supervisorApproval = data.supervisorApproval;
      _selectedDate = data.date;
    }

    // Add listeners for runtime calculation
    _systemStartTimeController.addListener(_calculateRuntime);
    _systemStopTimeController.addListener(_calculateRuntime);
  }

  void _setInitialDate() {
    if (existingData?.date != null) {
      _selectedDate = existingData!.date;
    } else {
      _selectedDate = DateTime.now().toIso8601String().split('T')[0];
    }
  }

  @override
  void dispose() {
    _systemStartTimeController.dispose();
    _systemStopTimeController.dispose();
    _totalRuntimeController.dispose();
    _avgTemperatureController.dispose();
    _maxTemperatureController.dispose();
    _minTemperatureController.dispose();
    _avgPressureController.dispose();
    _fuelConsumptionController.dispose();
    _powerConsumptionController.dispose();
    _maintenanceNotesController.dispose();
    _operatorSignatureController.dispose();
    super.dispose();
  }

  void _calculateRuntime() {
    final startTimeText = _systemStartTimeController.text;
    final stopTimeText = _systemStopTimeController.text;

    if (startTimeText.isNotEmpty && stopTimeText.isNotEmpty) {
      try {
        final startTime = _parseTimeString(startTimeText);
        final stopTime = _parseTimeString(stopTimeText);

        if (startTime != null && stopTime != null) {
          double runtime = stopTime.difference(startTime).inMinutes / 60.0;
          if (runtime < 0) runtime += 24; // Handle overnight shifts

          _totalRuntimeController.text = runtime.toStringAsFixed(1);
        }
      } catch (e) {
        // Handle parsing errors silently
      }
    }
  }

  DateTime? _parseTimeString(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return DateTime(2000, 1, 1, hour, minute);
      }
    } catch (e) {
      // Invalid time format
    }
    return null;
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // Check for critical status without supervisor approval
    if (_systemStatus == SystemStatus.critical && !_supervisorApproval) {
      _showErrorDialog(
          'Critical status requires supervisor approval before submission.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    final systemMetrics = SystemMetrics(
      date: _selectedDate,
      systemStartTime: _systemStartTimeController.text,
      systemStopTime: _systemStopTimeController.text,
      totalRuntime: double.tryParse(_totalRuntimeController.text) ?? 0,
      avgTemperature: double.tryParse(_avgTemperatureController.text),
      maxTemperature: double.tryParse(_maxTemperatureController.text),
      minTemperature: double.tryParse(_minTemperatureController.text),
      avgPressure: double.tryParse(_avgPressureController.text),
      fuelConsumption: double.tryParse(_fuelConsumptionController.text),
      powerConsumption: double.tryParse(_powerConsumptionController.text),
      maintenancePerformed: _maintenancePerformed,
      maintenanceNotes: _maintenanceNotesController.text,
      systemStatus: _systemStatus,
      operatorSignature: _operatorSignatureController.text,
      supervisorApproval: _supervisorApproval,
    );

    Navigator.pop(context, systemMetrics);

    setState(() {
      _isSaving = false;
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text(
          'Validation Error',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Color(0xFF9CA3AF)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectTime(
      BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF2563EB),
              surface: Color(0xFF1F2937),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedTime =
          "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      controller.text = formattedTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Metrics Entry',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Daily system performance and compliance data',
              style: TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Chip(
              label: Text(
                existingData != null ? 'Editing' : 'New Entry',
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: existingData != null
                  ? const Color(0xFF374151)
                  : const Color(0xFF1F2937),
              labelStyle: TextStyle(
                color: existingData != null
                    ? const Color(0xFF9CA3AF)
                    : Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Operation Hours Section
              _buildSectionCard(
                title: 'Operation Hours',
                icon: Icons.access_time,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeField(
                          label: 'System Start Time',
                          controller: _systemStartTimeController,
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Start time is required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTimeField(
                          label: 'System Stop Time',
                          controller: _systemStopTimeController,
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Stop time is required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildNumberField(
                    label: 'Total Runtime (hours)',
                    controller: _totalRuntimeController,
                    readOnly: true,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Runtime is required';
                      final num = double.tryParse(value!);
                      if (num == null || num < 0) {
                        return 'Runtime cannot be negative';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Temperature Summary Section
              _buildSectionCard(
                title: 'Temperature Summary',
                icon: Icons.thermostat,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildNumberField(
                          label: 'Average Temperature (°F)',
                          controller: _avgTemperatureController,
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Average temperature is required';
                            }
                            final num = double.tryParse(value!);
                            if (num == null || num < 0) {
                              return 'Temperature cannot be negative';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildNumberField(
                          label: 'Maximum Temperature (°F)',
                          controller: _maxTemperatureController,
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Maximum temperature is required';
                            }
                            final num = double.tryParse(value!);
                            if (num == null || num < 0) {
                              return 'Temperature cannot be negative';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildNumberField(
                    label: 'Minimum Temperature (°F)',
                    controller: _minTemperatureController,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Minimum temperature is required';
                      }
                      final num = double.tryParse(value!);
                      if (num == null || num < 0) {
                        return 'Temperature cannot be negative';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Performance Metrics Section
              _buildSectionCard(
                title: 'Performance Metrics',
                icon: Icons.settings,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildNumberField(
                          label: 'Average Pressure (PSI)',
                          controller: _avgPressureController,
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Average pressure is required';
                            }
                            final num = double.tryParse(value!);
                            if (num == null || num < 0) {
                              return 'Pressure cannot be negative';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildNumberField(
                          label: 'Fuel Consumption (gallons)',
                          controller: _fuelConsumptionController,
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Fuel consumption is required';
                            }
                            final num = double.tryParse(value!);
                            if (num == null || num < 0) {
                              return 'Consumption cannot be negative';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildNumberField(
                    label: 'Power Consumption (kWh)',
                    controller: _powerConsumptionController,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Power consumption is required';
                      }
                      final num = double.tryParse(value!);
                      if (num == null || num < 0) {
                        return 'Consumption cannot be negative';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // System Status & Maintenance Section
              _buildSectionCard(
                title: 'System Status & Maintenance',
                icon: Icons.build,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overall System Status',
                        style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F2937),
                          border: Border.all(color: const Color(0xFF374151)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonFormField<SystemStatus>(
                          value: _systemStatus,
                          onChanged: (SystemStatus? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _systemStatus = newValue;
                              });
                            }
                          },
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 16),
                          ),
                          dropdownColor: const Color(0xFF1F2937),
                          style: const TextStyle(color: Colors.white),
                          items: SystemStatus.values
                              .map<DropdownMenuItem<SystemStatus>>(
                                  (SystemStatus status) {
                            return DropdownMenuItem<SystemStatus>(
                              value: status,
                              child: Text(status.displayName),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: _maintenancePerformed,
                        onChanged: (bool? value) {
                          setState(() {
                            _maintenancePerformed = value ?? false;
                          });
                        },
                        activeColor: const Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Maintenance performed during this shift',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  if (_maintenancePerformed) ...[
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Maintenance Notes',
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _maintenanceNotesController,
                          maxLines: 4,
                          style: const TextStyle(color: Colors.white),
                          validator: _maintenancePerformed
                              ? (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'Maintenance notes are required when maintenance is performed';
                                  }
                                  return null;
                                }
                              : null,
                          decoration: InputDecoration(
                            hintText:
                                'Describe maintenance activities performed...',
                            hintStyle:
                                const TextStyle(color: Color(0xFF6B7280)),
                            filled: true,
                            fillColor: const Color(0xFF1F2937),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFF374151)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFF374151)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFF2563EB)),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFFEF4444)),
                            ),
                            errorStyle: const TextStyle(
                                color: Color(0xFFEF4444), fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 24),

              // Signatures & Approval Section
              _buildSectionCard(
                title: 'Signatures & Approval',
                icon: Icons.check_circle,
                children: [
                  _buildTextField(
                    label: 'Operator Signature',
                    controller: _operatorSignatureController,
                    hintText: 'Type your full name',
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Operator signature is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: _supervisorApproval,
                        onChanged: (bool? value) {
                          setState(() {
                            _supervisorApproval = value ?? false;
                          });
                        },
                        activeColor: const Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Supervisor approval received',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  if (_systemStatus == SystemStatus.critical) ...[
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.1),
                        border: Border.all(
                            color: const Color(0xFFEF4444).withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning,
                                  color: Color(0xFFF87171), size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Critical Status Alert',
                                style: TextStyle(
                                  color: Color(0xFFF87171),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'This entry indicates critical system status. Supervisor approval is required before submission.',
                            style: TextStyle(
                              color: Color(0xFFF87171),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 32),

              // Form Actions
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF4B5563)),
                        foregroundColor: const Color(0xFF9CA3AF),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: (_isSaving ||
                              (_systemStatus == SystemStatus.critical &&
                                  !_supervisorApproval))
                          ? null
                          : _onSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        disabledBackgroundColor: const Color(0xFF374151),
                      ),
                      child: _isSaving
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Saving...'),
                              ],
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save, size: 16),
                                SizedBox(width: 8),
                                Text('Save Metrics'),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        border: Border.all(color: const Color(0xFF374151)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF374151)),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF10B981), size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
          ],
          style: const TextStyle(color: Colors.white),
          readOnly: readOnly,
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor:
                readOnly ? const Color(0xFF374151) : const Color(0xFF1F2937),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF374151)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF374151)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2563EB)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            errorStyle: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Color(0xFF6B7280)),
            filled: true,
            fillColor: const Color(0xFF1F2937),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF374151)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF374151)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2563EB)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            errorStyle: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          readOnly: true,
          validator: validator,
          onTap: () => _selectTime(context, controller),
          decoration: InputDecoration(
            hintText: 'Select time',
            hintStyle: const TextStyle(color: Color(0xFF6B7280)),
            filled: true,
            fillColor: const Color(0xFF1F2937),
            suffixIcon: const Icon(Icons.access_time, color: Color(0xFF9CA3AF)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF374151)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF374151)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2563EB)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            errorStyle: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
          ),
        ),
      ],
    );
  }
}
