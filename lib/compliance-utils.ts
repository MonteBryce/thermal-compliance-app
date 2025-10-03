import { Timestamp } from 'firebase-admin/firestore';

export interface LogEntry {
  id: string;
  hour: number;
  exhaustTemp: number;
  flow: number;
  h2sPpm?: number;
  benzenePpm?: number;
  timestamp: Timestamp;
  operatorId: string;
  notes?: string;
}

export interface JobTemplateConfig {
  hasExcelTemplate: boolean;
  templateId?: string;
  templateName?: string;
  autoExportEnabled?: boolean;
  logType: string;
  configuredAt?: Date;
}

export interface ActiveJob {
  id: string;
  projectId: string;
  facility: string;
  tankId: string;
  logType: string;
  assignedOperators: string[];
  startDate: Date;
  endDate?: Date;
  expectedHours: number;
  completedHours: number;
  lastEntryTimestamp?: Date;
  templateConfig?: JobTemplateConfig;
}

export interface Deviation {
  id: string;
  projectId: string;
  logId: string;
  facility: string;
  dateTime: Date;
  type: 'missing_entry' | 'outlier' | 'limit_exceeded' | 'equipment' | 'other';
  description: string;
  cause?: string;
  status: 'open' | 'closed';
  assignedTo?: string;
  evidenceUrls: string[];
  createdBy: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface OutlierConfig {
  exhaustTempThreshold: number; // degrees F
  flowThreshold: number; // percentage change
  h2sThreshold: number; // ppm change
  benzeneThreshold: number; // ppm change
}

const DEFAULT_OUTLIER_CONFIG: OutlierConfig = {
  exhaustTempThreshold: 50, // 50°F jump
  flowThreshold: 25, // 25% change
  h2sThreshold: 10, // 10 ppm jump
  benzeneThreshold: 5, // 5 ppm jump
};

/**
 * Calculate progress percentage for a job
 */
export function calculateProgress(completedHours: number, expectedHours: number): number {
  if (expectedHours === 0) return 0;
  return Math.min(100, Math.round((completedHours / expectedHours) * 100));
}

/**
 * Find missing entries for a 24-hour period
 */
export function findMissingEntries(
  entries: LogEntry[],
  date: Date
): number[] {
  const presentHours = new Set(entries.map(e => e.hour));
  const missingHours: number[] = [];
  
  for (let hour = 0; hour < 24; hour++) {
    if (!presentHours.has(hour)) {
      missingHours.push(hour);
    }
  }
  
  return missingHours;
}

/**
 * Detect outliers in consecutive readings
 */
export function detectOutliers(
  entries: LogEntry[],
  config: OutlierConfig = DEFAULT_OUTLIER_CONFIG
): Array<{
  hour: number;
  metric: string;
  previousValue: number;
  currentValue: number;
  change: number;
  threshold: number;
}> {
  const outliers = [];
  const sortedEntries = [...entries].sort((a, b) => a.hour - b.hour);
  
  for (let i = 1; i < sortedEntries.length; i++) {
    const prev = sortedEntries[i - 1];
    const curr = sortedEntries[i];
    
    // Check exhaust temperature
    const tempChange = Math.abs(curr.exhaustTemp - prev.exhaustTemp);
    if (tempChange >= config.exhaustTempThreshold) {
      outliers.push({
        hour: curr.hour,
        metric: 'Exhaust Temperature',
        previousValue: prev.exhaustTemp,
        currentValue: curr.exhaustTemp,
        change: tempChange,
        threshold: config.exhaustTempThreshold,
      });
    }
    
    // Check flow (percentage change)
    if (prev.flow > 0) {
      const flowChangePercent = Math.abs((curr.flow - prev.flow) / prev.flow) * 100;
      if (flowChangePercent >= config.flowThreshold) {
        outliers.push({
          hour: curr.hour,
          metric: 'Flow Rate',
          previousValue: prev.flow,
          currentValue: curr.flow,
          change: flowChangePercent,
          threshold: config.flowThreshold,
        });
      }
    }
    
    // Check H2S if present
    if (curr.h2sPpm !== undefined && prev.h2sPpm !== undefined) {
      const h2sChange = Math.abs(curr.h2sPpm - prev.h2sPpm);
      if (h2sChange >= config.h2sThreshold) {
        outliers.push({
          hour: curr.hour,
          metric: 'H2S',
          previousValue: prev.h2sPpm,
          currentValue: curr.h2sPpm,
          change: h2sChange,
          threshold: config.h2sThreshold,
        });
      }
    }
    
    // Check Benzene if present
    if (curr.benzenePpm !== undefined && prev.benzenePpm !== undefined) {
      const benzeneChange = Math.abs(curr.benzenePpm - prev.benzenePpm);
      if (benzeneChange >= config.benzeneThreshold) {
        outliers.push({
          hour: curr.hour,
          metric: 'Benzene',
          previousValue: prev.benzenePpm,
          currentValue: curr.benzenePpm,
          change: benzeneChange,
          threshold: config.benzeneThreshold,
        });
      }
    }
  }
  
  return outliers;
}

/**
 * Verify meters against permit requirements
 */
export function verifyMeters(
  installedMeters: string[],
  requiredMeters: string[]
): {
  verified: boolean;
  missing: string[];
  extra: string[];
} {
  const installedSet = new Set(installedMeters);
  const requiredSet = new Set(requiredMeters);
  
  const missing = requiredMeters.filter(m => !installedSet.has(m));
  const extra = installedMeters.filter(m => !requiredSet.has(m));
  
  return {
    verified: missing.length === 0,
    missing,
    extra,
  };
}

/**
 * Calculate emissions from flow and concentration data
 * Formula: Emissions (lb/hr) = Flow (scfh) × Concentration (ppm) × MW / (379.5 × 10^6)
 * Where MW = molecular weight, 379.5 = molar volume at STP
 */
export function calculateEmissions(
  entries: LogEntry[],
  molecularWeight: number = 34.08 // Default to H2S
): {
  hourlyEmissions: Array<{ hour: number; emissions: number }>;
  totalEmissions: number;
  averageEmissions: number;
  peakEmissions: number;
  peakHour: number;
} {
  const hourlyEmissions = entries.map(entry => {
    const concentration = entry.h2sPpm || 0;
    const emissions = (entry.flow * concentration * molecularWeight) / (379.5 * 1000000);
    return {
      hour: entry.hour,
      emissions: Math.round(emissions * 1000) / 1000, // Round to 3 decimal places
    };
  });
  
  const totalEmissions = hourlyEmissions.reduce((sum, h) => sum + h.emissions, 0);
  const averageEmissions = entries.length > 0 ? totalEmissions / entries.length : 0;
  
  let peakEmissions = 0;
  let peakHour = 0;
  hourlyEmissions.forEach(h => {
    if (h.emissions > peakEmissions) {
      peakEmissions = h.emissions;
      peakHour = h.hour;
    }
  });
  
  return {
    hourlyEmissions,
    totalEmissions: Math.round(totalEmissions * 1000) / 1000,
    averageEmissions: Math.round(averageEmissions * 1000) / 1000,
    peakEmissions: Math.round(peakEmissions * 1000) / 1000,
    peakHour,
  };
}

/**
 * Determine urgency status based on various conditions
 */
export function determineUrgencyStatus(conditions: {
  hasOpenDeviations?: boolean;
  deviationAge?: number; // hours
  hasMissingEntries?: boolean;
  missingEntriesAge?: number; // hours  
  hasOutliers?: boolean;
  outliersAge?: number; // hours
  hasLimitExceeded?: boolean;
}): 'red' | 'amber' | 'green' {
  const {
    hasOpenDeviations,
    deviationAge = 0,
    hasMissingEntries,
    missingEntriesAge = 0,
    hasOutliers,
    outliersAge = 0,
    hasLimitExceeded,
  } = conditions;
  
  // Red conditions
  if (hasLimitExceeded) return 'red';
  if (hasOpenDeviations && deviationAge > 24) return 'red';
  if (hasMissingEntries && missingEntriesAge <= 2) return 'red';
  
  // Amber conditions
  if (hasOutliers && outliersAge <= 6) return 'amber';
  if (hasOpenDeviations) return 'amber';
  if (hasMissingEntries) return 'amber';
  
  // Default to green
  return 'green';
}

/**
 * Format hour number to time string
 */
export function formatHour(hour: number): string {
  return `${hour.toString().padStart(2, '0')}:00`;
}

/**
 * Get date range for a specific day
 */
export function getDayRange(date: Date): { start: Date; end: Date } {
  const start = new Date(date);
  start.setHours(0, 0, 0, 0);
  
  const end = new Date(date);
  end.setHours(23, 59, 59, 999);
  
  return { start, end };
}