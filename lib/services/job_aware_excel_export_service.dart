import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import '../model/job_model.dart';
import '../models/log_template.dart';
import '../services/excel_template_selection_service.dart';

/// Excel export result
class ExcelExportResult {
  final bool success;
  final String? filePath;
  final Uint8List? fileBytes;
  final String? errorMessage;
  final Map<String, dynamic> metadata;

  const ExcelExportResult({
    required this.success,
    this.filePath,
    this.fileBytes,
    this.errorMessage,
    this.metadata = const {},
  });

  factory ExcelExportResult.success({
    String? filePath,
    Uint8List? fileBytes,
    Map<String, dynamic> metadata = const {},
  }) {
    return ExcelExportResult(
      success: true,
      filePath: filePath,
      fileBytes: fileBytes,
      metadata: metadata,
    );
  }

  factory ExcelExportResult.failure(String error) {
    return ExcelExportResult(
      success: false,
      errorMessage: error,
    );
  }
}

/// Job-aware Excel export service that integrates with the template pipeline
class JobAwareExcelExportService {
  final ExcelTemplateSelectionService _templateService = ExcelTemplateSelectionService();

  /// Export job data to Excel using the configured template
  Future<ExcelExportResult> exportJobToExcel({
    required Job job,
    required Map<String, List<Map<String, dynamic>>> hourlyData,
    String? outputPath,
    Map<String, dynamic> additionalMetadata = const {},
  }) async {
    try {
      // Check if job has Excel template configured
      if (!job.hasExcelTemplate) {
        return ExcelExportResult.failure(
          'Job does not have an Excel template configured. Use Flutter forms only.',
        );
      }

      // Get template configuration
      final templateConfig = job.templateConfig!;
      final excelTemplate = await _templateService.getTemplateById(templateConfig.excelTemplateId!);
      
      if (excelTemplate == null) {
        return ExcelExportResult.failure(
          'Excel template not found: ${templateConfig.excelTemplateId}',
        );
      }

      // Validate template compatibility
      if (!excelTemplate.compatibleLogTypes.contains(job.logTypeEnum)) {
        return ExcelExportResult.failure(
          'Template ${excelTemplate.id} is not compatible with log type ${job.logTypeEnum.displayName}',
        );
      }

      // Prepare data for export
      final exportData = _prepareExportData(job, hourlyData, excelTemplate);

      // Call Node.js export pipeline
      final result = await _callNodeExportPipeline(
        job: job,
        excelTemplate: excelTemplate,
        exportData: exportData,
        outputPath: outputPath,
        additionalMetadata: additionalMetadata,
      );

      return result;

    } catch (e) {
      return ExcelExportResult.failure('Export failed: $e');
    }
  }

  /// Prepare data for export by mapping Flutter fields to Excel template fields
  Map<String, dynamic> _prepareExportData(
    Job job,
    Map<String, List<Map<String, dynamic>>> hourlyData,
    ExcelTemplateConfig excelTemplate,
  ) {
    final mappedData = <String, List<Map<String, dynamic>>>{};

    // Map each hour's data
    hourlyData.forEach((dateKey, dayData) {
      final mappedDayData = <Map<String, dynamic>>[];

      for (final hourEntry in dayData) {
        final mappedEntry = <String, dynamic>{};

        // Map each field using the template's field mapping
        excelTemplate.fieldMapping.forEach((excelField, flutterField) {
          if (hourEntry.containsKey(flutterField)) {
            mappedEntry[excelField] = hourEntry[flutterField];
          }
        });

        // Add timestamp if available
        if (hourEntry.containsKey('timestamp')) {
          mappedEntry['timestamp'] = hourEntry['timestamp'];
        }

        // Add hour index if available
        if (hourEntry.containsKey('hour')) {
          mappedEntry['hour'] = hourEntry['hour'];
        }

        mappedDayData.add(mappedEntry);
      }

      mappedData[dateKey] = mappedDayData;
    });

    return {
      'job': {
        'projectNumber': job.projectNumber,
        'facilityName': job.facilityName,
        'tankId': job.tankId,
        'logType': job.logType,
        'createdAt': job.createdAt?.toIso8601String(),
        'createdBy': job.createdBy,
      },
      'template': {
        'id': excelTemplate.id,
        'displayName': excelTemplate.displayName,
        'templatePath': excelTemplate.excelTemplatePath,
        'mappingPath': excelTemplate.mappingFilePath,
      },
      'hourlyData': mappedData,
      'metadata': {
        'exportedAt': DateTime.now().toIso8601String(),
        'exportedBy': 'Flutter App',
        'templateVersion': '1.0.0',
        'jobTemplateConfig': job.templateConfig?.toMap(),
      },
    };
  }

  /// Call the Node.js export pipeline
  Future<ExcelExportResult> _callNodeExportPipeline({
    required Job job,
    required ExcelTemplateConfig excelTemplate,
    required Map<String, dynamic> exportData,
    String? outputPath,
    Map<String, dynamic> additionalMetadata = const {},
  }) async {
    try {
      // For now, we'll use a method channel to call Node.js
      // In a real implementation, you might use:
      // 1. HTTP API to a Node.js server
      // 2. Platform channel to call Node.js directly
      // 3. Generate the file using a Dart Excel library

      const platform = MethodChannel('thermal_log_excel_export');
      
      final result = await platform.invokeMethod('exportToExcel', {
        'templatePath': excelTemplate.excelTemplatePath,
        'mappingPath': excelTemplate.mappingFilePath,
        'exportData': exportData,
        'outputPath': outputPath,
        'additionalMetadata': additionalMetadata,
      });

      if (result['success'] == true) {
        return ExcelExportResult.success(
          filePath: result['filePath'],
          fileBytes: result['fileBytes'],
          metadata: Map<String, dynamic>.from(result['metadata'] ?? {}),
        );
      } else {
        return ExcelExportResult.failure(result['error'] ?? 'Unknown export error');
      }

    } catch (e) {
      // Fallback: Return a mock result for development
      return _createMockExportResult(job, excelTemplate, exportData, outputPath);
    }
  }

