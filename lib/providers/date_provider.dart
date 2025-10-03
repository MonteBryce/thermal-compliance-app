import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/firestore_models.dart';
import '../services/log_completion_service.dart';
import '../services/path_helper.dart';
import '../services/project_service.dart';

// Model for date information
class LogDate {
  final String dateId; // Format: YYYY-MM-DD
  final DateTime date;
  final int completedHours;
  final int totalHours;

  LogDate({
    required this.dateId,
    required this.date,
    required this.completedHours,
    this.totalHours = 24,
  });

  double get completionPercentage => completedHours / totalHours;

  String get formattedDate => DateFormat('EEEE, MMMM d').format(date);

  String get shortDate => DateFormat('MMM d').format(date);
}

// Provider to get available log dates for a project
final availableLogDatesProvider =
    FutureProvider.family<List<LogDate>, String>((ref, projectId) async {
  final firestore = FirebaseFirestore.instance;

  try {
    // Get all log documents under this project
    final logsSnapshot =
        await PathHelper.logsCollectionRef(firestore, projectId).get();

    List<LogDate> logDates = [];

    for (var logDoc in logsSnapshot.docs) {
      final dateId = logDoc.id; // Should be in YYYY-MM-DD format

      try {
        // Parse the date from the document ID
        final date = DateTime.parse(dateId);

        // Get entries for this date to count completed hours
        final entriesSnapshot =
            await logDoc.reference.collection('entries').get();

        final completedHours = entriesSnapshot.docs.length;

        logDates.add(LogDate(
          dateId: dateId,
          date: date,
          completedHours: completedHours,
        ));
      } catch (e) {
        // Skip invalid date formats
        print('Skipping invalid date format: $dateId');
        continue;
      }
    }

    // Sort by date (newest first)
    logDates.sort((a, b) => b.date.compareTo(a.date));

    return logDates;
  } catch (e) {
    throw Exception('Failed to load log dates: $e');
  }
});

// Provider to get completion status for a specific date
final dateCompletionProvider =
    FutureProvider.family<LogDate, ({String projectId, String dateId})>(
        (ref, params) async {
  final firestore = FirebaseFirestore.instance;

  try {
    final date = DateTime.parse(params.dateId);

    final entriesSnapshot = await PathHelper.entriesCollectionRef(firestore, params.projectId, params.dateId).get();

    return LogDate(
      dateId: params.dateId,
      date: date,
      completedHours: entriesSnapshot.docs.length,
    );
  } catch (e) {
    throw Exception('Failed to load date completion: $e');
  }
});

// Helper provider to create a new log date (for today by default)
final createTodayLogProvider =
    FutureProvider.family<String, String>((ref, projectId) async {
  final today = DateTime.now();
  final dateId = DateFormat('yyyy-MM-dd').format(today);

  final firestore = FirebaseFirestore.instance;

  // Create the log document if it doesn't exist
  await PathHelper.logDocRef(firestore, projectId, dateId).set({
    'createdAt': FieldValue.serverTimestamp(),
    'date': dateId,
  }, SetOptions(merge: true));

  return dateId;
});

// Helper provider to create a log for any date
final createLogForDateProvider =
    FutureProvider.family<String, ({String projectId, String dateId})>(
        (ref, params) async {
  final firestore = FirebaseFirestore.instance;

  // Create the log document if it doesn't exist
  await PathHelper.logDocRef(firestore, params.projectId, params.dateId).set({
    'createdAt': FieldValue.serverTimestamp(),
    'date': params.dateId,
  }, SetOptions(merge: true));

  print('✅ Created log document for date: ${params.dateId}');

  return params.dateId;
});

// Enhanced providers using the new structured models
final logCompletionServiceProvider = Provider<LogCompletionService>((ref) {
  return LogCompletionService();
});

final projectServiceProvider = Provider<ProjectService>((ref) {
  return ProjectService();
});

// Provider to get structured log documents for a project
final projectLogDocumentsProvider =
    FutureProvider.family<List<LogDocument>, String>((ref, projectId) async {
  final logCompletionService = ref.read(logCompletionServiceProvider);

  try {
    return await logCompletionService.getProjectLogStatuses(
        projectId: projectId);
  } catch (e) {
    throw Exception('Failed to load project log documents: $e');
  }
});

// Provider to get a specific log document with full completion status
final logDocumentProvider =
    FutureProvider.family<LogDocument?, ({String projectId, String logId})>(
        (ref, params) async {
  final logCompletionService = ref.read(logCompletionServiceProvider);

  try {
    return await logCompletionService.getLogCompletionStatus(
      projectId: params.projectId,
      logId: params.logId,
    );
  } catch (e) {
    throw Exception('Failed to load log document: $e');
  }
});

