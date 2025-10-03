import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Represents a single field match from OCR parsing with confidence metrics
class FieldMatch {
  final String name;
  final dynamic value;
  final double confidence;
  final String rawMatch;
  final int position;
  final FieldType type;
  final String? unit;
  final ValidationResult validation;

  const FieldMatch({
    required this.name,
    required this.value,
    required this.confidence,
    required this.rawMatch,
    required this.position,
    required this.type,
    this.unit,
    required this.validation,
  });

  bool get isValid => validation.isValid && confidence >= 0.5;
  bool get isHighConfidence => confidence >= 0.8;

  Map<String, dynamic> toJson() => {
        'name': name,
        'value': value,
        'confidence': confidence,
        'rawMatch': rawMatch,
        'position': position,
        'type': type.name,
        'unit': unit,
        'validation': validation.toJson(),
      };

  factory FieldMatch.fromJson(Map<String, dynamic> json) => FieldMatch(
        name: json['name'],
        value: json['value'],
        confidence: json['confidence'],
        rawMatch: json['rawMatch'],
        position: json['position'],
        type: FieldType.values.firstWhere((e) => e.name == json['type']),
        unit: json['unit'],
        validation: ValidationResult.fromJson(json['validation']),
      );

  @override
  String toString() =>
      'FieldMatch($name: $value, conf: ${(confidence * 100).toInt()}%)';
}

/// Field type enumeration for type safety
enum FieldType {
  time,
  flowRate,
  temperature,
  pressure,
  concentration,
  totalizer,
  text,
  numeric
}

/// Validation result for field values
class ValidationResult {
  final bool isValid;
  final List<String> warnings;
  final List<String> errors;
  final String? suggestedValue;

  const ValidationResult({
    required this.isValid,
    this.warnings = const [],
    this.errors = const [],
    this.suggestedValue,
  });

  factory ValidationResult.valid() => const ValidationResult(isValid: true);

  factory ValidationResult.invalid(List<String> errors,
          {List<String> warnings = const []}) =>
      ValidationResult(isValid: false, errors: errors, warnings: warnings);

  Map<String, dynamic> toJson() => {
        'isValid': isValid,
        'warnings': warnings,
        'errors': errors,
        'suggestedValue': suggestedValue,
      };

  factory ValidationResult.fromJson(Map<String, dynamic> json) =>
      ValidationResult(
        isValid: json['isValid'],
        warnings: List<String>.from(json['warnings'] ?? []),
        errors: List<String>.from(json['errors'] ?? []),
        suggestedValue: json['suggestedValue'],
      );
}

/// Structured hourly reading data
class HourlyReading {
  final String inspectionTime;
  final int? vaporInletFpm;
  final int? dilutionAirFpm;
  final int? combustionAirFpm;
  final int? exhaustTempF;
  final double? spherePressurePsi;
  final double? inletPpm;
  final double? outletPpm;
  final int? totalizerScf;
  final double overallConfidence;
  final List<FieldMatch> fieldMatches;
  final DateTime parsedAt;
  final String rawOcrText;

  const HourlyReading({
    required this.inspectionTime,
    this.vaporInletFpm,
    this.dilutionAirFpm,
    this.combustionAirFpm,
    this.exhaustTempF,
    this.spherePressurePsi,
    this.inletPpm,
    this.outletPpm,
    this.totalizerScf,
    required this.overallConfidence,
    required this.fieldMatches,
    required this.parsedAt,
    required this.rawOcrText,
  });

