import { Suspense } from 'react';
import { TemplateLibrary } from './TemplateLibrary';

export default function TemplateLibraryPage() {
  return (
    <div className="px-6 py-8">
      <Suspense fallback={
        <div className="flex items-center justify-center p-12 text-gray-400">
          Loading template library...
        </div>
      }>
        <TemplateLibrary />
      </Suspense>
    </div>
  );
}