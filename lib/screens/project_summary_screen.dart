import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../model/job_data.dart';
import '../models/thermal_reading.dart';
import 'hourly_entry_form.dart';
import '../services/thermal_reading_service.dart';
import '../services/navigation_state_service.dart';
import '../widgets/date_selector_widget.dart';
import '../providers/date_provider.dart';
import '../routes/route_extensions.dart';

class SystemMetricsData {
  final double dailyTotalizer;
  final double avgVacuum;
  final double avgExhaustTemp;
  final double avgCombustionAir;
  final double peakInletPPM;
  final double peakOutletPPM;
  final String operationalNotes;
  final String maintenanceIssues;
  final String timestamp;

  SystemMetricsData({
    required this.dailyTotalizer,
    required this.avgVacuum,
    required this.avgExhaustTemp,
    required this.avgCombustionAir,
    required this.peakInletPPM,
    required this.peakOutletPPM,
    required this.operationalNotes,
    required this.maintenanceIssues,
    required this.timestamp,
  });

  factory SystemMetricsData.fromJson(Map<String, dynamic> json) {
    return SystemMetricsData(
      dailyTotalizer: json['dailyTotalizer']?.toDouble() ?? 0.0,
      avgVacuum: json['avgVacuum']?.toDouble() ?? 0.0,
      avgExhaustTemp: json['avgExhaustTemp']?.toDouble() ?? 0.0,
      avgCombustionAir: json['avgCombustionAir']?.toDouble() ?? 0.0,
      peakInletPPM: json['peakInletPPM']?.toDouble() ?? 0.0,
      peakOutletPPM: json['peakOutletPPM']?.toDouble() ?? 0.0,
      operationalNotes: json['operationalNotes'] ?? '',
      maintenanceIssues: json['maintenanceIssues'] ?? '',
      timestamp: json['timestamp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailyTotalizer': dailyTotalizer,
      'avgVacuum': avgVacuum,
      'avgExhaustTemp': avgExhaustTemp,
      'avgCombustionAir': avgCombustionAir,
      'peakInletPPM': peakInletPPM,
      'peakOutletPPM': peakOutletPPM,
      'operationalNotes': operationalNotes,
      'maintenanceIssues': maintenanceIssues,
      'timestamp': timestamp,
    };
  }
}

class ProjectSummaryScreen extends StatefulWidget {
  final JobData? initialJob;
  final String? projectId;

  const ProjectSummaryScreen({
    super.key, 
    this.initialJob,
    this.projectId,
  });

  @override
  State<ProjectSummaryScreen> createState() => _ProjectSummaryScreenState();
}

class _ProjectSummaryScreenState extends State<ProjectSummaryScreen> {
  // Keep existing state variables and methods
  JobData? currentJob;
  List<ThermalReading> thermalData = [];
  SystemMetricsData? systemMetrics;
  bool jobSetupComplete = false;
  String? selectedMeterType;
  TimeOfDay? systemStartTime;
  TimeOfDay? systemEndTime;
  double totalizerStartReading = 0.0;
  static const int totalHours = 24;
  
  // New variables for daily progress tracking
  final ThermalReadingService _thermalReadingService = ThermalReadingService();
  Set<int> _completedHours = {};
  bool _isLoadingProgress = false;
  String? _lastEntryTime;
  
  // Selected date for viewing different days
  LogDate? selectedLogDate;

