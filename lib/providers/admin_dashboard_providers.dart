/// Providers for Admin Dashboard using Riverpod
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/admin_dashboard_models.dart';
import '../services/path_helper.dart';
import '../services/firestore_data_service.dart';

/// Provider for dashboard summary statistics
final dashboardSummaryProvider = StreamProvider<DashboardSummary>((ref) {
  return FirebaseFirestore.instance
      .collection('dashboard')
      .doc('summary')
      .snapshots()
      .map((snapshot) {
    if (snapshot.exists) {
      return DashboardSummary.fromFirestore(snapshot.data()!);
    }
    return DashboardSummary.empty;
  });
});

/// Provider for all admin jobs
final adminJobsProvider = StreamProvider<List<AdminJob>>((ref) {
  return FirebaseFirestore.instance
      .collection('projects')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      return AdminJob.fromFirestore(doc.id, doc.data());
    }).toList();
  });
});

/// Provider for job filters
final jobFiltersProvider = StateProvider<JobFilters>((ref) {
  return JobFilters.empty;
});

/// Provider for dark mode toggle
final darkModeProvider = StateProvider<bool>((ref) {
  return false;
});

/// Provider for filtered jobs based on current filters
final filteredJobsProvider = Provider<List<AdminJob>>((ref) {
  final jobs = ref.watch(adminJobsProvider).value ?? [];
  final filters = ref.watch(jobFiltersProvider);

  return jobs.where((job) {
    // Status filter
    if (filters.status != null && filters.status!.isNotEmpty) {
      if (job.status.value != filters.status) return false;
    }

    // Log type filter
    if (filters.logType != null && filters.logType!.isNotEmpty) {
      if (job.logType != filters.logType) return false;
    }

    // Operator filter
    if (filters.operator != null && filters.operator!.isNotEmpty) {
      if (!job.assignedOperator.toLowerCase().contains(filters.operator!.toLowerCase())) {
        return false;
      }
    }

    // Date range filter
    if (filters.dateRange != null) {
      final range = filters.dateRange!;
      if (job.startDate.isBefore(range.start) || job.startDate.isAfter(range.end)) {
        return false;
      }
    }

    return true;
  }).toList();
});

/// Provider for dashboard state
final adminDashboardStateProvider = Provider<AdminDashboardState>((ref) {
  final jobs = ref.watch(adminJobsProvider).value ?? [];
  final filteredJobs = ref.watch(filteredJobsProvider);
  final summary = ref.watch(dashboardSummaryProvider).value ?? DashboardSummary.empty;
  final filters = ref.watch(jobFiltersProvider);
  final isDarkMode = ref.watch(darkModeProvider);
  final isLoading = ref.watch(adminJobsProvider).isLoading;
  final error = ref.watch(adminJobsProvider).error?.toString();

  return AdminDashboardState(
    jobs: jobs,
    filteredJobs: filteredJobs,
    summary: summary,
    filters: filters,
    isDarkMode: isDarkMode,
    isLoading: isLoading,
    error: error,
  );
});

/// Provider for available log types (for filter dropdown)
final availableLogTypesProvider = Provider<List<String>>((ref) {
  final jobs = ref.watch(adminJobsProvider).value ?? [];
  final logTypes = jobs.map((job) => job.logType).toSet().toList();
  logTypes.sort();
  return logTypes;
});

/// Provider for available operators (for filter dropdown)
final availableOperatorsProvider = Provider<List<String>>((ref) {
  final jobs = ref.watch(adminJobsProvider).value ?? [];
  final operators = jobs.map((job) => job.assignedOperator).toSet().toList();
  operators.sort();
  return operators;
});

/// Provider for job statistics
final jobStatisticsProvider = Provider<Map<String, int>>((ref) {
  final jobs = ref.watch(adminJobsProvider).value ?? [];
  
  final stats = <String, int>{
    'total': jobs.length,
    'active': 0,
    'completed': 0,
    'archived': 0,
    'paused': 0,
    'overdue': 0,
  };

  for (final job in jobs) {
    stats[job.status.value] = (stats[job.status.value] ?? 0) + 1;
    if (job.isOverdue) {
      stats['overdue'] = (stats['overdue'] ?? 0) + 1;
    }
  }

  return stats;
});

/// Action provider for updating job filters
final jobFiltersNotifierProvider = NotifierProvider<JobFiltersNotifier, JobFilters>(() {
  return JobFiltersNotifier();
});

class JobFiltersNotifier extends Notifier<JobFilters> {
  @override
  JobFilters build() {
    return JobFilters.empty;
  }

  void updateStatus(String? status) {
    state = state.copyWith(status: status);
  }

  void updateLogType(String? logType) {
    state = state.copyWith(logType: logType);
  }

  void updateOperator(String? operator) {
    state = state.copyWith(operator: operator);
  }

  void updateDateRange(DateTimeRange? dateRange) {
    state = state.copyWith(dateRange: dateRange);
  }

  void clearFilters() {
    state = JobFilters.empty;
  }
}
