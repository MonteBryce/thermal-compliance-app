import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/compliance_stat_card.dart';
import '../widgets/compliance_header_bar.dart';
import '../widgets/job_filters_row.dart';
import '../models/job_dashboard_models.dart';
import '../widgets/job_data_table.dart';
import '../widgets/excel_export_dialog.dart';
import '../services/job_dashboard_service.dart';

class MainJobDashboardScreen extends ConsumerStatefulWidget {
  const MainJobDashboardScreen({super.key});

  @override
  ConsumerState<MainJobDashboardScreen> createState() => _MainJobDashboardScreenState();
}

class _MainJobDashboardScreenState extends ConsumerState<MainJobDashboardScreen> {
  String? _selectedStatus;
  String? _selectedProject;
  String? _selectedOperator;
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';
  
  final JobDashboardService _dashboardService = JobDashboardService();
  late Stream<List<JobDashboardData>> _jobsStream;
  late List<JobDashboardData> _filteredJobs = [];
  JobDashboardSummary? _summary;

  @override
  void initState() {
    super.initState();
    _jobsStream = _dashboardService.getJobDashboardStream();
    _loadSummary();
  }

  void _loadSummary() async {
    try {
      final summary = await _dashboardService.getDashboardSummary();
      setState(() {
        _summary = summary;
      });
    } catch (e) {
      print('Error loading summary: $e');
    }
  }

