import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/hourly_reading_models.dart';
import 'hourly_log_parser.dart';

/// Anti-hallucination OCR parser for thermal logs
/// Prevents generating values for blank fields and only extracts actually detected values
class AntiHallucinationParser {
  static final _instance = AntiHallucinationParser._internal();
  factory AntiHallucinationParser() => _instance;
  AntiHallucinationParser._internal();

  final HourlyLogParser _traditionalParser = HourlyLogParser();

  // Anti-hallucination configuration
  static const double _minConfidenceThreshold = 0.7;
  static const double _patternDetectionThreshold = 0.85;
  static const int _maxConsecutiveValues =
      3; // Max consecutive filled hours before flagging
  static const double _spatialAlignmentThreshold = 0.8;
  static const bool _enableDebugMode = true;

  /// Parse hourly reading with strict anti-hallucination measures
  Future<AntiHallucinationResult> parseWithAntiHallucination(
    String ocrText,
    String targetHour, {
    List<String>? allHours, // All hours in the log for pattern detection
    Map<String, dynamic>? boundingBoxData, // OCR bounding box data if available
    bool strictMode = true,
  }) async {
    debugPrint('🛡️ Starting anti-hallucination parsing for hour: $targetHour');

    try {
      // Step 1: Extract raw OCR data with spatial information
      final rawData = _extractRawOcrData(ocrText, targetHour, boundingBoxData);

      // Step 2: Detect and flag potential hallucinations
      final hallucinationFlags = _detectHallucinations(rawData, allHours);

      // Step 3: Parse with traditional parser but apply strict filtering
      final traditionalResult =
          await _traditionalParser.parseHourlyReading(ocrText, targetHour);

      // Step 4: Apply anti-hallucination filters
      final filteredResult = _applyAntiHallucinationFilters(
        traditionalResult,
        rawData,
        hallucinationFlags,
        strictMode,
      );

      // Step 5: Generate confidence scores per cell
      final cellConfidences = _generateCellConfidences(filteredResult, rawData);

      // Step 6: Create final result with detailed metadata
      final result = AntiHallucinationResult(
        hourlyReading: filteredResult,
        cellConfidences: cellConfidences,
        hallucinationFlags: hallucinationFlags,
        rawOcrData: rawData,
        parsingMetadata: _generateParsingMetadata(rawData, hallucinationFlags),
        debugInfo: _enableDebugMode
            ? _generateDebugInfo(rawData, traditionalResult, filteredResult)
            : null,
      );

      debugPrint('✅ Anti-hallucination parsing complete');
      debugPrint(
          '📊 Valid fields: ${filteredResult.validFieldCount}/${filteredResult.fieldMatches.length}');
      debugPrint('🚨 Hallucination flags: ${hallucinationFlags.length}');

      return result;
    } catch (e, stackTrace) {
      debugPrint('❌ Anti-hallucination parsing error: $e');
      debugPrint('Stack trace: $stackTrace');

      return AntiHallucinationResult(
        hourlyReading: _createEmptyReading(targetHour, ocrText),
        cellConfidences: {},
        hallucinationFlags: [
          HallucinationFlag('parsing_error', 'Parsing failed: $e', 1.0)
        ],
        rawOcrData: RawOcrData.empty(),
        parsingMetadata: ParsingMetadata(error: e.toString()),
        debugInfo: null,
      );
    }
  }

  /// Extract raw OCR data with spatial positioning
  RawOcrData _extractRawOcrData(String ocrText, String targetHour,
      Map<String, dynamic>? boundingBoxData) {
    final lines = ocrText.split('\n');
    final cells = <OcrCell>[];

    // Find time column positions
    final timePositions = _findTimeColumnPositions(lines);
    final targetColumn = _findTargetColumn(timePositions, targetHour);

    if (targetColumn == null) {
      debugPrint('❌ Target hour column not found: $targetHour');
      return RawOcrData.empty();
    }

    // Extract cells from the target column
    for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex];
      final cellText = _extractCellText(line, targetColumn);

