'use client';

import { useEffect, useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Switch } from '@/components/ui/switch';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { AlertTriangle, Clock, RefreshCw } from 'lucide-react';
// import { detectMissingEntries, markEntryNotRequired, MissingEntry } from '../actions/detectMissingEntries';
import { formatHour } from '@/lib/compliance-utils';

interface MissingEntry {
  hour: number;
  timeString: string;
  isRequired: boolean;
  reason?: string;
}

// Mock missing entries for demonstration
const generateMockMissingEntries = (jobId: string): MissingEntry[] => {
  if (jobId === 'PROJ-001') {
    return [
      { hour: 0, timeString: '00:00', isRequired: true },
      { hour: 1, timeString: '01:00', isRequired: true },
      { hour: 2, timeString: '02:00', isRequired: false, reason: 'Planned maintenance' },
      { hour: 3, timeString: '03:00', isRequired: false, reason: 'Planned maintenance' },
      { hour: 4, timeString: '04:00', isRequired: true },
      { hour: 5, timeString: '05:00', isRequired: true },
    ];
  } else if (jobId === 'PROJ-002') {
    return [
      { hour: 0, timeString: '00:00', isRequired: true },
      { hour: 1, timeString: '01:00', isRequired: true },
    ];
  }
  return [];
};

interface MissingEntriesCardProps {
  jobId?: string | null;
  onStatusChange?: (status: 'red' | 'amber' | 'green', delta: number) => void;
}

export function MissingEntriesCard({ jobId, onStatusChange }: MissingEntriesCardProps) {
  const [missingEntries, setMissingEntries] = useState<MissingEntry[]>([]);
  const [totalExpected, setTotalExpected] = useState(24);
  const [totalFound, setTotalFound] = useState(0);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [selectedDate, setSelectedDate] = useState(new Date());
  const [markingNotRequired, setMarkingNotRequired] = useState<number | null>(null);
  const [reason, setReason] = useState('');

  const loadMissingEntries = async () => {
    if (!jobId) return;
    
    try {
      setLoading(true);
      setError(null);
      
      // Simulate loading delay
      await new Promise(resolve => setTimeout(resolve, 400));
      
      const mockEntries = generateMockMissingEntries(jobId);
      setMissingEntries(mockEntries);
      setTotalExpected(24);
      setTotalFound(24 - mockEntries.length);
      
      // Update status count
      if (onStatusChange) {
        const criticalMissing = mockEntries.filter(e => e.isRequired).length;
        if (criticalMissing > 0) {
          onStatusChange('red', 1);
        }
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to detect missing entries');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadMissingEntries();
  }, [jobId, selectedDate]);

  const handleMarkNotRequired = async () => {
    if (!jobId || markingNotRequired === null || !reason.trim()) return;
    
    try {
      const [projectId, logId] = jobId.split('-');
      await markEntryNotRequired(projectId, logId, markingNotRequired, reason.trim());
      setMarkingNotRequired(null);
      setReason('');
      loadMissingEntries();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to mark entry as not required');
    }
  };

  const requiredMissing = missingEntries.filter(e => e.isRequired);
  const plannedMissing = missingEntries.filter(e => !e.isRequired);

  return (
    <Card className="col-span-1">
      <CardHeader className="flex flex-row items-center justify-between">
        <CardTitle className="flex items-center gap-2">
          <Clock className="h-5 w-5" />
          Missing Entries
          {requiredMissing.length > 0 && (
            <Badge variant="destructive">{requiredMissing.length}</Badge>
          )}
        </CardTitle>
        <Button
          variant="ghost"
          size="icon"
          onClick={loadMissingEntries}
          disabled={loading}
        >
          <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
        </Button>
      </CardHeader>
      <CardContent>
        {!jobId && (
          <div className="text-center py-8 text-muted-foreground">
            Select a job to view missing entries
          </div>
        )}
        
        {jobId && (
          <>
            {error && (
              <div className="text-destructive text-sm mb-4">{error}</div>
            )}
            
            <div className="mb-4 flex items-center justify-between">
              <div className="text-sm text-muted-foreground">
                {totalFound}/{totalExpected} hours logged
              </div>
              <input
                type="date"
                value={selectedDate.toISOString().split('T')[0]}
                onChange={(e) => setSelectedDate(new Date(e.target.value))}
                className="text-sm border rounded px-2 py-1"
              />
            </div>
            
            {requiredMissing.length > 0 && (
              <div className="mb-4">
                <div className="flex items-center gap-2 mb-2">
                  <AlertTriangle className="h-4 w-4 text-destructive" />
                  <span className="text-sm font-medium text-destructive">
                    Critical Missing Entries
                  </span>
                </div>
                <div className="grid grid-cols-6 gap-1">
                  {requiredMissing.map(entry => (
                    <Dialog key={entry.hour}>
                      <DialogTrigger asChild>
                        <Button
                          variant="destructive"
                          size="sm"
                          className="h-8 text-xs"
                          onClick={() => setMarkingNotRequired(entry.hour)}
                        >
                          {formatHour(entry.hour)}
                        </Button>
                      </DialogTrigger>
                      <DialogContent>
                        <DialogHeader>
                          <DialogTitle>Mark Entry as Not Required</DialogTitle>
                          <DialogDescription>
                            Mark the {formatHour(entry.hour)} entry as not required (e.g., planned downtime).
                          </DialogDescription>
                        </DialogHeader>
                        <div className="space-y-4">
                          <div>
                            <Label htmlFor="reason">Reason</Label>
                            <Input
                              id="reason"
                              placeholder="e.g., Planned maintenance, Equipment shutdown"
                              value={reason}
                              onChange={(e) => setReason(e.target.value)}
                            />
                          </div>
                        </div>
                        <DialogFooter>
                          <Button variant="outline" onClick={() => setMarkingNotRequired(null)}>
                            Cancel
                          </Button>
                          <Button onClick={handleMarkNotRequired} disabled={!reason.trim()}>
                            Mark Not Required
                          </Button>
                        </DialogFooter>
                      </DialogContent>
                    </Dialog>
                  ))}
                </div>
              </div>
            )}
            
            {plannedMissing.length > 0 && (
              <div className="mb-4">
                <div className="flex items-center gap-2 mb-2">
                  <span className="text-sm font-medium text-muted-foreground">
                    Planned Downtime
                  </span>
                </div>
                <div className="grid grid-cols-6 gap-1">
                  {plannedMissing.map(entry => (
                    <div
                      key={entry.hour}
                      className="bg-muted text-muted-foreground rounded text-xs p-1 text-center"
                      title={entry.reason}
                    >
                      {formatHour(entry.hour)}
                    </div>
                  ))}
                </div>
              </div>
            )}
            
            {missingEntries.length === 0 && !loading && (
              <div className="text-center py-8 text-green-600">
                ✓ All entries complete
              </div>
            )}
          </>
        )}
      </CardContent>
    </Card>
  );
}