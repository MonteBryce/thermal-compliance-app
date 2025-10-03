import { Suspense } from 'react';
import { TemplatesHub } from './TemplatesHub';

export default function TemplatesPage() {
  return (
    <div className="px-6 py-8">
      <Suspense fallback={<div className="flex items-center justify-center p-12 text-gray-400">Loading templates...</div>}>
        <TemplatesHub />
      </Suspense>
    </div>
  );
}