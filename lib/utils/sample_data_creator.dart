import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/path_helper.dart';

class SampleDataCreator {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Creates sample log data for testing the DateSelector
  static Future<void> createSampleLogData() async {
    try {
      // Create sample project
      const projectId = '2025-2-100';
      
      // Create logs for different dates
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final twoDaysAgo = today.subtract(const Duration(days: 2));
      
      await _createLogForDate(projectId, today, 18); // 18/24 entries
      await _createLogForDate(projectId, yesterday, 24); // Complete day
      await _createLogForDate(projectId, twoDaysAgo, 12); // Half day
      
      print('Sample data created successfully!');
    } catch (e) {
      print('Error creating sample data: $e');
    }
  }

  static Future<void> _createLogForDate(String projectId, DateTime date, int numEntries) async {
    final dateId = DateFormat('yyyy-MM-dd').format(date);
    
    // Create the log document
    await PathHelper.logDocRef(_firestore, projectId, dateId).set({
      'createdAt': FieldValue.serverTimestamp(),
      'date': dateId,
      'projectId': projectId,
    });

    // Create hourly entries
    for (int hour = 0; hour < numEntries; hour++) {
      await PathHelper.entryDocRef(_firestore, projectId, dateId, hour.toString()).set({
        'hour': hour,
        'timestamp': DateTime(date.year, date.month, date.day, hour).toIso8601String(),
        'inletReading': 1200.0 + (hour * 10),
        'outletReading': 25.0 + (hour * 2),
        'toInletReadingH2S': 5.0 + hour,
        'vaporInletFlowRateFPM': 500.0 + (hour * 5),
        'vaporInletFlowRateBBL': 100.0 + hour,
        'tankRefillFlowRate': 50.0 + hour,
        'combustionAirFlowRate': 300.0 + (hour * 3),
        'vacuumAtTankVaporOutlet': 2.5 + (hour * 0.1),
        'exhaustTemperature': 1500.0 + (hour * 20),
        'totalizer': 1000.0 + (hour * 50),
        'observations': hour % 4 == 0 ? 'Normal operation' : '',
        'operatorId': 'OP001',
        'validated': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Helper to clean up sample data
  static Future<void> cleanupSampleData() async {
    try {
      const projectId = '2025-2-100';
      
      // Get all logs for the project
      final logsSnapshot = await PathHelper.logsCollectionRef(_firestore, projectId).get();

      for (var logDoc in logsSnapshot.docs) {
        // Delete all entries for this log
        final entriesSnapshot = await logDoc.reference
            .collection('entries')
            .get();
        
        for (var entryDoc in entriesSnapshot.docs) {
          await entryDoc.reference.delete();
        }
        
        // Delete the log document
        await logDoc.reference.delete();
      }
      
      print('Sample data cleaned up successfully!');
    } catch (e) {
      print('Error cleaning up sample data: $e');
    }
  }
}