import { Suspense } from 'react';
import { AssignTemplateFlow } from './AssignTemplateFlow';

export default function AssignTemplatePage() {
  return (
    <div className="px-6 py-8">
      <Suspense fallback={
        <div className="flex items-center justify-center p-12 text-gray-400">
          Loading assignment flow...
        </div>
      }>
        <AssignTemplateFlow />
      </Suspense>
    </div>
  );
}