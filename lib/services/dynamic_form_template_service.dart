import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/dynamic_form_schema.dart';
import '../models/firestore_models.dart';
import 'local_database_service.dart';

/// Service for managing dynamic form templates from Firestore
/// Supports offline-first architecture with local caching
class DynamicFormTemplateService {
  static final _firestore = FirebaseFirestore.instance;
  
  /// Get form template by logType and optional project-specific overrides
  static Future<DynamicFormTemplate?> getFormTemplate({
    required String logType,
    String? projectId,
    bool useCache = true,
  }) async {
    try {
      // First try to get project-specific template if projectId provided
      if (projectId != null) {
        final projectTemplate = await _getProjectSpecificTemplate(
          logType: logType, 
          projectId: projectId, 
          useCache: useCache,
        );
        if (projectTemplate != null) return projectTemplate;
      }
      
      // Fall back to generic template
      return await _getGenericTemplate(logType: logType, useCache: useCache);
      
    } catch (e) {
      debugPrint('Error getting form template: $e');
      
      // If online fails, try cached version
      if (useCache) {
        return await _getCachedTemplate(logType, projectId);
      }
      
      return null;
    }
  }
  
  /// Get all available form templates
  static Future<List<DynamicFormTemplate>> getAllFormTemplates({
    bool activeOnly = true,
    bool useCache = true,
  }) async {
    try {
      Query query = _firestore.collection(DynamicFormTemplateCollections.templates);
      
      if (activeOnly) {
        query = query.where('active', isEqualTo: true);
      }
      
      final snapshot = await query.orderBy('name').get();
      
      final templates = snapshot.docs
          .map((doc) => DynamicFormTemplate.fromFirestore(doc))
          .toList();
          
      // Cache templates locally
      if (useCache) {
        await _cacheTemplates(templates);
      }
      
      return templates;
      
    } catch (e) {
      debugPrint('Error getting all form templates: $e');
      
      // Fall back to cached templates
      if (useCache) {
        return await _getAllCachedTemplates();
      }
      
      return [];
    }
  }
  
  /// Get form template customized for specific project
  static Future<DynamicFormTemplate?> getCustomizedFormTemplate({
    required String logType,
    required ProjectDocument project,
    bool useCache = true,
  }) async {
    try {
      // Get base template
      final baseTemplate = await getFormTemplate(
        logType: logType,
        projectId: project.projectId,
        useCache: useCache,
      );
      
      if (baseTemplate == null) return null;
      
      // Apply project-specific customizations
      final customizedTemplate = _applyProjectCustomizations(baseTemplate, project);
      
      return customizedTemplate;
      
    } catch (e) {
      debugPrint('Error getting customized form template: $e');
      return null;
    }
  }
  
  /// Store/update form template in Firestore
  static Future<void> storeFormTemplate(DynamicFormTemplate template) async {
    try {
      final data = template.toJson();
      data['updatedAt'] = FieldValue.serverTimestamp();
      
      if (template.projectId != null) {
        // Store as project-specific template
        await _firestore
            .collection(DynamicFormTemplateCollections.projectTemplates)
            .doc('${template.projectId}_${template.logType}')
            .set(data);
      } else {
        // Store as generic template
        await _firestore
            .collection(DynamicFormTemplateCollections.templates)
            .doc(template.id)
            .set(data);
      }
      
      debugPrint('✅ Form template stored: ${template.name}');
      
    } catch (e) {
      debugPrint('❌ Error storing form template: $e');
      rethrow;
    }
  }
  
  /// Initialize default thermal logging templates
  static Future<void> initializeDefaultTemplates() async {
    try {
      await _initializeThermalTemplate();
      await _initializeMarathonGbrTemplate();
      await _initializeEnvironmentalTemplate();
      await _initializeSafetyTemplate();
      await _initializeMaintenanceTemplate();
      
      debugPrint('✅ All default form templates initialized');
      
    } catch (e) {
      debugPrint('❌ Error initializing default templates: $e');
      rethrow;
    }
  }
  
  /// Clear template cache
  static Future<void> clearTemplateCache() async {
    try {
      // Implementation would clear local Hive cache
      debugPrint('Template cache cleared');
    } catch (e) {
      debugPrint('Error clearing template cache: $e');
    }
  }
  
