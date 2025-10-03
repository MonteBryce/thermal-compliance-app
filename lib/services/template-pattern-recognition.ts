import { LogField, FieldType, LogTemplate } from '@/lib/types/logbuilder';
import { FieldPatternRecognition } from './field-pattern-recognition';

export interface TemplatePattern {
  id: string;
  name: string;
  description: string;
  category: 'thermal-monitoring' | 'maintenance' | 'compliance' | 'inspection' | 'calibration';
  confidence: number;
  fields: Array<{
    key: string;
    label: string;
    type: FieldType;
    required: boolean;
    unit?: string;
    validation?: any;
    placeholder?: string;
    helpText?: string;
  }>;
  fieldGroups: Array<{
    name: string;
    fields: string[];
    description: string;
  }>;
  workflowSteps?: string[];
  complianceStandards?: string[];
  industryTags: string[];
}

export interface PatternMatchResult {
  pattern: TemplatePattern;
  matchScore: number;
  matchedFields: string[];
  suggestedFields: string[];
  reasoning: string;
}

// Predefined thermal logging patterns
const thermalLoggingPatterns: TemplatePattern[] = [
  {
    id: 'daily-thermal-monitoring',
    name: 'Daily Thermal Monitoring',
    description: 'Standard daily thermal oxidizer monitoring and logging',
    category: 'thermal-monitoring',
    confidence: 0.95,
    fields: [
      {
        key: 'date_time',
        label: 'Date & Time',
        type: 'datetime-local',
        required: true,
        placeholder: 'MM/DD/YYYY HH:MM',
        helpText: 'Date and time of reading'
      },
      {
        key: 'equipment_id',
        label: 'Equipment ID',
        type: 'text',
        required: true,
        placeholder: 'TO-001',
        helpText: 'Unique thermal oxidizer identifier'
      },
      {
        key: 'chamber_temp',
        label: 'Chamber Temperature',
        type: 'number',
        required: true,
        unit: '°F',
        validation: { min: 1400, max: 2000 },
        placeholder: '1800',
        helpText: 'Primary combustion chamber temperature'
      },
      {
        key: 'stack_temp',
        label: 'Stack Temperature',
        type: 'number',
        required: true,
        unit: '°F',
        validation: { min: 200, max: 800 },
        placeholder: '400',
        helpText: 'Stack gas temperature'
      },
      {
        key: 'pressure_drop',
        label: 'Pressure Drop',
        type: 'number',
        required: true,
        unit: 'in H2O',
        validation: { min: 0, max: 50 },
        placeholder: '12.5',
        helpText: 'Pressure drop across the system'
      },
      {
        key: 'flow_rate',
        label: 'Gas Flow Rate',
        type: 'number',
        required: true,
        unit: 'SCFM',
        validation: { min: 0, max: 50000 },
        placeholder: '15000',
        helpText: 'Volumetric flow rate of waste gas'
      },
      {
        key: 'operator_name',
        label: 'Operator Name',
        type: 'text',
        required: true,
        placeholder: 'John Smith',
        helpText: 'Name of certified operator'
      },
      {
        key: 'status',
        label: 'Operating Status',
        type: 'select',
        required: true,
        placeholder: 'Select status',
        helpText: 'Current operational status'
      },
      {
        key: 'comments',
        label: 'Comments',
        type: 'textarea',
        required: false,
        placeholder: 'Additional observations...',
        helpText: 'Any unusual observations or notes'
      }
    ],
    fieldGroups: [
      {
        name: 'Header Information',
        fields: ['date_time', 'equipment_id', 'operator_name'],
        description: 'Basic identification and timing information'
      },
      {
        name: 'Temperature Readings',
        fields: ['chamber_temp', 'stack_temp'],
        description: 'Critical temperature measurements'
      },
      {
        name: 'Process Parameters',
        fields: ['pressure_drop', 'flow_rate'],
        description: 'Operational flow and pressure measurements'
      },
      {
        name: 'Status & Notes',
        fields: ['status', 'comments'],
        description: 'Current status and additional observations'
      }
    ],
    workflowSteps: [
      'Record current date and time',
      'Identify equipment and operator',
      'Take temperature readings from gauges',
      'Record pressure and flow measurements',
      'Assess overall operating status',
      'Document any unusual observations'
    ],
    complianceStandards: ['EPA 40 CFR Part 60', 'EPA 40 CFR Part 63', 'State Air Quality Standards'],
    industryTags: ['thermal-oxidizer', 'air-quality', 'emissions-control', 'daily-monitoring']
  },
  
  {
    id: 'maintenance-inspection',
    name: 'Maintenance Inspection',
    description: 'Comprehensive maintenance inspection checklist',
    category: 'maintenance',
    confidence: 0.90,
    fields: [
      {
        key: 'inspection_date',
        label: 'Inspection Date',
        type: 'date',
        required: true,
        helpText: 'Date maintenance inspection was performed'
      },
      {
        key: 'equipment_id',
        label: 'Equipment ID',
        type: 'text',
        required: true,
        placeholder: 'TO-001',
        helpText: 'Equipment identification number'
      },
      {
        key: 'inspector_name',
        label: 'Inspector Name',
        type: 'text',
        required: true,
        placeholder: 'Jane Doe',
        helpText: 'Qualified maintenance inspector'
      },
      {
        key: 'inspector_cert',
        label: 'Inspector Certification',
        type: 'text',
        required: true,
        placeholder: 'CERT-12345',
        helpText: 'Inspector certification number'
      },
      {
        key: 'burner_condition',
        label: 'Burner Condition',
        type: 'select',
        required: true,
        helpText: 'Overall condition of burner system'
      },
      {
        key: 'refractory_condition',
        label: 'Refractory Condition',
        type: 'select',
        required: true,
        helpText: 'Condition of refractory lining'
      },
      {
        key: 'control_system',
        label: 'Control System Check',
        type: 'select',
        required: true,
        helpText: 'Control system functionality test'
      },
      {
        key: 'safety_systems',
        label: 'Safety Systems',
        type: 'select',
        required: true,
        helpText: 'Safety interlock and alarm systems'
      },
      {
        key: 'maintenance_actions',
        label: 'Maintenance Actions',
        type: 'textarea',
        required: false,
        placeholder: 'List any maintenance performed...',
        helpText: 'Description of maintenance work completed'
      },
      {
        key: 'next_inspection_date',
        label: 'Next Inspection Date',
        type: 'date',
        required: true,
        helpText: 'Scheduled date for next inspection'
      }
    ],
    fieldGroups: [
      {
        name: 'Inspection Details',
        fields: ['inspection_date', 'equipment_id', 'inspector_name', 'inspector_cert'],
        description: 'Basic inspection identification information'
      },
      {
        name: 'Equipment Assessment',
        fields: ['burner_condition', 'refractory_condition', 'control_system', 'safety_systems'],
        description: 'Physical and operational condition checks'
      },
      {
        name: 'Actions & Schedule',
        fields: ['maintenance_actions', 'next_inspection_date'],
        description: 'Work performed and future planning'
      }
    ],
    workflowSteps: [
      'Document inspection date and personnel',
      'Visually inspect burner components',
      'Check refractory lining condition',
      'Test control system operation',
      'Verify safety system functionality',
      'Document maintenance actions taken',
      'Schedule next inspection'
    ],
    complianceStandards: ['OSHA 29 CFR 1910.147', 'NFPA 86', 'Insurance Requirements'],
    industryTags: ['maintenance', 'inspection', 'safety', 'compliance-check']
  },
  
  {
    id: 'calibration-record',
    name: 'Instrument Calibration',
    description: 'Calibration record for monitoring instruments',
    category: 'calibration',
    confidence: 0.88,
    fields: [
      {
        key: 'calibration_date',
        label: 'Calibration Date',
        type: 'date',
        required: true,
        helpText: 'Date calibration was performed'
      },
      {
        key: 'instrument_id',
        label: 'Instrument ID',
        type: 'text',
        required: true,
        placeholder: 'TI-001',
        helpText: 'Unique instrument identifier'
      },
      {
        key: 'instrument_type',
        label: 'Instrument Type',
        type: 'select',
        required: true,
        helpText: 'Type of monitoring instrument'
      },
      {
        key: 'technician_name',
        label: 'Technician Name',
        type: 'text',
        required: true,
        placeholder: 'Mike Johnson',
        helpText: 'Qualified calibration technician'
      },
      {
        key: 'standard_used',
        label: 'Calibration Standard',
        type: 'text',
        required: true,
        placeholder: 'STD-TEMP-001',
        helpText: 'Reference standard used for calibration'
      },
      {
        key: 'before_calibration',
        label: 'Before Calibration Reading',
        type: 'number',
        required: true,
        helpText: 'Instrument reading before calibration'
      },
      {
        key: 'after_calibration',
        label: 'After Calibration Reading',
        type: 'number',
        required: true,
        helpText: 'Instrument reading after calibration'
      },
      {
        key: 'accuracy_check',
        label: 'Accuracy Within Spec',
        type: 'checkbox',
        required: true,
        helpText: 'Is instrument accuracy within specification?'
      },
      {
        key: 'next_calibration',
        label: 'Next Calibration Due',
        type: 'date',
        required: true,
        helpText: 'Date when next calibration is due'
      }
    ],
    fieldGroups: [
      {
        name: 'Calibration Info',
        fields: ['calibration_date', 'instrument_id', 'instrument_type', 'technician_name'],
        description: 'Basic calibration identification'
      },
      {
        name: 'Calibration Process',
        fields: ['standard_used', 'before_calibration', 'after_calibration', 'accuracy_check'],
        description: 'Calibration procedure and results'
      },
      {
        name: 'Scheduling',
        fields: ['next_calibration'],
        description: 'Future calibration planning'
      }
    ],
    complianceStandards: ['ISO/IEC 17025', 'EPA Method Requirements', 'ANSI Standards'],
    industryTags: ['calibration', 'instrumentation', 'quality-assurance', 'metrology']
  },
  
  {
    id: 'compliance-report',
    name: 'Compliance Reporting',
    description: 'Environmental compliance reporting template',
    category: 'compliance',
    confidence: 0.92,
    fields: [
      {
        key: 'report_period_start',
        label: 'Report Period Start',
        type: 'date',
        required: true,
        helpText: 'Beginning of reporting period'
      },
      {
        key: 'report_period_end',
        label: 'Report Period End',
        type: 'date',
        required: true,
        helpText: 'End of reporting period'
      },
      {
        key: 'facility_id',
        label: 'Facility ID',
        type: 'text',
        required: true,
        placeholder: 'FAC-001',
        helpText: 'EPA facility identification number'
      },
      {
        key: 'permit_number',
        label: 'Permit Number',
        type: 'text',
        required: true,
        placeholder: 'AIR-2023-001',
        helpText: 'Air quality permit number'
      },
      {
        key: 'destruction_efficiency',
        label: 'Destruction Efficiency',
        type: 'number',
        required: true,
        unit: '%',
        validation: { min: 95, max: 100 },
        placeholder: '99.5',
        helpText: 'Calculated destruction and removal efficiency'
      },
      {
        key: 'operating_hours',
        label: 'Operating Hours',
        type: 'number',
        required: true,
        unit: 'hours',
        validation: { min: 0, max: 8760 },
        helpText: 'Total operating hours during period'
      },
      {
        key: 'compliance_status',
        label: 'Compliance Status',
        type: 'select',
        required: true,
        helpText: 'Overall compliance status for reporting period'
      },
      {
        key: 'deviations',
        label: 'Deviations',
        type: 'textarea',
        required: false,
        placeholder: 'Describe any permit deviations...',
        helpText: 'Description of any deviations from permit conditions'
      },
      {
        key: 'prepared_by',
        label: 'Prepared By',
        type: 'text',
        required: true,
        placeholder: 'Environmental Manager',
        helpText: 'Name and title of person preparing report'
      }
    ],
    fieldGroups: [
      {
        name: 'Report Period',
        fields: ['report_period_start', 'report_period_end', 'facility_id', 'permit_number'],
        description: 'Reporting period and facility identification'
      },
      {
        name: 'Performance Data',
        fields: ['destruction_efficiency', 'operating_hours', 'compliance_status'],
        description: 'Key performance and compliance metrics'
      },
      {
        name: 'Additional Information',
        fields: ['deviations', 'prepared_by'],
        description: 'Deviations and report preparation details'
      }
    ],
    complianceStandards: ['EPA 40 CFR Part 63', 'State Reporting Requirements', 'Permit Conditions'],
    industryTags: ['compliance', 'reporting', 'environmental', 'epa', 'permits']
  }
];

