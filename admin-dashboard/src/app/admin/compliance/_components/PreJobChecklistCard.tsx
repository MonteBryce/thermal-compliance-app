'use client';

import { useEffect, useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Checkbox } from '@/components/ui/checkbox';
import { Textarea } from '@/components/ui/textarea';
import { CheckSquare, Square, Edit, Save, X } from 'lucide-react';

interface ChecklistItem {
  id: string;
  title: string;
  description: string;
  completed: boolean;
  required: boolean;
  notes?: string;
}

interface PreJobCheck {
  id: string;
  permitId: string;
  jobId: string;
  items: ChecklistItem[];
  performedBy?: string;
  performedAt?: Date;
  overallStatus: 'pending' | 'partial' | 'complete';
}

interface PreJobChecklistCardProps {
  jobId?: string | null;
  onStatusChange?: (status: 'red' | 'amber' | 'green', delta: number) => void;
}

export function PreJobChecklistCard({ jobId, onStatusChange }: PreJobChecklistCardProps) {
  const [preJobCheck, setPreJobCheck] = useState<PreJobCheck | null>(null);
  const [editing, setEditing] = useState(false);
  const [editingNotes, setEditingNotes] = useState<string>('');
  const [editingItemId, setEditingItemId] = useState<string | null>(null);

  const defaultChecklist: ChecklistItem[] = [
    {
      id: 'meters-verified',
      title: 'Meter Verification',
      description: 'All required meters installed and calibrated',
      completed: false,
      required: true,
    },
    {
      id: 'permit-reviewed',
      title: 'Permit Review',
      description: 'Current permit limits and requirements reviewed',
      completed: false,
      required: true,
    },
    {
      id: 'log-template',
      title: 'Log Template Selection',
      description: 'Appropriate log template selected for permit type',
      completed: false,
      required: true,
    },
    {
      id: 'safety-briefing',
      title: 'Safety Briefing',
      description: 'Site safety requirements and emergency procedures reviewed',
      completed: false,
      required: true,
    },
    {
      id: 'communication-check',
      title: 'Communication Check',
      description: 'Radio/phone communication confirmed with control room',
      completed: false,
      required: false,
    },
    {
      id: 'weather-check',
      title: 'Weather Conditions',
      description: 'Weather conditions suitable for monitoring activities',
      completed: false,
      required: false,
    },
  ];

  useEffect(() => {
    if (jobId) {
      // Mock data - would normally fetch from server
      const mockCheck: PreJobCheck = {
        id: `check-${jobId}`,
        permitId: 'EPA-TX-2024-001',
        jobId,
        items: defaultChecklist,
        overallStatus: 'pending',
      };
      
      setPreJobCheck(mockCheck);
      onStatusChange?.('amber', 1); // Pending checklist
    }
  }, [jobId]);

  const updateChecklistItem = (itemId: string, completed: boolean) => {
    if (!preJobCheck) return;
    
    const updatedItems = preJobCheck.items.map(item =>
      item.id === itemId ? { ...item, completed } : item
    );
    
    const requiredItems = updatedItems.filter(item => item.required);
    const completedRequired = requiredItems.filter(item => item.completed);
    const totalRequired = requiredItems.length;
    
    let newStatus: PreJobCheck['overallStatus'] = 'pending';
    if (completedRequired.length === totalRequired) {
      newStatus = 'complete';
    } else if (completedRequired.length > 0) {
      newStatus = 'partial';
    }
    
    setPreJobCheck({
      ...preJobCheck,
      items: updatedItems,
      overallStatus: newStatus,
    });
    
    // Update status for parent component
    if (onStatusChange) {
      if (newStatus === 'complete') {
        onStatusChange('green', 1);
      } else if (newStatus === 'partial') {
        onStatusChange('amber', 1);
      } else {
        onStatusChange('red', 1);
      }
    }
  };

  const addNotesToItem = (itemId: string, notes: string) => {
    if (!preJobCheck) return;
    
    const updatedItems = preJobCheck.items.map(item =>
      item.id === itemId ? { ...item, notes } : item
    );
    
    setPreJobCheck({
      ...preJobCheck,
      items: updatedItems,
    });
    
    setEditingItemId(null);
    setEditingNotes('');
  };

  const getStatusBadge = (status: PreJobCheck['overallStatus']) => {
    switch (status) {
      case 'complete':
        return <Badge className="bg-green-500">✓ Complete</Badge>;
      case 'partial':
        return <Badge className="bg-amber-500">⚠ Partial</Badge>;
      case 'pending':
        return <Badge variant="outline">⏱ Pending</Badge>;
    }
  };

  const getCompletionStats = () => {
    if (!preJobCheck) return { completed: 0, total: 0, required: 0 };
    
    const completed = preJobCheck.items.filter(item => item.completed).length;
    const total = preJobCheck.items.length;
    const requiredCompleted = preJobCheck.items.filter(item => item.required && item.completed).length;
    const totalRequired = preJobCheck.items.filter(item => item.required).length;
    
    return { completed, total, required: requiredCompleted, totalRequired };
  };

  if (!jobId) {
    return (
      <Card className="col-span-1">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <CheckSquare className="h-5 w-5" />
            Pre-Job Checklist
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="text-center py-8 text-muted-foreground">
            Select a job to view checklist
          </div>
        </CardContent>
      </Card>
    );
  }

  if (!preJobCheck) {
    return (
      <Card className="col-span-1">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <CheckSquare className="h-5 w-5" />
            Pre-Job Checklist
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="text-center py-8 text-muted-foreground">
            Loading checklist...
          </div>
        </CardContent>
      </Card>
    );
  }

  const stats = getCompletionStats();

  return (
    <Card className="col-span-1">
      <CardHeader className="flex flex-row items-center justify-between">
        <div>
          <CardTitle className="flex items-center gap-2">
            <CheckSquare className="h-5 w-5" />
            Pre-Job Checklist
            {getStatusBadge(preJobCheck.overallStatus)}
          </CardTitle>
          <div className="text-xs text-muted-foreground mt-1">
            {stats.required}/{stats.totalRequired} required • {stats.completed}/{stats.total} total
          </div>
        </div>
        <Button
          variant="ghost"
          size="icon"
          onClick={() => setEditing(!editing)}
        >
          <Edit className="h-4 w-4" />
        </Button>
      </CardHeader>
      <CardContent>
        <div className="space-y-3">
          {preJobCheck.items.map(item => (
            <div key={item.id} className="space-y-2">
              <div className="flex items-start gap-3 p-2 border rounded-lg">
                <Checkbox
                  checked={item.completed}
                  onCheckedChange={(checked) => 
                    updateChecklistItem(item.id, checked as boolean)
                  }
                  disabled={!editing}
                />
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <span className={`text-sm font-medium ${
                      item.completed ? 'line-through text-muted-foreground' : ''
                    }`}>
                      {item.title}
                    </span>
                    {item.required && (
                      <Badge variant="outline" className="text-xs">Required</Badge>
                    )}
                  </div>
                  <div className="text-xs text-muted-foreground">
                    {item.description}
                  </div>
                  {item.notes && (
                    <div className="text-xs text-blue-600 mt-1 italic">
                      Note: {item.notes}
                    </div>
                  )}
                </div>
                {editing && (
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => {
                      setEditingItemId(item.id);
                      setEditingNotes(item.notes || '');
                    }}
                  >
                    <Edit className="h-3 w-3" />
                  </Button>
                )}
              </div>
              
              {editingItemId === item.id && (
                <div className="ml-6 space-y-2">
                  <Textarea
                    placeholder="Add notes for this checklist item..."
                    value={editingNotes}
                    onChange={(e) => setEditingNotes(e.target.value)}
                    rows={2}
                  />
                  <div className="flex gap-2">
                    <Button
                      size="sm"
                      onClick={() => addNotesToItem(item.id, editingNotes)}
                    >
                      <Save className="h-3 w-3 mr-1" />
                      Save
                    </Button>
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => {
                        setEditingItemId(null);
                        setEditingNotes('');
                      }}
                    >
                      <X className="h-3 w-3 mr-1" />
                      Cancel
                    </Button>
                  </div>
                </div>
              )}
            </div>
          ))}
        </div>
        
        {preJobCheck.performedBy && (
          <div className="mt-4 pt-3 border-t text-xs text-muted-foreground">
            Completed by {preJobCheck.performedBy} on {preJobCheck.performedAt?.toLocaleDateString()}
          </div>
        )}
      </CardContent>
    </Card>
  );
}