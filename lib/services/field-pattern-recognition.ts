import { LogField, FieldType } from '@/lib/types/logbuilder';

export interface FieldTypePattern {
  pattern: RegExp;
  type: FieldType;
  confidence: number;
  suggestedUnit?: string;
  suggestedValidation?: {
    required?: boolean;
    min?: number;
    max?: number;
    pattern?: string;
  };
  suggestedPlaceholder?: string;
}

export interface SmartDefaults {
  type: FieldType;
  unit?: string;
  validation?: {
    required?: boolean;
    min?: number;
    max?: number;
    pattern?: string;
  };
  placeholder?: string;
  confidence: number;
  reasoning: string;
}

// Thermal logging specific patterns
const thermalLoggingPatterns: FieldTypePattern[] = [
  // Temperature patterns
  {
    pattern: /temp(?:erature)?|thermal|heat|deg(?:ree)?s?/i,
    type: 'number',
    confidence: 0.95,
    suggestedUnit: '°F',
    suggestedValidation: { required: true, min: -50, max: 5000 },
    suggestedPlaceholder: 'Enter temperature in °F'
  },
  {
    pattern: /celsius|centigrade/i,
    type: 'number',
    confidence: 0.95,
    suggestedUnit: '°C',
    suggestedValidation: { required: true, min: -50, max: 2500 },
    suggestedPlaceholder: 'Enter temperature in °C'
  },
  
  // Pressure patterns
  {
    pattern: /pressure|psi|bar|pascal|kpa|mpa/i,
    type: 'number',
    confidence: 0.90,
    suggestedUnit: 'PSI',
    suggestedValidation: { required: true, min: 0, max: 10000 },
    suggestedPlaceholder: 'Enter pressure reading'
  },
  
  // Flow rate patterns
  {
    pattern: /flow|rate|cfm|scfm|gpm|lpm|velocity/i,
    type: 'number',
    confidence: 0.88,
    suggestedUnit: 'CFM',
    suggestedValidation: { required: true, min: 0, max: 100000 },
    suggestedPlaceholder: 'Enter flow rate'
  },
  
  // Time and date patterns
  {
    pattern: /date|time|when|schedule|maintenance|calibrat(?:ion|ed)|inspect(?:ion|ed)/i,
    type: 'date',
    confidence: 0.92,
    suggestedValidation: { required: true },
    suggestedPlaceholder: 'MM/DD/YYYY'
  },
  
  // Duration/Hours patterns
  {
    pattern: /hours?|duration|runtime|operating|uptime/i,
    type: 'number',
    confidence: 0.85,
    suggestedUnit: 'hours',
    suggestedValidation: { required: false, min: 0, max: 100000 },
    suggestedPlaceholder: 'Enter hours'
  },
  
  // Percentage patterns
  {
    pattern: /percent(?:age)?|%|efficiency|utilization/i,
    type: 'number',
    confidence: 0.90,
    suggestedUnit: '%',
    suggestedValidation: { required: false, min: 0, max: 100 },
    suggestedPlaceholder: 'Enter percentage (0-100)'
  },
  
  // Status/Selection patterns
  {
    pattern: /status|state|condition|alarm|alert|level/i,
    type: 'select',
    confidence: 0.80,
    suggestedPlaceholder: 'Select status'
  },
  
  // Boolean/Checkbox patterns
  {
    pattern: /(?:is|has|enable|disable|active|inactive|on|off|pass|fail|yes|no)$/i,
    type: 'checkbox',
    confidence: 0.85,
    suggestedPlaceholder: 'Check if applicable'
  },
  
  // ID/Serial number patterns
  {
    pattern: /(?:id|serial|number|code|tag)$/i,
    type: 'text',
    confidence: 0.80,
    suggestedValidation: { required: true, pattern: '^[A-Z0-9-]+$' },
    suggestedPlaceholder: 'Enter ID or serial number'
  },
  
  // Email patterns
  {
    pattern: /email|e-mail|mail/i,
    type: 'text',
    confidence: 0.95,
    suggestedValidation: { 
      required: false, 
      pattern: '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$' 
    },
    suggestedPlaceholder: 'user@company.com'
  },
  
  // Phone patterns
  {
    pattern: /phone|tel|mobile|cell/i,
    type: 'text',
    confidence: 0.92,
    suggestedValidation: { 
      required: false, 
      pattern: '^\\(?([0-9]{3})\\)?[-. ]?([0-9]{3})[-. ]?([0-9]{4})$' 
    },
    suggestedPlaceholder: '(555) 123-4567'
  },
  
  // Name patterns
  {
    pattern: /name|inspector|operator|technician|engineer/i,
    type: 'text',
    confidence: 0.85,
    suggestedValidation: { required: true },
    suggestedPlaceholder: 'Enter full name'
  },
  
  // Location patterns
  {
    pattern: /location|site|area|zone|building|room|unit/i,
    type: 'text',
    confidence: 0.80,
    suggestedPlaceholder: 'Enter location'
  },
  
  // Comments/Notes patterns
  {
    pattern: /comment|note|remark|observation|description/i,
    type: 'textarea',
    confidence: 0.88,
    suggestedValidation: { required: false },
    suggestedPlaceholder: 'Enter additional notes or observations...'
  }
];

