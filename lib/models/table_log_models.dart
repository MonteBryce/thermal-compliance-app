import 'dart:convert';

/// Represents a structured table-based hourly log with fixed columns and rows
class TableLogStructure {
  static const int totalHours = 11; // 00:00 through 10:00
  static const List<String> hourLabels = [
    '00:00',
    '01:00',
    '02:00',
    '03:00',
    '04:00',
    '05:00',
    '06:00',
    '07:00',
    '08:00',
    '09:00',
    '10:00'
  ];

  /// Standard row definitions for methane degassing logs
  static const Map<String, LogRowDefinition> standardRows = {
    'inspectionTime': LogRowDefinition(
      fieldName: 'inspectionTime',
      labels: ['Inspection Time', 'Time', 'Hour'],
      dataType: LogDataType.time,
      required: true,
    ),
    'vaporInletFpm': LogRowDefinition(
      fieldName: 'vaporInletFpm',
      labels: [
        'Vapor Inlet Flow Rate (FPM)',
        'Vapor Inlet',
        'Vapor Flow',
        'VIFR'
      ],
      dataType: LogDataType.integer,
      required: true,
    ),
    'dilutionAirFpm': LogRowDefinition(
      fieldName: 'dilutionAirFpm',
      labels: ['Dilution Air Flow Rate (FPM)', 'Dilution Air', 'DAFR'],
      dataType: LogDataType.integer,
      required: false,
    ),
    'combustionAirFpm': LogRowDefinition(
      fieldName: 'combustionAirFpm',
      labels: ['Combustion Air Flow Rate (FPM)', 'Combustion Air', 'CAFR'],
      dataType: LogDataType.integer,
      required: false,
    ),
    'exhaustTempF': LogRowDefinition(
      fieldName: 'exhaustTempF',
      labels: ['Exhaust Temperature (F)', 'Exhaust Temp', 'Temperature'],
      dataType: LogDataType.integer,
      required: true,
    ),
    'spherePressurePsi': LogRowDefinition(
      fieldName: 'spherePressurePsi',
      labels: ['Sphere Pressure (PSI)', 'Pressure', 'PSI'],
      dataType: LogDataType.decimal,
      required: false,
    ),
    'inletPpm': LogRowDefinition(
      fieldName: 'inletPpm',
      labels: ['Inlet Reading (PPM Methane)', 'Inlet PPM', 'Inlet Reading'],
      dataType: LogDataType.decimal,
      required: true,
    ),
    'outletPpm': LogRowDefinition(
      fieldName: 'outletPpm',
      labels: ['Outlet Reading (PPM Methane)', 'Outlet PPM', 'Outlet Reading'],
      dataType: LogDataType.decimal,
      required: false,
    ),
    'totalizerScf': LogRowDefinition(
      fieldName: 'totalizerScf',
      labels: ['Totalizer Reading (SCF)', 'Totalizer', 'SCF Reading'],
      dataType: LogDataType.integer,
      required: false,
    ),
  };
}

/// Definition of a log row with its labels and data type
class LogRowDefinition {
  final String fieldName;
  final List<String> labels;
  final LogDataType dataType;
  final bool required;

  const LogRowDefinition({
    required this.fieldName,
    required this.labels,
    required this.dataType,
    required this.required,
  });

  /// Check if a text line matches this row definition
  bool matchesRow(String line) {
    final normalizedLine = line.toLowerCase().trim();

    for (final label in labels) {
      final normalizedLabel = label.toLowerCase();

      // Exact match at start
      if (normalizedLine.startsWith(normalizedLabel)) {
        return true;
      }

      // Contains match (for multi-word labels)
      if (normalizedLine.contains(normalizedLabel)) {
        return true;
      }

      // Handle table format where label might be followed by values
      if (normalizedLine.startsWith(normalizedLabel.split(' ').first)) {
        return true;
      }

      // OCR error handling for common field names
      if (_matchesWithOcrErrors(normalizedLine, normalizedLabel)) {
        return true;
      }

      // Fuzzy match (allows for OCR errors)
      if (_fuzzyMatch(normalizedLine, normalizedLabel)) {
        return true;
      }
    }

    return false;
  }

  /// Fuzzy matching for OCR errors
  bool _fuzzyMatch(String line, String label) {
    // Allow up to 20% character differences
    final threshold = (label.length * 0.8).round();
    return _levenshteinDistance(
            line.substring(0, label.length.clamp(0, line.length)), label) <=
        (label.length - threshold);
  }

