import 'dart:io';
import 'package:flutter/material.dart';
// import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:permission_handler/permission_handler.dart';
import '../models/ocr_result.dart' as ocr;
import '../models/hourly_reading_models.dart' as hrm;
// import 'anti_hallucination_parser.dart';
// import 'ocr_validation_service.dart' as validation;
// import 'hourly_log_parser.dart';

/// Enhanced OCR Service with anti-hallucination capabilities
class EnhancedOcrService {
  static final _instance = EnhancedOcrService._internal();
  factory EnhancedOcrService() => _instance;
  EnhancedOcrService._internal();

  final _textRecognizer = TextRecognizer();
  final _imagePicker = ImagePicker();
  final _antiHallucinationParser = AntiHallucinationParser();
  final _validationService = validation.OcrValidationService();
  final _traditionalParser = HourlyLogParser();

  /// Dispose resources when done
  void dispose() {
    _textRecognizer.close();
  }

  /// Check and request camera permissions
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    return false;
  }

  /// Take photo from camera
  Future<File?> takePhoto() async {
    try {
      final hasPermission = await requestCameraPermission();
      if (!hasPermission) {
        throw Exception('Camera permission denied');
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error taking photo: $e');
      rethrow;
    }
  }

  /// Pick image from gallery
  Future<File?> pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error picking from gallery: $e');
      rethrow;
    }
  }

  /// Process image with anti-hallucination OCR
  Future<EnhancedOcrResult> processImageWithAntiHallucination(
    File imageFile, {
    String? targetHour,
    bool strictMode = true,
    bool enableDebugMode = true,
  }) async {
    try {
      debugPrint('🔍 Starting enhanced OCR with anti-hallucination...');

      // Step 1: Extract raw text using ML Kit
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      debugPrint(
          '📄 Raw OCR text extracted: ${recognizedText.text.length} characters');

      // Step 2: Process with anti-hallucination parser
      final antiHallucinationResult =
          await _antiHallucinationParser.parseWithAntiHallucination(
        recognizedText.text,
        targetHour ?? '00:00',
        strictMode: strictMode,
      );

      // Step 3: Validate results
      final validationResult = await _validationService.validateForInsertion(
        antiHallucinationResult,
        strictMode: strictMode,
      );

      // Step 4: Create enhanced result
      final result = EnhancedOcrResult(
        rawText: recognizedText.text,
        scanTimestamp: DateTime.now(),
        antiHallucinationResult: antiHallucinationResult,
        validationResult: validationResult,
        extractedFields: _extractFieldsFromResult(antiHallucinationResult),
        confidence: antiHallucinationResult.hourlyReading.overallConfidence,
        debugInfo: enableDebugMode
            ? _generateDebugInfo(
                recognizedText.text,
                antiHallucinationResult,
                validationResult,
              )
            : null,
      );

      debugPrint(
          '✅ Enhanced OCR completed with ${result.extractedFields.length} validated fields');
      debugPrint(
          '🎯 Overall confidence: ${(result.confidence * 100).toStringAsFixed(1)}%');

      return result;
    } catch (e) {
      debugPrint('❌ Enhanced OCR processing failed: $e');
      throw Exception('Failed to process image with anti-hallucination: $e');
    }
  }

  /// Extract fields from anti-hallucination result
  List<ExtractedField> _extractFieldsFromResult(
      AntiHallucinationResult result) {
    final fields = <ExtractedField>[];

    for (final fieldMatch in result.hourlyReading.fieldMatches) {
      if (fieldMatch.value != null) {
        fields.add(ExtractedField(
          fieldName: fieldMatch.name,
          value: fieldMatch.value.toString(),
          type: _mapFieldType(fieldMatch.name),
          confidence: fieldMatch.confidence,
          unit: _getUnitForField(fieldMatch.name),
        ));
      }
    }

    return fields;
  }

  /// Map field name to field type
  FieldType _mapFieldType(String fieldName) {
    final lowerName = fieldName.toLowerCase();

    if (lowerName.contains('temperature') || lowerName.contains('temp')) {
      return FieldType.temperature;
    } else if (lowerName.contains('pressure') || lowerName.contains('psi')) {
      return FieldType.pressure;
    } else if (lowerName.contains('flow') ||
        lowerName.contains('cfm') ||
        lowerName.contains('gpm')) {
      return FieldType.flowRate;
    } else if (lowerName.contains('ppm') || lowerName.contains('h2s')) {
      return FieldType.ppm;
    } else if (lowerName.contains('hour') || lowerName.contains('time')) {
      return FieldType.hour;
    } else {
      return FieldType.text;
    }
  }

  /// Get unit for field
  String _getUnitForField(String fieldName) {
    final lowerName = fieldName.toLowerCase();

    if (lowerName.contains('temperature') || lowerName.contains('temp')) {
      return '°F';
    } else if (lowerName.contains('pressure') || lowerName.contains('psi')) {
      return 'PSI';
    } else if (lowerName.contains('flow') || lowerName.contains('cfm')) {
      return 'CFM';
    } else if (lowerName.contains('gpm')) {
      return 'GPM';
    } else if (lowerName.contains('ppm') || lowerName.contains('h2s')) {
      return 'ppm';
    } else {
      return '';
    }
  }

  /// Generate debug information
  Map<String, dynamic> _generateDebugInfo(
    String rawText,
    AntiHallucinationResult antiHallucinationResult,
    validation.ValidationResult validationResult,
  ) {
    return {
      'rawTextLength': rawText.length,
      'rawTextPreview':
          rawText.length > 200 ? '${rawText.substring(0, 200)}...' : rawText,
      'hallucinationFlags': antiHallucinationResult.hallucinationFlags
          .map((f) => f.toJson())
          .toList(),
      'filteredFields': antiHallucinationResult.hourlyReading.fieldMatches
          .where((f) => f.value != null)
          .map((f) => f.toJson())
          .toList(),
      'validationChecks':
          validationResult.checks.map((c) => c.toJson()).toList(),
      'validationErrors': validationResult.errors,
      'validationWarnings': validationResult.warnings,
      'requiresManualReview': validationResult.requiresManualReview,
    };
  }

  /// Convert enhanced OCR result to ThermalReading data structure
  Map<String, dynamic> mapToThermalReading(EnhancedOcrResult ocrResult) {
    final data = <String, dynamic>{};

    // Add validation metadata
    data['_ocrValidation'] = {
      'isValid': ocrResult.validationResult.isValid,
      'confidence': ocrResult.confidence,
      'requiresManualReview': ocrResult.validationResult.requiresManualReview,
      'validationErrors': ocrResult.validationResult.errors,
      'validationWarnings': ocrResult.validationResult.warnings,
    };

    // Map extracted fields
    for (final field in ocrResult.extractedFields) {
      switch (field.fieldName.toLowerCase()) {
        case 'temperature':
        case 'exhaust temperature':
        case 'inlet temperature':
          final value = field.typedValue as double?;
          if (value != null) {
            data['inletReading'] = value;
          }
          break;

        case 'ppm':
        case 'h2s':
          final value = field.typedValue as double?;
          if (value != null) {
            data['toInletReadingH2S'] = value;
          }
          break;

        case 'pressure':
        case 'vapor pressure':
          final value = field.typedValue as double?;
          if (value != null) {
            data['vaporPressure'] = value;
          }
          break;

        case 'flow rate':
        case 'vapor inlet flow rate':
          final value = field.typedValue as double?;
          if (value != null) {
            data['vaporInletFlowRate'] = value;
          }
          break;

        case 'combustion air':
          final value = field.typedValue as double?;
          if (value != null) {
            data['combustionAir'] = value;
          }
          break;
      }
    }

    return data;
  }

  /// Get processing statistics
  Map<String, dynamic> getProcessingStats(EnhancedOcrResult result) {
    return {
      'totalFieldsDetected':
          result.antiHallucinationResult.rawOcrData.cells.length,
      'fieldsAfterAntiHallucination':
          result.antiHallucinationResult.hourlyReading.fieldMatches.where((f) => f.value != null).length,
      'fieldsAfterValidation': result.extractedFields.length,
      'hallucinationFlagsCount':
          result.antiHallucinationResult.hallucinationFlags.length,
      'validationErrorsCount': result.validationResult.errors.length,
      'validationWarningsCount': result.validationResult.warnings.length,
      'overallConfidence': result.confidence,
      'requiresManualReview': result.validationResult.requiresManualReview,
    };
  }
}

