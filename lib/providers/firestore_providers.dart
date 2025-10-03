import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_data_service.dart';
import '../services/project_service.dart';
import '../models/firestore_models.dart';

/// Provider for the Firestore data service
final firestoreDataServiceProvider = Provider<FirestoreDataService>((ref) {
  return FirestoreDataService();
});

/// Provider for the project service
final projectServiceProvider = Provider<ProjectService>((ref) {
  return ProjectService();
});

/// Provider for project logs
final projectLogsProvider = FutureProvider.family<List<LogDocument>, String>((ref, projectId) {
  final service = ref.read(firestoreDataServiceProvider);
  return service.getProjectLogs(projectId);
});

/// Provider for log entries for a specific date
final logEntriesProvider = FutureProvider.family<List<LogEntryDocument>, ({String projectId, String logId})>((ref, params) {
  final service = ref.read(firestoreDataServiceProvider);
  return service.getLogEntries(params.projectId, params.logId);
});

/// Provider for a specific log document
final logDocumentProvider = FutureProvider.family<LogDocument?, ({String projectId, String logId})>((ref, params) {
  final service = ref.read(firestoreDataServiceProvider);
  return service.getLogDocument(params.projectId, params.logId);
});

/// Provider for a specific log entry
final logEntryProvider = FutureProvider.family<LogEntryDocument?, ({String projectId, String logId, String entryId})>((ref, params) {
  final service = ref.read(firestoreDataServiceProvider);
  return service.getLogEntry(params.projectId, params.logId, params.entryId);
});

/// Provider for project summary
final projectSummaryProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, projectId) {
  final service = ref.read(projectServiceProvider);
  return service.getProjectSummary(projectId);
});

/// Provider for project date range
final projectDateRangeProvider = FutureProvider.family<List<DateTime>, String>((ref, projectId) {
  final service = ref.read(firestoreDataServiceProvider);
  return service.getProjectDateRange(projectId);
});

/// Provider for checking if log exists for a date
final hasLogForDateProvider = FutureProvider.family<bool, ({String projectId, DateTime date})>((ref, params) {
  final service = ref.read(firestoreDataServiceProvider);
  return service.hasLogForDate(params.projectId, params.date);
});

/// Provider for date completion status
final dateCompletionStatusProvider = FutureProvider.family<LogCompletionStatus, ({String projectId, DateTime date})>((ref, params) {
  final service = ref.read(firestoreDataServiceProvider);
  return service.getDateCompletionStatus(params.projectId, params.date);
});

/// State notifier for managing current project context
class ProjectContextNotifier extends StateNotifier<String?> {
  ProjectContextNotifier() : super(null);

  void setProject(String projectId) {
    state = projectId;
  }

  void clearProject() {
    state = null;
  }
}

/// Provider for current project context
final projectContextProvider = StateNotifierProvider<ProjectContextNotifier, String?>((ref) {
  return ProjectContextNotifier();
});

/// Computed provider for current project logs
final currentProjectLogsProvider = FutureProvider<List<LogDocument>?>((ref) {
  final projectId = ref.watch(projectContextProvider);
  if (projectId == null) return null;
  
  return ref.watch(projectLogsProvider(projectId).future);
});

/// Computed provider for current project summary
final currentProjectSummaryProvider = FutureProvider<Map<String, dynamic>?>((ref) {
  final projectId = ref.watch(projectContextProvider);
  if (projectId == null) return null;
  
  return ref.watch(projectSummaryProvider(projectId).future);
});

/// Extension methods for easier provider access
extension FirestoreProvidersX on WidgetRef {
  /// Set the current project context
  void setCurrentProject(String projectId) {
    read(projectContextProvider.notifier).setProject(projectId);
  }

  /// Clear the current project context
  void clearCurrentProject() {
    read(projectContextProvider.notifier).clearProject();
  }

  /// Get the current project ID
  String? getCurrentProjectId() {
    return read(projectContextProvider);
  }

  /// Check if current project is demo project
  bool isCurrentProjectDemo() {
    final projectId = getCurrentProjectId();
    return projectId != null && projectId == 'DEMO-2025-001';
  }
}