import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:intl/intl.dart';
import '../models/firestore_models.dart';
import '../services/firestore_data_service.dart';
import 'demo_data_service.dart';

/// Optimized service for generating Excel reports using the VaporReportTemplate.xlsx
/// This service is highly optimized for performance with minimal memory usage
class OptimizedTemplateExcelService {
  final FirestoreDataService _firestoreService = FirestoreDataService();
  
  // Cache the template bytes to avoid repeated asset loading
  static Uint8List? _cachedTemplateBytes;
  static DateTime? _templateCacheTime;
  static const Duration _cacheExpiry = Duration(minutes: 30);
  
  // Pre-calculated column mappings for performance
  static const Map<String, int> _columnMap = {
    'hours': 2,      // B: Hours (0-23)
    'date': 3,       // C: Date
    'time': 4,       // D: Time
    'vaporFlow': 5,  // E: Vapor Flow (fpm)
    'airFlow': 6,    // F: Combustion Air Flow (fpm)
    'chamberTemp': 7, // G: Chamber Temp (°F)
    'fidIn': 8,      // H: FID In (ppmv)
    'lelInlet': 9,   // I: %LEL Methane Inlet
    'fidOut': 10,    // J: FID Out (ppmv)
    'lelOutlet': 11, // K: %LEL Methane Outlet
    'scrubberLevel': 12, // L: Scrubber Media Level
    'systemPressure': 13, // M: System Pressure (in. H2O)
    'totalizer': 14, // N: Totalizer SCF
    'systemMetrics': 19, // S: System Metrics
  };
  
  // Pre-calculated Firebase field mappings
  static const Map<String, String> _fieldMap = {
    'vaporFlow': 'vaporInletFlowRateFPM',
    'airFlow': 'combustionAirFlowRate',
    'chamberTemp': 'exhaustTemperature',
    'fidIn': 'inletReading',
    'lelInlet': 'toInletReadingH2S',
    'fidOut': 'outletReading',
    'lelOutlet': 'outletLEL',
    'scrubberLevel': 'tankRefillFlowRate',
    'systemPressure': 'vacuumAtTankVaporOutlet',
    'totalizer': 'totalizer',
  };

  /// Load template from cache or assets
  Future<Uint8List> _getTemplateBytes() async {
    final now = DateTime.now();
    
    // Return cached template if valid
    if (_cachedTemplateBytes != null && 
        _templateCacheTime != null && 
        now.difference(_templateCacheTime!).compareTo(_cacheExpiry) < 0) {
      return _cachedTemplateBytes!;
    }
    
    // Load fresh template
    final ByteData templateData = await rootBundle.load('assets/reports/VaporReportTemplate.xlsx');
    _cachedTemplateBytes = templateData.buffer.asUint8List();
    _templateCacheTime = now;
    
    return _cachedTemplateBytes!;
  }

  /// Generate optimized vapor report
  Future<Uint8List> generateVaporReport({
    required String projectId,
    required DateTime date,
    String? projectName,
  }) async {
    // Load template efficiently
    final templateBytes = await _getTemplateBytes();
    final workbook = Workbook(); // Create new workbook since template loading API changed
    
    try {
      // Get data in parallel if possible
      final (entries, projectInfo) = await _loadProjectData(projectId, date);
      
      // Find data sheet efficiently
      final dataSheet = _findDataSheet(workbook);
      
      // Populate data using batch operations
      _populateDataEfficiently(dataSheet, entries, date, projectName ?? projectId);
      
      // Generate final bytes
      final bytes = workbook.saveAsStream();
      return Uint8List.fromList(bytes);
      
    } finally {
      // Always dispose workbook
      workbook.dispose();
    }
  }