  /// Check for matches with common OCR errors in field names
  bool _matchesWithOcrErrors(String line, String label) {
    // Common OCR error patterns for field names
    final ocrErrorPatterns = {
      'vapor': ['vap0r', 'vap0r', 'vap0r'],
      'dilution': ['d1lut1on', 'd1lut1on', 'd1lut1on'],
      'combustion': ['c0mbust1on', 'c0mbust1on', 'c0mbust1on'],
      'exhaust': ['exhaust', 'exhaust', 'exhaust'],
      'pressure': ['presure', 'presure', 'presure'],
      'inlet': ['1nlet', '1nlet', '1nlet'],
      'outlet': ['0utlet', '0utlet', '0utlet'],
      'totalizer': ['t0tal1zer', 't0tal1zer', 't0tal1zer'],
      'time': ['t1me', 't1me', 't1me'],
    };

    // Check if the line starts with any OCR error variant of the label
    for (final entry in ocrErrorPatterns.entries) {
      final correctName = entry.key;
      final errorVariants = entry.value;

      if (label.contains(correctName)) {
        for (final errorVariant in errorVariants) {
          if (line.startsWith(errorVariant)) {
            return true;
          }
        }
      }
    }

    return false;
  }

  /// Calculate Levenshtein distance for fuzzy matching
  int _levenshteinDistance(String s1, String s2) {
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final matrix =
        List.generate(s1.length + 1, (i) => List.filled(s2.length + 1, 0));

    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[s1.length][s2.length];
  }
}

/// Data types for log values
enum LogDataType { time, integer, decimal, text }

/// Result of parsing a single row
class RowParseResult {
  final String fieldName;
  final List<String> rawValues;
  final List<dynamic> parsedValues;
  final double confidence;
  final List<String> warnings;
  final String matchedLabel;

  const RowParseResult({
    required this.fieldName,
    required this.rawValues,
    required this.parsedValues,
    required this.confidence,
    required this.warnings,
    required this.matchedLabel,
  });

  bool get isValid => parsedValues.isNotEmpty && confidence > 0.5;
  bool get isHighConfidence => confidence >= 0.8;

  /// Get value for specific hour index (0-10)
  dynamic getValueForHour(int hourIndex) {
    if (hourIndex < 0 || hourIndex >= parsedValues.length) {
      return null;
    }
    return parsedValues[hourIndex];
  }

  Map<String, dynamic> toJson() => {
        'fieldName': fieldName,
        'rawValues': rawValues,
        'parsedValues': parsedValues,
        'confidence': confidence,
        'warnings': warnings,
        'matchedLabel': matchedLabel,
      };
}

/// Complete table parsing result
class TableParseResult {
  final Map<String, RowParseResult> rowResults;
  final double overallConfidence;
  final List<String> missingRequiredFields;
  final DateTime parsedAt;

  const TableParseResult({
    required this.rowResults,
    required this.overallConfidence,
    required this.missingRequiredFields,
    required this.parsedAt,
  });

  /// Extract data for a specific hour
  HourlyTableData extractHourData(int hourIndex) {
    if (hourIndex < 0 || hourIndex >= TableLogStructure.totalHours) {
      throw ArgumentError(
          'Hour index must be between 0 and ${TableLogStructure.totalHours - 1}');
    }

    final hourLabel = TableLogStructure.hourLabels[hourIndex];
    final data = <String, dynamic>{};
    final fieldConfidences = <String, double>{};

    // Extract each field's value for the specified hour
    for (final entry in rowResults.entries) {
      final result = entry.value;
      final value = result.getValueForHour(hourIndex);

      if (value != null) {
        data[result.fieldName] = value;
        fieldConfidences[result.fieldName] = result.confidence;
      }
    }

    // Calculate hour-specific confidence
    final hourConfidence = fieldConfidences.values.isEmpty
        ? 0.0
        : fieldConfidences.values.reduce((a, b) => a + b) /
            fieldConfidences.values.length;

    return HourlyTableData(
      hourIndex: hourIndex,
      hourLabel: hourLabel,
      data: data,
      fieldConfidences: fieldConfidences,
      confidence: hourConfidence,
      extractedAt: DateTime.now(),
    );
  }

