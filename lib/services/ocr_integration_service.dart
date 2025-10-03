import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/hourly_reading_models.dart';
import '../models/ocr_result.dart';
import 'ocr_service.dart';
import 'intelligent_ocr_parser.dart';
import 'ocr_fallback_handler.dart';

/// Complete OCR integration service for methane degassing logs
/// Combines image capture, text extraction, intelligent parsing, and fallback handling
class OcrIntegrationService {
  static final _instance = OcrIntegrationService._internal();
  factory OcrIntegrationService() => _instance;
  OcrIntegrationService._internal();

  final OcrService _ocrService = OcrService();
  final IntelligentOcrParser _intelligentParser = IntelligentOcrParser();
  final OcrFallbackHandler _fallbackHandler = OcrFallbackHandler();

  /// Complete OCR workflow: capture image → extract text → parse intelligently → handle fallbacks
  ///
  /// [targetHour] - Target hour to extract data for
  /// [fallbackLevel] - How aggressive to be with fallbacks
  /// [imageSource] - Whether to use camera or gallery
  ///
  /// Returns structured [OcrIntegrationResult] with all metadata
  Future<OcrIntegrationResult> processImageForHour(
    String targetHour, {
    FallbackLevel fallbackLevel = FallbackLevel.aggressive,
    ImageSource imageSource = ImageSource.camera,
  }) async {
    try {
      debugPrint(
          '🚀 Starting complete OCR integration workflow for hour: $targetHour');

      // Step 1: Capture/select image
      final imageFile = await _captureImage(imageSource);
      if (imageFile == null) {
        return OcrIntegrationResult.error('No image selected or captured');
      }

      // Step 2: Extract text from image
      final ocrResult = await _ocrService.extractTextFromImage(imageFile);
      debugPrint(
          '📄 OCR extracted ${ocrResult.extractedFields.length} fields with ${(ocrResult.confidence * 100).toInt()}% confidence');

      // Step 3: Parse intelligently with fallback handling
      final parsingResult = await _fallbackHandler.handleWithFallback(
        ocrResult.rawText,
        targetHour,
        fallbackLevel: fallbackLevel,
      );

      // Step 4: Create comprehensive result
      final integrationResult = OcrIntegrationResult.success(
        hourlyReading: parsingResult.reading,
        ocrResult: ocrResult,
        fallbackInfo: FallbackInfo(
          strategy: parsingResult.fallbackStrategy,
          reason: parsingResult.fallbackReason,
          confidence: parsingResult.confidence,
        ),
        imageFile: imageFile,
        processingTime: DateTime.now(),
      );

      debugPrint(
          '✅ OCR integration complete: ${integrationResult.hourlyReading?.validFieldCount} valid fields');
      return integrationResult;
    } catch (e, stackTrace) {
      debugPrint('❌ OCR integration error: $e');
      debugPrint('Stack trace: $stackTrace');
      return OcrIntegrationResult.error('OCR processing failed: $e');
    }
  }

