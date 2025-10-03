import 'dart:typed_data';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:intl/intl.dart';
import '../models/firestore_models.dart';
import '../services/firestore_data_service.dart';
import 'demo_data_service.dart';
import 'log_template_service.dart';
import 'dynamic_excel_export_service.dart';

/// Service for generating Excel reports from thermal logging data using Syncfusion
class ExcelReportService {
  final FirestoreDataService _firestoreService = FirestoreDataService();

  /// Generate a dynamic Excel report using log templates
  Future<Uint8List> generateDynamicProjectReport({
    required String projectId,
    String? projectName,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    print('🔄 Starting dynamic project report generation...');
    
    // Determine log type based on project
    final logType = LogTemplateService.getLogTypeForProject(projectId);
    print('📋 Using log type: ${logType.displayName} for project $projectId');
    
    // Get project data
    final ProjectDocument? project;
    final List<LogDocument> logs;
    final Map<String, List<LogEntryDocument>> allEntries = {};
    
    if (DemoDataService.isDemoProject(projectId)) {
      project = DemoDataService.getDemoProject();
      logs = DemoDataService.getDemoLogDocuments();
      
      // Get entries for each log
      for (final log in logs) {
        allEntries[log.logId] = DemoDataService.getDemoLogEntries(log.logId, log.completedHours);
      }
    } else {
      // Handle real project data
      logs = await _firestoreService.getProjectLogs(projectId);
      project = ProjectDocument(
        projectId: projectId,
        projectName: projectName ?? projectId,
        projectNumber: projectId,
        location: 'Unknown',
        unitNumber: 'Unknown',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'system',
      );
      
      // Get entries for each log
      for (final log in logs) {
        final entries = await _firestoreService.getLogEntries(projectId, log.logId);
        allEntries[log.logId] = entries;
      }
    }
    
    // Flatten all entries for dynamic export
    final List<Map<String, dynamic>> flatEntries = [];
    for (final logEntries in allEntries.values) {
      for (final entry in logEntries) {
        // Convert LogEntryDocument to Map with all readings
        final entryMap = {
          'hour': entry.hour,
          'timestamp': entry.timestamp.toIso8601String(),
          'date': DateFormat('yyyy-MM-dd').format(entry.timestamp),
          'operatorId': entry.operatorId,
          'validated': entry.validated,
          'observations': entry.observations,
          // Add all readings
          ...entry.readings,
        };
        flatEntries.add(entryMap);
      }
    }
    
    print('📊 Processing ${flatEntries.length} entries with ${logType.id} template');
    
    // Generate dynamic report using template
    final reportBytes = await DynamicExcelExportService.generateDynamicReport(
      projectId: projectId,
      logType: logType.id,
      entries: flatEntries,
      projectMetadata: {
        'projectName': project?.projectName ?? 'Unknown Project',
        'projectNumber': project?.projectNumber ?? projectId,
        'location': project?.location ?? 'Unknown',
        'unitNumber': project?.unitNumber ?? 'Unknown',
        'totalEntries': flatEntries.length,
        'dateRange': _getDateRange(flatEntries),
      },
    );
    
    print('✅ Dynamic report generated successfully');
    return Uint8List.fromList(reportBytes);
  }
  
  /// Get date range from entries
  String _getDateRange(List<Map<String, dynamic>> entries) {
    if (entries.isEmpty) return 'No data';
    
    final dates = entries
        .map((e) => DateTime.parse(e['timestamp']))
        .toList()
      ..sort();
    
    final startDate = dates.first;
    final endDate = dates.last;
    
    if (startDate.difference(endDate).inDays == 0) {
      return DateFormat('MMM dd, yyyy').format(startDate);
    } else {
      return '${DateFormat('MMM dd').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}';
    }
  }

  /// Generate a comprehensive Excel report for a project
  Future<Uint8List> generateProjectReport({
    required String projectId,
    String? projectName,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Create a new Excel document
    final Workbook workbook = Workbook();
    
    // Get project data
    final ProjectDocument? project;
    final List<LogDocument> logs;
    final Map<String, List<LogEntryDocument>> allEntries = {};
    
    if (DemoDataService.isDemoProject(projectId)) {
      project = DemoDataService.getDemoProject();
      logs = DemoDataService.getDemoLogDocuments();
      
      // Get entries for each log
      for (final log in logs) {
        allEntries[log.logId] = DemoDataService.getDemoLogEntries(log.logId, log.completedHours);
      }
    } else {
      // Handle real project data
      logs = await _firestoreService.getProjectLogs(projectId);
      project = ProjectDocument(
        projectId: projectId,
        projectName: projectName ?? projectId,
        projectNumber: projectId,
        location: 'Unknown',
        unitNumber: 'Unknown',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'system',
      );
      
      // Get entries for each log
      for (final log in logs) {
        allEntries[log.logId] = await _firestoreService.getLogEntries(projectId, log.logId);
      }
    }

    // Remove default sheet by removing all worksheets and add our custom sheets
    // Note: Skip this for now as API has changed, use default sheet
    
    // Create sheets
    _createProjectSummarySheet(workbook, project, logs);
    _createDailyLogsSheet(workbook, logs, allEntries);
    _createHourlyDataSheet(workbook, logs, allEntries);
    _createAnalyticsSheet(workbook, logs, allEntries);
    
    // Save and return
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();
    
    return Uint8List.fromList(bytes);
  }

  /// Create project summary sheet
  void _createProjectSummarySheet(
    Workbook workbook,
    ProjectDocument project,
    List<LogDocument> logs,
  ) {
    final Worksheet sheet = workbook.worksheets.addWithName('Project Summary');
    
    // Title
    sheet.getRangeByIndex(1, 1).setText('THERMAL LOGGING PROJECT REPORT');
    sheet.getRangeByIndex(1, 1).cellStyle.backColor = '#1E40AF';
    sheet.getRangeByIndex(1, 1).cellStyle.fontColor = '#FFFFFF';
    sheet.getRangeByIndex(1, 1).cellStyle.bold = true;
    sheet.getRangeByIndex(1, 1).cellStyle.fontSize = 16;
    sheet.getRangeByName('A1:F1').merge();

    // Project Information
    int row = 3;
    sheet.getRangeByIndex(row, 1).setText('PROJECT INFORMATION');
    sheet.getRangeByIndex(row, 1).cellStyle.backColor = '#3B82F6';
    sheet.getRangeByIndex(row, 1).cellStyle.fontColor = '#FFFFFF';
    sheet.getRangeByIndex(row, 1).cellStyle.bold = true;
    sheet.getRangeByName('A$row:F$row').merge();
    
    row++;
    _addProjectInfoRow(sheet, row++, 'Project Name:', project.projectName);
    _addProjectInfoRow(sheet, row++, 'Project Number:', project.projectNumber);
    _addProjectInfoRow(sheet, row++, 'Location:', project.location);
    _addProjectInfoRow(sheet, row++, 'Unit Number:', project.unitNumber);
    _addProjectInfoRow(sheet, row++, 'Work Order:', project.workOrderNumber);
    _addProjectInfoRow(sheet, row++, 'Tank Type:', project.tankType);
    _addProjectInfoRow(sheet, row++, 'Product:', project.product);
    _addProjectInfoRow(sheet, row++, 'Operating Temperature:', project.operatingTemperature);
    _addProjectInfoRow(sheet, row++, 'Facility Target:', project.facilityTarget);
    _addProjectInfoRow(sheet, row++, 'Benzene Target:', project.benzeneTarget);
    _addProjectInfoRow(sheet, row++, 'H2S Amp Required:', project.h2sAmpRequired ? 'Yes' : 'No');
    
    if (project.projectStartDate != null) {
      _addProjectInfoRow(sheet, row++, 'Start Date:', DateFormat('MMM dd, yyyy').format(project.projectStartDate!));
    }
    
    row += 2;
    
    // Project Statistics
    sheet.getRangeByIndex(row, 1).setText('PROJECT STATISTICS');
    sheet.getRangeByIndex(row, 1).cellStyle.backColor = '#3B82F6';
    sheet.getRangeByIndex(row, 1).cellStyle.fontColor = '#FFFFFF';
    sheet.getRangeByIndex(row, 1).cellStyle.bold = true;
    sheet.getRangeByName('A$row:F$row').merge();
    
    row++;
    final totalDays = logs.length;
    final completedDays = logs.where((log) => log.completionStatus == LogCompletionStatus.complete).length;
    final totalHours = logs.fold<int>(0, (sum, log) => sum + log.completedHours);
    final validatedHours = logs.fold<int>(0, (sum, log) => sum + log.validatedHours);
    
    _addProjectInfoRow(sheet, row++, 'Total Logging Days:', totalDays.toString());
    _addProjectInfoRow(sheet, row++, 'Completed Days:', completedDays.toString());
    _addProjectInfoRow(sheet, row++, 'Total Hours Logged:', totalHours.toString());
    _addProjectInfoRow(sheet, row++, 'Validated Hours:', validatedHours.toString());
    _addProjectInfoRow(sheet, row++, 'Completion Percentage:', '${((completedDays / totalDays) * 100).toStringAsFixed(1)}%');
    _addProjectInfoRow(sheet, row++, 'Validation Percentage:', '${totalHours > 0 ? ((validatedHours / totalHours) * 100).toStringAsFixed(1) : '0'}%');
    
    // Report Generation Info
    row += 2;
    sheet.getRangeByIndex(row, 1).setText('REPORT INFORMATION');
    sheet.getRangeByIndex(row, 1).cellStyle.backColor = '#3B82F6';
    sheet.getRangeByIndex(row, 1).cellStyle.fontColor = '#FFFFFF';
    sheet.getRangeByIndex(row, 1).cellStyle.bold = true;
    sheet.getRangeByName('A$row:F$row').merge();
    
    row++;
    _addProjectInfoRow(sheet, row++, 'Generated On:', DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now()));
    _addProjectInfoRow(sheet, row++, 'Generated By:', 'Thermal Log App');
    if (DemoDataService.isDemoProject(project.projectId)) {
      _addProjectInfoRow(sheet, row++, 'Data Type:', 'Demo Data');
    }

    // Auto-fit columns
    sheet.autoFitColumn(1);
    sheet.autoFitColumn(2);
  }

  void _addProjectInfoRow(Worksheet sheet, int row, String label, String value) {
    sheet.getRangeByIndex(row, 1).setText(label);
    sheet.getRangeByIndex(row, 1).cellStyle.bold = true;
    sheet.getRangeByIndex(row, 2).setText(value);
  }

  /// Create daily logs overview sheet
  void _createDailyLogsSheet(
    Workbook workbook,
    List<LogDocument> logs,
    Map<String, List<LogEntryDocument>> allEntries,
  ) {
    final Worksheet sheet = workbook.worksheets.addWithName('Daily Logs');

    // Headers
    final headers = [
      'Date',
      'Day of Week',
      'Status',
      'Total Entries',
      'Completed Hours',
      'Validated Hours',
      'Completion %',
      'First Entry',
      'Last Entry',
      'Notes',
    ];
    
    for (int i = 0; i < headers.length; i++) {
      sheet.getRangeByIndex(1, i + 1).setText(headers[i]);
      sheet.getRangeByIndex(1, i + 1).cellStyle.backColor = '#3B82F6';
      sheet.getRangeByIndex(1, i + 1).cellStyle.fontColor = '#FFFFFF';
      sheet.getRangeByIndex(1, i + 1).cellStyle.bold = true;
    }

    // Data rows
    logs.sort((a, b) => a.date.compareTo(b.date));
    
    for (int i = 0; i < logs.length; i++) {
      final log = logs[i];
      final row = i + 2;
      
      sheet.getRangeByIndex(row, 1).setText(DateFormat('MMM dd, yyyy').format(log.date));
      sheet.getRangeByIndex(row, 2).setText(DateFormat('EEEE').format(log.date));
      sheet.getRangeByIndex(row, 3).setText(log.completionStatus.displayName);
      sheet.getRangeByIndex(row, 4).setNumber(log.totalEntries.toDouble());
      sheet.getRangeByIndex(row, 5).setNumber(log.completedHours.toDouble());
      sheet.getRangeByIndex(row, 6).setNumber(log.validatedHours.toDouble());
      sheet.getRangeByIndex(row, 7).setText('${(log.completionPercentage * 100).toStringAsFixed(1)}%');
      
      if (log.firstEntryAt != null) {
        sheet.getRangeByIndex(row, 8).setText(DateFormat('HH:mm').format(log.firstEntryAt!));
      }
      
      if (log.lastEntryAt != null) {
        sheet.getRangeByIndex(row, 9).setText(DateFormat('HH:mm').format(log.lastEntryAt!));
      }
      
      sheet.getRangeByIndex(row, 10).setText(log.notes);
      
      // Color-code status
      switch (log.completionStatus) {
        case LogCompletionStatus.complete:
          sheet.getRangeByIndex(row, 3).cellStyle.backColor = '#D1FAE5';
          break;
        case LogCompletionStatus.incomplete:
          sheet.getRangeByIndex(row, 3).cellStyle.backColor = '#FEF3C7';
          break;
        case LogCompletionStatus.notStarted:
          sheet.getRangeByIndex(row, 3).cellStyle.backColor = '#F3F4F6';
          break;
        case LogCompletionStatus.validated:
          sheet.getRangeByIndex(row, 3).cellStyle.backColor = '#10B981';
          sheet.getRangeByIndex(row, 3).cellStyle.fontColor = '#FFFFFF';
          break;
      }
    }

    // Auto-fit columns
    for (int i = 1; i <= headers.length; i++) {
      sheet.autoFitColumn(i);
    }
  }

  /// Create detailed hourly data sheet
  void _createHourlyDataSheet(
    Workbook workbook,
    List<LogDocument> logs,
    Map<String, List<LogEntryDocument>> allEntries,
  ) {
    final Worksheet sheet = workbook.worksheets.addWithName('Hourly Data');

    // Headers
    final headers = [
      'Date',
      'Hour',
      'Time',
      'Inlet Reading (PPM)',
      'Outlet Reading (PPM)',
      'H2S Reading (PPM)',
      'Flow Rate FPM',
      'Flow Rate BBL',
      'Tank Refill Rate',
      'Combustion Air Flow',
      'Vacuum Outlet',
      'Exhaust Temp (°F)',
      'Totalizer',
      'Operator',
      'Validated',
      'Observations',
    ];
    
    for (int i = 0; i < headers.length; i++) {
      sheet.getRangeByIndex(1, i + 1).setText(headers[i]);
      sheet.getRangeByIndex(1, i + 1).cellStyle.backColor = '#3B82F6';
      sheet.getRangeByIndex(1, i + 1).cellStyle.fontColor = '#FFFFFF';
      sheet.getRangeByIndex(1, i + 1).cellStyle.bold = true;
    }

    // Data rows
    int dataRow = 2;
    logs.sort((a, b) => a.date.compareTo(b.date));
    
    for (final log in logs) {
      final entries = allEntries[log.logId] ?? [];
      entries.sort((a, b) => a.hour.compareTo(b.hour));
      
      for (final entry in entries) {
        sheet.getRangeByIndex(dataRow, 1).setText(DateFormat('MMM dd, yyyy').format(log.date));
        sheet.getRangeByIndex(dataRow, 2).setNumber(entry.hour.toDouble());
        sheet.getRangeByIndex(dataRow, 3).setText('${entry.hour.toString().padLeft(2, '0')}:00');
        
        // Thermal readings
        _setCellValue(sheet, dataRow, 4, entry.readings['inletReading']);
        _setCellValue(sheet, dataRow, 5, entry.readings['outletReading']);
        _setCellValue(sheet, dataRow, 6, entry.readings['toInletReadingH2S']);
        _setCellValue(sheet, dataRow, 7, entry.readings['vaporInletFlowRateFPM']);
        _setCellValue(sheet, dataRow, 8, entry.readings['vaporInletFlowRateBBL']);
        _setCellValue(sheet, dataRow, 9, entry.readings['tankRefillFlowRate']);
        _setCellValue(sheet, dataRow, 10, entry.readings['combustionAirFlowRate']);
        _setCellValue(sheet, dataRow, 11, entry.readings['vacuumAtTankVaporOutlet']);
        _setCellValue(sheet, dataRow, 12, entry.readings['exhaustTemperature']);
        _setCellValue(sheet, dataRow, 13, entry.readings['totalizer']);
        
        sheet.getRangeByIndex(dataRow, 14).setText(entry.operatorId);
        sheet.getRangeByIndex(dataRow, 15).setText(entry.validated ? 'Yes' : 'No');
        sheet.getRangeByIndex(dataRow, 16).setText(entry.observations);
        
        // Color-code validation status
        if (entry.validated) {
          sheet.getRangeByIndex(dataRow, 15).cellStyle.backColor = '#D1FAE5';
        }
        
        dataRow++;
      }
    }

    // Auto-fit columns
    for (int i = 1; i <= headers.length; i++) {
      sheet.autoFitColumn(i);
    }
  }

  void _setCellValue(Worksheet sheet, int row, int col, dynamic value) {
    if (value != null) {
      if (value is String) {
        final numValue = double.tryParse(value);
        if (numValue != null) {
          sheet.getRangeByIndex(row, col).setNumber(numValue);
        } else {
          sheet.getRangeByIndex(row, col).setText(value);
        }
      } else if (value is num) {
        sheet.getRangeByIndex(row, col).setNumber(value.toDouble());
      } else {
        sheet.getRangeByIndex(row, col).setText(value.toString());
      }
    }
  }

  /// Create analytics and summary sheet
  void _createAnalyticsSheet(
    Workbook workbook,
    List<LogDocument> logs,
    Map<String, List<LogEntryDocument>> allEntries,
  ) {
    final Worksheet sheet = workbook.worksheets.addWithName('Analytics');

    // Title
    sheet.getRangeByIndex(1, 1).setText('PROJECT ANALYTICS & STATISTICS');
    sheet.getRangeByIndex(1, 1).cellStyle.backColor = '#1E40AF';
    sheet.getRangeByIndex(1, 1).cellStyle.fontColor = '#FFFFFF';
    sheet.getRangeByIndex(1, 1).cellStyle.bold = true;
    sheet.getRangeByIndex(1, 1).cellStyle.fontSize = 16;
    sheet.getRangeByName('A1:F1').merge();

    int row = 3;
    
    // Data Quality Statistics
    sheet.getRangeByIndex(row, 1).setText('DATA QUALITY STATISTICS');
    sheet.getRangeByIndex(row, 1).cellStyle.backColor = '#3B82F6';
    sheet.getRangeByIndex(row, 1).cellStyle.fontColor = '#FFFFFF';
    sheet.getRangeByIndex(row, 1).cellStyle.bold = true;
    sheet.getRangeByName('A$row:F$row').merge();
    
    row++;
    final allLogEntries = allEntries.values.expand((entries) => entries).toList();
    final totalEntries = allLogEntries.length;
    final validatedEntries = allLogEntries.where((entry) => entry.validated).length;
    final entriesWithObservations = allLogEntries.where((entry) => entry.observations.isNotEmpty).length;
    
    _addProjectInfoRow(sheet, row++, 'Total Data Points:', totalEntries.toString());
    _addProjectInfoRow(sheet, row++, 'Validated Entries:', validatedEntries.toString());
    _addProjectInfoRow(sheet, row++, 'Entries with Observations:', entriesWithObservations.toString());
    _addProjectInfoRow(sheet, row++, 'Data Validation Rate:', '${totalEntries > 0 ? ((validatedEntries / totalEntries) * 100).toStringAsFixed(1) : '0'}%');
    
    row += 2;
    
    // Operational Statistics
    sheet.getRangeByIndex(row, 1).setText('OPERATIONAL STATISTICS');
    sheet.getRangeByIndex(row, 1).cellStyle.backColor = '#3B82F6';
    sheet.getRangeByIndex(row, 1).cellStyle.fontColor = '#FFFFFF';
    sheet.getRangeByIndex(row, 1).cellStyle.bold = true;
    sheet.getRangeByName('A$row:F$row').merge();
    
    row++;
    
    // Calculate averages
    final entriesWithInletReadings = allLogEntries.where((entry) => 
      entry.readings['inletReading'] != null && 
      double.tryParse(entry.readings['inletReading'].toString()) != null).toList();
    
    final entriesWithExhaustTemp = allLogEntries.where((entry) => 
      entry.readings['exhaustTemperature'] != null && 
      double.tryParse(entry.readings['exhaustTemperature'].toString()) != null).toList();
    
    if (entriesWithInletReadings.isNotEmpty) {
      final avgInletReading = entriesWithInletReadings
          .map((entry) => double.parse(entry.readings['inletReading'].toString()))
          .reduce((a, b) => a + b) / entriesWithInletReadings.length;
      _addProjectInfoRow(sheet, row++, 'Average Inlet Reading:', '${avgInletReading.toStringAsFixed(1)} PPM');
    }
    
    if (entriesWithExhaustTemp.isNotEmpty) {
      final avgExhaustTemp = entriesWithExhaustTemp
          .map((entry) => double.parse(entry.readings['exhaustTemperature'].toString()))
          .reduce((a, b) => a + b) / entriesWithExhaustTemp.length;
      _addProjectInfoRow(sheet, row++, 'Average Exhaust Temperature:', '${avgExhaustTemp.toStringAsFixed(0)}°F');
    }
    
    // Operator Statistics
    row += 2;
    sheet.getRangeByIndex(row, 1).setText('OPERATOR STATISTICS');
    sheet.getRangeByIndex(row, 1).cellStyle.backColor = '#3B82F6';
    sheet.getRangeByIndex(row, 1).cellStyle.fontColor = '#FFFFFF';
    sheet.getRangeByIndex(row, 1).cellStyle.bold = true;
    sheet.getRangeByName('A$row:F$row').merge();
    
    row++;
    final operatorStats = <String, int>{};
    for (final entry in allLogEntries) {
      operatorStats[entry.operatorId] = (operatorStats[entry.operatorId] ?? 0) + 1;
    }
    
    for (final operator in operatorStats.keys) {
      _addProjectInfoRow(sheet, row++, operator, '${operatorStats[operator]} entries');
    }

    // Auto-fit columns
    sheet.autoFitColumn(1);
    sheet.autoFitColumn(2);
  }

  /// Generate a quick summary report for a specific date
  Future<Uint8List> generateDailyReport({
    required String projectId,
    required String logId,
    DateTime? date,
  }) async {
    final Workbook workbook = Workbook();
    
    // Get data
    final logDoc = await _firestoreService.getLogDocument(projectId, logId);
    final entries = await _firestoreService.getLogEntries(projectId, logId);
    
    if (logDoc == null) {
      throw Exception('Log document not found');
    }
    
    // Remove default sheet and create our custom sheet
    // Note: Skip this for now as API has changed, use default sheet
    final Worksheet sheet = workbook.worksheets.addWithName('Daily Report');
    
    // Title
    sheet.getRangeByIndex(1, 1).setText('DAILY THERMAL LOG REPORT');
    sheet.getRangeByIndex(1, 1).cellStyle.backColor = '#3B82F6';
    sheet.getRangeByIndex(1, 1).cellStyle.fontColor = '#FFFFFF';
    sheet.getRangeByIndex(1, 1).cellStyle.bold = true;
    sheet.getRangeByName('A1:D1').merge();
    
    // Date info
    sheet.getRangeByIndex(3, 1).setText('Date: ${logDoc.formattedDate}');
    sheet.getRangeByIndex(4, 1).setText('Status: ${logDoc.completionStatus.displayName}');
    sheet.getRangeByIndex(5, 1).setText('Completed Hours: ${logDoc.completedHours}/24');
    
    // Headers for hourly data
    int row = 7;
    final headers = ['Hour', 'Inlet PPM', 'Outlet PPM', 'Exhaust Temp', 'Notes'];
    for (int i = 0; i < headers.length; i++) {
      sheet.getRangeByIndex(row, i + 1).setText(headers[i]);
      sheet.getRangeByIndex(row, i + 1).cellStyle.backColor = '#3B82F6';
      sheet.getRangeByIndex(row, i + 1).cellStyle.fontColor = '#FFFFFF';
      sheet.getRangeByIndex(row, i + 1).cellStyle.bold = true;
    }
    
    // Data
    entries.sort((a, b) => a.hour.compareTo(b.hour));
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final dataRow = row + 1 + i;
      
      sheet.getRangeByIndex(dataRow, 1).setNumber(entry.hour.toDouble());
      _setCellValue(sheet, dataRow, 2, entry.readings['inletReading']);
      _setCellValue(sheet, dataRow, 3, entry.readings['outletReading']);
      _setCellValue(sheet, dataRow, 4, entry.readings['exhaustTemperature']);
      sheet.getRangeByIndex(dataRow, 5).setText(entry.observations);
    }
    
    // Auto-fit columns
    for (int i = 1; i <= headers.length; i++) {
      sheet.autoFitColumn(i);
    }
    
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();
    
    return Uint8List.fromList(bytes);
  }
}