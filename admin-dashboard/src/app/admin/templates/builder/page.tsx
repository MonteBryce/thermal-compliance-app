import { lazy, Suspense } from 'react';

const TemplateWizard = lazy(() => import('./TemplateWizard').then(mod => ({ default: mod.TemplateWizard })));

export default function TemplateBuilderPage() {
  return (
    <div className="min-h-screen bg-[#111111]">
      <Suspense fallback={
        <div className="flex items-center justify-center h-screen">
          <div className="text-gray-400">Loading Template Builder...</div>
        </div>
      }>
        <TemplateWizard />
      </Suspense>
    </div>
  );
}