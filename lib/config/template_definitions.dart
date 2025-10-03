import '../models/log_template_models.dart';

/// Template definitions - like the D&D Player's Handbook
/// Each template is a "character class" with its own fields and abilities
class TemplateDefinitions {
  
  /// Methane Hourly Template - The "Fighter" class (straightforward, combat-focused)
  static LogTemplate getMethaneHourlyTemplate() {
    return LogTemplate(
      id: 'methane_hourly_v1',
      name: 'Methane Hourly Log',
      logType: 'methane_hourly',
      description: 'Standard hourly monitoring for methane levels',
      version: 1,
      fields: [
        // Core Fields (like base stats)
        TemplateField(
          id: 'inspection_time',
          key: 'inspectionTime',
          label: 'Inspection Time',
          type: FieldType.time,
          category: FieldCategory.core,
          validation: const FieldValidation(required: true),
          showInSummary: true,
          sortOrder: 1,
        ),
        TemplateField(
          id: 'operator_initials',
          key: 'operatorInitials',
          label: 'Operator Initials',
          type: FieldType.text,
          category: FieldCategory.core,
          validation: const FieldValidation(required: true, maxLength: 5),
          placeholder: 'XX',
          sortOrder: 2,
        ),
        
        // Primary Readings (like attack rolls)
        TemplateField(
          id: 'exhaust_temp',
          key: 'exhaustTemp',
          label: 'Exhaust Temperature',
          type: FieldType.temperature,
          category: FieldCategory.common,
          unit: '°F',
          validation: const FieldValidation(required: true, min: 0, max: 2000),
          showInSummary: true,
          sortOrder: 10,
        ),
        TemplateField(
          id: 'inlet_reading',
          key: 'inletReading',
          label: 'Inlet Reading',
          type: FieldType.ppm,
          category: FieldCategory.common,
          unit: 'PPM',
          validation: const FieldValidation(required: true, min: 0, max: 10000),
          helpText: 'Methane concentration at inlet',
          sortOrder: 11,
        ),
        TemplateField(
          id: 'outlet_reading',
          key: 'outletReading',
          label: 'Outlet Reading',
          type: FieldType.ppm,
          category: FieldCategory.common,
          unit: 'PPM',
          validation: const FieldValidation(required: true, min: 0, max: 1000),
          helpText: 'Methane concentration at outlet',
          sortOrder: 12,
        ),
        
        // Flow Rates (like movement speed)
        TemplateField(
          id: 'vapor_flow_rate',
          key: 'vaporFlowRate',
          label: 'Vapor Inlet Flow Rate',
          type: FieldType.flow,
          category: FieldCategory.common,
          unit: 'FPM',
          validation: const FieldValidation(min: 0, max: 500),
          sortOrder: 20,
        ),
        TemplateField(
          id: 'combustion_air_flow',
          key: 'combustionAirFlow',
          label: 'Combustion Air Flow Rate',
          type: FieldType.flow,
          category: FieldCategory.common,
          unit: 'FPM',
          validation: const FieldValidation(min: 0, max: 1000),
          sortOrder: 21,
        ),
        
        // Optional Fields (like feats)
        TemplateField(
          id: 'vacuum_reading',
          key: 'vacuumReading',
          label: 'Vacuum at Tank Outlet',
          type: FieldType.pressure,
          category: FieldCategory.optional,
          unit: 'in H2O',
          validation: const FieldValidation(min: -10, max: 10),
          sortOrder: 30,
        ),
        TemplateField(
          id: 'notes',
          key: 'notes',
          label: 'Notes',
          type: FieldType.text,
          category: FieldCategory.optional,
          validation: const FieldValidation(maxLength: 500),
          placeholder: 'Enter any observations...',
          sortOrder: 100,
        ),
      ],
      sections: [
        FieldSection(
          id: 'basic_info',
          title: 'Basic Information',
          fieldIds: ['inspection_time', 'operator_initials'],
          sortOrder: 1,
        ),
        FieldSection(
          id: 'primary_readings',
          title: 'Primary Readings',
          fieldIds: ['exhaust_temp', 'inlet_reading', 'outlet_reading'],
          sortOrder: 2,
        ),
        FieldSection(
          id: 'flow_rates',
          title: 'Flow Rates',
          fieldIds: ['vapor_flow_rate', 'combustion_air_flow'],
          collapsible: true,
          sortOrder: 3,
        ),
        FieldSection(
          id: 'additional',
          title: 'Additional Information',
          fieldIds: ['vacuum_reading', 'notes'],
          collapsible: true,
          defaultExpanded: false,
          sortOrder: 4,
        ),
      ],
    );
  }

