import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/job_dashboard_models.dart';
import '../providers/report_providers.dart';
import '../services/download_history_service.dart';
import '../widgets/download_history_dialog.dart';
import 'dart:html' as html;

/// Dialog for configuring and generating Excel reports
class ExcelExportDialog extends ConsumerStatefulWidget {
  final List<JobDashboardData> availableJobs;
  final JobDashboardData? selectedJob;

  const ExcelExportDialog({
    super.key,
    required this.availableJobs,
    this.selectedJob,
  });

  @override
  ConsumerState<ExcelExportDialog> createState() => _ExcelExportDialogState();
}

class _ExcelExportDialogState extends ConsumerState<ExcelExportDialog> {
  ExportType _exportType = ExportType.single;
  String? _selectedProjectId;
  DateTime? _selectedDate;
  DateTimeRange? _dateRange;
  List<String> _selectedProjectIds = [];
  bool _includeAnalytics = true;
  bool _includeDailyLogs = true;
  bool _includeHourlyData = true;
  
  // Template customization options
  String _reportTitle = '';
  String _companyName = '';
  bool _includeCompanyLogo = false;
  String _additionalNotes = '';
  String _selectedTheme = 'Professional';
  
  final DownloadHistoryService _historyService = DownloadHistoryService();
  
  /// Determine if a project should use dynamic export based on project configuration
  bool _shouldUseDynamicExport(String projectId) {
    // Marathon GBR projects use dynamic export
    if (projectId == '2025-2-095') return true;
    
    // Add other dynamic projects here
    // You could also check for a flag in project metadata or log templates
    
    return false;
  }
  