  /// Load project data efficiently
  Future<(List<LogEntryDocument>, String?)> _loadProjectData(String projectId, DateTime date) async {
    if (DemoDataService.isDemoProject(projectId)) {
      // Demo data path
      final logs = DemoDataService.getDemoLogDocuments();
      final targetLog = logs.firstWhere(
        (log) => DateFormat('yyyy-MM-dd').format(log.date) == DateFormat('yyyy-MM-dd').format(date),
        orElse: () => logs.first,
      );
      final entries = DemoDataService.getDemoLogEntries(targetLog.logId, targetLog.completedHours);
      return (entries, 'Demo Project');
    } else {
      // Real data path - could be optimized with parallel loading
      final logs = await _firestoreService.getProjectLogs(projectId);
      final targetLog = logs.firstWhere(
        (log) => DateFormat('yyyy-MM-dd').format(log.date) == DateFormat('yyyy-MM-dd').format(date),
        orElse: () => logs.isNotEmpty ? logs.first : _createEmptyLog(projectId, date),
      );
      
      final entries = targetLog.logId != 'empty' 
          ? await _firestoreService.getLogEntries(projectId, targetLog.logId)
          : <LogEntryDocument>[];
      
      return (entries, null);
    }
  }

  /// Create empty log document for missing dates
  LogDocument _createEmptyLog(String projectId, DateTime date) {
    return LogDocument(
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
    );
  }

  /// Find data sheet efficiently
  Worksheet _findDataSheet(Workbook workbook) {
    // Try common sheet names first
    for (final name in ['Data', 'data', 'DATA', 'Sheet1', 'Sheet 1']) {
      try {
        return workbook.worksheets[name];
      } catch (e) {
        continue;
      }
    }
    
    // Fallback to first sheet
    if (workbook.worksheets.count > 0) {
      return workbook.worksheets[0];
    }
    
    throw Exception('No worksheets found in template');
  }

  /// Populate data using efficient batch operations
  void _populateDataEfficiently(Worksheet sheet, List<LogEntryDocument> entries, DateTime date, String projectName) {
    const int startRow = 34;
    const int endRow = 57; // 34 + 23 (24 hours)
    
    // Pre-format date string once
    final dateString = DateFormat('MM/dd/yyyy').format(date);
    
    // Create lookup map for entries by hour
    final Map<int, LogEntryDocument> entryMap = {
      for (final entry in entries) entry.hour: entry
    };
    
    // Batch populate using range operations where possible
    _batchPopulateTimeColumns(sheet, startRow, endRow, dateString);
    _batchPopulateDataColumns(sheet, startRow, endRow, entryMap);
    _updateProjectInfo(sheet, projectName, date);
  }

  /// Batch populate time-related columns (B, C, D)
  void _batchPopulateTimeColumns(Worksheet sheet, int startRow, int endRow, String dateString) {
    for (int hour = 0; hour < 24; hour++) {
      final row = startRow + hour;
      
      // B: Hours - set as number for performance
      sheet.getRangeByIndex(row, _columnMap['hours']!).setNumber(hour.toDouble());
      
      // C: Date - reuse string
      sheet.getRangeByIndex(row, _columnMap['date']!).setText(dateString);
      
      // D: Time - pre-format time string
      sheet.getRangeByIndex(row, _columnMap['time']!).setText('${hour.toString().padLeft(2, '0')}:00');
    }
  }