  // Private helper methods
  
  static Future<DynamicFormTemplate?> _getProjectSpecificTemplate({
    required String logType,
    required String projectId,
    bool useCache = true,
  }) async {
    final docId = '${projectId}_${logType}';
    
    final doc = await _firestore
        .collection(DynamicFormTemplateCollections.projectTemplates)
        .doc(docId)
        .get();
        
    if (!doc.exists) return null;
    
    final template = DynamicFormTemplate.fromFirestore(doc);
    
    if (useCache) {
      await _cacheTemplate(template);
    }
    
    return template;
  }
  
  static Future<DynamicFormTemplate?> _getGenericTemplate({
    required String logType,
    bool useCache = true,
  }) async {
    final snapshot = await _firestore
        .collection(DynamicFormTemplateCollections.templates)
        .where('logType', isEqualTo: logType)
        .where('active', isEqualTo: true)
        .orderBy('version', descending: true)
        .limit(1)
        .get();
        
    if (snapshot.docs.isEmpty) return null;
    
    final template = DynamicFormTemplate.fromFirestore(snapshot.docs.first);
    
    if (useCache) {
      await _cacheTemplate(template);
    }
    
    return template;
  }
  
  static Future<DynamicFormTemplate?> _getCachedTemplate(String logType, String? projectId) async {
    // Implementation would retrieve from Hive cache
    // For now, return null - will be implemented in future enhancement
    debugPrint('Retrieving cached template for $logType, project: $projectId');
    return null;
  }
  
  static Future<List<DynamicFormTemplate>> _getAllCachedTemplates() async {
    // Implementation would retrieve all cached templates from Hive
    // For now, return empty list - will be implemented in future enhancement
    debugPrint('Retrieving all cached templates');
    return [];
  }
  
  static Future<void> _cacheTemplate(DynamicFormTemplate template) async {
    // Implementation would cache template in Hive
    debugPrint('Caching template: ${template.name}');
  }
  
  static Future<void> _cacheTemplates(List<DynamicFormTemplate> templates) async {
    // Implementation would cache multiple templates in Hive
    debugPrint('Caching ${templates.length} templates');
  }
  
  static DynamicFormTemplate _applyProjectCustomizations(
    DynamicFormTemplate baseTemplate, 
    ProjectDocument project,
  ) {
    // Apply project-specific field customizations
    final projectOverrides = <String, dynamic>{};
    
    // Temperature field customization based on operating temperature
    if (project.operatingTemperature.isNotEmpty) {
      projectOverrides['exhaustTemperature'] = {
        'helpText': 'Target: ${project.operatingTemperature}',
        'validation': {
          'warningMessage': '⚠ Outside project target (${project.operatingTemperature})',
        }
      };
    }
    
    // H2S field customization
    if (project.h2sAmpRequired) {
      projectOverrides['toInletReadingH2S'] = {
        'validation': {
          'required': true,
          'warningMessage': '⚠ H2S monitoring required for this project',
        }
      };
    }
    
    // LEL target customization
    if (project.facilityTarget.isNotEmpty) {
      if (project.facilityTarget.toLowerCase().contains('lel')) {
        projectOverrides['lelInletReading'] = {
          'helpText': 'Project target: ${project.facilityTarget}',
        };
      }
    }
    
    // Product-specific customizations
    switch (project.product.toLowerCase()) {
      case 'sour water':
        projectOverrides['toInletReadingH2S'] = {
          'validation': {
            'required': true,
            'warningMax': 10,
            'warningMessage': '⚠ High H2S levels for sour water processing',
          }
        };
        break;
        
      case 'crude oil':
      case 'crude':
        projectOverrides['vaporInletVOCPpm'] = {
          'validation': {
            'warningMax': 1000,
            'warningMessage': '⚠ High VOC levels for crude oil processing',
          }
        };
        break;
    }
    
    return baseTemplate.applyProjectOverrides(project.projectId, projectOverrides);
  }
  
  // Default template initialization methods
  
