import 'package:flutter/foundation.dart';
import '../models/firestore_models.dart';
import '../models/hive_models.dart';
import 'local_database_service.dart';

/// Service for handling form pre-fill logic based on selected project
class FormPrefillService {
  
  /// Get pre-fill data for a new log entry based on the selected project
  static Future<Map<String, dynamic>> getLogEntryPrefillData({
    ProjectDocument? selectedProject,
    String? date,
    String? hour,
  }) async {
    final prefillData = <String, dynamic>{};
    
    // If no project is provided, try to get the current selected project
    if (selectedProject == null) {
      final session = await LocalDatabaseService.getCurrentUserSession();
      if (session?.currentProjectId != null) {
        final cachedProject = await LocalDatabaseService.getCachedProject(session!.currentProjectId!);
        if (cachedProject != null) {
          selectedProject = _convertCachedToProject(cachedProject);
        }
      }
    }
    
    if (selectedProject != null) {
      // Basic project information
      prefillData['projectId'] = selectedProject.projectId;
      prefillData['projectName'] = selectedProject.projectName;
      prefillData['projectNumber'] = selectedProject.projectNumber;
      prefillData['location'] = selectedProject.location;
      prefillData['unitNumber'] = selectedProject.unitNumber;
      
      // Additional project metadata
      prefillData['workOrderNumber'] = selectedProject.workOrderNumber;
      prefillData['tankType'] = selectedProject.tankType;
      prefillData['facilityTarget'] = selectedProject.facilityTarget;
      prefillData['operatingTemperature'] = selectedProject.operatingTemperature;
      prefillData['benzeneTarget'] = selectedProject.benzeneTarget;
      prefillData['h2sAmpRequired'] = selectedProject.h2sAmpRequired;
      prefillData['product'] = selectedProject.product;
      
      // Form-specific defaults based on project type
      prefillData.addAll(_getProjectTypeDefaults(selectedProject));
      
      debugPrint('Pre-filled data for project: ${selectedProject.projectName}');
    }
    
    // Add date and time information
    if (date != null) {
      prefillData['date'] = date;
    } else {
      prefillData['date'] = DateTime.now().toIso8601String().split('T')[0];
    }
    
    if (hour != null) {
      prefillData['hour'] = hour;
    }
    
    // Add timestamp and user information
    prefillData['createdAt'] = DateTime.now().toIso8601String();
    prefillData['updatedAt'] = DateTime.now().toIso8601String();
    
    return prefillData;
  }
  
  /// Get hourly reading template pre-fill data
  static Future<Map<String, dynamic>> getHourlyReadingPrefillData({
    ProjectDocument? selectedProject,
    String? date,
    String? hour,
  }) async {
    final prefillData = await getLogEntryPrefillData(
      selectedProject: selectedProject,
      date: date,
      hour: hour,
    );
    
    // Add hourly reading specific fields
    if (selectedProject != null) {
      final hourlyDefaults = _getHourlyReadingDefaults(selectedProject);
      prefillData.addAll(hourlyDefaults);
    }
    
    return prefillData;
  }
  
  /// Get daily summary pre-fill data
  static Future<Map<String, dynamic>> getDailySummaryPrefillData({
    ProjectDocument? selectedProject,
    String? date,
  }) async {
    final prefillData = await getLogEntryPrefillData(
      selectedProject: selectedProject,
      date: date,
    );
    
    // Add daily summary specific fields
    if (selectedProject != null) {
      final summaryDefaults = _getDailySummaryDefaults(selectedProject);
      prefillData.addAll(summaryDefaults);
    }
    
    return prefillData;
  }
  
  /// Get pre-fill data for project summary screen
  static Map<String, dynamic> getProjectSummaryPrefillData(ProjectDocument project) {
    return {
      'projectId': project.projectId,
      'projectName': project.projectName,
      'projectNumber': project.projectNumber,
      'location': project.location,
      'unitNumber': project.unitNumber,
      'workOrderNumber': project.workOrderNumber,
      'tankType': project.tankType,
      'facilityTarget': project.facilityTarget,
      'operatingTemperature': project.operatingTemperature,
      'benzeneTarget': project.benzeneTarget,
      'h2sAmpRequired': project.h2sAmpRequired,
      'product': project.product,
      'projectStartDate': project.projectStartDate?.toIso8601String(),
      'createdBy': project.createdBy,
    };
  }
  
