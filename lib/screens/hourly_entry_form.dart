import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/log_entry_service.dart';
import '../services/thermal_reading_service.dart';
import '../models/thermal_reading.dart';

class HourlyEntryScreen extends StatefulWidget {
  final int hour;
  final ThermalReading? existingData;
  final String projectId;
  final String logId;
  final String logType;
  final Set<int> enteredHours;
  final DateTime? selectedDate;

  const HourlyEntryScreen({
    super.key,
    required this.hour,
    this.existingData,
    required this.projectId,
    required this.logId,
    required this.logType,
    required this.enteredHours,
    this.selectedDate,
  });

  @override
  State<HourlyEntryScreen> createState() => _HourlyEntryScreenState();
}

class _HourlyEntryScreenState extends State<HourlyEntryScreen> 
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _hasUnsynedEntries = false;
  bool _isDisposed = false;
  final _logEntryService = LogEntryService();
  final _thermalReadingService = ThermalReadingService();

  // Controllers for form fields
  TextEditingController? _inletReadingController;
  TextEditingController? _outletReadingController;
  TextEditingController? _toInletReadingH2SController;
  TextEditingController? _lelInletReadingController; // Marathon GBR specific
  TextEditingController? _vaporInletFlowRateFPMController;
  TextEditingController? _vaporInletFlowRateBBLController;
  TextEditingController? _tankRefillFlowRateController;
  TextEditingController? _combustionAirFlowRateController;
  TextEditingController? _vacuumAtTankVaporOutletController;
  TextEditingController? _exhaustTemperatureController;
  TextEditingController? _totalizerController;
  TextEditingController? _observationsController;

  int? hour;
  ThermalReading? existingData;
  bool _isOptionalSectionExpanded = false; // For Marathon GBR collapsible section

  int get totalHours => 24;
  int get hoursLogged => (hour != null && hour! >= 0) ? hour! : 0;
  double get progressPercentage => (hoursLogged / totalHours) * 100;
  int getMissingHoursCount() => totalHours - hoursLogged;

  Set<int> enteredHours = {};
  int selectedHour = 0;
  
  // Helper to determine if we're in edit mode
  bool get isEditMode {
    return existingData != null && (
      existingData!.inletReading != null || 
      existingData!.outletReading != null ||
      existingData!.observations.isNotEmpty ||
      existingData!.toInletReadingH2S != null ||
      existingData!.vaporInletFlowRateFPM != null ||
      existingData!.vaporInletFlowRateBBL != null ||
      existingData!.tankRefillFlowRate != null ||
      existingData!.combustionAirFlowRate != null ||
      existingData!.vacuumAtTankVaporOutlet != null ||
      existingData!.exhaustTemperature != null ||
      existingData!.totalizer != null
    );
  }

  @override
  void initState() {
    super.initState();
    
    // Initialize widget data
    selectedHour = widget.hour;
    existingData = widget.existingData;
    enteredHours = widget.enteredHours;
    
    // Initialize controllers immediately to prevent LateInitializationError
    _initializeControllers();
    
    // Debug logging for initialization
    debugPrint('🚀 HourlyEntryScreen initState');
    debugPrint('📊 Selected hour: $selectedHour');  
    debugPrint('📊 Widget existing data: ${widget.existingData?.toJson()}');
    debugPrint('📊 Entered hours: $enteredHours');
    
    _checkSyncStatus();
  }

  Future<void> _checkSyncStatus() async {
    final hasUnsyned = await _thermalReadingService.hasUnsyncedEntries();
    if (mounted && hasUnsyned != _hasUnsynedEntries) {
      setState(() {
        _hasUnsynedEntries = hasUnsyned;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAndInitialize();
  }

  Future<void> _loadAndInitialize() async {
    // If we don't have existing data or the data is empty, try to load from Firestore
    final hasData = existingData != null && 
        (existingData!.inletReading != null || 
         existingData!.outletReading != null ||
         existingData!.observations.isNotEmpty);
    
    if (!hasData) {
      debugPrint('🔄 No existing data found, loading from Firestore for hour $selectedHour');
      try {
        final loadedData = await _thermalReadingService.loadThermalReadingForHour(
          projectId: widget.projectId,
          logId: widget.logId,
          hour: selectedHour,
        );
        
        if (loadedData != null && mounted) {
          debugPrint('✅ Loaded data from Firestore: ${loadedData.toJson()}');
          setState(() {
            existingData = loadedData;
          });
        }
      } catch (e) {
        debugPrint('❌ Error loading data from Firestore: $e');
      }
    }
    
    _initializeControllers();
  }

  void _initializeControllers() {
    final data = existingData;
    
    // Debug logging
    debugPrint('🔍 Initializing controllers for hour $selectedHour');
    debugPrint('📊 Existing data: ${data?.toJson()}');
    debugPrint('📊 Widget data: ${widget.existingData?.toJson()}');
    debugPrint('📊 Data source: ${data == widget.existingData ? "widget" : "loaded"}');

    // Initialize controllers only if they haven't been created yet
    if (_inletReadingController == null) {
      _inletReadingController = TextEditingController(
        text: data?.inletReading?.toString() ?? '',
      );
    } else {
      _inletReadingController!.text = data?.inletReading?.toString() ?? '';
    }
    
    if (_outletReadingController == null) {
      _outletReadingController = TextEditingController(
        text: data?.outletReading?.toString() ?? '',
      );
    } else {
      _outletReadingController!.text = data?.outletReading?.toString() ?? '';
    }
    
    if (_toInletReadingH2SController == null) {
      _toInletReadingH2SController = TextEditingController(
        text: data?.toInletReadingH2S?.toString() ?? '',
      );
    } else {
      _toInletReadingH2SController!.text = data?.toInletReadingH2S?.toString() ?? '';
    }
    
    // Marathon GBR specific field
    if (_lelInletReadingController == null) {
      _lelInletReadingController = TextEditingController(
        text: data?.lelInletReading?.toString() ?? '',
      );
    } else {
      _lelInletReadingController!.text = data?.lelInletReading?.toString() ?? '';
    }
    
    // Auto-expand optional section if any optional fields have data (Marathon GBR)
    if (widget.projectId == '2025-2-095' && !_isOptionalSectionExpanded) {
      final hasOptionalData = (data?.vaporInletFlowRateFPM != null && data!.vaporInletFlowRateFPM! > 0) ||
                              (data?.tankRefillFlowRate != null && data!.tankRefillFlowRate! > 0) ||
                              (data?.vacuumAtTankVaporOutlet != null && data!.vacuumAtTankVaporOutlet! > 0);
      if (hasOptionalData) {
        setState(() {
          _isOptionalSectionExpanded = true;
        });
      }
    }
    
    if (_vaporInletFlowRateFPMController == null) {
      _vaporInletFlowRateFPMController = TextEditingController(
        text: data?.vaporInletFlowRateFPM?.toString() ?? '',
      );
    } else {
      _vaporInletFlowRateFPMController!.text = data?.vaporInletFlowRateFPM?.toString() ?? '';
    }
    
    if (_vaporInletFlowRateBBLController == null) {
      _vaporInletFlowRateBBLController = TextEditingController(
        text: data?.vaporInletFlowRateBBL?.toString() ?? '',
      );
    } else {
      _vaporInletFlowRateBBLController!.text = data?.vaporInletFlowRateBBL?.toString() ?? '';
    }
    
    if (_tankRefillFlowRateController == null) {
      _tankRefillFlowRateController = TextEditingController(
        text: data?.tankRefillFlowRate?.toString() ?? '',
      );
    } else {
      _tankRefillFlowRateController!.text = data?.tankRefillFlowRate?.toString() ?? '';
    }
    
    if (_combustionAirFlowRateController == null) {
      _combustionAirFlowRateController = TextEditingController(
        text: data?.combustionAirFlowRate?.toString() ?? '',
      );
    } else {
      _combustionAirFlowRateController!.text = data?.combustionAirFlowRate?.toString() ?? '';
    }
    
    if (_vacuumAtTankVaporOutletController == null) {
      _vacuumAtTankVaporOutletController = TextEditingController(
        text: data?.vacuumAtTankVaporOutlet?.toString() ?? '',
      );
    } else {
      _vacuumAtTankVaporOutletController!.text = data?.vacuumAtTankVaporOutlet?.toString() ?? '';
    }
    
    if (_exhaustTemperatureController == null) {
      _exhaustTemperatureController = TextEditingController(
        text: data?.exhaustTemperature?.toString() ?? '',
      );
    } else {
      _exhaustTemperatureController!.text = data?.exhaustTemperature?.toString() ?? '';
    }
    
    if (_totalizerController == null) {
      _totalizerController = TextEditingController(
        text: data?.totalizer?.toString() ?? '',
      );
    } else {
      _totalizerController!.text = data?.totalizer?.toString() ?? '';
    }
    
    if (_observationsController == null) {
      _observationsController = TextEditingController(
        text: data?.observations ?? '',
      );
    } else {
      _observationsController!.text = data?.observations ?? '';
    }
  }

  Future<void> _onHourSelected(int hour) async {
    if (_isDisposed || !mounted) return;
    
    // Load existing data for the selected hour from Firestore
    ThermalReading? hourData;
    try {
      hourData = await _thermalReadingService.loadThermalReadingForHour(
        projectId: widget.projectId,
        logId: widget.logId,
        hour: hour,
      );
    } catch (e) {
      debugPrint('Error loading data for hour $hour: $e');
    }
    
    if (mounted) {
      setState(() {
        selectedHour = hour;
        existingData = hourData; // Use loaded data instead of clearing
        _initializeControllers();
      });
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _inletReadingController?.dispose();
    _outletReadingController?.dispose();
    _toInletReadingH2SController?.dispose();
    _lelInletReadingController?.dispose(); // Marathon GBR specific
    _vaporInletFlowRateFPMController?.dispose();
    _vaporInletFlowRateBBLController?.dispose();
    _tankRefillFlowRateController?.dispose();
    _combustionAirFlowRateController?.dispose();
    _vacuumAtTankVaporOutletController?.dispose();
    _exhaustTemperatureController?.dispose();
    _totalizerController?.dispose();
    _observationsController?.dispose();
    super.dispose();
  }

  String _formatHour(int hour) {
    return "${hour.toString().padLeft(2, '0')}:00";
  }

  String _formatSelectedDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return '${weekdays[date.weekday % 7]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }
  
  String _formatLogIdDate(String logId) {
    try {
      // Parse the YYYY-MM-DD format
      final parts = logId.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        final date = DateTime(year, month, day);
        return _formatSelectedDate(date);
      }
    } catch (e) {
      // If parsing fails, return the original logId
    }
    return logId;
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Create ThermalReading object with current form data
      final thermalReading = ThermalReading(
        hour: selectedHour,
        timestamp: DateTime.now().toIso8601String(),
        inletReading: double.tryParse(_inletReadingController?.text ?? ''),
        outletReading: double.tryParse(_outletReadingController?.text ?? ''),
        toInletReadingH2S: double.tryParse(_toInletReadingH2SController?.text ?? ''),
        lelInletReading: double.tryParse(_lelInletReadingController?.text ?? ''),
        vaporInletFlowRateFPM: double.tryParse(_vaporInletFlowRateFPMController?.text ?? ''),
        vaporInletFlowRateBBL: double.tryParse(_vaporInletFlowRateBBLController?.text ?? ''),
        tankRefillFlowRate: double.tryParse(_tankRefillFlowRateController?.text ?? ''),
        combustionAirFlowRate: double.tryParse(_combustionAirFlowRateController?.text ?? ''),
        vacuumAtTankVaporOutlet: double.tryParse(_vacuumAtTankVaporOutletController?.text ?? ''),
        exhaustTemperature: double.tryParse(_exhaustTemperatureController?.text ?? ''),
        totalizer: double.tryParse(_totalizerController?.text ?? ''),
        observations: _observationsController?.text ?? '',
        operatorId: 'OP001', // TODO: Get from current user
        validated: false,
      );

      // Debug logging before save
      debugPrint('💾 Saving thermal reading for hour ${thermalReading.hour}');
      debugPrint('📊 Data to save: ${thermalReading.toJson()}');
      debugPrint('📁 Project: ${widget.projectId}, Log: ${widget.logId}');
      
      // Save using thermal reading service
      await _thermalReadingService.saveThermalReading(
        projectId: widget.projectId,
        logId: widget.logId,
        reading: thermalReading,
      );
      
      // Debug logging after save
      debugPrint('✅ Successfully saved thermal reading for hour ${thermalReading.hour}');

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Entry saved successfully'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Return to previous screen with success result
        context.pop(true);
      }
    } on ThermalReadingSaveException catch (e) {
      // Handle thermal reading save exceptions
      if (mounted) {
        final isOffline = e.isOfflineSaved;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isOffline ? Icons.cloud_off : Icons.error,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(e.message)),
              ],
            ),
            backgroundColor: isOffline ? Colors.orange : Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );

        if (isOffline) {
          // Still navigate back if saved offline
          context.pop();
        }
      }
    } on ValidationException catch (e) {
      // Show validation errors
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Validation Error'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Please correct the following:'),
                const SizedBox(height: 8),
                ...e.errors.entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 4),
                      child: Text(
                        '• ${entry.value}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    )),
              ],
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
    } on SaveException catch (e) {
      // Show offline save message
      if (mounted && e.isOfflineSaved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.offline_pin, color: Colors.white),
                SizedBox(width: 8),
                Text(
                    'Entry saved offline. Will sync when connection is restored.'),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
        context.pop();
      } else {
        // Show general save error
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error Saving Entry'),
              content: Text(e.toString()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      // Show unexpected error
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Unexpected Error'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        _checkSyncStatus();
      }
    }
  }

  // Debug function to verify Firebase data using ThermalReadingService
  Future<void> _verifyFirebaseData() async {
    try {
      debugPrint('\n🔍 Checking Firebase data for hour $selectedHour...');
      debugPrint('📁 Path: /projects/${widget.projectId}/logs/${widget.logId}/entries/${selectedHour.toString().padLeft(2, '0')}');

      // Use ThermalReadingService to load data for current hour
      final thermalReading = await _thermalReadingService.loadThermalReadingForHour(
        projectId: widget.projectId,
        logId: widget.logId,
        hour: selectedHour,
      );

      if (thermalReading != null) {
        debugPrint('\n✅ Firebase Data Found:');
        debugPrint('📊 Hour: ${thermalReading.hour}');
        debugPrint('📊 Inlet: ${thermalReading.inletReading}');
        debugPrint('📊 Outlet: ${thermalReading.outletReading}');
        debugPrint('📊 H2S: ${thermalReading.toInletReadingH2S}');
        debugPrint('📊 Observations: ${thermalReading.observations}');
        debugPrint('📊 Full data: ${thermalReading.toJson()}');

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✅ Data found in Firebase!'),
                  Text(
                    'Hour $selectedHour: Inlet=${thermalReading.inletReading}, Outlet=${thermalReading.outletReading}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        debugPrint('\n⚠️ No data found for hour $selectedHour');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('⚠️ No data found in Firebase'),
                  Text(
                    'Hour $selectedHour entry does not exist',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('\n❌ Error checking Firebase data: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('❌ Error checking Firebase data'),
                Text(
                  e.toString(),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final displayHour = selectedHour;
    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B132B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_isDisposed || !mounted) return;
            
            if (context.canPop()) {
              context.pop();
            } else {
              // Fallback navigation if pop fails
              context.goNamed('projectSummary');
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  'Hour ${_formatHour(displayHour)}',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isEditMode) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.orange.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit,
                          size: 12,
                          color: Colors.orange[300],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'EDIT',
                          style: GoogleFonts.nunito(
                            color: Colors.orange[300],
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.white70,
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.selectedDate != null ? _formatSelectedDate(widget.selectedDate!) : _formatLogIdDate(widget.logId)} • ${widget.projectId}',
                  style: GoogleFonts.nunito(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Sync status indicator
          if (_hasUnsynedEntries)
            IconButton(
              icon: const Icon(Icons.sync_problem, color: Colors.orange),
              onPressed: () async {
                if (_isDisposed || !mounted) return;
                setState(() => _isSaving = true);
                try {
                  await _thermalReadingService.syncOfflineEntries();
                  await _checkSyncStatus();
                  if (mounted && !_hasUnsynedEntries) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All entries synced successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Sync failed: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() => _isSaving = false);
                  }
                }
              },
              tooltip: 'Sync pending entries',
            ),
          // Debug button
          IconButton(
            icon: const Icon(Icons.bug_report_outlined, color: Colors.white),
            onPressed: _verifyFirebaseData,
            tooltip: 'Check Firebase Data',
          ),
          IconButton(
            icon: const Icon(Icons.save_rounded, color: Colors.white),
            onPressed: _isSaving ? null : _onSubmit,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Hour Selector
              SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 24,
                  separatorBuilder: (context, idx) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final isSelected = idx == selectedHour;
                    final isEntered = enteredHours.contains(idx);
                    return GestureDetector(
                      onTap: () async => await _onHourSelected(idx),
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF34D399)
                              : isEntered
                                  ? const Color(0xFF2563EB).withOpacity(0.7)
                                  : const Color(0xFF1F2937),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF34D399)
                                : isEntered
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF374151),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              idx.toString(),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.black
                                    : isEntered
                                        ? Colors.white
                                        : const Color(0xFF9CA3AF),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (isEntered)
                              const Icon(Icons.check_circle,
                                  color: Color(0xFF34D399), size: 16),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              // Progress Today Card
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937).withOpacity(0.5),
                  border: Border.all(color: const Color(0xFF374151)),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.trending_up,
                                color: Color(0xFF34D399), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Progress Today',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$hoursLogged',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'of $totalHours hours',
                              style: const TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        LinearProgressIndicator(
                          value: progressPercentage / 100,
                          minHeight: 8,
                          backgroundColor: const Color(0xFF374151),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF34D399)),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${progressPercentage.round()}% Complete',
                              style: const TextStyle(
                                color: Color(0xFF34D399),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${getMissingHoursCount()} hours remaining',
                              style: const TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (progressPercentage >= 75) ...[
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF34D399).withOpacity(0.1),
                          border: Border.all(
                              color: const Color(0xFF34D399).withOpacity(0.2)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: Color(0xFF34D399), size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Great progress! You're nearly done for today.",
                                style: TextStyle(
                                  color: Color(0xFF34D399),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // 🔍 Readings Section
              _buildSectionCard(
                title: '🔍 Readings',
                icon: Icons.search,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildNumberField(
                          label: 'Inlet Reading (PPM)',
                          controller: _inletReadingController!,
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Inlet reading is required';
                            }
                            final num = double.tryParse(value!);
                            if (num == null || num < 0) {
                              return 'Reading cannot be negative';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildNumberField(
                          label: 'Outlet Reading (PPM)',
                          controller: _outletReadingController!,
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Outlet reading is required';
                            }
                            final num = double.tryParse(value!);
                            if (num == null || num < 0) {
                              return 'Reading cannot be negative';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildNumberField(
                    label: 'T.O. Inlet Reading – PPM H₂S',
                    controller: _toInletReadingH2SController!,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'T.O. Inlet reading is required';
                      }
                      final num = double.tryParse(value!);
                      if (num == null || num < 0) {
                        return 'Reading cannot be negative';
                      }
                      return null;
                    },
                  ),
                  // Marathon GBR specific field - LEL Inlet Reading
                  if (widget.projectId == '2025-2-095') ...[
                    const SizedBox(height: 16),
                    _buildNumberField(
                      label: '%LEL Inlet',
                      controller: _lelInletReadingController!,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return '%LEL Inlet reading is required';
                        }
                        final num = double.tryParse(value!);
                        if (num == null || num < 0) {
                          return 'LEL reading cannot be negative';
                        }
                        if (num > 100) {
                          return 'LEL reading cannot exceed 100%';
                        }
                        return null;
                      },
                      warningChecker: (value) {
                        final num = double.tryParse(value);
                        if (num != null && num > 10) {
                          return '⚠ Above Marathon target (10% LEL)';
                        }
                        return null;
                      },
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 24),

              // 🌊 Flow Rates Section - Adaptive for Marathon GBR
              if (widget.projectId == '2025-2-095') 
                // Marathon GBR: Required combustion air flow only
                _buildSectionCard(
                  title: '🌊 Flow Rates',
                  icon: Icons.water_drop,
                  children: [
                    _buildNumberField(
                      label: 'Combustion Air Flow Rate (FPM)',
                      controller: _combustionAirFlowRateController!,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Combustion air flow rate is required';
                        }
                        final num = double.tryParse(value!);
                        if (num == null || num < 0) {
                          return 'Flow rate cannot be negative';
                        }
                        return null;
                      },
                    ),
                  ],
                )
              else
                // Standard: All flow fields required
                _buildSectionCard(
                  title: '🌊 Flow Rates',
                  icon: Icons.water_drop,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildNumberField(
                            label: 'Vapor Inlet Flow Rate (FPM)',
                            controller: _vaporInletFlowRateFPMController!,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Vapor inlet flow rate (FPM) is required';
                              }
                              final num = double.tryParse(value!);
                              if (num == null || num < 0) {
                                return 'Flow rate cannot be negative';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildNumberField(
                            label: 'Vapor Inlet Flow Rate (BBL/HR)',
                            controller: _vaporInletFlowRateBBLController!,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Vapor inlet flow rate (BBL/HR) is required';
                              }
                              final num = double.tryParse(value!);
                              if (num == null || num < 0) {
                                return 'Flow rate cannot be negative';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildNumberField(
                            label: 'Tank Refill Flow Rate (BBL/HR)',
                            controller: _tankRefillFlowRateController!,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Tank refill flow rate is required';
                              }
                              final num = double.tryParse(value!);
                              if (num == null || num < 0) {
                                return 'Flow rate cannot be negative';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildNumberField(
                            label: 'Combustion Air Flow Rate (FPM)',
                            controller: _combustionAirFlowRateController!,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Combustion air flow rate is required';
                              }
                              final num = double.tryParse(value!);
                              if (num == null || num < 0) {
                                return 'Flow rate cannot be negative';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

              const SizedBox(height: 24),

              // Marathon GBR: Optional Readings Section (Collapsible)
              if (widget.projectId == '2025-2-095') ...[
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2937).withOpacity(0.5),
                    border: Border.all(color: const Color(0xFF374151)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Expandable header
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isOptionalSectionExpanded = !_isOptionalSectionExpanded;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Icon(
                                Icons.tune,
                                color: Colors.blue[400],
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Add Optional Readings',
                                  style: GoogleFonts.nunito(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Icon(
                                _isOptionalSectionExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: Colors.blue[400],
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Expandable content
                      AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: Container(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Column(
                            children: [
                              Container(
                                height: 1,
                                color: const Color(0xFF374151),
                                margin: const EdgeInsets.only(bottom: 20),
                              ),
                              _buildNumberField(
                                label: 'Vapor Inlet Flow Rate (FPM)',
                                controller: _vaporInletFlowRateFPMController!,
                                validator: null, // Optional for Marathon
                              ),
                              const SizedBox(height: 16),
                              _buildNumberField(
                                label: 'Tank Refill Flow Rate (BBL/HR)',
                                controller: _tankRefillFlowRateController!,
                                validator: null, // Optional for Marathon
                              ),
                              const SizedBox(height: 16),
                              _buildNumberField(
                                label: 'Vacuum at Tank Vapor Outlet (Inch H₂O)',
                                controller: _vacuumAtTankVaporOutletController!,
                                validator: null, // Optional for Marathon
                                warningChecker: (value) {
                                  final num = double.tryParse(value);
                                  if (num != null && num < 2) {
                                    return '⚠ Below typical minimum (2 Inch H₂O)';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        crossFadeState: _isOptionalSectionExpanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 300),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // 🔥 System Metrics Section
              _buildSectionCard(
                title: '🔥 System Metrics',
                icon: Icons.thermostat,
                children: [
                  // Vacuum field only for non-Marathon projects (Marathon has it in optional section)
                  if (widget.projectId != '2025-2-095') ...[
                    _buildNumberField(
                      label: 'Vacuum at Tank Vapor Outlet (2 Inch H₂O MIN)',
                      controller: _vacuumAtTankVaporOutletController!,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Vacuum reading is required';
                        }
                        final num = double.tryParse(value!);
                        if (num == null || num < 2) {
                          return 'Minimum vacuum must be 2 Inch H₂O';
                        }
                        return null;
                      },
                      warningChecker: (value) {
                        final num = double.tryParse(value);
                        if (num != null && num < 2) {
                          return '⚠ Below minimum requirement (2 Inch H₂O)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: _buildNumberField(
                          label: 'Exhaust Temperature (°F)',
                          controller: _exhaustTemperatureController!,
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Exhaust temperature is required';
                            }
                            final num = double.tryParse(value!);
                            if (num == null || num < 0) {
                              return 'Temperature cannot be negative';
                            }
                            if (num > 2000) {
                              return 'Temperature seems unusually high';
                            }
                            return null;
                          },
                          warningChecker: (value) {
                            final num = double.tryParse(value);
                            if (num != null && (num < 300 || num > 1200)) {
                              return '⚠ Outside normal range (300-1200°F)';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildNumberField(
                          label: 'Totalizer (SCF)',
                          controller: _totalizerController!,
                          isInteger: true,
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Totalizer reading is required';
                            }
                            final num = double.tryParse(value!);
                            if (num == null || num < 0) {
                              return 'Totalizer cannot be negative';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 📝 Notes Section
              _buildSectionCard(
                title: '📝 Notes',
                icon: Icons.description,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Observations / Anomalies',
                        style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _observationsController!,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText:
                              'Enter any observations, anomalies, equipment issues, or maintenance notes...',
                          hintStyle: const TextStyle(color: Color(0xFF6B7280)),
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
                        ),
                      ),
                    ],
                  ),
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
                      onPressed: _isSaving ? null : _onSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                                Text('Save Reading'),
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
        color: const Color(0xFF152042),
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF1F2937)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2937),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
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
    String? Function(String)? warningChecker,
    bool isInteger = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.nunito(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: !isInteger),
          inputFormatters: isInteger
              ? [FilteringTextInputFormatter.digitsOnly]
              : [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontSize: 16,
          ),
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF1F2937),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2563EB)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            errorStyle: GoogleFonts.nunito(
              color: const Color(0xFFEF4444),
              fontSize: 12,
            ),
            hintStyle: GoogleFonts.nunito(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ),
        if (warningChecker != null) ...[
          const SizedBox(height: 4),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              final warning = warningChecker(value.text);
              if (warning != null) {
                return Text(
                  warning,
                  style: GoogleFonts.nunito(
                    color: const Color(0xFFFBBF24),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ],
    );
  }
}