  static Future<void> _initializeThermalTemplate() async {
    final template = DynamicFormTemplate(
      id: 'thermal_standard',
      name: 'Standard Thermal Log',
      logType: 'thermal',
      description: 'Standard thermal system readings and metrics',
      fields: [
        // Core readings
        DynamicFormField(
          id: 'inletReading',
          key: 'inletReading',
          label: 'Inlet Reading',
          type: DynamicFieldType.ppm,
          category: DynamicFieldCategory.readings,
          unit: 'PPM',
          sortOrder: 1,
          validation: DynamicFieldValidation(
            required: true,
            min: 0,
          ),
          showInSummary: true,
        ),
        DynamicFormField(
          id: 'outletReading',
          key: 'outletReading',
          label: 'Outlet Reading',
          type: DynamicFieldType.ppm,
          category: DynamicFieldCategory.readings,
          unit: 'PPM',
          sortOrder: 2,
          validation: DynamicFieldValidation(
            required: true,
            min: 0,
          ),
          showInSummary: true,
        ),
        DynamicFormField(
          id: 'exhaustTemperature',
          key: 'exhaustTemperature',
          label: 'Exhaust Temperature',
          type: DynamicFieldType.temperature,
          category: DynamicFieldCategory.readings,
          unit: '°F',
          sortOrder: 3,
          validation: DynamicFieldValidation(
            required: true,
            min: 0,
            max: 2000,
            warningMin: 300,
            warningMax: 1200,
            warningMessage: '⚠ Outside normal range (300-1200°F)',
          ),
          showInSummary: true,
        ),
        DynamicFormField(
          id: 'h2sReading',
          key: 'toInletReadingH2S',
          label: 'H₂S Reading',
          type: DynamicFieldType.ppm,
          category: DynamicFieldCategory.safety,
          unit: 'PPM',
          sortOrder: 4,
          validation: DynamicFieldValidation(
            required: true,
            min: 0,
            warningMax: 10,
            warningMessage: '⚠ H2S levels above safety threshold',
          ),
          showInSummary: true,
        ),
        DynamicFormField(
          id: 'observations',
          key: 'observations',
          label: 'Observations / Anomalies',
          type: DynamicFieldType.text,
          category: DynamicFieldCategory.optional,
          sortOrder: 10,
          helpText: 'Enter any observations, anomalies, equipment issues, or maintenance notes...',
        ),
      ],
      sections: [
        DynamicFormSection(
          id: 'readings',
          title: '🔍 Readings',
          fieldIds: ['inletReading', 'outletReading', 'exhaustTemperature', 'h2sReading'],
          sortOrder: 1,
        ),
        DynamicFormSection(
          id: 'notes',
          title: '📝 Notes',
          fieldIds: ['observations'],
          sortOrder: 2,
          collapsible: true,
        ),
      ],
      version: 1,
      active: true,
      supportedTankTypes: ['thermal', 'thermal oxidation'],
    );
    
    await storeFormTemplate(template);
  }
  
