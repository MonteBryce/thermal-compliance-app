import 'form_validation_service.dart';
import '../utils/validation_utils.dart';
import 'package:flutter/foundation.dart';

/// Initialize the validation system for the application
class ValidationInitialization {
  static bool _isInitialized = false;
  
  /// Initialize the validation system - call this once at app startup
  static void initialize() {
    if (_isInitialized) {
      debugPrint('Validation system already initialized');
      return;
    }
    
    debugPrint('Initializing validation system...');
    
    // Initialize thermal logging validators
    ValidationUtils.initialize();
    
    // Register additional custom validators
    _registerApplicationValidators();
    
    _isInitialized = true;
    debugPrint('Validation system initialized successfully');
  }
  
  /// Register application-specific validators
  static void _registerApplicationValidators() {
    final service = FormValidationService();
    
    // Project ID validator
    service.registerValidator('project_id', (value, allFields) {
      if (value.length < 3) {
        return 'Project ID must be at least 3 characters';
      }
      if (!RegExp(r'^[A-Z0-9\-]+$').hasMatch(value)) {
        return 'Project ID can only contain uppercase letters, numbers, and hyphens';
      }
      return null;
    });
    
    // Equipment ID validator
    service.registerValidator('equipment_id', (value, allFields) {
      if (!RegExp(r'^[A-Z]{2,3}-\d{3,4}$').hasMatch(value)) {
        return 'Equipment ID format: XX-123 or XXX-1234';
      }
      return null;
    });
    
    // Operator name validator
    service.registerValidator('operator_name', (value, allFields) {
      if (value.trim().split(' ').length < 2) {
        return 'Please enter first and last name';
      }
      if (value.length < 3) {
        return 'Name must be at least 3 characters';
      }
      return null;
    });
    
    // Date range validator
    service.registerValidator('date_range', (value, allFields) {
      try {
        final date = DateTime.parse(value);
        final now = DateTime.now();
        final thirtyDaysAgo = now.subtract(const Duration(days: 30));
        
        if (date.isAfter(now)) {
          return 'Date cannot be in the future';
        }
        if (date.isBefore(thirtyDaysAgo)) {
          return 'Date cannot be more than 30 days ago';
        }
      } catch (e) {
        return 'Invalid date format';
      }
      return null;
    });
    
    // Cross-field consistency validators
    service.registerValidator('inlet_outlet_consistency', (value, allFields) {
      if (allFields == null) return null;
      
      final inlet = double.tryParse(allFields['inletReading']?.toString() ?? '');
      final outlet = double.tryParse(allFields['outletReading']?.toString() ?? '');
      
      if (inlet != null && outlet != null) {
        final efficiency = ((inlet - outlet) / inlet) * 100;
        
        if (efficiency < 0) {
          return 'Outlet reading cannot exceed inlet reading';
        }
        if (efficiency < 95) {
          return 'Low thermal efficiency (${efficiency.toStringAsFixed(1)}%) - check equipment';
        }
      }
      return null;
    });
    
    // Safety threshold validator
    service.registerValidator('safety_threshold', (value, allFields) {
      final numValue = double.tryParse(value);
      if (numValue == null) return null;
      
      // H2S safety threshold
      if (allFields?['field_type'] == 'h2s' && numValue > 20) {
        return 'H₂S reading above safety threshold (20 PPM) - immediate action required';
      }
      
      // LEL safety threshold
      if (allFields?['field_type'] == 'lel' && numValue > 50) {
        return 'LEL reading above critical threshold (50%) - shutdown required';
      }
      
      return null;
    });
    
    // Marathon-specific validators
    service.registerValidator('marathon_temperature', (value, allFields) {
      final temp = double.tryParse(value);
      if (temp == null) return null;
      
      if (temp < 1200) {
        return 'Temperature below Marathon minimum (1200°F)';
      }
      if (temp > 1500) {
        return 'Temperature above Marathon maximum (1500°F) - risk of equipment damage';
      }
      return null;
    });
  }
  
  /// Check if validation system is initialized
  static bool get isInitialized => _isInitialized;
  
  /// Reset initialization (for testing)
  @visibleForTesting
  static void reset() {
    _isInitialized = false;
  }
}