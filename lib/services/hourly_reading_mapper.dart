import '../models/hive_models.dart';
import '../models/thermal_reading.dart';
import '../models/thermal_log.dart';

/// Service for mapping hourly reading form data to various data structures
/// Bridges the gap between form input, local storage, and Firebase
class HourlyReadingMapper {
  /// Map enhanced form data to LogEntry for Hive storage
  static LogEntry mapToLogEntry({
    required String projectId,
    required String projectName,
    required DateTime date,
    required int hour,
    required Map<String, dynamic> formData,
    required String userId,
    String? existingId,
  }) {
    final id = existingId ?? _generateId(projectId, date, hour);

    // Transform form data to structured format
    final structuredData = _structureFormData(formData, hour);

    return LogEntry(
      id: id,
      projectId: projectId,
      projectName: projectName,
      date: date.toIso8601String().split('T')[0], // YYYY-MM-DD format
      hour: hour.toString().padLeft(2, '0'), // 00-23 format
      data: structuredData,
      status: _determineStatus(structuredData),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: userId,
      isSynced: false,
    );
  }

  /// Map LogEntry to ThermalReading for display/export
  static ThermalReading mapToThermalReading(LogEntry entry) {
    final data = entry.data;
    final hour = int.tryParse(entry.hour) ?? 0;

    return ThermalReading(
      hour: hour,
      timestamp: '${entry.date} ${entry.hour}:00',
      // Primary readings
      inletReading: _parseDouble(data['inlet_reading'] ?? data['inletReading']),
      outletReading: _parseDouble(data['outlet_reading'] ?? data['outletReading']),
      toInletReadingH2S: _parseDouble(data['to_inlet_reading_h2s'] ?? data['toInletReadingH2S']),
      lelInletReading: _parseDouble(data['lel_inlet_reading'] ?? data['lelInletReading']),
      // Flow rates
      vaporInletFlowRateFPM: _parseDouble(data['vapor_inlet_flow_rate_fpm'] ?? data['vaporInletFlowRateFPM']),
      vaporInletFlowRateBBL: _parseDouble(data['vapor_inlet_flow_rate_bbl'] ?? data['vaporInletFlowRateBBL']),
      tankRefillFlowRate: _parseDouble(data['tank_refill_flow_rate'] ?? data['tankRefillFlowRate']),
      combustionAirFlowRate: _parseDouble(data['combustion_air_flow_rate'] ?? data['combustionAirFlowRate']),
      // System metrics
      vacuumAtTankVaporOutlet: _parseDouble(data['vacuum_at_tank_vapor_outlet'] ?? data['vacuumAtTankVaporOutlet']),
      exhaustTemperature: _parseDouble(data['exhaust_temperature'] ?? data['exhaustTemperature']),
      totalizer: _parseDouble(data['totalizer']),
      // Metadata
      observations: data['observations']?.toString() ?? '',
      operatorId: data['operator_id']?.toString() ?? entry.createdBy,
      validated: data['validated'] == true,
    );
  }

  /// Map LogEntry to Firestore-compatible format
  static Map<String, dynamic> mapToFirestore(LogEntry entry) {
    return {
      'id': entry.id,
      'projectId': entry.projectId,
      'projectName': entry.projectName,
      'date': entry.date,
      'hour': entry.hour,
      'hourInt': int.tryParse(entry.hour) ?? 0,
      'timestamp': DateTime.parse('${entry.date}T${entry.hour.padLeft(2, '0')}:00:00'),
      'data': _normalizeDataForFirestore(entry.data),
      'status': entry.status,
      'createdAt': entry.createdAt,
      'updatedAt': entry.updatedAt,
      'createdBy': entry.createdBy,
      'syncTimestamp': entry.syncTimestamp ?? DateTime.now(),
      // Additional metadata for queries
      'yearMonth': entry.date.substring(0, 7), // YYYY-MM for monthly queries
      'weekNumber': _getWeekNumber(DateTime.parse(entry.date)),
      'isComplete': entry.status == 'completed',
      'hasWarnings': _hasWarnings(entry.data),
      'hasErrors': _hasErrors(entry.data),
    };
  }

  /// Map Firestore data back to LogEntry
  static LogEntry mapFromFirestore(Map<String, dynamic> data) {
    return LogEntry(
      id: data['id'] ?? '',
      projectId: data['projectId'] ?? '',
      projectName: data['projectName'] ?? '',
      date: data['date'] ?? DateTime.now().toIso8601String().split('T')[0],
      hour: data['hour']?.toString() ?? '00',
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      status: data['status'] ?? 'pending',
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
      createdBy: data['createdBy'] ?? '',
      isSynced: true,
      syncTimestamp: _parseDateTime(data['syncTimestamp']),
    );
  }