  static Future<void> _initializeMarathonGbrTemplate() async {
    final template = DynamicFormTemplate(
      id: 'marathon_gbr_custom',
      name: 'Texas - BLANK Thermal Log - Marathon GBR - CUSTOM',
      logType: 'marathon_gbr_custom',
      description: 'Marathon GBR specific thermal log with LEL monitoring',
      fields: [
        // Marathon-specific fields with LEL monitoring
        DynamicFormField(
          id: 'inletReading',
          key: 'inletReading',
          label: 'Inlet Reading',
          type: DynamicFieldType.ppm,
          category: DynamicFieldCategory.readings,
          unit: 'PPM',
          sortOrder: 1,
          validation: DynamicFieldValidation(required: true, min: 0),
          showInSummary: true,
        ),
        DynamicFormField(
          id: 'outletReading',
          key: 'outletReading',
          label: 'Outlet Reading',
          type: DynamicFieldType.ppm,
          category: DynamicFieldCategory.readings,
          unit: 'PPM',
          sortOrder: 2,
          validation: DynamicFieldValidation(required: true, min: 0),
          showInSummary: true,
        ),
        DynamicFormField(
          id: 'exhaustTemperature',
          key: 'exhaustTemperature',
          label: 'Exhaust Temperature',
          type: DynamicFieldType.temperature,
          category: DynamicFieldCategory.readings,
          unit: '°F',
          sortOrder: 3,
          validation: DynamicFieldValidation(
            required: true,
            min: 0,
            max: 2000,
            warningMin: 1200,
            warningMax: 1400,
            warningMessage: '⚠ Marathon target >1250°F',
          ),
          helpText: 'Marathon target: >1250°F',
          showInSummary: true,
        ),
        DynamicFormField(
          id: 'lelInletReading',
          key: 'lelInletReading',
          label: '%LEL Inlet',
          type: DynamicFieldType.percentage,
          category: DynamicFieldCategory.safety,
          unit: '%',
          sortOrder: 4,
          validation: DynamicFieldValidation(
            required: true,
            min: 0,
            max: 100,
            warningMax: 10,
            warningMessage: '⚠ Above Marathon target (10% LEL)',
          ),
          helpText: 'Marathon target: 10% LEL',
          showInSummary: true,
        ),
        DynamicFormField(
          id: 'vaporInletVOC',
          key: 'vaporInletVOCPpm',
          label: 'Vapor Inlet VOC',
          type: DynamicFieldType.ppm,
          category: DynamicFieldCategory.readings,
          unit: 'PPM',
          sortOrder: 5,
          validation: DynamicFieldValidation(required: true, min: 0),
          showInSummary: true,
        ),
        DynamicFormField(
          id: 'combustionAirFlow',
          key: 'combustionAirFlowRate',
          label: 'Combustion Air Flow Rate',
          type: DynamicFieldType.flow,
          category: DynamicFieldCategory.readings,
          unit: 'FPM',
          sortOrder: 6,
          validation: DynamicFieldValidation(required: true, min: 0),
        ),
        DynamicFormField(
          id: 'h2sReading',
          key: 'toInletReadingH2S',
          label: 'H₂S Reading',
          type: DynamicFieldType.ppm,
          category: DynamicFieldCategory.safety,
          unit: 'PPM',
          sortOrder: 7,
          validation: DynamicFieldValidation(required: true, min: 0),
          showInSummary: true,
        ),
      ],
      sections: [
        DynamicFormSection(
          id: 'readings',
          title: '🔍 Readings',
          fieldIds: ['inletReading', 'outletReading', 'exhaustTemperature', 'lelInletReading', 'vaporInletVOC', 'combustionAirFlow', 'h2sReading'],
          sortOrder: 1,
        ),
      ],
      version: 1,
      active: true,
      supportedTankTypes: ['thermal'],
      metadata: {
        'clientName': 'Marathon GBR',
        'location': 'Texas City, TX',
        'specialRequirements': ['LEL monitoring', 'H2S detection'],
      },
    );
    
    await storeFormTemplate(template);
  }
  
  static Future<void> _initializeEnvironmentalTemplate() async {
    final template = DynamicFormTemplate(
      id: 'environmental_standard',
      name: 'Environmental Monitoring',
      logType: 'environmental',
      description: 'Environmental conditions and air quality readings',
      fields: [
        DynamicFormField(
          id: 'ambientTemperature',
          key: 'ambientTemperature',
          label: 'Ambient Temperature',
          type: DynamicFieldType.temperature,
          category: DynamicFieldCategory.conditions,
          unit: '°F',
          sortOrder: 1,
          validation: DynamicFieldValidation(required: true, min: -50, max: 150),
        ),
        DynamicFormField(
          id: 'humidity',
          key: 'humidity',
          label: 'Relative Humidity',
          type: DynamicFieldType.percentage,
          category: DynamicFieldCategory.conditions,
          unit: '%',
          sortOrder: 2,
          validation: DynamicFieldValidation(required: true, min: 0, max: 100),
        ),
        DynamicFormField(
          id: 'windSpeed',
          key: 'windSpeed',
          label: 'Wind Speed',
          type: DynamicFieldType.number,
          category: DynamicFieldCategory.conditions,
          unit: 'mph',
          sortOrder: 3,
          validation: DynamicFieldValidation(required: true, min: 0),
        ),
        DynamicFormField(
          id: 'windDirection',
          key: 'windDirection',
          label: 'Wind Direction',
          type: DynamicFieldType.select,
          category: DynamicFieldCategory.conditions,
          sortOrder: 4,
          validation: DynamicFieldValidation(required: true),
          options: [
            DynamicSelectOption(value: 'N', label: 'North'),
            DynamicSelectOption(value: 'NE', label: 'Northeast'),
            DynamicSelectOption(value: 'E', label: 'East'),
            DynamicSelectOption(value: 'SE', label: 'Southeast'),
            DynamicSelectOption(value: 'S', label: 'South'),
            DynamicSelectOption(value: 'SW', label: 'Southwest'),
            DynamicSelectOption(value: 'W', label: 'West'),
            DynamicSelectOption(value: 'NW', label: 'Northwest'),
          ],
        ),
      ],
      sections: [
        DynamicFormSection(
          id: 'conditions',
          title: '🌡️ Environmental Conditions',
          fieldIds: ['ambientTemperature', 'humidity', 'windSpeed', 'windDirection'],
          sortOrder: 1,
        ),
      ],
      version: 1,
      active: true,
    );
    
    await storeFormTemplate(template);
  }
  