  @override
  void initState() {
    super.initState();
    if (widget.initialJob != null) {
      currentJob = widget.initialJob;
      // Save current project for state preservation
      NavigationStateService.saveCurrentProject(widget.initialJob!);
    }
    _loadSavedData();
    _loadDailyProgress();
    
    // Save current route for restoration
    if (widget.projectId != null) {
      NavigationStateService.saveLastRoute('projectSummary', {
        'projectId': widget.projectId!,
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only reload if we have a job and haven't loaded yet
    if (currentJob != null && _completedHours.isEmpty && !_isLoadingProgress) {
      _loadDailyProgress();
    }
  }

  // Keep existing helper methods
  Future<void> _loadSavedData() async {
    // ... (keep existing implementation)
  }

  /// Load daily progress data from Firestore
  Future<void> _loadDailyProgress() async {
    if (currentJob == null && widget.projectId == null) {
      debugPrint('⚠️ Cannot load progress: both currentJob and projectId are null');
      return;
    }
    
    if (!mounted) return;

    setState(() {
      _isLoadingProgress = true;
    });

    try {
      final projectId = widget.projectId ?? currentJob?.projectNumber;
      if (projectId == null) {
        debugPrint('⚠️ Cannot load progress: no project ID available');
        return;
      }
      final logId = _getTodayLogId();
      
      debugPrint('🔄 Loading daily progress for project: $projectId, log: $logId');

      // Get completed hours from thermal reading service
      final completedHours = await _thermalReadingService.getCompletedHours(
        projectId: projectId,
        logId: logId,
      );

      debugPrint('✅ Found ${completedHours.length} completed hours: $completedHours');

      // Load thermal readings to get last entry time
      final readings = await _thermalReadingService.loadThermalReadings(
        projectId: projectId,
        logId: logId,
      );

      debugPrint('✅ Loaded ${readings.length} thermal readings');

      // Find the most recent entry time
      String? lastEntryTime;
      if (readings.isNotEmpty) {
        readings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        final lastReading = readings.first;
        final lastEntryDateTime = DateTime.tryParse(lastReading.timestamp);
        if (lastEntryDateTime != null) {
          lastEntryTime = _formatLastEntryTime(lastEntryDateTime);
          debugPrint('⏰ Last entry time: $lastEntryTime');
        }
      }

      if (mounted) {
        setState(() {
          _completedHours = completedHours;
          _lastEntryTime = lastEntryTime;
          thermalData = readings; // Update thermal data for compatibility
          _isLoadingProgress = false;
        });
        debugPrint('🎯 Progress updated: ${_completedHours.length}/24 hours logged');
      }
    } catch (e) {
      debugPrint('❌ Error loading daily progress: $e');
      if (mounted) {
        setState(() {
          _isLoadingProgress = false;
        });
        
        // Show error message to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to load progress data: ${e.toString()}'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadDailyProgress,
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadDailyProgressForDate(String dateId) async {
    if (currentJob == null && widget.projectId == null) {
      debugPrint('⚠️ Cannot load progress: both currentJob and projectId are null');
      return;
    }
    
    if (!mounted) return;

    setState(() {
      _isLoadingProgress = true;
    });

    try {
      final projectId = widget.projectId ?? currentJob?.projectNumber;
      if (projectId == null) {
        debugPrint('⚠️ Cannot load progress for date: no project ID available');
        return;
      }
      
      debugPrint('🔄 Loading daily progress for project: $projectId, date: $dateId');

      // Get completed hours from thermal reading service for specific date
      final completedHours = await _thermalReadingService.getCompletedHours(
        projectId: projectId,
        logId: dateId,
      );

      debugPrint('✅ Found ${completedHours.length} completed hours for $dateId: $completedHours');

      // Load thermal readings to get last entry time for this date
      final readings = await _thermalReadingService.loadThermalReadings(
        projectId: projectId,
        logId: dateId,
      );

      debugPrint('✅ Loaded ${readings.length} thermal readings for $dateId');

      // Find the most recent entry time for this date
      String? lastEntryTime;
      if (readings.isNotEmpty) {
        readings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        final lastReading = readings.first;
        final lastEntryDateTime = DateTime.tryParse(lastReading.timestamp);
        if (lastEntryDateTime != null) {
          lastEntryTime = _formatLastEntryTime(lastEntryDateTime);
          debugPrint('⏰ Last entry time for $dateId: $lastEntryTime');
        }
      }

      if (mounted) {
        setState(() {
          _completedHours = completedHours;
          _lastEntryTime = lastEntryTime;
          thermalData = readings; // Update thermal data for compatibility
          _isLoadingProgress = false;
        });
        debugPrint('🎯 Progress updated for $dateId: ${_completedHours.length}/24 hours logged');
      }
    } catch (e) {
      debugPrint('❌ Error loading daily progress for $dateId: $e');
      if (mounted) {
        setState(() {
          _isLoadingProgress = false;
        });
        
        // Show error message to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to load progress data for $dateId: ${e.toString()}'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _loadDailyProgressForDate(dateId),
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }

  /// Get today's log ID (formatted as current date)
  String _getTodayLogId() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Format last entry time for display
  String _formatLastEntryTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else {
      return '${difference.inDays} day(s) ago';
    }
  }

  int get hoursLogged => _completedHours.length;
  int get missingHoursCount => totalHours - hoursLogged;
  double get progressPercentage => (hoursLogged / totalHours) * 100;
  
  // Get the job data to display - either from currentJob or create a fallback
  JobData get displayJob => currentJob ?? JobData(
    projectNumber: widget.projectId ?? 'Unknown',
    projectName: 'Project ${widget.projectId ?? 'Unknown'}',
    unitNumber: 'N/A',
    date: 'N/A',
    status: 'In Progress',
    location: 'N/A',
    workOrderNumber: 'N/A',
    tankType: 'thermal',
    facilityTarget: 'N/A',
    operatingTemperature: 'N/A',
    benzeneTarget: 'N/A',
    h2sAmpRequired: false,
    product: 'N/A',
  );

  Future<void> _navigateToSystemForm() async {
    await context.pushNamed('systemMetrics', extra: {
      'existingData': systemMetrics,
    });
    // Refresh progress when returning
    _loadDailyProgress();
  }

  Future<void> _navigateToReview() async {
    
    final projectId = widget.projectId ?? displayJob.projectNumber;
    final logId = _getTodayLogId();
    
    await context.goToReviewAll(projectId, logId);
    // Refresh progress when returning
    _loadDailyProgress();
  }

  Future<void> _navigateToOcrScan() async {
    final result = await context.goToOcrScan(
      title: 'Scan Field Log',
      instructions: 'Take a photo or upload an image of your paper log or control panel to extract hourly data automatically.',
    );
    
    if (result != null && mounted) {
      // Show extracted data preview
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'OCR data extracted! Use it in hourly entry forms.',
                  style: GoogleFonts.nunito(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'View Data',
            textColor: Colors.white,
            onPressed: () {
              // Show extracted data in a dialog
              _showOcrDataDialog(result);
            },
          ),
        ),
      );
      
      // Optionally navigate to hourly entry with the extracted data
      debugPrint('📊 OCR Result: $result');
    }
  }

  void _showOcrDataDialog(Map<String, dynamic> extractedData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF152042),
        title: Text(
          'Extracted Data',
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: extractedData.entries.where((entry) => 
              !entry.key.startsWith('ocr') // Filter out OCR metadata
            ).map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      entry.key,
                      style: GoogleFonts.nunito(
                        color: Colors.grey[300],
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      entry.value.toString(),
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: GoogleFonts.nunito(color: Colors.blue[300]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToHourlyEntry(); // Navigate to hourly entry with data
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Use in Entry',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToHourlyEntry() async {
    // Use selected date if available, otherwise use today
    final logId = selectedLogDate?.dateId ?? _getTodayLogId();
    
    // Show a dialog if no date is selected
    if (selectedLogDate == null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF152042),
          title: Text(
            'No Date Selected',
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'You haven\'t selected a date. Would you like to log data for today (${_getTodayLogId()})?',
            style: GoogleFonts.nunito(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.nunito(color: Colors.grey[400]),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
              ),
              child: Text(
                'Yes, Use Today',
                style: GoogleFonts.nunito(color: Colors.white),
              ),
            ),
          ],
        ),
      );
      
      if (confirmed != true) return;
    }
    
    // Find the next hour that needs data
    int nextHour = -1;
    for (int i = 0; i < 24; i++) {
      if (!_completedHours.contains(i)) {
        nextHour = i;
        break;
      }
    }

    // If all hours are logged, start at hour 0 for editing
    nextHour = nextHour == -1 ? 0 : nextHour;

    final projectId = widget.projectId ?? displayJob.projectNumber;

    // Navigate to hourly entry form and wait for result
    final result = await context.safeNavigate(
      'hourlyEntry',
      pathParameters: {
        'projectId': projectId,
        'logDate': logId,
        'hour': nextHour.toString(),
      },
      extra: {
        'existingData': thermalData.firstWhere(
          (entry) => entry.hour == nextHour,
          orElse: () => ThermalReading(
            hour: nextHour,
            timestamp: DateTime.now().toIso8601String(),
          ),
        ),
        'logType': displayJob.tankType,
        'enteredHours': _completedHours,
      },
    );

    // Refresh progress when returning, especially if entry was saved
    if (result == true || result == null) {
      _loadDailyProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading if we don't have either currentJob or projectId
    if (currentJob == null && widget.projectId == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B132B),
        body: Center(
          child: CircularProgressIndicator(color: Colors.blue),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B132B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              // Fallback navigation - go to project selector
              context.goNamed('projectSelector');
            }
          },
        ),
        title: Text(
          'Project Summary',
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_isLoadingProgress)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadDailyProgress,
            tooltip: 'Refresh progress data',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDailyProgress,
        color: const Color(0xFF2563EB),
        backgroundColor: const Color(0xFF152042),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProjectHeader(),
              const SizedBox(height: 24),
              _buildOperationalParameters(),
              const SizedBox(height: 24),
              _buildDateSelector(),
              const SizedBox(height: 24),
              _buildDailyProgress(),
              if (missingHoursCount > 0) ...[
                const SizedBox(height: 16),
                _buildWarningBanner(),
              ],
              const SizedBox(height: 24),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            displayJob.projectName,
            style: GoogleFonts.nunito(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor(displayJob.status).withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            displayJob.status,
            style: GoogleFonts.nunito(
              color: _getStatusColor(displayJob.status),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF1C8C4D); // Green
      case 'in progress':
        return const Color(0xFF2563EB); // Blue
      case 'pending':
        return const Color(0xFFFBBF24); // Yellow
      default:
        return Colors.grey;
    }
  }

  Widget _buildDateSelector() {
    if (currentJob == null) return const SizedBox.shrink();
    
    final projectId = widget.projectId ?? displayJob.projectNumber;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedLogDate != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF2563EB).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Selected Date: ${selectedLogDate!.formattedDate}',
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${selectedLogDate!.completedHours}/24 hours',
                  style: GoogleFonts.nunito(
                    color: const Color(0xFF2563EB),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        DateSelectorWidget(
          projectId: projectId,
          initialJob: displayJob,
          onDateSelected: (logDate) {
            setState(() {
              selectedLogDate = logDate;
            });
            // Load progress for the selected date
            _loadDailyProgressForDate(logDate.dateId);
          },
        ),
      ],
    );
  }

