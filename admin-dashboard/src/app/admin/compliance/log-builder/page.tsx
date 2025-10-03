'use client';

import { useState, useEffect } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Label } from '@/components/ui/label';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
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
  Settings, 
  Plus, 
  Edit, 
  Trash2, 
  Copy, 
  Download,
  Upload,
  ArrowLeft,
  Save,
  RefreshCw,
  Eye,
  Calendar
} from 'lucide-react';

interface LogEntry {
  id: string;
  hour: number;
  date: string;
  exhaustTemp: number;
  flow: number;
  h2sPpm?: number;
  benzenePpm?: number;
  operatorId: string;
  operatorName: string;
  notes?: string;
  timestamp: Date;
  status: 'complete' | 'draft' | 'flagged';
  lastModified: Date;
  modifiedBy: string;
}

interface LogTemplate {
  id: string;
  name: string;
  logType: 'H2S' | 'Benzene' | 'Combined' | 'Temperature';
  fields: string[];
  defaultValues: Record<string, any>;
}

const mockLogTemplates: LogTemplate[] = [
  {
    id: 'h2s-standard',
    name: 'H2S Standard Monitoring',
    logType: 'H2S',
    fields: ['exhaustTemp', 'flow', 'h2sPpm'],
    defaultValues: { exhaustTemp: 650, flow: 1200, h2sPpm: 15 }
  },
  {
    id: 'benzene-standard', 
    name: 'Benzene Standard Monitoring',
    logType: 'Benzene',
    fields: ['exhaustTemp', 'flow', 'benzenePpm'],
    defaultValues: { exhaustTemp: 650, flow: 1200, benzenePpm: 5 }
  },
  {
    id: 'combined-monitoring',
    name: 'Combined H2S & Benzene',
    logType: 'Combined', 
    fields: ['exhaustTemp', 'flow', 'h2sPpm', 'benzenePpm'],
    defaultValues: { exhaustTemp: 650, flow: 1200, h2sPpm: 15, benzenePpm: 5 }
  }
];

const generateMockLogEntries = (projectId: string): LogEntry[] => {
  const entries: LogEntry[] = [];
  const today = new Date();
  const operators = ['john.doe', 'jane.smith', 'mike.wilson'];
  
  for (let hour = 8; hour <= 20; hour++) {
    entries.push({
      id: `entry-${projectId}-${hour}`,
      hour,
      date: today.toISOString().split('T')[0],
      exhaustTemp: 650 + Math.random() * 100,
      flow: 1000 + Math.random() * 500,
      h2sPpm: 10 + Math.random() * 15,
      benzenePpm: 3 + Math.random() * 7,
      operatorId: operators[Math.floor(Math.random() * operators.length)],
      operatorName: operators[Math.floor(Math.random() * operators.length)] === 'john.doe' ? 'John Doe' : 
                   operators[Math.floor(Math.random() * operators.length)] === 'jane.smith' ? 'Jane Smith' : 'Mike Wilson',
      notes: hour === 14 ? 'Temperature spike during startup' : '',
      timestamp: new Date(today.getFullYear(), today.getMonth(), today.getDate(), hour, 0),
      status: Math.random() > 0.9 ? 'flagged' : 'complete',
      lastModified: new Date(Date.now() - Math.random() * 24 * 60 * 60 * 1000),
      modifiedBy: 'admin',
    });
  }
  
  return entries;
};