// Industrial-specific status options
const statusOptions: { [key: string]: string[] } = {
  default: ['Normal', 'Warning', 'Critical', 'Off', 'Maintenance'],
  alarm: ['Normal', 'Low', 'High', 'Critical', 'Fault'],
  equipment: ['Online', 'Offline', 'Standby', 'Maintenance', 'Fault'],
  safety: ['Safe', 'Warning', 'Danger', 'Emergency', 'Lockout'],
  quality: ['Pass', 'Fail', 'Warning', 'Review Required'],
  compliance: ['Compliant', 'Non-Compliant', 'Pending Review', 'Exempt']
};

export class FieldPatternRecognition {
  /**
   * Analyze field name/label and suggest smart defaults
   */
  static analyzeFieldName(fieldName: string, fieldLabel?: string): SmartDefaults | null {
    const searchText = `${fieldName} ${fieldLabel || ''}`.toLowerCase();
    
    // Find the best matching pattern
    let bestMatch: FieldTypePattern | null = null;
    let bestConfidence = 0;
    
    for (const pattern of thermalLoggingPatterns) {
      if (pattern.pattern.test(searchText) && pattern.confidence > bestConfidence) {
        bestMatch = pattern;
        bestConfidence = pattern.confidence;
      }
    }
    
    if (!bestMatch) {
      return null;
    }
    
    // Generate smart defaults based on the matched pattern
    const defaults: SmartDefaults = {
      type: bestMatch.type,
      confidence: bestMatch.confidence,
      reasoning: `Detected as ${bestMatch.type} based on naming pattern`
    };
    
    if (bestMatch.suggestedUnit) {
      defaults.unit = bestMatch.suggestedUnit;
    }
    
    if (bestMatch.suggestedValidation) {
      defaults.validation = bestMatch.suggestedValidation;
    }
    
    if (bestMatch.suggestedPlaceholder) {
      defaults.placeholder = bestMatch.suggestedPlaceholder;
    }
    
    // Add specific options for select fields
    if (bestMatch.type === 'select') {
      const selectOptions = this.generateSelectOptions(searchText);
      if (selectOptions.length > 0) {
        defaults.validation = {
          ...defaults.validation,
          // Store options in a custom property (would need to extend validation type)
        };
        defaults.reasoning += ` with suggested options: ${selectOptions.slice(0, 3).join(', ')}`;
      }
    }
    
    return defaults;
  }
  
  /**
   * Generate appropriate select options based on field context
   */
  static generateSelectOptions(searchText: string): string[] {
    if (/alarm|alert/.test(searchText)) {
      return statusOptions.alarm;
    }
    if (/equipment|machine|device/.test(searchText)) {
      return statusOptions.equipment;
    }
    if (/safety|hazard|risk/.test(searchText)) {
      return statusOptions.safety;
    }
    if (/quality|test|check/.test(searchText)) {
      return statusOptions.quality;
    }
    if (/compliance|regulation|standard/.test(searchText)) {
      return statusOptions.compliance;
    }
    
    return statusOptions.default;
  }
  
