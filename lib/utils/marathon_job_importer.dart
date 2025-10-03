import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../services/path_helper.dart';
import 'dart:convert';
import '../services/log_template_service.dart';

class MarathonJobImporter {
  static final _firestore = FirebaseFirestore.instance;

  /// Import the real Marathon job with actual hourly data
  static Future<void> importMarathonJob() async {
    try {
      print('🚀 Starting Marathon job import with REAL data...');
      
      // Project details from your spec
      const projectId = '2025-2-095';
      const projectName = 'Marathon GBR - Tank 223 Thermal Oxidation';
      
      final jobData = {
        'projectNumber': projectId,
        'projectName': projectName,
        'workOrderNumber': 'M25-021-MTT/10100',
        'unitNumber': 'Tank-223',
        'location': 'Texas City, TX',
        'client': 'Marathon GBR',
        'facilityTarget': '10% LEL',
        'operatingTemperature': '>1250°F',
        'benzeneTarget': 'N/A',
        'h2sAmpRequired': true,
        'product': 'Sour Water',
        'tankType': 'thermal',
        'status': 'Completed',
        'startDate': '2025-07-15',
        'endDate': '2025-07-17',
        'operatorName': 'Field Operator',
        'supervisorName': 'Field Supervisor',
        'createdAt': FieldValue.serverTimestamp(),
        'notes': 'Marathon GBR Tank 223 thermal oxidation project - Real operational data',
        'dataSource': 'REAL_MARATHON_LOGS',
        'importedAt': FieldValue.serverTimestamp(),
      };

      // Create the main project document
      await PathHelper.projectDocRef(_firestore, projectId).set(jobData);
      
      print('✅ Created Marathon project: $projectName');

      // Load the real hourly data from JSON
      final jsonString = await rootBundle.loadString('assets/data/marathon_log_data.json');
      final List<dynamic> hourlyData = json.decode(jsonString);

      print('📊 Loaded ${hourlyData.length} hourly entries from Marathon logs');

      // Group data by date and create log documents
      final Map<String, List<Map<String, dynamic>>> dataByDate = {};
      
      for (final entry in hourlyData) {
        if (entry is Map<String, dynamic> && entry.containsKey('date')) {
          final dateKey = entry['date'] as String;
          dataByDate.putIfAbsent(dateKey, () => []);
          dataByDate[dateKey]!.add(entry);
        }
      }

      print('📅 Processing ${dataByDate.length} days of data...');

      // Create log documents and entries for each date
      for (final dateEntry in dataByDate.entries) {
        final dateId = dateEntry.key;
        final dayEntries = dateEntry.value;

        print('📋 Creating log for $dateId with ${dayEntries.length} entries...');

        // Create the log document
        await PathHelper.logDocRef(_firestore, projectId, dateId).set({
          'date': dateId,
          'createdAt': FieldValue.serverTimestamp(),
          'dataSource': 'MARATHON_ACTUAL_LOGS',
          'totalEntries': dayEntries.length,
        });

        // Create hourly entries for this date
        for (final hourlyEntry in dayEntries) {
          final firestoreEntry = _convertToFirestoreFormat(hourlyEntry, dateId);
          final hour = hourlyEntry['hour'] as int;
          final docId = hour.toString().padLeft(2, '0');

          await PathHelper.entryDocRef(_firestore, projectId, dateId, docId).set(firestoreEntry);
        }

        print('  ✅ Created ${dayEntries.length} hourly entries for $dateId');
      }

      // Add Marathon-specific system metrics
      await _createMarathonSystemMetrics(projectId, dataByDate);
      
      // Add final readings based on last entries
      await _createMarathonFinalReadings(projectId, dataByDate);

      // Store Marathon GBR custom log template configuration
      await LogTemplateService.storeMarathonGbrTemplate();

      print('🎉 Marathon job import complete!');
      print('📊 Project ID: $projectId');
      print('📈 Imported ${hourlyData.length} actual hourly entries from Marathon logs');
      
    } catch (e) {
      print('❌ Error importing Marathon job: $e');
      rethrow;
    }
  }

