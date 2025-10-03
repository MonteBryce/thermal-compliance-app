import { Suspense } from 'react';
import { FacilityPresetsManager } from './FacilityPresetsManager';

export default function FacilityPresetsPage() {
  return (
    <div className="px-6 py-8">
      <Suspense fallback={
        <div className="flex items-center justify-center p-12 text-gray-400">
          Loading facility presets...
        </div>
      }>
        <FacilityPresetsManager />
      </Suspense>
    </div>
  );
}