// Provider to get logs by completion status
final logsByStatusProvider = FutureProvider.family<List<LogDocument>,
    ({String projectId, LogCompletionStatus status})>((ref, params) async {
  final logCompletionService = ref.read(logCompletionServiceProvider);

  try {
    return await logCompletionService.getLogsByStatus(
      projectId: params.projectId,
      status: params.status,
    );
  } catch (e) {
    throw Exception('Failed to load logs by status: $e');
  }
});

// Provider to get log entries for a specific log
final logEntriesProvider = FutureProvider.family<List<LogEntryDocument>,
    ({String projectId, String logId})>((ref, params) async {
  try {
    final snapshot =
        await FirestoreQueries.logEntries(params.projectId, params.logId)
            .orderBy('hour')
            .get();

    return snapshot.docs
        .map((doc) => LogEntryDocument.fromFirestore(doc))
        .toList();
  } catch (e) {
    throw Exception('Failed to load log entries: $e');
  }
});

// Provider to get incomplete logs (for dashboard/overview)
final incompleteLogsProvider =
    FutureProvider.family<List<LogDocument>, String>((ref, projectId) async {
  final logCompletionService = ref.read(logCompletionServiceProvider);

  try {
    return await logCompletionService.getLogsByStatus(
      projectId: projectId,
      status: LogCompletionStatus.incomplete,
    );
  } catch (e) {
    throw Exception('Failed to load incomplete logs: $e');
  }
});

// Provider to update log completion status (used after making changes)
final updateLogStatusProvider =
    FutureProvider.family<LogDocument, ({String projectId, String logId})>(
        (ref, params) async {
  final logCompletionService = ref.read(logCompletionServiceProvider);

  try {
    return await logCompletionService.updateLogCompletionStatus(
      projectId: params.projectId,
      logId: params.logId,
    );
  } catch (e) {
    throw Exception('Failed to update log status: $e');
  }
});

// Provider to get project start date (with fallback to first log entry)
final projectStartDateProvider =
    FutureProvider.family<DateTime?, String>((ref, projectId) async {
  final projectService = ref.read(projectServiceProvider);

  try {
    return await projectService.getProjectStartDate(projectId);
  } catch (e) {
    throw Exception('Failed to get project start date: $e');
  }
});

// Provider to get project summary with computed statistics
final projectSummaryProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, projectId) async {
  final projectService = ref.read(projectServiceProvider);

  try {
    return await projectService.getProjectSummary(projectId);
  } catch (e) {
    throw Exception('Failed to get project summary: $e');
  }
});

// Provider to get project date range (from start to today)
final projectDateRangeProvider =
    FutureProvider.family<List<DateTime>, String>((ref, projectId) async {
  final projectService = ref.read(projectServiceProvider);

  try {
    return await projectService.getProjectDateRange(projectId: projectId);
  } catch (e) {
    throw Exception('Failed to get project date range: $e');
  }
});

// Provider to ensure project has a start date (creates one if missing)
final ensureProjectStartDateProvider =
    FutureProvider.family<DateTime?, String>((ref, projectId) async {
  final projectService = ref.read(projectServiceProvider);

  try {
    return await projectService.ensureProjectHasStartDate(projectId);
  } catch (e) {
    throw Exception('Failed to ensure project start date: $e');
  }
});

// Enhanced provider that shows ALL dates (including missing ones) with proper completion status
final enhancedLogDatesProvider =
    FutureProvider.family<List<LogDate>, String>((ref, projectId) async {
  final projectService = ref.read(projectServiceProvider);
  final logCompletionService = ref.read(logCompletionServiceProvider);

  try {
    // Get project start date and date range
    final dateRange =
        await projectService.getProjectDateRange(projectId: projectId);
    if (dateRange.isEmpty) {
      return [];
    }

    // Get existing log documents with completion status
    final logDocuments =
        await logCompletionService.getProjectLogStatuses(projectId: projectId);

    // Create a map for quick lookup of existing logs
    final logMap = <String, LogDocument>{};
    for (final logDoc in logDocuments) {
      logMap[logDoc.logId] = logDoc;
    }

    // Generate LogDate objects for all dates in range
    final logDates = <LogDate>[];
    for (final date in dateRange) {
      final dateId = DateFormat('yyyy-MM-dd').format(date);
      final logDoc = logMap[dateId];

      int completedHours = 0;
      if (logDoc != null) {
        // Count actual entries if log document exists
        completedHours = logDoc.totalEntries;
      }

      logDates.add(LogDate(
        dateId: dateId,
        date: date,
        completedHours: completedHours,
        totalHours: 24, // Standard 24-hour logging
      ));
    }

    // Sort by date (newest first for UI display)
    logDates.sort((a, b) => b.date.compareTo(a.date));

    return logDates;
  } catch (e) {
    throw Exception('Failed to load enhanced log dates: $e');
  }
});