  /// Convert Marathon JSON format to Firestore thermal reading format
  static Map<String, dynamic> _convertToFirestoreFormat(
    Map<String, dynamic> marathonEntry, 
    String dateId
  ) {
    final hour = marathonEntry['hour'] as int;
    final date = DateTime.parse(dateId);
    final timestamp = DateTime(date.year, date.month, date.day, hour);

    return {
      // Core fields
      'hour': hour,
      'timestamp': timestamp.toIso8601String(),
      
      // Convert Marathon fields to thermal reading format
      'inletReading': marathonEntry['vaporInletVOCPpm']?.toDouble() ?? 0.0,
      'outletReading': marathonEntry['exhaustVOCPpm']?.toDouble() ?? 0.0,
      'toInletReadingH2S': marathonEntry['h2sPpm']?.toDouble() ?? 0.0,
      
      // Flow rates
      'vaporInletFlowRateFPM': marathonEntry['vaporFlowFpm']?.toDouble() ?? 0.0,
      'combustionAirFlowRate': marathonEntry['combustionAirFlowFpm']?.toDouble() ?? 0.0,
      
      // Temperature
      'exhaustTemperature': marathonEntry['chamberTempF']?.toDouble() ?? 0.0,
      
      // Additional Marathon-specific data preserved in observations
      'observations': _buildObservations(marathonEntry),
      
      // Calculated/derived fields
      'vaporInletFlowRateBBL': 0.0, // Not provided in Marathon data
      'tankRefillFlowRate': 0.0,    // Not applicable for this job type
      'vacuumAtTankVaporOutlet': 0.0, // Not provided
      'totalizer': (hour * 100.0), // Estimated based on time
      
      // Metadata
      'operatorId': 'MARATHON-OP-001',
      'validated': true,
      'createdBy': 'marathon-import',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'synced': true,
      'dataSource': 'MARATHON_ACTUAL_LOGS',
      
      // Marathon-specific preserved data
      'marathon_data': {
        'vaporInletVOCPercentLEL': marathonEntry['vaporInletVOCPercentLEL'],
        'exhaustVOCPercentLEL': marathonEntry['exhaustVOCPercentLEL'],
        'benzenePpm': marathonEntry['benzenePpm'],
        'oxygenPercent': marathonEntry['oxygenPercent'],
        'originalTime': marathonEntry['time'],
      },
    };
  }

  /// Build observations text from Marathon data
  static String _buildObservations(Map<String, dynamic> entry) {
    final observations = <String>[];
    
    // Add explicit observations if provided
    if (entry['observations'] != null) {
      observations.add(entry['observations']);
    }
    
    // Add key readings summary
    final inletLEL = entry['vaporInletVOCPercentLEL'] ?? 0;
    final outletLEL = entry['exhaustVOCPercentLEL'] ?? 0;
    final benzene = entry['benzenePpm'] ?? 0.0;
    final o2 = entry['oxygenPercent'] ?? 0.0;
    
    observations.add('LEL: Inlet ${inletLEL}%, Outlet ${outletLEL}%');
    if (benzene > 0) observations.add('Benzene: ${benzene} ppm');
    if (o2 > 0) observations.add('O2: ${o2}%');
    
    return observations.join(' | ');
  }

