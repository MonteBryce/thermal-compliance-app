import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import '../lib/models/unified_thermal_log_model.dart';

void main() {
  group('Unified Thermal Log Schema Tests', () {
    late Map<String, dynamic> sampleData;

    setUpAll(() {
      // Mock sample data for testing
      const sampleJson = '''
      {
        "marathon_gbr_sample": {
          "schemaVersion": "1.0.0",
          "templateMetadata": {
            "id": "marathon_gbr_custom",
            "displayName": "Texas - BLANK Thermal Log - Marathon GBR - CUSTOM",
            "capacity": "10-60MMBTU",
            "fuelType": "METHANE",
            "monitoringTypes": ["H2S", "LEL", "VOC"],
            "frequency": "hourly",
            "processStage": "standard"
          },
          "sections": [
            {
              "id": "identification",
              "displayName": "🏷️ Identification",
              "order": 1,
              "collapsible": false
            },
            {
              "id": "readings",
              "displayName": "🔍 Readings",  
              "order": 2,
              "collapsible": false
            }
          ],
          "fields": [
            {
              "id": "unitNumber",
              "label": "Unit #",
              "type": "text",
              "section": "identification",
              "order": 1,
              "required": true,
              "validation": {
                "required": true,
                "minLength": 1,
                "maxLength": 10
              },
              "conditionalDisplay": {
                "enabledFor": ["marathon_gbr_custom"]
              }
            },
            {
              "id": "inletReading",
              "label": "Inlet Reading",
              "unit": "PPM",
              "type": "number",
              "section": "readings",
              "order": 1,
              "required": true,
              "validation": {
                "required": true,
                "min": 0,
                "warningMax": 1000,
                "warningMessage": "⚠ High inlet concentration detected"
              },
              "conditionalDisplay": {
                "enabledFor": ["marathon_gbr_custom"]
              }
            }
          ]
        }
      }
      ''';
      sampleData = json.decode(sampleJson);
    });

    test('should create UnifiedThermalLogModel from JSON', () {
      final marathonSample = sampleData['marathon_gbr_sample'] as Map<String, dynamic>;
      final model = UnifiedThermalLogModel.fromJson(marathonSample);

      expect(model.schemaVersion, equals('1.0.0'));
      expect(model.templateMetadata.id, equals('marathon_gbr_custom'));
      expect(model.templateMetadata.displayName, contains('Marathon GBR'));
      expect(model.templateMetadata.monitoringTypes, contains('LEL'));
      expect(model.sections.length, equals(2));
      expect(model.fields.length, equals(2));
    });

    test('should filter enabled fields for template', () {
      final marathonSample = sampleData['marathon_gbr_sample'] as Map<String, dynamic>;
      final model = UnifiedThermalLogModel.fromJson(marathonSample);
      
      final enabledFields = model.getEnabledFields('marathon_gbr_custom');
      
      expect(enabledFields.length, equals(2));
      expect(enabledFields.map((f) => f.id), contains('unitNumber'));
      expect(enabledFields.map((f) => f.id), contains('inletReading'));
    });

    test('should organize fields by sections', () {
      final marathonSample = sampleData['marathon_gbr_sample'] as Map<String, dynamic>;
      final model = UnifiedThermalLogModel.fromJson(marathonSample);
      
      final fieldsBySection = model.getFieldsBySection('marathon_gbr_custom');
      
      expect(fieldsBySection.keys, contains('identification'));
      expect(fieldsBySection.keys, contains('readings'));
      expect(fieldsBySection['identification']?.length, equals(1));
      expect(fieldsBySection['readings']?.length, equals(1));
      
      // Check field ordering within sections
      expect(fieldsBySection['identification']?.first.id, equals('unitNumber'));
      expect(fieldsBySection['readings']?.first.id, equals('inletReading'));
    });

    test('should handle validation rules correctly', () {
      final marathonSample = sampleData['marathon_gbr_sample'] as Map<String, dynamic>;
      final model = UnifiedThermalLogModel.fromJson(marathonSample);
      
      final inletField = model.fields.firstWhere((f) => f.id == 'inletReading');
      
      expect(inletField.validation?.min, equals(0));
      expect(inletField.validation?.warningMax, equals(1000));
      expect(inletField.validation?.warningMessage, contains('High inlet concentration'));
    });

    test('should convert model back to JSON', () {
      final marathonSample = sampleData['marathon_gbr_sample'] as Map<String, dynamic>;
      final model = UnifiedThermalLogModel.fromJson(marathonSample);
      
      final json = model.toJson();
      
      expect(json['schemaVersion'], equals('1.0.0'));
      expect(json['templateMetadata']['id'], equals('marathon_gbr_custom'));
      expect(json['fields'], isA<List>());
      expect(json['sections'], isA<List>());
    });

    test('should handle conditional display logic', () {
      final marathonSample = sampleData['marathon_gbr_sample'] as Map<String, dynamic>;
      final model = UnifiedThermalLogModel.fromJson(marathonSample);
      
      final unitField = model.fields.firstWhere((f) => f.id == 'unitNumber');
      
      expect(unitField.conditionalDisplay?.enabledFor, contains('marathon_gbr_custom'));
      expect(unitField.required, isTrue);
    });

    test('should handle template metadata correctly', () {
      final marathonSample = sampleData['marathon_gbr_sample'] as Map<String, dynamic>;
      final model = UnifiedThermalLogModel.fromJson(marathonSample);
      
      expect(model.templateMetadata.capacity, equals('10-60MMBTU'));
      expect(model.templateMetadata.fuelType, equals('METHANE'));
      expect(model.templateMetadata.frequency, equals('hourly'));
      expect(model.templateMetadata.processStage, equals('standard'));
    });

    test('should handle form sections properly', () {
      final marathonSample = sampleData['marathon_gbr_sample'] as Map<String, dynamic>;
      final model = UnifiedThermalLogModel.fromJson(marathonSample);
      
      final identSection = model.sections.firstWhere((s) => s.id == 'identification');
      final readingsSection = model.sections.firstWhere((s) => s.id == 'readings');
      
      expect(identSection.displayName, equals('🏷️ Identification'));
      expect(identSection.order, equals(1));
      expect(identSection.collapsible, isFalse);
      
      expect(readingsSection.displayName, equals('🔍 Readings'));
      expect(readingsSection.order, equals(2));
    });
  });

  group('Template Registry Tests', () {
    test('should register and retrieve templates', () {
      const sampleTemplate = {
        'schemaVersion': '1.0.0',
        'templateMetadata': {
          'id': 'test_template',
          'displayName': 'Test Template',
          'capacity': '1.5MMBTU',
          'fuelType': 'PENTANE'
        },
        'sections': [],
        'fields': []
      };

      UnifiedThermalLogRegistry.registerTemplate('test_template', sampleTemplate);
      
      final retrieved = UnifiedThermalLogRegistry.getTemplate('test_template');
      
      expect(retrieved, isNotNull);
      expect(retrieved?.templateMetadata.id, equals('test_template'));
      expect(retrieved?.templateMetadata.fuelType, equals('PENTANE'));
    });

    test('should list available template IDs', () {
      // Clear any existing templates
      UnifiedThermalLogRegistry.clearTemplates();
      
      const template1 = {
        'schemaVersion': '1.0.0',
        'templateMetadata': {
          'id': 'template1',
          'displayName': 'Template 1',
          'capacity': '1.5MMBTU',
          'fuelType': 'METHANE'
        },
        'sections': [],
        'fields': []
      };
      
      const template2 = {
        'schemaVersion': '1.0.0',
        'templateMetadata': {
          'id': 'template2',
          'displayName': 'Template 2',
          'capacity': '10-60MMBTU',
          'fuelType': 'PENTANE'
        },
        'sections': [],
        'fields': []
      };

      UnifiedThermalLogRegistry.registerTemplate('template1', template1);
      UnifiedThermalLogRegistry.registerTemplate('template2', template2);
      
      final availableIds = UnifiedThermalLogRegistry.availableTemplateIds;
      
      expect(availableIds.length, equals(2));
      expect(availableIds, contains('template1'));
      expect(availableIds, contains('template2'));
    });
  });
}