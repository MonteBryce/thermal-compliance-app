import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/log_template.dart';

class LogTemplateService {
  static final _firestore = FirebaseFirestore.instance;
  
  /// Store Marathon GBR custom log template in Firestore
  static Future<void> storeMarathonGbrTemplate() async {
    try {
      final template = LogTemplateRegistry.getTemplate(LogType.marathonGbrCustom);
      
      await _firestore
          .collection('logTemplates')
          .doc('marathon_gbr_custom')
          .set({
        'logType': 'marathon_gbr_custom',
        'displayName': 'Texas - BLANK Thermal Log - Marathon GBR - CUSTOM',
        'client': 'Marathon GBR',
        'location': 'Texas City, TX',
        'description': template.description,
        'fields': template.fields.map((field) => {
          'id': field.id,
          'label': field.label,
          'unit': field.unit,
          'type': field.type.name,
          'section': field.section,
          'order': field.order,
          'isRequired': field.validation.required,
          'isOptional': field.isOptional,
          'helpText': field.helpText,
          'validation': {
            'min': field.validation.min,
            'max': field.validation.max,
            'warningMin': field.validation.warningMin,
            'warningMax': field.validation.warningMax,
            'warningMessage': field.validation.warningMessage,
          }
        }).toList(),
        'requiredFields': template.fields
            .where((f) => f.validation.required)
            .map((f) => f.id)
            .toList(),
        'optionalFields': template.fields
            .where((f) => f.isOptional)
            .map((f) => f.id)
            .toList(),
        'collapsibleSections': ['⚙️ Optional Readings'],
        'customConfig': {
          'marathonSpecific': true,
          'lelMonitoring': true,
          'targetLEL': '10%',
          'targetTemperature': '>1250°F',
          'product': 'Sour Water',
        },
        'createdAt': FieldValue.serverTimestamp(),
        'version': '1.0',
        'active': true,
      });

      print('✅ Marathon GBR custom template stored in Firestore');
    } catch (e) {
      print('❌ Error storing Marathon GBR template: $e');
      rethrow;
    }
  }

  /// Retrieve log template configuration from Firestore
  static Future<Map<String, dynamic>?> getLogTemplate(String templateId) async {
    try {
      final doc = await _firestore
          .collection('logTemplates')
          .doc(templateId)
          .get();
      
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('❌ Error retrieving log template $templateId: $e');
      return null;
    }
  }

  /// Get all available log templates
  static Future<List<Map<String, dynamic>>> getAllLogTemplates() async {
    try {
      final snapshot = await _firestore
          .collection('logTemplates')
          .where('active', isEqualTo: true)
          .orderBy('displayName')
          .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('❌ Error retrieving log templates: $e');
      return [];
    }
  }

  /// Determine which log template to use for a specific project
  static LogType getLogTypeForProject(String projectId) {
    // Marathon GBR project uses custom template
    if (projectId == '2025-2-095') {
      return LogType.marathonGbrCustom;
    }
    
    // Default to standard thermal template
    return LogType.thermal;
  }

  /// Initialize log templates in Firestore (run once during setup)
  static Future<void> initializeLogTemplates() async {
    try {
      await storeMarathonGbrTemplate();
      print('✅ All log templates initialized');
    } catch (e) {
      print('❌ Error initializing log templates: $e');
      rethrow;
    }
  }
}