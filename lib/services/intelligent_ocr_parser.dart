import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/hourly_reading_models.dart';
import '../models/table_log_models.dart';
import '../models/ocr_result.dart' as ocr_result;
import 'table_log_parser.dart';
import 'hourly_log_parser.dart';

/// Intelligent OCR parser that combines table structure recognition with fallback handling
/// Automatically detects table format vs. free-form and applies appropriate parsing strategy
class IntelligentOcrParser {
  static final _instance = IntelligentOcrParser._internal();
  factory IntelligentOcrParser() => _instance;
  IntelligentOcrParser._internal();

  /// Parse OCR text with intelligent format detection
  ///
  /// [ocrText] - Raw OCR output
  /// [targetHour] - Target hour to extract (e.g., "00:00", "01:00")
  /// [preferredFormat] - Preferred parsing strategy (auto-detected if null)
  ///
  /// Returns structured [HourlyReading] with confidence metrics
  Future<HourlyReading> parseIntelligently(
    String ocrText,
    String targetHour, {
    ParsingStrategy? preferredFormat,
  }) async {
    try {
      debugPrint('🧠 Starting intelligent OCR parsing for hour: $targetHour');
      debugPrint('📄 Raw OCR text: $ocrText');

      // FORCE TABLE PARSING for your log format
      // Since your logs are always table-structured, bypass format detection
      debugPrint('🎯 FORCING table-structured parsing for your log format');

      final tableParser = TableLogParser();
      final targetHourIndex = _getHourIndex(targetHour);

      if (targetHourIndex == -1) {
        debugPrint('❌ Invalid target hour: $targetHour');
        return _createEmptyReading(targetHour, ocrText, 'Invalid target hour');
      }

      debugPrint('🔍 Parsing table for hour index: $targetHourIndex');
      final tableData =
          await tableParser.parseTableForHour(ocrText, targetHourIndex);

      // Convert to HourlyReading format
      final result =
          _convertTableDataToHourlyReading(tableData, targetHour, ocrText);

      debugPrint(
          '✅ Table parsing complete: ${result.validFieldCount} valid fields, ${(result.overallConfidence * 100).toInt()}% confidence');

      return result;
    } catch (e, stackTrace) {
      debugPrint('❌ Table parsing error: $e');
      debugPrint('Stack trace: $stackTrace');
      return _createEmptyReading(
          targetHour, ocrText, 'Table parsing error: $e');
    }
  }

  /// Analyze text structure to determine format type
  Future<FormatAnalysis> _analyzeTextStructure(String ocrText) async {
    final lines =
        ocrText.split('\n').where((line) => line.trim().isNotEmpty).toList();

    // Calculate various metrics
    final metrics = _calculateTextMetrics(lines);

    // Detect format based on metrics
    final formatType = _detectFormatType(metrics);
    final confidence = _calculateFormatConfidence(metrics, formatType);

    return FormatAnalysis(
      formatType: formatType,
      confidence: confidence,
      metrics: metrics,
      lineCount: lines.length,
    );
  }

