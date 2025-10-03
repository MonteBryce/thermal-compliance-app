import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../model/job_data.dart';
import '../routes/route_extensions.dart';
import '../services/project_data_service.dart';
import '../providers/app_state_providers.dart';

/// Provider for managing project data state
final projectDataProvider = StateNotifierProvider<ProjectDataNotifier, ProjectDataState>((ref) {
  return ProjectDataNotifier();
});

/// State management for project data
class ProjectDataState {
  final List<JobData> projects;
  final bool isLoading;
  final String? error;
  
  const ProjectDataState({
    this.projects = const [],
    this.isLoading = false,
    this.error,
  });
  
  ProjectDataState copyWith({
    List<JobData>? projects,
    bool? isLoading,
    String? error,
  }) {
    return ProjectDataState(
      projects: projects ?? this.projects,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// State notifier for project data operations
class ProjectDataNotifier extends StateNotifier<ProjectDataState> {
  ProjectDataNotifier() : super(const ProjectDataState()) {
    _loadProjects();
  }
  
  /// Load projects from Hive storage
  Future<void> _loadProjects() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Initialize with demo data if needed
      await ProjectDataService.initializeWithDemoData();
      
      // Load all projects from Hive
      final cachedProjects = ProjectDataService.getAllProjects();
      
      // Convert to JobData for UI compatibility
      final projects = cachedProjects
          .map((cached) => ProjectDataService.cachedProjectToJobData(cached))
          .toList();
      
      // Sort projects: Demo first, then by status (In Progress, Pending, Completed)
      projects.sort((a, b) {
        // Demo projects first
        if (a.status.contains('Demo')) return -1;
        if (b.status.contains('Demo')) return 1;
        
        // Then by status priority
        final statusPriority = {
          'In Progress': 0,
          'Pending': 1,
          'Completed': 2,
        };
        
        final aPriority = statusPriority[a.status] ?? 3;
        final bPriority = statusPriority[b.status] ?? 3;
        
        return aPriority.compareTo(bPriority);
      });
      
      state = state.copyWith(isLoading: false, projects: projects);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
  
  /// Refresh projects from storage
  Future<void> refreshProjects() async {
    await _loadProjects();
  }
  
  /// Add a new project to storage
  Future<void> addProject(JobData job) async {
    try {
      final cachedProject = ProjectDataService.jobDataToCachedProject(job, 'current_user');
      await ProjectDataService.saveProject(cachedProject);
      await _loadProjects(); // Refresh the list
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
  
  /// Remove a project from storage
  Future<void> removeProject(String projectId) async {
    try {
      await ProjectDataService.removeProject(projectId);
      await _loadProjects(); // Refresh the list
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

/// Enhanced project selector screen with offline-first Hive storage
class EnhancedProjectSelectorScreen extends ConsumerWidget {
  const EnhancedProjectSelectorScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectState = ref.watch(projectDataProvider);
    
    return PopScope(
      canPop: false, // Prevent going back to login after successful auth
      child: Scaffold(
        backgroundColor: const Color(0xFF0B132B),
        body: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context, ref),
              // Project List
              Expanded(
                child: _buildContent(context, ref, projectState),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "Select Your Project",
              style: GoogleFonts.nunito(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ref.read(projectDataProvider.notifier).refreshProjects(),
            tooltip: 'Refresh Projects',
          ),
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              // TODO: Navigate to settings screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings coming soon!'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, ProjectDataState state) {
    if (state.isLoading) {
      return _buildLoadingScreen();
    }
    
    if (state.error != null) {
      return _buildErrorScreen(context, ref, state.error!);
    }
    
    if (state.projects.isEmpty) {
      return _buildEmptyState();
    }
    
    return _buildProjectList(context, state.projects, ref);
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 20),
          Text(
            "Loading Your Projects",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 50),
            const SizedBox(height: 20),
            Text(
              "Error loading projects",
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              error,
              style: const TextStyle(color: Colors.red, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => ref.read(projectDataProvider.notifier).refreshProjects(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E40AF),
                foregroundColor: Colors.white,
              ),
              child: const Text("Try Again"),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildProjectList(BuildContext context, List<JobData> projects, WidgetRef ref) {
    return Column(
      children: [
        // Offline indicator
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.offline_bolt, color: Colors.green, size: 16),
              const SizedBox(width: 8),
              Text(
                "Offline Mode - ${projects.length} projects cached locally",
                style: GoogleFonts.nunito(
                  color: Colors.green,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        // Project list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildProjectCard(context, project, ref),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProjectCard(BuildContext context, JobData project, WidgetRef ref) {
    return InkWell(
      onTap: () => _handleProjectSelect(context, project, ref),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF152042),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project title and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project.projectName,
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusBadge(project.status),
                ],
              ),
              const SizedBox(height: 8),
              // Project details
              _buildDetailRow(Icons.numbers, "Project #", project.projectNumber),
              _buildDetailRow(Icons.location_on, "Location", project.location),
              _buildDetailRow(Icons.schedule, "Date", project.date),
              if (project.unitNumber.isNotEmpty)
                _buildDetailRow(Icons.precision_manufacturing, "Unit", project.unitNumber),
            ],
          ),
        ),
      ),
    );
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400], size: 16),
          const SizedBox(width: 8),
          Text(
            "$label: ",
            style: GoogleFonts.nunito(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.folder_open, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          Text(
            "No Projects Available",
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Projects are stored locally on your device",
            style: GoogleFonts.nunito(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _handleProjectSelect(BuildContext context, JobData project, WidgetRef ref) {
    // Store selected project in global state
    ref.read(selectedProjectProvider.notifier).selectProject(project);
    
    // Update workflow step
    ref.read(workflowStepProvider.notifier).state = WorkflowStep.dailySummary;
    
    // Navigate to daily summary screen
    context.goToProjectSummary(
      project.projectNumber,
      extra: {
        'initialJob': project,
      },
    );
  }

}