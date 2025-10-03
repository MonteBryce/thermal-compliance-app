import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../model/job_data.dart';
import '../routes/route_extensions.dart';
import 'create_demo_job_screen.dart';
import 'import_marathon_job_screen.dart';
import 'thermal_log_list_screen.dart';

class JobSelectorScreen extends StatefulWidget {
  const JobSelectorScreen({super.key});

  @override
  _JobSelectorScreenState createState() => _JobSelectorScreenState();
}

class _JobSelectorScreenState extends State<JobSelectorScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  JobData? _selectedJob;
  bool _isLoading = true;
  String? _error;
  List<JobData> _jobs = [];
  bool _hasInitialized = false;

  // Mock Data
  final List<JobData> _assignedJobs = [
    // Demo project - always appears first
    JobData(
      projectNumber: "DEMO-2025-001",
      projectName: "Demo Methane Job - Deer Park Terminal",
      unitNumber: "DEMO-UNIT-01",
      date: "Demo Available",
      status: "Demo Available",
      location: "Deer Park Terminal",
      workOrderNumber: "DEMO-WO-001",
      tankType: "Storage Tank",
      facilityTarget: "1,000 ppm & 5% LEL",
      operatingTemperature: ">800°F",
      benzeneTarget: "10 PPM",
      h2sAmpRequired: false,
      product: "Methane",
    ),
    // Marathon Real Data project
    JobData(
      projectNumber: "2025-2-095",
      projectName: "Marathon GBR - Tank 223 Thermal Oxidation",
      unitNumber: "Tank-223",
      date: "July 15-17, 2025",
      status: "Completed",
      location: "Texas City, TX",
      workOrderNumber: "M25-021-MTT/10100",
      tankType: "thermal",
      facilityTarget: "10% LEL",
      operatingTemperature: ">1250°F",
      benzeneTarget: "N/A",
      h2sAmpRequired: true,
      product: "Sour Water",
    ),
    JobData(
      projectNumber: "2025-2-100",
      projectName: "2025-2-100 Degas",
      unitNumber: "TO-05",
      date: "Jan 15-17, 2025",
      status: "Completed",
      location: "P66 WWR",
      workOrderNumber: "M25-64-PWI-3100",
      tankType: "IFR",
      facilityTarget: "5,000 ppm & 10% LEL",
      operatingTemperature: ">1450",
      benzeneTarget: "30 PPM",
      h2sAmpRequired: true,
      product: "Crude",
    ),
    JobData(
      projectNumber: "2025-2-101",
      projectName: "2025-2-101 Degas",
      unitNumber: "TO-06",
      date: "Jan 18, 2025",
      status: "In Progress",
      location: "P66 WWR",
      workOrderNumber: "M25-64-PWI-3101",
      tankType: "IFR",
      facilityTarget: "5,000 ppm & 10% LEL",
      operatingTemperature: ">1450",
      benzeneTarget: "30 PPM",
      h2sAmpRequired: true,
      product: "Crude",
    ),
    JobData(
      projectNumber: "2025-2-102",
      projectName: "2025-2-102 Degas",
      unitNumber: "TO-07",
      date: "Jan 21, 2025",
      status: "Pending",
      location: "P66 WWR",
      workOrderNumber: "M25-64-PWI-3102",
      tankType: "IFR",
      facilityTarget: "5,000 ppm & 10% LEL",
      operatingTemperature: ">1450",
      benzeneTarget: "30 PPM",
      h2sAmpRequired: true,
      product: "Crude",
    ),
    JobData(
      projectNumber: "2025-2-103",
      projectName: "2025-2-103 Degas",
      unitNumber: "TO-08",
      date: "Jan 24, 2025",
      status: "Pending",
      location: "P66 WWR",
      workOrderNumber: "M25-64-PWI-3103",
      tankType: "IFR",
      facilityTarget: "5,000 ppm & 10% LEL",
      operatingTemperature: ">1450",
      benzeneTarget: "30 PPM",
      h2sAmpRequired: true,
      product: "Crude",
    ),
    JobData(
      projectNumber: "2025-2-104",
      projectName: "2025-2-104 Degas",
      unitNumber: "TO-09",
      date: "Jan 27, 2025",
      status: "In Progress",
      location: "P66 WWR",
      workOrderNumber: "M25-64-PWI-3104",
      tankType: "IFR",
      facilityTarget: "5,000 ppm & 10% LEL",
      operatingTemperature: ">1450",
      benzeneTarget: "30 PPM",
      h2sAmpRequired: true,
      product: "Crude",
    ),
    JobData(
      projectNumber: "2025-2-106",
      projectName: "2025-2-106 Degas",
      unitNumber: "TO-11",
      date: "Jan 31, 2025",
      status: "In Progress",
      location: "P66 WWR",
      workOrderNumber: "M25-64-PWI-3106",
      tankType: "IFR",
      facilityTarget: "5,000 ppm & 10% LEL",
      operatingTemperature: ">1450",
      benzeneTarget: "30 PPM",
      h2sAmpRequired: true,
      product: "Crude",
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (!_hasInitialized) {
      _fetchJobs();
    }
  }

  Future<void> _fetchJobs() async {
    if (_hasInitialized && _jobs.isNotEmpty) {
      return; // Prevent unnecessary refetches
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      setState(() {
        _jobs = _assignedJobs;
        _isLoading = false;
        _hasInitialized = true;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _handleJobSelect(JobData job) {
    setState(() {
      _selectedJob = job;
    });
    // Navigate directly to project summary which now includes date selector
    context.goToProjectSummary(
      job.projectNumber,
      extra: {
        'initialJob': job,
      },
    );
  }

  Future<void> _handleLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigation will be handled by AuthGate automatically
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_error != null) {
      return _buildErrorScreen();
    }

    return PopScope(
      canPop: false, // Prevent going back to login after successful auth
      child: Scaffold(
        backgroundColor: const Color(0xFF0B132B),
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Select Your Assigned Job",
                        style: GoogleFonts.nunito(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Marathon Real Data Button
                    IconButton(
                      icon: const Icon(Icons.local_gas_station, color: Colors.red),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ImportMarathonJobScreen(),
                          ),
                        ).then((_) {
                          // Refresh the job list after returning
                          _fetchJobs();
                        });
                      },
                      tooltip: 'Import Marathon Real Data',
                    ),
                    // Demo Job Button
                    IconButton(
                      icon: const Icon(Icons.science, color: Colors.blue),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const CreateDemoJobScreen(),
                          ),
                        ).then((_) {
                          // Refresh the job list after returning
                          _fetchJobs();
                        });
                      },
                      tooltip: 'Create Demo Job',
                    ),
                    // Thermal Logs Button
                    IconButton(
                      icon: const Icon(Icons.thermostat, color: Colors.orange),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ThermalLogListScreen(
                              projectId: 'demo-project',
                            ),
                          ),
                        );
                      },
                      tooltip: 'Thermal Logs',
                    ),
                    // OCR Test Button
                    IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      onPressed: () => context.go('/ocr-demo'),
                      tooltip: 'Test OCR',
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: _handleLogout,
                      tooltip: 'Logout',
                    ),
                  ],
                ),
              ),

              // Job List
              Expanded(
                child: _buildJobList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      backgroundColor: Color(0xFF0B132B),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 20),
            Text(
              "Loading Your Assignments",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 50),
              const SizedBox(height: 20),
              Text(
                "Error: $_error",
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchJobs,
                child: const Text("Retry Connection"),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          Text(
            "No Active Assignments",
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobList() {
    if (_jobs.isEmpty) {
      return _buildEmptyState();
    }

    // Group jobs by status for better organization
    final groupedJobs = <String, List<JobData>>{};
    final statusOrder = ['In Progress', 'Pending', 'Demo Available', 'Completed'];
    
    for (final job in _jobs) {
      final status = job.status;
      if (!groupedJobs.containsKey(status)) {
        groupedJobs[status] = [];
      }
      groupedJobs[status]!.add(job);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: statusOrder.length,
      itemBuilder: (context, statusIndex) {
        final status = statusOrder[statusIndex];
        final statusJobs = groupedJobs[status] ?? [];
        
        if (statusJobs.isEmpty) return const SizedBox.shrink();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status group header
            if (statusIndex > 0) const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Row(
                children: [
                  _getStatusIcon(status),
                  const SizedBox(width: 8),
                  Text(
                    status.toUpperCase(),
                    style: GoogleFonts.nunito(
                      color: _getStatusColor(status),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${statusJobs.length}',
                      style: GoogleFonts.nunito(
                        color: _getStatusColor(status),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Jobs in this status
            ...statusJobs.map((job) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildEnhancedJobCard(job),
            )),
          ],
        );
      },
    );
  }

  Widget _buildEnhancedJobCard(JobData job) {
    final isDemo = job.status.toLowerCase() == 'demo available';
    final isInProgress = job.status.toLowerCase() == 'in progress';
    
    return InkWell(
      onTap: () => _handleJobSelect(job),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF152042),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isInProgress ? Colors.blue.withOpacity(0.3) : Colors.transparent,
            width: isInProgress ? 1.5 : 0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with project name and status
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.projectName,
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              color: Colors.grey[400],
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                job.location,
                                style: GoogleFonts.nunito(
                                  color: Colors.grey[400],
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildStatusBadge(job.status),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Job details row
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      icon: Icons.schedule_outlined,
                      label: job.date,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoChip(
                      icon: _getProductIcon(job.product),
                      label: job.product,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Additional details row
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      icon: Icons.thermostat_outlined,
                      label: job.operatingTemperature,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoChip(
                      icon: Icons.science_outlined,
                      label: job.facilityTarget,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              
              if (isDemo) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF7C3AED).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFF7C3AED),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Demo project for training and testing',
                          style: GoogleFonts.nunito(
                            color: const Color(0xFFDDD6FE),
                            fontSize: 12,
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
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color.withOpacity(0.8),
            size: 14,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.nunito(
                color: Colors.white.withOpacity(0.9),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'demo available':
        return const Icon(Icons.science, color: Color(0xFF7C3AED), size: 16);
      case 'completed':
        return const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16);
      case 'in progress':
        return const Icon(Icons.play_circle, color: Color(0xFF3B82F6), size: 16);
      case 'pending':
        return const Icon(Icons.schedule, color: Color(0xFFF59E0B), size: 16);
      default:
        return const Icon(Icons.circle, color: Colors.grey, size: 16);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'demo available':
        return const Color(0xFF7C3AED);
      case 'completed':
        return const Color(0xFF10B981);
      case 'in progress':
        return const Color(0xFF3B82F6);
      case 'pending':
        return const Color(0xFFF59E0B);
      default:
        return Colors.grey;
    }
  }

  IconData _getProductIcon(String product) {
    switch (product.toLowerCase()) {
      case 'methane':
        return Icons.gas_meter;
      case 'crude':
        return Icons.oil_barrel;
      case 'sour water':
        return Icons.water_drop;
      default:
        return Icons.science;
    }
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    Color textColor;
    String text = status;

    switch (status.toLowerCase()) {
      case 'demo available':
        badgeColor = const Color(0xFF7C3AED);
        textColor = const Color(0xFFDDD6FE);
        text = '🎯 Demo';
        break;
      case 'completed':
        badgeColor = const Color(0xFF1C8C4D);
        textColor = const Color(0xFF88E5AD);
        break;
      case 'in progress':
        badgeColor = const Color(0xFF1E40AF);
        textColor = const Color(0xFF93C5FD);
        break;
      case 'pending':
        badgeColor = const Color(0xFF854D0E);
        textColor = const Color(0xFFFCD34D);
        break;
      default:
        badgeColor = Colors.grey;
        textColor = Colors.white70;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        border: Border.all(color: badgeColor.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.nunito(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}