  /// Calculate text structure metrics
  TextMetrics _calculateTextMetrics(List<String> lines) {
    if (lines.isEmpty) {
      return const TextMetrics(
        avgLineLength: 0,
        lineLengthVariance: 0,
        timeColumnCount: 0,
        numericColumnCount: 0,
        hasConsistentSpacing: false,
        hasTimeHeaders: false,
        hasFieldLabels: false,
      );
    }

    // Calculate line length statistics
    final lineLengths = lines.map((line) => line.length).toList();
    final avgLineLength =
        lineLengths.reduce((a, b) => a + b) / lineLengths.length;
    final variance = lineLengths
            .map((len) => math.pow(len - avgLineLength, 2))
            .reduce((a, b) => a + b) /
        lineLengths.length;

    // Count time columns
    int timeColumnCount = 0;
    int numericColumnCount = 0;
    bool hasTimeHeaders = false;
    bool hasFieldLabels = false;

    for (final line in lines) {
      // Check for time patterns (including OCR errors)
      // Look for both HH:MM format and HHMM format (like 0000, 0100, etc.)
      final timeMatches = RegExp(r'[O0l1]{1,2}:[O0l1]{2}').allMatches(line);
      final hourMatches =
          RegExp(r'\b[O0l1]{4}\b').allMatches(line); // 0000, 0100, etc.

      final totalTimeMatches = timeMatches.length + hourMatches.length;
      timeColumnCount = math.max(timeColumnCount, totalTimeMatches);

      // Consider it a time header if there are multiple time columns in one line
      // (indicating a table header row) - be more lenient for table detection
      if (totalTimeMatches >= 2) {
        hasTimeHeaders = true;
      }

      // Check for numeric columns
      final numericMatches = RegExp(r'\b\d+\.?\d*\b').allMatches(line);
      numericColumnCount = math.max(numericColumnCount, numericMatches.length);

      // Check for field labels (including OCR errors)
      // Add more specific patterns for your log format
      if (RegExp(
              r'(temperature|pressure|flow|ppm|totalizer|inlet|outlet|vap0r|d1lut1on|combust1on|exhaust|presure|1nlet|0utlet|t0tal1zer|hour|vapor|dilution|combustion|sphere|inspection|operator|initial)',
              caseSensitive: false)
          .hasMatch(line)) {
        hasFieldLabels = true;
      }

      // Check for key-value pair patterns (like "Field: Value")
      if (RegExp(r'[A-Za-z\s]+:\s*\d+').hasMatch(line)) {
        hasFieldLabels = true;
      }

      // Check for your specific log field patterns
      if (RegExp(
              r'(VAPOR|DILUTION|COMBUSTION|EXHAUST|SPHERE|INLET|OUTLET|TOTALIZER)',
              caseSensitive: false)
          .hasMatch(line)) {
        hasFieldLabels = true;
      }
    }

    // Check for consistent spacing (table indicator)
    bool hasConsistentSpacing = false;
    if (lines.length > 2) {
      final firstLine = lines.first;
      final spacePositions = <int>[];
      for (int i = 0; i < firstLine.length; i++) {
        if (firstLine[i] == ' ') {
          spacePositions.add(i);
        }
      }

      // Check if other lines have similar spacing patterns
      int consistentLines = 0;
      for (int i = 1; i < math.min(5, lines.length); i++) {
        final line = lines[i];
        int matchingSpaces = 0;
        for (final pos in spacePositions) {
          if (pos < line.length && line[pos] == ' ') {
            matchingSpaces++;
          }
        }
        if (matchingSpaces >= spacePositions.length * 0.7) {
          consistentLines++;
        }
      }
      hasConsistentSpacing = consistentLines >= 2;
    }

    return TextMetrics(
      avgLineLength: avgLineLength,
      lineLengthVariance: variance,
      timeColumnCount: timeColumnCount,
      numericColumnCount: numericColumnCount,
      hasConsistentSpacing: hasConsistentSpacing,
      hasTimeHeaders: hasTimeHeaders,
      hasFieldLabels: hasFieldLabels,
    );
  }

  /// Detect format type based on metrics
  FormatType _detectFormatType(TextMetrics metrics) {
    // Table-structured: has time headers, consistent spacing, multiple columns
    // Be more lenient for table detection - your logs have this structure
    if (metrics.hasTimeHeaders &&
        metrics.timeColumnCount >= 2 &&
        metrics.numericColumnCount >= 3) {
      return FormatType.tableStructured;
    }

    // Column-aligned: has time headers but less structured
    if (metrics.hasTimeHeaders && metrics.timeColumnCount >= 2) {
      return FormatType.columnAligned;
    }

    // Free-form: has field labels but no clear time structure
    // Only use free-form if there are NO time headers at all
    if (metrics.hasFieldLabels && !metrics.hasTimeHeaders) {
      return FormatType.freeForm;
    }

    // Default to table-structured for unknown formats with field labels
    // This helps catch edge cases in your log format
    if (metrics.hasFieldLabels) {
      return FormatType.tableStructured;
    }

    // Default to hybrid for truly unknown formats
    return FormatType.hybrid;
  }

  /// Calculate confidence in format detection
  double _calculateFormatConfidence(
      TextMetrics metrics, FormatType formatType) {
    double confidence = 0.5; // Base confidence

    switch (formatType) {
      case FormatType.tableStructured:
        if (metrics.hasTimeHeaders) confidence += 0.2;
        if (metrics.hasConsistentSpacing) confidence += 0.2;
        if (metrics.timeColumnCount >= 5) confidence += 0.1;
        if (metrics.numericColumnCount >= 8) confidence += 0.1;
        break;

      case FormatType.columnAligned:
        if (metrics.hasTimeHeaders) confidence += 0.3;
        if (metrics.timeColumnCount >= 3) confidence += 0.2;
        if (metrics.hasFieldLabels) confidence += 0.1;
        break;

      case FormatType.freeForm:
        if (metrics.hasFieldLabels) confidence += 0.3;
        if (metrics.numericColumnCount >= 3) confidence += 0.2;
        break;

      case FormatType.hybrid:
        confidence = 0.6; // Moderate confidence for hybrid
        break;
    }

    return confidence.clamp(0.0, 1.0);
  }

