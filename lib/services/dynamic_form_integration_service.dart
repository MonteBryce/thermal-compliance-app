import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/dynamic_form_schema.dart';
import '../models/firestore_models.dart';
import '../models/hive_models.dart';
import 'dynamic_form_template_service.dart';
import 'dynamic_form_validation_service.dart';
import 'local_database_service.dart';
import 'form_prefill_service.dart';

/// Service that integrates dynamic forms with job logType and data submission
/// Handles the complete flow from template selection to data storage
class DynamicFormIntegrationService {
  
  /// Get appropriate form template based on job logType
  static Future<DynamicFormTemplate?> getFormTemplateForJob({
    required String logType,
    required String projectId,
    bool useCache = true,
  }) async {
    try {
      // Get project details for customization
      final project = await _getProjectDetails(projectId);
      
      // Get base template from service
      final template = await DynamicFormTemplateService.getFormTemplate(
        logType: logType,
        projectId: projectId,
        useCache: useCache,
      );
      
      if (template == null) {
        debugPrint('No template found for logType: $logType, projectId: $projectId');
        return null;
      }
      
      // Apply project-specific customizations
      if (project != null) {
        return await DynamicFormTemplateService.getCustomizedFormTemplate(
          logType: logType,
          project: project,
          useCache: useCache,
        );
      }
      
      return template;
      
    } catch (e) {
      debugPrint('Error getting form template for job: $e');
      return null;
    }
  }
  
  /// Create pre-filled form data based on project and previous entries
  static Future<Map<String, dynamic>> createPrefilledFormData({
    required DynamicFormTemplate template,
    required String projectId,
    String? date,
    String? hour,
  }) async {
    try {
      // Get project details
      final project = await _getProjectDetails(projectId);
      
      // Get base prefill data from existing service
      final basePrefillData = await FormPrefillService.getLogEntryPrefillData(
        selectedProject: project,
        date: date,
        hour: hour,
      );
      
      // Enhance with template-specific prefill logic
      final enhancedData = await _enhanceWithTemplateDefaults(
        template: template,
        basePrefillData: basePrefillData,
        project: project,
      );
      
      // Add previous entry context if available
      final contextualData = await _addPreviousEntryContext(
        template: template,
        projectId: projectId,
        enhancedData: enhancedData,
      );
      
      return contextualData;
      
    } catch (e) {
      debugPrint('Error creating prefilled form data: $e');
      return {};
    }
  }
  
  /// Submit form data with validation and storage
  static Future<FormSubmissionResult> submitFormData({
    required DynamicFormTemplate template,
    required Map<String, dynamic> formData,
    required String projectId,
    required String userId,
    bool validateBeforeSubmit = true,
  }) async {
    try {
      // Get project details for validation context
      final project = await _getProjectDetails(projectId);
      
      // Perform validation if requested
      if (validateBeforeSubmit) {
        final validationResult = DynamicFormValidationService.validateForm(
          template: template,
          formValues: formData,
          project: project,
        );
        
        if (!validationResult.isValid) {
          return FormSubmissionResult(
            success: false,
            errors: validationResult.errors,
            warnings: validationResult.warnings,
            message: 'Form validation failed. Please correct the errors and try again.',
          );
        }
        
        // Continue with warnings but notify user
        if (validationResult.hasWarnings) {
          debugPrint('Form submitted with warnings: ${validationResult.warnings}');
        }
      }
      
      // Prepare submission data
      final submissionData = await _prepareSubmissionData(
        template: template,
        formData: formData,
        projectId: projectId,
        userId: userId,
      );
      
      // Submit to Firestore
      final firestoreResult = await _submitToFirestore(submissionData, template.logType);
      
      // Cache locally for offline support
      await _cacheSubmissionLocally(submissionData, template);
      
      // Update user session activity
      await _updateUserActivity(projectId, template.logType);
      
      return FormSubmissionResult(
        success: firestoreResult.success,
        documentId: firestoreResult.documentId,
        errors: firestoreResult.errors,
        warnings: firestoreResult.warnings,
        message: firestoreResult.success 
            ? 'Form submitted successfully' 
            : 'Failed to submit form: ${firestoreResult.message}',
      );
      
    } catch (e) {
      debugPrint('Error submitting form data: $e');
      
      // Attempt offline submission
      return await _handleOfflineSubmission(template, formData, projectId, userId);
    }
  }
  
