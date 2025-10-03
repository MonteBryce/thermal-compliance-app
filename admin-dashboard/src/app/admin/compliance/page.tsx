'use client';

import { useEffect, useState, lazy, Suspense } from 'react';
import { useSearchParams } from 'next/navigation';
import { LazyWrapper } from '@/components/lazy/lazy-wrapper';

const ActiveJobsCard = lazy(() => import('./_components/ActiveJobsCard').then(mod => ({ default: mod.ActiveJobsCard })));
const DailyScheduleCard = lazy(() => import('./_components/DailyScheduleCard').then(mod => ({ default: mod.DailyScheduleCard })));
const MissingEntriesCard = lazy(() => import('./_components/MissingEntriesCard').then(mod => ({ default: mod.MissingEntriesCard })));
const OutliersCard = lazy(() => import('./_components/OutliersCard').then(mod => ({ default: mod.OutliersCard })));
const MeterVerificationCard = lazy(() => import('./_components/MeterVerificationCard').then(mod => ({ default: mod.MeterVerificationCard })));
const PermitQuickViewCard = lazy(() => import('./_components/PermitQuickViewCard').then(mod => ({ default: mod.PermitQuickViewCard })));
const LogTypeCheckCard = lazy(() => import('./_components/LogTypeCheckCard').then(mod => ({ default: mod.LogTypeCheckCard })));
const PreJobChecklistCard = lazy(() => import('./_components/PreJobChecklistCard').then(mod => ({ default: mod.PreJobChecklistCard })));
const DeviationTable = lazy(() => import('./_components/DeviationTable').then(mod => ({ default: mod.DeviationTable })));
const EmissionsCalculatorCard = lazy(() => import('./_components/EmissionsCalculatorCard').then(mod => ({ default: mod.EmissionsCalculatorCard })));
const ReportGeneratorCard = lazy(() => import('./_components/ReportGeneratorCard').then(mod => ({ default: mod.ReportGeneratorCard })));
const AutoEmailCard = lazy(() => import('./_components/AutoEmailCard').then(mod => ({ default: mod.AutoEmailCard })));
const CommsTray = lazy(() => import('./_components/CommsTray').then(mod => ({ default: mod.CommsTray })));
const TemplateManagementCard = lazy(() => import('./_components/TemplateManagementCard').then(mod => ({ default: mod.TemplateManagementCard })));
import { Badge } from '@/components/ui/badge';
import { ActiveJob } from '@/lib/compliance-utils';

type UrgencyStatus = 'red' | 'amber' | 'green';

interface StatusCounts {
  red: number;
  amber: number;
  green: number;
}

export default function ComplianceDashboard() {
  const searchParams = useSearchParams();
  const selectedJobId = searchParams.get('jobId');
  const [statusCounts, setStatusCounts] = useState<StatusCounts>({
    red: 0,
    amber: 0,
    green: 0,
  });
  const [selectedJob, setSelectedJob] = useState<ActiveJob | null>(null);

  const updateStatus = (type: UrgencyStatus, delta: number) => {
    setStatusCounts(prev => ({
      ...prev,
      [type]: Math.max(0, prev[type] + delta),
    }));
  };

  return (
    <div className="container mx-auto p-6 space-y-6">
      {/* Header with Status Indicators */}
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-3xl font-bold">Compliance Dashboard</h1>
        <div className="flex gap-3">
          <Badge variant="destructive" className="flex items-center gap-2">
            <span className="h-2 w-2 bg-white rounded-full animate-pulse" />
            Critical: {statusCounts.red}
          </Badge>
          <Badge className="bg-amber-500 hover:bg-amber-600 flex items-center gap-2">
            <span className="h-2 w-2 bg-white rounded-full" />
            Warning: {statusCounts.amber}
          </Badge>
          <Badge variant="outline" className="border-green-500 text-green-600 flex items-center gap-2">
            <span className="h-2 w-2 bg-green-500 rounded-full" />
            Normal: {statusCounts.green}
          </Badge>
        </div>
      </div>

      {/* Row A - Tracking */}
      <div className="space-y-4">
        <h2 className="text-xl font-semibold text-muted-foreground">Tracking</h2>
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          <LazyWrapper>
            <ActiveJobsCard 
              selectedJobId={selectedJobId} 
              onStatusChange={updateStatus}
              onJobSelect={setSelectedJob}
            />
          </LazyWrapper>
          <LazyWrapper>
            <DailyScheduleCard 
              onStatusChange={updateStatus}
            />
          </LazyWrapper>
        </div>
      </div>

      {/* Row B - Templates & Configuration */}
      <div className="space-y-4">
        <h2 className="text-xl font-semibold text-muted-foreground">Templates & Configuration</h2>
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
          <LazyWrapper>
            <TemplateManagementCard 
              onStatusChange={updateStatus}
            />
          </LazyWrapper>
        </div>
      </div>

      {/* Row C - Validation & Permits */}
      <div className="space-y-4">
        <h2 className="text-xl font-semibold text-muted-foreground">Validation & Permits</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          <LazyWrapper>
            <MissingEntriesCard 
              jobId={selectedJobId}
              onStatusChange={updateStatus}
            />
          </LazyWrapper>
          <LazyWrapper>
            <OutliersCard 
              jobId={selectedJobId}
              onStatusChange={updateStatus}
            />
          </LazyWrapper>
          <LazyWrapper>
            <MeterVerificationCard 
              jobId={selectedJobId}
              onStatusChange={updateStatus}
            />
          </LazyWrapper>
          <LazyWrapper>
            <PermitQuickViewCard 
              jobId={selectedJobId}
              onStatusChange={updateStatus}
            />
          </LazyWrapper>
          <LazyWrapper>
            <LogTypeCheckCard 
              jobId={selectedJobId}
              onStatusChange={updateStatus}
            />
          </LazyWrapper>
          <LazyWrapper>
            <PreJobChecklistCard 
              jobId={selectedJobId}
              onStatusChange={updateStatus}
            />
          </LazyWrapper>
        </div>
      </div>

      {/* Row D - Deviations, Reports & Communications */}
      <div className="space-y-4">
        <h2 className="text-xl font-semibold text-muted-foreground">Deviations, Reports & Communications</h2>
        <div className="grid grid-cols-1 xl:grid-cols-2 gap-4">
          <LazyWrapper>
            <DeviationTable 
              jobId={selectedJobId}
              onStatusChange={updateStatus}
            />
          </LazyWrapper>
          <div className="space-y-4">
            <LazyWrapper>
              <EmissionsCalculatorCard 
                jobId={selectedJobId}
                onStatusChange={updateStatus}
              />
            </LazyWrapper>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <LazyWrapper>
                <ReportGeneratorCard 
                  jobId={selectedJobId}
                  selectedJob={selectedJob}
                />
              </LazyWrapper>
              <LazyWrapper>
                <AutoEmailCard 
                  jobId={selectedJobId}
                />
              </LazyWrapper>
            </div>
            <LazyWrapper>
              <CommsTray 
                jobId={selectedJobId}
              />
            </LazyWrapper>
          </div>
        </div>
      </div>
    </div>
  );
}