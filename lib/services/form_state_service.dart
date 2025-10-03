import 'package:flutter/foundation.dart';
import '../models/hive_models.dart';
import 'local_database_service.dart';

class FormStateService {
  static const String _draftPrefix = 'draft_';
  
  static String _generateDraftId({
    required String projectId,
    required String date,
    required String formType,
    int? hour,
  }) {
    final hourSuffix = hour != null ? '_hour_$hour' : '_daily';
    return '${_draftPrefix}${formType}_${projectId}_${date}$hourSuffix';
  }

  static Future<void> saveFormProgress({
    required String projectId,
    required String projectName,
    required String date,
    required String formType,
    required Map<String, dynamic> formData,
    required String userId,
    int? hour,
    String? existingEntryId,
  }) async {
    try {
      final draftId = existingEntryId ?? _generateDraftId(
        projectId: projectId,
        date: date,
        formType: formType,
        hour: hour,
      );

      final draftEntry = LogEntry(
        id: draftId,
        projectId: projectId,
        projectName: projectName,
        date: date,
        hour: hour?.toString() ?? '0',
        data: Map.from(formData),
        status: 'draft',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: userId,
        isSynced: false,
      );

      await LocalDatabaseService.saveLogEntry(draftEntry);
      debugPrint('Form progress saved: $draftId');
    } catch (e) {
      debugPrint('Failed to save form progress: $e');
      rethrow;
    }
  }

  static Future<LogEntry?> loadFormProgress({
    required String projectId,
    required String date,
    required String formType,
    int? hour,
  }) async {
    try {
      final draftId = _generateDraftId(
        projectId: projectId,
        date: date,
        formType: formType,
        hour: hour,
      );

      final entry = await LocalDatabaseService.getLogEntry(draftId);
      if (entry?.status == 'draft') {
        debugPrint('Form progress loaded: $draftId');
        return entry;
      }
      return null;
    } catch (e) {
      debugPrint('Failed to load form progress: $e');
      return null;
    }
  }

  static Future<List<LogEntry>> getDraftEntries({
    String? projectId,
  }) async {
    try {
      final allEntries = await LocalDatabaseService.getAllLogEntries();
      
      return allEntries.where((entry) {
        final isDraft = entry.status == 'draft' && entry.id.startsWith(_draftPrefix);
        final matchesProject = projectId == null || entry.projectId == projectId;
        return isDraft && matchesProject;
      }).toList();
    } catch (e) {
      debugPrint('Failed to get draft entries: $e');
      return [];
    }
  }

  static Future<void> deleteDraft(String draftId) async {
    try {
      await LocalDatabaseService.deleteLogEntry(draftId);
      debugPrint('Draft deleted: $draftId');
    } catch (e) {
      debugPrint('Failed to delete draft: $e');
      rethrow;
    }
  }

  static Future<void> promoteDraftToCompleted({
    required String draftId,
    required Map<String, dynamic> finalData,
  }) async {
    try {
      final draft = await LocalDatabaseService.getLogEntry(draftId);
      if (draft == null) {
        throw Exception('Draft not found: $draftId');
      }

      final newId = draftId.replaceFirst(_draftPrefix, '');
      
      final completedEntry = LogEntry(
        id: newId,
        projectId: draft.projectId,
        projectName: draft.projectName,
        date: draft.date,
        hour: draft.hour,
        data: Map.from(finalData),
        status: 'completed',
        createdAt: draft.createdAt,
        updatedAt: DateTime.now(),
        createdBy: draft.createdBy,
        isSynced: false,
      );

      await LocalDatabaseService.saveLogEntry(completedEntry);
      await LocalDatabaseService.deleteLogEntry(draftId);
      
      debugPrint('Draft promoted to completed: $draftId -> $newId');
    } catch (e) {
      debugPrint('Failed to promote draft: $e');
      rethrow;
    }
  }

  static Future<void> autoSaveFormProgress({
    required String projectId,
    required String projectName,
    required String date,
    required String formType,
    required Map<String, dynamic> formData,
    required String userId,
    int? hour,
    Duration delay = const Duration(seconds: 2),
  }) async {
    await Future.delayed(delay);
    
    if (formData.isNotEmpty && _hasValidData(formData)) {
      await saveFormProgress(
        projectId: projectId,
        projectName: projectName,
        date: date,
        formType: formType,
        formData: formData,
        userId: userId,
        hour: hour,
      );
    }
  }

  static bool _hasValidData(Map<String, dynamic> formData) {
    return formData.values.any((value) {
      if (value == null) return false;
      if (value is String) return value.trim().isNotEmpty;
      if (value is num) return value != 0;
      if (value is bool) return value;
      return true;
    });
  }

  static Future<FormResumeInfo?> getResumeInfo({
    required String projectId,
    required String date,
    required String formType,
    int? hour,
  }) async {
    try {
      final draft = await loadFormProgress(
        projectId: projectId,
        date: date,
        formType: formType,
        hour: hour,
      );

      if (draft == null) return null;

      final completedFieldsCount = draft.data.values
          .where((value) => value != null && value.toString().isNotEmpty)
          .length;

      return FormResumeInfo(
        draftId: draft.id,
        lastModified: draft.updatedAt,
        completedFields: completedFieldsCount,
        totalFields: draft.data.length,
        canResume: completedFieldsCount > 0,
      );
    } catch (e) {
      debugPrint('Failed to get resume info: $e');
      return null;
    }
  }

  static Future<void> clearOldDrafts({
    Duration maxAge = const Duration(days: 7),
  }) async {
    try {
      final drafts = await getDraftEntries();
      final cutoffDate = DateTime.now().subtract(maxAge);

      for (final draft in drafts) {
        if (draft.updatedAt.isBefore(cutoffDate)) {
          await deleteDraft(draft.id);
          debugPrint('Deleted old draft: ${draft.id}');
        }
      }
    } catch (e) {
      debugPrint('Failed to clear old drafts: $e');
    }
  }
}

class FormResumeInfo {
  final String draftId;
  final DateTime lastModified;
  final int completedFields;
  final int totalFields;
  final bool canResume;

  const FormResumeInfo({
    required this.draftId,
    required this.lastModified,
    required this.completedFields,
    required this.totalFields,
    required this.canResume,
  });

  double get completionPercentage {
    if (totalFields == 0) return 0.0;
    return completedFields / totalFields;
  }

  String get formattedLastModified {
    final now = DateTime.now();
    final difference = now.difference(lastModified);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}