

class ValidationRule {
  final double? min;
  final double? max;
  final bool required;
  final String? errorMessage;

  const ValidationRule({
    this.min,
    this.max,
    this.required = true,
    this.errorMessage,
  });

  String? validate(String? value, String fieldName) {
    if (required && (value == null || value.isEmpty)) {
      return errorMessage ?? '$fieldName is required';
    }

    if (value != null && value.isNotEmpty) {
      final numValue = double.tryParse(value);
      if (numValue == null) {
        return '$fieldName must be a valid number';
      }

      if (min != null && numValue < min!) {
        return '$fieldName must be at least ${min!}';
      }

      if (max != null && numValue > max!) {
        return '$fieldName must be no more than ${max!}';
      }
    }

    return null;
  }
}

class LogTypeValidation {
  final Map<String, ValidationRule> rules;
  final List<String> requiredFields;

  const LogTypeValidation({
    required this.rules,
    required this.requiredFields,
  });
}

class ValidationService {
  static final Map<String, LogTypeValidation> _validationRules = {
    'degas': const LogTypeValidation(
      rules: {
        'inletReading': const ValidationRule(min: 0, max: 100),
        'outletReading': const ValidationRule(min: 0, max: 100),
        'toInletReadingH2S': const ValidationRule(min: 0, max: 1000),
        'vaporInletFlowRateFPM': const ValidationRule(min: 0),
        'vaporInletFlowRateBBL': const ValidationRule(min: 0),
        'tankRefillFlowRate': const ValidationRule(min: 0),
        'combustionAirFlowRate': const ValidationRule(min: 0),
        'vacuumAtTankVaporOutlet': const ValidationRule(min: 2),
        'exhaustTemperature': const ValidationRule(min: 300, max: 1200),
        'totalizer': const ValidationRule(min: 0),
      },
      requiredFields: [
        'inletReading',
        'outletReading',
        'vaporInletFlowRateFPM',
        'vacuumAtTankVaporOutlet',
        'exhaustTemperature',
      ],
    ),
    'thermal': const LogTypeValidation(
      rules: {
        'inletReading': const ValidationRule(min: 0, max: 1000),
        'outletReading': const ValidationRule(min: 0, max: 1000),
        'exhaustTemperature': const ValidationRule(min: 200, max: 1500),
        'totalizer': const ValidationRule(min: 0),
      },
      requiredFields: [
        'inletReading',
        'outletReading',
        'exhaustTemperature',
      ],
    ),
    // Add more log types as needed
  };

  static LogTypeValidation getValidationForType(String logType) {
    return _validationRules[logType.toLowerCase()] ?? 
      const LogTypeValidation(rules: {}, requiredFields: []);
  }

  static Map<String, String> validateEntry({
    required String logType,
    required Map<String, dynamic> data,
  }) {
    final validation = getValidationForType(logType);
    final errors = <String, String>{};

    // Check required fields
    for (final field in validation.requiredFields) {
      final value = data[field]?.toString();
      if (value == null || value.isEmpty) {
        errors[field] = '$field is required';
      }
    }

    // Apply validation rules
    validation.rules.forEach((field, rule) {
      final value = data[field]?.toString();
      final error = rule.validate(value, field);
      if (error != null) {
        errors[field] = error;
      }
    });

    return errors;
  }
}