/// Data model for OCR extracted results from field logs
class OcrResult {
  final String rawText;
  final DateTime scanTimestamp;
  final List<ExtractedField> extractedFields;
  final double confidence;
  
  const OcrResult({
    required this.rawText,
    required this.scanTimestamp,
    required this.extractedFields,
    this.confidence = 0.0,
  });
  
  Map<String, dynamic> toJson() => {
    'rawText': rawText,
    'scanTimestamp': scanTimestamp.toIso8601String(),
    'extractedFields': extractedFields.map((f) => f.toJson()).toList(),
    'confidence': confidence,
  };
  
  factory OcrResult.fromJson(Map<String, dynamic> json) => OcrResult(
    rawText: json['rawText'] ?? '',
    scanTimestamp: DateTime.parse(json['scanTimestamp']),
    extractedFields: (json['extractedFields'] as List?)
        ?.map((f) => ExtractedField.fromJson(f))
        .toList() ?? [],
    confidence: json['confidence']?.toDouble() ?? 0.0,
  );
}

/// Individual field extracted from OCR
class ExtractedField {
  final String fieldName;
  final String value;
  final FieldType type;
  final double confidence;
  final String unit;
  
  const ExtractedField({
    required this.fieldName,
    required this.value,
    required this.type,
    this.confidence = 0.0,
    this.unit = '',
  });
  
  Map<String, dynamic> toJson() => {
    'fieldName': fieldName,
    'value': value,
    'type': type.name,
    'confidence': confidence,
    'unit': unit,
  };
  
  factory ExtractedField.fromJson(Map<String, dynamic> json) => ExtractedField(
    fieldName: json['fieldName'] ?? '',
    value: json['value'] ?? '',
    type: FieldType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => FieldType.text,
    ),
    confidence: json['confidence']?.toDouble() ?? 0.0,
    unit: json['unit'] ?? '',
  );
  
  /// Convert to ThermalReading field value with proper type
  dynamic get typedValue {
    switch (type) {
      case FieldType.temperature:
      case FieldType.pressure:
      case FieldType.flowRate:
      case FieldType.ppm:
        return double.tryParse(value.replaceAll(RegExp(r'[^\d.-]'), ''));
      case FieldType.hour:
        return int.tryParse(value.replaceAll(RegExp(r'[^\d]'), ''));
      case FieldType.time:
        return _parseTime();
      case FieldType.text:
      default:
        return value;
    }
  }
  
  DateTime? _parseTime() {
    // Try to parse various time formats
    final timePatterns = [
      RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)', caseSensitive: false),
      RegExp(r'(\d{1,2}):(\d{2})'),
      RegExp(r'(\d{4})', caseSensitive: false), // 24-hour format like 1430
    ];
    
    for (final pattern in timePatterns) {
      final match = pattern.firstMatch(value);
      if (match != null) {
        try {
          int hour = int.parse(match.group(1)!);
          int minute = match.groupCount >= 2 ? int.parse(match.group(2)!) : 0;
          
          if (match.groupCount >= 3 && match.group(3) != null) {
            // 12-hour format
            final amPm = match.group(3)!.toUpperCase();
            if (amPm == 'PM' && hour != 12) hour += 12;
            if (amPm == 'AM' && hour == 12) hour = 0;
          }
          
          final now = DateTime.now();
          return DateTime(now.year, now.month, now.day, hour, minute);
        } catch (e) {
          continue;
        }
      }
    }
    return null;
  }
}

/// Types of fields we can extract from field logs
enum FieldType {
  temperature,
  pressure,
  flowRate,
  ppm,
  hour,
  time,
  text,
}

/// Predefined patterns for common field operations data
class FieldDataPatterns {
  // Temperature patterns (°F, °C, F, C)
  static final temperaturePattern = RegExp(
    r'(\d+\.?\d*)\s*°?[FC]?\s*(?:°F|°C|F|C|deg)',
    caseSensitive: false,
  );
  
  // PPM patterns
  static final ppmPattern = RegExp(
    r'(\d+\.?\d*)\s*(?:ppm|PPM)',
    caseSensitive: false,
  );
  
  // Flow rate patterns (CFM, FPM, BBL, GPM)
  static final flowRatePattern = RegExp(
    r'(\d+\.?\d*)\s*(?:CFM|FPM|BBL|GPM|cfm|fpm|bbl|gpm)',
    caseSensitive: false,
  );
  
  // Pressure patterns (PSI, inHg, etc.)
  static final pressurePattern = RegExp(
    r'(\d+\.?\d*)\s*(?:PSI|psi|inHg|inhg|\"HG|bar)',
    caseSensitive: false,
  );
  
  // Hour patterns (Hr, Hour, H)
  static final hourPattern = RegExp(
    r'(?:hr|hour|h)\s*:?\s*(\d{1,2})',
    caseSensitive: false,
  );
  
  // Time patterns (12:30 PM, 1430, etc.)
  static final timePattern = RegExp(
    r'(\d{1,2}):(\d{2})\s*(AM|PM)|(\d{4})',
    caseSensitive: false,
  );
  
  /// Extract all recognizable field data from raw text
  static List<ExtractedField> extractFields(String text) {
    final fields = <ExtractedField>[];
    
    // Extract temperatures
    for (final match in temperaturePattern.allMatches(text)) {
      fields.add(ExtractedField(
        fieldName: 'Temperature',
        value: match.group(1)!,
        type: FieldType.temperature,
        unit: '°F',
        confidence: 0.8,
      ));
    }
    
    // Extract PPM values
    for (final match in ppmPattern.allMatches(text)) {
      fields.add(ExtractedField(
        fieldName: 'PPM',
        value: match.group(1)!,
        type: FieldType.ppm,
        unit: 'ppm',
        confidence: 0.9,
      ));
    }
    
    // Extract flow rates
    for (final match in flowRatePattern.allMatches(text)) {
      final unit = match.group(0)!.replaceAll(RegExp(r'[\d\.\s]'), '');
      fields.add(ExtractedField(
        fieldName: 'Flow Rate',
        value: match.group(1)!,
        type: FieldType.flowRate,
        unit: unit.toUpperCase(),
        confidence: 0.8,
      ));
    }
    
    // Extract pressure values
    for (final match in pressurePattern.allMatches(text)) {
      final unit = match.group(0)!.replaceAll(RegExp(r'[\d\.\s]'), '');
      fields.add(ExtractedField(
        fieldName: 'Pressure',
        value: match.group(1)!,
        type: FieldType.pressure,
        unit: unit,
        confidence: 0.8,
      ));
    }
    
    // Extract hours
    for (final match in hourPattern.allMatches(text)) {
      fields.add(ExtractedField(
        fieldName: 'Hour',
        value: match.group(1)!,
        type: FieldType.hour,
        confidence: 0.9,
      ));
    }
    
    return fields;
  }
}