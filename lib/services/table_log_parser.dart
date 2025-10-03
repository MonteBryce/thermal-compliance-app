import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/table_log_models.dart';

/// Intelligent table-structured OCR parser for methane degassing logs
/// Understands fixed table format: 11 columns (00:00-10:00) x 9 labeled rows
class TableLogParser {
  static final _instance = TableLogParser._internal();
  factory TableLogParser() => _instance;
  TableLogParser._internal();

  /// Parse complete table and extract data for specific hour
  ///
  /// [ocrText] - Raw OCR output containing the full table
  /// [targetHourIndex] - Hour index (0=00:00, 1=01:00, ..., 10=10:00)
  ///
  /// Returns [HourlyTableData] with structured data for the target hour
  Future<HourlyTableData> parseTableForHour(
    String ocrText,
    int targetHourIndex,
  ) async {
    debugPrint(
        '🔍 Parsing table for hour index: $targetHourIndex (${TableLogStructure.hourLabels[targetHourIndex]})');

    try {
      // Step 1: Parse the complete table structure
      final tableResult = await parseCompleteTable(ocrText);
      debugPrint(
          '📊 Table parsing: ${tableResult.rowResults.length} rows found, ${(tableResult.overallConfidence * 100).toInt()}% confidence');

      // Step 2: Extract data for the specific hour
      final hourlyData = tableResult.extractHourData(targetHourIndex);
      debugPrint(
          '✅ Hour ${hourlyData.hourLabel}: ${hourlyData.data.length} fields, ${(hourlyData.confidence * 100).toInt()}% confidence');

      return hourlyData;
    } catch (e, stackTrace) {
      debugPrint('❌ Table parsing error: $e');
      debugPrint('Stack trace: $stackTrace');

      // Return empty data with error indication
      return HourlyTableData(
        hourIndex: targetHourIndex,
        hourLabel: TableLogStructure.hourLabels[targetHourIndex],
        data: {},
        fieldConfidences: {},
        confidence: 0.0,
        extractedAt: DateTime.now(),
      );
    }
  }

  /// Parse the complete table structure from OCR text
  Future<TableParseResult> parseCompleteTable(String ocrText) async {
    debugPrint('🔍 Starting complete table parsing...');

    // Step 1: Preprocess OCR text
    final normalizedText = _preprocessText(ocrText);
    final lines = normalizedText
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    debugPrint('📄 Processing ${lines.length} non-empty lines');
    for (int i = 0; i < lines.length; i++) {
      debugPrint('  Line $i: "${lines[i]}"');
    }

    // Step 2: Parse each row by finding matching labels
    final rowResults = <String, RowParseResult>{};
    const rowDefinitions = TableLogStructure.standardRows;

    for (final entry in rowDefinitions.entries) {
      final fieldName = entry.key;
      final definition = entry.value;

      debugPrint('🔍 Looking for row: ${definition.labels.first}');

      final rowResult = await _parseRowData(lines, definition);
      if (rowResult != null) {
        rowResults[fieldName] = rowResult;
        debugPrint(
            '✅ Found ${definition.labels.first}: ${rowResult.rawValues.length} values, ${(rowResult.confidence * 100).toInt()}% confidence');
      } else {
        debugPrint('❌ Missing row: ${definition.labels.first}');
      }
    }

    // Step 3: Calculate overall confidence and identify missing required fields
    final overallConfidence = _calculateOverallConfidence(rowResults);
    final missingRequired = _findMissingRequiredFields(rowResults);

    debugPrint(
        '📊 Table parsing complete: ${rowResults.length}/${rowDefinitions.length} rows, ${(overallConfidence * 100).toInt()}% confidence');
    if (missingRequired.isNotEmpty) {
      debugPrint('⚠️ Missing required fields: ${missingRequired.join(', ')}');
    }

    return TableParseResult(
      rowResults: rowResults,
      overallConfidence: overallConfidence,
      missingRequiredFields: missingRequired,
      parsedAt: DateTime.now(),
    );
  }

  /// Preprocess OCR text for better parsing
  String _preprocessText(String text) {
    // Split into lines first to preserve structure
    final lines = text.split('\n');
    final processedLines = <String>[];

    for (final line in lines) {
      final processedLine = line
          // Fix common OCR errors first
          .replaceAll(RegExp(r'[oO](?=\d)'), '0') // O -> 0 before digits
          .replaceAll(RegExp(r'[Il\|](?=\d)'), '1') // I,l,| -> 1 before digits
          // Clean up parentheses and special characters
          .replaceAll(RegExp(r'[()[\]{}]'), ' ')
          // Normalize colons
          .replaceAll(RegExp(r':\s*'), ': ')
          // Normalize whitespace but preserve line breaks
          .replaceAll(RegExp(r'[ \t]+'), ' ')
          .trim();

      if (processedLine.isNotEmpty) {
        processedLines.add(processedLine);
      }
    }

    return processedLines.join('\n');
  }

