import { Timestamp } from 'firebase/firestore';

export type LogFieldType = "text" | "number" | "select" | "checkbox";

export interface LogField {
  id: string;               // stable UUID within template
  key: string;              // Firestore field name operators write to
  label: string;
  type: LogFieldType;
  unit?: string;
  required?: boolean;
  defaultValue?: any;
  validation?: { 
    min?: number; 
    max?: number; 
    pattern?: string;
    maxLength?: number;
  };
  options?: { label: string; value: string }[];
  visibility?: {
    defaultHidden?: boolean;     // hidden unless expanded
    condition?: string;          // future rule expression
  };
}

export interface LogLayoutRow { 
  id: string;
  columns: { 
    fieldId: string; 
    width?: number;  // 1-12 grid units
  }[]; 
}

export interface LogSection { 
  id: string; 
  title?: string; 
  rows: LogLayoutRow[]; 
}

export interface LogSchema {
  fields: LogField[];       // palette used by this template
  layout: LogSection[];     // sections/rows/columns
  meta?: { 
    description?: string;
    hourFormat?: '24h' | '12h';
  };
}

export interface LogTemplate {
  id: string;
  name: string;
  logType: string;              // "methane_hourly" | "benzene_12hr" | "custom" | etc.
  status: "draft" | "published" | "archived";
  latestVersion: number;
  createdBy: string;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  draftSchema: LogSchema;
}

export interface LogTemplateVersion {
  id: string;
  templateId: string;
  version: number;
  schema: LogSchema;
  previewConfig?: {
    mockData?: Record<string, any>;
    theme?: 'light' | 'dark';
  };
  changelog: string;
  createdBy: string;
  createdAt: Timestamp;
}

export interface VariableCatalog {
  id: string;
  key: string;                     // Firestore field key (e.g., "exhaustTempF")
  label: string;                   // UI label
  type: LogFieldType;
  unit?: string;
  options?: {label: string; value: string}[];
  validation?: { 
    min?: number; 
    max?: number; 
    pattern?: string;
    maxLength?: number;
  };
  notes?: string;
  category?: string;               // for grouping in palette
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

export interface ProjectAssignment {
  projectId: string;
  assignedTemplateId?: string;
  assignedVersion?: number;
  assignedAt?: Timestamp;
  assignedBy?: string;
  usedTemplates: Array<{
    templateId: string;
    templateName: string;
    version: number;
    assignedAt: Timestamp;
    assignedBy: string;
  }>;
}

// Drag and drop types
export interface DragItem {
  type: 'variable' | 'field' | 'section' | 'row';
  id: string;
  data?: any;
}

export interface DropResult {
  dragItem: DragItem;
  dropZone: {
    type: 'canvas' | 'section' | 'row' | 'palette';
    id?: string;
    position?: number;
  };
}

// Schema diff types
export interface SchemaDiff {
  fieldsAdded: LogField[];
  fieldsRemoved: LogField[];
  fieldsModified: Array<{
    id: string;
    changes: Partial<LogField>;
  }>;
  layoutChanges: {
    sectionsAdded: LogSection[];
    sectionsRemoved: LogSection[];
    sectionsModified: Array<{
      id: string;
      changes: any;
    }>;
  };
}

// Export types
export interface ExportConfig {
  format: 'excel' | 'csv' | 'json';
  includeMetadata?: boolean;
  dateRange?: {
    start: Date;
    end: Date;
  };
  fieldMapping?: Record<string, string>;
}

export interface ExportResult {
  success: boolean;
  filePath?: string;
  fileName?: string;
  data?: any;
  error?: string;
}

// Validation types
export interface ValidationError {
  field: string;
  hour?: number;
  message: string;
  severity: 'error' | 'warning';
}

export interface ValidationResult {
  isValid: boolean;
  errors: ValidationError[];
  warnings: ValidationError[];
}

// Preview types
export interface OperatorPreviewConfig {
  showKeys: boolean;
  selectedHour: number;
  expandMoreFields: boolean;
  theme: 'light' | 'dark';
  mockData?: Record<string, any>;
}

// Bulk operations
export interface BulkOperation {
  type: 'clone' | 'validate' | 'delete' | 'update';
  hourRange: {
    start: number;
    end: number;
  };
  sourceHour?: number;
  fields?: Partial<Record<string, any>>;
}

export interface BulkOperationResult {
  success: boolean;
  affectedHours: number[];
  errors: ValidationError[];
}