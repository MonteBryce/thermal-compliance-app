import dynamic from 'next/dynamic';
import { ComponentType } from 'react';

export const DynamicChart = dynamic(
  () => import('recharts').then(mod => mod.LineChart),
  {
    loading: () => <div className="h-64 bg-gray-800 animate-pulse rounded-lg" />,
    ssr: false,
  }
);

export const DynamicBarChart = dynamic(
  () => import('recharts').then(mod => mod.BarChart),
  {
    loading: () => <div className="h-64 bg-gray-800 animate-pulse rounded-lg" />,
    ssr: false,
  }
);

export const DynamicAreaChart = dynamic(
  () => import('recharts').then(mod => mod.AreaChart),
  {
    loading: () => <div className="h-64 bg-gray-800 animate-pulse rounded-lg" />,
    ssr: false,
  }
);

export const DynamicPieChart = dynamic(
  () => import('recharts').then(mod => mod.PieChart),
  {
    loading: () => <div className="h-64 bg-gray-800 animate-pulse rounded-lg" />,
    ssr: false,
  }
);

export const DynamicExcelViewer = dynamic(
  () => import('@/components/logbuilder/ExcelPreview'),
  {
    loading: () => <div className="p-4 text-gray-400">Loading Excel preview...</div>,
    ssr: false,
  }
);

export const DynamicPDFViewer = dynamic(
  () => import('react-pdf').then(mod => mod.Document),
  {
    loading: () => <div className="p-4 text-gray-400">Loading PDF viewer...</div>,
    ssr: false,
  }
);

export function createDynamicComponent<P = {}>(
  importFunc: () => Promise<{ default: ComponentType<P> }>,
  options?: {
    loading?: ComponentType;
    ssr?: boolean;
  }
) {
  return dynamic(importFunc, {
    loading: options?.loading || (() => (
      <div className="flex items-center justify-center p-4">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-orange-500" />
      </div>
    )),
    ssr: options?.ssr ?? true,
  });
}