  /// Parse row data with enhanced spatial recognition
  Future<RowParseResult?> _parseRowData(
      List<String> lines, LogRowDefinition definition) async {
    debugPrint('🔍 Parsing row: ${definition.labels.first}');

    // Step 1: Find the row label line(s)
    final rowLineIndices = _findRowLabelLines(lines, definition);
    if (rowLineIndices.isEmpty) {
      debugPrint('❌ No row label found for: ${definition.labels.first}');
      return null;
    }

    debugPrint('📍 Found row at lines: $rowLineIndices');

    // Step 2: Extract values from the row with spatial awareness
    final rawValues = <String>[];
    final valueConfidences = <double>[];

    for (final lineIndex in rowLineIndices) {
      final line = lines[lineIndex];
      debugPrint('📝 Processing line $lineIndex: "$line"');

      // Extract values from this line, handling multi-line rows
      final lineValues = _extractValuesFromLine(line, definition);
      rawValues.addAll(lineValues['values']!);
      valueConfidences.addAll(lineValues['confidences']!);

      // For well-structured tables, each row contains its own data
      // No need for row continuation logic
    }

    if (rawValues.isEmpty) {
      debugPrint('❌ No values extracted for row: ${definition.labels.first}');
      return null;
    }

    debugPrint('📊 Extracted ${rawValues.length} values: $rawValues');

    // Step 3: Parse values according to data type
    final parsedValues = <dynamic>[];
    for (int i = 0; i < rawValues.length; i++) {
      final rawValue = rawValues[i];
      final confidence = valueConfidences[i];

      try {
        final parsed = _parseValue(rawValue, definition.dataType);
        if (parsed != null) {
          parsedValues.add(parsed);
        }
      } catch (e) {
        debugPrint('❌ Failed to parse value "$rawValue": $e');
      }
    }

    // Step 4: Calculate row confidence
    final rowConfidence = _calculateRowConfidence(
        rowLineIndices.length, rawValues.length, valueConfidences);

    debugPrint(
        '✅ Row parsing complete: ${parsedValues.length} parsed values, ${(rowConfidence * 100).toInt()}% confidence');

    return RowParseResult(
      fieldName: definition.fieldName,
      rawValues: rawValues,
      parsedValues: parsedValues,
      confidence: rowConfidence,
      warnings: [], // No warnings for now
      matchedLabel: definition.labels.first,
    );
  }

  /// Find lines containing the row label with fuzzy matching
  List<int> _findRowLabelLines(
      List<String> lines, LogRowDefinition definition) {
    final matchingLines = <int>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Check if this line matches the row definition
      if (definition.matchesRow(line)) {
        matchingLines.add(i);
        debugPrint('✅ Found row label at line $i: "${line.trim()}"');
      }

      // Also check for partial matches in case of OCR line breaks
      if (_hasPartialRowMatch(line, definition)) {
        matchingLines.add(i);
        debugPrint('✅ Found partial row match at line $i: "${line.trim()}"');
      }
    }

