import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/firestore_models.dart';
import '../utils/timestamp_utils.dart';

/// Service for managing log completion status and daily rollups
class LogCompletionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Update log completion status based on entries
  Future<LogDocument> updateLogCompletionStatus({
    required String projectId,
    required String logId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in');
    }

    try {
      // Get all entries for this log
      final entriesSnapshot =
          await FirestoreQueries.logEntries(projectId, logId).get();

      // Calculate completion metrics
      final totalEntries = entriesSnapshot.docs.length;
      final completedHours =
          totalEntries; // Each entry represents a completed hour
      final validatedHours = entriesSnapshot.docs
          .where((doc) => doc.data()['validated'] == true)
          .length;

      // Determine completion status
      LogCompletionStatus status;
      if (completedHours == 0) {
        status = LogCompletionStatus.notStarted;
      } else if (completedHours < 24) {
        status = LogCompletionStatus.incomplete;
      } else if (validatedHours == 24) {
        status = LogCompletionStatus.validated;
      } else {
        status = LogCompletionStatus.complete;
      }

      // Calculate daily metrics
      final dailyMetrics = await _calculateDailyMetrics(entriesSnapshot.docs);

      // Get operator IDs from entries
      final operatorIds = entriesSnapshot.docs
          .map((doc) => doc.data()['operatorId'] as String?)
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      // Get first and last entry timestamps
      DateTime? firstEntryAt;
      DateTime? lastEntryAt;

      if (entriesSnapshot.docs.isNotEmpty) {
        final timestamps = entriesSnapshot.docs
            .map((doc) => TimestampUtils.toDateTime(doc.data()['timestamp']))
            .where((date) => date != null)
            .cast<DateTime>()
            .toList();

        if (timestamps.isNotEmpty) {
          timestamps.sort();
          firstEntryAt = timestamps.first;
          lastEntryAt = timestamps.last;
        }
      }

      // Create or update log document
      final logDoc = LogDocument(
        logId: logId,
        date: DateTime.parse(logId),
        projectId: projectId,
        completionStatus: status,
        totalEntries: totalEntries,
        completedHours: completedHours,
        validatedHours: validatedHours,
        firstEntryAt: firstEntryAt,
        lastEntryAt: lastEntryAt,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: user.uid,
        dailyMetrics: dailyMetrics,
        operatorIds: operatorIds,
      );

      // Save to Firestore
      await FirestoreQueries.projectLogs(projectId)
          .doc(logId)
          .set(logDoc.toFirestore(), SetOptions(merge: true));

      return logDoc;
    } catch (e) {
      throw Exception('Failed to update log completion status: $e');
    }
  }

  /// Calculate daily metrics from entries
  Future<Map<String, dynamic>> _calculateDailyMetrics(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> entries,
  ) async {
    if (entries.isEmpty) {
      return {};
    }

    final metrics = <String, dynamic>{};
    final readings = <String, List<double>>{};

    // Collect all numeric readings
    for (final doc in entries) {
      final data = doc.data();
      final docReadings = data['readings'] as Map<String, dynamic>? ??
          _extractReadingsFromLegacyFormat(data);

      for (final entry in docReadings.entries) {
        final value = entry.value;
        if (value is num && !value.isNaN) {
          readings.putIfAbsent(entry.key, () => []).add(value.toDouble());
        }
      }
    }

    // Calculate averages, min, max for each reading type
    for (final entry in readings.entries) {
      final values = entry.value;
      if (values.isNotEmpty) {
        final key = entry.key;
        metrics['${key}_avg'] = values.reduce((a, b) => a + b) / values.length;
        metrics['${key}_min'] = values.reduce((a, b) => a < b ? a : b);
        metrics['${key}_max'] = values.reduce((a, b) => a > b ? a : b);
        metrics['${key}_count'] = values.length;
      }
    }

    // Calculate additional metrics
    metrics['totalReadings'] = entries.length;
    metrics['hoursWithData'] = entries.length;
    metrics['completionPercentage'] =
        (entries.length / 24.0 * 100).clamp(0, 100);

    // Calculate time span
    final timestamps = entries
        .map((doc) => TimestampUtils.toDateTime(doc.data()['timestamp']))
        .where((date) => date != null)
        .cast<DateTime>()
        .toList();

    if (timestamps.length > 1) {
      timestamps.sort();
      final duration = timestamps.last.difference(timestamps.first);
      metrics['timeSpanHours'] = duration.inHours;
      metrics['timeSpanMinutes'] = duration.inMinutes;
    }

    return metrics;
  }

  /// Helper method to extract readings from legacy flat format
  Map<String, dynamic> _extractReadingsFromLegacyFormat(
      Map<String, dynamic> data) {
    final readings = <String, dynamic>{};

    // List of known reading fields from the existing ThermalReading model
    final readingFields = [
      'inletReading',
      'outletReading',
      'toInletReadingH2S',
      'vaporInletFlowRateFPM',
      'vaporInletFlowRateBBL',
      'tankRefillFlowRate',
      'combustionAirFlowRate',
      'vacuumAtTankVaporOutlet',
      'exhaustTemperature',
      'totalizer',
    ];

    for (final field in readingFields) {
      if (data.containsKey(field) && data[field] != null) {
        readings[field] = data[field];
      }
    }

    return readings;
  }

  /// Get log completion status for a specific date
  Future<LogDocument?> getLogCompletionStatus({
    required String projectId,
    required String logId,
  }) async {
    try {
      final doc =
          await FirestoreQueries.projectLogs(projectId).doc(logId).get();

      if (!doc.exists) {
        return null;
      }

      return LogDocument.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get log completion status: $e');
    }
  }

  /// Get all log completion statuses for a project
  Future<List<LogDocument>> getProjectLogStatuses({
    required String projectId,
    int limit = 50,
  }) async {
    try {
      final snapshot = await FirestoreQueries.projectLogs(projectId)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => LogDocument.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get project log statuses: $e');
    }
  }

  /// Validate a log entry (mark as validated)
  Future<void> validateLogEntry({
    required String projectId,
    required String logId,
    required String entryId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to validate entries');
    }

    try {
      await FirestoreQueries.logEntry(projectId, logId, entryId).update({
        'validated': true,
        'validatedAt': FieldValue.serverTimestamp(),
        'validatedBy': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update the parent log completion status
      await updateLogCompletionStatus(projectId: projectId, logId: logId);
    } catch (e) {
      throw Exception('Failed to validate log entry: $e');
    }
  }

  /// Bulk validate multiple entries
  Future<void> bulkValidateEntries({
    required String projectId,
    required String logId,
    required List<String> entryIds,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to validate entries');
    }

    try {
      final batch = _firestore.batch();

      for (final entryId in entryIds) {
        final entryRef = FirestoreQueries.logEntry(projectId, logId, entryId);
        batch.update(entryRef, {
          'validated': true,
          'validatedAt': FieldValue.serverTimestamp(),
          'validatedBy': user.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      // Update the parent log completion status
      await updateLogCompletionStatus(projectId: projectId, logId: logId);
    } catch (e) {
      throw Exception('Failed to bulk validate entries: $e');
    }
  }

  /// Create a new log document with default values
  Future<LogDocument> createLogDocument({
    required String projectId,
    required String logId,
    String notes = '',
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to create logs');
    }

    try {
      final logDoc = LogDocument(
        logId: logId,
        date: DateTime.parse(logId),
        projectId: projectId,
        completionStatus: LogCompletionStatus.notStarted,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: user.uid,
        notes: notes,
      );

      await FirestoreQueries.projectLogs(projectId)
          .doc(logId)
          .set(logDoc.toFirestore());

      return logDoc;
    } catch (e) {
      throw Exception('Failed to create log document: $e');
    }
  }

  /// Add notes to a log document
  Future<void> updateLogNotes({
    required String projectId,
    required String logId,
    required String notes,
  }) async {
    try {
      await FirestoreQueries.projectLogs(projectId).doc(logId).update({
        'notes': notes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update log notes: $e');
    }
  }

  /// Get logs by completion status
  Future<List<LogDocument>> getLogsByStatus({
    required String projectId,
    required LogCompletionStatus status,
    int limit = 50,
  }) async {
    try {
      final snapshot = await FirestoreQueries.projectLogs(projectId)
          .where('completionStatus', isEqualTo: status.name)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => LogDocument.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get logs by status: $e');
    }
  }
}
