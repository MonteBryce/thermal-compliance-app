// Chart configuration and utilities for the thermal log admin dashboard

export interface ChartData {
  labels: string[];
  datasets: {
    label: string;
    data: number[];
    backgroundColor: string | string[];
    borderColor: string | string[];
    borderWidth?: number;
    tension?: number;
  }[];
}

export interface ExportStatData {
  exportType: string;
  count: number;
  color: string;
}

export interface UsageMetricData {
  date: string;
  activeUsers: number;
  templates: number;
  exports: number;
}

export interface PerformanceData {
  label: string;
  value: number;
  color: string;
}

// Chart color palette based on thermal log theme
export const chartColors = {
  primary: '#f97316',      // Orange-500
  secondary: '#fb923c',    // Orange-400
  accent: '#fed7aa',       // Orange-200
  background: '#1f2937',   // Gray-800
  text: '#f9fafb',         // Gray-50
  grid: '#374151',         // Gray-700
  success: '#10b981',      // Emerald-500
  warning: '#f59e0b',      // Amber-500
  error: '#ef4444',        // Red-500
  info: '#3b82f6',         // Blue-500
};

// Default chart configuration
export const defaultChartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: {
      labels: {
        color: chartColors.text,
        font: {
          size: 12,
        },
      },
    },
    tooltip: {
      backgroundColor: chartColors.background,
      titleColor: chartColors.text,
      bodyColor: chartColors.text,
      borderColor: chartColors.primary,
      borderWidth: 1,
    },
  },
  scales: {
    x: {
      ticks: {
        color: chartColors.text,
        font: {
          size: 11,
        },
      },
      grid: {
        color: chartColors.grid,
      },
    },
    y: {
      ticks: {
        color: chartColors.text,
        font: {
          size: 11,
        },
      },
      grid: {
        color: chartColors.grid,
      },
    },
  },
};

// Utility functions for chart data processing
export function formatChartData(data: any[]): ChartData {
  return {
    labels: data.map(item => item.label || item.name || item.date),
    datasets: [{
      label: 'Dataset',
      data: data.map(item => item.value || item.count || 0),
      backgroundColor: chartColors.primary,
      borderColor: chartColors.secondary,
      borderWidth: 2,
    }],
  };
}

export function formatExportStatsData(data: ExportStatData[]): ChartData {
  return {
    labels: data.map(item => item.exportType),
    datasets: [{
      label: 'Export Count',
      data: data.map(item => item.count),
      backgroundColor: data.map(item => item.color),
      borderColor: chartColors.text,
      borderWidth: 1,
    }],
  };
}

export function formatUsageMetricsData(data: UsageMetricData[]): ChartData {
  return {
    labels: data.map(item => item.date),
    datasets: [
      {
        label: 'Active Users',
        data: data.map(item => item.activeUsers),
        backgroundColor: chartColors.primary,
        borderColor: chartColors.primary,
        borderWidth: 2,
        tension: 0.1,
      },
      {
        label: 'Templates Created',
        data: data.map(item => item.templates),
        backgroundColor: chartColors.secondary,
        borderColor: chartColors.secondary,
        borderWidth: 2,
        tension: 0.1,
      },
      {
        label: 'Exports',
        data: data.map(item => item.exports),
        backgroundColor: chartColors.accent,
        borderColor: chartColors.accent,
        borderWidth: 2,
        tension: 0.1,
      },
    ],
  };
}

export function formatPerformanceData(data: PerformanceData[]): ChartData {
  return {
    labels: data.map(item => item.label),
    datasets: [{
      label: 'Performance Metrics',
      data: data.map(item => item.value),
      backgroundColor: data.map(item => item.color),
      borderColor: chartColors.text,
      borderWidth: 2,
    }],
  };
}

// Responsive breakpoints for charts
export const chartBreakpoints = {
  mobile: 480,
  tablet: 768,
  desktop: 1024,
  large: 1280,
};

// Chart size configurations for different breakpoints
export const chartSizes = {
  mobile: {
    height: 250,
    fontSize: 10,
    legendPosition: 'bottom',
  },
  tablet: {
    height: 300,
    fontSize: 11,
    legendPosition: 'right',
  },
  desktop: {
    height: 400,
    fontSize: 12,
    legendPosition: 'right',
  },
  large: {
    height: 450,
    fontSize: 12,
    legendPosition: 'right',
  },
};

export default {
  chartColors,
  defaultChartOptions,
  formatChartData,
  formatExportStatsData,
  formatUsageMetricsData,
  formatPerformanceData,
  chartBreakpoints,
  chartSizes,
};