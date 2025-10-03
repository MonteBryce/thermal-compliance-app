import 'package:flutter/foundation.dart';
import '../models/hourly_reading_models.dart';
import '../models/ocr_result.dart' as ocr_result;
import 'intelligent_ocr_parser.dart';
import 'table_log_parser.dart';

/// Intelligent fallback handler for OCR parsing failures
/// Provides multiple fallback strategies when primary parsing fails
class OcrFallbackHandler {
  static final _instance = OcrFallbackHandler._internal();
  factory OcrFallbackHandler() => _instance;
  OcrFallbackHandler._internal();

  /// Handle OCR parsing with intelligent fallback strategies
  ///
  /// [ocrText] - Raw OCR output
  /// [targetHour] - Target hour to extract
  /// [fallbackLevel] - How aggressive to be with fallbacks
  ///
  /// Returns best possible [HourlyReading] with fallback metadata
  Future<HourlyReadingWithFallback> handleWithFallback(
    String ocrText,
    String targetHour, {
    FallbackLevel fallbackLevel = FallbackLevel.aggressive,
  }) async {
    try {
      debugPrint(
          '🔄 Starting OCR parsing with fallback handling for hour: $targetHour');

      // Step 1: Try primary intelligent parsing
      final intelligentParser = IntelligentOcrParser();
      final primaryResult =
          await intelligentParser.parseIntelligently(ocrText, targetHour);

      // Step 2: Check if primary result is acceptable
      if (_isAcceptableResult(primaryResult, fallbackLevel)) {
        debugPrint('✅ Primary parsing successful, no fallback needed');
        return HourlyReadingWithFallback(
          reading: primaryResult,
          fallbackStrategy: FallbackStrategy.none,
          fallbackReason: null,
          confidence: primaryResult.overallConfidence,
        );
      }

      // Step 3: Apply fallback strategies based on level
      final fallbackResult = await _applyFallbackStrategies(
        ocrText,
        targetHour,
        primaryResult,
        fallbackLevel,
      );

      debugPrint(
          '🔄 Fallback applied: ${fallbackResult.fallbackStrategy.name}');
      return fallbackResult;
    } catch (e, stackTrace) {
      debugPrint('❌ Fallback handling error: $e');
      debugPrint('Stack trace: $stackTrace');

      // Ultimate fallback: return empty reading with error info
      return HourlyReadingWithFallback(
        reading: _createEmptyReading(targetHour, ocrText, 'Fallback error: $e'),
        fallbackStrategy: FallbackStrategy.error,
        fallbackReason: 'Exception during fallback handling: $e',
        confidence: 0.0,
      );
    }
  }

  /// Check if a parsing result is acceptable based on fallback level
  bool _isAcceptableResult(HourlyReading result, FallbackLevel level) {
    debugPrint(
        '🔍 Checking acceptability: confidence=${(result.overallConfidence * 100).toInt()}%, validFields=${result.validFieldCount}, level=$level');

    switch (level) {
      case FallbackLevel.conservative:
        // Require high confidence and most required fields
        final acceptable =
            result.overallConfidence >= 0.8 && result.validFieldCount >= 6;
        debugPrint(
            '🔍 Conservative check: $acceptable (need >=80% confidence, >=6 fields)');
        return acceptable;

      case FallbackLevel.moderate:
        // Require moderate confidence and some required fields
        final acceptable =
            result.overallConfidence >= 0.6 && result.validFieldCount >= 4;
        debugPrint(
            '🔍 Moderate check: $acceptable (need >=60% confidence, >=4 fields)');
        return acceptable;

      case FallbackLevel.aggressive:
        // Accept any result with some valid fields
        final acceptable =
            result.overallConfidence >= 0.3 && result.validFieldCount >= 2;
        debugPrint(
            '🔍 Aggressive check: $acceptable (need >=30% confidence, >=2 fields)');
        return acceptable;
    }
  }