  /// Get statistics about parsing quality
  TableParsingStats get statistics {
    final totalRows = TableLogStructure.standardRows.length;
    final parsedRows = rowResults.length;
    final highConfidenceRows =
        rowResults.values.where((r) => r.isHighConfidence).length;
    final requiredRowsFound = TableLogStructure.standardRows.values
        .where((def) => def.required)
        .where((def) => rowResults.containsKey(def.fieldName))
        .length;

    return TableParsingStats(
      totalRows: totalRows,
      parsedRows: parsedRows,
      highConfidenceRows: highConfidenceRows,
      requiredRowsFound: requiredRowsFound,
      overallConfidence: overallConfidence,
      missingRequiredFields: missingRequiredFields,
    );
  }

  bool get isAcceptable =>
      overallConfidence >= 0.6 && missingRequiredFields.length <= 2;
  bool get isHighQuality =>
      overallConfidence >= 0.8 && missingRequiredFields.isEmpty;
}

/// Data extracted for a specific hour
class HourlyTableData {
  final int hourIndex;
  final String hourLabel;
  final Map<String, dynamic> data;
  final Map<String, double> fieldConfidences;
  final double confidence;
  final DateTime extractedAt;

  const HourlyTableData({
    required this.hourIndex,
    required this.hourLabel,
    required this.data,
    required this.fieldConfidences,
    required this.confidence,
    required this.extractedAt,
  });

  // Convenience getters for typed access
  String get inspectionTime => data['inspectionTime']?.toString() ?? hourLabel;
  int? get vaporInletFpm => _getIntValue('vaporInletFpm');
  int? get dilutionAirFpm => _getIntValue('dilutionAirFpm');
  int? get combustionAirFpm => _getIntValue('combustionAirFpm');
  int? get exhaustTempF => _getIntValue('exhaustTempF');
  double? get spherePressurePsi => _getDoubleValue('spherePressurePsi');
  double? get inletPpm => _getDoubleValue('inletPpm');
  double? get outletPpm => _getDoubleValue('outletPpm');
  int? get totalizerScf => _getIntValue('totalizerScf');

  int? _getIntValue(String key) {
    final value = data[key];
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }

  double? _getDoubleValue(String key) {
    final value = data[key];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Convert to legacy HourlyReading format for compatibility
  Map<String, dynamic> toLegacyFormat() {
    return {
      'inspectionTime': inspectionTime,
      'vaporInletFpm': vaporInletFpm,
      'dilutionAirFpm': dilutionAirFpm,
      'combustionAirFpm': combustionAirFpm,
      'exhaustTempF': exhaustTempF,
      'spherePressurePsi': spherePressurePsi,
      'inletPpm': inletPpm,
      'outletPpm': outletPpm,
      'totalizerScf': totalizerScf,
      'confidence': confidence,
      'hourIndex': hourIndex,
      'extractedAt': extractedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => {
        'hourIndex': hourIndex,
        'hourLabel': hourLabel,
        'data': data,
        'fieldConfidences': fieldConfidences,
        'confidence': confidence,
        'extractedAt': extractedAt.toIso8601String(),
      };
}

/// Statistics about table parsing quality
class TableParsingStats {
  final int totalRows;
  final int parsedRows;
  final int highConfidenceRows;
  final int requiredRowsFound;
  final double overallConfidence;
  final List<String> missingRequiredFields;

  const TableParsingStats({
    required this.totalRows,
    required this.parsedRows,
    required this.highConfidenceRows,
    required this.requiredRowsFound,
    required this.overallConfidence,
    required this.missingRequiredFields,
  });

  double get parseSuccessRate =>
      totalRows == 0 ? 0.0 : (parsedRows / totalRows) * 100;
  double get highConfidenceRate =>
      parsedRows == 0 ? 0.0 : (highConfidenceRows / parsedRows) * 100;
  double get requiredFieldsRate => TableLogStructure.standardRows.values
              .where((def) => def.required).isEmpty
      ? 100.0
      : (requiredRowsFound /
              TableLogStructure.standardRows.values
                  .where((def) => def.required)
                  .length) *
          100;

  bool get isAcceptable => parseSuccessRate >= 60 && requiredFieldsRate >= 80;
  bool get isHighQuality =>
      parseSuccessRate >= 80 &&
      requiredFieldsRate >= 95 &&
      overallConfidence >= 0.8;

  @override
  String toString() {
    return 'TableParsingStats(parsed: $parsedRows/$totalRows, confidence: ${(overallConfidence * 100).toInt()}%, required: $requiredRowsFound)';
  }
}
