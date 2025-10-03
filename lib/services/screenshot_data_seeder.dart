import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/firestore_models.dart';
import '../models/hive_models.dart';

/// Service to seed Firestore with realistic data for portfolio screenshots
/// Run this once before taking screenshots to ensure consistent, professional data
class ScreenshotDataSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String SCREENSHOT_DATE = '2025-07-15'; // July 15, 2025

  /// Main seeding function - call this to populate all screenshot data
  Future<void> seedAllData() async {
    try {
      debugPrint('🌱 Starting screenshot data seeding...');

      await seedProjects();
      await seedLogEntriesForMarathonProject();
      await seedPartialLogForActiveProject();

      debugPrint('✅ Screenshot data seeding complete!');
    } catch (e) {
      debugPrint('❌ Error seeding data: $e');
      rethrow;
    }
  }

  /// Seed 5 realistic projects for portfolio screenshots
  Future<void> seedProjects() async {
    debugPrint('📋 Seeding projects...');

    final projects = [
      // Project 1: Marathon GBR - Completed project
      ProjectDocument(
        projectId: 'marathon-gbr-tank223',
        projectName: 'Marathon GBR - Tank 223 Thermal Oxidation',
        projectNumber: '2025-2-095',
        location: 'Texas City, TX',
        unitNumber: 'Tank-223',
        workOrderNumber: 'M25-021-MTT/10100',
        tankType: 'Thermal Oxidizer',
        facilityTarget: '10% LEL',
        operatingTemperature: '>1250°F',
        benzeneTarget: 'N/A',
        h2sAmpRequired: true,
        product: 'Sour Water',
        projectStartDate: DateTime.parse('2025-07-12'),
        createdAt: DateTime.parse('2025-07-10'),
        updatedAt: DateTime.parse('2025-07-15'),
        createdBy: 'john.smith@example.com',
      ),

      // Project 2: Phillips 66 - Active project
      ProjectDocument(
        projectId: 'p66-wwr-degas',
        projectName: 'Phillips 66 WWR - Tank Degassing Operations',
        projectNumber: '2025-2-100',
        location: 'P66 WWR, Houston, TX',
        unitNumber: 'TO-05',
        workOrderNumber: 'M25-64-PWI-3100',
        tankType: 'IFR Tank',
        facilityTarget: '5,000 ppm & 10% LEL',
        operatingTemperature: '>1450°F',
        benzeneTarget: '30 PPM',
        h2sAmpRequired: true,
        product: 'Crude Oil',
        projectStartDate: DateTime.parse('2025-07-14'),
        createdAt: DateTime.parse('2025-07-12'),
        updatedAt: DateTime.parse('2025-07-15'),
        createdBy: 'sarah.johnson@example.com',
      ),

      // Project 3: Deer Park Terminal - Active
      ProjectDocument(
        projectId: 'deer-park-terminal',
        projectName: 'Deer Park Terminal - Methane Vapor Recovery',
        projectNumber: '2025-2-102',
        location: 'Deer Park Terminal, TX',
        unitNumber: 'VRU-01',
        workOrderNumber: 'DP-2025-078',
        tankType: 'Storage Tank',
        facilityTarget: '1,000 ppm & 5% LEL',
        operatingTemperature: '>800°F',
        benzeneTarget: '10 PPM',
        h2sAmpRequired: false,
        product: 'Methane',
        projectStartDate: DateTime.parse('2025-07-15'),
        createdAt: DateTime.parse('2025-07-14'),
        updatedAt: DateTime.parse('2025-07-15'),
        createdBy: 'mike.davis@example.com',
      ),

      // Project 4: Valero - Pending Review
      ProjectDocument(
        projectId: 'valero-houston-refinery',
        projectName: 'Valero Houston Refinery - H2S Monitoring',
        projectNumber: '2025-2-098',
        location: 'Houston Refinery, TX',
        unitNumber: 'TO-12',
        workOrderNumber: 'VHR-2025-042',
        tankType: 'Fixed Roof',
        facilityTarget: '2% LEL & 50 ppm H2S',
        operatingTemperature: '>950°F',
        benzeneTarget: '15 PPM',
        h2sAmpRequired: true,
        product: 'Pentane',
        projectStartDate: DateTime.parse('2025-07-10'),
        createdAt: DateTime.parse('2025-07-08'),
        updatedAt: DateTime.parse('2025-07-14'),
        createdBy: 'sarah.johnson@example.com',
      ),

      // Project 5: Shell Deer Park - Completed
      ProjectDocument(
        projectId: 'shell-deer-park',
        projectName: 'Shell Deer Park - Benzene Recovery System',
        projectNumber: '2025-2-089',
        location: 'Deer Park Chemical Plant, TX',
        unitNumber: 'BZ-04',
        workOrderNumber: 'SDP-2025-031',
        tankType: 'Floating Roof',
        facilityTarget: '1 ppm Benzene',
        operatingTemperature: '>1100°F',
        benzeneTarget: '1 PPM',
        h2sAmpRequired: false,
        product: 'Benzene/Toluene',
        projectStartDate: DateTime.parse('2025-07-05'),
        createdAt: DateTime.parse('2025-07-03'),
        updatedAt: DateTime.parse('2025-07-12'),
        createdBy: 'john.smith@example.com',
      ),
    ];

    for (final project in projects) {
      await _firestore
          .collection('projects')
          .doc(project.projectId)
          .set(project.toFirestore());
      debugPrint('  ✓ Created project: ${project.projectName}');
    }
  }

  /// Seed 24 complete hourly log entries for Marathon project (Screenshot #6 - Review All Entries)
  Future<void> seedLogEntriesForMarathonProject() async {
    debugPrint('📝 Seeding log entries for Marathon project...');

    final projectId = 'marathon-gbr-tank223';
    final logDate = DateTime.parse(SCREENSHOT_DATE);

    // Create 20 complete entries, 3 missing, 1 recently edited
    for (int hour = 0; hour < 21; hour++) {
      if (hour == 15 || hour == 18 || hour == 22) continue; // Leave 3 hours missing

      final isEditedEntry = (hour == 12); // Mark hour 12 as recently edited
      final entryTime = logDate.add(Duration(hours: hour));

      final entry = LogEntry(
        id: '${projectId}_${SCREENSHOT_DATE}_h${hour.toString().padLeft(2, '0')}',
        projectId: projectId,
        projectName: 'Marathon GBR - Tank 223',
        date: SCREENSHOT_DATE,
        hour: hour.toString().padLeft(2, '0'),
        data: {
          'inletReading': 1250.0 + (hour * 5) + (hour % 3 * 10),
          'outletReading': 950.0 + (hour * 3) + (hour % 5 * 5),
          'toInletReadingH2S': 15.0 + (hour % 10),
          'exhaustTemperature': 1450.0 + (hour * 2),
          'vaporInletFlowRateFPM': 2500.0 + (hour * 10),
          'vacuumAtTankVaporOutlet': 3.2 + (hour * 0.05),
          'observations': hour % 8 == 0 ? 'All systems operating normally' : '',
        },
        status: isEditedEntry ? 'edited' : 'complete',
        createdAt: entryTime,
        updatedAt: isEditedEntry
            ? DateTime.now().subtract(const Duration(hours: 2))
            : entryTime.add(const Duration(minutes: 5)),
        createdBy: hour < 8 ? 'john.smith@example.com' :
                   hour < 16 ? 'sarah.johnson@example.com' :
                   'mike.davis@example.com',
        isSynced: true,
        syncTimestamp: entryTime.add(const Duration(minutes: 10)),
      );

      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('logEntries')
          .doc(entry.id)
          .set(entry.toJson());
    }

    debugPrint('  ✓ Created 20 complete log entries (3 missing hours: 15, 18, 22)');
  }

  /// Seed partial log entries for Phillips 66 project (Screenshot #2 - Daily Summary showing 15/24 hours)
  Future<void> seedPartialLogForActiveProject() async {
    debugPrint('📊 Seeding partial log for P66 project (15 of 24 hours)...');

    final projectId = 'p66-wwr-degas';
    final logDate = DateTime.parse(SCREENSHOT_DATE);

    // Create entries for hours 0-14 (15 total), leave 15-23 empty
    for (int hour = 0; hour < 15; hour++) {
      final entryTime = logDate.add(Duration(hours: hour));

      final entry = LogEntry(
        id: '${projectId}_${SCREENSHOT_DATE}_h${hour.toString().padLeft(2, '0')}',
        projectId: projectId,
        projectName: 'Phillips 66 WWR - Tank Degassing',
        date: SCREENSHOT_DATE,
        hour: hour.toString().padLeft(2, '0'),
        data: {
          'inletReading': 1450.0 + (hour * 8),
          'outletReading': 890.0 + (hour * 4),
          'toInletReadingH2S': 45.0 + (hour % 15),
          'benzeneReading': 28.0 + (hour % 5),
          'exhaustTemperature': 1550.0 + (hour * 3),
          'vaporInletFlowRateFPM': 3200.0 + (hour * 15),
          'vacuumAtTankVaporOutlet': 4.1 + (hour * 0.08),
        },
        status: 'complete',
        createdAt: entryTime,
        updatedAt: entryTime.add(const Duration(minutes: 3)),
        createdBy: hour < 8 ? 'sarah.johnson@example.com' : 'john.smith@example.com',
        isSynced: true,
        syncTimestamp: entryTime.add(const Duration(minutes: 8)),
      );

      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('logEntries')
          .doc(entry.id)
          .set(entry.toJson());
    }

    debugPrint('  ✓ Created 15 complete entries, 9 hours remaining (62% progress)');
  }

  /// Create sample entries for Hour Selector screen (Screenshot #3)
  /// Shows mixed completion status with hours 6-10 and 14-18 completed
  Future<void> seedHourSelectorData() async {
    debugPrint('🕐 Seeding hour selector sample data...');

    final projectId = 'deer-park-terminal';
    final logDate = DateTime.parse(SCREENSHOT_DATE);

    final completedHours = [6, 7, 8, 9, 10, 14, 15, 16, 17, 18];

    for (final hour in completedHours) {
      final entryTime = logDate.add(Duration(hours: hour));

      final entry = LogEntry(
        id: '${projectId}_${SCREENSHOT_DATE}_h${hour.toString().padLeft(2, '0')}',
        projectId: projectId,
        projectName: 'Deer Park Terminal - Methane Vapor Recovery',
        date: SCREENSHOT_DATE,
        hour: hour.toString().padLeft(2, '0'),
        data: {
          'inletReading': 850.0 + (hour * 10),
          'outletReading': 320.0 + (hour * 5),
          'methaneReading': 950.0 + (hour % 20),
          'lelReading': 4.5 + (hour * 0.1),
          'exhaustTemperature': 920.0 + (hour * 4),
        },
        status: 'complete',
        createdAt: entryTime,
        updatedAt: entryTime.add(const Duration(minutes: 2)),
        createdBy: 'mike.davis@example.com',
        isSynced: true,
      );

      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('logEntries')
          .doc(entry.id)
          .set(entry.toJson());
    }

    debugPrint('  ✓ Created entries for hours: ${completedHours.join(", ")}');
  }

  /// Clear all screenshot data (useful for resetting)
  Future<void> clearScreenshotData() async {
    debugPrint('🗑️  Clearing screenshot data...');

    final projectIds = [
      'marathon-gbr-tank223',
      'p66-wwr-degas',
      'deer-park-terminal',
      'valero-houston-refinery',
      'shell-deer-park',
    ];

    for (final projectId in projectIds) {
      // Delete all log entries
      final entries = await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('logEntries')
          .get();

      for (final doc in entries.docs) {
        await doc.reference.delete();
      }

      // Delete project
      await _firestore.collection('projects').doc(projectId).delete();
    }

    debugPrint('✅ Screenshot data cleared');
  }
}
