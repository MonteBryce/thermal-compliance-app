import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/hourly_reading_models.dart';

/// Enterprise-grade OCR parser for methane degassing hourly logs
/// Handles noisy OCR text with spatial column recognition and confidence scoring
class HourlyLogParser {
  static final _instance = HourlyLogParser._internal();
  factory HourlyLogParser() => _instance;
  HourlyLogParser._internal();

  final LogParsingConfig _config = LogParsingConfig.standard;

  /// Parse hourly reading from OCR text for a specific time column
  ///
  /// [ocrText] - Raw OCR output (multi-line string)
  /// [targetHour] - Target hour column (e.g., "00:00", "01:00")
  /// [config] - Optional parsing configuration
  ///
  /// Returns structured [HourlyReading] with confidence metrics
  Future<HourlyReading> parseHourlyReading(
    String ocrText,
    String targetHour, {
    LogParsingConfig? config,
  }) async {
    final parseConfig = config ?? _config;

    try {
      debugPrint('🔍 Parsing OCR for hour: $targetHour');
      debugPrint('📄 OCR text length: ${ocrText.length} chars');

      // Step 1: Preprocess and normalize text
      final normalizedText = _preprocessText(ocrText);

      // Step 2: Find time column positions
      final timePositions = _findTimeColumns(normalizedText);
      debugPrint(
          '⏰ Found ${timePositions.length} time columns: ${timePositions.keys}');

      // Step 3: Locate target hour column
      final targetPosition = _findTargetTimePosition(timePositions, targetHour);
      if (targetPosition == null) {
        debugPrint('❌ Target hour $targetHour not found in OCR text');
        return _createEmptyReading(
            targetHour, ocrText, 'Target hour not found');
      }

      debugPrint(
          '🎯 Target hour $targetHour found at position: $targetPosition');

      // Step 4: Extract column-specific text region
      final columnText =
          _extractColumnText(normalizedText, targetPosition, timePositions);
      debugPrint('📝 Extracted column text (${columnText.length} chars)');

      // Step 5: Parse field values with spatial awareness
      final fieldMatches =
          await _parseFieldValues(columnText, targetPosition, parseConfig);
      debugPrint('📊 Extracted ${fieldMatches.length} field matches');

      // Step 6: Validate and create structured reading
      final reading =
          HourlyReading.fromFieldMatches(targetHour, fieldMatches, ocrText);

      debugPrint(
          '✅ Parsing complete: ${reading.validFieldCount}/${fieldMatches.length} valid fields, confidence: ${(reading.overallConfidence * 100).toInt()}%');

      return reading;
    } catch (e, stackTrace) {
      debugPrint('❌ Parsing error: $e');
      debugPrint('Stack trace: $stackTrace');
      return _createEmptyReading(targetHour, ocrText, 'Parsing error: $e');
    }
  }

  /// Preprocess OCR text for better parsing accuracy
  String _preprocessText(String text) {
    return text
        // Normalize whitespace
        .replaceAll(RegExp(r'\s+'), ' ')
        // Fix common OCR errors
        .replaceAll(RegExp(r'[oO]'), '0') // O -> 0 in numbers
        .replaceAll(RegExp(r'[Il\|]'), '1') // I,l,| -> 1 in numbers
        // Normalize time separators
        .replaceAll(RegExp(r'(\d{1,2})[:\.\-\s](\d{2})'), r'$1:$2')
        // Clean up extra characters
        .replaceAll(RegExp(r'[^\w\s\:\.\-\,]'), ' ')
        .trim();
  }

  /// Find all time column positions in the text
  Map<String, TextPosition> _findTimeColumns(String text) {
    final timePositions = <String, TextPosition>{};
    final lines = text.split('\n');

    // Enhanced time pattern matching with OCR error handling
    final timePatterns = [
      RegExp(r'(\d{1,2}):(\d{2})', caseSensitive: false),
      RegExp(r'(\d{1,2})(\d{2})', caseSensitive: false),
      RegExp(r'(\d{1,2})\s*[:-]\s*(\d{2})', caseSensitive: false),
      // Handle OCR errors: O -> 0, l -> 1
      RegExp(r'([O0l1]{1,2}):([O0l1]{2})', caseSensitive: false),
      RegExp(r'([O0l1]{1,2})([O0l1]{2})', caseSensitive: false),
    ];

    for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex];