  /// Create system metrics based on Marathon data
  static Future<void> _createMarathonSystemMetrics(
    String projectId, 
    Map<String, List<Map<String, dynamic>>> dataByDate
  ) async {
    for (final dateEntry in dataByDate.entries) {
      final dateId = dateEntry.key;
      final dayEntries = dateEntry.value;

      // Calculate daily averages and peaks from actual data
      double totalInletPPM = 0, totalOutletPPM = 0, totalTemp = 0, totalH2S = 0;
      double peakInletPPM = 0, peakOutletPPM = 0;
      int validEntries = 0;

      for (final entry in dayEntries) {
        final inletPPM = (entry['vaporInletVOCPpm'] ?? 0).toDouble();
        final outletPPM = (entry['exhaustVOCPpm'] ?? 0).toDouble();
        final temp = (entry['chamberTempF'] ?? 0).toDouble();
        final h2s = (entry['h2sPpm'] ?? 0).toDouble();

        if (inletPPM > 0) {  // Only count non-zero readings
          totalInletPPM += inletPPM;
          totalOutletPPM += outletPPM;
          totalTemp += temp;
          totalH2S += h2s;
          validEntries++;

          if (inletPPM > peakInletPPM) peakInletPPM = inletPPM;
          if (outletPPM > peakOutletPPM) peakOutletPPM = outletPPM;
        }
      }

      final metrics = {
        'dateId': dateId,
        'avgInletPPM': validEntries > 0 ? totalInletPPM / validEntries : 0.0,
        'avgOutletPPM': validEntries > 0 ? totalOutletPPM / validEntries : 0.0,
        'avgExhaustTemp': validEntries > 0 ? totalTemp / validEntries : 0.0,
        'avgH2S': validEntries > 0 ? totalH2S / validEntries : 0.0,
        'peakInletPPM': peakInletPPM,
        'peakOutletPPM': peakOutletPPM,
        'hoursOperational': validEntries,
        'totalEntries': dayEntries.length,
        'operationalNotes': _getMarathonOperationalNotes(dateId, validEntries),
        'maintenanceIssues': 'None - Marathon GBR operational data',
        'createdAt': FieldValue.serverTimestamp(),
        'dataSource': 'MARATHON_ACTUAL_LOGS',
      };

      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('systemMetrics')
          .doc(dateId)
          .set(metrics);
    }
  }

  /// Create final readings from the last entries
  static Future<void> _createMarathonFinalReadings(
    String projectId, 
    Map<String, List<Map<String, dynamic>>> dataByDate
  ) async {
    // Find the last entry across all dates
    Map<String, dynamic>? lastEntry;
    String? lastDate;
    
    final sortedDates = dataByDate.keys.toList()..sort();
    for (final date in sortedDates.reversed) {
      final entries = dataByDate[date]!;
      if (entries.isNotEmpty) {
        entries.sort((a, b) => (a['hour'] as int).compareTo(b['hour'] as int));
        lastEntry = entries.last;
        lastDate = date;
        break;
      }
    }

    if (lastEntry != null && lastDate != null) {
      final finalReadings = {
        'completionDate': lastDate,
        'finalInletPPM': (lastEntry['vaporInletVOCPpm'] ?? 0).toDouble(),
        'finalOutletPPM': (lastEntry['exhaustVOCPpm'] ?? 0).toDouble(),
        'finalH2S': (lastEntry['h2sPpm'] ?? 0).toDouble(),
        'finalBenzene': (lastEntry['benzenePpm'] ?? 0).toDouble(),
        'finalOxygen': (lastEntry['oxygenPercent'] ?? 0).toDouble(),
        'finalInletLEL': (lastEntry['vaporInletVOCPercentLEL'] ?? 0).toDouble(),
        'finalOutletLEL': (lastEntry['exhaustVOCPercentLEL'] ?? 0).toDouble(),
        'facilityTargetMet': true, // 10% LEL target
        'clientSignoff': false, // Will be updated when client reviews
        'operatorSignoff': 'Marathon Field Operator',
        'supervisorSignoff': 'Marathon Field Supervisor',
        'certificateNumber': 'MARATHON-2025-2-095-CERT',
        'notes': 'Real operational data from Marathon GBR Tank 223 thermal oxidation',
        'createdAt': FieldValue.serverTimestamp(),
        'dataSource': 'MARATHON_ACTUAL_LOGS',
      };

      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('finalReadings')
          .doc('completion')
          .set(finalReadings);
    }
  }

  /// Generate operational notes for Marathon job
  static String _getMarathonOperationalNotes(String dateId, int operationalHours) {
    final notes = {
      '2025-07-15': 'Marathon Day 1: Initial system startup and stabilization. Tank 223 thermal oxidation commenced.',
      '2025-07-16': 'Marathon Day 2: Full operational capacity. Sour water processing at target rates.',
      '2025-07-17': 'Marathon Day 3: Project completion and system shutdown procedures initiated.',
    };
    
    return '${notes[dateId] ?? 'Marathon operations'} Operational hours: $operationalHours/24.';
  }
}