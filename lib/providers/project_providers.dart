import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/firestore_models.dart';
import '../services/project_service.dart';
import '../services/local_database_service.dart';
import '../services/auth_service.dart';
import '../models/hive_models.dart';

/// Provider for the currently selected project
final selectedProjectProvider = StateNotifierProvider<SelectedProjectNotifier, ProjectDocument?>((ref) {
  return SelectedProjectNotifier();
});

/// Provider for the list of user projects
final userProjectsProvider = FutureProvider<List<ProjectDocument>>((ref) async {
  return ProjectService().fetchUserProjects();
});

/// Provider for cached projects (offline)
final cachedProjectsProvider = FutureProvider<List<ProjectDocument>>((ref) async {
  return ProjectService().getCachedProjects();
});

/// Notifier for managing the selected project state
class SelectedProjectNotifier extends StateNotifier<ProjectDocument?> {
  SelectedProjectNotifier() : super(null) {
    _loadSelectedProject();
  }

  /// Load the previously selected project from cache
  Future<void> _loadSelectedProject() async {
    try {
      final session = await LocalDatabaseService.getCurrentUserSession();
      if (session?.currentProjectId != null) {
        final project = await _getProjectById(session!.currentProjectId!);
        if (project != null) {
          state = project;
          debugPrint('Loaded selected project from session: ${project.projectName}');
        }
      }
    } catch (e) {
      debugPrint('Failed to load selected project: $e');
    }
  }

  /// Select a project and cache it locally
  Future<void> selectProject(ProjectDocument project) async {
    try {
      state = project;
      
      // Cache the project for offline use
      final userId = AuthService.getCurrentUserId();
      if (userId != null) {
        final cachedProject = CachedProject(
          projectId: project.projectId,
          projectName: project.projectName,
          projectNumber: project.projectNumber,
          location: project.location,
          unitNumber: project.unitNumber,
          metadata: {
            'workOrderNumber': project.workOrderNumber,
            'tankType': project.tankType,
            'facilityTarget': project.facilityTarget,
            'operatingTemperature': project.operatingTemperature,
            'benzeneTarget': project.benzeneTarget,
            'h2sAmpRequired': project.h2sAmpRequired,
            'product': project.product,
            'projectStartDate': project.projectStartDate?.toIso8601String(),
          },
          cachedAt: DateTime.now(),
          createdBy: userId,
        );
        
        await LocalDatabaseService.cacheProject(cachedProject);
        
        // Update user session with current project
        await LocalDatabaseService.updateCurrentProject(
          project.projectId,
          project.projectName,
        );
        
        debugPrint('Selected and cached project: ${project.projectName}');
      }
    } catch (e) {
      debugPrint('Failed to select project: $e');
      throw Exception('Failed to select project: $e');
    }
  }

  /// Clear the selected project
  void clearSelection() {
    state = null;
    debugPrint('Cleared selected project');
  }

  /// Get project by ID (try online first, then cache)
  Future<ProjectDocument?> _getProjectById(String projectId) async {
    try {
      // Try to get from ProjectService first
      final projectService = ProjectService();
      final project = await projectService.getProject(projectId);
      if (project != null) {
        return project;
      }
      
      // Fall back to cached project
      final cachedProject = await LocalDatabaseService.getCachedProject(projectId);
      if (cachedProject != null) {
        return _convertCachedToProject(cachedProject);
      }
      
      return null;
    } catch (e) {
      debugPrint('Failed to get project by ID: $e');
      return null;
    }
  }

  /// Convert cached project to ProjectDocument
  ProjectDocument _convertCachedToProject(CachedProject cached) {
    return ProjectDocument(
      projectId: cached.projectId,
      projectName: cached.projectName,
      projectNumber: cached.projectNumber,
      location: cached.location,
      unitNumber: cached.unitNumber,
      workOrderNumber: cached.metadata['workOrderNumber'] ?? '',
      tankType: cached.metadata['tankType'] ?? '',
      facilityTarget: cached.metadata['facilityTarget'] ?? '',
      operatingTemperature: cached.metadata['operatingTemperature'] ?? '',
      benzeneTarget: cached.metadata['benzeneTarget'] ?? '',
      h2sAmpRequired: cached.metadata['h2sAmpRequired'] ?? false,
      product: cached.metadata['product'] ?? '',
      projectStartDate: cached.metadata['projectStartDate'] != null
          ? DateTime.parse(cached.metadata['projectStartDate'])
          : null,
      createdAt: cached.cachedAt,
      updatedAt: cached.cachedAt,
      createdBy: cached.createdBy,
    );
  }
}

