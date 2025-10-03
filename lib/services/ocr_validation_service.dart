import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/hourly_reading_models.dart';
import 'anti_hallucination_parser.dart';

/// OCR Validation Service for compliance-grade logging
/// Provides regex validation, bounding box checks, and confidence scoring
class OcrValidationService {
  static final _instance = OcrValidationService._internal();
  factory OcrValidationService() => _instance;
  OcrValidationService._internal();

  // Validation configuration
  static const double _minConfidenceForInsertion = 0.8;
  static const double _minBoundingBoxOverlap = 0.7;
  static const bool _enableStrictValidation = true;
  static const bool _enableDebugMode = true;

  /// Validate OCR result before database insertion
  Future<ValidationResult> validateForInsertion(
    AntiHallucinationResult antiHallucinationResult, {
    Map<String, dynamic>? sourceImageData,
    bool strictMode = true,
  }) async {
    debugPrint('🔍 Starting OCR validation for insertion');

    try {
      final validationChecks = <ValidationCheck>[];

      // 1. Hallucination detection validation
      final hallucinationCheck =
          _validateHallucinationDetection(antiHallucinationResult);
      validationChecks.add(hallucinationCheck);

      // 2. Regex pattern validation
      final regexCheck =
          _validateRegexPatterns(antiHallucinationResult.hourlyReading);
      validationChecks.add(regexCheck);

      // 3. Bounding box validation (if source image data available)
      if (sourceImageData != null) {
        final boundingBoxCheck = _validateBoundingBoxes(
          antiHallucinationResult,
          sourceImageData,
        );
        validationChecks.add(boundingBoxCheck);
      }

      // 4. Confidence threshold validation
      final confidenceCheck =
          _validateConfidenceThresholds(antiHallucinationResult);
      validationChecks.add(confidenceCheck);

      // 5. Business logic validation
      final businessLogicCheck =
          _validateBusinessLogic(antiHallucinationResult.hourlyReading);
      validationChecks.add(businessLogicCheck);

      // 6. Pattern consistency validation
      final patternCheck = _validatePatternConsistency(antiHallucinationResult);
      validationChecks.add(patternCheck);

      // Determine overall validation result
      final overallResult =
          _determineOverallValidation(validationChecks, strictMode);

      debugPrint(
          '✅ OCR validation complete: ${overallResult.isValid ? 'PASS' : 'FAIL'}');
      debugPrint(
          '📊 Validation checks: ${validationChecks.where((c) => c.isValid).length}/${validationChecks.length} passed');

      return overallResult;
    } catch (e, stackTrace) {
      debugPrint('❌ OCR validation error: $e');
      debugPrint('Stack trace: $stackTrace');

      return ValidationResult(
        isValid: false,
        errors: ['Validation process failed: $e'],
        warnings: [],
        checks: [],
        overallConfidence: 0.0,
        requiresManualReview: true,
      );
    }
  }

