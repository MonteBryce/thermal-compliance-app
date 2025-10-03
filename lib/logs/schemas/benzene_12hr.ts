import { z } from 'zod';

/**
 * Schema for Benzene 12-Hour Log Type
 * Used for monitoring benzene exposure over 12-hour shifts
 */

// Base reading schema for benzene measurement
export const BenzeneReadingSchema = z.object({
  timestamp: z.string().datetime(),
  value: z.number()
    .min(0, 'Benzene reading cannot be negative')
    .max(1000, 'Benzene reading exceeds maximum expected value'),
  unit: z.enum(['ppm', 'ppb']), // Parts per million or billion
  location: z.string().min(1, 'Location is required'),
  samplingMethod: z.enum(['personal', 'area', 'continuous']),
  operator: z.string().min(1, 'Operator name is required'),
  deviceId: z.string().optional(),
  temperature: z.number().optional(), // Celsius
  humidity: z.number().min(0).max(100).optional(), // Percentage
  windSpeed: z.number().min(0).optional(), // m/s
  windDirection: z.string().optional(),
  notes: z.string().optional(),
});

// Schema for a 12-hour shift entry
export const Benzene12HrEntrySchema = z.object({
  shiftId: z.enum(['day', 'night']), // Day shift (06:00-18:00) or Night (18:00-06:00)
  projectId: z.string().min(1),
  date: z.string().regex(/^\d{8}$/, 'Date must be YYYYMMDD format'),
  
  // Start and end times for the shift
  shiftStart: z.string().datetime(),
  shiftEnd: z.string().datetime(),
  
  // Readings during this shift
  readings: z.array(BenzeneReadingSchema).min(1, 'At least one reading per shift required'),
  
  // Time-weighted average calculations
  twa8hr: z.number().optional(), // 8-hour TWA
  twa12hr: z.number().optional(), // 12-hour TWA
  stel: z.number().optional(), // Short-term exposure limit (15-min)
  peak: z.number().optional(), // Peak reading
  
  // Compliance thresholds
  actionLevel: z.number().default(0.5), // ppm
  pel: z.number().default(1.0), // Permissible Exposure Limit in ppm
  stelLimit: z.number().default(5.0), // STEL limit in ppm
  
  // Compliance status
  exceedances: z.object({
    actionLevel: z.boolean().default(false),
    pel: z.boolean().default(false),
    stel: z.boolean().default(false),
  }),
  status: z.enum(['pass', 'fail', 'warning']).optional(),
  
  // PPE and controls
  ppeUsed: z.array(z.string()).optional(),
  engineeringControls: z.array(z.string()).optional(),
  
  // Metadata
  enteredAt: z.string().datetime(),
  enteredBy: z.string(),
  reviewedAt: z.string().datetime().optional(),
  reviewedBy: z.string().optional(),
  approvedAt: z.string().datetime().optional(),
  approvedBy: z.string().optional(),
});

// Schema for a full day's benzene log (2 shifts)
export const BenzeneDailyLogSchema = z.object({
  projectId: z.string().min(1),
  date: z.string().regex(/^\d{8}$/, 'Date must be YYYYMMDD format'),
  logType: z.literal('benzene_12hr'),
  
  // Shift entries
  dayShift: Benzene12HrEntrySchema.optional(),
  nightShift: Benzene12HrEntrySchema.optional(),
  
  // Daily summary
  summary: z.object({
    totalReadings: z.number().int().min(0),
    avgDailyValue: z.number().min(0),
    maxDailyValue: z.number().min(0),
    minDailyValue: z.number().min(0),
    shiftsWithData: z.number().int().min(0).max(2),
    actionLevelExceedances: z.number().int().min(0),
    pelExceedances: z.number().int().min(0),
    stelExceedances: z.number().int().min(0),
    complianceStatus: z.enum(['pass', 'fail', 'warning']),
    requiresFollowUp: z.boolean().default(false),
  }).optional(),
  
  // Metadata
  createdAt: z.string().datetime(),
  updatedAt: z.string().datetime(),
  exportedAt: z.string().datetime().optional(),
  exportedBy: z.string().optional(),
});

