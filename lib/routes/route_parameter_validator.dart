import 'package:flutter/foundation.dart';
import '../models/thermal_reading.dart';

/// Utility class for safe route parameter validation and parsing
class RouteParameterValidator {
  /// Safely validate and parse hour parameter
  static int? validateHour(String? hourStr) {
    if (hourStr == null || hourStr.isEmpty) return null;

    final hour = int.tryParse(hourStr);
    if (hour == null || hour < 0 || hour > 23) {
      debugPrint('❌ Invalid hour parameter: $hourStr');
      return null;
    }

    return hour;
  }

  /// Safely extract string parameter from route extra data
  static String? extractStringParam(
    Map<String, dynamic>? args,
    String key, [
    String? defaultValue,
  ]) {
    try {
      final value = args?[key];
      if (value == null) return defaultValue;

      if (value is String) return value;
      return value.toString();
    } catch (e) {
      debugPrint('❌ Failed to extract string parameter $key: $e');
      return defaultValue;
    }
  }

  /// Safely extract non-null string parameter from route extra data
  static String extractNonNullStringParam(
    Map<String, dynamic>? args,
    String key,
    String defaultValue,
  ) {
    try {
      final value = args?[key];
      if (value == null) return defaultValue;

      if (value is String) return value;
      return value.toString();
    } catch (e) {
      debugPrint('❌ Failed to extract string parameter $key: $e');
      return defaultValue;
    }
  }

  /// Safely extract required string parameter from route extra data
  static String extractRequiredStringParam(
    Map<String, dynamic>? args,
    String key,
  ) {
    final value = extractStringParam(args, key);
    if (value == null || value.isEmpty) {
      throw RouteParameterException('Required parameter $key is missing or empty');
    }
    return value;
  }

  /// Safely extract DateTime parameter from route extra data
  static DateTime extractDateTimeParam(
    Map<String, dynamic>? args,
    String key, [
    DateTime? defaultValue,
  ]) {
    try {
      final value = args?[key];
      if (value == null) return defaultValue ?? DateTime.now();

      if (value is DateTime) return value;
      if (value is String) {
        return DateTime.tryParse(value) ?? defaultValue ?? DateTime.now();
      }
      return defaultValue ?? DateTime.now();
    } catch (e) {
      debugPrint('❌ Failed to extract DateTime parameter $key: $e');
      return defaultValue ?? DateTime.now();
    }
  }

  /// Safely extract Set<int> parameter from route extra data
  static Set<int> extractIntSetParam(
    Map<String, dynamic>? args,
    String key, [
    Set<int>? defaultValue,
  ]) {
    try {
      final value = args?[key];
      if (value == null) return defaultValue ?? <int>{};

      if (value is Set<int>) return value;
      if (value is List) {
        return value.whereType<int>().toSet();
      }
      return defaultValue ?? <int>{};
    } catch (e) {
      debugPrint('❌ Failed to extract Set<int> parameter $key: $e');
      return defaultValue ?? <int>{};
    }
  }

  /// Safely extract Function parameter from route extra data
  static T? extractFunctionParam<T extends Function>(
    Map<String, dynamic>? args,
    String key,
  ) {
    try {
      final value = args?[key];
      if (value == null) return null;

      if (value is T) return value;

      debugPrint('❌ Function parameter $key has wrong type: ${value.runtimeType}');
      return null;
    } catch (e) {
      debugPrint('❌ Failed to extract Function parameter $key: $e');
      return null;
    }
  }

  /// Safely convert and validate ThermalReading from route data
  static ThermalReading? validateThermalReading(dynamic data, int fallbackHour) {
    try {
      if (data == null) return null;

      if (data is ThermalReading) {
        return data;
      }

      if (data is Map<String, dynamic>) {
        return _createThermalReadingFromMap(data, fallbackHour);
      }

      debugPrint('❌ ThermalReading data has unsupported type: ${data.runtimeType}');
      return null;
    } catch (e) {
      debugPrint('❌ Failed to validate ThermalReading: $e');
      return null;
    }
  }