export default function LogBuilderPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const projectId = searchParams.get('projectId') || 'PROJ-001';
  
  const [logEntries, setLogEntries] = useState<LogEntry[]>([]);
  const [selectedTemplate, setSelectedTemplate] = useState<LogTemplate | null>(null);
  const [editingEntry, setEditingEntry] = useState<LogEntry | null>(null);
  const [bulkMode, setBulkMode] = useState(false);
  const [selectedEntries, setSelectedEntries] = useState<string[]>([]);
  const [showNewEntryDialog, setShowNewEntryDialog] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadLogEntries();
  }, [projectId]);

  const loadLogEntries = async () => {
    setLoading(true);
    // Simulate loading
    await new Promise(resolve => setTimeout(resolve, 500));
    setLogEntries(generateMockLogEntries(projectId));
    setLoading(false);
  };

  const handleCreateEntry = (hour: number) => {
    const newEntry: LogEntry = {
      id: `new-entry-${Date.now()}`,
      hour,
      date: new Date().toISOString().split('T')[0],
      exhaustTemp: selectedTemplate?.defaultValues.exhaustTemp || 650,
      flow: selectedTemplate?.defaultValues.flow || 1200,
      h2sPpm: selectedTemplate?.defaultValues.h2sPpm,
      benzenePpm: selectedTemplate?.defaultValues.benzenePpm,
      operatorId: 'admin',
      operatorName: 'Administrator',
      notes: '',
      timestamp: new Date(),
      status: 'draft',
      lastModified: new Date(),
      modifiedBy: 'admin',
    };
    
    setEditingEntry(newEntry);
    setShowNewEntryDialog(true);
  };

  const handleSaveEntry = () => {
    if (!editingEntry) return;
    
    setLogEntries(prev => {
      const existing = prev.find(e => e.id === editingEntry.id);
      if (existing) {
        return prev.map(e => 
          e.id === editingEntry.id 
            ? { ...editingEntry, lastModified: new Date(), status: 'complete' }
            : e
        );
      } else {
        return [...prev, { ...editingEntry, status: 'complete' }].sort((a, b) => a.hour - b.hour);
      }
    });
    
    setEditingEntry(null);
    setShowNewEntryDialog(false);
  };

  const handleDeleteEntry = (entryId: string) => {
    setLogEntries(prev => prev.filter(e => e.id !== entryId));
  };

  const handleBulkDelete = () => {
    setLogEntries(prev => prev.filter(e => !selectedEntries.includes(e.id)));
    setSelectedEntries([]);
  };

  const handleCloneEntry = (entry: LogEntry) => {
    const clonedEntry: LogEntry = {
      ...entry,
      id: `cloned-${Date.now()}`,
      hour: entry.hour + 1,
      status: 'draft',
      lastModified: new Date(),
      modifiedBy: 'admin',
    };
    
    setEditingEntry(clonedEntry);
    setShowNewEntryDialog(true);
  };

  const getStatusBadge = (status: LogEntry['status']) => {
    switch (status) {
      case 'complete':
        return <Badge className="bg-green-500">Complete</Badge>;
      case 'draft':
        return <Badge className="bg-amber-500">Draft</Badge>;
      case 'flagged':
        return <Badge variant="destructive">Flagged</Badge>;
    }
  };

  const missingHours = Array.from({ length: 24 }, (_, i) => i)
    .filter(hour => !logEntries.some(entry => entry.hour === hour));

  return (
    <div className="container mx-auto p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Button variant="ghost" onClick={() => router.back()}>
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back to Dashboard
          </Button>
          <div>
            <h1 className="text-3xl font-bold">Log Builder</h1>
            <p className="text-muted-foreground">Project: {projectId}</p>
          </div>
        </div>
        
        <div className="flex gap-2">
          <Button variant="outline" onClick={loadLogEntries} disabled={loading}>
            <RefreshCw className={`h-4 w-4 mr-2 ${loading ? 'animate-spin' : ''}`} />
            Refresh
          </Button>
          <Button variant="outline">
            <Download className="h-4 w-4 mr-2" />
            Export
          </Button>
          <Button variant="outline">
            <Upload className="h-4 w-4 mr-2" />
            Import
          </Button>
        </div>
      </div>

      {/* Controls Row */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        {/* Template Selection */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Settings className="h-5 w-5" />
              Log Template
            </CardTitle>
          </CardHeader>
          <CardContent>
            <Select onValueChange={(value) => {
              const template = mockLogTemplates.find(t => t.id === value);
              setSelectedTemplate(template || null);
            }}>
              <SelectTrigger>
                <SelectValue placeholder="Select template" />
              </SelectTrigger>
              <SelectContent>
                {mockLogTemplates.map(template => (
                  <SelectItem key={template.id} value={template.id}>
                    {template.name} ({template.logType})
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
            
            {selectedTemplate && (
              <div className="mt-3 p-2 bg-muted rounded text-xs">
                <div>Fields: {selectedTemplate.fields.join(', ')}</div>
                <div>Type: {selectedTemplate.logType}</div>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Quick Actions */}
        <Card>
          <CardHeader>
            <CardTitle>Quick Actions</CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            <Button 
              className="w-full" 
              disabled={!selectedTemplate}
              onClick={() => setShowNewEntryDialog(true)}
            >
              <Plus className="h-4 w-4 mr-2" />
              Add Entry
            </Button>
            <Button 
              variant="outline" 
              className="w-full"
              onClick={() => setBulkMode(!bulkMode)}
            >
              {bulkMode ? 'Exit Bulk Mode' : 'Bulk Edit Mode'}
            </Button>
            {bulkMode && selectedEntries.length > 0 && (
              <Button 
                variant="destructive" 
                className="w-full"
                onClick={handleBulkDelete}
              >
                <Trash2 className="h-4 w-4 mr-2" />
                Delete Selected ({selectedEntries.length})
              </Button>
            )}
          </CardContent>
        </Card>

        {/* Summary Stats */}
        <Card>
          <CardHeader>
            <CardTitle>Log Summary</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2 text-sm">
              <div className="flex justify-between">
                <span>Total Entries:</span>
                <Badge variant="secondary">{logEntries.length}</Badge>
              </div>
              <div className="flex justify-between">
                <span>Complete:</span>
                <Badge className="bg-green-500">
                  {logEntries.filter(e => e.status === 'complete').length}
                </Badge>
              </div>
              <div className="flex justify-between">
                <span>Draft:</span>
                <Badge className="bg-amber-500">
                  {logEntries.filter(e => e.status === 'draft').length}
                </Badge>
              </div>
              <div className="flex justify-between">
                <span>Missing Hours:</span>
                <Badge variant="outline">{missingHours.length}</Badge>
              </div>
            </div>
            
            {missingHours.length > 0 && (
              <div className="mt-3">
                <div className="text-xs font-medium mb-1">Missing Hours:</div>
                <div className="flex flex-wrap gap-1">
                  {missingHours.slice(0, 8).map(hour => (
                    <Button
                      key={hour}
                      size="sm"
                      variant="outline"
                      className="h-6 w-8 p-0 text-xs"
                      onClick={() => handleCreateEntry(hour)}
                      disabled={!selectedTemplate}
                    >
                      {hour.toString().padStart(2, '0')}
                    </Button>
                  ))}
                  {missingHours.length > 8 && (
                    <span className="text-xs text-muted-foreground">
                      +{missingHours.length - 8} more
                    </span>
                  )}
                </div>
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Main Table */}
      <Card>
        <CardHeader>
          <CardTitle>Log Entries</CardTitle>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                {bulkMode && <TableHead className="w-12"></TableHead>}
                <TableHead>Hour</TableHead>
                <TableHead>Temp (°F)</TableHead>
                <TableHead>Flow (scfh)</TableHead>
                <TableHead>H2S (ppm)</TableHead>
                <TableHead>Benzene (ppm)</TableHead>
                <TableHead>Operator</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Modified</TableHead>
                <TableHead>Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {logEntries.map(entry => (
                <TableRow key={entry.id}>
                  {bulkMode && (
                    <TableCell>
                      <input
                        type="checkbox"
                        checked={selectedEntries.includes(entry.id)}
                        onChange={(e) => {
                          if (e.target.checked) {
                            setSelectedEntries(prev => [...prev, entry.id]);
                          } else {
                            setSelectedEntries(prev => prev.filter(id => id !== entry.id));
                          }
                        }}
                      />
                    </TableCell>
                  )}
                  <TableCell className="font-mono">{entry.hour.toString().padStart(2, '0')}:00</TableCell>
                  <TableCell>{entry.exhaustTemp.toFixed(1)}</TableCell>
                  <TableCell>{entry.flow.toFixed(0)}</TableCell>
                  <TableCell>{entry.h2sPpm ? entry.h2sPpm.toFixed(1) : '-'}</TableCell>
                  <TableCell>{entry.benzenePpm ? entry.benzenePpm.toFixed(1) : '-'}</TableCell>
                  <TableCell>{entry.operatorName}</TableCell>
                  <TableCell>{getStatusBadge(entry.status)}</TableCell>
                  <TableCell className="text-xs text-muted-foreground">
                    {entry.lastModified.toLocaleDateString()}
                  </TableCell>
                  <TableCell>
                    <div className="flex gap-1">
                      <Button
                        size="sm"
                        variant="ghost"
                        onClick={() => {
                          setEditingEntry(entry);
                          setShowNewEntryDialog(true);
                        }}
                      >
                        <Edit className="h-3 w-3" />
                      </Button>
                      <Button
                        size="sm"
                        variant="ghost"
                        onClick={() => handleCloneEntry(entry)}
                      >
                        <Copy className="h-3 w-3" />
                      </Button>
                      <Button
                        size="sm"
                        variant="ghost"
                        onClick={() => handleDeleteEntry(entry.id)}
                      >
                        <Trash2 className="h-3 w-3" />
                      </Button>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
          
          {logEntries.length === 0 && !loading && (
            <div className="text-center py-8 text-muted-foreground">
              No log entries found. Select a template and create your first entry.
            </div>
          )}
        </CardContent>
      </Card>

      {/* Edit/Create Dialog */}
      <Dialog open={showNewEntryDialog} onOpenChange={setShowNewEntryDialog}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>
              {editingEntry?.id?.startsWith('new-') || editingEntry?.id?.startsWith('cloned-') 
                ? 'Create Log Entry' 
                : 'Edit Log Entry'
              }
            </DialogTitle>
            <DialogDescription>
              {editingEntry ? `Hour ${editingEntry.hour.toString().padStart(2, '0')}:00` : ''}
            </DialogDescription>
          </DialogHeader>
          
          {editingEntry && (
            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label>Hour</Label>
                <Input
                  type="number"
                  min="0"
                  max="23"
                  value={editingEntry.hour}
                  onChange={(e) => setEditingEntry({
                    ...editingEntry,
                    hour: parseInt(e.target.value)
                  })}
                />
              </div>
              
              <div>
                <Label>Date</Label>
                <Input
                  type="date"
                  value={editingEntry.date}
                  onChange={(e) => setEditingEntry({
                    ...editingEntry,
                    date: e.target.value
                  })}
                />
              </div>
              
              <div>
                <Label>Exhaust Temperature (°F)</Label>
                <Input
                  type="number"
                  step="0.1"
                  value={editingEntry.exhaustTemp}
                  onChange={(e) => setEditingEntry({
                    ...editingEntry,
                    exhaustTemp: parseFloat(e.target.value)
                  })}
                />
              </div>
              
              <div>
                <Label>Flow Rate (scfh)</Label>
                <Input
                  type="number"
                  step="0.1"
                  value={editingEntry.flow}
                  onChange={(e) => setEditingEntry({
                    ...editingEntry,
                    flow: parseFloat(e.target.value)
                  })}
                />
              </div>
              
              {selectedTemplate?.fields.includes('h2sPpm') && (
                <div>
                  <Label>H2S Concentration (ppm)</Label>
                  <Input
                    type="number"
                    step="0.1"
                    value={editingEntry.h2sPpm || ''}
                    onChange={(e) => setEditingEntry({
                      ...editingEntry,
                      h2sPpm: parseFloat(e.target.value) || undefined
                    })}
                  />
                </div>
              )}
              
              {selectedTemplate?.fields.includes('benzenePpm') && (
                <div>
                  <Label>Benzene Concentration (ppm)</Label>
                  <Input
                    type="number"
                    step="0.1"
                    value={editingEntry.benzenePpm || ''}
                    onChange={(e) => setEditingEntry({
                      ...editingEntry,
                      benzenePpm: parseFloat(e.target.value) || undefined
                    })}
                  />
                </div>
              )}
              
              <div className="col-span-2">
                <Label>Operator</Label>
                <Select 
                  value={editingEntry.operatorId}
                  onValueChange={(value) => {
                    const operatorNames = {
                      'john.doe': 'John Doe',
                      'jane.smith': 'Jane Smith', 
                      'mike.wilson': 'Mike Wilson',
                      'admin': 'Administrator'
                    };
                    setEditingEntry({
                      ...editingEntry,
                      operatorId: value,
                      operatorName: operatorNames[value as keyof typeof operatorNames]
                    });
                  }}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="john.doe">John Doe</SelectItem>
                    <SelectItem value="jane.smith">Jane Smith</SelectItem>
                    <SelectItem value="mike.wilson">Mike Wilson</SelectItem>
                    <SelectItem value="admin">Administrator</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              
              <div className="col-span-2">
                <Label>Notes</Label>
                <Textarea
                  value={editingEntry.notes || ''}
                  onChange={(e) => setEditingEntry({
                    ...editingEntry,
                    notes: e.target.value
                  })}
                  placeholder="Optional notes about this reading..."
                />
              </div>
            </div>
          )}
          
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowNewEntryDialog(false)}>
              Cancel
            </Button>
            <Button onClick={handleSaveEntry}>
              <Save className="h-4 w-4 mr-2" />
              Save Entry
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}