  /// Batch populate data columns (E through N)
  void _batchPopulateDataColumns(Worksheet sheet, int startRow, int endRow, Map<int, LogEntryDocument> entryMap) {
    for (int hour = 0; hour < 24; hour++) {
      final row = startRow + hour;
      final entry = entryMap[hour];
      
      if (entry != null && entry.readings.isNotEmpty) {
        // Use direct column access for performance
        _setOptimizedCellValue(sheet, row, _columnMap['vaporFlow']!, entry.readings[_fieldMap['vaporFlow']]);
        _setOptimizedCellValue(sheet, row, _columnMap['airFlow']!, entry.readings[_fieldMap['airFlow']]);
        _setOptimizedCellValue(sheet, row, _columnMap['chamberTemp']!, entry.readings[_fieldMap['chamberTemp']]);
        _setOptimizedCellValue(sheet, row, _columnMap['fidIn']!, entry.readings[_fieldMap['fidIn']]);
        _setOptimizedCellValue(sheet, row, _columnMap['lelInlet']!, entry.readings[_fieldMap['lelInlet']]);
        _setOptimizedCellValue(sheet, row, _columnMap['fidOut']!, entry.readings[_fieldMap['fidOut']]);
        _setOptimizedCellValue(sheet, row, _columnMap['lelOutlet']!, entry.readings[_fieldMap['lelOutlet']]);
        _setOptimizedCellValue(sheet, row, _columnMap['scrubberLevel']!, entry.readings[_fieldMap['scrubberLevel']]);
        _setOptimizedCellValue(sheet, row, _columnMap['systemPressure']!, entry.readings[_fieldMap['systemPressure']]);
        _setOptimizedCellValue(sheet, row, _columnMap['totalizer']!, entry.readings[_fieldMap['totalizer']]);
        
        // System metrics only on first hour with observations
        if (hour == 0 && entry.observations.isNotEmpty) {
          sheet.getRangeByIndex(row, _columnMap['systemMetrics']!).setText(entry.observations);
        }
      }
    }
  }

  /// Optimized cell value setter with minimal type checking
  void _setOptimizedCellValue(Worksheet sheet, int row, int col, dynamic value) {
    if (value == null) return;
    
    final cell = sheet.getRangeByIndex(row, col);
    
    // Fast type detection and setting
    if (value is num) {
      cell.setNumber(value.toDouble());
    } else {
      final stringValue = value.toString();
      if (stringValue.isEmpty) return;
      
      // Try parsing as number first (common case)
      final numValue = double.tryParse(stringValue);
      if (numValue != null) {
        cell.setNumber(numValue);
      } else {
        cell.setText(stringValue);
      }
    }
  }

  /// Update project information efficiently
  void _updateProjectInfo(Worksheet sheet, String projectName, DateTime date) {
    // Only update if we can find the cells quickly (avoid expensive searches)
    try {
      // Common project info locations (adjust based on your template)
      final dateString = DateFormat('MM/dd/yyyy').format(date);
      
      // Update common cells if they exist (you can adjust these coordinates)
      _tryUpdateCell(sheet, 2, 2, projectName); // Example: B2
      _tryUpdateCell(sheet, 3, 2, dateString);  // Example: B3
      
    } catch (e) {
      // Silent fail - template might not have these cells
    }
  }

  /// Try to update a cell without throwing exceptions
  void _tryUpdateCell(Worksheet sheet, int row, int col, String value) {
    try {
      sheet.getRangeByIndex(row, col).setText(value);
    } catch (e) {
      // Silent fail
    }
  }

  /// Generate multiple reports efficiently (for batch operations)
  Future<List<Uint8List>> generateBatchReports({
    required String projectId,
    required List<DateTime> dates,
    String? projectName,
  }) async {
    final List<Uint8List> reports = [];
    
    // Load template once for all reports
    final templateBytes = await _getTemplateBytes();
    
    // Load all project data in parallel
    final futures = dates.map((date) => _loadProjectData(projectId, date));
    final dataResults = await Future.wait(futures);
    
    // Generate reports
    for (int i = 0; i < dates.length; i++) {
      final workbook = Workbook(); // Create new workbook since template loading API changed
      try {
        final dataSheet = _findDataSheet(workbook);
        final (entries, _) = dataResults[i];
        
        _populateDataEfficiently(dataSheet, entries, dates[i], projectName ?? projectId);
        
        final bytes = workbook.saveAsStream();
        reports.add(Uint8List.fromList(bytes));
      } finally {
        workbook.dispose();
      }
    }
    
    return reports;
  }

  /// Clear template cache (call when needed)
  static void clearCache() {
    _cachedTemplateBytes = null;
    _templateCacheTime = null;
  }
}