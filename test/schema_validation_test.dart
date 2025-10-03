import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'dart:io';

void main() {
  group('Formal Schema Validation Tests', () {
    late Map<String, dynamic> thermalLogSchema;
    late Map<String, dynamic> templateRequirementsSchema;
    late Map<String, dynamic> comprehensiveMockData;
    late Map<String, dynamic> templateSpecificMockData;

    setUpAll(() async {
      // Load schema files
      final thermalLogSchemaFile = File('lib/schemas/thermal_log.schema.json');
      final templateRequirementsFile = File('lib/schemas/template_requirements.schema.json');
      final comprehensiveMockDataFile = File('lib/mock_data/comprehensive_thermal_log_mockdata.json');
      final templateSpecificMockDataFile = File('lib/mock_data/template_specific_mockdata.json');

      expect(thermalLogSchemaFile.existsSync(), isTrue, reason: 'Thermal log schema file should exist');
      expect(templateRequirementsFile.existsSync(), isTrue, reason: 'Template requirements schema file should exist');
      expect(comprehensiveMockDataFile.existsSync(), isTrue, reason: 'Comprehensive mock data file should exist');
      expect(templateSpecificMockDataFile.existsSync(), isTrue, reason: 'Template specific mock data file should exist');

      thermalLogSchema = json.decode(await thermalLogSchemaFile.readAsString());
      templateRequirementsSchema = json.decode(await templateRequirementsFile.readAsString());
      comprehensiveMockData = json.decode(await comprehensiveMockDataFile.readAsString());
      templateSpecificMockData = json.decode(await templateSpecificMockDataFile.readAsString());
    });

    test('should have valid JSON Schema structure for thermal log', () {
      // Validate JSON Schema meta-properties
      expect(thermalLogSchema['\$schema'], equals('http://json-schema.org/draft-07/schema#'));
      expect(thermalLogSchema['\$id'], isA<String>());
      expect(thermalLogSchema['title'], isA<String>());
      expect(thermalLogSchema['description'], isA<String>());
      expect(thermalLogSchema['version'], equals('1.0.0'));
      expect(thermalLogSchema['type'], equals('object'));

      // Validate required properties
      expect(thermalLogSchema['properties'], isA<Map>());
      expect(thermalLogSchema['required'], isA<List>());
      
      final required = thermalLogSchema['required'] as List;
      expect(required, contains('templateId'));
      expect(required, contains('schemaVersion'));
      expect(required, contains('entryMetadata'));
      expect(required, contains('identification'));
      expect(required, contains('readings'));

      // Validate property definitions exist
      final properties = thermalLogSchema['properties'] as Map;
      expect(properties.containsKey('templateId'), isTrue);
      expect(properties.containsKey('identification'), isTrue);
      expect(properties.containsKey('readings'), isTrue);
      expect(properties.containsKey('chemicalMonitoring'), isTrue);
      expect(properties.containsKey('systemMetrics'), isTrue);
    });

    test('should have valid template requirements schema structure', () {
      expect(templateRequirementsSchema['\$schema'], equals('http://json-schema.org/draft-07/schema#'));
      expect(templateRequirementsSchema['title'], isA<String>());
      expect(templateRequirementsSchema['version'], equals('1.0.0'));
      
      // Should define template structure
      expect(templateRequirementsSchema['properties'], isA<Map>());
      expect(templateRequirementsSchema['definitions'], isA<Map>());
    });

    test('should validate comprehensive mock data structure', () {
      expect(comprehensiveMockData['version'], equals('1.0.0'));
      expect(comprehensiveMockData['description'], isA<String>());
      expect(comprehensiveMockData['generatedAt'], isA<String>());
      expect(comprehensiveMockData['mockDataSets'], isA<Map>());

      final mockDataSets = comprehensiveMockData['mockDataSets'] as Map;
      
      // Should have all 17 template mock data sets
      final expectedTemplates = [
        'methane_1_5mmbtu',
        'pentane_1_5mmbtu',
        'methane_10_60mmbtu', 
        'pentane_10_60mmbtu',
        'methane_10_60mmbtu_2targets',
        'pentane_h2s_degas',
        'methane_h2s_12hr',
        'pentane_h2s_12hr',
        'pentane_h2s_lel_degas',
        'pentane_h2s_lel_hourly',
        'pentane_benzene_degas',
        'pentane_benzene_lel_degas',
        'pentane_methane_o2_degas',
        'methane_refill',
        'pentane_degas_final',
        'pentane_degas_tanks',
        'marathon_gbr_custom'
      ];

      for (final templateId in expectedTemplates) {
        expect(mockDataSets.containsKey(templateId), isTrue, 
               reason: 'Should contain mock data for template: $templateId');
        
        final mockData = mockDataSets[templateId] as Map;
        expect(mockData['templateId'], equals(templateId));
        expect(mockData['schemaVersion'], equals('1.0.0'));
        expect(mockData['entryMetadata'], isA<Map>());
        expect(mockData['identification'], isA<Map>());
        expect(mockData['readings'], isA<Map>());
      }
    });

    test('should validate template-specific mock data variations', () {
      expect(templateSpecificMockData['version'], equals('1.0.0'));
      expect(templateSpecificMockData['templateVariations'], isA<Map>());

      final variations = templateSpecificMockData['templateVariations'] as Map;
      
      // Should have different template categories
      expect(variations.containsKey('small_capacity_templates'), isTrue);
      expect(variations.containsKey('standard_capacity_templates'), isTrue);
      expect(variations.containsKey('specialized_monitoring'), isTrue);
      expect(variations.containsKey('process_operations'), isTrue);
      expect(variations.containsKey('marathon_custom'), isTrue);
    });

    test('should validate mock data field compliance with schema', () {
      final mockDataSets = comprehensiveMockData['mockDataSets'] as Map;
      
      // Test a few key templates for field compliance
      final testTemplates = ['methane_1_5mmbtu', 'methane_10_60mmbtu', 'marathon_gbr_custom'];
      
      for (final templateId in testTemplates) {
        final mockData = mockDataSets[templateId] as Map;
        
        // Validate required fields exist
        expect(mockData.containsKey('templateId'), isTrue, 
               reason: '$templateId should have templateId');
        expect(mockData.containsKey('schemaVersion'), isTrue,
               reason: '$templateId should have schemaVersion');
        expect(mockData.containsKey('entryMetadata'), isTrue,
               reason: '$templateId should have entryMetadata');
        
        // Validate identification section
        final identification = mockData['identification'] as Map;
        expect(identification.containsKey('unitNumber'), isTrue);
        expect(identification.containsKey('operatorName'), isTrue);
        expect(identification.containsKey('readingDateTime'), isTrue);
        
        // Validate readings section
        final readings = mockData['readings'] as Map;
        expect(readings.containsKey('inletReading'), isTrue);
        expect(readings.containsKey('outletReading'), isTrue);
        expect(readings.containsKey('exhaustTemperature'), isTrue);
        
        // Validate numeric ranges
        expect(readings['inletReading'], isA<num>());
        expect(readings['outletReading'], isA<num>());
        expect(readings['exhaustTemperature'], isA<num>());
        
        expect(readings['inletReading'] >= 0, isTrue);
        expect(readings['outletReading'] >= 0, isTrue);
        expect(readings['exhaustTemperature'] >= 0, isTrue);
        expect(readings['exhaustTemperature'] <= 2000, isTrue);
      }
    });

    test('should validate positive test cases', () {
      final validationTests = comprehensiveMockData['validationTestCases'] as Map;
      final positiveTests = validationTests['positiveTests'] as Map;
      
      final basicValidEntry = positiveTests['basic_valid_entry'] as Map;
      
      // Should have all required fields
      expect(basicValidEntry['templateId'], isA<String>());
      expect(basicValidEntry['schemaVersion'], equals('1.0.0'));
      expect(basicValidEntry['entryMetadata'], isA<Map>());
      expect(basicValidEntry['identification'], isA<Map>());
      expect(basicValidEntry['readings'], isA<Map>());
      
      // Required identification fields
      final identification = basicValidEntry['identification'] as Map;
      expect(identification['unitNumber'], isA<String>());
      expect(identification['operatorName'], isA<String>());
      expect(identification['readingDateTime'], isA<String>());
      
      // Required readings fields
      final readings = basicValidEntry['readings'] as Map;
      expect(readings['inletReading'], isA<num>());
      expect(readings['outletReading'], isA<num>());
      expect(readings['exhaustTemperature'], isA<num>());
    });

    test('should validate negative test cases structure', () {
      final validationTests = comprehensiveMockData['validationTestCases'] as Map;
      final negativeTests = validationTests['negativeTests'] as Map;
      
      expect(negativeTests.containsKey('missing_required_fields'), isTrue);
      expect(negativeTests.containsKey('invalid_temperature_range'), isTrue);
      
      final missingFieldsTest = negativeTests['missing_required_fields'] as Map;
      final entryMetadata = missingFieldsTest['entryMetadata'] as Map;
      expect(entryMetadata['validationStatus'], equals('errors'));
    });

    test('should validate edge cases structure', () {
      final edgeCases = templateSpecificMockData['edgeCases'] as Map;
      
      expect(edgeCases.containsKey('minMaxValues'), isTrue);
      expect(edgeCases.containsKey('warningThresholds'), isTrue);
      expect(edgeCases.containsKey('validationErrors'), isTrue);
      
      final minMaxValues = edgeCases['minMaxValues'] as Map;
      expect(minMaxValues.containsKey('minimum_valid_readings'), isTrue);
      expect(minMaxValues.containsKey('maximum_valid_readings'), isTrue);
      
      final minReadings = minMaxValues['minimum_valid_readings'] as Map;
      expect(minReadings['inletReading'], equals(0.1));
      expect(minReadings['outletReading'], equals(0.0));
      
      final maxReadings = minMaxValues['maximum_valid_readings'] as Map;
      expect(maxReadings['inletReading'], equals(9999.9));
      expect(maxReadings['exhaustTemperature'], equals(1999.9));
    });

    test('should validate template ID enum consistency', () {
      final thermalLogProperties = thermalLogSchema['properties'] as Map;
      final templateIdProperty = thermalLogProperties['templateId'] as Map;
      final enumValues = templateIdProperty['enum'] as List;
      
      // Should have all 17 template IDs
      expect(enumValues.length, equals(17));
      
      final expectedTemplateIds = [
        'methane_1_5mmbtu',
        'pentane_1_5mmbtu',
        'methane_10_60mmbtu',
        'pentane_10_60mmbtu',
        'methane_10_60mmbtu_2targets',
        'pentane_h2s_degas',
        'methane_h2s_12hr',
        'pentane_h2s_12hr',
        'pentane_h2s_lel_degas',
        'pentane_h2s_lel_hourly',
        'pentane_benzene_degas',
        'pentane_benzene_lel_degas',
        'pentane_methane_o2_degas',
        'methane_refill',
        'pentane_degas_final',
        'pentane_degas_tanks',
        'marathon_gbr_custom'
      ];
      
      for (final templateId in expectedTemplateIds) {
        expect(enumValues, contains(templateId),
               reason: 'Schema should include templateId: $templateId');
      }
    });

    test('should validate field type definitions', () {
      final properties = thermalLogSchema['properties'] as Map;
      
      // Validate identification section
      final identification = properties['identification'] as Map;
      final identificationProps = identification['properties'] as Map;
      
      expect(identificationProps['unitNumber']['type'], equals('string'));
      expect(identificationProps['operatorName']['type'], equals('string'));
      expect(identificationProps['readingDateTime']['format'], equals('date-time'));
      
      // Validate readings section
      final readings = properties['readings'] as Map;
      final readingsProps = readings['properties'] as Map;
      
      expect(readingsProps['inletReading']['type'], equals('number'));
      expect(readingsProps['outletReading']['type'], equals('number'));
      expect(readingsProps['exhaustTemperature']['type'], equals('number'));
      
      // Validate numeric constraints
      expect(readingsProps['inletReading']['minimum'], equals(0));
      expect(readingsProps['inletReading']['maximum'], equals(10000));
      expect(readingsProps['exhaustTemperature']['minimum'], equals(0));
      expect(readingsProps['exhaustTemperature']['maximum'], equals(2000));
    });

    test('should validate mock data completeness', () {
      // Count total mock data entries across all files
      final comprehensiveEntries = (comprehensiveMockData['mockDataSets'] as Map).length;
      final templateSpecificCategories = (templateSpecificMockData['templateVariations'] as Map).length;
      final edgeCaseCategories = (templateSpecificMockData['edgeCases'] as Map).length;
      
      expect(comprehensiveEntries, equals(17), reason: 'Should have mock data for all 17 templates');
      expect(templateSpecificCategories, greaterThanOrEqualTo(5), reason: 'Should have multiple template variation categories');
      expect(edgeCaseCategories, greaterThanOrEqualTo(3), reason: 'Should have edge case categories');
      
      // Validate testing coverage
      final validationTests = comprehensiveMockData['validationTestCases'] as Map;
      expect(validationTests.containsKey('positiveTests'), isTrue);
      expect(validationTests.containsKey('negativeTests'), isTrue);
    });
  });
}