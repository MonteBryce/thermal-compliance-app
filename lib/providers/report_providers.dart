import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/dynamic_excel_export_service.dart';
import '../services/job_aware_excel_export_service.dart';
import '../services/excel_template_selection_service.dart';

/// Provider for the Excel report service
final dynamicExcelExportServiceProvider = Provider<DynamicExcelExportService>((ref) {
  return DynamicExcelExportService();
});

/// Provider for the template-based Excel report service
final jobAwareExcelExportServiceProvider = Provider<JobAwareExcelExportService>((ref) {
  return JobAwareExcelExportService();
});

/// Provider for the optimized template-based Excel report service
final excelTemplateSelectionServiceProvider = Provider<ExcelTemplateSelectionService>((ref) {
  return ExcelTemplateSelectionService();
});

/// State notifier for managing report generation
class ReportGenerationNotifier extends StateNotifier<ReportGenerationState> {
  ReportGenerationNotifier(this._dynamicService, this._jobAwareService, this._templateSelectionService) : super(const ReportGenerationState.idle());

  final DynamicExcelExportService _dynamicService;
  final JobAwareExcelExportService _jobAwareService;
  final ExcelTemplateSelectionService _templateSelectionService;

  /// Generate a full project report using dynamic templates
  Future<void> generateDynamicProjectReport({
    required String projectId,
    String? projectName,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = const ReportGenerationState.generating();
    
    try {
      print('🚀 Starting dynamic project report for $projectId');
      final reportData = await DynamicExcelExportService.generateDynamicReport(
        projectId: projectId,
        logType: projectName ?? 'thermal_log',
        entries: [],
        projectMetadata: {
          'name': projectName ?? 'Thermal Report',
          'startDate': startDate?.toIso8601String(),
          'endDate': endDate?.toIso8601String(),
        },
      );
      
      state = ReportGenerationState.completed(
        reportData: reportData,
        fileName: '${projectName ?? projectId}_dynamic_thermal_report.xlsx',
      );
      
      print('✅ Dynamic report generated successfully');
    } catch (error) {
      print('❌ Error generating dynamic report: $error');
      state = ReportGenerationState.error(error: error.toString());
    }
  }

  /// Generate a full project report (legacy method)
  Future<void> generateProjectReport({
    required String projectId,
    String? projectName,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // TODO: Update to use available service methods
    state = const ReportGenerationState.error(error: 'Legacy report method not implemented');
  }

  /// Generate a daily report
  Future<void> generateDailyReport({
    required String projectId,
    required String logId,
    DateTime? date,
  }) async {
    // TODO: Update to use available service methods
    state = const ReportGenerationState.error(error: 'Daily report method not implemented');
  }

  /// Generate a vapor combustor report using optimized template format
  Future<void> generateVaporReport({
    required String projectId,
    required DateTime date,
    String? projectName,
  }) async {
    // TODO: Update to use available service methods
    state = const ReportGenerationState.error(error: 'Vapor report method not implemented');
  }

  /// Generate multiple vapor reports for different dates (batch operation)
  Future<void> generateBatchVaporReports({
    required String projectId,
    required List<DateTime> dates,
    String? projectName,
  }) async {
    // TODO: Update to use available service methods
    state = const ReportGenerationState.error(error: 'Batch vapor report method not implemented');
  }

  /// Reset the state
  void reset() {
    state = const ReportGenerationState.idle();
  }
}

/// Provider for report generation state management
final reportGenerationProvider = StateNotifierProvider<ReportGenerationNotifier, ReportGenerationState>((ref) {
  final dynamicService = ref.read(dynamicExcelExportServiceProvider);
  final jobAwareService = ref.read(jobAwareExcelExportServiceProvider);
  final templateSelectionService = ref.read(excelTemplateSelectionServiceProvider);
  return ReportGenerationNotifier(dynamicService, jobAwareService, templateSelectionService);
});

/// State for report generation
sealed class ReportGenerationState {
  const ReportGenerationState();

  const factory ReportGenerationState.idle() = _Idle;
  const factory ReportGenerationState.generating() = _Generating;
  const factory ReportGenerationState.completed({
    required List<int> reportData,
    required String fileName,
  }) = _Completed;
  const factory ReportGenerationState.error({
    required String error,
  }) = _Error;

  bool get isIdle => this is _Idle;
  bool get isGenerating => this is _Generating;
  bool get isCompleted => this is _Completed;
  bool get isError => this is _Error;

  T when<T>({
    required T Function() idle,
    required T Function() generating,
    required T Function(List<int> reportData, String fileName) completed,
    required T Function(String error) onError,
  }) {
    return switch (this) {
      _Idle() => idle(),
      _Generating() => generating(),
      _Completed(:final reportData, :final fileName) => completed(reportData, fileName),
      _Error(:final error) => onError(error),
    };
  }
}

class _Idle extends ReportGenerationState {
  const _Idle();
}

class _Generating extends ReportGenerationState {
  const _Generating();
}

class _Completed extends ReportGenerationState {
  final List<int> reportData;
  final String fileName;

  const _Completed({required this.reportData, required this.fileName});
}

class _Error extends ReportGenerationState {
  final String error;

  const _Error({required this.error});
}

/// Extension methods for easier provider access
extension ReportProvidersX on WidgetRef {
  /// Generate a project report
  Future<void> generateProjectReport(String projectId, {String? projectName}) async {
    read(reportGenerationProvider.notifier).generateProjectReport(
      projectId: projectId,
      projectName: projectName,
    );
  }

  /// Generate a daily report
  Future<void> generateDailyReport(String projectId, String logId, {DateTime? date}) async {
    read(reportGenerationProvider.notifier).generateDailyReport(
      projectId: projectId,
      logId: logId,
      date: date,
    );
  }

  /// Generate a vapor combustor report
  Future<void> generateVaporReport(String projectId, DateTime date, {String? projectName}) async {
    read(reportGenerationProvider.notifier).generateVaporReport(
      projectId: projectId,
      date: date,
      projectName: projectName,
    );
  }

  /// Reset report generation state
  void resetReportGeneration() {
    read(reportGenerationProvider.notifier).reset();
  }
}