  /// Validate hallucination detection
  ValidationCheck _validateHallucinationDetection(
      AntiHallucinationResult result) {
    final errors = <String>[];
    final warnings = <String>[];

    if (result.hasHallucinations) {
      errors.add(
          'Hallucination detected: ${result.hallucinationFlags.length} flags');

      for (final flag in result.hallucinationFlags) {
        warnings.add('${flag.type}: ${flag.description}');
      }
    }

    // Check for suspicious patterns in the data
    final suspiciousPatterns = _detectSuspiciousPatterns(result.hourlyReading);
    if (suspiciousPatterns.isNotEmpty) {
      warnings.addAll(suspiciousPatterns.map((p) => 'Suspicious pattern: $p'));
    }

    return ValidationCheck(
      name: 'hallucination_detection',
      isValid: !result.hasHallucinations,
      confidence: result.hasHallucinations ? 0.3 : 0.9,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate regex patterns for each field
  ValidationCheck _validateRegexPatterns(HourlyReading reading) {
    final errors = <String>[];
    final warnings = <String>[];

    final regexPatterns = {
      'vaporInletFpm': RegExp(r'^\d{1,5}$'),
      'dilutionAirFpm': RegExp(r'^\d{1,5}$'),
      'combustionAirFpm': RegExp(r'^\d{1,5}$'),
      'exhaustTempF': RegExp(r'^\d{3,4}$'),
      'spherePressurePsi': RegExp(r'^\d{1,3}(\.\d{1,2})?$'),
      'inletPpm': RegExp(r'^\d{1,6}(\.\d{1,2})?$'),
      'outletPpm': RegExp(r'^\d{1,6}(\.\d{1,2})?$'),
      'totalizerScf': RegExp(r'^\d{4,10}$'),
    };

    for (final match in reading.fieldMatches) {
      final pattern = regexPatterns[match.name];
      if (pattern != null && match.value != null) {
        final valueStr = match.value.toString();
        if (!pattern.hasMatch(valueStr)) {
          errors.add(
              '${match.name}: "$valueStr" does not match expected pattern');
        }
      }
    }

    return ValidationCheck(
      name: 'regex_patterns',
      isValid: errors.isEmpty,
      confidence: errors.isEmpty ? 0.9 : 0.4,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate bounding boxes against source image
  ValidationCheck _validateBoundingBoxes(
    AntiHallucinationResult result,
    Map<String, dynamic> sourceImageData,
  ) {
    final errors = <String>[];
    final warnings = <String>[];

    // This would need to be implemented based on your OCR engine's bounding box format
    // For now, we'll provide a framework for the validation

    for (final cell in result.rawOcrData.cells) {
      if (cell.boundingBox != null) {
        final overlapScore =
            _calculateBoundingBoxOverlap(cell.boundingBox!, sourceImageData);

        if (overlapScore < _minBoundingBoxOverlap) {
          warnings.add(
              'Low bounding box overlap for cell "${cell.text}": ${(overlapScore * 100).toInt()}%');
        }

        // Check for reasonable bounding box dimensions
        if (!_isBoundingBoxReasonable(cell.boundingBox!)) {
          errors.add('Unreasonable bounding box for cell "${cell.text}"');
        }
      }
    }

    return ValidationCheck(
      name: 'bounding_boxes',
      isValid: errors.isEmpty,
      confidence: errors.isEmpty ? 0.8 : 0.3,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate confidence thresholds
  ValidationCheck _validateConfidenceThresholds(
      AntiHallucinationResult result) {
    final errors = <String>[];
    final warnings = <String>[];

    // Check overall confidence
    if (result.hourlyReading.overallConfidence < _minConfidenceForInsertion) {
      errors.add(
          'Overall confidence too low: ${(result.hourlyReading.overallConfidence * 100).toInt()}%');
    }

    // Check individual field confidences
    for (final match in result.hourlyReading.fieldMatches) {
      if (match.confidence < _minConfidenceForInsertion) {
        warnings.add(
            'Low confidence field ${match.name}: ${(match.confidence * 100).toInt()}%');
      }
    }

    // Check cell confidences
    for (final entry in result.cellConfidences.entries) {
      if (entry.value < _minConfidenceForInsertion) {
        warnings.add(
            'Low cell confidence for ${entry.key}: ${(entry.value * 100).toInt()}%');
      }
    }

    return ValidationCheck(
      name: 'confidence_thresholds',
      isValid: errors.isEmpty,
      confidence: errors.isEmpty ? 0.9 : 0.4,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate business logic rules
  ValidationCheck _validateBusinessLogic(HourlyReading reading) {
    final errors = <String>[];
    final warnings = <String>[];

    // Temperature validation
    if (reading.exhaustTempF != null) {
      if (reading.exhaustTempF! < 500) {
        errors.add('Exhaust temperature too low: ${reading.exhaustTempF}°F');
      } else if (reading.exhaustTempF! > 2000) {
        warnings.add(
            'Exhaust temperature unusually high: ${reading.exhaustTempF}°F');
      }
    }

    // Pressure validation
    if (reading.spherePressurePsi != null) {
      if (reading.spherePressurePsi! <= 0) {
        errors.add(
            'Sphere pressure must be positive: ${reading.spherePressurePsi} PSI');
      } else if (reading.spherePressurePsi! > 50) {
        warnings.add(
            'Sphere pressure unusually high: ${reading.spherePressurePsi} PSI');
      }
    }

    // Flow rate validation
    if (reading.vaporInletFpm != null && reading.dilutionAirFpm != null) {
      if (reading.vaporInletFpm! < reading.dilutionAirFpm!) {
        warnings.add('Vapor inlet flow rate lower than dilution air flow rate');
      }
    }

    // PPM validation
    if (reading.inletPpm != null && reading.outletPpm != null) {
      if (reading.outletPpm! > reading.inletPpm! * 0.1) {
        warnings.add('Outlet PPM unusually high relative to inlet PPM');
      }
    }

    return ValidationCheck(
      name: 'business_logic',
      isValid: errors.isEmpty,
      confidence: errors.isEmpty ? 0.9 : 0.5,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate pattern consistency
  ValidationCheck _validatePatternConsistency(AntiHallucinationResult result) {
    final errors = <String>[];
    final warnings = <String>[];

    // Check for too many consecutive filled hours
    final filledHours =
        result.rawOcrData.cells.where((cell) => !cell.isEmpty).length;
    if (filledHours > 8) {
      warnings.add('Unusually many filled hours: $filledHours');
    }

    // Check for suspicious value patterns
    final numericValues = result.rawOcrData.cells
        .where((cell) => _isNumeric(cell.text))
        .map((cell) => double.tryParse(cell.text) ?? 0.0)
        .toList();

    if (numericValues.length >= 3) {
      // Check for arithmetic sequences
      final differences = <double>[];
      for (int i = 1; i < numericValues.length; i++) {
        differences.add(numericValues[i] - numericValues[i - 1]);
      }

      if (differences.length >= 2) {
        final avgDifference =
            differences.reduce((a, b) => a + b) / differences.length;
        final variance = differences
                .map((d) => (d - avgDifference) * (d - avgDifference))
                .reduce((a, b) => a + b) /
            differences.length;

        if (variance < 1.0) {
          // Very low variance suggests artificial pattern
          warnings.add('Suspiciously consistent value differences detected');
        }
      }
    }

    return ValidationCheck(
      name: 'pattern_consistency',
      isValid: errors.isEmpty,
      confidence: errors.isEmpty ? 0.8 : 0.6,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Detect suspicious patterns in the data
  List<String> _detectSuspiciousPatterns(HourlyReading reading) {
    final patterns = <String>[];

    // Check for round numbers
    final roundNumberPatterns = [
      RegExp(r'^\d{1,3}00$'), // 100, 200, 300, etc.
      RegExp(r'^\d{1,2}50$'), // 50, 150, 250, etc.
      RegExp(r'^\d{1,2}0$'), // 10, 20, 30, etc.
    ];

    for (final match in reading.fieldMatches) {
      if (match.value != null) {
        final valueStr = match.value.toString();
        for (final pattern in roundNumberPatterns) {
          if (pattern.hasMatch(valueStr)) {
            patterns.add('Round number detected: ${match.name} = $valueStr');
          }
        }
      }
    }

    return patterns;
  }

  /// Calculate bounding box overlap score
  double _calculateBoundingBoxOverlap(
      Map<String, dynamic> boundingBox, Map<String, dynamic> sourceImageData) {
    // This is a placeholder implementation
    // You would need to implement actual bounding box overlap calculation
    // based on your OCR engine's bounding box format

    try {
      // Example implementation for a simple bounding box format
      final box1 = boundingBox;
      final box2 = sourceImageData['expectedBounds'];

      if (box2 == null) return 0.5;

      // Calculate intersection over union (IoU)
      // This is a simplified version - you'd need the actual coordinates
      return 0.8; // Placeholder
    } catch (e) {
      debugPrint('Error calculating bounding box overlap: $e');
      return 0.5;
    }
  }

  /// Check if bounding box dimensions are reasonable
  bool _isBoundingBoxReasonable(Map<String, dynamic> boundingBox) {
    try {
      // This would check if the bounding box dimensions make sense
      // for the expected text content

      // Example checks:
      // - Width and height are positive
      // - Aspect ratio is reasonable for text
      // - Size is appropriate for the content

      return true; // Placeholder
    } catch (e) {
      debugPrint('Error checking bounding box reasonableness: $e');
      return false;
    }
  }

  /// Determine overall validation result
  ValidationResult _determineOverallValidation(
      List<ValidationCheck> checks, bool strictMode) {
    final allErrors = <String>[];
    final allWarnings = <String>[];
    double totalConfidence = 0.0;
    int validChecks = 0;

    for (final check in checks) {
      allErrors.addAll(check.errors);
      allWarnings.addAll(check.warnings);
      totalConfidence += check.confidence;

      if (check.isValid) {
        validChecks++;
      }
    }

    final averageConfidence =
        checks.isEmpty ? 0.0 : totalConfidence / checks.length;
    final isValid = strictMode
        ? allErrors.isEmpty && validChecks == checks.length
        : allErrors.isEmpty;
    final requiresManualReview =
        allWarnings.isNotEmpty || averageConfidence < 0.8;

    return ValidationResult(
      isValid: isValid,
      errors: allErrors,
      warnings: allWarnings,
      checks: checks,
      overallConfidence: averageConfidence,
      requiresManualReview: requiresManualReview,
    );
  }

  /// Check if text is numeric
  bool _isNumeric(String text) {
    return double.tryParse(text.trim()) != null;
  }

  /// Generate validation report for debugging
  String generateValidationReport(ValidationResult result) {
    final buffer = StringBuffer();

    buffer.writeln('=== OCR Validation Report ===');
    buffer.writeln('Overall Result: ${result.isValid ? 'PASS' : 'FAIL'}');
    buffer.writeln('Confidence: ${(result.overallConfidence * 100).toInt()}%');
    buffer.writeln(
        'Requires Manual Review: ${result.requiresManualReview ? 'YES' : 'NO'}');
    buffer.writeln('');

    if (result.errors.isNotEmpty) {
      buffer.writeln('❌ ERRORS:');
      for (final error in result.errors) {
        buffer.writeln('  - $error');
      }
      buffer.writeln('');
    }

    if (result.warnings.isNotEmpty) {
      buffer.writeln('⚠️ WARNINGS:');
      for (final warning in result.warnings) {
        buffer.writeln('  - $warning');
      }
      buffer.writeln('');
    }

    buffer.writeln('📊 Individual Checks:');
    for (final check in result.checks) {
      final status = check.isValid ? '✅' : '❌';
      buffer.writeln(
          '  $status ${check.name}: ${(check.confidence * 100).toInt()}%');
      if (check.errors.isNotEmpty) {
        for (final error in check.errors) {
          buffer.writeln('    - $error');
        }
      }
      if (check.warnings.isNotEmpty) {
        for (final warning in check.warnings) {
          buffer.writeln('    - $warning');
        }
      }
    }

    return buffer.toString();
  }
}

/// Validation result for OCR data
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final List<ValidationCheck> checks;
  final double overallConfidence;
  final bool requiresManualReview;

  const ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.checks,
    required this.overallConfidence,
    required this.requiresManualReview,
  });

  Map<String, dynamic> toJson() => {
        'isValid': isValid,
        'errors': errors,
        'warnings': warnings,
        'checks': checks.map((c) => c.toJson()).toList(),
        'overallConfidence': overallConfidence,
        'requiresManualReview': requiresManualReview,
      };
}

/// Individual validation check
class ValidationCheck {
  final String name;
  final bool isValid;
  final double confidence;
  final List<String> errors;
  final List<String> warnings;

  const ValidationCheck({
    required this.name,
    required this.isValid,
    required this.confidence,
    required this.errors,
    required this.warnings,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'isValid': isValid,
        'confidence': confidence,
        'errors': errors,
        'warnings': warnings,
      };
}

/// Usage examples and integration patterns
class OcrValidationUsageExamples {
  /// Example: Basic validation before database insertion
  static Future<void> basicValidationExample() async {
    final validationService = OcrValidationService();
    final antiHallucinationParser = AntiHallucinationParser();

    // Parse with anti-hallucination measures
    const ocrText = 'your OCR text here...';
    final result = await antiHallucinationParser.parseWithAntiHallucination(
      ocrText,
      '02:00',
      allHours: ['00:00', '01:00', '02:00', '03:00'],
    );

    // Validate before insertion
    final validation = await validationService.validateForInsertion(result);

    if (validation.isValid && !validation.requiresManualReview) {
      print('✅ Data validated successfully - safe to insert');
      // Proceed with database insertion
    } else {
      print('⚠️ Validation issues detected - manual review required');
      print(validationService.generateValidationReport(validation));
    }
  }

  /// Example: With bounding box validation
  static Future<void> boundingBoxValidationExample() async {
    final validationService = OcrValidationService();
    final antiHallucinationParser = AntiHallucinationParser();

    // OCR result with bounding box data
    final result = await antiHallucinationParser.parseWithAntiHallucination(
      'OCR text...',
      '02:00',
      boundingBoxData: {
        'cells': [
          {
            'text': '1500',
            'bounds': {'x': 100, 'y': 200, 'width': 50, 'height': 20},
          }
        ]
      },
    );

    // Source image data for comparison
    final sourceImageData = {
      'expectedBounds': [
        {'x': 95, 'y': 195, 'width': 60, 'height': 25},
      ],
      'imageWidth': 800,
      'imageHeight': 600,
    };

    final validation = await validationService.validateForInsertion(
      result,
      sourceImageData: sourceImageData,
    );

    print(validationService.generateValidationReport(validation));
  }

  /// Example: Integration with Riverpod state management
  static Future<void> riverpodIntegrationExample() async {
    // This would integrate with your existing Riverpod providers
    // Example implementation:

    /*
    class OcrValidationNotifier extends StateNotifier<ValidationState> {
      final OcrValidationService _validationService = OcrValidationService();
      
      Future<void> validateAndInsert(AntiHallucinationResult result) async {
        state = ValidationState.loading();
        
        try {
          final validation = await _validationService.validateForInsertion(result);
          
          if (validation.isValid) {
            // Insert into database
            await _databaseService.insertHourlyReading(result.hourlyReading);
            state = ValidationState.success(result.hourlyReading);
          } else {
            state = ValidationState.validationFailed(validation);
          }
        } catch (e) {
          state = ValidationState.error(e.toString());
        }
      }
    }
    */
  }
}