  void _applyFilters(List<JobDashboardData> allJobs) {
    _filteredJobs = allJobs.where((job) {
        // Status filter
        if (_selectedStatus != null && job.status != _selectedStatus) {
          return false;
        }
        
        // Project filter
        if (_selectedProject != null && job.projectType != _selectedProject) {
          return false;
        }
        
        // Operator filter
        if (_selectedOperator != null && 
            !job.assignedOperators.contains(_selectedOperator)) {
          return false;
        }
        
        // Search filter
        if (_searchQuery.isNotEmpty &&
            !job.projectName.toLowerCase().contains(_searchQuery.toLowerCase()) &&
            !job.facility.toLowerCase().contains(_searchQuery.toLowerCase())) {
          return false;
        }
        
        return true;
      }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _buildDarkTheme(),
      home: Scaffold(
        backgroundColor: const Color(0xFF111111),
        body: StreamBuilder<List<JobDashboardData>>(
          stream: _jobsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }
            
            final allJobs = snapshot.data ?? [];
            _applyFilters(allJobs);
            
            return Column(
              children: [
                // Header Bar
                ComplianceHeaderBar(
                  onRefresh: () {
                    // Refresh job data
                    _loadSummary();
                  },
              onNewJob: () {
                // Create new job
                _showCreateJobDialog();
              },
              onExport: () {
                // Export data
                _exportJobData();
              },
              onSettings: () {
                // Open settings
                _showSettingsDialog();
              },
              onSearchChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
                _applyFilters(allJobs);
              },
            ),
            
            // Main Content
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isSmallScreen = constraints.maxWidth < 768;
                  
                  return Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                    child: Column(
                      children: [
                        // Summary Cards
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final cardWidth = (constraints.maxWidth - 48) / 4;
                            final shouldWrap = cardWidth < 200 || isSmallScreen;
                            
                            final cards = [
                              ComplianceStatCard(
                                title: 'Active Projects',
                                value: '${_getActiveJobsCount()}',
                                subtitle: '${_getNewJobsThisWeek()} new this week',
                                icon: Icons.work_outline,
                                iconColor: const Color(0xFF3B82F6),
                              ),
                              ComplianceStatCard(
                                title: 'Completion Rate',
                                value: '${_getCompletionRate()}%',
                                subtitle: 'Average across all jobs',
                                icon: Icons.trending_up,
                                iconColor: const Color(0xFF10B981),
                                showProgress: true,
                                progressValue: _getCompletionRate().toDouble(),
                              ),
                              ComplianceStatCard(
                                title: 'Pending Review',
                                value: '${_getPendingReviewCount()}',
                                subtitle: 'Requires attention',
                                icon: Icons.pending_actions,
                                iconColor: const Color(0xFFF59E0B),
                              ),
                              ComplianceStatCard(
                                title: 'Completed Today',
                                value: '${_getCompletedTodayCount()}',
                                subtitle: 'Jobs finished',
                                icon: Icons.check_circle,
                                iconColor: const Color(0xFF10B981),
                              ),
                            ];
                            
                            if (shouldWrap) {
                              final crossAxisCount = isSmallScreen ? 1 : 2;
                              return SizedBox(
                                height: isSmallScreen ? 600 : 300,
                                child: GridView.count(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: isSmallScreen ? 2.5 : 1.4,
                                  children: cards,
                                ),
                              );
                            } else {
                              return SizedBox(
                                height: 140,
                                child: Row(
                                  children: [
                                    for (int i = 0; i < cards.length; i++) ...[
                                      if (i > 0) const SizedBox(width: 16),
                                      Expanded(child: cards[i]),
                                    ],
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                        
                        SizedBox(height: isSmallScreen ? 16 : 24),
                        
                        // Filters Row
                        JobFiltersRow(
                          selectedStatus: _selectedStatus,
                          selectedProject: _selectedProject,
                          selectedOperator: _selectedOperator,
                          selectedDateRange: _selectedDateRange,
                          onStatusChanged: (status) {
                            setState(() {
                              _selectedStatus = status;
                            });
                            _applyFilters(allJobs);
                          },
                          onProjectChanged: (project) {
                            setState(() {
                              _selectedProject = project;
                            });
                            _applyFilters(allJobs);
                          },
                          onOperatorChanged: (operator) {
                            setState(() {
                              _selectedOperator = operator;
                            });
                            _applyFilters(allJobs);
                          },
                          onDateRangeChanged: (dateRange) {
                            setState(() {
                              _selectedDateRange = dateRange;
                            });
                            _applyFilters(allJobs);
                          },
                        ),
                        
                        SizedBox(height: isSmallScreen ? 16 : 24),
                        
                        // Jobs Data Table
                        Expanded(
                          child: JobDataTable(
                            jobs: _filteredJobs,
                            onViewJob: (job) {
                              _showJobDetails(job);
                            },
                            onAssignJob: (job) {
                              _showAssignDialog(job);
                            },
                            onExportJob: (job) {
                              _exportJob(job);
                            },
                            onEditJob: (job) {
                              _editJob(job);
                            },
                            onArchiveJob: (job) {
                              _archiveJob(job);
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
              ],
            );
          },
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF111111),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF3B82F6),
        surface: Color(0xFF1E1E1E),
        onSurface: Colors.white,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: Color(0xFF1E1E1E),
      ),
    );
  }

  // Analytics helper methods using summary data
  int _getActiveJobsCount() {
    return _summary?.totalActiveJobs ?? 0;
  }

  int _getNewJobsThisWeek() {
    return _summary?.newJobsThisWeek ?? 0;
  }

  int _getCompletionRate() {
    return _summary?.averageCompletionRate.round() ?? 0;
  }

  int _getPendingReviewCount() {
    return _summary?.pendingReviewCount ?? 0;
  }

  int _getCompletedTodayCount() {
    return _summary?.completedTodayCount ?? 0;
  }

  // Dialog methods
  void _showCreateJobDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          'Create New Job',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        content: const Text(
          'Job creation form would go here.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          'Dashboard Settings',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        content: const Text(
          'Settings panel would go here.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _exportJobData() {
    showDialog(
      context: context,
      builder: (context) => ExcelExportDialog(
        availableJobs: _filteredJobs,
      ),
    );
  }

  void _showJobDetails(JobDashboardData job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          job.projectName,
          style: GoogleFonts.inter(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Facility: ${job.facility}', 
                 style: const TextStyle(color: Colors.white70)),
            Text('Project Type: ${job.projectType}', 
                 style: const TextStyle(color: Colors.white70)),
            Text('Progress: ${job.hoursLogged}/${job.totalHours} hours', 
                 style: const TextStyle(color: Colors.white70)),
            Text('Priority: ${job.priority}', 
                 style: const TextStyle(color: Colors.white70)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAssignDialog(JobDashboardData job) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Assign operators to ${job.projectName}'),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
    );
  }

  void _exportJob(JobDashboardData job) {
    showDialog(
      context: context,
      builder: (context) => ExcelExportDialog(
        availableJobs: [job],
        selectedJob: job,
      ),
    );
  }

  void _editJob(JobDashboardData job) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit ${job.projectName}'),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
    );
  }

  void _archiveJob(JobDashboardData job) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Archived ${job.projectName}'),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
    );
  }
}