  /// Process existing OCR text (for testing or manual input)
  Future<OcrIntegrationResult> processOcrText(
    String ocrText,
    String targetHour, {
    FallbackLevel fallbackLevel = FallbackLevel.aggressive,
  }) async {
    try {
      debugPrint('🔄 Processing existing OCR text for hour: $targetHour');

      // Parse intelligently with fallback handling
      final parsingResult = await _fallbackHandler.handleWithFallback(
        ocrText,
        targetHour,
        fallbackLevel: fallbackLevel,
      );

      // Create OCR result from text
      final ocrResult = OcrResult(
        rawText: ocrText,
        scanTimestamp: DateTime.now(),
        extractedFields: [], // Will be populated by parsing
        confidence: parsingResult.confidence,
      );

      debugPrint('🔍 parsingResult.reading: vaporInletFpm=${parsingResult.reading.vaporInletFpm}, exhaustTempF=${parsingResult.reading.exhaustTempF}, inletPpm=${parsingResult.reading.inletPpm}');
      
      return OcrIntegrationResult.success(
        hourlyReading: parsingResult.reading,
        ocrResult: ocrResult,
        fallbackInfo: FallbackInfo(
          strategy: parsingResult.fallbackStrategy,
          reason: parsingResult.fallbackReason,
          confidence: parsingResult.confidence,
        ),
        imageFile: null,
        processingTime: DateTime.now(),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ OCR text processing error: $e');
      debugPrint('Stack trace: $stackTrace');
      return OcrIntegrationResult.error('OCR text processing failed: $e');
    }
  }

  /// Batch process multiple images for different hours
  Future<List<OcrIntegrationResult>> processBatchImages(
    List<BatchImageRequest> requests, {
    FallbackLevel fallbackLevel = FallbackLevel.aggressive,
  }) async {
    debugPrint(
        '📦 Starting batch OCR processing for ${requests.length} images');

    final results = <OcrIntegrationResult>[];

    for (int i = 0; i < requests.length; i++) {
      final request = requests[i];
      debugPrint(
          '📸 Processing image ${i + 1}/${requests.length} for hour: ${request.targetHour}');

      try {
        final result = await processImageForHour(
          request.targetHour,
          fallbackLevel: fallbackLevel,
          imageSource: request.imageSource,
        );
        results.add(result);
      } catch (e) {
        debugPrint(
            '❌ Batch processing error for hour ${request.targetHour}: $e');
        results.add(OcrIntegrationResult.error('Batch processing failed: $e'));
      }
    }

    debugPrint(
        '✅ Batch processing complete: ${results.where((r) => r.isSuccess).length}/${results.length} successful');
    return results;
  }

  /// Validate OCR result quality and provide recommendations
  OcrQualityAssessment assessQuality(OcrIntegrationResult result) {
    if (!result.isSuccess || result.hourlyReading == null) {
      return const OcrQualityAssessment(
        overallScore: 0.0,
        issues: ['OCR processing failed'],
        recommendations: [
          'Try capturing a clearer image',
          'Ensure good lighting'
        ],
        confidence: 0.0,
      );
    }

    final reading = result.hourlyReading!;
    final issues = <String>[];
    final recommendations = <String>[];
    double score = reading.overallConfidence;

    // Check field completeness
    if (reading.validFieldCount < 4) {
      issues.add('Missing required fields (${reading.validFieldCount}/8)');
      recommendations.add('Ensure all field labels are clearly visible');
      score -= 0.2;
    }

    // Check confidence levels
    if (reading.overallConfidence < 0.6) {
      issues.add(
          'Low confidence parsing (${(reading.overallConfidence * 100).toInt()}%)');
      recommendations.add('Improve image quality and lighting');
      score -= 0.3;
    }

    // Check for fallback usage
    if (result.fallbackInfo?.strategy != FallbackStrategy.none) {
      issues
          .add('Fallback strategy used: ${result.fallbackInfo!.strategy.name}');
      recommendations.add('Consider retaking photo for better results');
      score -= 0.1;
    }

    // Check for validation warnings
    final warnings = reading.fieldMatches
        .expand((field) => field.validation.warnings)
        .toList();

    if (warnings.isNotEmpty) {
      issues.add('${warnings.length} validation warnings');
      recommendations.add('Review extracted values for accuracy');
      score -= 0.1;
    }

    // Add positive recommendations for good results
    if (score > 0.8) {
      recommendations.add('Excellent OCR quality - no action needed');
    } else if (score > 0.6) {
      recommendations.add('Good OCR quality - minor improvements possible');
    }

    return OcrQualityAssessment(
      overallScore: score.clamp(0.0, 1.0),
      issues: issues,
      recommendations: recommendations,
      confidence: reading.overallConfidence,
    );
  }

  /// Get usage statistics and performance metrics
  OcrUsageStats getUsageStats() {
    // This would typically track metrics over time
    // For now, return placeholder stats
    return const OcrUsageStats(
      totalProcessed: 0,
      successfulExtractions: 0,
      averageConfidence: 0.0,
      mostCommonFallback: FallbackStrategy.none,
      averageProcessingTime: Duration.zero,
    );
  }

  /// Helper methods
  Future<File?> _captureImage(ImageSource source) async {
    switch (source) {
      case ImageSource.camera:
        return await _ocrService.takePhoto();
      case ImageSource.gallery:
        return await _ocrService.pickFromGallery();
    }
  }
}

/// Result of complete OCR integration workflow
class OcrIntegrationResult {
  final bool isSuccess;
  final HourlyReading? hourlyReading;
  final OcrResult? ocrResult;
  final FallbackInfo? fallbackInfo;
  final File? imageFile;
  final DateTime? processingTime;
  final String? errorMessage;

  const OcrIntegrationResult._({
    required this.isSuccess,
    this.hourlyReading,
    this.ocrResult,
    this.fallbackInfo,
    this.imageFile,
    this.processingTime,
    this.errorMessage,
  });

  factory OcrIntegrationResult.success({
    required HourlyReading hourlyReading,
    required OcrResult ocrResult,
    required FallbackInfo fallbackInfo,
    File? imageFile,
    required DateTime processingTime,
  }) =>
      OcrIntegrationResult._(
        isSuccess: true,
        hourlyReading: hourlyReading,
        ocrResult: ocrResult,
        fallbackInfo: fallbackInfo,
        imageFile: imageFile,
        processingTime: processingTime,
      );

  factory OcrIntegrationResult.error(String message) => OcrIntegrationResult._(
        isSuccess: false,
        errorMessage: message,
      );

  /// Get a summary of the result
  String get summary {
    if (!isSuccess) {
      return 'OCR failed: $errorMessage';
    }

    final reading = hourlyReading!;
    final fallback = fallbackInfo!;

    return 'Extracted ${reading.validFieldCount} fields with ${(reading.overallConfidence * 100).toInt()}% confidence'
        ' (${fallback.strategy.name})';
  }
}

/// Information about fallback strategy used
class FallbackInfo {
  final FallbackStrategy strategy;
  final String? reason;
  final double confidence;

  const FallbackInfo({
    required this.strategy,
    this.reason,
    required this.confidence,
  });
}

/// Quality assessment of OCR results
class OcrQualityAssessment {
  final double overallScore;
  final List<String> issues;
  final List<String> recommendations;
  final double confidence;

  const OcrQualityAssessment({
    required this.overallScore,
    required this.issues,
    required this.recommendations,
    required this.confidence,
  });

  bool get isHighQuality => overallScore >= 0.8;
  bool get needsImprovement => overallScore < 0.6;
}

/// Usage statistics for OCR service
class OcrUsageStats {
  final int totalProcessed;
  final int successfulExtractions;
  final double averageConfidence;
  final FallbackStrategy mostCommonFallback;
  final Duration averageProcessingTime;

  const OcrUsageStats({
    required this.totalProcessed,
    required this.successfulExtractions,
    required this.averageConfidence,
    required this.mostCommonFallback,
    required this.averageProcessingTime,
  });

  double get successRate =>
      totalProcessed > 0 ? successfulExtractions / totalProcessed : 0.0;
}

/// Request for batch image processing
class BatchImageRequest {
  final String targetHour;
  final ImageSource imageSource;

  const BatchImageRequest({
    required this.targetHour,
    required this.imageSource,
  });
}

/// Image source options
enum ImageSource {
  camera,
  gallery,
}
