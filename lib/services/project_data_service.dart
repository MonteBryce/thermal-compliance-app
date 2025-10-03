import 'package:hive_flutter/hive_flutter.dart';
import '../models/hive_models.dart';
import '../model/job_data.dart';

/// Service for managing project data using Hive offline storage
class ProjectDataService {
  static const String _projectsBoxName = 'cachedProjects';
  
  /// Get the Hive box for cached projects
  static Box<CachedProject> get _projectsBox => Hive.box<CachedProject>(_projectsBoxName);
  
  /// Initialize the service with demo data if no projects exist
  static Future<void> initializeWithDemoData() async {
    final box = _projectsBox;
    
    // If we already have projects, don't add demo data again
    if (box.isNotEmpty) return;
    
    // Demo project data
    final demoProjects = [
      _createDemoProject(
        projectId: "demo-2025-001",
        projectNumber: "DEMO-2025-001",
        projectName: "Demo Methane Job - Deer Park Terminal",
        location: "Deer Park Terminal",
        unitNumber: "DEMO-UNIT-01",
        metadata: {
          'workOrderNumber': 'DEMO-WO-001',
          'tankType': 'Storage Tank',
          'facilityTarget': '1,000 ppm & 5% LEL',
          'operatingTemperature': '>800°F',
          'benzeneTarget': '10 PPM',
          'h2sAmpRequired': false,
          'product': 'Methane',
          'status': 'Demo Available',
          'date': 'Demo Available',
        },
      ),
      _createDemoProject(
        projectId: "2025-2-095",
        projectNumber: "2025-2-095",
        projectName: "Marathon GBR - Tank 223 Thermal Oxidation",
        location: "Texas City, TX",
        unitNumber: "Tank-223",
        metadata: {
          'workOrderNumber': 'M25-021-MTT/10100',
          'tankType': 'thermal',
          'facilityTarget': '10% LEL',
          'operatingTemperature': '>1250°F',
          'benzeneTarget': 'N/A',
          'h2sAmpRequired': true,
          'product': 'Sour Water',
          'status': 'Completed',
          'date': 'July 15-17, 2025',
        },
      ),
      _createDemoProject(
        projectId: "2025-2-101",
        projectNumber: "2025-2-101",
        projectName: "2025-2-101 Degas",
        location: "P66 WWR",
        unitNumber: "TO-06",
        metadata: {
          'workOrderNumber': 'M25-64-PWI-3101',
          'tankType': 'IFR',
          'facilityTarget': '5,000 ppm & 10% LEL',
          'operatingTemperature': '>1450',
          'benzeneTarget': '30 PPM',
          'h2sAmpRequired': true,
          'product': 'Crude',
          'status': 'In Progress',
          'date': 'Jan 18, 2025',
        },
      ),
      _createDemoProject(
        projectId: "2025-2-102",
        projectNumber: "2025-2-102",
        projectName: "2025-2-102 Degas",
        location: "P66 WWR",
        unitNumber: "TO-07",
        metadata: {
          'workOrderNumber': 'M25-64-PWI-3102',
          'tankType': 'IFR',
          'facilityTarget': '5,000 ppm & 10% LEL',
          'operatingTemperature': '>1450',
          'benzeneTarget': '30 PPM',
          'h2sAmpRequired': true,
          'product': 'Crude',
          'status': 'Pending',
          'date': 'Jan 21, 2025',
        },
      ),
    ];
    
    // Add all demo projects to Hive
    for (final project in demoProjects) {
      await box.put(project.projectId, project);
    }
  }
  
  /// Get all cached projects
  static List<CachedProject> getAllProjects() {
    return _projectsBox.values.toList();
  }
  
  /// Get a specific project by ID
  static CachedProject? getProject(String projectId) {
    return _projectsBox.get(projectId);
  }
  
  /// Convert CachedProject to JobData for compatibility
  static JobData cachedProjectToJobData(CachedProject project) {
    return JobData(
      projectNumber: project.projectNumber,
      projectName: project.projectName,
      unitNumber: project.unitNumber,
      date: project.metadata['date'] ?? '',
      status: project.metadata['status'] ?? 'Unknown',
      location: project.location,
      workOrderNumber: project.metadata['workOrderNumber'] ?? '',
      tankType: project.metadata['tankType'] ?? '',
      facilityTarget: project.metadata['facilityTarget'] ?? '',
      operatingTemperature: project.metadata['operatingTemperature'] ?? '',
      benzeneTarget: project.metadata['benzeneTarget'] ?? '',
      h2sAmpRequired: project.metadata['h2sAmpRequired'] ?? false,
      product: project.metadata['product'] ?? '',
    );
  }
  
  /// Convert JobData to CachedProject for storage
  static CachedProject jobDataToCachedProject(JobData job, String userId) {
    return CachedProject(
      projectId: job.projectNumber,
      projectName: job.projectName,
      projectNumber: job.projectNumber,
      location: job.location,
      unitNumber: job.unitNumber,
      metadata: {
        'workOrderNumber': job.workOrderNumber,
        'tankType': job.tankType,
        'facilityTarget': job.facilityTarget,
        'operatingTemperature': job.operatingTemperature,
        'benzeneTarget': job.benzeneTarget,
        'h2sAmpRequired': job.h2sAmpRequired,
        'product': job.product,
        'status': job.status,
        'date': job.date,
      },
      cachedAt: DateTime.now(),
      createdBy: userId,
    );
  }
  
  /// Add or update a project
  static Future<void> saveProject(CachedProject project) async {
    await _projectsBox.put(project.projectId, project);
  }
  
  /// Remove a project
  static Future<void> removeProject(String projectId) async {
    await _projectsBox.delete(projectId);
  }
  
  /// Clear all projects
  static Future<void> clearAllProjects() async {
    await _projectsBox.clear();
  }
  
  /// Get projects by status
  static List<CachedProject> getProjectsByStatus(String status) {
    return _projectsBox.values
        .where((project) => project.metadata['status'] == status)
        .toList();
  }
  
  /// Helper method to create demo projects
  static CachedProject _createDemoProject({
    required String projectId,
    required String projectNumber,
    required String projectName,
    required String location,
    required String unitNumber,
    required Map<String, dynamic> metadata,
  }) {
    return CachedProject(
      projectId: projectId,
      projectName: projectName,
      projectNumber: projectNumber,
      location: location,
      unitNumber: unitNumber,
      metadata: metadata,
      cachedAt: DateTime.now(),
      createdBy: 'system',
    );
  }
}