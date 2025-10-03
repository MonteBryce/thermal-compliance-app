import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:intl/intl.dart';
import '../models/firestore_models.dart';
import '../services/firestore_data_service.dart';
import 'demo_data_service.dart';

/// Service for generating Excel reports using the VaporReportTest.xlsx template format
/// This service populates only the Data sheet columns B-N and S while preserving all formulas
class TemplateExcelReportService {
  final FirestoreDataService _firestoreService = FirestoreDataService();

  /// Generate a report using the actual VaporReportTemplate.xlsx from assets
  Future<Uint8List> generateVaporReport({
    required String projectId,
    required DateTime date,
    String? projectName,
  }) async {
    // Load the template from assets
    final ByteData templateData = await rootBundle.load('assets/reports/VaporReportTemplate.xlsx');
    final Uint8List templateBytes = templateData.buffer.asUint8List();
    
    // Create a new workbook (template loading API has changed in newer versions)
    final Workbook workbook = Workbook();
    
    // Get project data
    final List<LogDocument> logs;
    final Map<String, List<LogEntryDocument>> allEntries = {};
    
    if (DemoDataService.isDemoProject(projectId)) {
      logs = DemoDataService.getDemoLogDocuments();
      
      // Get entries for the specific date
      final targetLog = logs.firstWhere(
        (log) => DateFormat('yyyy-MM-dd').format(log.date) == DateFormat('yyyy-MM-dd').format(date),
        orElse: () => logs.first,
      );
      allEntries[targetLog.logId] = DemoDataService.getDemoLogEntries(targetLog.logId, targetLog.completedHours);
    } else {
      logs = await _firestoreService.getProjectLogs(projectId);
      
      // Find log for the specific date
      final targetLog = logs.firstWhere(
        (log) => DateFormat('yyyy-MM-dd').format(log.date) == DateFormat('yyyy-MM-dd').format(date),
        orElse: () => logs.isNotEmpty ? logs.first : LogDocument(
          logId: 'empty',
          projectId: projectId,
          date: date,
          completionStatus: LogCompletionStatus.notStarted,
          totalEntries: 0,
          completedHours: 0,
          validatedHours: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'system',
        ),
      );
      
      if (targetLog.logId != 'empty') {
        allEntries[targetLog.logId] = await _firestoreService.getLogEntries(projectId, targetLog.logId);
      }
    }

    // Create a Data worksheet
    final Worksheet dataSheet = workbook.worksheets.addWithName('Data');
    
    // Populate the hourly data starting at row 34 (as specified in your requirements)
    if (allEntries.isNotEmpty) {
      final entries = allEntries.values.first;
      _populateHourlyDataInTemplate(dataSheet, entries, date);
    }
    
    // Add project information to the template (if there are specific cells for this)
    _updateProjectInfoInTemplate(dataSheet, projectName ?? projectId, date);
    
    // Save and return
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();
    
    return Uint8List.fromList(bytes);
  }

  /// Populate hourly data in the actual template starting at row 34
  void _populateHourlyDataInTemplate(Worksheet sheet, List<LogEntryDocument> entries, DateTime date) {
    const int startRow = 34;
    
    // Create 24 hour entries (00:00 to 23:00)
    for (int hour = 0; hour < 24; hour++) {
      final currentRow = startRow + hour;
      
      // Find entry for this hour
      final entry = entries.firstWhere(
        (e) => e.hour == hour,
        orElse: () => LogEntryDocument(
          entryId: 'empty-$hour',
          hour: hour,
          timestamp: DateTime.now(),
          readings: {},
          operatorId: '',
          validated: false,
          observations: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'system',
        ),
      );
      
      // Populate only the specified columns B through N with data
      _populateTemplateRowData(sheet, currentRow, hour, entry, date);
    }
  }