  /// Select parsing strategy based on format analysis
  ParsingStrategy _selectParsingStrategy(FormatAnalysis analysis) {
    switch (analysis.formatType) {
      case FormatType.tableStructured:
        return ParsingStrategy.tableStructured;
      case FormatType.columnAligned:
        return ParsingStrategy.columnAligned;
      case FormatType.freeForm:
        return ParsingStrategy.freeForm;
      case FormatType.hybrid:
        return ParsingStrategy.hybrid;
    }
  }

  /// Parse as table-structured format
  Future<HourlyReading> _parseAsTable(
      String ocrText, String targetHour, FormatAnalysis analysis) async {
    debugPrint('📊 Parsing as table-structured format');

    // Use the table log parser for structured tables
    final tableParser = TableLogParser();
    final targetHourIndex = _getHourIndex(targetHour);

    if (targetHourIndex == -1) {
      return _createEmptyReading(targetHour, ocrText, 'Invalid target hour');
    }

    final tableData =
        await tableParser.parseTableForHour(ocrText, targetHourIndex);

    // Convert to HourlyReading format
    return _convertTableDataToHourlyReading(tableData, targetHour, ocrText);
  }

  /// Parse as column-aligned format
  Future<HourlyReading> _parseAsColumnAligned(
      String ocrText, String targetHour, FormatAnalysis analysis) async {
    debugPrint('📊 Parsing as column-aligned format');

    // Use the hourly log parser for column-aligned data
    final hourlyParser = HourlyLogParser();
    return await hourlyParser.parseHourlyReading(ocrText, targetHour);
  }

  /// Parse as free-form format
  Future<HourlyReading> _parseAsFreeForm(
      String ocrText, String targetHour, FormatAnalysis analysis) async {
    debugPrint('📊 Parsing as free-form format');

    // Parse key-value pairs from free-form text
    final fieldMatches = _parseKeyValuePairs(ocrText, targetHour);

    return HourlyReading(
      inspectionTime: targetHour,
      overallConfidence: _calculateFieldMatchesConfidence(fieldMatches),
      fieldMatches: fieldMatches,
      parsedAt: DateTime.now(),
      rawOcrText: ocrText,
    );
  }

  /// Parse key-value pairs from free-form text
  List<FieldMatch> _parseKeyValuePairs(String text, String targetHour) {
    final fieldMatches = <FieldMatch>[];
    final lines =
        text.split('\n').where((line) => line.trim().isNotEmpty).toList();

    for (final line in lines) {
      final match = _extractKeyValueFromLine(line);
      if (match != null) {
        fieldMatches.add(match);
      }
    }

    debugPrint(
        '🔍 Extracted ${fieldMatches.length} field matches from free-form text');
    return fieldMatches;
  }

  /// Extract key-value pair from a single line
  FieldMatch? _extractKeyValueFromLine(String line) {
    // Pattern for "Field Name: Value Unit" format
    final keyValuePattern = RegExp(
      r'([^:]+):\s*([0-9]+\.?[0-9]*)\s*([A-Za-z]*)',
      caseSensitive: false,
    );

    final match = keyValuePattern.firstMatch(line);
    if (match == null) return null;

    final fieldName = match.group(1)!.trim();
    final value = match.group(2)!;
    final unit = match.group(3)!.trim();

    // Map field names to our standard field names
    final mappedFieldName = _mapFreeFormFieldName(fieldName);
    if (mappedFieldName == null) return null;

    // Parse the value
    final parsedValue = _parseFreeFormValue(value, unit);
    if (parsedValue == null) return null;

    debugPrint('🔍 Extracted: $mappedFieldName = $parsedValue ($unit)');

    return FieldMatch(
      name: mappedFieldName,
      value: parsedValue,
      confidence: 0.9,
      rawMatch: value,
      position: 0,
      type: _inferFieldType(mappedFieldName, parsedValue),
      unit: unit.isNotEmpty ? unit : _getFieldUnit(mappedFieldName),
      validation: const ValidationResult(isValid: true, errors: [], warnings: []),
    );
  }