  /// Apply fallback strategies in order of preference
  Future<HourlyReadingWithFallback> _applyFallbackStrategies(
    String ocrText,
    String targetHour,
    HourlyReading primaryResult,
    FallbackLevel level,
  ) async {
    final strategies = _getFallbackStrategies(level);

    for (final strategy in strategies) {
      try {
        final fallbackResult =
            await _applyStrategy(strategy, ocrText, targetHour);

        if (_isAcceptableResult(fallbackResult, level)) {
          return HourlyReadingWithFallback(
            reading: fallbackResult,
            fallbackStrategy: strategy,
            fallbackReason: _getFallbackReason(strategy, primaryResult),
            confidence: fallbackResult.overallConfidence,
          );
        }
      } catch (e) {
        debugPrint('❌ Fallback strategy ${strategy.name} failed: $e');
      }
    }

    // If all fallbacks fail, return the best available result
    return _getBestAvailableResult(ocrText, targetHour, primaryResult);
  }

  /// Get fallback strategies based on level
  List<FallbackStrategy> _getFallbackStrategies(FallbackLevel level) {
    switch (level) {
      case FallbackLevel.conservative:
        return [
          FallbackStrategy.textPreprocessing,
          FallbackStrategy.patternMatching,
        ];

      case FallbackLevel.moderate:
        return [
          FallbackStrategy.textPreprocessing,
          FallbackStrategy.patternMatching,
          FallbackStrategy.fieldExtraction,
          FallbackStrategy.templateMatching,
        ];

      case FallbackLevel.aggressive:
        return [
          FallbackStrategy.textPreprocessing,
          FallbackStrategy.patternMatching,
          FallbackStrategy.fieldExtraction,
          FallbackStrategy.templateMatching,
          FallbackStrategy.heuristicGuessing,
          FallbackStrategy.partialExtraction,
          FallbackStrategy.forcedTableParsing,
        ];
    }
  }

  /// Apply a specific fallback strategy
  Future<HourlyReading> _applyStrategy(
    FallbackStrategy strategy,
    String ocrText,
    String targetHour,
  ) async {
    switch (strategy) {
      case FallbackStrategy.textPreprocessing:
        return await _applyTextPreprocessing(ocrText, targetHour);

      case FallbackStrategy.patternMatching:
        return await _applyPatternMatching(ocrText, targetHour);

      case FallbackStrategy.fieldExtraction:
        return await _applyFieldExtraction(ocrText, targetHour);

      case FallbackStrategy.templateMatching:
        return await _applyTemplateMatching(ocrText, targetHour);

      case FallbackStrategy.heuristicGuessing:
        return await _applyHeuristicGuessing(ocrText, targetHour);

      case FallbackStrategy.partialExtraction:
        return await _applyPartialExtraction(ocrText, targetHour);

      case FallbackStrategy.forcedTableParsing:
        return await _applyForcedTableParsing(ocrText, targetHour);

      case FallbackStrategy.none:
      case FallbackStrategy.error:
        return _createEmptyReading(targetHour, ocrText, 'Invalid strategy');
    }
  }

  /// Strategy 1: Enhanced text preprocessing
  Future<HourlyReading> _applyTextPreprocessing(
      String ocrText, String targetHour) async {
    debugPrint('🔄 Applying text preprocessing fallback');

    // Apply aggressive text cleaning
    final cleanedText = _aggressiveTextCleaning(ocrText);

    // Try parsing with cleaned text
    final intelligentParser = IntelligentOcrParser();
    return await intelligentParser.parseIntelligently(cleanedText, targetHour);
  }

