'use client';

import { useState, lazy, Suspense } from 'react';
import dynamic from 'next/dynamic';
import { sampleExportStats, sampleUsageMetrics, samplePerformanceData } from '@/lib/sample-chart-data';

const ExportStatsChart = dynamic(
  () => import('@/components/charts').then(mod => ({ default: mod.ExportStatsChart })),
  {
    loading: () => <div className="h-64 bg-gray-800 animate-pulse rounded-lg" />,
    ssr: false,
  }
);

const UsageMetricsChart = dynamic(
  () => import('@/components/charts').then(mod => ({ default: mod.UsageMetricsChart })),
  {
    loading: () => <div className="h-64 bg-gray-800 animate-pulse rounded-lg" />,
    ssr: false,
  }
);

const PerformanceChart = dynamic(
  () => import('@/components/charts').then(mod => ({ default: mod.PerformanceChart })),
  {
    loading: () => <div className="h-64 bg-gray-800 animate-pulse rounded-lg" />,
    ssr: false,
  }
);

export default function ChartsTestPage() {
  const [selectedData, setSelectedData] = useState<string>('');

  const handleExportBarClick = (exportType: string, value: number) => {
    setSelectedData(`Clicked: ${exportType} (${value} exports)`);
  };

  const handleUsagePointClick = (date: string, metric: string, value: number) => {
    setSelectedData(`Clicked: ${metric} on ${date} (${value})`);
  };

  const handlePerformanceSliceClick = (label: string, value: number) => {
    setSelectedData(`Clicked: ${label} (${value}%)`);
  };

  return (
    <div className="min-h-screen bg-black text-white p-4 md:p-8">
      <div className="max-w-7xl mx-auto">
        <h1 className="text-3xl font-bold mb-8 text-center">Chart Responsiveness Test</h1>
        
        {/* Interactive feedback */}
        {selectedData && (
          <div className="mb-6 p-4 bg-orange-600 rounded-lg text-center">
            <p className="font-medium">{selectedData}</p>
          </div>
        )}

        {/* Grid layout for different screen sizes */}
        <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-2 gap-8 mb-8">
          {/* Export Statistics Chart */}
          <div className="w-full">
            <ExportStatsChart
              data={sampleExportStats}
              title="Export Statistics (Click bars to test interactivity)"
              onBarClick={handleExportBarClick}
            />
          </div>

          {/* Performance Chart */}
          <div className="w-full">
            <PerformanceChart
              data={samplePerformanceData}
              title="System Performance (Click slices to test)"
              onSliceClick={handlePerformanceSliceClick}
            />
          </div>
        </div>

        {/* Usage Metrics Chart - Full width */}
        <div className="w-full mb-8">
          <UsageMetricsChart
            data={sampleUsageMetrics}
            title="Usage Metrics Over Time (Click points to test)"
            onDataPointClick={handleUsagePointClick}
          />
        </div>

        {/* Responsive testing grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mb-8">
          <div className="text-center p-4 bg-gray-800 rounded-lg">
            <h3 className="text-lg font-semibold mb-2">Mobile (&lt; 768px)</h3>
            <p className="text-sm text-gray-300">Single column layout</p>
          </div>
          <div className="text-center p-4 bg-gray-800 rounded-lg">
            <h3 className="text-lg font-semibold mb-2">Tablet (768px - 1024px)</h3>
            <p className="text-sm text-gray-300">Two column layout</p>
          </div>
          <div className="text-center p-4 bg-gray-800 rounded-lg">
            <h3 className="text-lg font-semibold mb-2">Desktop (&gt; 1024px)</h3>
            <p className="text-sm text-gray-300">Three column layout</p>
          </div>
        </div>

        {/* Instructions */}
        <div className="bg-gray-900 p-6 rounded-lg border border-gray-700">
          <h2 className="text-xl font-bold mb-4">Responsiveness Test Instructions</h2>
          <ul className="space-y-2 text-gray-300">
            <li>• Resize your browser window to test different screen sizes</li>
            <li>• Click on chart elements to test interactivity</li>
            <li>• Verify that charts maintain aspect ratio and readability</li>
            <li>• Check that tooltips and hover effects work properly</li>
            <li>• Confirm that legends and titles scale appropriately</li>
          </ul>
        </div>
      </div>
    </div>
  );
}