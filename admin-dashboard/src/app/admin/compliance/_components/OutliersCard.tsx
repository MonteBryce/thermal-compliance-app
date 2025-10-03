'use client';

import { useEffect, useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { TrendingUp, RefreshCw, Settings } from 'lucide-react';
import { detectOutliers, OutlierResult } from '../actions/detectOutliers';
import { formatHour } from '@/lib/compliance-utils';

interface OutliersCardProps {
  jobId?: string | null;
  onStatusChange?: (status: 'red' | 'amber' | 'green', delta: number) => void;
}

export function OutliersCard({ jobId, onStatusChange }: OutliersCardProps) {
  const [outliers, setOutliers] = useState<OutlierResult[]>([]);
  const [entriesAnalyzed, setEntriesAnalyzed] = useState(0);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [selectedDate, setSelectedDate] = useState(new Date());

  const loadOutliers = async () => {
    if (!jobId) return;
    
    try {
      setLoading(true);
      setError(null);
      
      // Extract projectId and logId from jobId
      const [projectId, logId] = jobId.split('-');
      
      const result = await detectOutliers(projectId, logId, selectedDate);
      setOutliers(result.outliers);
      setEntriesAnalyzed(result.entriesAnalyzed);
      
      // Update status count based on recent outliers
      if (onStatusChange) {
        const recentOutliers = result.outliers.filter(o => {
          const currentHour = new Date().getHours();
          return Math.abs(currentHour - o.hour) <= 6;
        });
        
        if (recentOutliers.length > 0) {
          onStatusChange('amber', 1);
        }
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to detect outliers');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadOutliers();
  }, [jobId, selectedDate]);

  const getSeverityBadge = (severity: 'low' | 'medium' | 'high') => {
    switch (severity) {
      case 'high':
        return <Badge variant="destructive">High</Badge>;
      case 'medium':
        return <Badge className="bg-amber-500">Medium</Badge>;
      case 'low':
        return <Badge variant="outline">Low</Badge>;
    }
  };

  const formatChange = (outlier: OutlierResult) => {
    if (outlier.metric === 'Flow Rate') {
      return `${outlier.change.toFixed(1)}%`;
    }
    return `${outlier.change.toFixed(1)} ${getMetricUnit(outlier.metric)}`;
  };

  const getMetricUnit = (metric: string) => {
    switch (metric) {
      case 'Exhaust Temperature':
        return '°F';
      case 'H2S':
      case 'Benzene':
        return 'ppm';
      case 'Flow Rate':
        return '%';
      default:
        return '';
    }
  };

  return (
    <Card className="col-span-1">
      <CardHeader className="flex flex-row items-center justify-between">
        <CardTitle className="flex items-center gap-2">
          <TrendingUp className="h-5 w-5" />
          Outliers
          {outliers.length > 0 && (
            <Badge variant="secondary">{outliers.length}</Badge>
          )}
        </CardTitle>
        <div className="flex gap-2">
          <Button variant="ghost" size="icon">
            <Settings className="h-4 w-4" />
          </Button>
          <Button
            variant="ghost"
            size="icon"
            onClick={loadOutliers}
            disabled={loading}
          >
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          </Button>
        </div>
      </CardHeader>
      <CardContent>
        {!jobId && (
          <div className="text-center py-8 text-muted-foreground">
            Select a job to detect outliers
          </div>
        )}
        
        {jobId && (
          <>
            {error && (
              <div className="text-destructive text-sm mb-4">{error}</div>
            )}
            
            <div className="mb-4 flex items-center justify-between">
              <div className="text-sm text-muted-foreground">
                {entriesAnalyzed} entries analyzed
              </div>
              <input
                type="date"
                value={selectedDate.toISOString().split('T')[0]}
                onChange={(e) => setSelectedDate(new Date(e.target.value))}
                className="text-sm border rounded px-2 py-1"
              />
            </div>
            
            {outliers.length > 0 ? (
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Time</TableHead>
                    <TableHead>Metric</TableHead>
                    <TableHead>Change</TableHead>
                    <TableHead>Values</TableHead>
                    <TableHead>Severity</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {outliers.map((outlier, idx) => (
                    <TableRow key={idx}>
                      <TableCell className="font-mono">
                        {formatHour(outlier.hour)}
                      </TableCell>
                      <TableCell>{outlier.metric}</TableCell>
                      <TableCell>
                        <span className="font-medium">
                          {formatChange(outlier)}
                        </span>
                      </TableCell>
                      <TableCell>
                        <div className="text-xs space-y-1">
                          <div>
                            Prev: {outlier.previousValue.toFixed(1)} {getMetricUnit(outlier.metric)}
                          </div>
                          <div>
                            Curr: {outlier.currentValue.toFixed(1)} {getMetricUnit(outlier.metric)}
                          </div>
                        </div>
                      </TableCell>
                      <TableCell>{getSeverityBadge(outlier.severity)}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            ) : (
              !loading && (
                <div className="text-center py-8 text-green-600">
                  ✓ No outliers detected
                </div>
              )
            )}
          </>
        )}
      </CardContent>
    </Card>
  );
}