/// Enhanced OCR result with anti-hallucination and validation data
class EnhancedOcrResult {
  final String rawText;
  final DateTime scanTimestamp;
  final AntiHallucinationResult antiHallucinationResult;
  final validation.ValidationResult validationResult;
  final List<ExtractedField> extractedFields;
  final double confidence;
  final Map<String, dynamic>? debugInfo;

  const EnhancedOcrResult({
    required this.rawText,
    required this.scanTimestamp,
    required this.antiHallucinationResult,
    required this.validationResult,
    required this.extractedFields,
    required this.confidence,
    this.debugInfo,
  });

  Map<String, dynamic> toJson() => {
        'rawText': rawText,
        'scanTimestamp': scanTimestamp.toIso8601String(),
        'antiHallucinationResult': antiHallucinationResult.toJson(),
        'validationResult': validationResult.toJson(),
        'extractedFields': extractedFields.map((f) => f.toJson()).toList(),
        'confidence': confidence,
        'debugInfo': debugInfo,
      };

  factory EnhancedOcrResult.fromJson(Map<String, dynamic> json) {
    return EnhancedOcrResult(
      rawText: json['rawText'] ?? '',
      scanTimestamp: DateTime.parse(json['scanTimestamp']),
      antiHallucinationResult:
          AntiHallucinationResult.fromJson(json['antiHallucinationResult']),
      validationResult:
          validation.ValidationResult.fromJson(json['validationResult']),
      extractedFields: (json['extractedFields'] as List?)
              ?.map((f) => ExtractedField.fromJson(f))
              .toList() ??
          [],
      confidence: json['confidence']?.toDouble() ?? 0.0,
      debugInfo: json['debugInfo'] as Map<String, dynamic>?,
    );
  }
}
