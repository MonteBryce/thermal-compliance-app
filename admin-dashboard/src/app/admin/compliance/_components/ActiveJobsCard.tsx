'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { Button } from '@/components/ui/button';
import { ChevronRight, RefreshCw, AlertCircle, Settings, FileText, Smartphone, Zap } from 'lucide-react';
// import { fetchActiveJobs } from '../actions/fetchActiveJobs';
import { ActiveJob, calculateProgress, determineUrgencyStatus } from '@/lib/compliance-utils';
import { formatDistanceToNow } from 'date-fns';

// Mock data for demonstration
const mockJobs: ActiveJob[] = [
  {
    id: 'PROJ-001',
    projectId: 'PROJ-001',
    facility: 'Tank Farm Alpha',
    tankId: 'TANK-A1',
    logType: 'H2S',
    assignedOperators: ['john.doe', 'jane.smith'],
    startDate: new Date(Date.now() - 8 * 60 * 60 * 1000),
    expectedHours: 24,
    completedHours: 18,
    lastEntryTimestamp: new Date(Date.now() - 30 * 60 * 1000),
    templateConfig: {
      hasExcelTemplate: true,
      templateId: 'texas_methane_h2s_benzene',
      templateName: 'Texas Methane H2S & Benzene',
      autoExportEnabled: true,
      logType: 'thermal',
    },
  },
  {
    id: 'PROJ-002',
    projectId: 'PROJ-002',
    facility: 'Tank Farm Beta',
    tankId: 'TANK-B2',
    logType: 'Combined',
    assignedOperators: ['mike.wilson'],
    startDate: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
    expectedHours: 24,
    completedHours: 22,
    lastEntryTimestamp: new Date(Date.now() - 2 * 60 * 60 * 1000),
    templateConfig: {
      hasExcelTemplate: false,
      logType: 'thermal',
    },
  },
  {
    id: 'PROJ-003',
    projectId: 'PROJ-003',
    facility: 'Tank Farm Gamma',
    tankId: 'TANK-C3',
    logType: 'Benzene',
    assignedOperators: ['sarah.jones'],
    startDate: new Date(Date.now() - 4 * 60 * 60 * 1000),
    expectedHours: 24,
    completedHours: 8,
    lastEntryTimestamp: new Date(Date.now() - 4 * 60 * 60 * 1000),
    templateConfig: {
      hasExcelTemplate: true,
      templateId: 'texas_pentane_h2s_benzene',
      templateName: 'Texas Pentane H2S & Benzene',
      autoExportEnabled: false,
      logType: 'thermal',
    },
  },
];

interface ActiveJobsCardProps {
  selectedJobId?: string | null;
  onStatusChange?: (status: 'red' | 'amber' | 'green', delta: number) => void;
  onJobSelect?: (job: ActiveJob | null) => void;
}

