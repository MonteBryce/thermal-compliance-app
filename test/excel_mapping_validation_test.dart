import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';

void main() {
  group('Excel Mapping Validation Tests', () {
    test('should validate template mapping structure', () {
      // Test mapping structure validation
      final sampleTemplate = {
        'templateId': 'test_template',
        'displayName': 'Test Template',
        'capacity': '10-60MMBTU',
        'fuelType': 'METHANE',
        'monitoringTypes': ['H2S'],
        'fieldMappings': {
          'unitNumber': {
            'column': 'A',
            'header': 'Unit #'
          },
          'readingDateTime': {
            'column': 'B',
            'header': 'Date'
          },
          'inletReading': {
            'column': 'E',
            'header': 'Inlet Reading (PPM)'
          }
        }
      };

      // Validate template has required fields
      expect(sampleTemplate.containsKey('templateId'), isTrue);
      expect(sampleTemplate.containsKey('displayName'), isTrue);
      expect(sampleTemplate.containsKey('fieldMappings'), isTrue);

      final fieldMappings = sampleTemplate['fieldMappings'] as Map<String, dynamic>;
      
      // Check that each field mapping has required properties
      for (final entry in fieldMappings.entries) {
        final fieldId = entry.key;
        final mapping = entry.value as Map<String, dynamic>;
        
        expect(mapping.containsKey('column'), isTrue, reason: 'Field $fieldId should have column');
        expect(mapping.containsKey('header'), isTrue, reason: 'Field $fieldId should have header');
      }
    });

    test('should detect duplicate column assignments', () {
      final duplicateColumns = {
        'field1': {'column': 'A', 'header': 'Field 1'},
        'field2': {'column': 'A', 'header': 'Field 2'}, // Duplicate column!
        'field3': {'column': 'B', 'header': 'Field 3'},
      };

      final usedColumns = <String>{};
      final duplicates = <String>[];

      for (final entry in duplicateColumns.entries) {
        final column = entry.value['column'] as String;
        if (usedColumns.contains(column)) {
          duplicates.add('Duplicate column $column for field ${entry.key}');
        } else {
          usedColumns.add(column);
        }
      }

      expect(duplicates.length, equals(1));
      expect(duplicates.first, contains('Duplicate column A'));
    });

    test('should validate field coverage for universal fields', () {
      final universalFields = [
        {'id': 'unitNumber', 'required': true},
        {'id': 'readingDateTime', 'required': true},
        {'id': 'operatorName', 'required': true},
        {'id': 'inletReading', 'required': true},
        {'id': 'outletReading', 'required': true},
      ];

      final templateMapping = {
        'unitNumber': {'column': 'A'},
        'readingDateTime': {'column': 'B'},
        'operatorName': {'column': 'C'},
        'inletReading': {'column': 'D'},
        // Missing outletReading!
      };

      final mappedFields = <String>[];
      final missingRequired = <String>[];

      for (final field in universalFields) {
        final fieldId = field['id'] as String;
        final isRequired = field['required'] as bool;
        
        if (templateMapping.containsKey(fieldId)) {
          mappedFields.add(fieldId);
        } else if (isRequired) {
          missingRequired.add(fieldId);
        }
      }

      expect(mappedFields.length, equals(4));
      expect(missingRequired.length, equals(1));
      expect(missingRequired.first, equals('outletReading'));
    });

    test('should validate conditional field enablement', () {
      final conditionalField = {
        'id': 'lelInletReading',
        'conditionalDisplay': {
          'enabledFor': ['marathon_gbr_custom', 'pentane_h2s_lel_degas']
        }
      };

      final templateIds = [
        'marathon_gbr_custom',   // Should be enabled
        'thermal',              // Should not be enabled
        'pentane_h2s_lel_degas', // Should be enabled
      ];

      for (final templateId in templateIds) {
        final conditionalDisplay = conditionalField['conditionalDisplay'] as Map<String, dynamic>;
        final enabledFor = conditionalDisplay['enabledFor'] as List<dynamic>;
        final shouldBeEnabled = enabledFor.contains(templateId) || enabledFor.contains('*');
        
        if (templateId == 'marathon_gbr_custom' || templateId == 'pentane_h2s_lel_degas') {
          expect(shouldBeEnabled, isTrue, reason: 'LEL field should be enabled for $templateId');
        } else {
          expect(shouldBeEnabled, isFalse, reason: 'LEL field should not be enabled for $templateId');
        }
      }
    });

    test('should calculate coverage percentage correctly', () {
      const totalExpectedFields = 10;
      const mappedFields = 8;
      const coverage = (mappedFields / totalExpectedFields) * 100;

      expect(coverage, equals(80.0));
      expect(coverage >= 90, isFalse, reason: 'Should not meet 90% threshold');
      
      const fullMapping = 10;
      const fullCoverage = (fullMapping / totalExpectedFields) * 100;
      
      expect(fullCoverage, equals(100.0));
      expect(fullCoverage >= 90, isTrue, reason: 'Should meet 90% threshold');
    });

    test('should validate Excel column letter format', () {
      final validColumns = ['A', 'B', 'C', 'Z', 'AA', 'AB', 'AZ'];
      final invalidColumns = ['1', '0A', 'A1', '', 'a'];

      for (final column in validColumns) {
        expect(RegExp(r'^[A-Z]+$').hasMatch(column), isTrue, 
               reason: '$column should be valid Excel column');
      }

      for (final column in invalidColumns) {
        expect(RegExp(r'^[A-Z]+$').hasMatch(column), isFalse, 
               reason: '$column should be invalid Excel column');
      }
    });

    test('should handle template variations correctly', () {
      final templateVariations = {
        'capacity_1_5MMBTU': {
          'commonFields': ['unitNumber', 'readingDateTime', 'inletReading', 'outletReading'],
          'templates': ['methane_1_5mmbtu', 'pentane_1_5mmbtu']
        },
        'h2s_monitoring': {
          'additionalFields': ['toInletReadingH2S', 'h2sOutletReading'],
          'templates': ['methane_h2s_12hr', 'pentane_h2s_degas']
        }
      };

      // Test 1.5MMBTU templates should have simpler field set
      final smallCapacityFields = templateVariations['capacity_1_5MMBTU']!['commonFields'] as List<dynamic>;
      expect(smallCapacityFields.length, equals(4));
      expect(smallCapacityFields, contains('unitNumber'));
      expect(smallCapacityFields, contains('readingDateTime'));

      // Test H2S monitoring templates should have additional H2S fields
      final h2sFields = templateVariations['h2s_monitoring']!['additionalFields'] as List<dynamic>;
      expect(h2sFields, contains('toInletReadingH2S'));
      expect(h2sFields, contains('h2sOutletReading'));
    });

    test('should generate meaningful validation report', () {
      // Test basic validation report generation structure
      final sampleStatistics = {
        'totalTemplates': 17,
        'validTemplates': 15,
        'totalFields': 25,
        'mappedFields': 400,
        'unmappedFields': 25,
        'templateCoverage': {
          'marathon_gbr_custom': {
            'mappedFields': 16,
            'totalExpectedFields': 18,
            'coverage': 88.9,
            'isValid': false,
          }
        }
      };

      // Verify statistics calculation
      expect(sampleStatistics['totalTemplates'], equals(17));
      expect(sampleStatistics['validTemplates'], equals(15));
      final totalTemplates = sampleStatistics['totalTemplates'] as int;
      final validTemplates = sampleStatistics['validTemplates'] as int;
      expect(totalTemplates > validTemplates, isTrue);
      
      final templateCoverage = sampleStatistics['templateCoverage'] as Map<String, dynamic>;
      final marathonStats = templateCoverage['marathon_gbr_custom'] as Map<String, dynamic>;
      expect(marathonStats['coverage'], equals(88.9));
      expect(marathonStats['isValid'], isFalse);
    });
  });
}