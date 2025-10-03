import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Save an hourly log entry under: jobs/{jobId}/entries/{hour}
  Future<void> saveHourlyEntry({
    required String jobId,
    required int hour,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _db
          .collection('jobs')
          .doc(jobId)
          .collection('entries')
          .doc(hour.toString().padLeft(2, '0'))
          .set(data);

      print('✅ Hourly entry saved for $jobId at hour $hour');
    } catch (e) {
      print('❌ Error saving hourly entry: $e');
      rethrow;
    }
  }

  /// Save system metrics once per day
  Future<void> saveSystemMetrics({
    required String jobId,
    required DateTime date,
    required Map<String, dynamic> data,
  }) async {
    final docId = '${date.year}-${date.month}-${date.day}';
    try {
      await _db
          .collection('jobs')
          .doc(jobId)
          .collection('systemMetrics')
          .doc(docId)
          .set(data);

      print('✅ System metrics saved for $jobId on $docId');
    } catch (e) {
      print('❌ Error saving system metrics: $e');
      rethrow;
    }
  }

  /// Get all hourly entries for a given job
  Future<List<Map<String, dynamic>>> getHourlyEntries(String jobId) async {
    try {
      final snapshot = await _db
          .collection('jobs')
          .doc(jobId)
          .collection('entries')
          .orderBy('hour')
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('❌ Error fetching hourly entries: $e');
      return [];
    }
  }

  /// Get system metrics for a given date (optional)
  Future<Map<String, dynamic>?> getSystemMetrics(String jobId, DateTime date) async {
    final docId = '${date.year}-${date.month}-${date.day}';
    try {
      final doc = await _db
          .collection('jobs')
          .doc(jobId)
          .collection('systemMetrics')
          .doc(docId)
          .get();

      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('❌ Error fetching system metrics: $e');
      return null;
    }
  }
}
