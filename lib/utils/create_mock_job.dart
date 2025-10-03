import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../services/path_helper.dart';

class MockJobCreator {
  static final _firestore = FirebaseFirestore.instance;
  static final _random = Random();

  /// Creates a complete mock job with realistic data
  static Future<void> createCompleteMockJob() async {
    try {
      print('🚀 Starting mock job creation...');
      
      // Job details - Realistic refinery project
      const projectId = 'CHEVRON-2024-TOX-147';
      const projectName = 'Chevron Richmond Refinery - Tank 42B Thermal Oxidation';
      final jobData = {
        'projectNumber': projectId,
        'projectName': projectName,
        'workOrderNumber': 'WO-2024-8847',
        'unitNumber': 'TOX-42B',
        'location': 'Richmond, CA',
        'client': 'Chevron U.S.A. Inc.',
        'facilityTarget': '1500 PPM',
        'operatingTemperature': '1400°F',
        'benzeneTarget': '< 5 PPM',
        'h2sAmpRequired': true,
        'product': 'Crude Oil Residue',
        'tankType': 'thermal',
        'tankVolume': '50,000 BBL',
        'status': 'Completed',
        'startDate': '2024-08-01',
        'endDate': '2024-08-05',
        'operatorName': 'John Martinez',
        'supervisorName': 'Sarah Thompson',
        'safetyOfficer': 'Mike Johnson',
        'createdAt': FieldValue.serverTimestamp(),
        'notes': 'Tank cleaning completed successfully. All emission targets met. No safety incidents.',
      };

      // Create the main project document
      await PathHelper.projectDocRef(_firestore, projectId).set(jobData);
      
      print('✅ Created project: $projectName');

      // Create 5 days of logs (Aug 1-5, 2024)
      final startDate = DateTime(2024, 8, 1);
      for (int dayOffset = 0; dayOffset < 5; dayOffset++) {
        final currentDate = startDate.add(Duration(days: dayOffset));
        final dateId = DateFormat('yyyy-MM-dd').format(currentDate);
        
        // Create log document for this date
        await PathHelper.logDocRef(_firestore, projectId, dateId).set({
          'date': dateId,
          'createdAt': FieldValue.serverTimestamp(),
          'dayNumber': dayOffset + 1,
          'weatherConditions': _getWeatherForDay(dayOffset),
          'shiftSupervisor': dayOffset % 2 == 0 ? 'Sarah Thompson' : 'Tom Wilson',
        });

        print('📅 Creating data for $dateId (Day ${dayOffset + 1})...');

        // Generate 24 hours of entries for each day
        for (int hour = 0; hour < 24; hour++) {
          final entryData = _generateHourlyEntry(hour, dayOffset, currentDate);
          
          await PathHelper.entryDocRef(_firestore, projectId, dateId, hour.toString().padLeft(2, '0')).set(entryData);
        }
        
        print('  ✅ Created 24 hourly entries for $dateId');

        // Add system metrics for each day
        await _createSystemMetrics(projectId, dateId, dayOffset);
      }

      // Add final readings for project completion
      await _createFinalReadings(projectId);
      
      // Add some additional documents for completeness
      await _createSafetyRecords(projectId);
      await _createCalibrationRecords(projectId);
      
      print('🎉 Mock job creation complete!');
      print('📊 Project ID: $projectId');
      print('📈 Created 5 days of data with 120 total hourly entries');
      
    } catch (e) {
      print('❌ Error creating mock job: $e');
      rethrow;
    }
  }