/// Extension on ProjectService for user projects
extension ProjectServiceExtension on ProjectService {
  /// Fetch all projects assigned to the current user
  Future<List<ProjectDocument>> fetchUserProjects({bool forceRefresh = false}) async {
    final userId = AuthService.getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    try {
      // For now, we'll use the existing mock data approach
      // TODO: Replace with actual Firestore query when ready
      final mockProjects = [
        ProjectDocument(
          projectId: 'demo-project-1',
          projectName: 'Demo Methane Job - Deer Park Terminal',
          projectNumber: 'DEMO-2025-001',
          location: 'Deer Park Terminal',
          unitNumber: 'DEMO-UNIT-01',
          workOrderNumber: 'DEMO-WO-001',
          tankType: 'Storage Tank',
          facilityTarget: '1,000 ppm & 5% LEL',
          operatingTemperature: '>800°F',
          benzeneTarget: '10 PPM',
          h2sAmpRequired: false,
          product: 'Methane',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now(),
          createdBy: userId,
        ),
        ProjectDocument(
          projectId: 'marathon-project-1',
          projectName: 'Marathon GBR - Tank 223 Thermal Oxidation',
          projectNumber: '2025-2-095',
          location: 'Texas City, TX',
          unitNumber: 'Tank-223',
          workOrderNumber: 'M25-021-MTT/10100',
          tankType: 'thermal',
          facilityTarget: '10% LEL',
          operatingTemperature: '>1250°F',
          benzeneTarget: 'N/A',
          h2sAmpRequired: true,
          product: 'Sour Water',
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
          updatedAt: DateTime.now(),
          createdBy: userId,
        ),
        ProjectDocument(
          projectId: 'p66-project-1',
          projectName: '2025-2-100 Degas',
          projectNumber: '2025-2-100',
          location: 'P66 WWR',
          unitNumber: 'TO-05',
          workOrderNumber: 'M25-64-PWI-3100',
          tankType: 'IFR',
          facilityTarget: '5,000 ppm & 10% LEL',
          operatingTemperature: '>1450°F',
          benzeneTarget: '30 PPM',
          h2sAmpRequired: true,
          product: 'Crude',
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          updatedAt: DateTime.now(),
          createdBy: userId,
        ),
      ];
      
      // Cache all projects for offline use
      for (final project in mockProjects) {
        final cachedProject = CachedProject(
          projectId: project.projectId,
          projectName: project.projectName,
          projectNumber: project.projectNumber,
          location: project.location,
          unitNumber: project.unitNumber,
          metadata: {
            'workOrderNumber': project.workOrderNumber,
            'tankType': project.tankType,
            'facilityTarget': project.facilityTarget,
            'operatingTemperature': project.operatingTemperature,
            'benzeneTarget': project.benzeneTarget,
            'h2sAmpRequired': project.h2sAmpRequired,
            'product': project.product,
            'projectStartDate': project.projectStartDate?.toIso8601String(),
          },
          cachedAt: DateTime.now(),
          createdBy: userId,
        );
        
        await LocalDatabaseService.cacheProject(cachedProject);
      }
      
      debugPrint('Fetched and cached ${mockProjects.length} projects');
      return mockProjects;
      
    } catch (e) {
      debugPrint('Failed to fetch projects: $e');
      
      // Fall back to cached projects
      final cachedProjects = await getCachedProjects();
      if (cachedProjects.isEmpty) {
        throw Exception('No projects available offline: $e');
      }
      
      return cachedProjects;
    }
  }
  
  /// Get projects from local cache only
  Future<List<ProjectDocument>> getCachedProjects() async {
    final cachedProjects = await LocalDatabaseService.getUserCachedProjects();
    return cachedProjects.map((cached) => _convertCachedToProject(cached)).toList();
  }
  
  /// Convert cached project to ProjectDocument
  ProjectDocument _convertCachedToProject(CachedProject cached) {
    return ProjectDocument(
      projectId: cached.projectId,
      projectName: cached.projectName,
      projectNumber: cached.projectNumber,
      location: cached.location,
      unitNumber: cached.unitNumber,
      workOrderNumber: cached.metadata['workOrderNumber'] ?? '',
      tankType: cached.metadata['tankType'] ?? '',
      facilityTarget: cached.metadata['facilityTarget'] ?? '',
      operatingTemperature: cached.metadata['operatingTemperature'] ?? '',
      benzeneTarget: cached.metadata['benzeneTarget'] ?? '',
      h2sAmpRequired: cached.metadata['h2sAmpRequired'] ?? false,
      product: cached.metadata['product'] ?? '',
      projectStartDate: cached.metadata['projectStartDate'] != null
          ? DateTime.parse(cached.metadata['projectStartDate'])
          : null,
      createdAt: cached.cachedAt,
      updatedAt: cached.cachedAt,
      createdBy: cached.createdBy,
    );
  }
}