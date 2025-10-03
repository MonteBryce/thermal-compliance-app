import { z } from 'zod';
import { Timestamp, DocumentReference } from 'firebase/firestore';

// Core field specification
export const FieldSpecSchema = z.object({
  key: z.string(),
  label: z.string(),
  type: z.enum(['number', 'text', 'select', 'time']),
  required: z.boolean().optional(),
  unit: z.string().optional(),
  showIf: z.object({
    gasType: z.enum(['methane', 'pentane']).optional(),
    flags: z.array(z.string()).optional(),
  }).optional(),
  validationRules: z.object({
    min: z.number().optional(),
    max: z.number().optional(),
    options: z.array(z.string()).optional(),
  }).optional(),
});

export type FieldSpec = z.infer<typeof FieldSpecSchema>;

// Toggle configuration
export const TogglesSchema = z.object({
  hasH2S: z.boolean().default(false),
  hasBenzene: z.boolean().default(false),
  hasLEL: z.boolean().default(false),
  hasO2: z.boolean().default(false),
  isRefill: z.boolean().default(false),
  is12hr: z.boolean().default(false),
  isFinal: z.boolean().default(false),
});

export type Toggles = z.infer<typeof TogglesSchema>;

// Targets and thresholds
export const TargetsSchema = z.object({
  h2sPPM: z.number().optional(),
  benzenePPM: z.number().optional(),
  lelPct: z.number().optional(),
  oxygenPct: z.number().optional(),
  tankRefillBBLHR: z.number().optional(),
});

export type Targets = z.infer<typeof TargetsSchema>;

// Operation range in Excel
export const OperationRangeSchema = z.object({
  start: z.string(), // e.g., 'B12'
  end: z.string(),   // e.g., 'N28'
  sheet: z.string().default('Sheet1'),
});

export type OperationRange = z.infer<typeof OperationRangeSchema>;

// UI configuration
export const UIConfigSchema = z.object({
  groups: z.array(z.string()),
  columnHints: z.record(z.string()).optional(),
  layout: z.enum(['standard', 'compact', 'extended']).default('standard'),
});

export type UIConfig = z.infer<typeof UIConfigSchema>;

// Template version (immutable once published)
export const TemplateVersionSchema = z.object({
  version: z.number(),
  status: z.enum(['draft', 'active', 'deprecated', 'locked', 'canary']),
  toggles: TogglesSchema,
  gasType: z.enum(['methane', 'pentane']),
  fields: z.array(FieldSpecSchema),
  targets: TargetsSchema,
  ui: UIConfigSchema,
  excelTemplatePath: z.string(),
  operationRange: OperationRangeSchema,
  derivedFromVersion: z.number().optional(),
  createdAt: z.union([z.number(), z.instanceof(Timestamp)]),
  createdBy: z.string(),
  changelog: z.string().optional(),
  hash: z.string(), // For integrity checking
});

export type TemplateVersion = z.infer<typeof TemplateVersionSchema>;

// Template metadata (mutable container)
export const LogTemplateSchema = z.object({
  id: z.string().optional(),
  name: z.string(),
  templateKey: z.string(), // e.g., 'methane_hourly'
  gasFamily: z.enum(['methane', 'pentane']),
  activeVersionRef: z.string().optional(), // Reference to versions/{versionId}
  createdAt: z.union([z.number(), z.instanceof(Timestamp)]),
  createdBy: z.string(),
  facilityDefaults: z.record(z.object({
    toggles: TogglesSchema,
    targets: TargetsSchema,
    name: z.string(),
  })).optional(),
});

export type LogTemplate = z.infer<typeof LogTemplateSchema>;

// Template snapshot for job pinning
export const TemplateSnapshotSchema = z.object({
  version: z.number(),
  toggles: TogglesSchema,
  gasType: z.enum(['methane', 'pentane']),
  hourlyColumns: z.array(z.string()),
  targets: TargetsSchema,
  hash: z.string(),
  templateKey: z.string(),
});

export type TemplateSnapshot = z.infer<typeof TemplateSnapshotSchema>;