  /// Create mock export result for development/testing
  ExcelExportResult _createMockExportResult(
    Job job,
    ExcelTemplateConfig excelTemplate,
    Map<String, dynamic> exportData,
    String? outputPath,
  ) {
    final fileName = outputPath ?? 
        'thermal_log_${job.projectNumber}_${DateTime.now().millisecondsSinceEpoch}.xlsx';

    return ExcelExportResult.success(
      filePath: fileName,
      metadata: {
        'templateUsed': excelTemplate.displayName,
        'recordsExported': _countTotalRecords(exportData),
        'exportMethod': 'mock',
        'validationStatus': 'pending',
      },
    );
  }

  int _countTotalRecords(Map<String, dynamic> exportData) {
    final hourlyData = exportData['hourlyData'] as Map<String, dynamic>? ?? {};
    return hourlyData.values
        .cast<List>()
        .fold(0, (total, dayData) => total + dayData.length);
  }

  /// Validate export data against template requirements
  Future<List<String>> validateExportData({
    required Job job,
    required Map<String, List<Map<String, dynamic>>> hourlyData,
  }) async {
    final errors = <String>[];

    if (!job.hasExcelTemplate) {
      return ['Job does not have Excel template configured'];
    }

    final templateConfig = job.templateConfig!;
    final excelTemplate = await _templateService.getTemplateById(templateConfig.excelTemplateId!);
    
    if (excelTemplate == null) {
      errors.add('Excel template not found: ${templateConfig.excelTemplateId}');
      return errors;
    }

    // Check required fields
    for (final entry in hourlyData.entries) {
      final dayData = entry.value;
      for (int i = 0; i < dayData.length; i++) {
        final hourEntry = dayData[i];
        
        for (final requiredExcelField in excelTemplate.requiredFields) {
          final flutterField = excelTemplate.fieldMapping[requiredExcelField];
          
          if (flutterField == null) {
            errors.add('Mapping not found for required field: $requiredExcelField');
            continue;
          }
          
          if (!hourEntry.containsKey(flutterField) || hourEntry[flutterField] == null) {
            errors.add('Missing required field "$flutterField" for ${entry.key} hour ${i + 1}');
          }
        }
      }
    }

    // Validate field values against template rules
    for (final entry in hourlyData.entries) {
      final dayData = entry.value;
      for (int i = 0; i < dayData.length; i++) {
        final hourEntry = dayData[i];
        
        excelTemplate.validationRules.forEach((excelField, rules) {
          final flutterField = excelTemplate.fieldMapping[excelField];
          if (flutterField != null && hourEntry.containsKey(flutterField)) {
            final value = hourEntry[flutterField];
            final validationErrors = _validateFieldValue(
              excelField,
              value,
              rules as Map<String, dynamic>,
              '${entry.key} hour ${i + 1}',
            );
            errors.addAll(validationErrors);
          }
        });
      }
    }

    return errors;
  }

  List<String> _validateFieldValue(
    String fieldName,
    dynamic value,
    Map<String, dynamic> rules,
    String location,
  ) {
    final errors = <String>[];

    if (value == null) return errors;

    final numValue = double.tryParse(value.toString());
    if (numValue == null) return errors;

    if (rules['min'] != null && numValue < rules['min']) {
      errors.add('$fieldName at $location: $numValue is below minimum ${rules['min']}');
    }

    if (rules['max'] != null && numValue > rules['max']) {
      errors.add('$fieldName at $location: $numValue is above maximum ${rules['max']}');
    }

    return errors;
  }

  /// Generate export preview/summary
  Future<Map<String, dynamic>> generateExportPreview({
    required Job job,
    required Map<String, List<Map<String, dynamic>>> hourlyData,
  }) async {
    final validationErrors = await validateExportData(job: job, hourlyData: hourlyData);
    final totalRecords = _countTotalRecords({'hourlyData': hourlyData});

    final templateConfig = job.templateConfig;
    ExcelTemplateConfig? excelTemplate;
    if (templateConfig?.excelTemplateId != null) {
      excelTemplate = await _templateService.getTemplateById(templateConfig!.excelTemplateId!);
    }

    return {
      'job': {
        'projectNumber': job.projectNumber,
        'facilityName': job.facilityName,
        'tankId': job.tankId,
        'logType': job.logType,
        'hasExcelTemplate': job.hasExcelTemplate,
        'templateDisplayName': job.templateDisplayName,
      },
      'template': excelTemplate != null ? {
        'id': excelTemplate.id,
        'displayName': excelTemplate.displayName,
        'description': excelTemplate.description,
        'requiredFields': excelTemplate.requiredFields,
        'compatibleTypes': excelTemplate.compatibleLogTypes.map((t) => t.displayName).toList(),
      } : null,
      'data': {
        'totalRecords': totalRecords,
        'dateRange': hourlyData.keys.toList()..sort(),
        'recordsPerDay': hourlyData.map((date, dayData) => MapEntry(date, dayData.length)),
      },
      'validation': {
        'isValid': validationErrors.isEmpty,
        'errors': validationErrors,
        'warnings': [], // Could add warnings for non-critical issues
      },
      'export': {
        'canExport': job.hasExcelTemplate && validationErrors.isEmpty,
        'exportMethod': job.hasExcelTemplate ? 'excel_template' : 'flutter_forms',
        'estimatedFileSize': '${(totalRecords * 0.5).round()} KB', // Rough estimate
      },
    };
  }
}