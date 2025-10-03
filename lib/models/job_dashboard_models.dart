/// Job Dashboard Data Models
import 'package:flutter/material.dart';
import '../widgets/metric_status_cell.dart';

class JobDashboardData {
  final String id;
  final String projectName;
  final String facility;
  final String projectType;
  final String dateRange;
  final int hoursLogged;
  final int totalHours;
  final List<MetricStatus> systemMetrics;
  final String status;
  final String priority;
  final List<String> assignedOperators;
  final DateTime createdDate;
  final DateTime? completedDate;
  final double estimatedCompletion;

  const JobDashboardData({
    required this.id,
    required this.projectName,
    required this.facility,
    required this.projectType,
    required this.dateRange,
    required this.hoursLogged,
    required this.totalHours,
    required this.systemMetrics,
    required this.status,
    required this.priority,
    required this.assignedOperators,
    required this.createdDate,
    this.completedDate,
    required this.estimatedCompletion,
  });

  static List<JobDashboardData> getMockData() {
    return [
      JobDashboardData(
        id: '1',
        projectName: 'Refinery Tank A-203 Maintenance',
        facility: 'Houston Plant',
        projectType: 'Tank Inspection',
        dateRange: '1/15 - 1/29',
        hoursLogged: 168,
        totalHours: 336,
        systemMetrics: [
          MetricStatus.pass,
          MetricStatus.pass,
          MetricStatus.warning,
          MetricStatus.pass,
          MetricStatus.pass,
          MetricStatus.pass,
          MetricStatus.pass,
        ],
        status: 'Active',
        priority: 'High',
        assignedOperators: ['Alex Walker', 'Maria Johnson'],
        createdDate: DateTime.now().subtract(const Duration(days: 14)),
        estimatedCompletion: 75.5,
      ),
      JobDashboardData(
        id: '2',
        projectName: 'Pipeline Integrity Assessment',
        facility: 'Dallas Plant',
        projectType: 'Safety Inspection',
        dateRange: '1/20 - 2/10',
        hoursLogged: 124,
        totalHours: 240,
        systemMetrics: [
          MetricStatus.pass,
          MetricStatus.pass,
          MetricStatus.fail,
          MetricStatus.warning,
          MetricStatus.pass,
          MetricStatus.pass,
          MetricStatus.warning,
        ],
        status: 'Pending Review',
        priority: 'Critical',
        assignedOperators: ['David Chen', 'Sarah Wilson'],
        createdDate: DateTime.now().subtract(const Duration(days: 10)),
        estimatedCompletion: 52.3,
      ),
      JobDashboardData(
        id: '3',
        projectName: 'Benzene Monitoring System Update',
        facility: 'Austin Plant',
        projectType: 'System Upgrade',
        dateRange: '1/10 - 1/31',
        hoursLogged: 336,
        totalHours: 336,
        systemMetrics: [
          MetricStatus.pass,
          MetricStatus.pass,
          MetricStatus.pass,
          MetricStatus.pass,
          MetricStatus.pass,
          MetricStatus.pass,
          MetricStatus.pass,
        ],
        status: 'Complete',
        priority: 'Medium',
        assignedOperators: ['Alex Walker', 'Maria Johnson', 'David Chen'],
        createdDate: DateTime.now().subtract(const Duration(days: 21)),
        completedDate: DateTime.now().subtract(const Duration(days: 1)),
        estimatedCompletion: 100.0,
      ),
      JobDashboardData(
        id: '4',
        projectName: 'Methane Leak Detection Survey',
        facility: 'Fort Worth Plant',
        projectType: 'Environmental',
        dateRange: '1/25 - 2/15',
        hoursLogged: 48,
        totalHours: 192,
        systemMetrics: [
          MetricStatus.pass,
          MetricStatus.warning,
          MetricStatus.pass,
          MetricStatus.pass,
          MetricStatus.unknown,
          MetricStatus.unknown,
          MetricStatus.unknown,
        ],
        status: 'Active',
        priority: 'High',
        assignedOperators: ['Sarah Wilson'],
        createdDate: DateTime.now().subtract(const Duration(days: 5)),
        estimatedCompletion: 25.0,
      ),
      JobDashboardData(
        id: '5',
        projectName: 'Emergency Response Drill',
        facility: 'San Antonio Plant',
        projectType: 'Safety Training',
        dateRange: '2/1 - 2/1',
        hoursLogged: 8,
        totalHours: 8,
        systemMetrics: [
          MetricStatus.pass,
          MetricStatus.pass,
          MetricStatus.pass,
          MetricStatus.pass,
          MetricStatus.pass,
          MetricStatus.pass,
          MetricStatus.pass,
        ],
        status: 'Complete',
        priority: 'Medium',
        assignedOperators: ['Alex Walker', 'Maria Johnson', 'David Chen', 'Sarah Wilson'],
        createdDate: DateTime.now().subtract(const Duration(days: 3)),
        completedDate: DateTime.now(),
        estimatedCompletion: 100.0,
      ),
      JobDashboardData(
        id: '6',
        projectName: 'Thermal Imaging Inspection',
        facility: 'Houston Plant',
        projectType: 'Maintenance',
        dateRange: '2/5 - 2/20',
        hoursLogged: 16,
        totalHours: 120,
        systemMetrics: [
          MetricStatus.pass,
          MetricStatus.pass,
          MetricStatus.unknown,
          MetricStatus.unknown,
          MetricStatus.unknown,
          MetricStatus.unknown,
          MetricStatus.unknown,
        ],
        status: 'Active',
        priority: 'Low',
        assignedOperators: ['David Chen'],
        createdDate: DateTime.now().subtract(const Duration(days: 2)),
        estimatedCompletion: 13.3,
      ),
    ];
  }
}

class JobDashboardSummary {
  final int totalActiveJobs;
  final int totalCompletedJobs;
  final int pendingReviewCount;
  final int completedTodayCount;
  final double averageCompletionRate;
  final int newJobsThisWeek;

  const JobDashboardSummary({
    required this.totalActiveJobs,
    required this.totalCompletedJobs,
    required this.pendingReviewCount,
    required this.completedTodayCount,
    required this.averageCompletionRate,
    required this.newJobsThisWeek,
  });
}

class JobFilters {
  final String? status;
  final String? projectType;
  final String? operator;
  final String? facility;
  final String? priority;
  final DateTimeRange? dateRange;

  const JobFilters({
    this.status,
    this.projectType,
    this.operator,
    this.facility,
    this.priority,
    this.dateRange,
  });
}
