import { z } from 'zod';

/**
 * Schema for Methane Hourly Log Type
 * Used for degassing operations monitoring methane levels
 */

// Base reading schema for a single measurement
export const MethaneReadingSchema = z.object({
  timestamp: z.string().datetime(),
  value: z.number()
    .min(0, 'Methane reading cannot be negative')
    .max(100, 'Methane percentage cannot exceed 100%'),
  unit: z.literal('%LEL'), // Lower Explosive Limit percentage
  location: z.string().min(1, 'Location is required'),
  operator: z.string().min(1, 'Operator name is required'),
  deviceId: z.string().optional(),
  notes: z.string().optional(),
});

// Schema for an hourly entry (can have multiple readings)
export const MethaneHourlyEntrySchema = z.object({
  hourId: z.string().regex(/^(0[0-9]|1[0-9]|2[0-3])$/, 'Hour must be 00-23'),
  projectId: z.string().min(1),
  date: z.string().regex(/^\d{8}$/, 'Date must be YYYYMMDD format'),
  
  // Readings for this hour
  readings: z.array(MethaneReadingSchema).min(1, 'At least one reading per hour required'),
  
  // Computed fields
  avgValue: z.number().optional(), // Average of all readings
  maxValue: z.number().optional(), // Maximum reading
  minValue: z.number().optional(), // Minimum reading
  
  // Compliance fields
  exceedanceCount: z.number().int().min(0).default(0), // Times over threshold
  threshold: z.number().default(25), // %LEL threshold
  status: z.enum(['pass', 'fail', 'warning']).optional(),
  
  // Metadata
  enteredAt: z.string().datetime(),
  enteredBy: z.string(),
  modifiedAt: z.string().datetime().optional(),
  modifiedBy: z.string().optional(),
  
  // Validation
  validated: z.boolean().default(false),
  validatedAt: z.string().datetime().optional(),
  validatedBy: z.string().optional(),
  validationNotes: z.string().optional(),
});

// Schema for a full day's log
export const MethaneDailyLogSchema = z.object({
  projectId: z.string().min(1),
  date: z.string().regex(/^\d{8}$/, 'Date must be YYYYMMDD format'),
  logType: z.literal('methane_hourly'),
  
  // All hourly entries for the day
  entries: z.record(
    z.string().regex(/^(0[0-9]|1[0-9]|2[0-3])$/),
    MethaneHourlyEntrySchema
  ),
  
  // Daily summary
  summary: z.object({
    totalReadings: z.number().int().min(0),
    avgDailyValue: z.number().min(0).max(100),
    maxDailyValue: z.number().min(0).max(100),
    minDailyValue: z.number().min(0).max(100),
    hoursWithData: z.number().int().min(0).max(24),
    hoursAboveThreshold: z.number().int().min(0).max(24),
    complianceStatus: z.enum(['pass', 'fail', 'warning']),
  }).optional(),
  
  // Metadata
  createdAt: z.string().datetime(),
  updatedAt: z.string().datetime(),
  exportedAt: z.string().datetime().optional(),
  exportedBy: z.string().optional(),
});

// Excel template configuration for methane_hourly
export const MethaneHourlyExcelConfig = {
  templateName: 'methane_hourly_template.xlsx',
  worksheetName: 'Methane Log',
  
  // Column mappings (Excel column -> data field)
  columnMappings: {
    'A': 'date',
    'B': 'hourId',
    'C': 'location',
    'D': 'value',
    'E': 'unit',
    'F': 'operator',
    'G': 'status',
    'H': 'notes',
  },
  
  // Columns to show/hide based on requirements
  visibleColumns: ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'],
  
  // Summary section cells
  summaryMappings: {
    'J2': 'projectId',
    'J3': 'date',
    'J4': 'avgDailyValue',
    'J5': 'maxDailyValue',
    'J6': 'minDailyValue',
    'J7': 'hoursWithData',
    'J8': 'complianceStatus',
  },
  
  // Conditional formatting rules
  conditionalFormatting: [
    {
      range: 'D:D',
      type: 'cell',
      operator: 'greaterThan',
      value: 25,
      style: { fill: { bgColor: { argb: 'FFFF0000' } } }, // Red background
    },
    {
      range: 'G:G',
      type: 'cell',
      operator: 'equal',
      value: 'fail',
      style: { font: { color: { argb: 'FFFF0000' }, bold: true } }, // Red text
    },
  ],
  
  // Data validation rules
  dataValidation: {
    'E': {
      type: 'list',
      allowBlank: false,
      formulae: ['"% LEL"'],
    },
    'G': {
      type: 'list',
      allowBlank: false,
      formulae: ['"pass,fail,warning"'],
    },
  },
  
  // Starting row for data (after headers)
  dataStartRow: 2,
  
  // Formulas for calculated cells
  formulas: {
    'J4': 'AVERAGE(D:D)', // Average daily value
    'J5': 'MAX(D:D)',     // Max daily value
    'J6': 'MIN(D:D)',     // Min daily value
    'J7': 'COUNTA(B:B)-1', // Hours with data (minus header)
  },
};

// Type exports
export type MethaneReading = z.infer<typeof MethaneReadingSchema>;
export type MethaneHourlyEntry = z.infer<typeof MethaneHourlyEntrySchema>;
export type MethaneDailyLog = z.infer<typeof MethaneDailyLogSchema>;