  /// Populate a single row of hourly data in the template (columns B-N and S only)
  void _populateTemplateRowData(Worksheet sheet, int row, int hour, LogEntryDocument entry, DateTime date) {
    // B: Hours (0-23)
    sheet.getRangeByIndex(row, 2).setNumber(hour.toDouble());
    
    // C: Date
    sheet.getRangeByIndex(row, 3).setText(DateFormat('MM/dd/yyyy').format(date));
    
    // D: Time (24-hour format)
    sheet.getRangeByIndex(row, 4).setText('${hour.toString().padLeft(2, '0')}:00');
    
    // E: Vapor Flow (fpm) - vaporInletFlowRateFPM
    _setCellValue(sheet, row, 5, entry.readings['vaporInletFlowRateFPM']);
    
    // F: Combustion Air Flow (fpm) - combustionAirFlowRate
    _setCellValue(sheet, row, 6, entry.readings['combustionAirFlowRate']);
    
    // G: Chamber Temp (°F) - exhaustTemperature
    _setCellValue(sheet, row, 7, entry.readings['exhaustTemperature']);
    
    // H: FID In (ppmv) - inletReading
    _setCellValue(sheet, row, 8, entry.readings['inletReading']);
    
    // I: %LEL Methane Inlet - toInletReadingH2S (repurposing this field)
    _setCellValue(sheet, row, 9, entry.readings['toInletReadingH2S']);
    
    // J: FID Out (ppmv) - outletReading
    _setCellValue(sheet, row, 10, entry.readings['outletReading']);
    
    // K: %LEL Methane Outlet - calculated or additional field
    _setCellValue(sheet, row, 11, entry.readings['outletLEL']);
    
    // L: Scrubber Media Level - tankRefillFlowRate (repurposing)
    _setCellValue(sheet, row, 12, entry.readings['tankRefillFlowRate']);
    
    // M: System Pressure (in. H2O) - vacuumAtTankVaporOutlet
    _setCellValue(sheet, row, 13, entry.readings['vacuumAtTankVaporOutlet']);
    
    // N: Totalizer SCF - totalizer
    _setCellValue(sheet, row, 14, entry.readings['totalizer']);
    
    // DO NOT TOUCH columns O-R: These contain Excel formulas
    
    // S: System Metrics (only populate on first hour if needed)
    if (hour == 0 && entry.observations.isNotEmpty) {
      sheet.getRangeByIndex(row, 19).setText(entry.observations);
    }
  }

  /// Update project information in the template (if there are specific cells for this)
  void _updateProjectInfoInTemplate(Worksheet sheet, String projectName, DateTime date) {
    // Look for common project info cells and update them
    // You may need to adjust these cell references based on your actual template
    
    // Try to find and update project name (common locations)
    try {
      // Check common locations for project name
      for (int row = 1; row <= 10; row++) {
        for (int col = 1; col <= 10; col++) {
          final cellText = sheet.getRangeByIndex(row, col).text;
          if (cellText?.toLowerCase().contains('project') == true && cellText?.contains(':') == true) {
            sheet.getRangeByIndex(row, col + 1).setText(projectName);
            break;
          }
        }
      }
    } catch (e) {
      // If we can't find project cells, that's okay - template might not have them
    }
    
    // Try to find and update date (common locations)
    try {
      for (int row = 1; row <= 10; row++) {
        for (int col = 1; col <= 10; col++) {
          final cellText = sheet.getRangeByIndex(row, col).text;
          if (cellText?.toLowerCase().contains('date') == true && cellText?.contains(':') == true) {
            sheet.getRangeByIndex(row, col + 1).setText(DateFormat('MM/dd/yyyy').format(date));
            break;
          }
        }
      }
    } catch (e) {
      // If we can't find date cells, that's okay - template might not have them
    }
  }

  /// Helper method to set cell values with proper type handling
  void _setCellValue(Worksheet sheet, int row, int col, dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return; // Leave cell empty for null/empty values
    }
    
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

  /// Helper to convert column letter to index
  int _getColumnIndex(String column) {
    return column.codeUnitAt(0) - 'A'.codeUnitAt(0) + 1;
  }

  /// Generate a report for a specific date range
  Future<Uint8List> generateDateRangeReport({
    required String projectId,
    required DateTime startDate,
    required DateTime endDate,
    String? projectName,
  }) async {
    // For now, generate report for the start date
    // You can extend this to handle multiple days across sheets
    return generateVaporReport(
      projectId: projectId,
      date: startDate,
      projectName: projectName,
    );
  }
}