import { Suspense, lazy, ComponentType } from 'react';
import { ErrorBoundary } from 'react-error-boundary';

interface LazyWrapperProps {
  children: React.ReactNode;
  fallback?: React.ReactNode;
}

const DefaultFallback = () => (
  <div className="flex items-center justify-center p-8">
    <div className="flex flex-col items-center gap-3">
      <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-orange-500"></div>
      <div className="text-gray-400 text-sm">Loading component...</div>
    </div>
  </div>
);

const ErrorFallback = ({ error, resetErrorBoundary }: any) => (
  <div className="p-6 bg-red-900/20 border border-red-600/30 rounded-lg">
    <h3 className="text-red-400 font-semibold mb-2">Component failed to load</h3>
    <p className="text-gray-400 text-sm mb-4">{error?.message || 'Unknown error'}</p>
    <button
      onClick={resetErrorBoundary}
      className="px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded-md text-sm"
    >
      Try again
    </button>
  </div>
);

export function LazyWrapper({ children, fallback = <DefaultFallback /> }: LazyWrapperProps) {
  return (
    <ErrorBoundary FallbackComponent={ErrorFallback}>
      <Suspense fallback={fallback}>
        {children}
      </Suspense>
    </ErrorBoundary>
  );
}

export function createLazyComponent<T extends ComponentType<any>>(
  importFunc: () => Promise<{ default: T }>,
  displayName?: string
) {
  const LazyComponent = lazy(importFunc);
  if (displayName) {
    LazyComponent.displayName = displayName;
  }
  return LazyComponent;
}