  /// Map free-form field names to standard field names
  String? _mapFreeFormFieldName(String fieldName) {
    final normalizedName = fieldName.toLowerCase();

    if (normalizedName.contains('vapor') && normalizedName.contains('flow')) {
      return 'vaporInletFpm';
    }
    if (normalizedName.contains('exhaust') && normalizedName.contains('temp')) {
      return 'exhaustTempF';
    }
    if (normalizedName.contains('inlet') && normalizedName.contains('ppm')) {
      return 'inletPpm';
    }
    if (normalizedName.contains('outlet') && normalizedName.contains('ppm')) {
      return 'outletPpm';
    }
    if (normalizedName.contains('sphere') &&
        normalizedName.contains('pressure')) {
      return 'spherePressurePsi';
    }
    if (normalizedName.contains('totalizer') ||
        normalizedName.contains('reading')) {
      return 'totalizerScf';
    }
    if (normalizedName.contains('hour') || normalizedName.contains('time')) {
      return 'inspectionTime';
    }

    return null;
  }

  /// Parse value from free-form text
  dynamic _parseFreeFormValue(String value, String unit) {
    try {
      if (value.contains('.')) {
        return double.parse(value);
      } else {
        return int.parse(value);
      }
    } catch (e) {
      debugPrint('❌ Failed to parse value: $value');
      return null;
    }
  }

  /// Calculate confidence from field matches
  double _calculateFieldMatchesConfidence(List<FieldMatch> fieldMatches) {
    if (fieldMatches.isEmpty) return 0.0;

    final totalConfidence =
        fieldMatches.map((f) => f.confidence).reduce((a, b) => a + b);
    return totalConfidence / fieldMatches.length;
  }

  /// Parse as hybrid format (combine multiple strategies)
  Future<HourlyReading> _parseAsHybrid(
      String ocrText, String targetHour, FormatAnalysis analysis) async {
    debugPrint('📊 Parsing as hybrid format');

    // Try multiple parsing strategies and combine results
    final results = <HourlyReading>[];

    try {
      final tableResult = await _parseAsTable(ocrText, targetHour, analysis);
      if (tableResult.overallConfidence > 0.3) {
        results.add(tableResult);
      }
    } catch (e) {
      debugPrint('Table parsing failed: $e');
    }

    try {
      final columnResult =
          await _parseAsColumnAligned(ocrText, targetHour, analysis);
      if (columnResult.overallConfidence > 0.3) {
        results.add(columnResult);
      }
    } catch (e) {
      debugPrint('Column parsing failed: $e');
    }

    try {
      final freeFormResult =
          await _parseAsFreeForm(ocrText, targetHour, analysis);
      if (freeFormResult.overallConfidence > 0.3) {
        results.add(freeFormResult);
      }
    } catch (e) {
      debugPrint('Free-form parsing failed: $e');
    }

    if (results.isEmpty) {
      return _createEmptyReading(
          targetHour, ocrText, 'All parsing strategies failed');
    }

    // Combine results, preferring higher confidence values
    return _combineParsingResults(results, targetHour, ocrText);
  }

  /// Post-process parsing result with validation and enhancement
  Future<HourlyReading> _postProcessResult(
    HourlyReading result,
    String ocrText,
    ParsingStrategy strategy,
  ) async {
    // Apply confidence adjustments based on strategy
    double adjustedConfidence = result.overallConfidence;

    switch (strategy) {
      case ParsingStrategy.tableStructured:
        // Table parsing is generally more reliable
        adjustedConfidence = math.min(1.0, adjustedConfidence * 1.1);
        break;
      case ParsingStrategy.columnAligned:
        // Column parsing is moderately reliable
        break;
      case ParsingStrategy.freeForm:
        // Free-form parsing is less reliable
        adjustedConfidence = adjustedConfidence * 0.9;
        break;
      case ParsingStrategy.hybrid:
        // Hybrid parsing can be more reliable due to multiple strategies
        adjustedConfidence = math.min(1.0, adjustedConfidence * 1.05);
        break;
    }

    // Add validation warnings for suspicious values
    final enhancedFieldMatches = result.fieldMatches.map((field) {
      final warnings = <String>[];

      // Check for common OCR errors
      if (field.value is num) {
        final value = field.value as num;

        // Check for unreasonably high values
        if (value > 1000000) {
          warnings.add('Value seems unusually high - possible OCR error');
        }

        // Check for zero values that should be non-zero
        if (value == 0 &&
            ['exhaustTempF', 'vaporInletFpm'].contains(field.name)) {
          warnings.add('Zero value may indicate missing data');
        }
      }

      return FieldMatch(
        name: field.name,
        value: field.value,
        confidence: field.confidence,
        rawMatch: field.rawMatch,
        position: field.position,
        type: field.type,
        unit: field.unit,
        validation: ValidationResult(
          isValid: field.validation.isValid,
          errors: field.validation.errors,
          warnings: [...field.validation.warnings, ...warnings],
        ),
      );
    }).toList();

    // Use fromFieldMatches to properly set the specific field properties
    return HourlyReading.fromFieldMatches(
      result.inspectionTime,
      enhancedFieldMatches,
      result.rawOcrText,
    );
  }