  /// Get form submission history for analytics
  static Future<List<FormSubmissionSummary>> getSubmissionHistory({
    required String projectId,
    String? logType,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      Query query = FirebaseFirestore.instance.collection('logEntries')
          .where('projectId', isEqualTo: projectId);
      
      if (logType != null) {
        query = query.where('logType', isEqualTo: logType);
      }
      
      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: startDate);
      }
      
      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: endDate);
      }
      
      query = query.orderBy('createdAt', descending: true).limit(limit);
      
      final snapshot = await query.get();
      
      return snapshot.docs.map((doc) => FormSubmissionSummary.fromFirestore(doc)).toList();
      
    } catch (e) {
      debugPrint('Error getting submission history: $e');
      return [];
    }
  }
  
  /// Sync offline submissions when connection is restored
  static Future<SyncResult> syncOfflineSubmissions() async {
    try {
      final offlineSubmissions = await LocalDatabaseService.getPendingSyncEntries();
      
      int successCount = 0;
      int failCount = 0;
      final List<String> errors = [];
      
      for (final entry in offlineSubmissions) {
        try {
          final success = await _resubmitOfflineEntry(entry);
          if (success) {
            successCount++;
            await LocalDatabaseService.markSyncEntryCompleted(entry.id);
          } else {
            failCount++;
            errors.add('Failed to sync entry: ${entry.id}');
          }
        } catch (e) {
          failCount++;
          errors.add('Error syncing entry ${entry.id}: $e');
        }
      }
      
      return SyncResult(
        totalProcessed: offlineSubmissions.length,
        successCount: successCount,
        failCount: failCount,
        errors: errors,
      );
      
    } catch (e) {
      debugPrint('Error syncing offline submissions: $e');
      return SyncResult(
        totalProcessed: 0,
        successCount: 0,
        failCount: 0,
        errors: ['Sync process failed: $e'],
      );
    }
  }
  
  // Private helper methods
  
  static Future<ProjectDocument?> _getProjectDetails(String projectId) async {
    try {
      // First try to get from local cache
      final cachedProject = await LocalDatabaseService.getCachedProject(projectId);
      if (cachedProject != null) {
        return _convertCachedToProjectDocument(cachedProject);
      }
      
      // Fall back to Firestore
      final doc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .get();
          
      if (doc.exists) {
        return ProjectDocument.fromFirestore(doc);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting project details: $e');
      return null;
    }
  }
  
  static ProjectDocument _convertCachedToProjectDocument(CachedProject cached) {
    return ProjectDocument(
      projectId: cached.projectId,
      projectName: cached.projectName,
      projectNumber: cached.projectNumber,
      location: cached.location,
      unitNumber: cached.unitNumber,
      workOrderNumber: cached.metadata['workOrderNumber'] ?? '',
      tankType: cached.metadata['tankType'] ?? '',
      facilityTarget: cached.metadata['facilityTarget'] ?? '',
      operatingTemperature: cached.metadata['operatingTemperature'] ?? '',
      benzeneTarget: cached.metadata['benzeneTarget'] ?? '',
      h2sAmpRequired: cached.metadata['h2sAmpRequired'] ?? false,
      product: cached.metadata['product'] ?? '',
      createdAt: cached.cachedAt,
      updatedAt: cached.cachedAt,
      createdBy: cached.createdBy,
    );
  }
  
  static Future<Map<String, dynamic>> _enhanceWithTemplateDefaults(
      {required DynamicFormTemplate template,
      required Map<String, dynamic> basePrefillData,
      ProjectDocument? project}) async {
    final enhanced = Map<String, dynamic>.from(basePrefillData);
    
    // Apply template field defaults
    for (final field in template.fields) {
      if (!enhanced.containsKey(field.key) && field.defaultValue != null) {
        enhanced[field.key] = field.defaultValue;
      }
      
      // Apply project-specific defaults if available
      if (project != null && field.projectSpecificDefault != null) {
        enhanced[field.key] = field.projectSpecificDefault;
      }
    }
    
    return enhanced;
  }
  
  static Future<Map<String, dynamic>> _addPreviousEntryContext({
    required DynamicFormTemplate template,
    required String projectId,
    required Map<String, dynamic> enhancedData,
  }) async {
    try {
      // Get the most recent entry for context
      final recentEntry = await _getRecentEntry(projectId, template.logType);
      
      if (recentEntry != null) {
        // Add contextual fields that might be helpful
        enhancedData['_previousEntryContext'] = {
          'lastEntryDate': recentEntry['date'],
          'lastEntryTime': recentEntry['createdAt'],
          'suggestedValues': _extractSuggestedValues(recentEntry, template),
        };
      }
      
      return enhancedData;
    } catch (e) {
      debugPrint('Error adding previous entry context: $e');
      return enhancedData;
    }
  }
  
  static Future<Map<String, dynamic>?> _getRecentEntry(String projectId, String logType) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('logEntries')
          .where('projectId', isEqualTo: projectId)
          .where('logType', isEqualTo: logType)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
          
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data();
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting recent entry: $e');
      return null;
    }
  }
  
  static Map<String, dynamic> _extractSuggestedValues(
    Map<String, dynamic> recentEntry, 
    DynamicFormTemplate template
  ) {
    final suggestions = <String, dynamic>{};
    
    // Extract stable values that typically don't change between entries
    final stableFields = ['equipmentId', 'workOrderNumber', 'operatorName'];
    
    for (final fieldName in stableFields) {
      if (recentEntry.containsKey(fieldName)) {
        suggestions[fieldName] = recentEntry[fieldName];
      }
    }
    
    return suggestions;
  }
  
  static Future<Map<String, dynamic>> _prepareSubmissionData({
    required DynamicFormTemplate template,
    required Map<String, dynamic> formData,
    required String projectId,
    required String userId,
  }) async {
    final submissionData = Map<String, dynamic>.from(formData);
    
    // Add metadata
    submissionData['_metadata'] = {
      'templateId': template.id,
      'templateVersion': template.version,
      'logType': template.logType,
      'projectId': projectId,
      'userId': userId,
      'submittedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    
    // Add form-specific data structure
    submissionData['formStructure'] = {
      'fields': template.fields.map((f) => {
        'id': f.id,
        'key': f.key,
        'type': f.type.name,
        'category': f.category.name,
      }).toList(),
      'sections': template.sections.map((s) => {
        'id': s.id,
        'title': s.title,
        'fieldIds': s.fieldIds,
      }).toList(),
    };
    
    return submissionData;
  }
  
  static Future<FirestoreSubmissionResult> _submitToFirestore(
    Map<String, dynamic> submissionData, 
    String logType
  ) async {
    try {
      final docRef = await FirebaseFirestore.instance
          .collection('logEntries')
          .add(submissionData);
          
      return FirestoreSubmissionResult(
        success: true,
        documentId: docRef.id,
        message: 'Successfully submitted to Firestore',
      );
      
    } catch (e) {
      return FirestoreSubmissionResult(
        success: false,
        message: 'Firestore submission failed: $e',
      );
    }
  }
  
  static Future<void> _cacheSubmissionLocally(
    Map<String, dynamic> submissionData,
    DynamicFormTemplate template,
  ) async {
    try {
      final logEntry = LogEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        projectId: submissionData['_metadata']['projectId'],
        logType: template.logType,
        date: submissionData['date'] ?? DateTime.now().toIso8601String().split('T')[0],
        hour: submissionData['hour'],
        data: Map<String, dynamic>.from(submissionData)..remove('_metadata'),
        createdAt: DateTime.now(),
        syncStatus: 'synced', // Mark as synced since we just submitted to Firestore
        userId: submissionData['_metadata']['userId'],
      );
      
      await LocalDatabaseService.saveLogEntry(logEntry);
      
    } catch (e) {
      debugPrint('Error caching submission locally: $e');
    }
  }
  
  static Future<void> _updateUserActivity(String projectId, String logType) async {
    try {
      await LocalDatabaseService.updateSessionActivity();
      await FormPrefillService.trackProjectUsage(projectId);
    } catch (e) {
      debugPrint('Error updating user activity: $e');
    }
  }
  
  static Future<FormSubmissionResult> _handleOfflineSubmission(
    DynamicFormTemplate template,
    Map<String, dynamic> formData,
    String projectId,
    String userId,
  ) async {
    try {
      // Create sync queue entry
      final syncEntry = SyncQueueEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        operation: 'create_log_entry',
        collection: 'logEntries',
        data: formData,
        priority: 1,
        createdAt: DateTime.now(),
        retryCount: 0,
        userId: userId,
      );
      
      await LocalDatabaseService.addToSyncQueue(syncEntry);
      
      // Cache locally
      await _cacheSubmissionLocally(
        await _prepareSubmissionData(
          template: template,
          formData: formData,
          projectId: projectId,
          userId: userId,
        ),
        template,
      );
      
      return FormSubmissionResult(
        success: true,
        message: 'Form saved offline. Will sync when connection is restored.',
        isOfflineSubmission: true,
      );
      
    } catch (e) {
      return FormSubmissionResult(
        success: false,
        message: 'Failed to save form offline: $e',
      );
    }
  }
  
  static Future<bool> _resubmitOfflineEntry(SyncQueueEntry entry) async {
    try {
      final result = await _submitToFirestore(entry.data, entry.data['logType']);
      return result.success;
    } catch (e) {
      debugPrint('Error resubmitting offline entry: $e');
      return false;
    }
  }
}

