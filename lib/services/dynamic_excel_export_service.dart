import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import '../models/log_template.dart';
import '../services/log_template_service.dart';

/// Dynamic Excel export service that uses log templates for schema binding
class DynamicExcelExportService {
  static final Map<String, Workbook> _templateCache = {};
  
  /// Export data using dynamic schema from log template
  static Future<List<int>> generateDynamicReport({
    required String projectId,
    required String logType,
    required List<Map<String, dynamic>> entries,
    required Map<String, dynamic> projectMetadata,
  }) async {
    
    // 1. Get log template configuration
    print('🔍 Looking for log template: $logType');
    final templateConfig = await LogTemplateService.getLogTemplate(logType);
    if (templateConfig == null) {
      print('❌ Log template not found: $logType');
      throw Exception('Log template not found: $logType');
    }
    print('✅ Found log template: ${templateConfig['displayName']}');
    
    // 2. Build dynamic column mapping from template
    final columnMapping = _buildColumnMapping(templateConfig);
    print('📊 Built column mapping with ${columnMapping.length} fields');
    
    // Debug: Print field mapping
    for (final entry in columnMapping.entries) {
      final info = entry.value;
      print('   ${info.fieldId} -> Column ${info.columnIndex} (${info.label})${info.isOptional ? ' [OPTIONAL]' : ''}');
    }
    
    // 3. Create workbook with dynamic schema
    final workbook = Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = templateConfig['displayName'] ?? 'Thermal Log';
    print('📝 Created workbook with sheet: ${sheet.name}');
    
    // 4. Generate dynamic headers
    await _generateDynamicHeaders(sheet, templateConfig, columnMapping);
    
    // 5. Export data with conditional field visibility
    print('📈 Exporting ${entries.length} entries...');
    if (entries.isNotEmpty) {
      print('🔍 Sample entry fields: ${entries.first.keys.join(', ')}');
    }
    await _exportDataWithConditionalFields(
      sheet, 
      entries, 
      templateConfig, 
      columnMapping
    );
    
    // 6. Apply template-specific formatting
    await _applyTemplateFormatting(sheet, templateConfig);
    
    final bytes = workbook.saveAsStream();
    workbook.dispose();
    return bytes;
  }
  
  /// Build dynamic column mapping from log template
  static Map<String, ExcelColumnInfo> _buildColumnMapping(
    Map<String, dynamic> templateConfig
  ) {
    final Map<String, ExcelColumnInfo> mapping = {};
    int columnIndex = 1; // Start at column A
    
    // Sort fields by order from template
    final fields = (templateConfig['fields'] as List)
        .cast<Map<String, dynamic>>()
        .where((field) => _shouldIncludeField(field))
        .toList()
      ..sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
    
    for (final field in fields) {
      mapping[field['id']] = ExcelColumnInfo(
        columnIndex: columnIndex++,
        fieldId: field['id'],
        label: field['label'],
        unit: field['unit'],
        isRequired: field['isRequired'] ?? false,
        isOptional: field['isOptional'] ?? false,
        section: field['section'],
      );
    }
    
    return mapping;
  }
  
  /// Generate dynamic headers based on template configuration
  static Future<void> _generateDynamicHeaders(
    Worksheet sheet,
    Map<String, dynamic> templateConfig,
    Map<String, ExcelColumnInfo> columnMapping,
  ) async {
    // Project header row
    sheet.getRangeByIndex(1, 1).setText(templateConfig['displayName'] ?? 'Thermal Log');
    sheet.getRangeByIndex(1, 1).cellStyle.bold = true;
    
    // Field headers row (row 3)
    int headerRow = 3;
    for (final columnInfo in columnMapping.values) {
      final cell = sheet.getRangeByIndex(headerRow, columnInfo.columnIndex);
      
      // Build header text with unit
      String headerText = columnInfo.label;
      if (columnInfo.unit != null && columnInfo.unit!.isNotEmpty) {
        headerText += ' (${columnInfo.unit})';
      }
      
      cell.setText(headerText);
      cell.cellStyle.bold = true;
      cell.cellStyle.backColor = '#E6F3FF'; // Light blue background
      
      // Mark optional fields differently
      if (columnInfo.isOptional) {
        cell.cellStyle.fontColor = '#666666'; // Gray text for optional
      }
    }
  }
  
