import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/firestore_models.dart';
import 'demo_data_service.dart';
import 'path_helper.dart';

/// Service for fetching log data from Firestore or demo data
class FirestoreDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get log documents for a project
  Future<List<LogDocument>> getProjectLogs(String projectId) async {
    // Return demo data for demo project
    if (DemoDataService.isDemoProject(projectId)) {
      return DemoDataService.getDemoLogDocuments();
    }

    try {
      final snapshot = await PathHelper.logsCollectionRef(_firestore, projectId)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => LogDocument.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get project logs: $e');
    }
  }

  /// Get log entries for a specific date
  Future<List<LogEntryDocument>> getLogEntries(
    String projectId,
    String logId,
  ) async {
    // Return demo data for demo project
    if (DemoDataService.isDemoProject(projectId)) {
      final logs = DemoDataService.getDemoLogDocuments();
      final targetLog = logs.firstWhere(
        (log) => log.logId == logId,
        orElse: () => throw Exception('Demo log not found'),
      );
      return DemoDataService.getDemoLogEntries(logId, targetLog.completedHours);
    }

    try {
      final snapshot = await PathHelper.entriesCollectionRef(_firestore, projectId, logId)
          .orderBy('hour')
          .get();

      return snapshot.docs
          .map((doc) => LogEntryDocument.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get log entries: $e');
    }
  }

  /// Get a specific log document
  Future<LogDocument?> getLogDocument(String projectId, String logId) async {
    // Return demo data for demo project
    if (DemoDataService.isDemoProject(projectId)) {
      final logs = DemoDataService.getDemoLogDocuments();
      try {
        return logs.firstWhere((log) => log.logId == logId);
      } catch (e) {
        return null;
      }
    }

    try {
      final doc = await PathHelper.logDocRef(_firestore, projectId, logId).get();

      if (!doc.exists) {
        return null;
      }

      return LogDocument.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get log document: $e');
    }
  }

  /// Get a specific log entry
  Future<LogEntryDocument?> getLogEntry(
    String projectId,
    String logId,
    String entryId,
  ) async {
    // Return demo data for demo project
    if (DemoDataService.isDemoProject(projectId)) {
      final logs = DemoDataService.getDemoLogDocuments();
      final targetLog = logs.firstWhere(
        (log) => log.logId == logId,
        orElse: () => throw Exception('Demo log not found'),
      );
      final entries =
          DemoDataService.getDemoLogEntries(logId, targetLog.completedHours);

      try {
        return entries.firstWhere((entry) => entry.entryId == entryId);
      } catch (e) {
        return null;
      }
    }

    try {
      final doc = await PathHelper.entryDocRef(_firestore, projectId, logId, entryId).get();

      if (!doc.exists) {
        return null;
      }

      return LogEntryDocument.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get log entry: $e');
    }
  }

  /// Save log entry (only for non-demo projects)
  Future<void> saveLogEntry(
    String projectId,
    String logId,
    LogEntryDocument entry,
  ) async {
    // Don't save demo data
    if (DemoDataService.isDemoProject(projectId)) {
      throw Exception('Cannot save data to demo project');
    }

    try {
      await PathHelper.entryDocRef(_firestore, projectId, logId, entry.entryId)
          .set(entry.toFirestore());
    } catch (e) {
      throw Exception('Failed to save log entry: $e');
    }
  }

  /// Update log document statistics (only for non-demo projects)
  Future<void> updateLogDocument(
    String projectId,
    LogDocument logDoc,
  ) async {
    // Don't update demo data
    if (DemoDataService.isDemoProject(projectId)) {
      throw Exception('Cannot update demo project data');
    }

    try {
      await PathHelper.logDocRef(_firestore, projectId, logDoc.logId)
          .set(logDoc.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update log document: $e');
    }
  }

  /// Get date range for a project
  Future<List<DateTime>> getProjectDateRange(
    String projectId, {
    DateTime? endDate,
  }) async {
    // Return demo data for demo project
    if (DemoDataService.isDemoProject(projectId)) {
      final logs = DemoDataService.getDemoLogDocuments();
      return logs.map((log) => log.date).toList()..sort();
    }

    try {
      final logs = await getProjectLogs(projectId);
      if (logs.isEmpty) return [];

      final dates = logs.map((log) => log.date).toList()..sort();
      final startDate = dates.first;
      final end = endDate ?? DateTime.now();

      final allDates = <DateTime>[];
      var currentDate =
          DateTime(startDate.year, startDate.month, startDate.day);
      final endDay = DateTime(end.year, end.month, end.day);

      while (currentDate.isBefore(endDay) ||
          currentDate.isAtSameMomentAs(endDay)) {
        allDates.add(currentDate);
        currentDate = currentDate.add(const Duration(days: 1));
      }

      return allDates;
    } catch (e) {
      throw Exception('Failed to get project date range: $e');
    }
  }

  /// Check if data exists for a specific date
  Future<bool> hasLogForDate(String projectId, DateTime date) async {
    final logId =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final logDoc = await getLogDocument(projectId, logId);
    return logDoc != null;
  }

  /// Get completion status for a date
  Future<LogCompletionStatus> getDateCompletionStatus(
    String projectId,
    DateTime date,
  ) async {
    final logId =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final logDoc = await getLogDocument(projectId, logId);
    return logDoc?.completionStatus ?? LogCompletionStatus.notStarted;
  }
}
