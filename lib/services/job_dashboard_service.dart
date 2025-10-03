/// Job Dashboard Firestore Service
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/firestore_models.dart';
import '../models/job_dashboard_models.dart';
import 'path_helper.dart';
import '../widgets/metric_status_cell.dart';

class JobDashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all projects for the dashboard
  Stream<List<JobDashboardData>> getJobDashboardStream() {
    return _firestore
        .collection('projects')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<JobDashboardData> jobs = [];
      
      for (var doc in snapshot.docs) {
        try {
          final project = ProjectDocument.fromFirestore(doc);
          final jobData = await _convertProjectToJobDashboardData(project);
          jobs.add(jobData);
        } catch (e) {
          print('Error converting project ${doc.id}: $e');
          // Continue with other projects even if one fails
        }
      }
      
      return jobs;
    });
  }

  /// Get dashboard summary metrics
  Future<JobDashboardSummary> getDashboardSummary() async {
    try {
      final projectsSnapshot = await _firestore
          .collection('projects')
          .get();
      
      int totalActiveJobs = 0;
      int totalCompletedJobs = 0;
      int pendingReviewCount = 0;
      int completedTodayCount = 0;
      int newJobsThisWeek = 0;
      
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final todayStart = DateTime(now.year, now.month, now.day);
      
      for (var doc in projectsSnapshot.docs) {
        try {
          final project = ProjectDocument.fromFirestore(doc);
          final status = await _getProjectStatus(project);
          
          // Count by status
          switch (status) {
            case 'Active':
              totalActiveJobs++;
              break;
            case 'Complete':
              totalCompletedJobs++;
              // Check if completed today
              if (project.updatedAt.isAfter(todayStart)) {
                completedTodayCount++;
              }
              break;
            case 'Pending Review':
              pendingReviewCount++;
              break;
          }
          
          // Check if created this week
          if (project.createdAt.isAfter(weekAgo)) {
            newJobsThisWeek++;
          }
          
        } catch (e) {
          print('Error processing project ${doc.id}: $e');
        }
      }
      
      final totalJobs = totalActiveJobs + totalCompletedJobs + pendingReviewCount;
      final averageCompletionRate = totalJobs > 0 
          ? ((totalCompletedJobs / totalJobs) * 100) 
          : 0.0;
      
      return JobDashboardSummary(
        totalActiveJobs: totalActiveJobs,
        totalCompletedJobs: totalCompletedJobs,
        pendingReviewCount: pendingReviewCount,
        completedTodayCount: completedTodayCount,
        averageCompletionRate: averageCompletionRate,
        newJobsThisWeek: newJobsThisWeek,
      );
      
    } catch (e) {
      throw Exception('Failed to get dashboard summary: $e');
    }
  }

  /// Convert ProjectDocument to JobDashboardData
  Future<JobDashboardData> _convertProjectToJobDashboardData(ProjectDocument project) async {
    try {
      // Get recent logs for this project
      final logsSnapshot = await PathHelper.logsCollectionRef(_firestore, project.projectId)
          .orderBy('date', descending: true)
          .limit(10)
          .get();
      
      // Calculate metrics from logs
      int totalHours = 0;
      int loggedHours = 0;
      List<MetricStatus> systemMetrics = [];
      List<String> operators = <String>{}.toList();
      
      for (var logDoc in logsSnapshot.docs) {
        try {
          final log = LogDocument.fromFirestore(logDoc);
          totalHours += 24; // Each log represents a day (24 hours)
          loggedHours += log.completedHours;
          
          // Add operators
          operators.addAll(log.operatorIds);
          
          // Generate system metrics based on completion status
          systemMetrics.add(_getMetricStatusFromLog(log));
        } catch (e) {
          print('Error processing log ${logDoc.id}: $e');
        }
      }
      
      // Remove duplicates and limit operators
      operators = operators.toSet().toList();
      
      // Ensure we have at least 7 days of metrics
      while (systemMetrics.length < 7) {
        systemMetrics.add(MetricStatus.unknown);
      }
      
      // Calculate estimated completion
      final estimatedCompletion = totalHours > 0 
          ? ((loggedHours / totalHours) * 100) 
          : 0.0;
      
      // Determine project status
      final status = await _getProjectStatus(project);
      
      // Generate date range
      final dateRange = _generateDateRange(project);
      
      return JobDashboardData(
        id: project.projectId,
        projectName: project.projectName,
        facility: project.location ?? 'Unknown Facility',
        projectType: _mapTankTypeToProjectType(project.tankType ?? 'Unknown'),
        dateRange: dateRange,
        hoursLogged: loggedHours,
        totalHours: totalHours,
        systemMetrics: systemMetrics.take(7).toList(),
        status: status,
        priority: _determinePriority(project, logsSnapshot.docs.length),
        assignedOperators: operators.take(4).toList(),
        createdDate: project.createdAt,
        completedDate: status == 'Complete' ? project.updatedAt : null,
        estimatedCompletion: estimatedCompletion.clamp(0.0, 100.0),
      );
      
    } catch (e) {
      throw Exception('Failed to convert project to job dashboard data: $e');
    }
  }

  /// Get project status based on recent activity and logs
  Future<String> _getProjectStatus(ProjectDocument project) async {
    try {
      final now = DateTime.now();
      final daysSinceUpdate = now.difference(project.updatedAt).inDays;
      
      // Get recent logs to determine status
      final logsSnapshot = await PathHelper.logsCollectionRef(_firestore, project.projectId)
          .orderBy('date', descending: true)
          .limit(3)
          .get();
      
      if (logsSnapshot.docs.isEmpty) {
        return 'Active'; // New project
      }
      
      // Check if project has recent activity
      bool hasRecentActivity = daysSinceUpdate < 7;
      
      // Check completion status of recent logs
      int completeLogs = 0;
      int validatedLogs = 0;
      
      for (var doc in logsSnapshot.docs) {
        final log = LogDocument.fromFirestore(doc);
        if (log.completionStatus == LogCompletionStatus.complete) {
          completeLogs++;
        }
        if (log.completionStatus == LogCompletionStatus.validated) {
          validatedLogs++;
        }
      }
      
      // Determine status based on completion and activity
      if (validatedLogs == logsSnapshot.docs.length && !hasRecentActivity) {
        return 'Complete';
      } else if (completeLogs > 0 && !hasRecentActivity) {
        return 'Pending Review';
      } else if (hasRecentActivity) {
        return 'Active';
      } else {
        return 'On Hold';
      }
      
    } catch (e) {
      // Fallback to active if we can't determine status
      return 'Active';
    }
  }

  /// Convert tank type to project type
  String _mapTankTypeToProjectType(String tankType) {
    switch (tankType.toLowerCase()) {
      case 'storage tank':
        return 'Tank Inspection';
      case 'process tank':
        return 'System Upgrade';
      case 'reactor':
        return 'Safety Inspection';
      default:
        return 'Maintenance';
    }
  }

  /// Determine priority based on project properties
  String _determinePriority(ProjectDocument project, int logCount) {
    // High priority if H2S amplification required
    if (project.h2sAmpRequired) {
      return 'Critical';
    }
    
    // High priority if benzene target is low (strict requirements)
    final benzeneTarget = project.benzeneTarget.toLowerCase() ?? '';
    if (benzeneTarget.contains('0.5') || benzeneTarget.contains('< 1')) {
      return 'High';
    }
    
    // Medium priority if recent activity
    final daysSinceUpdate = DateTime.now().difference(project.updatedAt).inDays;
    if (daysSinceUpdate < 3) {
      return 'High';
    } else if (daysSinceUpdate < 7) {
      return 'Medium';
    } else {
      return 'Low';
    }
  }

  /// Generate date range string
  String _generateDateRange(ProjectDocument project) {
    final start = project.createdAt;
    final end = project.updatedAt;
    
    final startMonth = start.month;
    final startDay = start.day;
    final endMonth = end.month;
    final endDay = end.day;
    
    return '$startMonth/$startDay - $endMonth/$endDay';
  }

  /// Get metric status from log completion
  MetricStatus _getMetricStatusFromLog(LogDocument log) {
    switch (log.completionStatus) {
      case LogCompletionStatus.validated:
        return MetricStatus.pass;
      case LogCompletionStatus.complete:
        return MetricStatus.pass;
      case LogCompletionStatus.incomplete:
        return log.completedHours > 12 ? MetricStatus.warning : MetricStatus.fail;
      case LogCompletionStatus.notStarted:
        return MetricStatus.fail;
      default:
        return MetricStatus.unknown;
    }
  }

  /// Get active projects count
  Future<int> getActiveProjectsCount() async {
    try {
      final summary = await getDashboardSummary();
      return summary.totalActiveJobs;
    } catch (e) {
      return 0;
    }
  }

  /// Get projects by status
  Stream<List<JobDashboardData>> getProjectsByStatus(String status) {
    return getJobDashboardStream().map((jobs) => 
        jobs.where((job) => job.status == status).toList());
  }

  /// Get projects by priority
  Stream<List<JobDashboardData>> getProjectsByPriority(String priority) {
    return getJobDashboardStream().map((jobs) => 
        jobs.where((job) => job.priority == priority).toList());
  }

  /// Search projects
  Stream<List<JobDashboardData>> searchProjects(String query) {
    return getJobDashboardStream().map((jobs) {
      if (query.isEmpty) return jobs;
      
      final lowerQuery = query.toLowerCase();
      return jobs.where((job) =>
          job.projectName.toLowerCase().contains(lowerQuery) ||
          job.facility.toLowerCase().contains(lowerQuery) ||
          job.projectType.toLowerCase().contains(lowerQuery)
      ).toList();
    });
  }
}
