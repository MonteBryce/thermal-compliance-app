import { TemplateVersion, Toggles, Targets, FieldSpec } from './versioned-types';

// Pre-made template library based on analyzed Excel/PDF documents
export interface LibraryTemplate {
  id: string;
  name: string;
  description: string;
  category: 'thermal' | 'environmental' | 'safety' | 'operations';
  tags: string[];
  gasType: 'methane' | 'pentane';
  version: TemplateVersion;
  sourceDocument: string;
  facilityType: string[];
  popularity: number; // For sorting
  lastUpdated: string;
}

export const LIBRARY_TEMPLATES: LibraryTemplate[] = [
  {
    id: 'marathon-gbr-standard',
    name: 'Marathon GBR Thermal Standard',
    description: 'Standard hourly thermal log for Marathon GBR platform operations',
    category: 'thermal',
    tags: ['Methane', 'Hourly', 'Platform'],
    gasType: 'methane',
    sourceDocument: 'Marathon_GBR_Thermal_Log.xlsx',
    facilityType: ['offshore', 'platform'],
    popularity: 95,
    lastUpdated: '2024-01-15',
    version: {
      version: 1,
      status: 'locked',
      toggles: {
        hasH2S: false,
        hasBenzene: false,
        hasLEL: false,
        hasO2: false,
        isRefill: false,
        is12hr: false,
        isFinal: false,
      },
      gasType: 'methane',
      fields: [
        { id: 'time', key: 'time', label: 'Time', type: 'time', required: true, visible: true },
        { id: 'exhaustTempF', key: 'exhaustTempF', label: 'Exhaust Temperature', type: 'number', unit: '°F', required: true, visible: true, validationRules: { min: 32, max: 2000 } },
        { id: 'vacuumH2O', key: 'vacuumH2O', label: 'Vacuum', type: 'number', unit: 'inH2O', required: true, visible: true, validationRules: { min: 0, max: 30 } },
        { id: 'inletMethanePct', key: 'inletMethanePct', label: 'Inlet Methane', type: 'number', unit: '%', required: true, visible: true, validationRules: { min: 0, max: 100 } },
        { id: 'outletMethanePPM', key: 'outletMethanePPM', label: 'Outlet Methane', type: 'number', unit: 'PPM', required: true, visible: true, validationRules: { min: 0, max: 100000 } },
        { id: 'operatorInitials', key: 'operatorInitials', label: 'Operator Initials', type: 'text', required: true, visible: true },
      ],
      targets: {},
      ui: { groups: ['core', 'operator'], layout: 'standard' },
      excelTemplatePath: 'library/marathon-gbr-standard.xlsx',
      operationRange: { start: 'B12', end: 'N28', sheet: 'Sheet1' },
      createdAt: Date.now(),
      createdBy: 'system',
      hash: 'marathon-gbr-v1',
    },
  },
  {
    id: 'shell-perdido-h2s',
    name: 'Shell Perdido H₂S Enhanced',
    description: 'Enhanced thermal log with H₂S monitoring for Shell Perdido platform',
    category: 'safety',
    tags: ['Methane', 'Hourly', 'H₂S', 'Platform'],
    gasType: 'methane',
    sourceDocument: 'Shell_Perdido_H2S_Log.xlsx',
    facilityType: ['offshore', 'platform'],
    popularity: 88,
    lastUpdated: '2024-01-12',
    version: {
      version: 1,
      status: 'locked',
      toggles: {
        hasH2S: true,
        hasBenzene: false,
        hasLEL: false,
        hasO2: false,
        isRefill: false,
        is12hr: false,
        isFinal: false,
      },
      gasType: 'methane',
      fields: [
        { id: 'time', key: 'time', label: 'Time', type: 'time', required: true, visible: true },
        { id: 'exhaustTempF', key: 'exhaustTempF', label: 'Exhaust Temperature', type: 'number', unit: '°F', required: true, visible: true, validationRules: { min: 32, max: 2000 } },
        { id: 'vacuumH2O', key: 'vacuumH2O', label: 'Vacuum', type: 'number', unit: 'inH2O', required: true, visible: true, validationRules: { min: 0, max: 30 } },
        { id: 'inletMethanePct', key: 'inletMethanePct', label: 'Inlet Methane', type: 'number', unit: '%', required: true, visible: true, validationRules: { min: 0, max: 100 } },
        { id: 'outletMethanePPM', key: 'outletMethanePPM', label: 'Outlet Methane', type: 'number', unit: 'PPM', required: true, visible: true, validationRules: { min: 0, max: 100000 } },
        { id: 'h2sPPM', key: 'h2sPPM', label: 'H₂S Level', type: 'number', unit: 'PPM', required: true, visible: true, validationRules: { min: 0, max: 1000 } },
        { id: 'operatorInitials', key: 'operatorInitials', label: 'Operator Initials', type: 'text', required: true, visible: true },
      ],
      targets: { h2sPPM: 10 },
      ui: { groups: ['core', 'safety', 'operator'], layout: 'standard' },
      excelTemplatePath: 'library/shell-perdido-h2s.xlsx',
      operationRange: { start: 'B12', end: 'O28', sheet: 'Sheet1' },
      createdAt: Date.now(),
      createdBy: 'system',
      hash: 'shell-perdido-h2s-v1',
    },
  },
  {
    id: 'bp-thunder-benzene',
    name: 'BP Thunder Horse Benzene Monitor',
    description: 'Comprehensive benzene monitoring for BP Thunder Horse operations',
    category: 'environmental',
    tags: ['Methane', 'Hourly', 'Benzene', 'Environmental'],
    gasType: 'methane',
    sourceDocument: 'BP_Thunder_Benzene_Log.xlsx',
    facilityType: ['offshore', 'platform'],
    popularity: 82,
    lastUpdated: '2024-01-10',
    version: {
      version: 1,
      status: 'locked',
      toggles: {
        hasH2S: false,
        hasBenzene: true,
        hasLEL: false,
        hasO2: false,
        isRefill: false,
        is12hr: false,
        isFinal: false,
      },
      gasType: 'methane',
      fields: [
        { id: 'time', key: 'time', label: 'Time', type: 'time', required: true, visible: true },
        { id: 'exhaustTempF', key: 'exhaustTempF', label: 'Exhaust Temperature', type: 'number', unit: '°F', required: true, visible: true, validationRules: { min: 32, max: 2000 } },
        { id: 'vacuumH2O', key: 'vacuumH2O', label: 'Vacuum', type: 'number', unit: 'inH2O', required: true, visible: true, validationRules: { min: 0, max: 30 } },
        { id: 'inletMethanePct', key: 'inletMethanePct', label: 'Inlet Methane', type: 'number', unit: '%', required: true, visible: true, validationRules: { min: 0, max: 100 } },
        { id: 'outletMethanePPM', key: 'outletMethanePPM', label: 'Outlet Methane', type: 'number', unit: 'PPM', required: true, visible: true, validationRules: { min: 0, max: 100000 } },
        { id: 'benzenePPM', key: 'benzenePPM', label: 'Benzene Level', type: 'number', unit: 'PPM', required: true, visible: true, validationRules: { min: 0, max: 1000 } },
        { id: 'operatorInitials', key: 'operatorInitials', label: 'Operator Initials', type: 'text', required: true, visible: true },
      ],
      targets: { benzenePPM: 1 },
      ui: { groups: ['core', 'environmental', 'operator'], layout: 'standard' },
      excelTemplatePath: 'library/bp-thunder-benzene.xlsx',
      operationRange: { start: 'B12', end: 'O28', sheet: 'Sheet1' },
      createdAt: Date.now(),
      createdBy: 'system',
      hash: 'bp-thunder-benzene-v1',
    },
  },
  {
    id: 'chevron-pentane-lel',
    name: 'Chevron Pentane LEL Monitor',
    description: 'Pentane vapor monitoring with LEL safety controls',
    category: 'safety',
    tags: ['Pentane', 'Hourly', 'LEL', 'Safety'],
    gasType: 'pentane',
    sourceDocument: 'Chevron_Pentane_LEL_Log.xlsx',
    facilityType: ['onshore', 'refinery'],
    popularity: 76,
    lastUpdated: '2024-01-08',
    version: {
      version: 1,
      status: 'locked',
      toggles: {
        hasH2S: false,
        hasBenzene: false,
        hasLEL: true,
        hasO2: false,
        isRefill: false,
        is12hr: false,
        isFinal: false,
      },
      gasType: 'pentane',
      fields: [
        { id: 'time', key: 'time', label: 'Time', type: 'time', required: true, visible: true },
        { id: 'exhaustTempF', key: 'exhaustTempF', label: 'Exhaust Temperature', type: 'number', unit: '°F', required: true, visible: true, validationRules: { min: 32, max: 2000 } },
        { id: 'vacuumH2O', key: 'vacuumH2O', label: 'Vacuum', type: 'number', unit: 'inH2O', required: true, visible: true, validationRules: { min: 0, max: 30 } },
        { id: 'inletPentanePPM', key: 'inletPentanePPM', label: 'Inlet Pentane', type: 'number', unit: 'PPM', required: true, visible: true, validationRules: { min: 0, max: 100000 } },
        { id: 'outletPentanePPM', key: 'outletPentanePPM', label: 'Outlet Pentane', type: 'number', unit: 'PPM', required: true, visible: true, validationRules: { min: 0, max: 100000 } },
        { id: 'inletLEL', key: 'inletLEL', label: 'Inlet LEL', type: 'number', unit: '%', required: true, visible: true, validationRules: { min: 0, max: 100 } },
        { id: 'operatorInitials', key: 'operatorInitials', label: 'Operator Initials', type: 'text', required: true, visible: true },
      ],
      targets: { lelPct: 10 },
      ui: { groups: ['core', 'safety', 'operator'], layout: 'standard' },
      excelTemplatePath: 'library/chevron-pentane-lel.xlsx',
      operationRange: { start: 'B12', end: 'O28', sheet: 'Sheet1' },
      createdAt: Date.now(),
      createdBy: 'system',
      hash: 'chevron-pentane-lel-v1',
    },
  },
  {
    id: 'exxon-12hr-extended',
    name: 'ExxonMobil 12-Hour Extended',
    description: '12-hour extended monitoring for continuous operations',
    category: 'operations',
    tags: ['Methane', '12-hr', 'Extended', 'Continuous'],
    gasType: 'methane',
    sourceDocument: 'ExxonMobil_12hr_Extended_Log.xlsx',
    facilityType: ['offshore', 'platform'],
    popularity: 71,
    lastUpdated: '2024-01-05',
    version: {
      version: 1,
      status: 'locked',
      toggles: {
        hasH2S: false,
        hasBenzene: false,
        hasLEL: false,
        hasO2: false,
        isRefill: false,
        is12hr: true,
        isFinal: false,
      },
      gasType: 'methane',
      fields: [
        { id: 'startTime', key: 'startTime', label: 'Start Time', type: 'time', required: true, visible: true },
        { id: 'stopTime', key: 'stopTime', label: 'Stop Time', type: 'time', required: true, visible: true },
        { id: 'exhaustTempF', key: 'exhaustTempF', label: 'Exhaust Temperature', type: 'number', unit: '°F', required: true, visible: true, validationRules: { min: 32, max: 2000 } },
        { id: 'vacuumH2O', key: 'vacuumH2O', label: 'Vacuum', type: 'number', unit: 'inH2O', required: true, visible: true, validationRules: { min: 0, max: 30 } },
        { id: 'inletMethanePct', key: 'inletMethanePct', label: 'Inlet Methane', type: 'number', unit: '%', required: true, visible: true, validationRules: { min: 0, max: 100 } },
        { id: 'outletMethanePPM', key: 'outletMethanePPM', label: 'Outlet Methane', type: 'number', unit: 'PPM', required: true, visible: true, validationRules: { min: 0, max: 100000 } },
        { id: 'operatorInitials', key: 'operatorInitials', label: 'Operator Initials', type: 'text', required: true, visible: true },
      ],
      targets: {},
      ui: { groups: ['core', 'operator'], layout: 'extended' },
      excelTemplatePath: 'library/exxon-12hr-extended.xlsx',
      operationRange: { start: 'B12', end: 'N24', sheet: 'Sheet1' },
      createdAt: Date.now(),
      createdBy: 'system',
      hash: 'exxon-12hr-extended-v1',
    },
  },
  {
    id: 'conocophillips-refill',
    name: 'ConocoPhillips Tank Refill',
    description: 'Tank refill operations monitoring with flow rates',
    category: 'operations',
    tags: ['Methane', 'Refill', 'Operations', 'Tank'],
    gasType: 'methane',
    sourceDocument: 'ConocoPhillips_Tank_Refill_Log.xlsx',
    facilityType: ['onshore', 'storage'],
    popularity: 68,
    lastUpdated: '2024-01-03',
    version: {
      version: 1,
      status: 'locked',
      toggles: {
        hasH2S: false,
        hasBenzene: false,
        hasLEL: false,
        hasO2: false,
        isRefill: true,
        is12hr: false,
        isFinal: false,
      },
      gasType: 'methane',
      fields: [
        { id: 'time', key: 'time', label: 'Time', type: 'time', required: true, visible: true },
        { id: 'exhaustTempF', key: 'exhaustTempF', label: 'Exhaust Temperature', type: 'number', unit: '°F', required: true, visible: true, validationRules: { min: 32, max: 2000 } },
        { id: 'vacuumH2O', key: 'vacuumH2O', label: 'Vacuum', type: 'number', unit: 'inH2O', required: true, visible: true, validationRules: { min: 0, max: 30 } },
        { id: 'inletMethanePct', key: 'inletMethanePct', label: 'Inlet Methane', type: 'number', unit: '%', required: true, visible: true, validationRules: { min: 0, max: 100 } },
        { id: 'outletMethanePPM', key: 'outletMethanePPM', label: 'Outlet Methane', type: 'number', unit: 'PPM', required: true, visible: true, validationRules: { min: 0, max: 100000 } },
        { id: 'tankRefillBBLHR', key: 'tankRefillBBLHR', label: 'Tank Refill Rate', type: 'number', unit: 'BBL/HR', required: true, visible: true, validationRules: { min: 0, max: 1000 } },
        { id: 'operatorInitials', key: 'operatorInitials', label: 'Operator Initials', type: 'text', required: true, visible: true },
      ],
      targets: { tankRefillBBLHR: 100 },
      ui: { groups: ['core', 'operations', 'operator'], layout: 'standard' },
      excelTemplatePath: 'library/conocophillips-refill.xlsx',
      operationRange: { start: 'B12', end: 'O28', sheet: 'Sheet1' },
      createdAt: Date.now(),
      createdBy: 'system',
      hash: 'conocophillips-refill-v1',
    },
  },
  {
    id: 'marathon-comprehensive',
    name: 'Marathon Comprehensive Final',
    description: 'Complete monitoring suite with final inspection signatures',
    category: 'safety',
    tags: ['Methane', 'Final', 'H₂S', 'Benzene', 'O₂', 'Comprehensive'],
    gasType: 'methane',
    sourceDocument: 'Marathon_Comprehensive_Final_Log.xlsx',
    facilityType: ['offshore', 'platform'],
    popularity: 92,
    lastUpdated: '2024-01-14',
    version: {
      version: 1,
      status: 'locked',
      toggles: {
        hasH2S: true,
        hasBenzene: true,
        hasLEL: false,
        hasO2: true,
        isRefill: false,
        is12hr: false,
        isFinal: true,
      },
      gasType: 'methane',
      fields: [
        { id: 'time', key: 'time', label: 'Time', type: 'time', required: true, visible: true },
        { id: 'exhaustTempF', key: 'exhaustTempF', label: 'Exhaust Temperature', type: 'number', unit: '°F', required: true, visible: true, validationRules: { min: 32, max: 2000 } },
        { id: 'vacuumH2O', key: 'vacuumH2O', label: 'Vacuum', type: 'number', unit: 'inH2O', required: true, visible: true, validationRules: { min: 0, max: 30 } },
        { id: 'inletMethanePct', key: 'inletMethanePct', label: 'Inlet Methane', type: 'number', unit: '%', required: true, visible: true, validationRules: { min: 0, max: 100 } },
        { id: 'outletMethanePPM', key: 'outletMethanePPM', label: 'Outlet Methane', type: 'number', unit: 'PPM', required: true, visible: true, validationRules: { min: 0, max: 100000 } },
        { id: 'h2sPPM', key: 'h2sPPM', label: 'H₂S Level', type: 'number', unit: 'PPM', required: true, visible: true, validationRules: { min: 0, max: 1000 } },
        { id: 'benzenePPM', key: 'benzenePPM', label: 'Benzene Level', type: 'number', unit: 'PPM', required: true, visible: true, validationRules: { min: 0, max: 1000 } },
        { id: 'oxygenPct', key: 'oxygenPct', label: 'Oxygen Level', type: 'number', unit: '%', required: true, visible: true, validationRules: { min: 0, max: 25 } },
        { id: 'operatorInitials', key: 'operatorInitials', label: 'Operator Initials', type: 'text', required: true, visible: true },
        { id: 'supervisorSignature', key: 'supervisorSignature', label: 'Supervisor Signature', type: 'text', required: true, visible: true },
      ],
      targets: { h2sPPM: 10, benzenePPM: 1, oxygenPct: 19.5 },
      ui: { groups: ['core', 'safety', 'environmental', 'operator'], layout: 'comprehensive' },
      excelTemplatePath: 'library/marathon-comprehensive.xlsx',
      operationRange: { start: 'B12', end: 'R28', sheet: 'Sheet1' },
      createdAt: Date.now(),
      createdBy: 'system',
      hash: 'marathon-comprehensive-v1',
    },
  },
];

