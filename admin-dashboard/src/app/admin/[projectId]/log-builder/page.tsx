import { Suspense } from 'react';
import { notFound } from 'next/navigation';
import { requireAdmin } from '@/lib/auth/rbac';
import { LogBuilderClient } from './LogBuilderClient';

interface PageProps {
  params: Promise<{
    projectId: string;
  }>;
}

export default async function LogBuilderPage({ params }: PageProps) {
  // Verify admin access
  const user = await requireAdmin();
  
  // Await params first
  const { projectId } = await params;
  
  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="mb-8">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">
                Log Template Assignment
              </h1>
              <p className="mt-2 text-gray-600">
                Select and assign thermal log templates for this project
              </p>
            </div>
            <div className="text-sm text-gray-500">
              <p>Project ID: <span className="font-medium">{projectId}</span></p>
              <p>Admin: {user.displayName || user.email}</p>
            </div>
          </div>
        </div>
        
        {/* Template Selection */}
        <Suspense fallback={<div>Loading templates...</div>}>
          <LogBuilderClient projectId={projectId} />
        </Suspense>
      </div>
    </div>
  );
}