export class TemplatePatternRecognition {
  /**
   * Analyze existing fields and suggest matching patterns
   */
  static analyzeExistingFields(existingFields: LogField[]): PatternMatchResult[] {
    const results: PatternMatchResult[] = [];
    
    for (const pattern of thermalLoggingPatterns) {
      const matchResult = this.calculatePatternMatch(existingFields, pattern);
      if (matchResult.matchScore > 0.3) { // Only include matches above 30%
        results.push(matchResult);
      }
    }
    
    return results.sort((a, b) => b.matchScore - a.matchScore);
  }
  
  /**
   * Calculate how well existing fields match a pattern
   */
  private static calculatePatternMatch(
    existingFields: LogField[], 
    pattern: TemplatePattern
  ): PatternMatchResult {
    const existingFieldKeys = existingFields.map(f => f.key.toLowerCase());
    const existingFieldLabels = existingFields.map(f => (f.label || '').toLowerCase());
    const existingFieldText = [...existingFieldKeys, ...existingFieldLabels].join(' ');
    
    let matchedFields: string[] = [];
    let keywordMatches = 0;
    
    // Check for direct field matches
    for (const patternField of pattern.fields) {
      const patternKey = patternField.key.toLowerCase();
      const patternLabel = patternField.label.toLowerCase();
      
      const hasKeyMatch = existingFieldKeys.some(key => 
        key.includes(patternKey) || patternKey.includes(key)
      );
      
      const hasLabelMatch = existingFieldLabels.some(label =>
        label.includes(patternLabel) || patternLabel.includes(label)
      );
      
      if (hasKeyMatch || hasLabelMatch) {
        matchedFields.push(patternField.key);
      }
    }
    
    // Check for keyword/theme matches
    const patternKeywords = [
      ...pattern.industryTags,
      ...pattern.complianceStandards.map(s => s.toLowerCase()),
      pattern.name.toLowerCase(),
      pattern.description.toLowerCase()
    ].join(' ');
    
    for (const tag of pattern.industryTags) {
      if (existingFieldText.includes(tag.toLowerCase())) {
        keywordMatches++;
      }
    }
    
    // Calculate match score
    const fieldMatchScore = matchedFields.length / pattern.fields.length;
    const keywordMatchScore = Math.min(keywordMatches / pattern.industryTags.length, 1.0);
    const overallMatchScore = (fieldMatchScore * 0.7) + (keywordMatchScore * 0.3);
    
    // Generate suggestions for missing fields
    const suggestedFields = pattern.fields
      .filter(f => !matchedFields.includes(f.key))
      .map(f => f.key)
      .slice(0, 5); // Limit to top 5 suggestions
    
    const reasoning = this.generateMatchReasoning(
      matchedFields, 
      keywordMatches, 
      pattern.name,
      overallMatchScore
    );
    
    return {
      pattern,
      matchScore: overallMatchScore,
      matchedFields,
      suggestedFields,
      reasoning
    };
  }
  
