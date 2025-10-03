// Sample chart data for testing and demonstration
import { ExportStatData, UsageMetricData, PerformanceData, chartColors } from './charts';

// Sample export statistics data
export const sampleExportStats: ExportStatData[] = [
  {
    exportType: 'PDF Reports',
    count: 156,
    color: chartColors.primary,
  },
  {
    exportType: 'Excel Files',
    count: 234,
    color: chartColors.secondary,
  },
  {
    exportType: 'CSV Data',
    count: 89,
    color: chartColors.success,
  },
  {
    exportType: 'JSON Export',
    count: 67,
    color: chartColors.info,
  },
  {
    exportType: 'Custom Reports',
    count: 43,
    color: chartColors.warning,
  },
];

// Sample usage metrics data (last 30 days)
export const sampleUsageMetrics: UsageMetricData[] = [
  { date: '2025-01-01', activeUsers: 45, templates: 12, exports: 23 },
  { date: '2025-01-02', activeUsers: 52, templates: 15, exports: 31 },
  { date: '2025-01-03', activeUsers: 38, templates: 9, exports: 18 },
  { date: '2025-01-04', activeUsers: 67, templates: 18, exports: 42 },
  { date: '2025-01-05', activeUsers: 71, templates: 21, exports: 38 },
  { date: '2025-01-06', activeUsers: 44, templates: 11, exports: 25 },
  { date: '2025-01-07', activeUsers: 58, templates: 16, exports: 33 },
  { date: '2025-01-08', activeUsers: 63, templates: 19, exports: 29 },
  { date: '2025-01-09', activeUsers: 49, templates: 13, exports: 27 },
  { date: '2025-01-10', activeUsers: 55, templates: 17, exports: 34 },
  { date: '2025-01-11', activeUsers: 72, templates: 22, exports: 41 },
  { date: '2025-01-12', activeUsers: 68, templates: 20, exports: 36 },
  { date: '2025-01-13', activeUsers: 41, templates: 10, exports: 22 },
  { date: '2025-01-14', activeUsers: 59, templates: 16, exports: 30 },
  { date: '2025-01-15', activeUsers: 64, templates: 18, exports: 35 },
  { date: '2025-01-16', activeUsers: 53, templates: 14, exports: 28 },
  { date: '2025-01-17', activeUsers: 47, templates: 12, exports: 24 },
  { date: '2025-01-18', activeUsers: 61, templates: 17, exports: 32 },
  { date: '2025-01-19', activeUsers: 69, templates: 21, exports: 39 },
  { date: '2025-01-20', activeUsers: 56, templates: 15, exports: 31 },
  { date: '2025-01-21', activeUsers: 73, templates: 23, exports: 44 },
  { date: '2025-01-22', activeUsers: 65, templates: 19, exports: 37 },
  { date: '2025-01-23', activeUsers: 48, templates: 13, exports: 26 },
  { date: '2025-01-24', activeUsers: 54, templates: 16, exports: 29 },
  { date: '2025-01-25', activeUsers: 62, templates: 18, exports: 33 },
  { date: '2025-01-26', activeUsers: 57, templates: 15, exports: 30 },
  { date: '2025-01-27', activeUsers: 66, templates: 20, exports: 38 },
  { date: '2025-01-28', activeUsers: 70, templates: 22, exports: 41 },
  { date: '2025-01-29', activeUsers: 51, templates: 14, exports: 27 },
  { date: '2025-01-30', activeUsers: 60, templates: 17, exports: 34 },
];

// Sample performance data
export const samplePerformanceData: PerformanceData[] = [
  {
    label: 'Template Load Time',
    value: 85,
    color: chartColors.success,
  },
  {
    label: 'Export Processing',
    value: 78,
    color: chartColors.primary,
  },
  {
    label: 'Database Response',
    value: 92,
    color: chartColors.info,
  },
  {
    label: 'UI Responsiveness',
    value: 88,
    color: chartColors.secondary,
  },
  {
    label: 'OCR Processing',
    value: 73,
    color: chartColors.warning,
  },
  {
    label: 'File Upload',
    value: 81,
    color: chartColors.accent,
  },
];

// Sample template usage data
export const sampleTemplateUsage = [
  { name: 'Thermal Inspection', usage: 45, trend: '+12%' },
  { name: 'Equipment Check', usage: 38, trend: '+8%' },
  { name: 'Safety Audit', usage: 32, trend: '+5%' },
  { name: 'Maintenance Log', usage: 28, trend: '+15%' },
  { name: 'Quality Control', usage: 24, trend: '+3%' },
  { name: 'Compliance Check', usage: 19, trend: '+7%' },
];

// Sample error tracking data
export const sampleErrorData = [
  { type: 'Template Load Error', count: 12, severity: 'high' },
  { type: 'Export Timeout', count: 8, severity: 'medium' },
  { type: 'Database Connection', count: 5, severity: 'high' },
  { type: 'File Upload Failed', count: 15, severity: 'low' },
  { type: 'OCR Processing Error', count: 7, severity: 'medium' },
  { type: 'Authentication Issue', count: 3, severity: 'high' },
];

// Sample user activity data
export const sampleUserActivity = [
  { action: 'Template Created', count: 45, percentage: 32 },
  { action: 'Export Generated', count: 67, percentage: 48 },
  { action: 'Template Edited', count: 23, percentage: 16 },
  { action: 'User Login', count: 89, percentage: 63 },
  { action: 'Settings Changed', count: 12, percentage: 9 },
  { action: 'Help Accessed', count: 18, percentage: 13 },
];

// Sample system resource data
export const sampleResourceData = [
  { resource: 'CPU Usage', current: 45, max: 100, unit: '%' },
  { resource: 'Memory Usage', current: 68, max: 100, unit: '%' },
  { resource: 'Disk Space', current: 72, max: 100, unit: '%' },
  { resource: 'Network I/O', current: 34, max: 100, unit: '%' },
  { resource: 'Database Load', current: 56, max: 100, unit: '%' },
];

export default {
  sampleExportStats,
  sampleUsageMetrics,
  samplePerformanceData,
  sampleTemplateUsage,
  sampleErrorData,
  sampleUserActivity,
  sampleResourceData,
};