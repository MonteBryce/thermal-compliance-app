import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/firestore_models.dart';
import 'demo_data_service.dart';
import 'path_helper.dart';

/// Service for managing project information and determining project start dates
class ProjectService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get project document with dynamic start date resolution
  Future<ProjectDocument?> getProject(String projectId) async {
    // Return demo data for demo project
    if (DemoDataService.isDemoProject(projectId)) {
      return DemoDataService.getDemoProject();
    }

    try {
      final doc = await PathHelper.projectDocRef(_firestore, projectId).get();

      if (!doc.exists) {
        return null;
      }

      return ProjectDocument.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get project: $e');
    }
  }

  /// Get the effective project start date, using fallback logic
  Future<DateTime?> getProjectStartDate(String projectId) async {
    try {
      // First, try to get the explicit project start date
      final project = await getProject(projectId);

      if (project?.projectStartDate != null) {
        return project!.projectStartDate;
      }

      // Fallback: Find the earliest log entry date
      return await _findEarliestLogEntryDate(projectId);
    } catch (e) {
      throw Exception('Failed to determine project start date: $e');
    }
  }

  /// Find the earliest log entry date in the project
  Future<DateTime?> _findEarliestLogEntryDate(String projectId) async {
    try {
      // Get all log documents for this project, ordered by date (earliest first)
      final logsQuery =
          await PathHelper.logsCollectionRef(_firestore, projectId)
              .orderBy('date')
              .limit(1)
              .get();

      if (logsQuery.docs.isEmpty) {
        return null;
      }

      // Get the first (earliest) log document
      final earliestLogDoc = logsQuery.docs.first;
      final dateId = earliestLogDoc.id; // Should be in YYYY-MM-DD format

      try {
        return DateTime.parse(dateId);
      } catch (parseError) {
        // If the document ID is not a valid date, try to get it from the document data
        final logData = earliestLogDoc.data();
        if (logData != null &&
            (logData as Map<String, dynamic>).containsKey('date')) {
          return DateTime.parse((logData as Map<String, dynamic>)['date']!);
        }
        return null;
      }
    } catch (e) {
      throw Exception('Failed to find earliest log entry: $e');
    }
  }

  /// Get all log dates from project start to today (or specified end date)
  Future<List<DateTime>> getProjectDateRange({
    required String projectId,
    DateTime? endDate,
  }) async {
    try {
      final startDate = await getProjectStartDate(projectId);
      if (startDate == null) {
        return [];
      }

      final end = endDate ?? DateTime.now();
      final dates = <DateTime>[];

      // Generate all dates from start to end
      var currentDate =
          DateTime(startDate.year, startDate.month, startDate.day);
      final endDay = DateTime(end.year, end.month, end.day);

      while (currentDate.isBefore(endDay) ||
          currentDate.isAtSameMomentAs(endDay)) {
        dates.add(currentDate);
        currentDate = currentDate.add(const Duration(days: 1));
      }

      return dates;
    } catch (e) {
      throw Exception('Failed to get project date range: $e');
    }
  }

  /// Update project start date
  Future<void> updateProjectStartDate({
    required String projectId,
    required DateTime startDate,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to update project');
    }

    try {
      await _firestore.collection('projects').doc(projectId).update({
        'projectStartDate': Timestamp.fromDate(startDate),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update project start date: $e');
    }
  }

  /// Automatically set project start date if missing
  Future<DateTime?> ensureProjectHasStartDate(String projectId) async {
    try {
      final project = await getProject(projectId);

      // If project doesn't exist, return null
      if (project == null) {
        return null;
      }

      // If project already has a start date, return it
      if (project.projectStartDate != null) {
        return project.projectStartDate;
      }

      // Find the earliest log entry
      final earliestDate = await _findEarliestLogEntryDate(projectId);

      if (earliestDate != null) {
        // Update the project with the calculated start date
        await updateProjectStartDate(
          projectId: projectId,
          startDate: earliestDate,
        );
        return earliestDate;
      }

      return null;
    } catch (e) {
      throw Exception('Failed to ensure project has start date: $e');
    }
  }

  /// Create or update a project with comprehensive data
  Future<ProjectDocument> createOrUpdateProject({
    required String projectId,
    required String projectName,
    required String projectNumber,
    required String location,
    required String unitNumber,
    DateTime? projectStartDate,
    String workOrderNumber = '',
    String tankType = '',
    String facilityTarget = '',
    String operatingTemperature = '',
    String benzeneTarget = '',
    bool h2sAmpRequired = false,
    String product = '',
    Map<String, dynamic> metadata = const {},
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to create/update project');
    }

    try {
      final now = DateTime.now();
      final projectDoc = ProjectDocument(
        projectId: projectId,
        projectName: projectName,
        projectNumber: projectNumber,
        location: location,
        unitNumber: unitNumber,
        workOrderNumber: workOrderNumber,
        tankType: tankType,
        facilityTarget: facilityTarget,
        operatingTemperature: operatingTemperature,
        benzeneTarget: benzeneTarget,
        h2sAmpRequired: h2sAmpRequired,
        product: product,
        projectStartDate: projectStartDate,
        createdAt: now,
        updatedAt: now,
        createdBy: user.uid,
        metadata: metadata,
      );

      await PathHelper.projectDocRef(_firestore, projectId)
          .set(projectDoc.toFirestore(), SetOptions(merge: true));

      return projectDoc;
    } catch (e) {
      throw Exception('Failed to create/update project: $e');
    }
  }

  /// Get project summary with computed statistics
  Future<Map<String, dynamic>> getProjectSummary(String projectId) async {
    // Return demo data for demo project
    if (DemoDataService.isDemoProject(projectId)) {
      return DemoDataService.getDemoProjectSummary();
    }

    try {
      final project = await getProject(projectId);
      if (project == null) {
        throw Exception('Project not found');
      }

      final startDate = await getProjectStartDate(projectId);

      // Get total logs count
      final logsSnapshot = await PathHelper.logsCollectionRef(_firestore, projectId).get();

      final totalLogs = logsSnapshot.docs.length;

      // Calculate project duration if start date is available
      int? projectDurationDays;
      if (startDate != null) {
        final today = DateTime.now();
        projectDurationDays = today.difference(startDate).inDays + 1;
      }

      return {
        'project': project,
        'startDate': startDate,
        'totalLogs': totalLogs,
        'projectDurationDays': projectDurationDays,
        'hasExplicitStartDate': project.projectStartDate != null,
        'calculatedFromLogs':
            project.projectStartDate == null && startDate != null,
      };
    } catch (e) {
      throw Exception('Failed to get project summary: $e');
    }
  }
}