  /**
   * Generate human-readable reasoning for pattern match
   */
  private static generateMatchReasoning(
    matchedFields: string[],
    keywordMatches: number,
    patternName: string,
    score: number
  ): string {
    let reasoning = `${Math.round(score * 100)}% match with ${patternName} pattern. `;
    
    if (matchedFields.length > 0) {
      reasoning += `Matched fields: ${matchedFields.slice(0, 3).join(', ')}`;
      if (matchedFields.length > 3) {
        reasoning += ` and ${matchedFields.length - 3} others`;
      }
      reasoning += '. ';
    }
    
    if (keywordMatches > 0) {
      reasoning += `${keywordMatches} keyword matches found. `;
    }
    
    if (score > 0.8) {
      reasoning += 'Strong pattern match - highly recommended.';
    } else if (score > 0.6) {
      reasoning += 'Good pattern match - recommended for consideration.';
    } else if (score > 0.4) {
      reasoning += 'Partial pattern match - may be relevant.';
    } else {
      reasoning += 'Weak pattern match - consider for inspiration.';
    }
    
    return reasoning;
  }
  
  /**
   * Get all available patterns by category
   */
  static getPatternsByCategory(): { [key: string]: TemplatePattern[] } {
    const categorized: { [key: string]: TemplatePattern[] } = {};
    
    for (const pattern of thermalLoggingPatterns) {
      if (!categorized[pattern.category]) {
        categorized[pattern.category] = [];
      }
      categorized[pattern.category].push(pattern);
    }
    
    return categorized;
  }
  
