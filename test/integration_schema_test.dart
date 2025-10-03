import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'dart:io';
import '../lib/models/unified_thermal_log_model.dart';

void main() {
  group('Schema Integration Tests', () {
    test('should parse actual thermal field definitions JSON', () async {
      final file = File('lib/models/thermal_field_definitions.json');
      expect(file.existsSync(), isTrue, reason: 'Thermal field definitions file should exist');

      final jsonString = await file.readAsString();
      final jsonData = json.decode(jsonString);

      // Validate schema structure
      expect(jsonData['schemaVersion'], equals('1.0.0'));
      expect(jsonData['commonSections'], isA<List>());
      expect(jsonData['universalFields'], isA<List>());
      expect(jsonData['conditionalFields'], isA<List>());

      // Test section structure
      final sections = jsonData['commonSections'] as List;
      expect(sections.isNotEmpty, isTrue);
      
      for (final section in sections) {
        expect(section['id'], isA<String>());
        expect(section['displayName'], isA<String>());
        expect(section['order'], isA<int>());
      }

      // Test universal fields structure  
      final universalFields = jsonData['universalFields'] as List;
      expect(universalFields.length, greaterThanOrEqualTo(5));

      final requiredUniversalFields = ['unitNumber', 'operatorName', 'readingDateTime', 'inletReading', 'outletReading'];
      final fieldIds = universalFields.map((f) => f['id']).toList();
      
      for (final requiredField in requiredUniversalFields) {
        expect(fieldIds, contains(requiredField), reason: 'Should contain required universal field: $requiredField');
      }

      // Test conditional fields structure
      final conditionalFields = jsonData['conditionalFields'] as List;
      expect(conditionalFields.isNotEmpty, isTrue);

      for (final field in conditionalFields) {
        expect(field['id'], isA<String>());
        expect(field['label'], isA<String>());
        expect(field['type'], isA<String>());
        expect(field['section'], isA<String>());
        expect(field['order'], isA<int>());

        if (field['conditionalDisplay'] != null) {
          final conditionalDisplay = field['conditionalDisplay'];
          expect(conditionalDisplay['enabledFor'], isA<List>());
        }
      }
    });

    test('should parse complete template mappings JSON', () async {
      final file = File('lib/models/complete_template_mappings.json');
      expect(file.existsSync(), isTrue, reason: 'Complete template mappings file should exist');

      final jsonString = await file.readAsString();
      final jsonData = json.decode(jsonString);

      // Validate top-level structure
      expect(jsonData['version'], equals('1.0.0'));
      expect(jsonData['allTemplateMappings'], isA<Map<String, dynamic>>());

      final allMappings = jsonData['allTemplateMappings'] as Map<String, dynamic>;
      
      // Should have all 17 templates
      expect(allMappings.length, equals(17));

      // Check key templates exist
      final keyTemplates = [
        'marathon_gbr_custom',
        'methane_10_60mmbtu',
        'pentane_10_60mmbtu',
        'pentane_h2s_lel_hourly'
      ];

      for (final templateId in keyTemplates) {
        expect(allMappings.containsKey(templateId), isTrue, reason: 'Should contain template: $templateId');
        
        final template = allMappings[templateId] as Map<String, dynamic>;
        expect(template['templateId'], equals(templateId));
        expect(template['displayName'], isA<String>());
        expect(template['capacity'], isA<String>());
        expect(template['fuelType'], isA<String>());
        expect(template['fieldMappings'], isA<Map<String, dynamic>>());

        // Validate field mappings structure
        final fieldMappings = template['fieldMappings'] as Map<String, dynamic>;
        expect(fieldMappings.isNotEmpty, isTrue);

        for (final entry in fieldMappings.entries) {
          final fieldId = entry.key;
          final mapping = entry.value as Map<String, dynamic>;
          
          expect(mapping['column'], isA<String>(), reason: 'Field $fieldId should have column');
          expect(mapping['header'], isA<String>(), reason: 'Field $fieldId should have header');
          
          // Validate column format
          final column = mapping['column'] as String;
          expect(RegExp(r'^[A-Z]+$').hasMatch(column), isTrue, reason: 'Column $column should be valid Excel column');
        }
      }
    });

    test('should demonstrate dynamic form generation feasibility', () async {
      // Load sample template data
      final fieldFile = File('lib/models/thermal_field_definitions.json');
      final fieldData = json.decode(await fieldFile.readAsString());
      
      // Create sample template configuration
      final sampleTemplate = {
        'schemaVersion': '1.0.0',
        'templateMetadata': {
          'id': 'test_template',
          'displayName': 'Test Template',
          'capacity': '10-60MMBTU',
          'fuelType': 'METHANE',
          'monitoringTypes': ['H2S'],
        },
        'sections': fieldData['commonSections'],
        'fields': fieldData['universalFields'].take(5).toList(), // Use first 5 fields
      };

      // Test that UnifiedThermalLogModel can parse it
      final model = UnifiedThermalLogModel.fromJson(sampleTemplate);
      
      expect(model.schemaVersion, equals('1.0.0'));
      expect(model.templateMetadata.id, equals('test_template'));
      expect(model.sections.length, greaterThan(0));
      expect(model.fields.length, equals(5));

      // Test field filtering for dynamic generation
      final enabledFields = model.getEnabledFields('test_template');
      expect(enabledFields.isNotEmpty, isTrue);

      // Test section-based organization for UI
      final fieldsBySection = model.getFieldsBySection('test_template');
      expect(fieldsBySection.isNotEmpty, isTrue);

      // Each section should have ordered fields
      for (final entry in fieldsBySection.entries) {
        final sectionId = entry.key;
        final sectionFields = entry.value;
        
        expect(sectionFields.isNotEmpty, isTrue, reason: 'Section $sectionId should have fields');
        
        // Verify fields are ordered
        for (int i = 1; i < sectionFields.length; i++) {
          expect(sectionFields[i].order, greaterThanOrEqualTo(sectionFields[i-1].order), 
                 reason: 'Fields should be ordered within section $sectionId');
        }
      }
    });

    test('should validate Excel export compatibility', () async {
      final mappingFile = File('lib/models/complete_template_mappings.json');
      final mappingData = json.decode(await mappingFile.readAsString());
      
      final fieldFile = File('lib/models/thermal_field_definitions.json');
      final fieldData = json.decode(await fieldFile.readAsString());

      // Test Marathon GBR template export compatibility
      final marathonTemplate = mappingData['allTemplateMappings']['marathon_gbr_custom'];
      final fieldMappings = marathonTemplate['fieldMappings'] as Map<String, dynamic>;

      // Create sample data entry
      final sampleData = {
        'unitNumber': 'GBR-001',
        'operatorName': 'John Smith', 
        'readingDateTime': '2025-09-11T14:30:00Z',
        'inletReading': 875.5,
        'outletReading': 45.2,
        'exhaustTemperature': 1275.8,
        'lelInletReading': 8.5,
        'toInletReadingH2S': 7.2,
      };

      // Verify all sample fields can be mapped to Excel columns
      int mappedFields = 0;
      for (final fieldId in sampleData.keys) {
        if (fieldMappings.containsKey(fieldId)) {
          mappedFields++;
          final mapping = fieldMappings[fieldId];
          
          // Verify column and header exist
          expect(mapping['column'], isA<String>());
          expect(mapping['header'], isA<String>());
        }
      }

      expect(mappedFields, equals(sampleData.length), reason: 'All sample fields should be mappable');
    });

    test('should validate schema completeness across all templates', () async {
      final mappingFile = File('lib/models/complete_template_mappings.json');
      final mappingData = json.decode(await mappingFile.readAsString());

      final fieldFile = File('lib/models/thermal_field_definitions.json');
      final fieldData = json.decode(await fieldFile.readAsString());

      final allMappings = mappingData['allTemplateMappings'] as Map<String, dynamic>;
      final universalFields = (fieldData['universalFields'] as List).map((f) => f['id']).toList();

      // Check that all templates have universal fields mapped
      for (final entry in allMappings.entries) {
        final templateId = entry.key;
        final template = entry.value as Map<String, dynamic>;
        final fieldMappings = template['fieldMappings'] as Map<String, dynamic>;

        int universalFieldsFound = 0;
        for (final universalFieldId in universalFields) {
          if (fieldMappings.containsKey(universalFieldId)) {
            universalFieldsFound++;
          }
        }

        // Most templates should have most universal fields
        final coverage = universalFieldsFound / universalFields.length;
        expect(coverage, greaterThan(0.7), 
               reason: 'Template $templateId should have >70% universal field coverage');
      }
    });

    test('should validate JSON schema compliance', () async {
      final schemaFile = File('lib/models/unified_thermal_log_schema.json');
      expect(schemaFile.existsSync(), isTrue, reason: 'Schema file should exist');

      final jsonString = await schemaFile.readAsString();
      
      // Should be valid JSON
      final jsonData = json.decode(jsonString);
      expect(jsonData, isA<Map<String, dynamic>>());

      // Should have JSON Schema properties
      expect(jsonData['\$schema'], equals('http://json-schema.org/draft-07/schema#'));
      expect(jsonData['title'], isA<String>());
      expect(jsonData['type'], equals('object'));
      expect(jsonData['properties'], isA<Map<String, dynamic>>());
      expect(jsonData['required'], isA<List>());

      // Should define all required properties
      final properties = jsonData['properties'] as Map<String, dynamic>;
      final requiredProperties = ['schemaVersion', 'templateMetadata', 'sections', 'fields'];
      
      for (final prop in requiredProperties) {
        expect(properties.containsKey(prop), isTrue, reason: 'Schema should define property: $prop');
      }
    });
  });
}