// Facility preset
export const FacilityPresetSchema = z.object({
  id: z.string().optional(),
  name: z.string(),
  facilityId: z.string(),
  toggles: TogglesSchema,
  targets: TargetsSchema,
  gasType: z.enum(['methane', 'pentane']),
  createdAt: z.union([z.number(), z.instanceof(Timestamp)]),
  createdBy: z.string(),
});

export type FacilityPreset = z.infer<typeof FacilityPresetSchema>;

// Version diff for comparison
export interface VersionDiff {
  fieldsAdded: FieldSpec[];
  fieldsRemoved: FieldSpec[];
  fieldsModified: Array<{
    field: FieldSpec;
    changes: Record<string, { from: any; to: any }>;
  }>;
  togglesChanged: Record<string, { from: boolean; to: boolean }>;
  targetsChanged: Record<string, { from: number; to: number }>;
}

// Master field definitions
export const MASTER_FIELDS: FieldSpec[] = [
  // Required core fields
  {
    key: 'exhaustTempF',
    label: 'Exhaust Temperature',
    type: 'number',
    unit: '°F',
    required: true,
    validationRules: { min: 32, max: 2000 }
  },
  {
    key: 'vacuumH2O',
    label: 'Vacuum',
    type: 'number',
    unit: 'inH2O',
    required: true,
    validationRules: { min: 0, max: 30 }
  },
  
  // Air flow measurements
  {
    key: 'vaporInletFPM',
    label: 'Vapor Inlet',
    type: 'number',
    unit: 'FPM',
    validationRules: { min: 0, max: 10000 }
  },
  {
    key: 'combustionAirFPM',
    label: 'Combustion Air',
    type: 'number',
    unit: 'FPM',
    validationRules: { min: 0, max: 10000 }
  },
  
  // Gas-specific inlet measurements
  {
    key: 'inletMethanePct',
    label: 'Inlet Methane',
    type: 'number',
    unit: '%',
    showIf: { gasType: 'methane' },
    validationRules: { min: 0, max: 100 }
  },
  {
    key: 'inletPentanePPM',
    label: 'Inlet Pentane',
    type: 'number',
    unit: 'PPM',
    showIf: { gasType: 'pentane' },
    validationRules: { min: 0, max: 100000 }
  },
  
  // Gas-specific outlet measurements
  {
    key: 'outletMethanePPM',
    label: 'Outlet Methane',
    type: 'number',
    unit: 'PPM',
    showIf: { gasType: 'methane' },
    validationRules: { min: 0, max: 100000 }
  },
  {
    key: 'outletPentanePPM',
    label: 'Outlet Pentane',
    type: 'number',
    unit: 'PPM',
    showIf: { gasType: 'pentane' },
    validationRules: { min: 0, max: 100000 }
  },
  
  // Optional flag-dependent fields
  {
    key: 'inletLEL',
    label: 'Inlet LEL',
    type: 'number',
    unit: '%',
    showIf: { flags: ['hasLEL'] },
    validationRules: { min: 0, max: 100 }
  },
  {
    key: 'benzenePPM',
    label: 'Benzene',
    type: 'number',
    unit: 'PPM',
    showIf: { flags: ['hasBenzene'] },
    validationRules: { min: 0, max: 1000 }
  },
  {
    key: 'h2sPPM',
    label: 'H₂S',
    type: 'number',
    unit: 'PPM',
    showIf: { flags: ['hasH2S'] },
    validationRules: { min: 0, max: 1000 }
  },
  {
    key: 'oxygenPct',
    label: 'Oxygen',
    type: 'number',
    unit: '%',
    showIf: { flags: ['hasO2'] },
    validationRules: { min: 0, max: 25 }
  },
  {
    key: 'tankRefillBBLHR',
    label: 'Tank Refill Rate',
    type: 'number',
    unit: 'BBL/HR',
    showIf: { flags: ['isRefill'] },
    validationRules: { min: 0, max: 1000 }
  },
  
  // Operator fields
  {
    key: 'operatorInitials',
    label: 'Operator Initials',
    type: 'text',
    required: true,
    validationRules: { options: ['JD', 'MB', 'RS', 'TK', 'AL'] }
  },
  {
    key: 'inspectionTime',
    label: 'Inspection Time',
    type: 'time',
    required: true
  },
  {
    key: 'totalizer',
    label: 'Totalizer Reading',
    type: 'number',
    unit: 'MCF'
  },
  {
    key: 'generatorHours',
    label: 'Generator Hours',
    type: 'number',
    unit: 'hrs'
  },
  {
    key: 'fuelUsage',
    label: 'Fuel Usage',
    type: 'number',
    unit: 'gal'
  },
  {
    key: 'startTime',
    label: 'Start Time',
    type: 'time',
    showIf: { flags: ['is12hr'] }
  },
  {
    key: 'stopTime',
    label: 'Stop Time',
    type: 'time',
    showIf: { flags: ['is12hr'] }
  },
  {
    key: 'supervisorSignature',
    label: 'Supervisor Signature',
    type: 'text',
    showIf: { flags: ['isFinal'] }
  }
];

