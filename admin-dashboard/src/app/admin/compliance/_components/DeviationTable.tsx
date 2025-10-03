'use client';

import { useEffect, useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
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
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { AlertTriangle, Plus, ExternalLink, Edit } from 'lucide-react';
import { Deviation } from '@/lib/compliance-utils';
import { formatDistanceToNow } from 'date-fns';

interface DeviationTableProps {
  jobId?: string | null;
  onStatusChange?: (status: 'red' | 'amber' | 'green', delta: number) => void;
}

export function DeviationTable({ jobId, onStatusChange }: DeviationTableProps) {
  const [deviations, setDeviations] = useState<Deviation[]>([]);
  const [loading, setLoading] = useState(false);
  const [filteredDeviations, setFilteredDeviations] = useState<Deviation[]>([]);
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [typeFilter, setTypeFilter] = useState<string>('all');
  const [facilityFilter, setFacilityFilter] = useState<string>('all');
  
  // New deviation dialog state
  const [showNewDialog, setShowNewDialog] = useState(false);
  const [newDeviation, setNewDeviation] = useState({
    type: '',
    description: '',
    cause: '',
    facility: '',
  });

  const mockDeviations: Deviation[] = [
    {
      id: 'dev-001',
      projectId: 'PROJ-001',
      logId: 'LOG-001',
      facility: 'Tank Farm Alpha',
      dateTime: new Date(Date.now() - 2 * 60 * 60 * 1000), // 2 hours ago
      type: 'outlier',
      description: 'Sudden temperature spike detected at hour 14',
      cause: 'Equipment malfunction - faulty thermocouple',
      status: 'open',
      assignedTo: 'john.doe@company.com',
      evidenceUrls: ['https://example.com/evidence1.jpg'],
      createdBy: 'system',
      createdAt: new Date(Date.now() - 2 * 60 * 60 * 1000),
      updatedAt: new Date(Date.now() - 1 * 60 * 60 * 1000),
    },
    {
      id: 'dev-002',
      projectId: 'PROJ-002',
      logId: 'LOG-002',
      facility: 'Tank Farm Beta',
      dateTime: new Date(Date.now() - 25 * 60 * 60 * 1000), // 25 hours ago
      type: 'missing_entry',
      description: 'Missing hourly readings for hours 8-12',
      cause: 'Operator illness - replacement not immediately available',
      status: 'open',
      assignedTo: 'jane.smith@company.com',
      evidenceUrls: [],
      createdBy: 'admin',
      createdAt: new Date(Date.now() - 25 * 60 * 60 * 1000),
      updatedAt: new Date(Date.now() - 20 * 60 * 60 * 1000),
    },
    {
      id: 'dev-003',
      projectId: 'PROJ-001',
      logId: 'LOG-003',
      facility: 'Tank Farm Alpha',
      dateTime: new Date(Date.now() - 48 * 60 * 60 * 1000), // 2 days ago
      type: 'limit_exceeded',
      description: 'H2S levels exceeded permit limit',
      cause: 'Process upset during startup procedure',
      status: 'closed',
      assignedTo: 'bob.wilson@company.com',
      evidenceUrls: ['https://example.com/corrective-action.pdf'],
      createdBy: 'operator',
      createdAt: new Date(Date.now() - 48 * 60 * 60 * 1000),
      updatedAt: new Date(Date.now() - 24 * 60 * 60 * 1000),
    },
  ];

  useEffect(() => {
    if (jobId) {
      setDeviations(mockDeviations);
      
      // Calculate status impact
      const openDeviations = mockDeviations.filter(d => d.status === 'open');
      const criticalDeviations = openDeviations.filter(d => {
        const hoursAgo = (Date.now() - d.createdAt.getTime()) / (1000 * 60 * 60);
        return hoursAgo > 24 || d.type === 'limit_exceeded';
      });
      
      if (criticalDeviations.length > 0) {
        onStatusChange?.('red', criticalDeviations.length);
      } else if (openDeviations.length > 0) {
        onStatusChange?.('amber', openDeviations.length);
      }
    }
  }, [jobId]);

  useEffect(() => {
    let filtered = deviations;
    
    if (statusFilter !== 'all') {
      filtered = filtered.filter(d => d.status === statusFilter);
    }
    
    if (typeFilter !== 'all') {
      filtered = filtered.filter(d => d.type === typeFilter);
    }
    
    if (facilityFilter !== 'all') {
      filtered = filtered.filter(d => d.facility === facilityFilter);
    }
    
    setFilteredDeviations(filtered);
  }, [deviations, statusFilter, typeFilter, facilityFilter]);

  const getStatusBadge = (status: Deviation['status']) => {
    return status === 'open' 
      ? <Badge variant="destructive">Open</Badge>
      : <Badge variant="outline">Closed</Badge>;
  };

  const getTypeBadge = (type: Deviation['type']) => {
    const colors = {
      outlier: 'bg-amber-500',
      missing_entry: 'bg-blue-500',
      limit_exceeded: 'bg-red-500',
      equipment: 'bg-purple-500',
      other: 'bg-gray-500',
    };
    
    return (
      <Badge className={colors[type]}>
        {type.replace('_', ' ').toUpperCase()}
      </Badge>
    );
  };

  const toggleDeviationStatus = (deviationId: string) => {
    setDeviations(prev => prev.map(d => 
      d.id === deviationId 
        ? { ...d, status: d.status === 'open' ? 'closed' : 'open', updatedAt: new Date() }
        : d
    ));
  };

  const createNewDeviation = () => {
    if (!newDeviation.type || !newDeviation.description || !newDeviation.facility) return;
    
    const deviation: Deviation = {
      id: `dev-${Date.now()}`,
      projectId: jobId?.split('-')[0] || 'PROJ-001',
      logId: jobId?.split('-')[1] || 'LOG-001',
      facility: newDeviation.facility,
      dateTime: new Date(),
      type: newDeviation.type as Deviation['type'],
      description: newDeviation.description,
      cause: newDeviation.cause,
      status: 'open',
      evidenceUrls: [],
      createdBy: 'admin',
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    
    setDeviations(prev => [deviation, ...prev]);
    setNewDeviation({ type: '', description: '', cause: '', facility: '' });
    setShowNewDialog(false);
  };

  const facilities = Array.from(new Set(deviations.map(d => d.facility)));
  const types = Array.from(new Set(deviations.map(d => d.type)));

  return (
    <Card className="col-span-1">
      <CardHeader className="flex flex-row items-center justify-between">
        <CardTitle className="flex items-center gap-2">
          <AlertTriangle className="h-5 w-5" />
          Deviations
          <Badge variant="secondary">{filteredDeviations.length}</Badge>
        </CardTitle>
        <Dialog open={showNewDialog} onOpenChange={setShowNewDialog}>
          <DialogTrigger asChild>
            <Button size="sm">
              <Plus className="h-4 w-4 mr-1" />
              New Deviation
            </Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Create New Deviation</DialogTitle>
              <DialogDescription>
                Record a new deviation or non-conformance event.
              </DialogDescription>
            </DialogHeader>
            <div className="space-y-4">
              <div>
                <label className="text-sm font-medium">Type</label>
                <Select value={newDeviation.type} onValueChange={(value) => 
                  setNewDeviation(prev => ({ ...prev, type: value }))
                }>
                  <SelectTrigger>
                    <SelectValue placeholder="Select deviation type" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="outlier">Outlier</SelectItem>
                    <SelectItem value="missing_entry">Missing Entry</SelectItem>
                    <SelectItem value="limit_exceeded">Limit Exceeded</SelectItem>
                    <SelectItem value="equipment">Equipment</SelectItem>
                    <SelectItem value="other">Other</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div>
                <label className="text-sm font-medium">Facility</label>
                <Input
                  placeholder="e.g., Tank Farm Alpha"
                  value={newDeviation.facility}
                  onChange={(e) => setNewDeviation(prev => ({ ...prev, facility: e.target.value }))}
                />
              </div>
              <div>
                <label className="text-sm font-medium">Description</label>
                <Textarea
                  placeholder="Describe what happened..."
                  value={newDeviation.description}
                  onChange={(e) => setNewDeviation(prev => ({ ...prev, description: e.target.value }))}
                  rows={3}
                />
              </div>
              <div>
                <label className="text-sm font-medium">Cause (Optional)</label>
                <Textarea
                  placeholder="What caused this deviation?"
                  value={newDeviation.cause}
                  onChange={(e) => setNewDeviation(prev => ({ ...prev, cause: e.target.value }))}
                  rows={2}
                />
              </div>
            </div>
            <DialogFooter>
              <Button variant="outline" onClick={() => setShowNewDialog(false)}>
                Cancel
              </Button>
              <Button onClick={createNewDeviation}>
                Create Deviation
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      </CardHeader>
      <CardContent>
        {!jobId && (
          <div className="text-center py-8 text-muted-foreground">
            Select a job to view deviations
          </div>
        )}
        
        {jobId && (
          <>
            {/* Filters */}
            <div className="flex gap-2 mb-4">
              <Select value={statusFilter} onValueChange={setStatusFilter}>
                <SelectTrigger className="w-32">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Status</SelectItem>
                  <SelectItem value="open">Open</SelectItem>
                  <SelectItem value="closed">Closed</SelectItem>
                </SelectContent>
              </Select>
              
              <Select value={typeFilter} onValueChange={setTypeFilter}>
                <SelectTrigger className="w-40">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Types</SelectItem>
                  {types.map(type => (
                    <SelectItem key={type} value={type}>
                      {type.replace('_', ' ')}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              
              <Select value={facilityFilter} onValueChange={setFacilityFilter}>
                <SelectTrigger className="w-40">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Facilities</SelectItem>
                  {facilities.map(facility => (
                    <SelectItem key={facility} value={facility}>
                      {facility}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            
            {/* Table */}
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Date/Time</TableHead>
                  <TableHead>Type</TableHead>
                  <TableHead>Description</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Age</TableHead>
                  <TableHead>Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredDeviations.map(deviation => (
                  <TableRow key={deviation.id}>
                    <TableCell>
                      <div className="text-sm">
                        <div>{deviation.dateTime.toLocaleDateString()}</div>
                        <div className="text-muted-foreground">
                          {deviation.dateTime.toLocaleTimeString()}
                        </div>
                      </div>
                    </TableCell>
                    <TableCell>{getTypeBadge(deviation.type)}</TableCell>
                    <TableCell>
                      <div className="max-w-xs">
                        <div className="text-sm">{deviation.description}</div>
                        <div className="text-xs text-muted-foreground">
                          {deviation.facility}
                        </div>
                      </div>
                    </TableCell>
                    <TableCell>{getStatusBadge(deviation.status)}</TableCell>
                    <TableCell className="text-sm text-muted-foreground">
                      {formatDistanceToNow(deviation.createdAt, { addSuffix: true })}
                    </TableCell>
                    <TableCell>
                      <div className="flex gap-1">
                        <Button
                          size="sm"
                          variant="outline"
                          onClick={() => toggleDeviationStatus(deviation.id)}
                        >
                          {deviation.status === 'open' ? 'Close' : 'Reopen'}
                        </Button>
                        {deviation.evidenceUrls.length > 0 && (
                          <Button size="sm" variant="ghost">
                            <ExternalLink className="h-3 w-3" />
                          </Button>
                        )}
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
            
            {filteredDeviations.length === 0 && (
              <div className="text-center py-8 text-muted-foreground">
                No deviations found
              </div>
            )}
          </>
        )}
      </CardContent>
    </Card>
  );
}