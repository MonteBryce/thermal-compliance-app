export interface MetricValidation {
  min?: number;
  max?: number;
  warnBelow?: number;
  warnAbove?: number;
  required?: boolean;
  pattern?: string;
}

export interface TemplateMetric {
  key: string;
  label: string;
  unit?: string;
  required: boolean;
  visible: boolean;
  notes?: string;
  order: number;
  category?: 'primary' | 'flow' | 'pressure' | 'composition' | 'other';
  validation?: MetricValidation;
}

export interface HourGroup {
  label: string;
  hours: string[];
  color?: string;
}

export interface LogTemplate {
  id: string;
  logType: string;
  displayName: string;
  description?: string;
  hours: string[];
  groups: HourGroup[];
  metrics: TemplateMetric[];
  validation: Record<string, MetricValidation>;
  version: number;
  updatedAt: string;
  updatedBy: string;
  active: boolean;
  notes?: string;
}

export interface StructureCheckResult {
  passed: boolean;
  mismatches: StructureMismatch[];
  warnings: string[];
  excelHeaders?: string[];
  templateHeaders?: string[];
}

export interface StructureMismatch {
  type: 'missing_metric' | 'extra_metric' | 'wrong_order' | 'wrong_unit' | 'wrong_label';
  expected?: string;
  actual?: string;
  suggestion?: string;
  severity: 'error' | 'warning';
}

// Default template configurations
export const DEFAULT_HOURS = [
  '00', '01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11',
  '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23'
];

export const DEFAULT_HOUR_GROUPS: HourGroup[] = [
  {
    label: 'AM',
    hours: ['00', '01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11'],
    color: '#3B82F6'
  },
  {
    label: 'PM', 
    hours: ['12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23'],
    color: '#F59E0B'
  }
];

// Standard metric definitions for different log types
export const STANDARD_METRICS: Record<string, TemplateMetric[]> = {
  methane_hourly: [
    {
      key: 'inspectionTime',
      label: 'Inspection Time',
      required: true,
      visible: true,
      order: 1,
      category: 'primary'
    },
    {
      key: 'operatorInitials',
      label: 'Operator Initials',
      required: true,
      visible: true,
      order: 2,
      category: 'primary'
    },
    {
      key: 'exhaustTempF',
      label: 'Exhaust Temperature',
      unit: '°F',
      required: true,
      visible: true,
      order: 10,
      category: 'primary',
      validation: { min: 1200, max: 2000, warnBelow: 1400 }
    },
    {
      key: 'inletReadingPpm',
      label: 'Inlet Reading (PPM or % METHANE)',
      unit: 'PPM',
      required: true,
      visible: true,
      order: 11,
      category: 'composition'
    },
    {
      key: 'outletReadingPpm',
      label: 'Outlet Reading (PPM METHANE)',
      unit: 'PPM',
      required: true,
      visible: true,
      order: 12,
      category: 'composition'
    },
    {
      key: 'vaporInletFlowRateFpm',
      label: 'Vapor Inlet Flow Rate',
      unit: 'FPM',
      required: false,
      visible: true,
      order: 20,
      category: 'flow'
    },
    {
      key: 'vaporInletFlowRateBbl',
      label: 'Vapor Inlet Flow Rate',
      unit: 'BBL/HR',
      required: false,
      visible: false,
      order: 21,
      category: 'flow'
    },
    {
      key: 'tankRefillFlowRate',
      label: 'Tank Refill Flow Rate',
      unit: 'BBL/HR',
      required: false,
      visible: false,
      order: 22,
      category: 'flow'
    },
    {
      key: 'combustionAirFlowRate',
      label: 'Combustion Air Flow Rate',
      unit: 'FPM',
      required: false,
      visible: true,
      order: 23,
      category: 'flow'
    },
    {
      key: 'vacuumAtTankVaporOutlet',
      label: 'Vacuum at Tank Vapor Outlet (2 in H₂O MIN)',
      unit: 'in H₂O',
      required: false,
      visible: false,
      order: 30,
      category: 'pressure'
    },
    {
      key: 'totalizer',
      label: 'Totalizer',
      unit: 'SCF',
      required: false,
      visible: false,
      order: 40,
      category: 'other'
    }
  ],
  
  benzene_12hr: [
    {
      key: 'inspectionTime',
      label: 'Inspection Time',
      required: true,
      visible: true,
      order: 1,
      category: 'primary'
    },
    {
      key: 'operatorInitials',
      label: 'Operator Initials',
      required: true,
      visible: true,
      order: 2,
      category: 'primary'
    },
    {
      key: 'exhaustTempF',
      label: 'Exhaust Temperature',
      unit: '°F',
      required: true,
      visible: true,
      order: 10,
      category: 'primary'
    },
    {
      key: 'benzeneInletPpm',
      label: 'T.O. Inlet Reading - PPM BENZENE',
      unit: 'PPM',
      required: true,
      visible: true,
      order: 11,
      category: 'composition'
    },
    {
      key: 'h2sInletPpm',
      label: 'T.O. Inlet Reading - PPM H₂S',
      unit: 'PPM',
      required: true,
      visible: true,
      order: 12,
      category: 'composition'
    },
    {
      key: 'inletReadingMethane',
      label: 'Inlet Reading (PPM or % METHANE)',
      unit: 'PPM',
      required: true,
      visible: true,
      order: 13,
      category: 'composition'
    },
    {
      key: 'outletReadingMethane',
      label: 'Outlet Reading (PPM METHANE)',
      unit: 'PPM',
      required: true,
      visible: true,
      order: 14,
      category: 'composition'
    },
    {
      key: 'degasFiveMinReadingPpm',
      label: 'Degas Five Minute Readings - PPM METHANE',
      unit: 'PPM',
      required: false,
      visible: true,
      order: 20,
      category: 'composition'
    },
    {
      key: 'finalBenzeneReading',
      label: 'Final Benzene Reading - When Required',
      unit: 'PPM',
      required: false,
      visible: true,
      order: 21,
      category: 'composition'
    }
  ]
};

export function createDefaultTemplate(logType: string): LogTemplate {
  const metrics = STANDARD_METRICS[logType] || STANDARD_METRICS.methane_hourly;
  
  return {
    id: `${logType}_v1`,
    logType,
    displayName: `${logType.replace('_', ' ').toUpperCase()} Log Template`,
    hours: DEFAULT_HOURS,
    groups: DEFAULT_HOUR_GROUPS,
    metrics,
    validation: {},
    version: 1,
    updatedAt: new Date().toISOString(),
    updatedBy: 'admin',
    active: true
  };
}