    return matchingLines;
  }

  /// Check if line has partial match for row definition
  bool _hasPartialRowMatch(String line, LogRowDefinition definition) {
    final normalizedLine = line.toLowerCase().trim();

    for (final label in definition.labels) {
      final normalizedLabel = label.toLowerCase();
      final words = normalizedLabel.split(' ');

      // Check if line contains at least 60% of the label words
      int matchingWords = 0;
      for (final word in words) {
        if (word.length > 2 && normalizedLine.contains(word)) {
          matchingWords++;
        }
      }

      if (matchingWords >= (words.length * 0.6).ceil()) {
        return true;
      }
    }

    return false;
  }

  /// Check if next line is a continuation of current row
  bool _isRowContinuation(String nextLine, LogRowDefinition definition) {
    // If next line contains field labels, it's NOT a continuation
    final hasFieldLabels = TableLogStructure.standardRows.values.any((def) =>
        def.labels.any(
            (label) => nextLine.toLowerCase().contains(label.toLowerCase())));

    if (hasFieldLabels) {
      return false;
    }

    // Check if this line looks like it belongs to the current row definition
    // by checking if it contains similar patterns or if it's clearly a data line
    final hasNumericValues =
        RegExp(r'\b\d+\.?\d*\b').allMatches(nextLine).length >= 5;
    final hasTimePatterns = RegExp(r'\d{1,2}:\d{2}').hasMatch(nextLine);

    // If it has many numeric values but no time patterns, it might be a continuation
    // But we need to be more conservative to avoid merging different rows
    return hasNumericValues && !hasTimePatterns && nextLine.trim().length > 10;
  }

  /// Extract values from a line with spatial awareness
  Map<String, dynamic> _extractValuesFromLine(
      String line, LogRowDefinition definition) {
    final values = <String>[];
    final confidences = <double>[];

    // Split line by whitespace and extract potential values
    final parts = line.split(RegExp(r'\s+'));

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i].trim();

      // Skip empty parts and likely labels
      if (part.isEmpty || _isLikelyLabel(part, definition)) {
        continue;
      }

      // Check if this part looks like a value
      if (_isLikelyValue(part, definition.dataType)) {
        values.add(part);

        // Calculate confidence based on how "value-like" this part is
        final confidence = _calculateValueConfidence(part, definition.dataType);
        confidences.add(confidence);

        debugPrint(
            '🔍 Extracted value: "$part" (confidence: ${(confidence * 100).toInt()}%)');
      }
    }

    return {'values': values, 'confidences': confidences};
  }

  /// Check if a part is likely a field label (not a value)
  bool _isLikelyLabel(String part, LogRowDefinition definition) {
    final normalizedPart = part.toLowerCase();

    // Check if it matches any of the row labels
    for (final label in definition.labels) {
      final normalizedLabel = label.toLowerCase();
      if (normalizedPart.contains(normalizedLabel) ||
          normalizedLabel.contains(normalizedPart)) {
        return true;
      }
    }

    // Check if it's a common non-numeric word
    final commonWords = [
      'time',
      'hour',
      'temperature',
      'pressure',
      'flow',
      'rate',
      'reading',
      'totalizer'
    ];
    return commonWords.any((word) => normalizedPart.contains(word));
  }

  /// Check if a part looks like a value for the given data type
  bool _isLikelyValue(String part, LogDataType dataType) {
    switch (dataType) {
      case LogDataType.integer:
        return RegExp(r'^\d+$').hasMatch(part) ||
            RegExp(r'^\d+[Oo]$').hasMatch(part) || // Handle OCR errors
            RegExp(r'^[Oo]\d+$').hasMatch(part);
      case LogDataType.decimal:
        return RegExp(r'^\d+\.?\d*$').hasMatch(part) ||
            RegExp(r'^\d+[Oo]\d*$').hasMatch(part) ||
            RegExp(r'^\d*[Oo]\d+$').hasMatch(part);
      case LogDataType.time:
        return RegExp(r'^\d{1,2}[:\.]\d{2}$').hasMatch(part) ||
            RegExp(r'^\d{1,2}[Oo]\d{2}$').hasMatch(part);
      case LogDataType.text:
        return part.isNotEmpty;
    }
  }

  /// Calculate confidence for a value based on data type and OCR quality
  double _calculateValueConfidence(String value, LogDataType dataType) {
    double confidence = 0.5; // Base confidence

    // Check for OCR errors
    final hasOcrErrors =
        RegExp(r'[Oo]').hasMatch(value) || RegExp(r'[l|I]').hasMatch(value);
    if (hasOcrErrors) {
      confidence -= 0.2;
    }

    // Check for reasonable value ranges
    switch (dataType) {
      case LogDataType.integer:
        final intValue = int.tryParse(_cleanOcrErrors(value));
        if (intValue != null) {
          if (intValue >= 0 && intValue <= 10000) confidence += 0.2;
          if (intValue >= 0 && intValue <= 1000) confidence += 0.1;
        }
        break;
      case LogDataType.decimal:
        final doubleValue = double.tryParse(_cleanOcrErrors(value));
        if (doubleValue != null) {
          if (doubleValue >= 0 && doubleValue <= 10000) confidence += 0.2;
          if (doubleValue >= 0 && doubleValue <= 1000) confidence += 0.1;
        }
        break;
      case LogDataType.time:
        if (RegExp(r'^\d{1,2}[:\.]\d{2}$').hasMatch(value)) confidence += 0.3;
        break;
      case LogDataType.text:
        if (value.isNotEmpty) confidence += 0.1;
        break;
    }

    return confidence.clamp(0.0, 1.0);
  }

  /// Calculate overall row confidence
  double _calculateRowConfidence(
      int labelLines, int valueCount, List<double> valueConfidences) {
    if (valueCount == 0) return 0.0;

    // Base confidence from label detection
    double confidence = labelLines > 0 ? 0.6 : 0.3;

    // Add confidence from value quality
    if (valueConfidences.isNotEmpty) {
      final avgValueConfidence =
          valueConfidences.reduce((a, b) => a + b) / valueConfidences.length;
      confidence += avgValueConfidence * 0.3;
    }

    // Penalize for too few or too many values
    if (valueCount < 5) confidence -= 0.1;
    if (valueCount > 15) confidence -= 0.1;

    return confidence.clamp(0.0, 1.0);
  }

  /// Parse raw values according to data type
  _ParseValuesResult _parseValues(
      List<String> rawValues, LogDataType dataType) {
    final parsedValues = <dynamic>[];
    final warnings = <String>[];

    for (final rawValue in rawValues) {
      try {
        final parsed = _parseValue(rawValue.trim(), dataType);
        parsedValues.add(parsed);
      } catch (e) {
        warnings.add('Failed to parse "$rawValue" as ${dataType.name}: $e');
        parsedValues.add(null);
      }
    }

    return _ParseValuesResult(
      rawValues: rawValues,
      parsedValues: parsedValues,
      warnings: warnings,
    );
  }

  /// Parse numeric value with OCR error correction
  /// Handles common OCR errors in numbers: O->0, l->1, etc.
  dynamic _parseValue(String rawValue, LogDataType expectedType) {
    if (rawValue.trim().isEmpty) return null;

    // Clean OCR errors in numeric values
    String cleanedValue = _cleanOcrErrors(rawValue.trim());

    debugPrint(
        '🔧 Parsing value: "$rawValue" -> "$cleanedValue" (type: $expectedType)');

    try {
      switch (expectedType) {
        case LogDataType.integer:
          return int.parse(cleanedValue);
        case LogDataType.decimal:
          return double.parse(cleanedValue);
        case LogDataType.time:
          return _parseTimeValue(cleanedValue);
        case LogDataType.text:
        default:
          return cleanedValue;
      }
    } catch (e) {
      debugPrint('❌ Failed to parse "$cleanedValue" as $expectedType: $e');
      return null;
    }
  }

  /// Clean common OCR errors in numeric values
  String _cleanOcrErrors(String value) {
    // Handle common OCR substitutions in numbers
    String cleaned = value;

    // Replace OCR errors in numbers (but preserve in text)
    cleaned = cleaned
        .replaceAll(
            RegExp(r'\b([0-9]*)[Oo]([0-9]*)\b'), r'$10$2') // O -> 0 in numbers
        .replaceAll(RegExp(r'\b([0-9]*)[l|I]([0-9]*)\b'),
            r'$11$2') // l,I,| -> 1 in numbers
        .replaceAll(
            RegExp(r'\b([0-9]*)[Ss]([0-9]*)\b'), r'$15$2') // S -> 5 in numbers
        .replaceAll(
            RegExp(r'\b([0-9]*)[Gg]([0-9]*)\b'), r'$16$2') // G -> 6 in numbers
        .replaceAll(
            RegExp(r'\b([0-9]*)[Bb]([0-9]*)\b'), r'$18$2') // B -> 8 in numbers
        .replaceAll(
            RegExp(r'\b([0-9]*)[Zz]([0-9]*)\b'), r'$12$2'); // Z -> 2 in numbers

    // Fix decimal points that might be OCR'd as other characters
    cleaned = cleaned
        .replaceAll(RegExp(r'([0-9])[Oo]([0-9])'),
            r'$1.$2') // O between numbers -> decimal
        .replaceAll(RegExp(r'([0-9])[l|I]([0-9])'),
            r'$1.$2'); // l,I between numbers -> decimal

    // Remove any remaining non-numeric characters (except decimal point and minus)
    if (RegExp(r'^[0-9\-\.]+$').hasMatch(cleaned)) {
      return cleaned;
    }

    // If it's not a pure number, try to extract numeric part
    final numericMatch = RegExp(r'([0-9\-\.]+)').firstMatch(cleaned);
    if (numericMatch != null) {
      return numericMatch.group(1)!;
    }

    return value; // Return original if no numeric part found
  }

  /// Parse time value with OCR error handling
  String _parseTimeValue(String timeStr) {
    // Handle common time format OCR errors
    String cleaned = timeStr
        .replaceAll(RegExp(r'[Oo]'), '0') // O -> 0
        .replaceAll(RegExp(r'[l|I]'), '1'); // l,I,| -> 1

    // Extract time pattern
    final timeMatch = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(cleaned);
    if (timeMatch != null) {
      final hour = int.parse(timeMatch.group(1)!);
      final minute = int.parse(timeMatch.group(2)!);
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    }

    return timeStr;
  }

  /// Assess quality of parsed data
  double _assessDataQuality(List<dynamic> values, LogDataType dataType) {
    final nonNullValues = values.where((v) => v != null).toList();
    if (nonNullValues.isEmpty) return 0.0;

    double quality = 0.8; // Base quality

    switch (dataType) {
      case LogDataType.integer:
        // Check if values are reasonable integers
        final intValues = nonNullValues.whereType<int>().toList();
        if (intValues.length == nonNullValues.length) {
          quality += 0.2; // All values are proper integers
        }
        break;

      case LogDataType.decimal:
        // Check if values are reasonable decimals
        final numValues = nonNullValues.whereType<num>().toList();
        if (numValues.length == nonNullValues.length) {
          quality += 0.2; // All values are proper numbers
        }
        break;

      case LogDataType.time:
        // Check if values follow time format
        final timeValues = nonNullValues
            .whereType<String>()
            .where((v) => RegExp(r'^\d{2}:\d{2}$').hasMatch(v))
            .toList();
        if (timeValues.length == nonNullValues.length) {
          quality += 0.2; // All values are proper time format
        }
        break;

      case LogDataType.text:
        quality += 0.1; // Text is generally acceptable
        break;
    }

    return quality.clamp(0.0, 1.0);
  }

  /// Assess consistency of values (no extreme outliers)
  double _assessValueConsistency(List<dynamic> values) {
    final numValues = values.whereType<num>().toList();
    if (numValues.length < 3) return 0.8; // Not enough data to assess

    // Calculate coefficient of variation
    final mean = numValues.reduce((a, b) => a + b) / numValues.length;
    final variance =
        numValues.map((v) => math.pow(v - mean, 2)).reduce((a, b) => a + b) /
            numValues.length;
    final stdDev = math.sqrt(variance);

    if (mean == 0) return 0.8; // Avoid division by zero

    final coefficientOfVariation = stdDev / mean.abs();

    // Lower CV indicates more consistent data
    if (coefficientOfVariation < 0.1) return 1.0; // Very consistent
    if (coefficientOfVariation < 0.3) return 0.8; // Moderately consistent
    if (coefficientOfVariation < 0.5) return 0.6; // Some variation
    return 0.4; // High variation
  }

  /// Assess if values are in expected ranges for the field
  double _assessValueRanges(List<dynamic> values, String fieldName) {
    final numValues = values.whereType<num>().toList();
    if (numValues.isEmpty) return 0.5; // Neutral score for non-numeric

    final expectedRanges = {
      'vaporInletFpm': (0, 10000),
      'dilutionAirFpm': (0, 5000),
      'combustionAirFpm': (0, 5000),
      'exhaustTempF': (500, 2000),
      'spherePressurePsi': (0, 50),
      'inletPpm': (0, 100000),
      'outletPpm': (0, 1000),
      'totalizerScf': (1000, 999999999),
    };

    final range = expectedRanges[fieldName];
    if (range == null) return 0.8; // Default score for unknown fields

    final inRangeCount =
        numValues.where((v) => v >= range.$1 && v <= range.$2).length;
    return inRangeCount / numValues.length;
  }

  /// Calculate overall confidence from individual row results
  double _calculateOverallConfidence(Map<String, RowParseResult> rowResults) {
    if (rowResults.isEmpty) return 0.0;

    final confidences = rowResults.values.map((r) => r.confidence).toList();
    final avgConfidence =
        confidences.reduce((a, b) => a + b) / confidences.length;

    // Bonus for finding required fields
    final requiredFieldsFound = TableLogStructure.standardRows.values
        .where((def) => def.required)
        .where((def) => rowResults.containsKey(def.fieldName))
        .length;

    final totalRequiredFields = TableLogStructure.standardRows.values
        .where((def) => def.required)
        .length;
    final requiredFieldsBonus = requiredFieldsFound / totalRequiredFields * 0.2;

    return (avgConfidence + requiredFieldsBonus).clamp(0.0, 1.0);
  }

  /// Find missing required fields
  List<String> _findMissingRequiredFields(
      Map<String, RowParseResult> rowResults) {
    return TableLogStructure.standardRows.values
        .where((def) => def.required)
        .where((def) => !rowResults.containsKey(def.fieldName))
        .map((def) => def.fieldName)
        .toList();
  }
}

/// Helper class for parse values result
class _ParseValuesResult {
  final List<String> rawValues;
  final List<dynamic> parsedValues;
  final List<String> warnings;

  const _ParseValuesResult({
    required this.rawValues,
    required this.parsedValues,
    required this.warnings,
  });
}