  /// Create from field matches with validation
  factory HourlyReading.fromFieldMatches(
    String inspectionTime,
    List<FieldMatch> matches,
    String rawText,
  ) {
    final fieldMap = <String, FieldMatch>{};
    for (final match in matches) {
      fieldMap[match.name] = match;
    }

    final overallConfidence = matches.isEmpty
        ? 0.0
        : matches.map((m) => m.confidence).reduce((a, b) => a + b) /
            matches.length;

    final vaporInletFpm = _extractIntValue(fieldMap['vaporInletFpm']);
    final exhaustTempF = _extractIntValue(fieldMap['exhaustTempF']);
    final inletPpm = _extractDoubleValue(fieldMap['inletPpm']);

    debugPrint(
        '🔧 fromFieldMatches: vaporInletFpm=$vaporInletFpm, exhaustTempF=$exhaustTempF, inletPpm=$inletPpm');
    debugPrint('🔧 fromFieldMatches: fieldMap keys=${fieldMap.keys.toList()}');

    return HourlyReading(
      inspectionTime: inspectionTime,
      vaporInletFpm: vaporInletFpm,
      dilutionAirFpm: _extractIntValue(fieldMap['dilutionAirFpm']),
      combustionAirFpm: _extractIntValue(fieldMap['combustionAirFpm']),
      exhaustTempF: exhaustTempF,
      spherePressurePsi: _extractDoubleValue(fieldMap['spherePressurePsi']),
      inletPpm: inletPpm,
      outletPpm: _extractDoubleValue(fieldMap['outletPpm']),
      totalizerScf: _extractIntValue(fieldMap['totalizerScf']),
      overallConfidence: overallConfidence,
      fieldMatches: matches,
      parsedAt: DateTime.now(),
      rawOcrText: rawText,
    );
  }

  static int? _extractIntValue(FieldMatch? match) {
    if (match?.value == null) return null;
    if (match!.value is int) return match.value;
    if (match.value is double) return (match.value as double).round();
    if (match.value is String) return int.tryParse(match.value);
    debugPrint(
        '🔧 _extractIntValue: match=$match, value=${match.value}, type=${match.value.runtimeType}');
    return null;
  }

  static double? _extractDoubleValue(FieldMatch? match) {
    if (match?.value == null) return null;
    if (match!.value is double) return match.value;
    if (match.value is int) return (match.value as int).toDouble();
    if (match.value is String) return double.tryParse(match.value);
    debugPrint(
        '🔧 _extractDoubleValue: match=$match, value=${match.value}, type=${match.value.runtimeType}');
    return null;
  }

  /// Quality assessment
  bool get isHighQuality =>
      overallConfidence >= 0.8 && fieldMatches.length >= 6;
  bool get isAcceptable => overallConfidence >= 0.6 && fieldMatches.length >= 4;

  int get validFieldCount => fieldMatches.where((m) => m.isValid).length;
  int get highConfidenceFieldCount =>
      fieldMatches.where((m) => m.isHighConfidence).length;

  Map<String, dynamic> toJson() => {
        'inspectionTime': inspectionTime,
        'vaporInletFpm': vaporInletFpm,
        'dilutionAirFpm': dilutionAirFpm,
        'combustionAirFpm': combustionAirFpm,
        'exhaustTempF': exhaustTempF,
        'spherePressurePsi': spherePressurePsi,
        'inletPpm': inletPpm,
        'outletPpm': outletPpm,
        'totalizerScf': totalizerScf,
        'overallConfidence': overallConfidence,
        'fieldMatches': fieldMatches.map((m) => m.toJson()).toList(),
        'parsedAt': parsedAt.toIso8601String(),
        'rawOcrText': rawOcrText,
      };

  factory HourlyReading.fromJson(Map<String, dynamic> json) => HourlyReading(
        inspectionTime: json['inspectionTime'],
        vaporInletFpm: json['vaporInletFpm'],
        dilutionAirFpm: json['dilutionAirFpm'],
        combustionAirFpm: json['combustionAirFpm'],
        exhaustTempF: json['exhaustTempF'],
        spherePressurePsi: json['spherePressurePsi']?.toDouble(),
        inletPpm: json['inletPpm']?.toDouble(),
        outletPpm: json['outletPpm']?.toDouble(),
        totalizerScf: json['totalizerScf'],
        overallConfidence: json['overallConfidence'],
        fieldMatches: (json['fieldMatches'] as List)
            .map((m) => FieldMatch.fromJson(m))
            .toList(),
        parsedAt: DateTime.parse(json['parsedAt']),
        rawOcrText: json['rawOcrText'],
      );