export function ActiveJobsCard({ selectedJobId, onStatusChange, onJobSelect }: ActiveJobsCardProps) {
  const router = useRouter();
  const [jobs, setJobs] = useState<ActiveJob[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [hasMore, setHasMore] = useState(false);
  const [lastDoc, setLastDoc] = useState<string | undefined>();

  const loadJobs = async (startAfter?: string) => {
    try {
      setLoading(true);
      setError(null);
      
      // Simulate loading delay
      await new Promise(resolve => setTimeout(resolve, 500));
      
      if (startAfter) {
        // For demo, don't add more jobs
        setHasMore(false);
      } else {
        setJobs(mockJobs);
      }
      
      setHasMore(false);
      setLastDoc(undefined);
      
      // Calculate status counts
      if (onStatusChange && !startAfter) {
        mockJobs.forEach(job => {
          const hoursAgo = job.lastEntryTimestamp 
            ? (Date.now() - job.lastEntryTimestamp.getTime()) / (1000 * 60 * 60)
            : 24;
          
          const status = determineUrgencyStatus({
            hasMissingEntries: job.completedHours < job.expectedHours,
            missingEntriesAge: hoursAgo,
          });
          
          onStatusChange(status, 1);
        });
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load jobs');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadJobs();
  }, []);

  const handleJobClick = (jobId: string) => {
    const job = jobs.find(j => j.id === jobId);
    if (onJobSelect && job) {
      onJobSelect(job);
    }
    router.push(`/admin/compliance?jobId=${jobId}`);
  };

  const handleLogBuilder = (jobId: string, event: React.MouseEvent) => {
    event.stopPropagation();
    router.push(`/admin/compliance/log-builder?projectId=${jobId}`);
  };

  const getStatusBadge = (job: ActiveJob) => {
    const progress = calculateProgress(job.completedHours, job.expectedHours);
    const hoursAgo = job.lastEntryTimestamp 
      ? (Date.now() - job.lastEntryTimestamp.getTime()) / (1000 * 60 * 60)
      : 24;

    if (hoursAgo > 2) {
      return <Badge variant="destructive">Missing Entries</Badge>;
    } else if (progress < 80) {
      return <Badge className="bg-amber-500">Behind Schedule</Badge>;
    } else {
      return <Badge variant="outline" className="border-green-500">On Track</Badge>;
    }
  };

  const getTemplateIndicator = (job: ActiveJob) => {
    if (!job.templateConfig?.hasExcelTemplate) {
      return (
        <div className="flex items-center gap-1.5 text-blue-600">
          <Smartphone className="h-3.5 w-3.5" />
          <span className="text-xs font-medium">Flutter</span>
        </div>
      );
    }

    return (
      <div className="flex items-center gap-1.5 text-green-600">
        <FileText className="h-3.5 w-3.5" />
        <span className="text-xs font-medium">Excel</span>
        {job.templateConfig.autoExportEnabled && (
          <Zap className="h-3 w-3 text-amber-500" />
        )}
      </div>
    );
  };

  return (
    <Card className="col-span-1">
      <CardHeader className="flex flex-row items-center justify-between">
        <CardTitle className="flex items-center gap-2">
          Active Jobs
          <Badge variant="secondary">{jobs.length}</Badge>
        </CardTitle>
        <Button
          variant="ghost"
          size="icon"
          onClick={() => loadJobs()}
          disabled={loading}
        >
          <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
        </Button>
      </CardHeader>
      <CardContent>
        {error && (
          <div className="flex items-center gap-2 text-destructive mb-4">
            <AlertCircle className="h-4 w-4" />
            <span className="text-sm">{error}</span>
          </div>
        )}
        
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Project</TableHead>
              <TableHead>Facility/Tank</TableHead>
              <TableHead>Type</TableHead>
              <TableHead>Template</TableHead>
              <TableHead>Progress</TableHead>
              <TableHead>Last Entry</TableHead>
              <TableHead>Status</TableHead>
              <TableHead className="w-40">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {jobs.map(job => (
              <TableRow
                key={job.id}
                className={`cursor-pointer hover:bg-muted/50 ${
                  selectedJobId === job.id ? 'bg-muted' : ''
                }`}
                onClick={() => handleJobClick(job.id)}
              >
                <TableCell className="font-medium">{job.projectId}</TableCell>
                <TableCell>
                  <div>
                    <div className="font-medium">{job.facility}</div>
                    <div className="text-sm text-muted-foreground">{job.tankId}</div>
                  </div>
                </TableCell>
                <TableCell>{job.logType}</TableCell>
                <TableCell>
                  <div className="flex flex-col gap-1">
                    {getTemplateIndicator(job)}
                    {job.templateConfig?.hasExcelTemplate && job.templateConfig.templateName && (
                      <div className="text-xs text-muted-foreground max-w-[120px] truncate" title={job.templateConfig.templateName}>
                        {job.templateConfig.templateName}
                      </div>
                    )}
                  </div>
                </TableCell>
                <TableCell>
                  <div className="space-y-1">
                    <Progress value={calculateProgress(job.completedHours, job.expectedHours)} />
                    <div className="text-xs text-muted-foreground">
                      {job.completedHours}/{job.expectedHours} hrs
                    </div>
                  </div>
                </TableCell>
                <TableCell>
                  {job.lastEntryTimestamp ? (
                    <span className="text-sm">
                      {formatDistanceToNow(job.lastEntryTimestamp, { addSuffix: true })}
                    </span>
                  ) : (
                    <span className="text-sm text-muted-foreground">No entries</span>
                  )}
                </TableCell>
                <TableCell>{getStatusBadge(job)}</TableCell>
                <TableCell>
                  <div className="flex items-center gap-2">
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={(e) => handleLogBuilder(job.id, e)}
                      title="Edit Log Entries"
                      className="h-8 px-3"
                    >
                      <Settings className="h-4 w-4 mr-1" />
                      Edit Logs
                    </Button>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => handleJobClick(job.id)}
                      title="View Details"
                    >
                      <ChevronRight className="h-4 w-4" />
                    </Button>
                  </div>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
        
        {hasMore && (
          <div className="mt-4 flex justify-center">
            <Button
              variant="outline"
              onClick={() => loadJobs(lastDoc)}
              disabled={loading}
            >
              Load More
            </Button>
          </div>
        )}
        
        {jobs.length === 0 && !loading && (
          <div className="text-center py-8 text-muted-foreground">
            No active jobs found
          </div>
        )}
      </CardContent>
    </Card>
  );
}