  /// Create ThermalReading from Map with safe type conversion
  static ThermalReading _createThermalReadingFromMap(
    Map<String, dynamic> data,
    int fallbackHour,
  ) {
    return ThermalReading(
      hour: _safeIntExtract(data, 'hour') ?? fallbackHour,
      timestamp: _safeStringExtract(data, 'timestamp') ?? DateTime.now().toIso8601String(),
      inletReading: _safeDoubleExtract(data, 'inletReading'),
      outletReading: _safeDoubleExtract(data, 'outletReading'),
      toInletReadingH2S: _safeDoubleExtract(data, 'toInletReadingH2S'),
      vaporInletFlowRateFPM: _safeDoubleExtract(data, 'vaporInletFlowRateFPM'),
      vaporInletFlowRateBBL: _safeDoubleExtract(data, 'vaporInletFlowRateBBL'),
      tankRefillFlowRate: _safeDoubleExtract(data, 'tankRefillFlowRate'),
      combustionAirFlowRate: _safeDoubleExtract(data, 'combustionAirFlowRate'),
      vacuumAtTankVaporOutlet: _safeDoubleExtract(data, 'vacuumAtTankVaporOutlet'),
      exhaustTemperature: _safeDoubleExtract(data, 'exhaustTemperature'),
      totalizer: _safeDoubleExtract(data, 'totalizer'),
      observations: _safeStringExtract(data, 'observations') ?? '',
      operatorId: _safeStringExtract(data, 'operatorId') ?? 'OP001',
      validated: _safeBoolExtract(data, 'validated') ?? false,
    );
  }

  /// Safe int extraction with null handling
  static int? _safeIntExtract(Map<String, dynamic> data, String key) {
    try {
      final value = data[key];
      if (value == null) return null;

      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value);

      return null;
    } catch (e) {
      debugPrint('❌ Failed to extract int for key $key: $e');
      return null;
    }
  }

  /// Safe double extraction with null handling
  static double? _safeDoubleExtract(Map<String, dynamic> data, String key) {
    try {
      final value = data[key];
      if (value == null) return null;

      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);

      return null;
    } catch (e) {
      debugPrint('❌ Failed to extract double for key $key: $e');
      return null;
    }
  }

  /// Safe string extraction with null handling
  static String? _safeStringExtract(Map<String, dynamic> data, String key) {
    try {
      final value = data[key];
      if (value == null) return null;

      if (value is String) return value;
      return value.toString();
    } catch (e) {
      debugPrint('❌ Failed to extract string for key $key: $e');
      return null;
    }
  }

  /// Safe boolean extraction with null handling
  static bool? _safeBoolExtract(Map<String, dynamic> data, String key) {
    try {
      final value = data[key];
      if (value == null) return null;

      if (value is bool) return value;
      if (value is String) {
        return value.toLowerCase() == 'true' || value == '1';
      }
      if (value is int) return value != 0;

      return null;
    } catch (e) {
      debugPrint('❌ Failed to extract bool for key $key: $e');
      return null;
    }
  }

  /// Validate route extra data is properly formatted
  static Map<String, dynamic>? validateRouteExtra(dynamic extra) {
    try {
      if (extra == null) return null;

      if (extra is Map<String, dynamic>) {
        return extra;
      }

      // Try to convert other Map types
      if (extra is Map) {
        final converted = <String, dynamic>{};
        extra.forEach((key, value) {
          if (key is String) {
            converted[key] = value;
          }
        });
        return converted.isNotEmpty ? converted : null;
      }

      debugPrint('❌ Route extra data has unsupported type: ${extra.runtimeType}');
      return null;
    } catch (e) {
      debugPrint('❌ Failed to validate route extra data: $e');
      return null;
    }
  }
}

/// Exception for route parameter validation errors
class RouteParameterException implements Exception {
  final String message;

  const RouteParameterException(this.message);

  @override
  String toString() => 'RouteParameterException: $message';
}