      if (cellText.trim().isNotEmpty) {
        final cell = OcrCell(
          text: cellText.trim(),
          line: lineIndex,
          column: targetColumn,
          confidence: _estimateOcrConfidence(cellText),
          boundingBox:
              _extractBoundingBox(boundingBoxData, lineIndex, targetColumn),
          isEmpty: _isCellEmpty(cellText),
        );
        cells.add(cell);
      }
    }

    return RawOcrData(
      cells: cells,
      targetHour: targetHour,
      targetColumn: targetColumn,
      timePositions: timePositions,
      boundingBoxData: boundingBoxData,
    );
  }

  /// Detect potential hallucinations using multiple heuristics
  List<HallucinationFlag> _detectHallucinations(
      RawOcrData rawData, List<String>? allHours) {
    final flags = <HallucinationFlag>[];

    // 1. Perfect pattern detection
    final patternFlags = _detectPerfectPatterns(rawData, allHours);
    flags.addAll(patternFlags);

    // 2. Spatial misalignment detection
    final spatialFlags = _detectSpatialMisalignment(rawData);
    flags.addAll(spatialFlags);

    // 3. Confidence inconsistency detection
    final confidenceFlags = _detectConfidenceInconsistencies(rawData);
    flags.addAll(confidenceFlags);

    // 4. Empty cell detection
    final emptyFlags = _detectEmptyCells(rawData);
    flags.addAll(emptyFlags);

    // 5. Sequential value detection
    final sequentialFlags = _detectSequentialValues(rawData, allHours);
    flags.addAll(sequentialFlags);

    return flags;
  }

  /// Detect perfect patterns that suggest hallucination
  List<HallucinationFlag> _detectPerfectPatterns(
      RawOcrData rawData, List<String>? allHours) {
    final flags = <HallucinationFlag>[];

    if (allHours == null) return flags;

    // Check for arithmetic sequences across hours
    final numericCells =
        rawData.cells.where((cell) => _isNumeric(cell.text)).toList();

    for (int i = 0; i < numericCells.length - 2; i++) {
      final values = <double>[];
      for (int j = i; j < math.min(i + 3, numericCells.length); j++) {
        final value = double.tryParse(numericCells[j].text);
        if (value != null) values.add(value);
      }

      if (values.length >= 3) {
        // Check for arithmetic sequence
        final differences = <double>[];
        for (int k = 1; k < values.length; k++) {
          differences.add(values[k] - values[k - 1]);
        }

        if (differences.every((diff) => (diff - differences[0]).abs() < 0.1)) {
          flags.add(HallucinationFlag(
            'perfect_arithmetic_sequence',
            'Detected perfect arithmetic sequence: ${values.join(' → ')}',
            0.9,
            affectedCells: numericCells.sublist(i, i + values.length),
          ));
        }
      }
    }

    return flags;
  }

  /// Detect spatial misalignment issues
  List<HallucinationFlag> _detectSpatialMisalignment(RawOcrData rawData) {
    final flags = <HallucinationFlag>[];

    // Check if cells are properly aligned with expected positions
    final expectedPositions = _getExpectedFieldPositions();

    for (final cell in rawData.cells) {
      final expectedPosition = expectedPositions[cell.line];
      if (expectedPosition != null) {
        final alignmentScore = _calculateAlignmentScore(cell, expectedPosition);
        if (alignmentScore < _spatialAlignmentThreshold) {
          flags.add(HallucinationFlag(
            'spatial_misalignment',
            'Cell misaligned: expected line $expectedPosition, found line ${cell.line}',
            alignmentScore,
            affectedCells: [cell],
          ));
        }
      }
    }

    return flags;
  }

  /// Detect confidence inconsistencies
  List<HallucinationFlag> _detectConfidenceInconsistencies(RawOcrData rawData) {
    final flags = <HallucinationFlag>[];

    // Check for cells with high confidence but suspicious content
    for (final cell in rawData.cells) {
      if (cell.confidence > 0.8) {
        // High confidence but empty or suspicious content
        if (cell.isEmpty || _isSuspiciousContent(cell.text)) {
          flags.add(HallucinationFlag(
            'confidence_inconsistency',
            'High confidence but suspicious content: "${cell.text}"',
            cell.confidence,
            affectedCells: [cell],
          ));
        }
      }
    }

    return flags;
  }

  /// Detect empty cells that shouldn't have values
  List<HallucinationFlag> _detectEmptyCells(RawOcrData rawData) {
    final flags = <HallucinationFlag>[];

    for (final cell in rawData.cells) {
      if (cell.isEmpty && cell.text.trim().isNotEmpty) {
        flags.add(HallucinationFlag(
          'empty_cell_with_content',
          'Empty cell contains content: "${cell.text}"',
          0.8,
          affectedCells: [cell],
        ));
      }
    }

    return flags;
  }

  /// Detect sequential values that suggest pattern generation
  List<HallucinationFlag> _detectSequentialValues(
      RawOcrData rawData, List<String>? allHours) {
    final flags = <HallucinationFlag>[];

    if (allHours == null) return flags;

    // Check for consecutive filled hours that might be hallucinated
    int consecutiveFilled = 0;
    for (final hour in allHours) {
      final hasData = rawData.cells.any((cell) => !cell.isEmpty);
      if (hasData) {
        consecutiveFilled++;
        if (consecutiveFilled > _maxConsecutiveValues) {
          flags.add(HallucinationFlag(
            'too_many_consecutive_values',
            'Too many consecutive filled hours: $consecutiveFilled',
            0.7,
          ));
        }
      } else {
        consecutiveFilled = 0;
      }
    }

    return flags;
  }

  /// Apply anti-hallucination filters to traditional parser results
  HourlyReading _applyAntiHallucinationFilters(
    HourlyReading traditionalResult,
    RawOcrData rawData,
    List<HallucinationFlag> hallucinationFlags,
    bool strictMode,
  ) {
    final filteredMatches = <FieldMatch>[];

    for (final match in traditionalResult.fieldMatches) {
      // Check if this field is affected by hallucination flags
      final isAffected =
          _isFieldAffectedByHallucination(match, hallucinationFlags, rawData);

      if (isAffected) {
        debugPrint(
            '🚨 Filtering out hallucinated field: ${match.name} = ${match.value}');
        continue;
      }

      // Apply additional confidence adjustments
      final adjustedConfidence =
          _adjustConfidenceForAntiHallucination(match, rawData);

      if (adjustedConfidence >= _minConfidenceThreshold || !strictMode) {
        final adjustedMatch = FieldMatch(
          name: match.name,
          value: match.value,
          confidence: adjustedConfidence,
          rawMatch: match.rawMatch,
          position: match.position,
          type: match.type,
          unit: match.unit,
          validation: match.validation,
        );
        filteredMatches.add(adjustedMatch);
      } else {
        debugPrint(
            '🚨 Filtering out low confidence field: ${match.name} (${(adjustedConfidence * 100).toInt()}%)');
      }
    }

    return HourlyReading.fromFieldMatches(
      traditionalResult.inspectionTime,
      filteredMatches,
      traditionalResult.rawOcrText,
    );
  }

  /// Generate confidence scores per cell
  Map<String, double> _generateCellConfidences(
      HourlyReading result, RawOcrData rawData) {
    final confidences = <String, double>{};

    for (final match in result.fieldMatches) {
      final cell = _findMatchingCell(match, rawData);
      if (cell != null) {
        confidences[match.name] = cell.confidence;
      } else {
        confidences[match.name] = match.confidence;
      }
    }

    return confidences;
  }

  // Helper methods
  List<TextPosition> _findTimeColumnPositions(List<String> lines) {
    final positions = <TextPosition>[];
    final timePattern = RegExp(r'(\d{1,2}):(\d{2})');

    for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex];
      final matches = timePattern.allMatches(line);

      for (final match in matches) {
        positions.add(TextPosition(
          line: lineIndex,
          column: match.start,
          absolutePosition:
              _calculateAbsolutePosition(lines, lineIndex, match.start),
          confidence: _calculateTimeConfidence(match.group(0) ?? '', line),
        ));
      }
    }

    return positions;
  }

  int? _findTargetColumn(List<TextPosition> timePositions, String targetHour) {
    // Find the column position for the target hour
    // This is a simplified version - you might need more sophisticated logic
    if (timePositions.isEmpty) return null;

    // For now, return the first time position column
    return timePositions.first.column;
  }

  String _extractCellText(String line, int column) {
    final start = math.max(0, column - 10);
    final end = math.min(line.length, column + 10);
    return line.substring(start, end);
  }

  double _estimateOcrConfidence(String text) {
    // Simple confidence estimation based on text characteristics
    double confidence = 0.5;

    // Clean numeric text gets higher confidence
    if (RegExp(r'^\d+\.?\d*$').hasMatch(text)) confidence += 0.3;

    // Text with common OCR artifacts gets lower confidence
    if (text.contains(RegExp(r'[^\w\s\.\:\-]'))) confidence -= 0.2;

    // Very short text gets lower confidence
    if (text.length < 2) confidence -= 0.3;

    return confidence.clamp(0.0, 1.0);
  }

  Map<String, dynamic>? _extractBoundingBox(
      Map<String, dynamic>? boundingBoxData, int line, int column) {
    // Extract bounding box data if available
    if (boundingBoxData == null) return null;

    // This would need to be implemented based on your OCR engine's bounding box format
    return null;
  }

  bool _isCellEmpty(String text) {
    final trimmed = text.trim();
    return trimmed.isEmpty ||
        trimmed == '-' ||
        trimmed == 'N/A' ||
        trimmed == 'n/a' ||
        RegExp(r'^\s*$').hasMatch(trimmed);
  }

  bool _isNumeric(String text) {
    return double.tryParse(text.trim()) != null;
  }

  bool _isSuspiciousContent(String text) {
    // Check for suspicious patterns that might indicate hallucination
    final suspiciousPatterns = [
      RegExp(r'^\d{4}$'), // Perfect 4-digit numbers
      RegExp(r'^\d{3}$'), // Perfect 3-digit numbers
      RegExp(r'^\d{2}$'), // Perfect 2-digit numbers
    ];

    return suspiciousPatterns.any((pattern) => pattern.hasMatch(text.trim()));
  }

  Map<int, int> _getExpectedFieldPositions() {
    // Define expected line positions for different field types
    // This would be based on your log template structure
    return {
      0: 0, // Time header
      1: 1, // Vapor inlet
      2: 2, // Dilution air
      3: 3, // Combustion air
      4: 4, // Exhaust temp
      5: 5, // Sphere pressure
      6: 6, // Inlet PPM
      7: 7, // Outlet PPM
      8: 8, // Totalizer
    };
  }

  double _calculateAlignmentScore(OcrCell cell, int expectedLine) {
    final lineDiff = (cell.line - expectedLine).abs();
    return math.max(0.0, 1.0 - (lineDiff * 0.2));
  }

  bool _isFieldAffectedByHallucination(
    FieldMatch match,
    List<HallucinationFlag> flags,
    RawOcrData rawData,
  ) {
    // Check if any hallucination flags affect this field
    for (final flag in flags) {
      if (flag.affectedCells != null) {
        for (final cell in flag.affectedCells!) {
          if (_isFieldMatchCell(match, cell)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  bool _isFieldMatchCell(FieldMatch match, OcrCell cell) {
    // Check if the field match corresponds to this cell
    // This is a simplified check - you might need more sophisticated logic
    return cell.text.contains(match.rawMatch) ||
        match.rawMatch.contains(cell.text);
  }

  double _adjustConfidenceForAntiHallucination(
      FieldMatch match, RawOcrData rawData) {
    double adjustedConfidence = match.confidence;

    // Reduce confidence for fields without corresponding OCR cells
    final matchingCell = _findMatchingCell(match, rawData);
    if (matchingCell == null) {
      adjustedConfidence *= 0.5; // Significant penalty for no OCR evidence
    } else {
      // Adjust based on cell confidence
      adjustedConfidence = (adjustedConfidence + matchingCell.confidence) / 2;

      // Additional penalty for empty cells
      if (matchingCell.isEmpty) {
        adjustedConfidence *= 0.3;
      }
    }

    return adjustedConfidence.clamp(0.0, 1.0);
  }

  OcrCell? _findMatchingCell(FieldMatch match, RawOcrData rawData) {
    // Find the OCR cell that corresponds to this field match
    for (final cell in rawData.cells) {
      if (_isFieldMatchCell(match, cell)) {
        return cell;
      }
    }
    return null;
  }

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

  HourlyReading _createEmptyReading(String targetHour, String rawText) {
    return HourlyReading(
      inspectionTime: targetHour,
      overallConfidence: 0.0,
      fieldMatches: [],
      parsedAt: DateTime.now(),
      rawOcrText: rawText,
    );
  }

  ParsingMetadata _generateParsingMetadata(
      RawOcrData rawData, List<HallucinationFlag> flags) {
    return ParsingMetadata(
      totalCells: rawData.cells.length,
      emptyCells: rawData.cells.where((cell) => cell.isEmpty).length,
      hallucinationFlags: flags.length,
      averageConfidence: rawData.cells.isEmpty
          ? 0.0
          : rawData.cells
                  .map((cell) => cell.confidence)
                  .reduce((a, b) => a + b) /
              rawData.cells.length,
    );
  }

  DebugInfo? _generateDebugInfo(
      RawOcrData rawData, HourlyReading traditional, HourlyReading filtered) {
    if (!_enableDebugMode) return null;

    return DebugInfo(
      rawOcrText: rawData.toString(),
      traditionalResult: traditional.toJson(),
      filteredResult: filtered.toJson(),
      cellDetails: rawData.cells.map((cell) => cell.toJson()).toList(),
    );
  }
}

/// Result of anti-hallucination parsing
class AntiHallucinationResult {
  final HourlyReading hourlyReading;
  final Map<String, double> cellConfidences;
  final List<HallucinationFlag> hallucinationFlags;
  final RawOcrData rawOcrData;
  final ParsingMetadata parsingMetadata;
  final DebugInfo? debugInfo;

  const AntiHallucinationResult({
    required this.hourlyReading,
    required this.cellConfidences,
    required this.hallucinationFlags,
    required this.rawOcrData,
    required this.parsingMetadata,
    this.debugInfo,
  });

  bool get hasHallucinations => hallucinationFlags.isNotEmpty;
  bool get isHighQuality => hourlyReading.isHighQuality && !hasHallucinations;
  bool get requiresManualReview =>
      hasHallucinations || hourlyReading.overallConfidence < 0.8;
}

/// Hallucination detection flag
class HallucinationFlag {
  final String type;
  final String description;
  final double confidence;
  final List<OcrCell>? affectedCells;

  const HallucinationFlag(
    this.type,
    this.description,
    this.confidence, {
    this.affectedCells,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'description': description,
        'confidence': confidence,
        'affectedCells': affectedCells?.map((cell) => cell.toJson()).toList(),
      };
}

/// Raw OCR data with spatial information
class RawOcrData {
  final List<OcrCell> cells;
  final String targetHour;
  final int? targetColumn;
  final List<TextPosition> timePositions;
  final Map<String, dynamic>? boundingBoxData;

  const RawOcrData({
    required this.cells,
    required this.targetHour,
    this.targetColumn,
    required this.timePositions,
    this.boundingBoxData,
  });

  factory RawOcrData.empty() => const RawOcrData(
        cells: [],
        targetHour: '',
        timePositions: [],
      );

  @override
  String toString() =>
      'RawOcrData(cells: ${cells.length}, targetHour: $targetHour)';
}

/// Individual OCR cell with metadata
class OcrCell {
  final String text;
  final int line;
  final int column;
  final double confidence;
  final Map<String, dynamic>? boundingBox;
  final bool isEmpty;

  const OcrCell({
    required this.text,
    required this.line,
    required this.column,
    required this.confidence,
    this.boundingBox,
    required this.isEmpty,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'line': line,
        'column': column,
        'confidence': confidence,
        'boundingBox': boundingBox,
        'isEmpty': isEmpty,
      };
}

/// Parsing metadata
class ParsingMetadata {
  final int totalCells;
  final int emptyCells;
  final int hallucinationFlags;
  final double averageConfidence;
  final String? error;

  const ParsingMetadata({
    this.totalCells = 0,
    this.emptyCells = 0,
    this.hallucinationFlags = 0,
    this.averageConfidence = 0.0,
    this.error,
  });

  Map<String, dynamic> toJson() => {
        'totalCells': totalCells,
        'emptyCells': emptyCells,
        'hallucinationFlags': hallucinationFlags,
        'averageConfidence': averageConfidence,
        'error': error,
      };
}

/// Debug information for development
class DebugInfo {
  final String rawOcrText;
  final Map<String, dynamic> traditionalResult;
  final Map<String, dynamic> filteredResult;
  final List<Map<String, dynamic>> cellDetails;

  const DebugInfo({
    required this.rawOcrText,
    required this.traditionalResult,
    required this.filteredResult,
    required this.cellDetails,
  });

  Map<String, dynamic> toJson() => {
        'rawOcrText': rawOcrText,
        'traditionalResult': traditionalResult,
        'filteredResult': filteredResult,
        'cellDetails': cellDetails,
      };
}

/// Text position with confidence
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