  /// Helper methods
  int _getHourIndex(String targetHour) {
    const hourLabels = TableLogStructure.hourLabels;
    return hourLabels.indexOf(targetHour);
  }

  double _calculateAverageConfidence(List<ocr_result.ExtractedField> fields) {
    if (fields.isEmpty) return 0.0;
    final total = fields.map((f) => f.confidence).reduce((a, b) => a + b);
    return total / fields.length;
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

  HourlyReading _convertTableDataToHourlyReading(
    HourlyTableData tableData,
    String targetHour,
    String ocrText,
  ) {
    final fieldMatches = tableData.data.entries.map((entry) {
      final fieldName = entry.key;
      final value = entry.value;
      final confidence = tableData.fieldConfidences[fieldName] ?? 0.5;

      debugPrint(
          '🔧 Creating FieldMatch: $fieldName = $value (confidence: ${(confidence * 100).toInt()}%)');

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

    debugPrint(
        '🔧 Converting ${fieldMatches.length} field matches to HourlyReading');
    for (final match in fieldMatches) {
      debugPrint('  - ${match.name}: ${match.value} (${match.type})');
    }

    // Use the fromFieldMatches constructor to properly set the specific field properties
    final result =
        HourlyReading.fromFieldMatches(targetHour, fieldMatches, ocrText);

    debugPrint(
        '🔧 HourlyReading created: vaporInletFpm=${result.vaporInletFpm}, exhaustTempF=${result.exhaustTempF}, inletPpm=${result.inletPpm}');

    return result;
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

  HourlyReading _combineParsingResults(
    List<HourlyReading> results,
    String targetHour,
    String ocrText,
  ) {
    // Sort by confidence
    results.sort((a, b) => b.overallConfidence.compareTo(a.overallConfidence));

    // Use the highest confidence result as base
    final baseResult = results.first;

    // Merge field matches from other results if they have higher confidence
    final mergedFields = <String, FieldMatch>{};

    for (final result in results) {
      for (final field in result.fieldMatches) {
        if (!mergedFields.containsKey(field.name) ||
            mergedFields[field.name]!.confidence < field.confidence) {
          mergedFields[field.name] = field;
        }
      }
    }

    return HourlyReading(
      inspectionTime: baseResult.inspectionTime,
      overallConfidence: _calculateCombinedConfidence(results),
      fieldMatches: mergedFields.values.toList(),
      parsedAt: baseResult.parsedAt,
      rawOcrText: baseResult.rawOcrText,
    );
  }

  double _calculateCombinedConfidence(List<HourlyReading> results) {
    if (results.isEmpty) return 0.0;

    // Weighted average based on confidence
    double totalWeightedConfidence = 0.0;
    double totalWeight = 0.0;

    for (int i = 0; i < results.length; i++) {
      final weight =
          1.0 / (i + 1); // Decreasing weight for lower confidence results
      totalWeightedConfidence += results[i].overallConfidence * weight;
      totalWeight += weight;
    }

    return totalWeightedConfidence / totalWeight;
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
enum ParsingStrategy {
  tableStructured,
  columnAligned,
  freeForm,
  hybrid,
}

enum FormatType {
  tableStructured,
  columnAligned,
  freeForm,
  hybrid,
}

class FormatAnalysis {
  final FormatType formatType;
  final double confidence;
  final TextMetrics metrics;
  final int lineCount;

  const FormatAnalysis({
    required this.formatType,
    required this.confidence,
    required this.metrics,
    required this.lineCount,
  });
}

class TextMetrics {
  final double avgLineLength;
  final double lineLengthVariance;
  final int timeColumnCount;
  final int numericColumnCount;
  final bool hasConsistentSpacing;
  final bool hasTimeHeaders;
  final bool hasFieldLabels;

  const TextMetrics({
    required this.avgLineLength,
    required this.lineLengthVariance,
    required this.timeColumnCount,
    required this.numericColumnCount,
    required this.hasConsistentSpacing,
    required this.hasTimeHeaders,
    required this.hasFieldLabels,
  });
}