// Utility functions
export function filterFieldsByConditions(
  fields: FieldSpec[],
  gasType: 'methane' | 'pentane',
  toggles: Toggles
): FieldSpec[] {
  return fields.filter(field => {
    if (field.showIf?.gasType && field.showIf.gasType !== gasType) {
      return false;
    }
    
    if (field.showIf?.flags) {
      return field.showIf.flags.some(flag => toggles[flag as keyof Toggles]);
    }
    
    return true;
  });
}

export function generateTemplateHash(version: Omit<TemplateVersion, 'hash'>): string {
  const hashContent = {
    version: version.version,
    toggles: version.toggles,
    gasType: version.gasType,
    fields: version.fields.map(f => ({ key: f.key, label: f.label, type: f.type, unit: f.unit })),
    targets: version.targets,
  };
  
  // Simple hash function - in production use crypto.subtle or similar
  const str = JSON.stringify(hashContent);
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash; // Convert to 32-bit integer
  }
  return Math.abs(hash).toString(16);
}

export function computeVersionDiff(
  oldVersion: TemplateVersion,
  newVersion: TemplateVersion
): VersionDiff {
  const oldFieldKeys = new Set(oldVersion.fields.map(f => f.key));
  const newFieldKeys = new Set(newVersion.fields.map(f => f.key));
  
  const fieldsAdded = newVersion.fields.filter(f => !oldFieldKeys.has(f.key));
  const fieldsRemoved = oldVersion.fields.filter(f => !newFieldKeys.has(f.key));
  
  const fieldsModified: VersionDiff['fieldsModified'] = [];
  for (const newField of newVersion.fields) {
    const oldField = oldVersion.fields.find(f => f.key === newField.key);
    if (oldField) {
      const changes: Record<string, { from: any; to: any }> = {};
      
      if (oldField.label !== newField.label) {
        changes.label = { from: oldField.label, to: newField.label };
      }
      if (oldField.unit !== newField.unit) {
        changes.unit = { from: oldField.unit, to: newField.unit };
      }
      if (oldField.required !== newField.required) {
        changes.required = { from: oldField.required, to: newField.required };
      }
      
      if (Object.keys(changes).length > 0) {
        fieldsModified.push({ field: newField, changes });
      }
    }
  }
  
  const togglesChanged: Record<string, { from: boolean; to: boolean }> = {};
  for (const [key, newValue] of Object.entries(newVersion.toggles)) {
    const oldValue = oldVersion.toggles[key as keyof Toggles];
    if (oldValue !== newValue) {
      togglesChanged[key] = { from: oldValue, to: newValue };
    }
  }
  
  const targetsChanged: Record<string, { from: number; to: number }> = {};
  for (const [key, newValue] of Object.entries(newVersion.targets)) {
    const oldValue = oldVersion.targets[key as keyof Targets];
    if (oldValue !== newValue && newValue !== undefined && oldValue !== undefined) {
      targetsChanged[key] = { from: oldValue, to: newValue };
    }
  }
  
  return {
    fieldsAdded,
    fieldsRemoved,
    fieldsModified,
    togglesChanged,
    targetsChanged,
  };
}