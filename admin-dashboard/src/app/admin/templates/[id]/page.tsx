import { Suspense } from 'react';
import { TemplateEditorClient } from './TemplateEditorClient';

interface TemplateEditorPageProps {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ action?: string }>;
}

export default async function TemplateEditorPage({ params, searchParams }: TemplateEditorPageProps) {
  const { id } = await params;
  const { action } = await searchParams;
  
  return (
    <div className="h-screen overflow-hidden">
      <Suspense fallback={<div>Loading template editor...</div>}>
        <TemplateEditorClient templateId={id} initialAction={action} />
      </Suspense>
    </div>
  );
}