  /// Benzene 12-Hour Template - The "Wizard" class (complex, many specialized fields)
  static LogTemplate getBenzene12HrTemplate() {
    return LogTemplate(
      id: 'benzene_12hr_v1',
      name: 'Benzene 12-Hour Log',
      logType: 'benzene_12hr',
      description: 'Extended monitoring for benzene and H2S levels',
      version: 1,
      fields: [
        // Core Fields
        TemplateField(
          id: 'inspection_time',
          key: 'inspectionTime',
          label: 'Inspection Time',
          type: FieldType.time,
          category: FieldCategory.core,
          validation: const FieldValidation(required: true),
          showInSummary: true,
          sortOrder: 1,
        ),
        TemplateField(
          id: 'operator_initials',
          key: 'operatorInitials',
          label: 'Operator Initials',
          type: FieldType.text,
          category: FieldCategory.core,
          validation: const FieldValidation(required: true, maxLength: 5),
          sortOrder: 2,
        ),
        
        // Specialized Fields (like spell slots)
        TemplateField(
          id: 'benzene_inlet',
          key: 'benzeneInlet',
          label: 'T.O. Inlet - Benzene',
          type: FieldType.ppm,
          category: FieldCategory.specialized,
          unit: 'PPM',
          validation: const FieldValidation(required: true, min: 0, max: 500),
          showInSummary: true,
          sortOrder: 10,
        ),
        TemplateField(
          id: 'h2s_inlet',
          key: 'h2sInlet',
          label: 'T.O. Inlet - H2S',
          type: FieldType.ppm,
          category: FieldCategory.specialized,
          unit: 'PPM',
          validation: const FieldValidation(required: true, min: 0, max: 500),
          sortOrder: 11,
        ),
        TemplateField(
          id: 'h2s_amp_required',
          key: 'h2sAmpRequired',
          label: 'H2S AMP Required',
          type: FieldType.checkbox,
          category: FieldCategory.specialized,
          sortOrder: 12,
        ),
        
        // Conditional field (appears only if H2S AMP is required)
        TemplateField(
          id: 'h2s_amp_reading',
          key: 'h2sAmpReading',
          label: 'H2S AMP Reading',
          type: FieldType.ppm,
          category: FieldCategory.specialized,
          unit: 'PPM',
          dependsOn: 'h2s_amp_required',
          dependencyCondition: {'equals': true},
          sortOrder: 13,
        ),
        
        // Temperature readings
        TemplateField(
          id: 'exhaust_temp',
          key: 'exhaustTemp',
          label: 'Exhaust Temperature',
          type: FieldType.temperature,
          category: FieldCategory.common,
          unit: '°F',
          validation: const FieldValidation(required: true, min: 0, max: 2000),
          sortOrder: 20,
        ),
        
        // Methane readings (still tracked)
        TemplateField(
          id: 'inlet_methane',
          key: 'inletMethane',
          label: 'Inlet Methane',
          type: FieldType.percentage,
          category: FieldCategory.common,
          unit: '%',
          validation: const FieldValidation(min: 0, max: 100),
          sortOrder: 21,
        ),
        TemplateField(
          id: 'outlet_methane',
          key: 'outletMethane',
          label: 'Outlet Methane',
          type: FieldType.ppm,
          category: FieldCategory.common,
          unit: 'PPM',
          validation: const FieldValidation(min: 0, max: 1000),
          sortOrder: 22,
        ),
        
        // Additional monitoring
        TemplateField(
          id: 'totalizer',
          key: 'totalizer',
          label: 'Totalizer Reading',
          type: FieldType.number,
          category: FieldCategory.optional,
          unit: 'SCF',
          sortOrder: 30,
        ),
        TemplateField(
          id: 'degas_reading',
          key: 'degasReading',
          label: 'Degas Five Minute Reading',
          type: FieldType.ppm,
          category: FieldCategory.optional,
          unit: 'PPM',
          helpText: 'Take reading every 5 minutes during degas',
          sortOrder: 31,
        ),
      ],
      sections: [
        FieldSection(
          id: 'basic_info',
          title: 'Basic Information',
          fieldIds: ['inspection_time', 'operator_initials'],
          sortOrder: 1,
        ),
        FieldSection(
          id: 'benzene_h2s',
          title: 'Benzene & H2S Monitoring',
          fieldIds: ['benzene_inlet', 'h2s_inlet', 'h2s_amp_required', 'h2s_amp_reading'],
          sortOrder: 2,
        ),
        FieldSection(
          id: 'temperature_methane',
          title: 'Temperature & Methane',
          fieldIds: ['exhaust_temp', 'inlet_methane', 'outlet_methane'],
          sortOrder: 3,
        ),
        FieldSection(
          id: 'additional_monitoring',
          title: 'Additional Monitoring',
          fieldIds: ['totalizer', 'degas_reading'],
          collapsible: true,
          defaultExpanded: false,
          sortOrder: 4,
        ),
      ],
    );
  }