  /**
   * Analyze a collection of fields to suggest relationships and groupings
   */
  static analyzeFieldRelationships(fields: LogField[]): {
    suggestedGroupings: Array<{
      name: string;
      fields: string[];
      reasoning: string;
    }>;
    fieldDependencies: Array<{
      primary: string;
      dependent: string;
      relationship: string;
    }>;
  } {
    const groupings: Array<{
      name: string;
      fields: string[];
      reasoning: string;
    }> = [];
    
    const dependencies: Array<{
      primary: string;
      dependent: string;
      relationship: string;
    }> = [];
    
    // Group fields by common themes
    const themes = {
      temperature: fields.filter(f => /temp|thermal|heat|deg/i.test(`${f.key} ${f.label}`)),
      pressure: fields.filter(f => /pressure|psi|bar/i.test(`${f.key} ${f.label}`)),
      flow: fields.filter(f => /flow|rate|cfm|velocity/i.test(`${f.key} ${f.label}`)),
      maintenance: fields.filter(f => /maint|service|repair|calibrat/i.test(`${f.key} ${f.label}`)),
      identification: fields.filter(f => /id|serial|tag|number|name/i.test(`${f.key} ${f.label}`)),
      datetime: fields.filter(f => /date|time|when/i.test(`${f.key} ${f.label}`)),
      personnel: fields.filter(f => /inspector|operator|tech|engineer|name/i.test(`${f.key} ${f.label}`)),
      location: fields.filter(f => /location|site|area|zone|building/i.test(`${f.key} ${f.label}`))
    };
    
    // Create groupings for themes with multiple fields
    Object.entries(themes).forEach(([theme, themeFields]) => {
      if (themeFields.length >= 2) {
        groupings.push({
          name: `${theme.charAt(0).toUpperCase() + theme.slice(1)} Readings`,
          fields: themeFields.map(f => f.key),
          reasoning: `Fields related to ${theme} measurements and monitoring`
        });
      }
    });
    
    // Identify common dependencies
    fields.forEach(field => {
      const fieldText = `${field.key} ${field.label}`.toLowerCase();
      
      // Date/time dependencies
      if (/date|time/.test(fieldText)) {
        const relatedFields = fields.filter(f => 
          f.key !== field.key && 
          /reading|measure|value|level/.test(`${f.key} ${f.label}`.toLowerCase())
        );
        
        relatedFields.forEach(related => {
          dependencies.push({
            primary: field.key,
            dependent: related.key,
            relationship: 'temporal_context'
          });
        });
      }
      
      // Equipment ID dependencies
      if (/(?:equipment|unit|device).*id/i.test(fieldText) || /id.*(?:equipment|unit|device)/i.test(fieldText)) {
        const equipmentFields = fields.filter(f =>
          f.key !== field.key &&
          !/id|serial|tag/.test(`${f.key} ${f.label}`.toLowerCase()) &&
          /temp|pressure|flow|status/.test(`${f.key} ${f.label}`.toLowerCase())
        );
        
        equipmentFields.forEach(related => {
          dependencies.push({
            primary: field.key,
            dependent: related.key,
            relationship: 'equipment_association'
          });
        });
      }
    });
    
    return {
      suggestedGroupings: groupings,
      fieldDependencies: dependencies
    };
  }
  
  /**
   * Learn from user behavior to improve pattern recognition
   */
  static learnFromUserChoice(
    fieldName: string,
    suggestedType: FieldType,
    actualType: FieldType,
    accepted: boolean
  ): void {
    const learningKey = 'field-pattern-learning';
    let learningData: Array<{
      pattern: string;
      suggested: FieldType;
      actual: FieldType;
      accepted: boolean;
      timestamp: number;
    }> = [];
    
    try {
      const stored = localStorage.getItem(learningKey);
      if (stored) {
        learningData = JSON.parse(stored);
      }
    } catch (error) {
      console.warn('Failed to load learning data:', error);
    }
    
    learningData.push({
      pattern: fieldName.toLowerCase(),
      suggested: suggestedType,
      actual: actualType,
      accepted,
      timestamp: Date.now()
    });
    
    // Keep only the last 1000 learning entries
    if (learningData.length > 1000) {
      learningData = learningData.slice(-1000);
    }
    
    try {
      localStorage.setItem(learningKey, JSON.stringify(learningData));
    } catch (error) {
      console.warn('Failed to save learning data:', error);
    }
  }
  
  /**
   * Get learning-adjusted confidence for a field pattern
   */
  static getAdjustedConfidence(fieldName: string, suggestedType: FieldType): number {
    const learningKey = 'field-pattern-learning';
    
    try {
      const stored = localStorage.getItem(learningKey);
      if (!stored) return 1.0;
      
      const learningData: Array<{
        pattern: string;
        suggested: FieldType;
        actual: FieldType;
        accepted: boolean;
        timestamp: number;
      }> = JSON.parse(stored);
      
      // Find similar patterns
      const similarPatterns = learningData.filter(entry => {
        return entry.pattern.includes(fieldName.toLowerCase()) || 
               fieldName.toLowerCase().includes(entry.pattern);
      });
      
      if (similarPatterns.length === 0) return 1.0;
      
      // Calculate acceptance rate for this type
      const typeMatches = similarPatterns.filter(entry => entry.suggested === suggestedType);
      const acceptanceRate = typeMatches.length > 0 
        ? typeMatches.filter(entry => entry.accepted).length / typeMatches.length
        : 1.0;
      
      // Adjust confidence based on learning
      return Math.max(0.1, Math.min(1.0, acceptanceRate));
      
    } catch (error) {
      console.warn('Failed to get adjusted confidence:', error);
      return 1.0;
    }
  }
}