  /// Export data with conditional field visibility
  static Future<void> _exportDataWithConditionalFields(
    Worksheet sheet,
    List<Map<String, dynamic>> entries,
    Map<String, dynamic> templateConfig,
    Map<String, ExcelColumnInfo> columnMapping,
  ) async {
    int dataStartRow = 4; // Data starts after headers
    
    // Check which optional fields have data
    final optionalFieldsWithData = _getOptionalFieldsWithData(
      entries, 
      templateConfig
    );
    
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final rowIndex = dataStartRow + i;
      
      for (final columnInfo in columnMapping.values) {
        // Skip optional fields that have no data (conditional visibility)
        if (columnInfo.isOptional && 
            !optionalFieldsWithData.contains(columnInfo.fieldId)) {
          continue; // Hide empty optional columns
        }
        
        final value = entry[columnInfo.fieldId];
        final cell = sheet.getRangeByIndex(rowIndex, columnInfo.columnIndex);
        
        // Set value with proper formatting
        _setDynamicCellValue(cell, value, columnInfo);
      }
    }
  }
  
  /// Determine which optional fields contain actual data
  static Set<String> _getOptionalFieldsWithData(
    List<Map<String, dynamic>> entries,
    Map<String, dynamic> templateConfig,
  ) {
    final optionalFields = Set<String>.from(
      templateConfig['optionalFields'] ?? []
    );
    final fieldsWithData = <String>{};
    
    for (final entry in entries) {
      for (final fieldId in optionalFields) {
        final value = entry[fieldId];
        if (value != null && 
            value.toString().isNotEmpty && 
            value.toString() != '0' && 
            value.toString() != '0.0') {
          fieldsWithData.add(fieldId);
        }
      }
    }
    
    return fieldsWithData;
  }
  
  /// Set cell value with appropriate formatting based on field type
  static void _setDynamicCellValue(
    Range cell, 
    dynamic value, 
    ExcelColumnInfo columnInfo
  ) {
    if (value == null || value.toString().isEmpty) {
      cell.setText('');
      return;
    }
    
    // Format based on field type
    if (value is num) {
      cell.setNumber(value.toDouble());
      
      // Apply number formatting based on unit
      if (columnInfo.unit?.contains('°') == true) {
        cell.numberFormat = '0.0"°"'; // Temperature format
      } else if (columnInfo.unit?.contains('%') == true) {
        cell.numberFormat = '0.0"%"'; // Percentage format
      } else {
        cell.numberFormat = '0.00'; // Default decimal format
      }
    } else {
      cell.setText(value.toString());
    }
    
    // Optional field styling
    if (columnInfo.isOptional) {
      cell.cellStyle.fontColor = '#666666';
    }
  }
  
  /// Apply template-specific formatting and styling
  static Future<void> _applyTemplateFormatting(
    Worksheet sheet,
    Map<String, dynamic> templateConfig,
  ) async {
    final customConfig = templateConfig['customConfig'] as Map<String, dynamic>?;
    
    // Marathon GBR specific formatting
    if (customConfig?['marathonSpecific'] == true) {
      // LEL column highlighting
      _highlightLELColumn(sheet);
      // Temperature warning thresholds
      _applyTemperatureFormatting(sheet, targetTemp: '>1250°F');
    }
    
    // Auto-resize columns
    sheet.autoFitColumn(1);
    sheet.autoFitColumn(2);
  }
  
  /// Highlight LEL monitoring columns for Marathon projects
  static void _highlightLELColumn(Worksheet sheet) {
    // Find LEL column and apply special formatting
    // This would scan for 'lelInletReading' field and highlight it
  }
  
  /// Apply temperature-specific formatting with warning thresholds
  static void _applyTemperatureFormatting(
    Worksheet sheet, 
    {required String targetTemp}
  ) {
    // Apply conditional formatting for temperature columns
    // Red background for values outside target range
  }
  
  /// Check if field should be included in export
  static bool _shouldIncludeField(Map<String, dynamic> field) {
    // Skip metadata fields
    final fieldId = field['id'] as String;
    return !['hour', 'timestamp', 'operatorId', 'validated'].contains(fieldId);
  }
}

/// Information about Excel column mapping
class ExcelColumnInfo {
  final int columnIndex;
  final String fieldId;
  final String label;
  final String? unit;
  final bool isRequired;
  final bool isOptional;
  final String? section;
  
  const ExcelColumnInfo({
    required this.columnIndex,
    required this.fieldId,
    required this.label,
    this.unit,
    this.isRequired = false,
    this.isOptional = false,
    this.section,
  });
}

/// Export configuration for mixed log types
class MixedLogTypeExportConfig {
  final Map<String, ExcelColumnInfo> sharedColumns;
  final Map<String, Map<String, ExcelColumnInfo>> typeSpecificColumns;
  final List<String> logTypes;
  
  const MixedLogTypeExportConfig({
    required this.sharedColumns,
    required this.typeSpecificColumns, 
    required this.logTypes,
  });
  
  /// Generate export for mixed log types
  static Future<List<int>> exportMixedLogTypes({
    required List<Map<String, dynamic>> entries,
    required MixedLogTypeExportConfig config,
  }) async {
    final workbook = Workbook();
    
    // Create separate sheet for each log type
    for (final logType in config.logTypes) {
      final typeEntries = entries.where((e) => e['logType'] == logType).toList();
      if (typeEntries.isNotEmpty) {
        await _createLogTypeSheet(workbook, logType, typeEntries, config);
      }
    }
    
    final bytes = workbook.saveAsStream();
    workbook.dispose();
    return bytes;
  }
  
  static Future<void> _createLogTypeSheet(
    Workbook workbook,
    String logType,
    List<Map<String, dynamic>> entries,
    MixedLogTypeExportConfig config,
  ) async {
    final sheet = workbook.worksheets.add();
    sheet.name = logType.replaceAll('_', ' ').toUpperCase();
    
    // Combine shared and type-specific columns
    final allColumns = <String, ExcelColumnInfo>{
      ...config.sharedColumns,
      ...(config.typeSpecificColumns[logType] ?? {}),
    };
    
    // Generate headers and data
    // ... implementation similar to main export
  }
}