// Enhanced facility presets with template suggestions
export interface EnhancedFacilityPreset {
  id: string;
  name: string;
  facilityId: string;
  facilityType: string;
  gasType: 'methane' | 'pentane';
  toggles: Toggles;
  targets: Targets;
  suggestedTemplates: string[]; // Library template IDs
  description: string;
  createdAt: number;
  createdBy: string;
}

export const ENHANCED_FACILITY_PRESETS: EnhancedFacilityPreset[] = [
  {
    id: 'marathon-gbr-preset',
    name: 'Marathon GBR Standard',
    facilityId: 'marathon-gbr',
    facilityType: 'offshore-platform',
    gasType: 'methane',
    toggles: {
      hasH2S: false,
      hasBenzene: false,
      hasLEL: false,
      hasO2: false,
      isRefill: false,
      is12hr: false,
      isFinal: false,
    },
    targets: {},
    suggestedTemplates: ['marathon-gbr-standard', 'marathon-comprehensive'],
    description: 'Standard configuration for Marathon GBR platform operations',
    createdAt: Date.now(),
    createdBy: 'system',
  },
  {
    id: 'shell-perdido-preset',
    name: 'Shell Perdido H₂S Enhanced',
    facilityId: 'shell-perdido',
    facilityType: 'offshore-platform',
    gasType: 'methane',
    toggles: {
      hasH2S: true,
      hasBenzene: false,
      hasLEL: false,
      hasO2: false,
      isRefill: false,
      is12hr: false,
      isFinal: false,
    },
    targets: { h2sPPM: 10 },
    suggestedTemplates: ['shell-perdido-h2s', 'marathon-comprehensive'],
    description: 'H₂S monitoring for Shell Perdido platform with safety thresholds',
    createdAt: Date.now(),
    createdBy: 'system',
  },
  {
    id: 'chevron-refinery-preset',
    name: 'Chevron Refinery LEL',
    facilityId: 'chevron-refinery',
    facilityType: 'onshore-refinery',
    gasType: 'pentane',
    toggles: {
      hasH2S: false,
      hasBenzene: false,
      hasLEL: true,
      hasO2: false,
      isRefill: false,
      is12hr: false,
      isFinal: false,
    },
    targets: { lelPct: 10 },
    suggestedTemplates: ['chevron-pentane-lel'],
    description: 'Pentane vapor monitoring with LEL safety controls for refinery operations',
    createdAt: Date.now(),
    createdBy: 'system',
  },
  {
    id: 'comprehensive-safety-preset',
    name: 'Comprehensive Safety Monitor',
    facilityId: 'any',
    facilityType: 'any',
    gasType: 'methane',
    toggles: {
      hasH2S: true,
      hasBenzene: true,
      hasLEL: false,
      hasO2: true,
      isRefill: false,
      is12hr: false,
      isFinal: true,
    },
    targets: { h2sPPM: 10, benzenePPM: 1, oxygenPct: 19.5 },
    suggestedTemplates: ['marathon-comprehensive'],
    description: 'Complete safety monitoring suite with all environmental parameters',
    createdAt: Date.now(),
    createdBy: 'system',
  },
];