// Excel template configuration for benzene_12hr
export const Benzene12HrExcelConfig = {
  templateName: 'benzene_12hr_template.xlsx',
  worksheetName: 'Benzene Log',
  
  // Column mappings (Excel column -> data field)
  columnMappings: {
    'A': 'date',
    'B': 'shiftId',
    'C': 'shiftStart',
    'D': 'shiftEnd',
    'E': 'location',
    'F': 'value',
    'G': 'unit',
    'H': 'samplingMethod',
    'I': 'twa8hr',
    'J': 'twa12hr',
    'K': 'stel',
    'L': 'peak',
    'M': 'operator',
    'N': 'temperature',
    'O': 'humidity',
    'P': 'windSpeed',
    'Q': 'windDirection',
    'R': 'ppeUsed',
    'S': 'status',
    'T': 'notes',
  },
  
  // Columns to show/hide based on requirements
  visibleColumns: ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'S', 'T'],
  
  // Summary section cells
  summaryMappings: {
    'V2': 'projectId',
    'V3': 'date',
    'V4': 'avgDailyValue',
    'V5': 'maxDailyValue',
    'V6': 'minDailyValue',
    'V7': 'actionLevelExceedances',
    'V8': 'pelExceedances',
    'V9': 'stelExceedances',
    'V10': 'complianceStatus',
    'V11': 'requiresFollowUp',
  },
  
  // Conditional formatting rules
  conditionalFormatting: [
    {
      range: 'I:I', // TWA 8hr column
      type: 'cell',
      operator: 'greaterThan',
      value: 0.5, // Action level
      style: { fill: { bgColor: { argb: 'FFFFFF00' } } }, // Yellow background
    },
    {
      range: 'I:I', // TWA 8hr column
      type: 'cell',
      operator: 'greaterThan',
      value: 1.0, // PEL
      style: { fill: { bgColor: { argb: 'FFFF0000' } } }, // Red background
    },
    {
      range: 'K:K', // STEL column
      type: 'cell',
      operator: 'greaterThan',
      value: 5.0,
      style: { fill: { bgColor: { argb: 'FFFF0000' } } }, // Red background
    },
    {
      range: 'S:S', // Status column
      type: 'cell',
      operator: 'equal',
      value: 'fail',
      style: { font: { color: { argb: 'FFFF0000' }, bold: true } }, // Red text
    },
  ],
  
  // Data validation rules
  dataValidation: {
    'B': {
      type: 'list',
      allowBlank: false,
      formulae: ['"day,night"'],
    },
    'G': {
      type: 'list',
      allowBlank: false,
      formulae: ['"ppm,ppb"'],
    },
    'H': {
      type: 'list',
      allowBlank: false,
      formulae: ['"personal,area,continuous"'],
    },
    'S': {
      type: 'list',
      allowBlank: false,
      formulae: ['"pass,fail,warning"'],
    },
  },
  
  // Starting row for data (after headers)
  dataStartRow: 2,
  
  // Formulas for calculated cells
  formulas: {
    'V4': 'AVERAGE(F:F)', // Average daily value
    'V5': 'MAX(F:F)',     // Max daily value
    'V6': 'MIN(F:F)',     // Min daily value
    'V7': 'COUNTIF(I:I,">0.5")', // Action level exceedances
    'V8': 'COUNTIF(I:I,">1.0")', // PEL exceedances
    'V9': 'COUNTIF(K:K,">5.0")', // STEL exceedances
  },
  
  // Additional configuration for 12-hour shifts
  shiftConfiguration: {
    day: {
      startHour: 6,
      endHour: 18,
      label: 'Day Shift (06:00-18:00)',
    },
    night: {
      startHour: 18,
      endHour: 6,
      label: 'Night Shift (18:00-06:00)',
    },
  },
};

// Type exports
export type BenzeneReading = z.infer<typeof BenzeneReadingSchema>;
export type Benzene12HrEntry = z.infer<typeof Benzene12HrEntrySchema>;
export type BenzeneDailyLog = z.infer<typeof BenzeneDailyLogSchema>;