  /// Combined Monitoring Template - The "Paladin" (versatile, bit of everything)
  static LogTemplate getCombinedMonitoringTemplate() {
    return LogTemplate(
      id: 'combined_monitoring_v1',
      name: 'Combined Monitoring Log',
      logType: 'combined_monitoring',
      description: 'Comprehensive monitoring for multiple parameters',
      version: 1,
      fields: [
        // Include fields from both methane and benzene templates
        // Plus some unique fields
        TemplateField(
          id: 'monitoring_type',
          key: 'monitoringType',
          label: 'Monitoring Type',
          type: FieldType.select,
          category: FieldCategory.core,
          options: [
            SelectOption(value: 'routine', label: 'Routine'),
            SelectOption(value: 'startup', label: 'Startup'),
            SelectOption(value: 'shutdown', label: 'Shutdown'),
            SelectOption(value: 'emergency', label: 'Emergency'),
          ],
          validation: const FieldValidation(required: true),
          sortOrder: 3,
        ),
        // ... include other fields as needed
      ],
      sections: [
        // ... define sections
      ],
    );
  }

  /// Thermal Oxidizer Template - The "Ranger" (specialized for specific environment)
  static LogTemplate getThermalOxidizerTemplate() {
    return LogTemplate(
      id: 'thermal_oxidizer_v1',
      name: 'Thermal Oxidizer Log',
      logType: 'thermal_oxidizer',
      description: 'Thermal oxidizer operational monitoring',
      version: 1,
      fields: [
        // Thermal oxidizer specific fields
        TemplateField(
          id: 'flame_status',
          key: 'flameStatus',
          label: 'Flame Status',
          type: FieldType.select,
          category: FieldCategory.core,
          options: [
            SelectOption(value: 'stable', label: 'Stable'),
            SelectOption(value: 'unstable', label: 'Unstable'),
            SelectOption(value: 'out', label: 'Out'),
          ],
          validation: const FieldValidation(required: true),
          showInSummary: true,
          sortOrder: 10,
        ),
        TemplateField(
          id: 'pilot_pressure',
          key: 'pilotPressure',
          label: 'Pilot Pressure',
          type: FieldType.pressure,
          category: FieldCategory.specialized,
          unit: 'PSI',
          validation: const FieldValidation(min: 0, max: 100),
          sortOrder: 11,
        ),
        // ... more oxidizer-specific fields
      ],
      sections: [
        // ... define sections
      ],
    );
  }

  /// Custom Template - The "Homebrew Class" (fully customizable)
  static LogTemplate getCustomTemplate() {
    return LogTemplate(
      id: 'custom_v1',
      name: 'Custom Log',
      logType: 'custom',
      description: 'Customizable log template',
      version: 1,
      fields: [
        // Basic fields that can be extended
        TemplateField(
          id: 'inspection_time',
          key: 'inspectionTime',
          label: 'Inspection Time',
          type: FieldType.time,
          category: FieldCategory.core,
          validation: const FieldValidation(required: true),
          sortOrder: 1,
        ),
        TemplateField(
          id: 'operator_initials',
          key: 'operatorInitials',
          label: 'Operator Initials',
          type: FieldType.text,
          category: FieldCategory.core,
          validation: const FieldValidation(required: true, maxLength: 5),
          sortOrder: 2,
        ),
        // Custom fields can be added dynamically
      ],
      sections: [
        FieldSection(
          id: 'basic_info',
          title: 'Basic Information',
          fieldIds: ['inspection_time', 'operator_initials'],
          sortOrder: 1,
        ),
      ],
    );
  }
}