  /// Structure form data into organized categories
  static Map<String, dynamic> _structureFormData(Map<String, dynamic> formData, int hour) {
    final structured = <String, dynamic>{
      'hour': hour,
      'timestamp': DateTime.now().toIso8601String(),

      // Gas readings
      'gas_readings': {
        'inlet_reading': formData['inlet_reading'],
        'outlet_reading': formData['outlet_reading'],
        'to_inlet_reading_h2s': formData['to_inlet_reading_h2s'],
        'lel_inlet_reading': formData['lel_inlet_reading'],
      },

      // Flow rates
      'flow_rates': {
        'vapor_inlet_flow_rate_fpm': formData['vapor_inlet_flow_rate_fpm'],
        'vapor_inlet_flow_rate_bbl': formData['vapor_inlet_flow_rate_bbl'],
        'tank_refill_flow_rate': formData['tank_refill_flow_rate'],
        'combustion_air_flow_rate': formData['combustion_air_flow_rate'],
      },

      // System metrics
      'system_metrics': {
        'vacuum_at_tank_vapor_outlet': formData['vacuum_at_tank_vapor_outlet'],
        'exhaust_temperature': formData['exhaust_temperature'],
        'totalizer': formData['totalizer'],
      },

      // Metadata
      'metadata': {
        'observations': formData['observations'] ?? '',
        'operator_id': formData['operator_id'],
        'validated': formData['validated'] ?? false,
        'form_template': formData['form_template'] ?? 'standard',
        'entry_method': formData['entry_method'] ?? 'manual',
      },

      // Validation results
      'validation': {
        'has_warnings': formData['has_warnings'] ?? false,
        'has_errors': formData['has_errors'] ?? false,
        'warning_messages': formData['warning_messages'] ?? [],
        'error_messages': formData['error_messages'] ?? [],
      },
    };

    // Also keep flat structure for backward compatibility
    structured.addAll(formData);

    return structured;
  }

  /// Normalize data for Firestore storage
  static Map<String, dynamic> _normalizeDataForFirestore(Map<String, dynamic> data) {
    final normalized = <String, dynamic>{};

    data.forEach((key, value) {
      if (value == null) {
        // Skip null values
      } else if (value is DateTime) {
        normalized[key] = value.toIso8601String();
      } else if (value is Map) {
        normalized[key] = _normalizeDataForFirestore(value as Map<String, dynamic>);
      } else if (value is List) {
        normalized[key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return _normalizeDataForFirestore(item);
          }
          return item;
        }).toList();
      } else {
        normalized[key] = value;
      }
    });

    return normalized;
  }

  /// Generate unique ID for log entry
  static String _generateId(String projectId, DateTime date, int hour) {
    final dateStr = date.toIso8601String().split('T')[0].replaceAll('-', '');
    final hourStr = hour.toString().padLeft(2, '0');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${projectId}_${dateStr}_${hourStr}_$timestamp';
  }

  /// Determine status based on data completeness
  static String _determineStatus(Map<String, dynamic> data) {
    // Check validation flags first
    if (data['validation']?['has_errors'] == true) return 'error';

    final requiredFields = [
      'inlet_reading',
      'outlet_reading',
      'exhaust_temperature',
    ];

    final missingFields = requiredFields.where((field) {
      final value = data[field];
      return value == null || value.toString().isEmpty;
    }).toList();

    if (missingFields.isEmpty) {
      return 'completed';
    } else if (missingFields.length < requiredFields.length) {
      return 'partial';
    } else {
      return 'pending';
    }
  }

  /// Check if data has warnings
  static bool _hasWarnings(Map<String, dynamic> data) {
    // Check for out-of-range values
    final inlet = _parseDouble(data['inlet_reading']);
    final outlet = _parseDouble(data['outlet_reading']);
    final exhaust = _parseDouble(data['exhaust_temperature']);

    if (inlet != null && (inlet < 0 || inlet > 1000)) return true;
    if (outlet != null && (outlet < 0 || outlet > 1000)) return true;
    if (exhaust != null && (exhaust < 200 || exhaust > 2000)) return true;

    // Check validation flags
    if (data['validation']?['has_warnings'] == true) return true;

    return false;
  }

  /// Check if data has errors
  static bool _hasErrors(Map<String, dynamic> data) {
    // Check validation flags only
    if (data['validation']?['has_errors'] == true) return true;

    // Don't check for missing fields here - that's handled in _determineStatus
    // This is only for actual validation errors

    return false;
  }

  /// Parse double value safely
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return double.tryParse(trimmed);
    }
    return null;
  }

  /// Parse DateTime safely
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }

  /// Get week number for date
  static int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return ((daysSinceFirstDay + firstDayOfYear.weekday - 1) / 7).ceil();
  }

  /// Create batch of hourly entries for a day
  static List<LogEntry> createDailyBatch({
    required String projectId,
    required String projectName,
    required DateTime date,
    required String userId,
    String? templateName,
  }) {
    final entries = <LogEntry>[];

    for (int hour = 0; hour < 24; hour++) {
      entries.add(LogEntry(
        id: _generateId(projectId, date, hour),
        projectId: projectId,
        projectName: projectName,
        date: date.toIso8601String().split('T')[0],
        hour: hour.toString().padLeft(2, '0'),
        data: {
          'hour': hour,
          'template': templateName ?? 'standard',
          'status': 'pending',
        },
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: userId,
        isSynced: false,
      ));
    }

    return entries;
  }
}