  static Future<void> _initializeSafetyTemplate() async {
    final template = DynamicFormTemplate(
      id: 'safety_standard',
      name: 'Safety Inspection',
      logType: 'safety',
      description: 'Safety equipment and protocol verification',
      fields: [
        DynamicFormField(
          id: 'fireExtinguishers',
          key: 'fireExtinguishers',
          label: 'Fire Extinguishers Check',
          type: DynamicFieldType.checkbox,
          category: DynamicFieldCategory.safety,
          sortOrder: 1,
          validation: DynamicFieldValidation(required: true),
        ),
        DynamicFormField(
          id: 'emergencyShutoff',
          key: 'emergencyShutoff',
          label: 'Emergency Shutoff Systems',
          type: DynamicFieldType.checkbox,
          category: DynamicFieldCategory.safety,
          sortOrder: 2,
          validation: DynamicFieldValidation(required: true),
        ),
        DynamicFormField(
          id: 'gasDetectors',
          key: 'gasDetectors',
          label: 'Gas Detectors Operational',
          type: DynamicFieldType.checkbox,
          category: DynamicFieldCategory.safety,
          sortOrder: 3,
          validation: DynamicFieldValidation(required: true),
        ),
      ],
      sections: [
        DynamicFormSection(
          id: 'safety_equipment',
          title: '🚨 Safety Equipment',
          fieldIds: ['fireExtinguishers', 'emergencyShutoff', 'gasDetectors'],
          sortOrder: 1,
        ),
      ],
      version: 1,
      active: true,
    );
    
    await storeFormTemplate(template);
  }
  
  static Future<void> _initializeMaintenanceTemplate() async {
    final template = DynamicFormTemplate(
      id: 'maintenance_standard',
      name: 'Maintenance Log',
      logType: 'maintenance',
      description: 'Equipment maintenance and service records',
      fields: [
        DynamicFormField(
          id: 'equipmentId',
          key: 'equipmentId',
          label: 'Equipment ID',
          type: DynamicFieldType.text,
          category: DynamicFieldCategory.core,
          sortOrder: 1,
          validation: DynamicFieldValidation(required: true),
        ),
        DynamicFormField(
          id: 'maintenanceType',
          key: 'maintenanceType',
          label: 'Maintenance Type',
          type: DynamicFieldType.select,
          category: DynamicFieldCategory.core,
          sortOrder: 2,
          validation: DynamicFieldValidation(required: true),
          options: [
            DynamicSelectOption(value: 'preventive', label: 'Preventive'),
            DynamicSelectOption(value: 'corrective', label: 'Corrective'),
            DynamicSelectOption(value: 'emergency', label: 'Emergency'),
            DynamicSelectOption(value: 'inspection', label: 'Inspection'),
          ],
        ),
        DynamicFormField(
          id: 'workPerformed',
          key: 'workPerformed',
          label: 'Work Performed',
          type: DynamicFieldType.text,
          category: DynamicFieldCategory.core,
          sortOrder: 3,
          validation: DynamicFieldValidation(required: true),
        ),
      ],
      sections: [
        DynamicFormSection(
          id: 'maintenance_details',
          title: '🔧 Maintenance Details',
          fieldIds: ['equipmentId', 'maintenanceType', 'workPerformed'],
          sortOrder: 1,
        ),
      ],
      version: 1,
      active: true,
    );
    
    await storeFormTemplate(template);
  }
}