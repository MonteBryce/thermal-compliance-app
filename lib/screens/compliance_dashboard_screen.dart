import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/compliance_stat_card.dart';
import '../widgets/compliance_header_bar.dart';
import '../widgets/compliance_filters_row.dart';
import '../widgets/compliance_data_table.dart';

class ComplianceDashboardScreen extends StatefulWidget {
  const ComplianceDashboardScreen({super.key});

  @override
  State<ComplianceDashboardScreen> createState() => _ComplianceDashboardScreenState();
}

class _ComplianceDashboardScreenState extends State<ComplianceDashboardScreen> {
  String? _selectedStatus;
  String? _selectedLogType;
  String? _selectedOperator;
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';
  
  late List<ComplianceJobData> _allJobs;
  late List<ComplianceJobData> _filteredJobs;

  @override
  void initState() {
    super.initState();
    _allJobs = ComplianceJobData.getMockData();
    _filteredJobs = _allJobs;
  }

  void _applyFilters() {
    setState(() {
      _filteredJobs = _allJobs.where((job) {
        // Status filter
        if (_selectedStatus != null && job.status != _selectedStatus) {
          return false;
        }
        
        // Log type filter
        if (_selectedLogType != null && job.logType != _selectedLogType) {
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: Column(
        children: [
          // Header Bar
          ComplianceHeaderBar(
            onRefresh: () {
              // Refresh data
            },
            onNewJob: () {
              // Create new job
            },
            onExport: () {
              // Export data
            },
            onSettings: () {
              // Open settings
            },
            onSearchChanged: (query) {
              setState(() {
                _searchQuery = query;
              });
              _applyFilters();
            },
          ),
          
          // Main Content
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 768;
                final isMediumScreen = constraints.maxWidth < 1024;
                
                return Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                  child: Column(
                    children: [
                      // Summary Cards
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final cardWidth = (constraints.maxWidth - 48) / 4; // 4 cards with 3 gaps of 16px
                          final shouldWrap = cardWidth < 200 || isSmallScreen;
                      
                      final cards = [
                        const ComplianceStatCard(
                          title: 'Total Active Jobs',
                          value: '12',
                          subtitle: '3 new this week',
                          icon: Icons.work_outline,
                          iconColor: Color(0xFF3B82F6),
                        ),
                        const ComplianceStatCard(
                          title: '% Logs Completed',
                          value: '73%',
                          subtitle: 'Average completion',
                          icon: Icons.trending_up,
                          iconColor: Color(0xFF10B981),
                          showProgress: true,
                          progressValue: 73,
                        ),
                        const ComplianceStatCard(
                            title: 'Jobs with Warnings',
                            value: '3',
                            subtitle: 'Requires attention',
                            icon: Icons.warning,
                            iconColor: Color(0xFFF59E0B),
                          ),
                          const ComplianceStatCard(
                            title: 'Jobs Passed All Checks',
                            value: '9',
                            subtitle: 'Meeting standards',
                            icon: Icons.check_circle,
                            iconColor: Color(0xFF10B981),
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
                        ComplianceFiltersRow(
                      selectedStatus: _selectedStatus,
                      selectedLogType: _selectedLogType,
                      selectedOperator: _selectedOperator,
                      selectedDateRange: _selectedDateRange,
                      onStatusChanged: (status) {
                        setState(() {
                          _selectedStatus = status;
                        });
                        _applyFilters();
                      },
                      onLogTypeChanged: (logType) {
                        setState(() {
                          _selectedLogType = logType;
                        });
                        _applyFilters();
                      },
                      onOperatorChanged: (operator) {
                        setState(() {
                          _selectedOperator = operator;
                        });
                        _applyFilters();
                      },
                          onDateRangeChanged: (dateRange) {
                            setState(() {
                              _selectedDateRange = dateRange;
                            });
                            _applyFilters();
                          },
                        ),
                        
                        SizedBox(height: isSmallScreen ? 16 : 24),
                        
                        // Data Table
                        Expanded(
                          child: ComplianceDataTable(
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

  void _showJobDetails(ComplianceJobData job) {
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
            Text('Tank ID: ${job.tankId}', 
                 style: const TextStyle(color: Colors.white70)),
            Text('Log Type: ${job.logType}', 
                 style: const TextStyle(color: Colors.white70)),
            Text('Progress: ${job.hoursLogged}/${job.totalHours} hours', 
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

  void _showAssignDialog(ComplianceJobData job) {
    // Show assign operator dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Assign operators to ${job.projectName}'),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
    );
  }

  void _exportJob(ComplianceJobData job) {
    // Export job data
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting ${job.projectName}...'),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
    );
  }

  void _editJob(ComplianceJobData job) {
    // Edit job
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit ${job.projectName}'),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
    );
  }

  void _archiveJob(ComplianceJobData job) {
    // Archive job
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Archived ${job.projectName}'),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
    );
  }
}
