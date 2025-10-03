import '../models/firestore_models.dart';

/// Demo data service for testing and demonstration purposes
class DemoDataService {
  static const String DEMO_PROJECT_ID = 'demo-project-12345';
  
  static bool isDemoProject(String projectId) {
    return projectId == DEMO_PROJECT_ID;
  }
  
  static ProjectDocument getDemoProject() {
    return ProjectDocument(
      projectId: DEMO_PROJECT_ID,
      projectName: 'Demo Refinery Tank A-203',
      projectNumber: 'DEMO-2024-001',
      location: 'Demo Houston Plant',
      unitNumber: 'A-203',
      workOrderNumber: 'WO-DEMO-001',
      tankType: 'Fixed Roof Tank',
      facilityTarget: '95% Efficiency',
      operatingTemperature: '650°F',
      benzeneTarget: '<1 ppm',
      h2sAmpRequired: true,
      product: 'Crude Oil',
      projectStartDate: DateTime.now().subtract(const Duration(days: 7)),
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      updatedAt: DateTime.now(),
      createdBy: 'demo-user',
    );
  }
  
  static List<LogDocument> getDemoLogDocuments() {
    final now = DateTime.now();
    final logs = <LogDocument>[];
    
    // Generate logs for the past 7 days
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final logId = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      logs.add(LogDocument(
        logId: logId,
        date: date,
        projectId: DEMO_PROJECT_ID,
        completionStatus: i < 2 ? LogCompletionStatus.complete : LogCompletionStatus.incomplete,
        totalEntries: 24,
        completedHours: i < 2 ? 24 : (16 + (i * 2)),
        validatedHours: i < 2 ? 24 : (12 + i),
        firstEntryAt: date.add(const Duration(hours: 1)),
        lastEntryAt: date.add(const Duration(hours: 23)),
        createdAt: date,
        updatedAt: date.add(const Duration(hours: 2)),
        createdBy: 'demo-operator-${i % 3 + 1}',
        operatorIds: ['demo-operator-1', 'demo-operator-2'],
        notes: 'Demo log entry for demonstration purposes',
      ));
    }
    
    return logs;
  }
  
  static List<LogEntryDocument> getDemoLogEntries(String logId, int completedHours) {
    final entries = <LogEntryDocument>[];
    final date = DateTime.parse(logId);
    
    for (int hour = 0; hour < completedHours; hour++) {
      final entryTime = date.add(Duration(hours: hour));
      
      entries.add(LogEntryDocument(
        entryId: hour.toString().padLeft(2, '0'),
        hour: hour,
        timestamp: entryTime,
        readings: {
          'inletReading': 85.0 + (hour * 0.5) + (DateTime.now().millisecond % 10),
          'outletReading': 12.0 + (hour * 0.2) + (DateTime.now().millisecond % 5),
          'exhaustTemperature': 650.0 + (hour * 2) + (DateTime.now().millisecond % 20),
          'vaporInletFlowRateFPM': 1200.0 + (hour * 5),
          'vacuumAtTankVaporOutlet': 2.5 + (hour * 0.1),
          'totalizer': 1000.0 + (hour * 50),
        },
        observations: hour % 8 == 0 ? 'Equipment running normally' : '',
        operatorId: 'demo-operator-${(hour ~/ 8) + 1}',
        validated: hour < (completedHours * 0.8),
        validatedAt: hour < (completedHours * 0.8) ? entryTime.add(const Duration(hours: 1)) : null,
        validatedBy: hour < (completedHours * 0.8) ? 'demo-supervisor' : null,
        createdAt: entryTime,
        updatedAt: entryTime.add(const Duration(minutes: 5)),
        createdBy: 'demo-operator-${(hour ~/ 8) + 1}',
      ));
    }
    
    return entries;
  }
  
  static Map<String, dynamic> getDemoProjectSummary() {
    return {
      'totalProjects': 3,
      'activeProjects': 2,
      'completedProjects': 1,
      'totalLogs': 21,
      'validatedLogs': 18,
      'pendingValidation': 3,
      'lastUpdate': DateTime.now().toIso8601String(),
    };
  }
}