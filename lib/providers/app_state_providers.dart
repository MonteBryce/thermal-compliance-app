import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/job_data.dart';

/// Global state management for core app context
/// 
/// This file provides centralized state management for:
/// - Selected project/job
/// - Selected date for log entries
/// - Navigation context shared across screens

// =============================================================================
// SELECTED PROJECT STATE
// =============================================================================

/// State class for managing selected project information
class SelectedProjectState {
  final JobData? project;
  final DateTime? selectedDate;
  final String? currentLogId;
  final bool isLoading;
  final String? error;

  const SelectedProjectState({
    this.project,
    this.selectedDate,
    this.currentLogId,
    this.isLoading = false,
    this.error,
  });

  SelectedProjectState copyWith({
    JobData? project,
    DateTime? selectedDate,
    String? currentLogId,
    bool? isLoading,
    String? error,
  }) {
    return SelectedProjectState(
      project: project ?? this.project,
      selectedDate: selectedDate ?? this.selectedDate,
      currentLogId: currentLogId ?? this.currentLogId,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  /// Clear all selections
  SelectedProjectState clear() {
    return const SelectedProjectState();
  }

  /// Quick access properties
  bool get hasProject => project != null;
  bool get hasDate => selectedDate != null;
  bool get hasLogId => currentLogId != null && currentLogId!.isNotEmpty;
  
  String get projectDisplayName => project?.projectName ?? 'No Project';
  String get dateDisplayText => selectedDate != null 
      ? "${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}"
      : 'No Date';
}

/// StateNotifier for managing selected project and related context
class SelectedProjectNotifier extends StateNotifier<SelectedProjectState> {
  SelectedProjectNotifier() : super(const SelectedProjectState());

  /// Select a project and optionally set the date
  void selectProject(JobData project, [DateTime? date]) {
    state = state.copyWith(
      project: project,
      selectedDate: date ?? DateTime.now(),
      currentLogId: _generateLogId(project.projectNumber, date ?? DateTime.now()),
      error: null,
    );
  }

  /// Update the selected date for the current project
  void selectDate(DateTime date) {
    if (state.project == null) {
      state = state.copyWith(error: 'No project selected');
      return;
    }
    
    state = state.copyWith(
      selectedDate: date,
      currentLogId: _generateLogId(state.project!.projectNumber, date),
      error: null,
    );
  }

  /// Clear the current project selection
  void clearSelection() {
    state = const SelectedProjectState();
  }

  /// Set loading state
  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  /// Set error state
  void setError(String error) {
    state = state.copyWith(error: error, isLoading: false);
  }

  /// Generate a consistent log ID based on project and date
  String _generateLogId(String projectNumber, DateTime date) {
    final dateString = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    return "${projectNumber}_$dateString";
  }
}

// =============================================================================
// PROVIDERS
// =============================================================================

/// Main provider for selected project state
final selectedProjectProvider = StateNotifierProvider<SelectedProjectNotifier, SelectedProjectState>((ref) {
  return SelectedProjectNotifier();
});

/// Convenience providers for common access patterns
final currentProjectProvider = Provider<JobData?>((ref) {
  return ref.watch(selectedProjectProvider).project;
});

final currentDateProvider = Provider<DateTime?>((ref) {
  return ref.watch(selectedProjectProvider).selectedDate;
});

final currentLogIdProvider = Provider<String?>((ref) {
  return ref.watch(selectedProjectProvider).currentLogId;
});

/// Provider to check if we have complete selection
final hasCompleteSelectionProvider = Provider<bool>((ref) {
  final state = ref.watch(selectedProjectProvider);
  return state.hasProject && state.hasDate;
});

// =============================================================================
// NAVIGATION CONTEXT PROVIDERS
// =============================================================================

/// Provider for tracking current screen/step in the workflow
final workflowStepProvider = StateProvider<WorkflowStep>((ref) {
  return WorkflowStep.projectSelection;
});

/// Enum for tracking workflow steps
enum WorkflowStep {
  projectSelection,
  dailySummary,
  hourSelection,
  dataEntry,
  review;
  
  String get displayName {
    switch (this) {
      case WorkflowStep.projectSelection:
        return 'Select Project';
      case WorkflowStep.dailySummary:
        return 'Daily Summary';
      case WorkflowStep.hourSelection:
        return 'Select Hour';
      case WorkflowStep.dataEntry:
        return 'Data Entry';
      case WorkflowStep.review:
        return 'Review';
    }
  }
  
  bool get canGoBack {
    return this != WorkflowStep.projectSelection;
  }
  
  WorkflowStep? get previousStep {
    final values = WorkflowStep.values;
    final currentIndex = values.indexOf(this);
    if (currentIndex > 0) {
      return values[currentIndex - 1];
    }
    return null;
  }
  
  WorkflowStep? get nextStep {
    final values = WorkflowStep.values;
    final currentIndex = values.indexOf(this);
    if (currentIndex < values.length - 1) {
      return values[currentIndex + 1];
    }
    return null;
  }
}

// =============================================================================
// UTILITY PROVIDERS
// =============================================================================

/// Provider for checking navigation readiness
final navigationReadinessProvider = Provider<NavigationReadiness>((ref) {
  final projectState = ref.watch(selectedProjectProvider);
  final currentStep = ref.watch(workflowStepProvider);
  
  return NavigationReadiness(
    canNavigateToDaily: projectState.hasProject && projectState.hasDate,
    canNavigateToHours: projectState.hasProject && projectState.hasDate,
    canNavigateToEntry: projectState.hasProject && projectState.hasDate,
    currentStep: currentStep,
    contextComplete: projectState.hasProject && projectState.hasDate && projectState.hasLogId,
  );
});

/// Helper class for navigation readiness checks
class NavigationReadiness {
  final bool canNavigateToDaily;
  final bool canNavigateToHours;
  final bool canNavigateToEntry;
  final WorkflowStep currentStep;
  final bool contextComplete;

  const NavigationReadiness({
    required this.canNavigateToDaily,
    required this.canNavigateToHours,
    required this.canNavigateToEntry,
    required this.currentStep,
    required this.contextComplete,
  });
}

// =============================================================================
// HELPER EXTENSIONS
// =============================================================================

/// Extension to add state management helpers to Riverpod widgets
extension AppStateHelpers on WidgetRef {
  
  /// Quick access to current project
  JobData? get currentProject => read(currentProjectProvider);
  
  /// Quick access to current date
  DateTime? get currentDate => read(currentDateProvider);
  
  /// Quick access to current log ID
  String? get currentLogId => read(currentLogIdProvider);
  
  /// Check if we have complete context for navigation
  bool get hasCompleteContext => read(hasCompleteSelectionProvider);
  
  /// Update workflow step
  void setWorkflowStep(WorkflowStep step) {
    read(workflowStepProvider.notifier).state = step;
  }
  
  /// Navigate to next workflow step
  void goToNextWorkflowStep() {
    final current = read(workflowStepProvider);
    final next = current.nextStep;
    if (next != null) {
      read(workflowStepProvider.notifier).state = next;
    }
  }
  
  /// Navigate to previous workflow step
  void goToPreviousWorkflowStep() {
    final current = read(workflowStepProvider);
    final previous = current.previousStep;
    if (previous != null) {
      read(workflowStepProvider.notifier).state = previous;
    }
  }
}