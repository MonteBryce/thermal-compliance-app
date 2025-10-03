import { z } from 'zod';
import { Timestamp } from 'firebase/firestore';

export const FieldRuleSchema = z.object({
  min: z.number().optional(),
  max: z.number().optional(),
  precision: z.number().optional(),
  maxLength: z.number().optional()
});

export const FieldTypeSchema = z.enum(['number', 'text', 'boolean', 'hour', 'computed']);

export const FieldSchema = z.object({
  id: z.string(),
  label: z.string(),
  type: FieldTypeSchema,
  unit: z.string().optional(),
  required: z.boolean().default(false),
  visible: z.boolean().default(true),
  rules: FieldRuleSchema.optional(),
  excelKey: z.string().optional(),
  compute: z.string().optional()
});

export const RangeSchema = z.object({
  sheet: z.string(),
  start: z.string(),
  end: z.string(),
  role: z.enum(['operation', 'readonly'])
});

export const LogTemplateSchema = z.object({
  key: z.string(),
  title: z.string(),
  frequency: z.literal('hourly'),
  version: z.number(),
  status: z.enum(['draft', 'published']),
  fields: z.array(FieldSchema),
  editableAreas: z.array(RangeSchema),
  sourceXlsxPath: z.string(),
  createdBy: z.string().optional(),
  updatedBy: z.string().optional(),
  updatedAt: z.number().optional()
});

export type FieldRule = z.infer<typeof FieldRuleSchema>;
export type FieldType = z.infer<typeof FieldTypeSchema>;
export type Field = z.infer<typeof FieldSchema>;
export type Range = z.infer<typeof RangeSchema>;
export type LogTemplate = z.infer<typeof LogTemplateSchema>;

export interface LogTemplateFirestore extends Omit<LogTemplate, 'updatedAt'> {
  updatedAt?: Timestamp;
}

export interface LogTemplateHistory {
  templateId: string;
  version: number;
  template: LogTemplate;
  publishedAt: Timestamp;
  publishedBy: string;
}

export interface ProjectMetadata {
  logType: string;
  updatedBy: string;
  updatedAt: Timestamp;
}

export interface LogTypeHistory {
  from: { logType: string } | null;
  to: { logType: string };
  reason?: string;
  userId: string;
  ts: Timestamp;
}

export interface ValidationIssue {
  field: string;
  type: 'missing' | 'extra' | 'renamed' | 'orderMismatch';
  expected?: string;
  actual?: string;
  suggestion?: string;
}

export interface ValidationResult {
  valid: boolean;
  issues: ValidationIssue[];
  autoFixAvailable: boolean;
  suggestedFields?: Field[];
}

export interface ExcelPreviewData {
  html: string;
  css?: string;
  operationRange?: Range;
  mergedCells?: Array<{
    s: { r: number; c: number };
    e: { r: number; c: number };
  }>;
}

export interface DragDropItem {
  id: string;
  field: Field;
  sourceIndex: number;
  sourceType: 'palette' | 'operation';
}

export interface EditableFieldAction {
  type: 'toggle_visibility' | 'toggle_required' | 'edit_label' | 'edit_unit' | 'add_custom' | 'remove' | 'reorder';
  fieldId?: string;
  payload?: any;
}

export const MANDATORY_FIELDS = ['hour', 'exhaust_temp_f', 'outlet_h2s_ppm', 'totalizer_scf'];

export function isMandatoryField(excelKey?: string): boolean {
  return excelKey ? MANDATORY_FIELDS.includes(excelKey.toLowerCase()) : false;
}

export function validateTemplate(template: unknown): LogTemplate {
  return LogTemplateSchema.parse(template);
}

export function createEmptyTemplate(): LogTemplate {
  return {
    key: '',
    title: '',
    frequency: 'hourly',
    version: 0,
    status: 'draft',
    fields: [],
    editableAreas: [],
    sourceXlsxPath: ''
  };
}