      for (final pattern in timePatterns) {
        final matches = pattern.allMatches(line);

        for (final match in matches) {
          // Handle OCR errors in time parsing
          String hourStr = match.group(1) ?? '';
          String minuteStr = match.group(2) ?? '';

          // Fix common OCR errors
          hourStr = hourStr.replaceAll('O', '0').replaceAll('l', '1');
          minuteStr = minuteStr.replaceAll('O', '0').replaceAll('l', '1');

          final hour = int.tryParse(hourStr);
          final minute = int.tryParse(minuteStr);

          if (hour != null &&
              minute != null &&
              hour >= 0 &&
              hour <= 23 &&
              minute >= 0 &&
              minute <= 59) {
            final timeStr =
                '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
            final position = TextPosition(
              line: lineIndex,
              column: match.start,
              absolutePosition:
                  _calculateAbsolutePosition(lines, lineIndex, match.start),
              confidence: _calculateTimeConfidence(match.group(0) ?? '', line),
            );

            // Keep highest confidence position for each time
            if (!timePositions.containsKey(timeStr) ||
                timePositions[timeStr]!.confidence < position.confidence) {
              timePositions[timeStr] = position;
            }
          }
        }
      }
    }

    return timePositions;
  }

  /// Find the target time position with fuzzy matching
  TextPosition? _findTargetTimePosition(
      Map<String, TextPosition> timePositions, String targetHour) {
    // Direct match
    if (timePositions.containsKey(targetHour)) {
      return timePositions[targetHour];
    }

    // Parse target hour for fuzzy matching
    final targetMatch = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(targetHour);
    if (targetMatch == null) return null;

    final targetHourInt = int.parse(targetMatch.group(1)!);
    final targetMinuteInt = int.parse(targetMatch.group(2)!);

    // Find closest match
    TextPosition? bestMatch;
    double bestScore = 0.0;

    for (final entry in timePositions.entries) {
      final timeMatch = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(entry.key);
      if (timeMatch == null) continue;

      final hourInt = int.parse(timeMatch.group(1)!);
      final minuteInt = int.parse(timeMatch.group(2)!);

      // Calculate similarity score
      final hourDiff = (hourInt - targetHourInt).abs();
      final minuteDiff = (minuteInt - targetMinuteInt).abs();
      final score = 1.0 - (hourDiff * 0.4 + minuteDiff * 0.01);

      if (score > bestScore && score > 0.8) {
        // 80% similarity threshold
        bestScore = score;
        bestMatch = entry.value;
      }
    }

    return bestMatch;
  }

  /// Extract text within a specific column boundary
  String _extractColumnText(String text, TextPosition targetPosition,
      Map<String, TextPosition> allPositions) {
    final lines = text.split('\n');
    final columnBounds = _calculateColumnBounds(targetPosition, allPositions);

    final columnLines = <String>[];

    // Extract lines around the target time position
    final startLine = math.max(0, targetPosition.line - 2);
    final endLine = math.min(lines.length - 1,
        targetPosition.line + 15); // Assume data is below time header

    for (int i = startLine; i <= endLine; i++) {
      final line = lines[i];
      if (line.trim().isEmpty) continue;

      // Extract column-specific portion of the line
      final columnPortion = _extractLineColumn(line, columnBounds);
      if (columnPortion.trim().isNotEmpty) {
        columnLines.add(columnPortion);
      }
    }

    return columnLines.join('\n');
  }

  /// Calculate column boundaries based on time positions
  ColumnBounds _calculateColumnBounds(
      TextPosition targetPosition, Map<String, TextPosition> allPositions) {
    final positions = allPositions.values.toList()
      ..sort((a, b) => a.column.compareTo(b.column));

    final targetIndex =
        positions.indexWhere((p) => p.column == targetPosition.column);
    if (targetIndex == -1) {
      return ColumnBounds(
          start: targetPosition.column - 20, end: targetPosition.column + 20);
    }

    final leftBound = targetIndex > 0
        ? (targetPosition.column + positions[targetIndex - 1].column) ~/ 2
        : math.max(0, targetPosition.column - 30);

    final rightBound = targetIndex < positions.length - 1
        ? (targetPosition.column + positions[targetIndex + 1].column) ~/ 2
        : targetPosition.column + 30;

    return ColumnBounds(start: leftBound, end: rightBound);
  }

  /// Extract column portion from a line
  String _extractLineColumn(String line, ColumnBounds bounds) {
    final start = math.max(0, bounds.start);
    final end = math.min(line.length, bounds.end);

    if (start >= line.length) return '';
    return line.substring(start, end);
  }

  /// Parse field values from column text with confidence scoring
  Future<List<FieldMatch>> _parseFieldValues(
    String columnText,
    TextPosition timePosition,
    LogParsingConfig config,
  ) async {
    final matches = <FieldMatch>[];
    final lines = columnText.split('\n');

    for (final fieldEntry in config.fieldPatterns.entries) {
      final fieldName = fieldEntry.key;
      final pattern = fieldEntry.value;

      final fieldMatch = await _findFieldValue(
        fieldName,
        pattern,
        lines,
        timePosition,
      );

      if (fieldMatch != null) {
        matches.add(fieldMatch);
      }
    }

    return matches;
  }

  /// Find a specific field value with confidence scoring
  Future<FieldMatch?> _findFieldValue(
    String fieldName,
    FieldPattern pattern,
    List<String> lines,
    TextPosition timePosition,
  ) async {
    final candidates = <FieldCandidate>[];

    // Search through column lines for pattern matches
    for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex];
      final matches = pattern.regex.allMatches(line);

      for (final match in matches) {
        final rawValue = match.group(1);
        if (rawValue == null || rawValue.trim().isEmpty) continue;

        final candidate = FieldCandidate(
          value: rawValue,
          line: lineIndex,
          position: match.start,
          rawMatch: match.group(0) ?? rawValue,
        );

        candidates.add(candidate);
      }
    }

    if (candidates.isEmpty) return null;

    // Score candidates based on multiple factors
    final scoredCandidates = candidates.map((candidate) {
      final confidence = _calculateFieldConfidence(
        candidate,
        pattern,
        lines,
        timePosition,
      );

      return ScoredCandidate(candidate, confidence);
    }).toList();

    // Sort by confidence and return best match
    scoredCandidates.sort((a, b) => b.confidence.compareTo(a.confidence));
    final best = scoredCandidates.first;

    if (best.confidence < _config.minConfidenceThreshold) return null;

    final parsedValue = _parseValue(best.candidate.value, pattern.type);
    final validation = _validateValue(parsedValue, pattern);

    return FieldMatch(
      name: fieldName,
      value: parsedValue,
      confidence: best.confidence,
      rawMatch: best.candidate.rawMatch,
      position: best.candidate.position,
      type: pattern.type,
      unit: pattern.unit,
      validation: validation,
    );
  }

  /// Calculate confidence score for a field candidate
  double _calculateFieldConfidence(
    FieldCandidate candidate,
    FieldPattern pattern,
    List<String> lines,
    TextPosition timePosition,
  ) {
    double confidence = 0.5; // Base confidence

    // Factor 1: Pattern match quality (20%)
    final patternQuality = _assessPatternQuality(candidate.value, pattern);
    confidence += patternQuality * 0.2;

    // Factor 2: Value range validation (25%)
    final parsedValue = _parseValue(candidate.value, pattern.type);
    if (pattern.isInExpectedRange(parsedValue)) {
      confidence += 0.25;
    } else {
      confidence -= 0.3; // Penalty for out-of-range values
    }

    // Factor 3: Spatial positioning (20%)
    final spatialScore = _calculateSpatialScore(candidate, timePosition);
    confidence += spatialScore * 0.2;

    // Factor 4: Context clues (15%)
    final contextScore = _calculateContextScore(candidate, lines, pattern);
    confidence += contextScore * 0.15;

    // Factor 5: Distinctiveness (avoid duplicates) (10%)
    final distinctiveness = _calculateDistinctiveness(candidate, lines);
    confidence += distinctiveness * 0.1;

    // Factor 6: OCR quality indicators (10%)
    final ocrQuality = _assessOcrQuality(candidate.rawMatch);
    confidence += ocrQuality * 0.1;

    return math.max(0.0, math.min(1.0, confidence));
  }

  /// Assess pattern match quality
  double _assessPatternQuality(String value, FieldPattern pattern) {
    if (value.isEmpty) return 0.0;

    // Check for clean numeric patterns
    if (pattern.type == FieldType.numeric ||
        pattern.type == FieldType.flowRate ||
        pattern.type == FieldType.temperature ||
        pattern.type == FieldType.pressure) {
      final numValue = double.tryParse(value);
      if (numValue == null) return 0.0;

      // Prefer whole numbers for flow rates and temperatures
      if (pattern.type == FieldType.flowRate ||
          pattern.type == FieldType.temperature) {
        return value.contains('.') ? 0.7 : 1.0;
      }

      return 0.9;
    }

    return 0.8;
  }

  /// Calculate spatial positioning score
  double _calculateSpatialScore(
      FieldCandidate candidate, TextPosition timePosition) {
    // Prefer values that appear below the time header
    if (candidate.line > 0) {
      return 1.0;
    }
    return 0.3;
  }

  /// Calculate context score based on surrounding text
  double _calculateContextScore(
      FieldCandidate candidate, List<String> lines, FieldPattern pattern) {
    if (candidate.line >= lines.length) return 0.0;

    final line = lines[candidate.line];
    double score = 0.5;

    // Look for unit indicators
    if (pattern.unit.isNotEmpty) {
      final unitPattern = RegExp(pattern.unit, caseSensitive: false);
      if (unitPattern.hasMatch(line)) {
        score += 0.3;
      }
    }

    // Look for field name aliases in nearby text
    for (final alias in pattern.aliases) {
      final aliasPattern = RegExp(alias, caseSensitive: false);

      // Check current line and nearby lines
      for (int i = math.max(0, candidate.line - 3);
          i <= math.min(lines.length - 1, candidate.line + 1);
          i++) {
        if (aliasPattern.hasMatch(lines[i])) {
          score += 0.2;
          break;
        }
      }
    }

    return math.min(1.0, score);
  }

  /// Calculate distinctiveness score
  double _calculateDistinctiveness(
      FieldCandidate candidate, List<String> lines) {
    int occurrences = 0;
    for (final line in lines) {
      if (line.contains(candidate.value)) {
        occurrences++;
      }
    }

    // Prefer unique or rare values
    if (occurrences == 1) return 1.0;
    if (occurrences == 2) return 0.8;
    if (occurrences <= 4) return 0.6;
    return 0.3;
  }

  /// Assess OCR quality of the match
  double _assessOcrQuality(String rawMatch) {
    double quality = 1.0;

    // Penalize common OCR artifacts
    if (rawMatch.contains(RegExp(r'[^\w\s\.\:\-]'))) quality -= 0.2;
    if (rawMatch.length < 2) quality -= 0.3;
    if (rawMatch.contains('  ')) quality -= 0.1; // Double spaces

    return math.max(0.0, quality);
  }

  /// Parse value according to field type
  dynamic _parseValue(String value, FieldType type) {
    final cleaned = value.trim().replaceAll(RegExp(r'[^\d\.\-]'), '');

    switch (type) {
      case FieldType.flowRate:
      case FieldType.temperature:
      case FieldType.totalizer:
        return int.tryParse(cleaned) ?? double.tryParse(cleaned)?.round();

      case FieldType.pressure:
      case FieldType.concentration:
        return double.tryParse(cleaned);

      case FieldType.numeric:
        final intValue = int.tryParse(cleaned);
        if (intValue != null) return intValue;
        return double.tryParse(cleaned);

      case FieldType.time:
      case FieldType.text:
      default:
        return value.trim();
    }
  }

  /// Validate parsed value
  ValidationResult _validateValue(dynamic value, FieldPattern pattern) {
    final errors = <String>[];
    final warnings = <String>[];

    if (value == null) {
      errors.add('Failed to parse value');
      return ValidationResult.invalid(errors);
    }

    // Range validation
    if (!pattern.isInExpectedRange(value)) {
      final range = pattern.expectedRange;
      warnings.add(
          'Value $value outside expected range ${range.$1}-${range.$2} ${pattern.unit}');
    }

    // Type-specific validation
    switch (pattern.type) {
      case FieldType.temperature:
        if (value is num && value < 100) {
          warnings.add('Temperature seems low for exhaust system');
        }
        break;

      case FieldType.concentration:
        if (value is num && value > 50000) {
          warnings.add('PPM value seems extremely high');
        }
        break;

      case FieldType.pressure:
        if (value is num && value <= 0) {
          errors.add('Pressure must be positive');
        }
        break;

      default:
        break;
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Helper methods
  int _calculateAbsolutePosition(
      List<String> lines, int lineIndex, int columnIndex) {
    int position = 0;
    for (int i = 0; i < lineIndex; i++) {
      position += lines[i].length + 1; // +1 for newline
    }
    return position + columnIndex;
  }

  double _calculateTimeConfidence(String timeString, String line) {
    double confidence = 0.7;

    // Well-formed time pattern
    if (RegExp(r'^\d{2}:\d{2}$').hasMatch(timeString)) confidence += 0.2;

    // Appears at beginning of line (likely header)
    if (line.trim().startsWith(timeString)) confidence += 0.1;

    return math.min(1.0, confidence);
  }

  /// Create empty reading for error cases
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

/// Supporting classes for internal parsing logic
class TextPosition {
  final int line;
  final int column;
  final int absolutePosition;
  final double confidence;

  const TextPosition({
    required this.line,
    required this.column,
    required this.absolutePosition,
    required this.confidence,
  });
}

class ColumnBounds {
  final int start;
  final int end;

  const ColumnBounds({required this.start, required this.end});
}

class FieldCandidate {
  final String value;
  final int line;
  final int position;
  final String rawMatch;

  const FieldCandidate({
    required this.value,
    required this.line,
    required this.position,
    required this.rawMatch,
  });
}

class ScoredCandidate {
  final FieldCandidate candidate;
  final double confidence;

  const ScoredCandidate(this.candidate, this.confidence);
}
