/// Models for the Admin Dashboard
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Summary statistics for the dashboard
class DashboardSummary {
  final int activeJobs;
  final double completionPercentage;
  final int totalAlerts;
  final int totalLogs;
  final DateTime lastSync;

  const DashboardSummary({
    required this.activeJobs,
    required this.completionPercentage,
    required this.totalAlerts,
    required this.totalLogs,
    required this.lastSync,
  });

  factory DashboardSummary.fromFirestore(Map<String, dynamic> data) {
    return DashboardSummary(
      activeJobs: data['activeJobs'] ?? 0,
      completionPercentage: (data['completionPercentage'] ?? 0.0).toDouble(),
      totalAlerts: data['totalAlerts'] ?? 0,
      totalLogs: data['totalLogs'] ?? 0,
      lastSync: data['lastSync']?.toDate() ?? DateTime.now(),
    );
  }

  static final empty = DashboardSummary(
    activeJobs: 0,
    completionPercentage: 0.0,
    totalAlerts: 0,
    totalLogs: 0,
    lastSync: DateTime(1970),
  );
}

/// Job filters for dashboard filtering
class JobFilters {
  final String? status;
  final String? logType;
  final String? operator;
  final DateTimeRange? dateRange;

  const JobFilters({
    this.status,
    this.logType,
    this.operator,
    this.dateRange,
  });

  JobFilters copyWith({
    String? status,
    String? logType,
    String? operator,
    DateTimeRange? dateRange,
  }) {
    return JobFilters(
      status: status ?? this.status,
      logType: logType ?? this.logType,
      operator: operator ?? this.operator,
      dateRange: dateRange ?? this.dateRange,
    );
  }

  static const empty = JobFilters();
}

/// Job status enumeration
enum JobStatus {
  active('Active', 'active'),
  completed('Completed', 'completed'),
  archived('Archived', 'archived'),
  paused('Paused', 'paused');

  const JobStatus(this.displayName, this.value);
  final String displayName;
  final String value;

  static JobStatus fromString(String value) {
    return JobStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => JobStatus.active,
    );
  }
}

/// Admin job data model
class AdminJob {
  final String id;
  final String projectName;
  final String logType;
  final JobStatus status;
  final String assignedOperator;
  final DateTime startDate;
  final DateTime? endDate;
  final int totalLogs;
  final int completedLogs;
  final DateTime lastActivity;
  final String location;

  const AdminJob({
    required this.id,
    required this.projectName,
    required this.logType,
    required this.status,
    required this.assignedOperator,
    required this.startDate,
    this.endDate,
    required this.totalLogs,
    required this.completedLogs,
    required this.lastActivity,
    required this.location,
  });

  factory AdminJob.fromFirestore(String id, Map<String, dynamic> data) {
    return AdminJob(
      id: id,
      projectName: data['projectName'] ?? 'Unknown Project',
      logType: data['logType'] ?? 'unknown',
      status: JobStatus.fromString(data['status'] ?? 'active'),
      assignedOperator: data['assignedOperator'] ?? 'Unassigned',
      startDate: data['startDate']?.toDate() ?? DateTime.now(),
      endDate: data['endDate']?.toDate(),
      totalLogs: data['totalLogs'] ?? 0,
      completedLogs: data['completedLogs'] ?? 0,
      lastActivity: data['lastActivity']?.toDate() ?? DateTime.now(),
      location: data['location'] ?? 'Unknown Location',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'projectName': projectName,
      'logType': logType,
      'status': status.value,
      'assignedOperator': assignedOperator,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'totalLogs': totalLogs,
      'completedLogs': completedLogs,
      'lastActivity': Timestamp.fromDate(lastActivity),
      'location': location,
    };
  }

  double get completionPercentage {
    if (totalLogs == 0) return 0.0;
    return (completedLogs / totalLogs * 100).clamp(0.0, 100.0);
  }

  bool get isOverdue {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!) && status != JobStatus.completed;
  }
}

/// Dashboard state model
class AdminDashboardState {
  final List<AdminJob> jobs;
  final List<AdminJob> filteredJobs;
  final DashboardSummary summary;
  final JobFilters filters;
  final bool isDarkMode;
  final bool isLoading;
  final String? error;

  AdminDashboardState({
    List<AdminJob> jobs = const [],
    List<AdminJob> filteredJobs = const [],
    DashboardSummary? summary,
    JobFilters filters = JobFilters.empty,
    bool isDarkMode = false,
    bool isLoading = false,
    String? error,
  })  : jobs = jobs,
        filteredJobs = filteredJobs,
        summary = summary ?? DashboardSummary.empty,
        filters = filters,
        isDarkMode = isDarkMode,
        isLoading = isLoading,
        error = error;

  AdminDashboardState copyWith({
    List<AdminJob>? jobs,
    List<AdminJob>? filteredJobs,
    DashboardSummary? summary,
    JobFilters? filters,
    bool? isDarkMode,
    bool? isLoading,
    String? error,
  }) {
    return AdminDashboardState(
      jobs: jobs ?? this.jobs,
      filteredJobs: filteredJobs ?? this.filteredJobs,
      summary: summary ?? this.summary,
      filters: filters ?? this.filters,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
