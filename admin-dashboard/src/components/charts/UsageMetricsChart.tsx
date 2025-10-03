'use client';

import { Line } from 'react-chartjs-2';
import { defaultChartOptions, chartColors, type UsageMetricData } from '@/lib/charts';

interface UsageMetricsChartProps {
  data: UsageMetricData[];
  title?: string;
  onDataPointClick?: (date: string, metric: string, value: number) => void;
}

export default function UsageMetricsChart({ data, title = 'Usage Metrics Over Time', onDataPointClick }: UsageMetricsChartProps) {
  const chartData = {
    labels: data.map(item => new Date(item.date).toLocaleDateString()),
    datasets: [
      {
        label: 'Active Jobs',
        data: data.map(item => item.activeJobs),
        borderColor: chartColors.primary,
        backgroundColor: chartColors.primary + '20',
        tension: 0.4,
        fill: false,
      },
      {
        label: 'Completed Jobs',
        data: data.map(item => item.completedJobs),
        borderColor: chartColors.success,
        backgroundColor: chartColors.success + '20',
        tension: 0.4,
        fill: false,
      },
      {
        label: 'Total Exports',
        data: data.map(item => item.totalExports),
        borderColor: chartColors.info,
        backgroundColor: chartColors.info + '20',
        tension: 0.4,
        fill: false,
      },
    ],
  };

  const options = {
    ...defaultChartOptions,
    plugins: {
      ...defaultChartOptions.plugins,
      title: {
        display: true,
        text: title,
        color: '#ffffff',
        font: {
          size: 16,
          weight: 'bold' as const,
        },
      },
    },
    scales: {
      ...defaultChartOptions.scales,
      y: {
        ...defaultChartOptions.scales?.y,
        beginAtZero: true,
      },
    },
    interaction: {
      intersect: false,
      mode: 'index' as const,
    },
    onClick: (event: any, elements: any) => {
      if (elements.length > 0 && onDataPointClick) {
        const element = elements[0];
        const datasetIndex = element.datasetIndex;
        const index = element.index;
        const date = data[index].date;
        const datasets = ['activeJobs', 'completedJobs', 'totalExports'];
        const metric = datasets[datasetIndex];
        const value = element.element.$context.parsed.y;
        onDataPointClick(date, metric, value);
      }
    },
    onHover: (event: any, elements: any, chart: any) => {
      chart.canvas.style.cursor = elements.length > 0 ? 'pointer' : 'default';
    },
  };

  return (
    <div className="bg-gray-900 p-4 sm:p-6 rounded-lg border border-gray-700">
      <div className="h-64 sm:h-80 w-full">
        <Line data={chartData} options={options} />
      </div>
    </div>
  );
}