  @override
  void initState() {
    super.initState();
    if (widget.selectedJob != null) {
      _selectedProjectId = widget.selectedJob!.id;
      _exportType = ExportType.single;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportGenerationProvider);
    
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.file_download_outlined,
                  color: Color(0xFF3B82F6),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Export Excel Report',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const DownloadHistoryDialog(),
                    );
                  },
                  icon: const Icon(Icons.history, color: Colors.white70),
                  tooltip: 'View Download History',
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Export Type Selection
            _buildExportTypeSection(),
            
            const SizedBox(height: 20),
            
            // Content based on export type
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_exportType == ExportType.single) ...[
                      _buildSingleProjectSection(),
                    ] else if (_exportType == ExportType.daily) ...[
                      _buildDailyReportSection(),
                    ] else if (_exportType == ExportType.batch) ...[
                      _buildBatchExportSection(),
                    ],
                    
                    const SizedBox(height: 20),
                    
                    // Report Options
                    _buildReportOptionsSection(),
                    
                    const SizedBox(height: 20),
                    
                    // Template Customization
                    _buildTemplateCustomizationSection(),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            _buildActionButtons(reportState),
          ],
        ),
      ),
    );
  }

  Widget _buildExportTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Export Type',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildExportTypeCard(
                ExportType.single,
                'Single Project',
                'Export complete project report',
                Icons.folder_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildExportTypeCard(
                ExportType.daily,
                'Daily Report',
                'Export single day data',
                Icons.calendar_today_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildExportTypeCard(
                ExportType.batch,
                'Batch Export',
                'Export multiple projects',
                Icons.batch_prediction_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExportTypeCard(ExportType type, String title, String subtitle, IconData icon) {
    final isSelected = _exportType == type;
    
    return GestureDetector(
      onTap: () => setState(() => _exportType = type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6).withOpacity(0.1) : const Color(0xFF2A2A2A),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF404040),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF3B82F6) : Colors.white70,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? const Color(0xFF3B82F6) : Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleProjectSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Project',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF404040)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedProjectId,
              isExpanded: true,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Choose a project...',
                  style: GoogleFonts.inter(color: Colors.white70),
                ),
              ),
              dropdownColor: const Color(0xFF2A2A2A),
              items: widget.availableJobs.map((job) {
                return DropdownMenuItem<String>(
                  value: job.id,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          job.projectName,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${job.facility} • ${job.projectType}',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedProjectId = value),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyReportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSingleProjectSection(),
        const SizedBox(height: 20),
        Text(
          'Select Date',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: Color(0xFF3B82F6),
                      onPrimary: Colors.white,
                      surface: Color(0xFF2A2A2A),
                      onSurface: Colors.white,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) {
              setState(() => _selectedDate = date);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF404040)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, color: Colors.white70),
                const SizedBox(width: 12),
                Text(
                  _selectedDate != null
                      ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                      : 'Select date...',
                  style: GoogleFonts.inter(
                    color: _selectedDate != null ? Colors.white : Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBatchExportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select Projects',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  if (_selectedProjectIds.length == widget.availableJobs.length) {
                    _selectedProjectIds.clear();
                  } else {
                    _selectedProjectIds = widget.availableJobs.map((job) => job.id).toList();
                  }
                });
              },
              child: Text(
                _selectedProjectIds.length == widget.availableJobs.length ? 'Deselect All' : 'Select All',
                style: GoogleFonts.inter(color: const Color(0xFF3B82F6)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF404040)),
          ),
          child: ListView.builder(
            itemCount: widget.availableJobs.length,
            itemBuilder: (context, index) {
              final job = widget.availableJobs[index];
              final isSelected = _selectedProjectIds.contains(job.id);
              
              return CheckboxListTile(
                value: isSelected,
                onChanged: (selected) {
                  setState(() {
                    if (selected == true) {
                      _selectedProjectIds.add(job.id);
                    } else {
                      _selectedProjectIds.remove(job.id);
                    }
                  });
                },
                title: Text(
                  job.projectName,
                  style: GoogleFonts.inter(color: Colors.white),
                ),
                subtitle: Text(
                  '${job.facility} • ${job.projectType}',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                ),
                activeColor: const Color(0xFF3B82F6),
                checkColor: Colors.white,
                tileColor: Colors.transparent,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReportOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Report Options',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          value: _includeAnalytics,
          onChanged: (value) => setState(() => _includeAnalytics = value ?? true),
          title: Text(
            'Include Analytics & Statistics',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          subtitle: Text(
            'Operational metrics and data quality statistics',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
          ),
          activeColor: const Color(0xFF3B82F6),
          tileColor: Colors.transparent,
        ),
        CheckboxListTile(
          value: _includeDailyLogs,
          onChanged: (value) => setState(() => _includeDailyLogs = value ?? true),
          title: Text(
            'Include Daily Logs Summary',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          subtitle: Text(
            'Daily completion status and overview',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
          ),
          activeColor: const Color(0xFF3B82F6),
          tileColor: Colors.transparent,
        ),
        CheckboxListTile(
          value: _includeHourlyData,
          onChanged: (value) => setState(() => _includeHourlyData = value ?? true),
          title: Text(
            'Include Detailed Hourly Data',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          subtitle: Text(
            'Complete thermal readings and measurements',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
          ),
          activeColor: const Color(0xFF3B82F6),
          tileColor: Colors.transparent,
        ),
      ],
    );
  }

  Widget _buildTemplateCustomizationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Template Customization',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        
        // Report Title
        TextFormField(
          initialValue: _reportTitle,
          onChanged: (value) => setState(() => _reportTitle = value),
          style: GoogleFonts.inter(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Custom Report Title',
            labelStyle: GoogleFonts.inter(color: Colors.white70),
            hintText: 'Leave empty for default title',
            hintStyle: GoogleFonts.inter(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF404040)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF404040)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF3B82F6)),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Company Name
        TextFormField(
          initialValue: _companyName,
          onChanged: (value) => setState(() => _companyName = value),
          style: GoogleFonts.inter(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Company Name',
            labelStyle: GoogleFonts.inter(color: Colors.white70),
            hintText: 'Your company name',
            hintStyle: GoogleFonts.inter(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF404040)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF404040)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF3B82F6)),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Theme Selection
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Report Theme',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF404040)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedTheme,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF2A2A2A),
                        items: ['Professional', 'Modern', 'Compact', 'Detailed'].map((theme) {
                          return DropdownMenuItem<String>(
                            value: theme,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                theme,
                                style: GoogleFonts.inter(color: Colors.white),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedTheme = value ?? 'Professional'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CheckboxListTile(
                value: _includeCompanyLogo,
                onChanged: (value) => setState(() => _includeCompanyLogo = value ?? false),
                title: Text(
                  'Include Company Logo',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                ),
                subtitle: Text(
                  'Placeholder for logo integration',
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                ),
                activeColor: const Color(0xFF3B82F6),
                tileColor: Colors.transparent,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Additional Notes
        TextFormField(
          initialValue: _additionalNotes,
          onChanged: (value) => setState(() => _additionalNotes = value),
          style: GoogleFonts.inter(color: Colors.white),
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Additional Notes',
            labelStyle: GoogleFonts.inter(color: Colors.white70),
            hintText: 'Any additional information to include in the report...',
            hintStyle: GoogleFonts.inter(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF404040)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF404040)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF3B82F6)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ReportGenerationState reportState) {
    return Row(
      children: [
        // Status indicator
        Expanded(
          child: reportState.when(
            idle: () => const SizedBox.shrink(),
            generating: () => Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Generating report...',
                  style: GoogleFonts.inter(color: Colors.white70),
                ),
              ],
            ),
            completed: (data, fileName) => Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Report generated successfully',
                  style: GoogleFonts.inter(color: Colors.green),
                ),
              ],
            ),
            onError: (error) => Row(
              children: [
                const Icon(Icons.error, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error: $error',
                    style: GoogleFonts.inter(color: Colors.red),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Cancel button
        TextButton(
          onPressed: reportState.isGenerating ? null : () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: GoogleFonts.inter(color: Colors.white70),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Generate button
        ElevatedButton(
          onPressed: reportState.isGenerating || !_canGenerate() ? null : _generateReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(
            'Generate Report',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  bool _canGenerate() {
    switch (_exportType) {
      case ExportType.single:
        return _selectedProjectId != null;
      case ExportType.daily:
        return _selectedProjectId != null && _selectedDate != null;
      case ExportType.batch:
        return _selectedProjectIds.isNotEmpty;
    }
  }

  void _generateReport() async {
    final notifier = ref.read(reportGenerationProvider.notifier);
    
    switch (_exportType) {
      case ExportType.single:
        final selectedJob = widget.availableJobs.firstWhere((job) => job.id == _selectedProjectId);
        
        // Use dynamic export for Marathon projects and any future dynamic templates
        if (_selectedProjectId == '2025-2-095' || _shouldUseDynamicExport(_selectedProjectId!)) {
          print('🔄 Using dynamic export for project $_selectedProjectId');
          await notifier.generateDynamicProjectReport(
            projectId: _selectedProjectId!,
            projectName: selectedJob.projectName,
          );
        } else {
          print('🔄 Using legacy export for project $_selectedProjectId');
          await notifier.generateProjectReport(
            projectId: _selectedProjectId!,
            projectName: selectedJob.projectName,
          );
        }
        break;
        
      case ExportType.daily:
        final selectedJob = widget.availableJobs.firstWhere((job) => job.id == _selectedProjectId);
        // For daily reports, we'll use the vapor report service
        await notifier.generateVaporReport(
          projectId: _selectedProjectId!,
          date: _selectedDate!,
          projectName: selectedJob.projectName,
        );
        break;
        
      case ExportType.batch:
        // For now, generate the first selected project
        // This can be extended to handle multiple projects
        if (_selectedProjectIds.isNotEmpty) {
          final selectedJob = widget.availableJobs.firstWhere((job) => job.id == _selectedProjectIds.first);
          await notifier.generateProjectReport(
            projectId: _selectedProjectIds.first,
            projectName: selectedJob.projectName,
          );
        }
        break;
    }
    
    // Wait for completion and download
    ref.listen(reportGenerationProvider, (previous, next) {
      next.when(
        idle: () {},
        generating: () {},
        completed: (data, fileName) {
          _downloadFile(data, fileName);
          Navigator.of(context).pop();
        },
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error generating report: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    });
  }

  void _downloadFile(List<int> data, String fileName) {
    final blob = html.Blob([data]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = fileName;
    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
    
    // Record the download in history
    _recordDownloadInHistory(data, fileName);
  }

  void _recordDownloadInHistory(List<int> data, String fileName) {
    String reportType = 'Unknown';
    String projectId = '';
    String projectName = '';
    
    // Determine report type and project info based on current selection
    switch (_exportType) {
      case ExportType.single:
        reportType = 'Project Report';
        if (_selectedProjectId != null) {
          final job = widget.availableJobs.firstWhere((j) => j.id == _selectedProjectId);
          projectId = job.id;
          projectName = job.projectName;
        }
        break;
      case ExportType.daily:
        reportType = 'Daily Report';
        if (_selectedProjectId != null) {
          final job = widget.availableJobs.firstWhere((j) => j.id == _selectedProjectId);
          projectId = job.id;
          projectName = job.projectName;
        }
        break;
      case ExportType.batch:
        reportType = 'Batch Export';
        projectId = 'batch';
        projectName = 'Multiple Projects';
        break;
    }
    
    // Record in Firestore (async, don't wait)
    _historyService.recordDownload(
      fileName: fileName,
      projectId: projectId,
      projectName: projectName,
      reportType: reportType,
      fileSizeBytes: data.length,
      downloadedBy: 'admin', // In a real app, this would be the current user
      metadata: {
        'customTitle': _reportTitle,
        'companyName': _companyName,
        'theme': _selectedTheme,
        'includeCompanyLogo': _includeCompanyLogo,
        'additionalNotes': _additionalNotes,
        'includeAnalytics': _includeAnalytics,
        'includeDailyLogs': _includeDailyLogs,
        'includeHourlyData': _includeHourlyData,
      },
    );
  }
}

enum ExportType {
  single,
  daily,
  batch,
}