// Tag definitions for filtering
export const TEMPLATE_TAGS = [
  { id: 'methane', label: 'Methane', color: 'blue', category: 'gas-type' },
  { id: 'pentane', label: 'Pentane', color: 'purple', category: 'gas-type' },
  { id: 'hourly', label: 'Hourly', color: 'green', category: 'frequency' },
  { id: '12-hr', label: '12-Hour', color: 'yellow', category: 'frequency' },
  { id: 'h2s', label: 'H₂S', color: 'red', category: 'safety' },
  { id: 'benzene', label: 'Benzene', color: 'orange', category: 'environmental' },
  { id: 'lel', label: 'LEL', color: 'red', category: 'safety' },
  { id: 'o2', label: 'O₂', color: 'cyan', category: 'monitoring' },
  { id: 'refill', label: 'Refill', color: 'indigo', category: 'operations' },
  { id: 'final', label: 'Final', color: 'gray', category: 'approval' },
  { id: 'platform', label: 'Platform', color: 'blue', category: 'facility' },
  { id: 'refinery', label: 'Refinery', color: 'orange', category: 'facility' },
  { id: 'storage', label: 'Storage', color: 'green', category: 'facility' },
];

export function getTemplatesByTags(tags: string[]): LibraryTemplate[] {
  if (tags.length === 0) return LIBRARY_TEMPLATES;
  
  return LIBRARY_TEMPLATES.filter(template =>
    tags.every(tag => 
      template.tags.some(templateTag => 
        templateTag.toLowerCase().includes(tag.toLowerCase())
      )
    )
  );
}

export function getTemplatesByCategory(category: string): LibraryTemplate[] {
  return LIBRARY_TEMPLATES.filter(template => template.category === category);
}

export function getTemplatesByGasType(gasType: 'methane' | 'pentane'): LibraryTemplate[] {
  return LIBRARY_TEMPLATES.filter(template => template.gasType === gasType);
}

export function searchTemplates(query: string): LibraryTemplate[] {
  const lowercaseQuery = query.toLowerCase();
  return LIBRARY_TEMPLATES.filter(template =>
    template.name.toLowerCase().includes(lowercaseQuery) ||
    template.description.toLowerCase().includes(lowercaseQuery) ||
    template.tags.some(tag => tag.toLowerCase().includes(lowercaseQuery)) ||
    template.sourceDocument.toLowerCase().includes(lowercaseQuery)
  );
}