  /// Generate realistic hourly entry data
  static Map<String, dynamic> _generateHourlyEntry(int hour, int dayOffset, DateTime date) {
    // Simulate realistic patterns - lower readings at night, higher during day
    final isDayTime = hour >= 6 && hour <= 18;
    final baseMultiplier = isDayTime ? 1.2 : 0.8;
    
    // Gradually improve readings over the 5-day period
    final progressMultiplier = 1.0 - (dayOffset * 0.1);
    
    // Add some randomness but keep within realistic ranges
    final inletBase = 800 + (isDayTime ? 200 : 0);
    final outletBase = 15 + (isDayTime ? 5 : 0);
    
    return {
      'hour': hour,
      'timestamp': DateTime(date.year, date.month, date.day, hour).toIso8601String(),
      
      // PPM Readings - gradually decreasing over days
      'inletReading': (inletBase * progressMultiplier + _random.nextInt(100)).round(),
      'outletReading': (outletBase * progressMultiplier + _random.nextDouble() * 3).toStringAsFixed(1),
      'toInletReadingH2S': (45 * progressMultiplier + _random.nextInt(10)).toDouble(),
      
      // Flow rates - fairly consistent with small variations
      'vaporInletFlowRateFPM': 450 + _random.nextInt(50).toDouble(),
      'vaporInletFlowRateBBL': 125 + _random.nextInt(15).toDouble(),
      'tankRefillFlowRate': isDayTime ? 85 + _random.nextInt(20).toDouble() : 0,
      
      // Operating parameters
      'combustionAirFlowRate': 2200 + _random.nextInt(100).toDouble(),
      'vacuumAtTankVaporOutlet': -2.5 - _random.nextDouble() * 0.5,
      'exhaustTemperature': 1380 + _random.nextInt(40).toDouble(),
      
      // Totalizer - accumulating throughout the project
      'totalizer': (dayOffset * 24 + hour) * 125.0 + _random.nextInt(50).toDouble(),
      
      // Observations
      'observations': _getObservationForHour(hour, dayOffset),
      
      // Metadata
      'operatorId': _getOperatorForShift(hour),
      'validated': true,
      'createdBy': 'mock-data-generator',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'synced': true,
    };
  }