  /// Strategy 2: Pattern-based matching
  Future<HourlyReading> _applyPatternMatching(
      String ocrText, String targetHour) async {
    debugPrint('🔄 Applying pattern matching fallback');

    // Extract all numeric patterns and try to map them to fields
    final fieldMatches = <FieldMatch>[];
    final lines = ocrText.split('\n');

    // Define patterns for common field types
    final patterns = {
      'vaporInletFpm':
          RegExp(r'\b(\d{3,4})\s*(?:FPM|fpm|flow)\b', caseSensitive: false),
      'exhaustTempF': RegExp(r'\b(\d{3,4})\s*(?:°?F|temp|temperature)\b',
          caseSensitive: false),
      'inletPpm':
          RegExp(r'\b(\d+\.?\d*)\s*(?:PPM|ppm|inlet)\b', caseSensitive: false),
      'outletPpm':
          RegExp(r'\b(\d+\.?\d*)\s*(?:PPM|ppm|outlet)\b', caseSensitive: false),
      'spherePressurePsi': RegExp(r'\b(\d+\.?\d*)\s*(?:PSI|psi|pressure)\b',
          caseSensitive: false),
      'totalizerScf': RegExp(r'\b(\d{6,9})\s*(?:SCF|scf|totalizer)\b',
          caseSensitive: false),
    };

    for (final entry in patterns.entries) {
      final fieldName = entry.key;
      final pattern = entry.value;

      for (final line in lines) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final value = _parseNumericValue(match.group(1)!);
          if (value != null) {
            fieldMatches.add(FieldMatch(
              name: fieldName,
              value: value,
              confidence: 0.7, // Moderate confidence for pattern matching
              rawMatch: match.group(0)!,
              position: 0,
              type: _inferFieldType(fieldName, value),
              unit: _getFieldUnit(fieldName),
              validation:
                  const ValidationResult(isValid: true, errors: [], warnings: []),
            ));
            break; // Take first match for each field
          }
        }
      }
    }

    return HourlyReading(
      inspectionTime: targetHour,
      overallConfidence: fieldMatches.isNotEmpty ? 0.6 : 0.0,
      fieldMatches: fieldMatches,
      parsedAt: DateTime.now(),
      rawOcrText: ocrText,
    );
  }

  /// Strategy 3: Field extraction from OCR result
  Future<HourlyReading> _applyFieldExtraction(
      String ocrText, String targetHour) async {
    debugPrint('🔄 Applying field extraction fallback');

    // Use the existing OCR field extraction patterns
    final extractedFields = ocr_result.FieldDataPatterns.extractFields(ocrText);

    // Map extracted fields to hourly reading format
    final fieldMatches = extractedFields.map((field) {
      return FieldMatch(
        name: _mapFieldName(field.fieldName),
        value: field.typedValue,
        confidence:
            field.confidence * 0.8, // Slightly lower confidence for fallback
        rawMatch: field.value,
        position: 0,
        type: _mapFieldType(field.type),
        unit: field.unit,
        validation: const ValidationResult(isValid: true, errors: [], warnings: []),
      );
    }).toList();

    return HourlyReading(
      inspectionTime: targetHour,
      overallConfidence: fieldMatches.isNotEmpty ? 0.5 : 0.0,
      fieldMatches: fieldMatches,
      parsedAt: DateTime.now(),
      rawOcrText: ocrText,
    );
  }

  /// Strategy 4: Template matching
  Future<HourlyReading> _applyTemplateMatching(
      String ocrText, String targetHour) async {
    debugPrint('🔄 Applying template matching fallback');

    // Try to match against known log templates
    final templates = _getLogTemplates();

    for (final template in templates) {
      final matchResult = _matchTemplate(ocrText, template);
      if (matchResult.confidence > 0.5) {
        return _applyTemplateResult(matchResult, targetHour, ocrText);
      }
    }

    return _createEmptyReading(
        targetHour, ocrText, 'No template matches found');
  }

  /// Strategy 5: Heuristic guessing
  Future<HourlyReading> _applyHeuristicGuessing(
      String ocrText, String targetHour) async {
    debugPrint('🔄 Applying heuristic guessing fallback');

    // Extract all numbers and try to guess their meaning based on context
    final numbers = _extractAllNumbers(ocrText);
    final fieldMatches = <FieldMatch>[];

    // Apply heuristics to categorize numbers
    for (final number in numbers) {
      final fieldName = _guessFieldFromValue(number.value, number.context);
      if (fieldName != null) {
        fieldMatches.add(FieldMatch(
          name: fieldName,
          value: number.value,
          confidence: 0.4, // Low confidence for guessing
          rawMatch: number.rawText,
          position: 0,
          type: _inferFieldType(fieldName, number.value),
          unit: _getFieldUnit(fieldName),
          validation: const ValidationResult(
            isValid: true,
            errors: [],
            warnings: ['Value guessed from context'],
          ),
        ));
      }
    }

    return HourlyReading(
      inspectionTime: targetHour,
      overallConfidence: fieldMatches.isNotEmpty ? 0.3 : 0.0,
      fieldMatches: fieldMatches,
      parsedAt: DateTime.now(),
      rawOcrText: ocrText,
    );
  }

  /// Strategy 6: Partial extraction
  Future<HourlyReading> _applyPartialExtraction(
      String ocrText, String targetHour) async {
    debugPrint('🔄 Applying partial extraction fallback');

    // Extract whatever we can find, even if incomplete
    final fieldMatches = <FieldMatch>[];

    // Look for any recognizable patterns
    final allMatches = RegExp(r'\b(\d+\.?\d*)\b').allMatches(ocrText);

    for (final match in allMatches) {
      final value = double.tryParse(match.group(1)!);
      if (value != null && value > 0) {
        // Try to infer field type from surrounding text
        final context = _getContextAroundMatch(ocrText, match.start, 20);
        final fieldName = _inferFieldFromContext(context, value);

        if (fieldName != null) {
          fieldMatches.add(FieldMatch(
            name: fieldName,
            value: value,
            confidence: 0.3, // Very low confidence for partial extraction
            rawMatch: match.group(0)!,
            position: match.start,
            type: _inferFieldType(fieldName, value),
            unit: _getFieldUnit(fieldName),
            validation: const ValidationResult(
              isValid: true,
              errors: [],
              warnings: ['Partially extracted value'],
            ),
          ));
        }
      }
    }

    return HourlyReading(
      inspectionTime: targetHour,
      overallConfidence: fieldMatches.isNotEmpty ? 0.2 : 0.0,
      fieldMatches: fieldMatches,
      parsedAt: DateTime.now(),
      rawOcrText: ocrText,
    );
  }

  /// Strategy 7: Force table parsing for noisy OCR text
  Future<HourlyReading> _applyForcedTableParsing(
      String ocrText, String targetHour) async {
    debugPrint('🔄 Applying forced table parsing fallback');

    try {
      // Force the use of TableLogParser regardless of format detection
      final tableParser = TableLogParser();
      final targetHourIndex = _parseHourToIndex(targetHour);

      if (targetHourIndex == -1) {
        return _createEmptyReading(targetHour, ocrText, 'Invalid target hour');
      }

      final tableData =
          await tableParser.parseTableForHour(ocrText, targetHourIndex);

      // Convert to HourlyReading format using the same logic as IntelligentOcrParser
      final fieldMatches = tableData.data.entries.map((entry) {
        final fieldName = entry.key;
        final value = entry.value;
        final confidence = tableData.fieldConfidences[fieldName] ?? 0.5;

        return FieldMatch(
          name: fieldName,
          value: value,
          confidence: confidence,
          rawMatch: value.toString(),
          position: 0,
          type: _inferFieldType(fieldName, value),
          unit: _getFieldUnit(fieldName),
          validation: const ValidationResult(isValid: true, errors: [], warnings: []),
        );
      }).toList();

      return HourlyReading.fromFieldMatches(targetHour, fieldMatches, ocrText);
    } catch (e) {
      debugPrint('❌ Forced table parsing failed: $e');
      return _createEmptyReading(
          targetHour, ocrText, 'Forced table parsing failed: $e');
    }
  }

  /// Helper methods
  String _aggressiveTextCleaning(String text) {
    return text
        .replaceAll(RegExp(r'[^\w\s\d\.\:\-]'), ' ') // Remove special chars
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .replaceAll(RegExp(r'[oO](?=\d)'), '0') // Fix OCR errors
        .replaceAll(RegExp(r'[Il\|](?=\d)'), '1')
        .trim();
  }

  double? _parseNumericValue(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^\d\.\-]'), '');
    return double.tryParse(cleaned);
  }

  String _mapFieldName(String ocrFieldName) {
    final name = ocrFieldName.toLowerCase();
    if (name.contains('temp') || name.contains('temperature')) {
      return 'exhaustTempF';
    }
    if (name.contains('flow') || name.contains('fpm')) return 'vaporInletFpm';
    if (name.contains('ppm')) return 'inletPpm';
    if (name.contains('pressure') || name.contains('psi')) {
      return 'spherePressurePsi';
    }
    if (name.contains('totalizer') || name.contains('scf')) {
      return 'totalizerScf';
    }
    return ocrFieldName.toLowerCase().replaceAll(' ', '');
  }

  FieldType _mapFieldType(ocr_result.FieldType ocrType) {
    switch (ocrType) {
      case ocr_result.FieldType.temperature:
        return FieldType.temperature;
      case ocr_result.FieldType.pressure:
        return FieldType.pressure;
      case ocr_result.FieldType.flowRate:
        return FieldType.flowRate;
      case ocr_result.FieldType.ppm:
        return FieldType.concentration;
      case ocr_result.FieldType.hour:
        return FieldType.time;
      case ocr_result.FieldType.time:
        return FieldType.time;
      case ocr_result.FieldType.text:
      default:
        return FieldType.text;
    }
  }

  FieldType _inferFieldType(String fieldName, dynamic value) {
    if (fieldName.contains('temp') || fieldName.contains('Temp')) {
      return FieldType.temperature;
    }
    if (fieldName.contains('pressure') || fieldName.contains('Pressure')) {
      return FieldType.pressure;
    }
    if (fieldName.contains('flow') || fieldName.contains('Flow')) {
      return FieldType.flowRate;
    }
    if (fieldName.contains('ppm') || fieldName.contains('PPM')) {
      return FieldType.concentration;
    }
    if (fieldName.contains('totalizer') || fieldName.contains('Totalizer')) {
      return FieldType.totalizer;
    }
    if (value is num) {
      return FieldType.numeric;
    }
    return FieldType.text;
  }

  String _getFieldUnit(String fieldName) {
    if (fieldName.contains('temp') || fieldName.contains('Temp')) {
      return '°F';
    }
    if (fieldName.contains('pressure') || fieldName.contains('Pressure')) {
      return 'PSI';
    }
    if (fieldName.contains('flow') || fieldName.contains('Flow')) {
      return 'FPM';
    }
    if (fieldName.contains('ppm') || fieldName.contains('PPM')) {
      return 'PPM';
    }
    if (fieldName.contains('totalizer') || fieldName.contains('Totalizer')) {
      return 'SCF';
    }
    return '';
  }

  int _parseHourToIndex(String hour) {
    final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(hour);
    if (match == null) return -1;

    final hourInt = int.tryParse(match.group(1) ?? '');
    final minuteInt = int.tryParse(match.group(2) ?? '');

    if (hourInt == null || minuteInt == null) return -1;
    if (hourInt < 0 || hourInt > 23 || minuteInt < 0 || minuteInt > 59) {
      return -1;
    }

    return hourInt;
  }

  List<LogTemplate> _getLogTemplates() {
    // Define common log templates
    return [
      LogTemplate(
        name: 'Standard Table',
        patterns: [
          RegExp(r'\d{1,2}:\d{2}'),
          RegExp(r'Vapor.*Flow'),
          RegExp(r'Exhaust.*Temp'),
        ],
        confidence: 0.8,
      ),
      LogTemplate(
        name: 'Column Format',
        patterns: [
          RegExp(r'Time.*\d{1,2}:\d{2}'),
          RegExp(r'Flow.*\d+'),
          RegExp(r'Temp.*\d+'),
        ],
        confidence: 0.7,
      ),
    ];
  }

  TemplateMatchResult _matchTemplate(String text, LogTemplate template) {
    int matches = 0;
    for (final pattern in template.patterns) {
      if (pattern.hasMatch(text)) {
        matches++;
      }
    }

    final confidence =
        (matches / template.patterns.length) * template.confidence;
    return TemplateMatchResult(template: template, confidence: confidence);
  }

  HourlyReading _applyTemplateResult(
      TemplateMatchResult result, String targetHour, String ocrText) {
    // Apply template-specific parsing logic
    // This is a simplified implementation
    return HourlyReading(
      inspectionTime: targetHour,
      overallConfidence: result.confidence,
      fieldMatches: [],
      parsedAt: DateTime.now(),
      rawOcrText: ocrText,
    );
  }

  List<NumberMatch> _extractAllNumbers(String text) {
    final matches = RegExp(r'\b(\d+\.?\d*)\b').allMatches(text);
    return matches.map((match) {
      final context = _getContextAroundMatch(text, match.start, 30);
      return NumberMatch(
        value: double.parse(match.group(1)!),
        rawText: match.group(0)!,
        context: context,
        position: match.start,
      );
    }).toList();
  }

  String? _guessFieldFromValue(double value, String context) {
    // Apply heuristics based on value ranges and context
    if (value >= 1000 &&
        value <= 2000 &&
        context.toLowerCase().contains('temp')) {
      return 'exhaustTempF';
    }
    if (value >= 1000 &&
        value <= 10000 &&
        context.toLowerCase().contains('flow')) {
      return 'vaporInletFpm';
    }
    if (value >= 100 &&
        value <= 1000 &&
        context.toLowerCase().contains('ppm')) {
      return 'inletPpm';
    }
    if (value >= 1000000 && context.toLowerCase().contains('totalizer')) {
      return 'totalizerScf';
    }
    return null;
  }

  String _getContextAroundMatch(String text, int position, int contextSize) {
    final start = (position - contextSize).clamp(0, text.length);
    final end = (position + contextSize).clamp(0, text.length);
    return text.substring(start, end);
  }

  String? _inferFieldFromContext(String context, double value) {
    final lowerContext = context.toLowerCase();

    if (lowerContext.contains('temp') || lowerContext.contains('°f')) {
      return 'exhaustTempF';
    }
    if (lowerContext.contains('flow') || lowerContext.contains('fpm')) {
      return 'vaporInletFpm';
    }
    if (lowerContext.contains('ppm')) {
      return 'inletPpm';
    }
    if (lowerContext.contains('pressure') || lowerContext.contains('psi')) {
      return 'spherePressurePsi';
    }
    if (lowerContext.contains('totalizer') || lowerContext.contains('scf')) {
      return 'totalizerScf';
    }

    return null;
  }

  String _getFallbackReason(
      FallbackStrategy strategy, HourlyReading primaryResult) {
    switch (strategy) {
      case FallbackStrategy.textPreprocessing:
        return 'Applied text preprocessing due to low OCR quality';
      case FallbackStrategy.patternMatching:
        return 'Used pattern matching due to poor structure recognition';
      case FallbackStrategy.fieldExtraction:
        return 'Extracted individual fields due to parsing failures';
      case FallbackStrategy.templateMatching:
        return 'Applied template matching for structured data';
      case FallbackStrategy.heuristicGuessing:
        return 'Used heuristic guessing for incomplete data';
      case FallbackStrategy.partialExtraction:
        return 'Performed partial extraction of available data';
      case FallbackStrategy.forcedTableParsing:
        return 'Forced table parsing for noisy OCR text';
      case FallbackStrategy.none:
        return 'No fallback applied';
      case FallbackStrategy.error:
        return 'Error occurred during fallback processing';
    }
  }

  HourlyReadingWithFallback _getBestAvailableResult(
    String ocrText,
    String targetHour,
    HourlyReading primaryResult,
  ) {
    // Return the best available result, even if not ideal
    return HourlyReadingWithFallback(
      reading: primaryResult,
      fallbackStrategy: FallbackStrategy.partialExtraction,
      fallbackReason: 'Using best available result despite low confidence',
      confidence: primaryResult.overallConfidence,
    );
  }

  HourlyReading _createEmptyReading(
      String targetHour, String rawText, String reason) {
    return HourlyReading(
      inspectionTime: targetHour,
      overallConfidence: 0.0,
      fieldMatches: [],
      parsedAt: DateTime.now(),
      rawOcrText: rawText,
    );
  }
}