  @override
  String toString() =>
      'HourlyReading($inspectionTime, conf: ${(overallConfidence * 100).toInt()}%, fields: ${fieldMatches.length})';
}

/// Parsing configuration for different log formats
class LogParsingConfig {
  final Map<String, FieldPattern> fieldPatterns;
  final List<String> timeFormats;
  final double minConfidenceThreshold;
  final int maxColumnDistance;
  final bool strictAlignment;

  const LogParsingConfig({
    required this.fieldPatterns,
    this.timeFormats = const ['HH:mm', 'H:mm', 'HHmm'],
    this.minConfidenceThreshold = 0.5,
    this.maxColumnDistance = 100,
    this.strictAlignment = true,
  });

  static LogParsingConfig get standard => const LogParsingConfig(
        fieldPatterns: {
          'vaporInletFpm': const FieldPattern(
            pattern: r'(\d{1,5})',
            type: FieldType.flowRate,
            unit: 'FPM',
            expectedRange: (0, 10000),
            aliases: ['vapor inlet', 'vapor in', 'inlet fpm'],
          ),
          'dilutionAirFpm': const FieldPattern(
            pattern: r'(\d{1,5})',
            type: FieldType.flowRate,
            unit: 'FPM',
            expectedRange: (0, 5000),
            aliases: ['dilution air', 'dilution', 'dil air'],
          ),
          'combustionAirFpm': const FieldPattern(
            pattern: r'(\d{1,5})',
            type: FieldType.flowRate,
            unit: 'FPM',
            expectedRange: (0, 5000),
            aliases: ['combustion air', 'comb air', 'combustion'],
          ),
          'exhaustTempF': const FieldPattern(
            pattern: r'(\d{3,4})',
            type: FieldType.temperature,
            unit: '°F',
            expectedRange: (500, 2000),
            aliases: ['exhaust temp', 'temperature', 'temp'],
          ),
          'spherePressurePsi': const FieldPattern(
            pattern: r'(\d{1,3}\.?\d*)',
            type: FieldType.pressure,
            unit: 'PSI',
            expectedRange: (0, 50),
            aliases: ['sphere pressure', 'pressure', 'psi'],
          ),
          'inletPpm': const FieldPattern(
            pattern: r'(\d{1,6}\.?\d*)',
            type: FieldType.concentration,
            unit: 'PPM',
            expectedRange: (0, 100000),
            aliases: ['inlet ppm', 'in ppm', 'inlet'],
          ),
          'outletPpm': const FieldPattern(
            pattern: r'(\d{1,6}\.?\d*)',
            type: FieldType.concentration,
            unit: 'PPM',
            expectedRange: (0, 1000),
            aliases: ['outlet ppm', 'out ppm', 'outlet'],
          ),
          'totalizerScf': const FieldPattern(
            pattern: r'(\d{4,10})',
            type: FieldType.totalizer,
            unit: 'SCF',
            expectedRange: (1000, 999999999),
            aliases: ['totalizer', 'total', 'scf'],
          ),
        },
      );
}

/// Field pattern definition for parsing
class FieldPattern {
  final String pattern;
  final FieldType type;
  final String unit;
  final (double, double) expectedRange;
  final List<String> aliases;
  final bool required;

  const FieldPattern({
    required this.pattern,
    required this.type,
    required this.unit,
    required this.expectedRange,
    this.aliases = const [],
    this.required = true,
  });

  RegExp get regex => RegExp(pattern, caseSensitive: false);

  bool isInExpectedRange(dynamic value) {
    final numValue =
        value is num ? value.toDouble() : double.tryParse(value.toString());
    if (numValue == null) return false;
    return numValue >= expectedRange.$1 && numValue <= expectedRange.$2;
  }
}