  /// Get default form values based on project type
  static Map<String, dynamic> _getProjectTypeDefaults(ProjectDocument project) {
    final defaults = <String, dynamic>{};
    
    // Set defaults based on tank type
    switch (project.tankType.toLowerCase()) {
      case 'thermal':
      case 'thermal oxidation':
        defaults['expectedTempRange'] = '>1200°F';
        defaults['monitoringFrequency'] = 'hourly';
        defaults['safetyRequirements'] = ['High temperature monitoring', 'H2S detection'];
        break;
        
      case 'ifr':
      case 'internal floating roof':
        defaults['expectedTempRange'] = '200-400°F';
        defaults['monitoringFrequency'] = 'hourly';
        defaults['safetyRequirements'] = ['Vapor monitoring', 'LEL detection'];
        break;
        
      case 'storage':
      case 'storage tank':
        defaults['expectedTempRange'] = 'ambient';
        defaults['monitoringFrequency'] = 'every 2 hours';
        defaults['safetyRequirements'] = ['Vapor monitoring'];
        break;
        
      default:
        defaults['expectedTempRange'] = 'project-specific';
        defaults['monitoringFrequency'] = 'hourly';
        defaults['safetyRequirements'] = ['Standard monitoring'];
    }
    
    // Set defaults based on product type
    switch (project.product.toLowerCase()) {
      case 'crude':
      case 'crude oil':
        defaults['vaporPressure'] = 'medium';
        defaults['toxicityLevel'] = 'moderate';
        break;
        
      case 'methane':
      case 'natural gas':
        defaults['vaporPressure'] = 'high';
        defaults['toxicityLevel'] = 'low';
        break;
        
      case 'sour water':
        defaults['vaporPressure'] = 'low';
        defaults['toxicityLevel'] = 'high';
        defaults['specialPrecautions'] = ['H2S monitoring required'];
        break;
    }
    
    return defaults;
  }
  
  /// Get hourly reading specific defaults
  static Map<String, dynamic> _getHourlyReadingDefaults(ProjectDocument project) {
    final defaults = <String, dynamic>{};
    
    // Parse operating temperature to get target ranges
    if (project.operatingTemperature.isNotEmpty) {
      if (project.operatingTemperature.contains('>')) {
        defaults['targetMinTemp'] = project.operatingTemperature;
      } else if (project.operatingTemperature.contains('-')) {
        defaults['targetTempRange'] = project.operatingTemperature;
      }
    }
    
    // Parse facility target for LEL and PPM values
    if (project.facilityTarget.isNotEmpty) {
      if (project.facilityTarget.contains('LEL')) {
        defaults['targetLEL'] = project.facilityTarget;
      }
      if (project.facilityTarget.contains('ppm')) {
        defaults['targetPPM'] = project.facilityTarget;
      }
    }
    
    // H2S monitoring requirement
    if (project.h2sAmpRequired) {
      defaults['h2sMonitoringRequired'] = true;
      defaults['h2sTarget'] = project.benzeneTarget.isNotEmpty ? project.benzeneTarget : '10 PPM';
    }
    
    // Default reading status
    defaults['readingStatus'] = 'pending';
    defaults['readingType'] = 'routine';
    
    return defaults;
  }
  
  /// Get daily summary specific defaults
  static Map<String, dynamic> _getDailySummaryDefaults(ProjectDocument project) {
    final defaults = <String, dynamic>{};
    
    defaults['totalExpectedReadings'] = 24; // 24 hours
    defaults['completedReadings'] = 0;
    defaults['completionStatus'] = 'incomplete';
    defaults['summaryType'] = 'daily';
    
    // Project-specific summary fields
    defaults['projectSummary'] = {
      'location': project.location,
      'unitNumber': project.unitNumber,
      'tankType': project.tankType,
      'operatingConditions': project.operatingTemperature,
      'safetyTargets': {
        'facilityTarget': project.facilityTarget,
        'benzeneTarget': project.benzeneTarget,
        'h2sRequired': project.h2sAmpRequired,
      },
    };
    
    return defaults;
  }
  
  /// Helper method to convert cached project to ProjectDocument
  static ProjectDocument _convertCachedToProject(CachedProject cached) {
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
  
  /// Update user session with most recently used project data
  static Future<void> trackProjectUsage(String projectId) async {
    try {
      await LocalDatabaseService.updateSessionActivity();
      debugPrint('Tracked project usage: $projectId');
    } catch (e) {
      debugPrint('Failed to track project usage: $e');
    }
  }
  
  /// Clear any cached pre-fill data
  static Future<void> clearPrefillCache() async {
    // This would clear any temporary pre-fill data if needed
    debugPrint('Cleared pre-fill cache');
  }
}