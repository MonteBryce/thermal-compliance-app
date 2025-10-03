'use client';

import { useEffect, useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { Button } from '@/components/ui/button';
import { Calendar, CheckCircle, AlertTriangle, RefreshCw } from 'lucide-react';
// import { fetchDailySchedule, ScheduleItem } from '../actions/fetchDailySchedule';
import { formatHour } from '@/lib/compliance-utils';

interface ScheduleItem {
  operatorId: string;
  operatorName: string;
  projectId: string;
  facility: string;
  role: string;
  lastLoggedHour?: number;
  status: 'active' | 'missing';
}

// Mock data for demonstration
const mockSchedule: ScheduleItem[] = [
  {
    operatorId: 'john.doe',
    operatorName: 'John Doe',
    projectId: 'PROJ-001',
    facility: 'Tank Farm Alpha',
    role: 'Lead Operator',
    lastLoggedHour: new Date().getHours() - 1,
    status: 'active',
  },
  {
    operatorId: 'jane.smith',
    operatorName: 'Jane Smith',
    projectId: 'PROJ-001',
    facility: 'Tank Farm Alpha',
    role: 'Assistant Operator',
    lastLoggedHour: new Date().getHours(),
    status: 'active',
  },
  {
    operatorId: 'mike.wilson',
    operatorName: 'Mike Wilson',
    projectId: 'PROJ-002',
    facility: 'Tank Farm Beta',
    role: 'Solo Operator',
    lastLoggedHour: new Date().getHours() - 3,
    status: 'missing',
  },
  {
    operatorId: 'sarah.jones',
    operatorName: 'Sarah Jones',
    projectId: 'PROJ-003',
    facility: 'Tank Farm Gamma',
    role: 'Lead Operator',
    lastLoggedHour: new Date().getHours() - 1,
    status: 'active',
  },
];

interface DailyScheduleCardProps {
  onStatusChange?: (status: 'red' | 'amber' | 'green', delta: number) => void;
}

export function DailyScheduleCard({ onStatusChange }: DailyScheduleCardProps) {
  const [schedule, setSchedule] = useState<ScheduleItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedDate, setSelectedDate] = useState(new Date());

  const loadSchedule = async () => {
    try {
      setLoading(true);
      setError(null);
      
      // Simulate loading delay
      await new Promise(resolve => setTimeout(resolve, 300));
      
      setSchedule(mockSchedule);
      
      // Update status counts
      if (onStatusChange) {
        const missingCount = mockSchedule.filter(item => item.status === 'missing').length;
        if (missingCount > 0) {
          onStatusChange('amber', missingCount);
        }
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load schedule');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadSchedule();
    // Refresh every 5 minutes
    const interval = setInterval(loadSchedule, 5 * 60 * 1000);
    return () => clearInterval(interval);
  }, [selectedDate]);

  const getStatusIcon = (item: ScheduleItem) => {
    if (item.status === 'active') {
      return <CheckCircle className="h-4 w-4 text-green-500" />;
    } else {
      return <AlertTriangle className="h-4 w-4 text-amber-500" />;
    }
  };

  const getLastLoggedDisplay = (item: ScheduleItem) => {
    if (item.lastLoggedHour !== undefined) {
      return (
        <span className="text-sm">
          Last: {formatHour(item.lastLoggedHour)}
        </span>
      );
    }
    return <span className="text-sm text-muted-foreground">No logs today</span>;
  };

  return (
    <Card className="col-span-1">
      <CardHeader className="flex flex-row items-center justify-between">
        <CardTitle className="flex items-center gap-2">
          <Calendar className="h-5 w-5" />
          Daily Schedule
          <Badge variant="secondary">
            {selectedDate.toLocaleDateString()}
          </Badge>
        </CardTitle>
        <div className="flex gap-2">
          <Button
            variant="ghost"
            size="icon"
            onClick={loadSchedule}
            disabled={loading}
          >
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          </Button>
        </div>
      </CardHeader>
      <CardContent>
        {error && (
          <div className="text-destructive text-sm mb-4">{error}</div>
        )}
        
        <div className="mb-4 flex gap-2">
          <Badge variant="outline" className="text-xs">
            <CheckCircle className="h-3 w-3 mr-1 text-green-500" />
            Active: {schedule.filter(s => s.status === 'active').length}
          </Badge>
          <Badge variant="outline" className="text-xs">
            <AlertTriangle className="h-3 w-3 mr-1 text-amber-500" />
            Missing: {schedule.filter(s => s.status === 'missing').length}
          </Badge>
        </div>
        
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Status</TableHead>
              <TableHead>Operator</TableHead>
              <TableHead>Assignment</TableHead>
              <TableHead>Role</TableHead>
              <TableHead>Last Logged</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {schedule.map((item, idx) => (
              <TableRow key={`${item.operatorId}-${idx}`}>
                <TableCell>{getStatusIcon(item)}</TableCell>
                <TableCell className="font-medium">
                  {item.operatorName}
                </TableCell>
                <TableCell>
                  <div>
                    <div className="font-medium">{item.facility}</div>
                    <div className="text-xs text-muted-foreground">
                      {item.projectId}
                    </div>
                  </div>
                </TableCell>
                <TableCell>
                  <Badge variant="outline">{item.role}</Badge>
                </TableCell>
                <TableCell>{getLastLoggedDisplay(item)}</TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
        
        {schedule.length === 0 && !loading && (
          <div className="text-center py-8 text-muted-foreground">
            No schedule found for today
          </div>
        )}
      </CardContent>
    </Card>
  );
}