  Widget _buildOperationalParameters() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF152042),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildParameterRow(
            icon: Icons.assignment,
            label: 'Work Order #',
            value: displayJob.workOrderNumber,
          ),
          _buildParameterRow(
            icon: Icons.business,
            label: 'Unit #',
            value: displayJob.unitNumber,
          ),
          _buildParameterRow(
            icon: Icons.storage,
            label: 'Tank Type',
            value: displayJob.tankType,
          ),
          _buildParameterRow(
            icon: Icons.local_drink,
            label: 'Product',
            value: displayJob.product,
          ),
          _buildParameterRow(
            icon: Icons.speed,
            label: 'Facility Target',
            value: displayJob.facilityTarget,
          ),
          _buildParameterRow(
            icon: Icons.thermostat,
            label: 'Operating Temp',
            value: displayJob.operatingTemperature,
            valueColor: Colors.red[400],
          ),
          _buildParameterRow(
            icon: Icons.science,
            label: 'Benzene Target',
            value: displayJob.benzeneTarget,
          ),
          _buildParameterRow(
            icon: Icons.warning,
            label: 'H₂S Amp Required',
            value: displayJob.h2sAmpRequired ? 'Yes' : 'No',
            valueColor: displayJob.h2sAmpRequired
                ? Colors.red[400]
                : Colors.green[400],
          ),
        ],
      ),
    );
  }

  Widget _buildParameterRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.nunito(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.nunito(
              color: valueColor ?? Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyProgress() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF152042),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                selectedLogDate != null 
                    ? 'Progress for ${selectedLogDate!.shortDate}'
                    : 'Daily Progress (Today)',
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (_isLoadingProgress) ...[
                const SizedBox(width: 12),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
              ]
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hours Logged',
                style: GoogleFonts.nunito(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ),
              if (_lastEntryTime != null)
                Text(
                  'Last entry: $_lastEntryTime',
                  style: GoogleFonts.nunito(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                width: MediaQuery.of(context).size.width * 0.8 * (hoursLogged / totalHours),
                height: 12,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: hoursLogged == totalHours
                        ? [const Color(0xFF10B981), const Color(0xFF34D399)]
                        : [const Color(0xFF2563EB), const Color(0xFF3B82F6)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$hoursLogged/$totalHours hours',
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${progressPercentage.toInt()}%',
                style: GoogleFonts.nunito(
                  color: hoursLogged == totalHours 
                      ? const Color(0xFF10B981) 
                      : const Color(0xFF2563EB),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (hoursLogged == totalHours) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Excellent! All 24 hourly entries completed for today.',
                      style: GoogleFonts.nunito(
                        color: const Color(0xFF10B981),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWarningBanner() {
    if (missingHoursCount <= 0) return const SizedBox.shrink();
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: missingHoursCount > 12 
            ? Colors.red[900]?.withOpacity(0.3)
            : Colors.orange[900]?.withOpacity(0.3),
        border: Border.all(
          color: missingHoursCount > 12 
              ? Colors.red[700]! 
              : Colors.orange[700]!, 
          width: 1
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded, 
                color: missingHoursCount > 12 
                    ? Colors.red[300] 
                    : Colors.orange[300], 
                size: 24
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$missingHoursCount hourly ${missingHoursCount == 1 ? 'entry' : 'entries'} still required for today',
                  style: GoogleFonts.nunito(
                    color: missingHoursCount > 12 
                        ? Colors.red[300] 
                        : Colors.orange[300],
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (_completedHours.isNotEmpty && missingHoursCount > 0) ...[
            const SizedBox(height: 12),
            ExpansionTile(
              title: Text(
                'Show missing hours',
                style: GoogleFonts.nunito(
                  color: missingHoursCount > 12 
                      ? Colors.red[400] 
                      : Colors.orange[400],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              iconColor: missingHoursCount > 12 
                  ? Colors.red[400] 
                  : Colors.orange[400],
              collapsedIconColor: missingHoursCount > 12 
                  ? Colors.red[400] 
                  : Colors.orange[400],
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(24, (hour) {
                      if (_completedHours.contains(hour)) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: missingHoursCount > 12 
                              ? Colors.red[800]?.withOpacity(0.3)
                              : Colors.orange[800]?.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${hour.toString().padLeft(2, '0')}:00',
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).where((widget) => widget is! SizedBox).toList(),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _buildActionButtonWithText(
          iconText: '📝',
          label: selectedLogDate != null 
              ? 'Log Data for ${selectedLogDate!.shortDate}'
              : 'Start Logging Hourly Data',
          subtitle: selectedLogDate != null
              ? 'Record readings for ${selectedLogDate!.formattedDate}'
              : 'Select a date above first, or use today',
          color: const Color(0xFF2563EB),
          onTap: _navigateToHourlyEntry,
        ),
        const SizedBox(height: 16),
        _buildActionButtonWithText(
          iconText: '📊',
          label: 'Enter System Metrics',
          subtitle: 'Update system parameters and readings',
          color: Colors.green,
          onTap: _navigateToSystemForm,
        ),
        const SizedBox(height: 16),
        _buildActionButtonWithText(
          iconText: '🕒',
          label: 'Review All Entries',
          subtitle: 'View and edit previous entries',
          color: Colors.purple,
          onTap: _navigateToReview,
        ),
        const SizedBox(height: 16),
        _buildActionButtonWithText(
          iconText: '📷',
          label: 'Scan Paper Log',
          subtitle: 'Use OCR to extract data from photos',
          color: Colors.orange,
          onTap: _navigateToOcrScan,
        ),
        const SizedBox(height: 24),
        const Divider(color: Color(0xFF374151)),
        const SizedBox(height: 24),
        _buildActionButtonWithText(
          iconText: '✅',
          label: 'Job Completed',
          subtitle: 'Enter final readings and complete project',
          color: const Color(0xFF10B981), // Green
          onTap: () => context.pushNamed(
            'finalReadings',
            extra: {
              'projectId': displayJob.projectNumber,
              'logId': displayJob.date,
              'logType': displayJob.tankType,
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtonWithText({
    required String iconText,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF152042),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  iconText,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF152042),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
