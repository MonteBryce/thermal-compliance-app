'use client';

import { Bar } from 'react-chartjs-2';
import { defaultChartOptions, chartColors, type ExportStatData } from '@/lib/charts';

interface ExportStatsChartProps {
  data: ExportStatData[];
  title?: string;
  onBarClick?: (exportType: string, value: number) => void;
}

export default function ExportStatsChart({ data, title = 'Export Statistics', onBarClick }: ExportStatsChartProps) {
  const chartData = {
    labels: data.map(item => item.exportType),
    datasets: [
      {
        label: 'Export Count',
        data: data.map(item => item.count),
        backgroundColor: data.map(item => item.color),
        borderColor: data.map(item => item.color),
        borderWidth: 1,
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
        ticks: {
          ...defaultChartOptions.scales?.y?.ticks,
          stepSize: 1,
        },
      },
    },
    onClick: (event: any, elements: any) => {
      if (elements.length > 0 && onBarClick) {
        const index = elements[0].index;
        const exportType = data[index].exportType;
        const value = data[index].count;
        onBarClick(exportType, value);
      }
    },
    onHover: (event: any, elements: any, chart: any) => {
      chart.canvas.style.cursor = elements.length > 0 ? 'pointer' : 'default';
    },
  };

  return (
    <div className="bg-gray-900 p-4 sm:p-6 rounded-lg border border-gray-700">
      <div className="h-64 sm:h-80 w-full">
        <Bar data={chartData} options={options} />
      </div>
    </div>
  );
}