/// Result of form submission
class FormSubmissionResult {
  final bool success;
  final String? documentId;
  final Map<String, String> errors;
  final Map<String, String> warnings;
  final String message;
  final bool isOfflineSubmission;
  
  const FormSubmissionResult({
    required this.success,
    this.documentId,
    this.errors = const {},
    this.warnings = const {},
    required this.message,
    this.isOfflineSubmission = false,
  });
  
  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
}

/// Result of Firestore submission
class FirestoreSubmissionResult {
  final bool success;
  final String? documentId;
  final Map<String, String> errors;
  final Map<String, String> warnings;
  final String message;
  
  const FirestoreSubmissionResult({
    required this.success,
    this.documentId,
    this.errors = const {},
    this.warnings = const {},
    required this.message,
  });
}

/// Summary of a form submission
class FormSubmissionSummary {
  final String id;
  final String projectId;
  final String logType;
  final String? templateId;
  final DateTime submittedAt;
  final String submittedBy;
  final Map<String, dynamic> summaryData;
  
  const FormSubmissionSummary({
    required this.id,
    required this.projectId,
    required this.logType,
    this.templateId,
    required this.submittedAt,
    required this.submittedBy,
    required this.summaryData,
  });
  
  factory FormSubmissionSummary.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final metadata = data['_metadata'] as Map<String, dynamic>? ?? {};
    
    return FormSubmissionSummary(
      id: doc.id,
      projectId: metadata['projectId'] ?? '',
      logType: metadata['logType'] ?? '',
      templateId: metadata['templateId'],
      submittedAt: (metadata['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      submittedBy: metadata['userId'] ?? '',
      summaryData: _extractSummaryData(data),
    );
  }
  
  static Map<String, dynamic> _extractSummaryData(Map<String, dynamic> data) {
    final summary = <String, dynamic>{};
    
    // Extract key fields that are commonly used in summaries
    final summaryFields = [
      'inletReading', 'outletReading', 'exhaustTemperature', 
      'h2sReading', 'lelInletReading', 'date', 'hour'
    ];
    
    for (final field in summaryFields) {
      if (data.containsKey(field)) {
        summary[field] = data[field];
      }
    }
    
    return summary;
  }
}

/// Result of sync operation
class SyncResult {
  final int totalProcessed;
  final int successCount;
  final int failCount;
  final List<String> errors;
  
  const SyncResult({
    required this.totalProcessed,
    required this.successCount,
    required this.failCount,
    required this.errors,
  });
  
  bool get allSuccessful => failCount == 0;
  double get successRate => totalProcessed > 0 ? successCount / totalProcessed : 0.0;
}