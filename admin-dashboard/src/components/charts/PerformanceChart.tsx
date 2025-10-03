'use client';

import { Doughnut } from 'react-chartjs-2';
import { defaultChartOptions, chartColors, type PerformanceData } from '@/lib/charts';

interface PerformanceChartProps {
  data: PerformanceData[];
  title?: string;
  onSliceClick?: (label: string, value: number) => void;
}

export default function PerformanceChart({ data, title = 'Performance Metrics', onSliceClick }: PerformanceChartProps) {
  const chartData = {
    labels: data.map(item => item.label),
    datasets: [
      {
        label: 'Performance',
        data: data.map(item => item.value),
        backgroundColor: data.map(item => item.color),
        borderColor: chartColors.background,
        borderWidth: 2,
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
      legend: {
        ...defaultChartOptions.plugins?.legend,
        position: 'right' as const,
      },
    },
    onClick: (event: any, elements: any) => {
      if (elements.length > 0 && onSliceClick) {
        const index = elements[0].index;
        const label = data[index].label;
        const value = data[index].value;
        onSliceClick(label, value);
      }
    },
    onHover: (event: any, elements: any, chart: any) => {
      chart.canvas.style.cursor = elements.length > 0 ? 'pointer' : 'default';
    },
  };

  return (
    <div className="bg-gray-900 p-4 sm:p-6 rounded-lg border border-gray-700">
      <div className="h-64 sm:h-80 w-full">
        <Doughnut data={chartData} options={options} />
      </div>
    </div>
  );
}