  /// Create system metrics for a day
  static Future<void> _createSystemMetrics(String projectId, String dateId, int dayOffset) async {
    final metrics = {
      'dateId': dateId,
      'dailyTotalizer': 3000 + (dayOffset * 500) + _random.nextInt(200).toDouble(),
      'avgVacuum': -2.8 - _random.nextDouble() * 0.3,
      'avgExhaustTemp': 1395 + _random.nextInt(20).toDouble(),
      'avgCombustionAir': 2250 + _random.nextInt(50).toDouble(),
      'peakInletPPM': 1200 - (dayOffset * 100) + _random.nextInt(50).toDouble(),
      'peakOutletPPM': 25 - (dayOffset * 3) + _random.nextDouble() * 2,
      'operationalNotes': _getOperationalNotes(dayOffset),
      'maintenanceIssues': dayOffset == 2 ? 'Minor valve adjustment required on combustion air intake' : 'None',
      'hoursOperational': 24,
      'systemUptime': 100.0,
      'fuelConsumption': 850 + _random.nextInt(100).toDouble(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('systemMetrics')
        .doc(dateId)
        .set(metrics);
  }

  /// Create final readings for project completion
  static Future<void> _createFinalReadings(String projectId) async {
    final finalReadings = {
      'completionDate': '2024-08-05',
      'finalInletPPM': 125.0,
      'finalOutletPPM': 3.2,
      'finalH2S': 8.0,
      'totalVolumeProcessed': 15750.0,
      'totalRuntime': 120, // hours
      'averageEfficiency': 98.7,
      'emissionsCompliance': true,
      'benzeneFinal': 2.8,
      'vocReduction': 99.2,
      'clientSignoff': true,
      'clientName': 'Robert Chen',
      'clientTitle': 'Environmental Manager',
      'clientComments': 'Excellent work. All parameters within spec. Very satisfied with the operation.',
      'operatorSignoff': 'John Martinez',
      'supervisorSignoff': 'Sarah Thompson',
      'qcApproval': true,
      'certificateIssued': true,
      'certificateNumber': 'CERT-2024-TOX-8847',
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('finalReadings')
        .doc('completion')
        .set(finalReadings);
  }

  /// Create safety records
  static Future<void> _createSafetyRecords(String projectId) async {
    final safetyData = {
      'totalManHours': 240,
      'incidentCount': 0,
      'nearMissCount': 1,
      'safetyMeetings': 5,
      'permitsClosed': 12,
      'h2sAlarms': 2,
      'evacuations': 0,
      'firstAidCases': 0,
      'toolboxTalks': [
        'H2S awareness and response',
        'Thermal hazards and PPE',
        'Confined space entry procedures',
        'Emergency evacuation routes',
        'Heat stress prevention'
      ],
      'ppe_compliance': 100.0,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('safety')
        .doc('summary')
        .set(safetyData);
  }

  /// Create calibration records
  static Future<void> _createCalibrationRecords(String projectId) async {
    final calibrations = [
      {
        'equipmentId': 'LEL-001',
        'equipmentType': 'LEL Meter',
        'calibrationDate': '2024-07-31',
        'nextDue': '2024-08-07',
        'technician': 'Cal Tech Services',
        'certificateNumber': 'CAL-2024-7891',
      },
      {
        'equipmentId': 'H2S-001',
        'equipmentType': 'H2S Monitor',
        'calibrationDate': '2024-07-31',
        'nextDue': '2024-08-07',
        'technician': 'Cal Tech Services',
        'certificateNumber': 'CAL-2024-7892',
      },
      {
        'equipmentId': 'TEMP-001',
        'equipmentType': 'Temperature Probe',
        'calibrationDate': '2024-07-30',
        'nextDue': '2024-08-30',
        'technician': 'In-house',
        'certificateNumber': 'CAL-2024-7893',
      },
    ];

    for (final cal in calibrations) {
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('calibrations')
          .add({
        ...cal,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Helper methods for realistic data generation
  static String _getWeatherForDay(int dayOffset) {
    final conditions = [
      'Clear, 72°F, Wind: 5 mph NW',
      'Partly Cloudy, 68°F, Wind: 8 mph W',
      'Overcast, 65°F, Wind: 12 mph SW',
      'Clear, 75°F, Wind: 3 mph N',
      'Sunny, 78°F, Wind: 6 mph NW',
    ];
    return conditions[dayOffset];
  }

  static String _getObservationForHour(int hour, int dayOffset) {
    if (hour == 0) return 'Shift change. All systems operational.';
    if (hour == 6) return 'Day shift started. Morning safety meeting completed.';
    if (hour == 12) return 'Lunch rotation. Maintaining steady operations.';
    if (hour == 18) return 'Evening shift change. System running smoothly.';
    
    final observations = [
      'Normal operations',
      'All parameters within range',
      'Steady state operations',
      'System stable',
      'No issues to report',
      'Routine monitoring',
      'Parameters nominal',
    ];
    
    // Occasionally add more detailed observations
    if (_random.nextInt(8) == 0) {
      final detailed = [
        'Slight increase in inlet PPM, monitoring closely',
        'Adjusted combustion air flow for optimization',
        'Tank refill in progress',
        'Completed routine valve inspection',
        'H2S levels trending down as expected',
        'Thermal efficiency at peak performance',
      ];
      return detailed[_random.nextInt(detailed.length)];
    }
    
    return observations[_random.nextInt(observations.length)];
  }

  static String _getOperatorForShift(int hour) {
    if (hour >= 6 && hour < 14) return 'John Martinez';
    if (hour >= 14 && hour < 22) return 'Mike Rodriguez';
    return 'Dave Wilson';
  }

  static String _getOperationalNotes(int dayOffset) {
    final notes = [
      'Day 1: Initial startup successful. All systems checked and operational. Baseline readings established.',
      'Day 2: Steady operations. Inlet PPM decreasing as expected. Maintained target temperature throughout.',
      'Day 3: Minor valve adjustment performed during morning shift. No impact on operations.',
      'Day 4: Excellent progress. All emissions well below targets. Combustion efficiency optimal.',
      'Day 5: Final day of operations. Preparing for shutdown procedures. All objectives met.',
    ];
    return notes[dayOffset];
  }
}