  /**
   * Search patterns by keywords
   */
  static searchPatterns(query: string): TemplatePattern[] {
    const queryLower = query.toLowerCase();
    
    return thermalLoggingPatterns.filter(pattern => {
      const searchableText = [
        pattern.name,
        pattern.description,
        ...pattern.industryTags,
        ...pattern.complianceStandards
      ].join(' ').toLowerCase();
      
      return searchableText.includes(queryLower);
    }).sort((a, b) => b.confidence - a.confidence);
  }
  
  /**
   * Apply a pattern to create new fields for a template
   */
  static applyPatternToTemplate(
    pattern: TemplatePattern,
    existingFields: LogField[] = []
  ): {
    newFields: LogField[];
    fieldGroups: Array<{ name: string; fields: string[]; description: string }>;
    workflowSteps?: string[];
  } {
    const existingKeys = existingFields.map(f => f.key);
    const newFields: LogField[] = [];
    
    for (const patternField of pattern.fields) {
      if (!existingKeys.includes(patternField.key)) {
        const newField: LogField = {
          id: `pattern-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
          key: patternField.key,
          label: patternField.label,
          type: patternField.type,
          required: patternField.required,
          unit: patternField.unit,
          validation: patternField.validation,
          placeholder: patternField.placeholder,
          helpText: patternField.helpText
        };
        
        newFields.push(newField);
      }
    }
    
    return {
      newFields,
      fieldGroups: pattern.fieldGroups,
      workflowSteps: pattern.workflowSteps
    };
  }
  
  /**
   * Learn from user pattern adoption
   */
  static recordPatternUsage(
    patternId: string,
    fieldsAdopted: string[],
    fieldsRejected: string[],
    userFeedback?: string
  ): void {
    const learningKey = 'pattern-learning-data';
    let learningData: Array<{
      patternId: string;
      fieldsAdopted: string[];
      fieldsRejected: string[];
      userFeedback?: string;
      timestamp: number;
    }> = [];
    
    try {
      const stored = localStorage.getItem(learningKey);
      if (stored) {
        learningData = JSON.parse(stored);
      }
    } catch (error) {
      console.warn('Failed to load pattern learning data:', error);
    }
    
    learningData.push({
      patternId,
      fieldsAdopted,
      fieldsRejected,
      userFeedback,
      timestamp: Date.now()
    });
    
    // Keep only the last 500 entries
    if (learningData.length > 500) {
      learningData = learningData.slice(-500);
    }
    
    try {
      localStorage.setItem(learningKey, JSON.stringify(learningData));
    } catch (error) {
      console.warn('Failed to save pattern learning data:', error);
    }
  }
}