/// Supporting classes
enum FallbackLevel {
  conservative, // Only use high-confidence fallbacks
  moderate, // Use moderate fallbacks
  aggressive, // Use all available fallbacks
}

enum FallbackStrategy {
  none,
  textPreprocessing,
  patternMatching,
  fieldExtraction,
  templateMatching,
  heuristicGuessing,
  partialExtraction,
  forcedTableParsing,
  error,
}

class HourlyReadingWithFallback {
  final HourlyReading reading;
  final FallbackStrategy fallbackStrategy;
  final String? fallbackReason;
  final double confidence;

  const HourlyReadingWithFallback({
    required this.reading,
    required this.fallbackStrategy,
    this.fallbackReason,
    required this.confidence,
  });
}

class LogTemplate {
  final String name;
  final List<RegExp> patterns;
  final double confidence;

  const LogTemplate({
    required this.name,
    required this.patterns,
    required this.confidence,
  });
}

class TemplateMatchResult {
  final LogTemplate template;
  final double confidence;

  const TemplateMatchResult({
    required this.template,
    required this.confidence,
  });
}

class NumberMatch {
  final double value;
  final String rawText;
  final String context;
  final int position;

  const NumberMatch({
    required this.value,
    required this.rawText,
    required this.context,
    required this.position,
  });
}
