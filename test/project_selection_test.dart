import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_flutter_app/models/hive_models.dart';
import 'package:my_flutter_app/models/firestore_models.dart';
import 'package:my_flutter_app/services/local_database_service.dart';
import 'package:my_flutter_app/services/form_prefill_service.dart';
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Project Selection and Auto-fill Tests', () {
    setUpAll(() async {
      // Initialize Hive for testing
      final path = Directory.systemTemp.path;
      Hive.init(path);
      
      // Register adapters
      Hive.registerAdapter(LogEntryAdapter());
      Hive.registerAdapter(DailyMetricAdapter());
      Hive.registerAdapter(UserSessionAdapter());
      Hive.registerAdapter(CachedProjectAdapter());
      Hive.registerAdapter(SyncQueueEntryAdapter());
      
      // Open boxes
      await Hive.openBox<LogEntry>('logEntries');
      await Hive.openBox<DailyMetric>('dailyMetrics');
      await Hive.openBox<UserSession>('userSessions');
      await Hive.openBox<CachedProject>('cachedProjects');
      await Hive.openBox<SyncQueueEntry>('syncQueue');
    });
    
    tearDownAll(() async {
      await Hive.close();
    });
    
    tearDown(() async {
      // Clear all data after each test
      await LocalDatabaseService.clearAllData();
    });
    
    group('Project Caching', () {
      test('Should cache a project successfully', () async {
        final project = CachedProject(
          projectId: 'test-project-1',
          projectName: 'Test Thermal Project',
          projectNumber: 'TEST-2025-001',
          location: 'Test Facility',
          unitNumber: 'TEST-UNIT-01',
          metadata: {
            'workOrderNumber': 'TEST-WO-001',
            'tankType': 'thermal',
            'facilityTarget': '10% LEL',
            'operatingTemperature': '>1200°F',
            'benzeneTarget': '10 PPM',
            'h2sAmpRequired': true,
            'product': 'Crude Oil',
          },
          cachedAt: DateTime.now(),
          createdBy: 'test-user',
        );
        
        await LocalDatabaseService.cacheProject(project);
        final retrieved = await LocalDatabaseService.getCachedProject('test-project-1');
        
        expect(retrieved, isNotNull);
        expect(retrieved!.projectName, equals('Test Thermal Project'));
        expect(retrieved.metadata['tankType'], equals('thermal'));
        expect(retrieved.metadata['h2sAmpRequired'], isTrue);
      });
      
      test('Should retrieve user cached projects', () async {
        // Cache multiple projects
        for (int i = 0; i < 3; i++) {
          final project = CachedProject(
            projectId: 'test-project-$i',
            projectName: 'Test Project $i',
            projectNumber: 'TEST-2025-00$i',
            location: 'Test Facility $i',
            unitNumber: 'TEST-UNIT-0$i',
            metadata: {},
            cachedAt: DateTime.now().subtract(Duration(hours: i)),
            createdBy: 'test-user',
          );
          
          await LocalDatabaseService.cacheProject(project);
        }
        
        final userProjects = await LocalDatabaseService.getUserCachedProjects();
        expect(userProjects.length, equals(3));
        // Should be sorted by cached time (most recent first)
        expect(userProjects.first.projectId, equals('test-project-0'));
      });
    });
    
    group('User Session Management', () {
      test('Should update current project in session', () async {
        final session = UserSession(
          userId: 'test-user',
          email: 'test@example.com',
          displayName: 'Test User',
          loginTime: DateTime.now(),
          currentProjectId: null,
          currentProjectName: null,
        );
        
        await LocalDatabaseService.saveUserSession(session);
        
        // Update current project
        await LocalDatabaseService.updateCurrentProject('test-project-1', 'Test Project');
        
        final updatedSession = await LocalDatabaseService.getCurrentUserSession();
        expect(updatedSession?.currentProjectId, equals('test-project-1'));
        expect(updatedSession?.currentProjectName, equals('Test Project'));
        expect(updatedSession?.recentProjects, contains('test-project-1'));
      });
      
      test('Should track recent projects', () async {
        final session = UserSession(
          userId: 'test-user',
          email: 'test@example.com',
          displayName: 'Test User',
          loginTime: DateTime.now(),
          recentProjects: ['old-project'],
        );
        
        await LocalDatabaseService.saveUserSession(session);
        
        // Add multiple projects
        await LocalDatabaseService.updateCurrentProject('project-1', 'Project 1');
        await LocalDatabaseService.updateCurrentProject('project-2', 'Project 2');
        await LocalDatabaseService.updateCurrentProject('project-3', 'Project 3');
        
        final updatedSession = await LocalDatabaseService.getCurrentUserSession();
        expect(updatedSession?.recentProjects.length, lessThanOrEqualTo(5)); // Max 5 recent projects
        expect(updatedSession?.recentProjects.first, equals('project-3')); // Most recent first
      });
    });
    
    group('Form Pre-fill Logic', () {
      test('Should generate correct pre-fill data for log entry', () async {
        final project = ProjectDocument(
          projectId: 'thermal-project',
          projectName: 'Thermal Test Project',
          projectNumber: 'THERMAL-2025-001',
          location: 'Texas City, TX',
          unitNumber: 'TANK-001',
          workOrderNumber: 'WO-THERMAL-001',
          tankType: 'thermal',
          facilityTarget: '10% LEL & 1000 ppm',
          operatingTemperature: '>1200°F',
          benzeneTarget: '10 PPM',
          h2sAmpRequired: true,
          product: 'Crude Oil',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'test-user',
        );
        
        final prefillData = await FormPrefillService.getLogEntryPrefillData(
          selectedProject: project,
          date: '2025-09-09',
          hour: '10:00',
        );
        
        expect(prefillData['projectId'], equals('thermal-project'));
        expect(prefillData['projectName'], equals('Thermal Test Project'));
        expect(prefillData['location'], equals('Texas City, TX'));
        expect(prefillData['tankType'], equals('thermal'));
        expect(prefillData['date'], equals('2025-09-09'));
        expect(prefillData['hour'], equals('10:00'));
        expect(prefillData['h2sAmpRequired'], isTrue);
        
        // Check project-type specific defaults
        expect(prefillData['expectedTempRange'], equals('>1200°F'));
        expect(prefillData['monitoringFrequency'], equals('hourly'));
      });
      
      test('Should generate correct hourly reading pre-fill data', () async {
        final project = ProjectDocument(
          projectId: 'storage-project',
          projectName: 'Storage Tank Project',
          projectNumber: 'STORAGE-2025-001',
          location: 'Houston, TX',
          unitNumber: 'STORAGE-001',
          tankType: 'storage',
          facilityTarget: '5000 ppm & 5% LEL',
          operatingTemperature: '200-400°F',
          benzeneTarget: '30 PPM',
          h2sAmpRequired: false,
          product: 'Methane',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'test-user',
        );
        
        final prefillData = await FormPrefillService.getHourlyReadingPrefillData(
          selectedProject: project,
          date: '2025-09-09',
          hour: '14:00',
        );
        
        expect(prefillData['projectId'], equals('storage-project'));
        expect(prefillData['tankType'], equals('storage'));
        expect(prefillData['targetTempRange'], equals('200-400°F'));
        expect(prefillData['targetLEL'], contains('LEL'));
        expect(prefillData['targetPPM'], contains('ppm'));
        expect(prefillData['h2sMonitoringRequired'], isFalse);
        expect(prefillData['readingStatus'], equals('pending'));
        expect(prefillData['readingType'], equals('routine'));
      });
      
      test('Should generate correct daily summary pre-fill data', () async {
        final project = ProjectDocument(
          projectId: 'ifr-project',
          projectName: 'IFR Tank Project',
          projectNumber: 'IFR-2025-001',
          location: 'Deer Park, TX',
          unitNumber: 'IFR-001',
          tankType: 'IFR',
          facilityTarget: '2000 ppm & 8% LEL',
          operatingTemperature: '300-500°F',
          h2sAmpRequired: true,
          product: 'Sour Water',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'test-user',
        );
        
        final prefillData = await FormPrefillService.getDailySummaryPrefillData(
          selectedProject: project,
          date: '2025-09-09',
        );
        
        expect(prefillData['projectId'], equals('ifr-project'));
        expect(prefillData['totalExpectedReadings'], equals(24));
        expect(prefillData['completedReadings'], equals(0));
        expect(prefillData['completionStatus'], equals('incomplete'));
        expect(prefillData['summaryType'], equals('daily'));
        
        final projectSummary = prefillData['projectSummary'] as Map<String, dynamic>;
        expect(projectSummary['location'], equals('Deer Park, TX'));
        expect(projectSummary['tankType'], equals('IFR'));
        
        final safetyTargets = projectSummary['safetyTargets'] as Map<String, dynamic>;
        expect(safetyTargets['h2sRequired'], isTrue);
      });
      
      test('Should handle missing project gracefully', () async {
        final prefillData = await FormPrefillService.getLogEntryPrefillData(
          selectedProject: null,
          date: '2025-09-09',
        );
        
        // Should still have date and timestamp
        expect(prefillData['date'], equals('2025-09-09'));
        expect(prefillData['createdAt'], isNotNull);
        expect(prefillData['updatedAt'], isNotNull);
        
        // Should not have project-specific data
        expect(prefillData['projectId'], isNull);
        expect(prefillData['projectName'], isNull);
      });
    });
    
    group('Project Type Defaults', () {
      test('Should set correct defaults for thermal projects', () async {
        final thermalProject = ProjectDocument(
          projectId: 'thermal-test',
          projectName: 'Thermal Project',
          projectNumber: 'THERMAL-001',
          location: 'Test Location',
          unitNumber: 'TEST-001',
          tankType: 'thermal',
          product: 'Sour Water',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'test-user',
        );
        
        final prefillData = await FormPrefillService.getLogEntryPrefillData(
          selectedProject: thermalProject,
        );
        
        expect(prefillData['expectedTempRange'], equals('>1200°F'));
        expect(prefillData['monitoringFrequency'], equals('hourly'));
        expect(prefillData['vaporPressure'], equals('low')); // Sour water
        expect(prefillData['toxicityLevel'], equals('high')); // Sour water
      });
      
      test('Should set correct defaults for IFR projects', () async {
        final ifrProject = ProjectDocument(
          projectId: 'ifr-test',
          projectName: 'IFR Project',
          projectNumber: 'IFR-001',
          location: 'Test Location',
          unitNumber: 'TEST-001',
          tankType: 'IFR',
          product: 'Crude',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'test-user',
        );
        
        final prefillData = await FormPrefillService.getLogEntryPrefillData(
          selectedProject: ifrProject,
        );
        
        expect(prefillData['expectedTempRange'], equals('200-400°F'));
        expect(prefillData['vaporPressure'], equals('medium')); // Crude
        expect(prefillData['toxicityLevel'], equals('moderate')); // Crude
      });
    });
  });
}