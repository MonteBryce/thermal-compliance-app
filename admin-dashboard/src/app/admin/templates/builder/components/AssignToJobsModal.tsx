'use client';

import React, { useState, useEffect } from 'react';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { Checkbox } from '@/components/ui/checkbox';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { 
  Search, 
  MapPin, 
  Calendar, 
  Clock, 
  Users, 
  CheckCircle, 
  AlertCircle, 
  Play, 
  Pause,
  Pin
} from 'lucide-react';

interface Job {
  id: string;
  name: string;
  projectName: string;
  facilityName: string;
  status: 'not_started' | 'in_progress' | 'completed';
  assignedOperators: string[];
  scheduledDate: string;
  currentTemplateId?: string;
  currentTemplateVersion?: number;
}

interface AssignToJobsModalProps {
  open: boolean;
  onClose: () => void;
  templateId: string;
  templateKey: string;
  templateName: string;
  onAssign: (jobIds: string[]) => void;
}

// Mock job data - in real implementation, this would come from Firestore
const MOCK_JOBS: Job[] = [
  {
    id: 'job-1',
    name: 'Marathon GBR Well #1',
    projectName: 'Marathon North Sea Project',
    facilityName: 'GBR Platform',
    status: 'not_started',
    assignedOperators: ['John Doe', 'Mike Smith'],
    scheduledDate: '2024-01-15',
  },
  {
    id: 'job-2',
    name: 'Shell Perdido Thermal Check',
    projectName: 'Shell Gulf Operations',
    facilityName: 'Perdido Platform',
    status: 'in_progress',
    assignedOperators: ['Sarah Johnson'],
    scheduledDate: '2024-01-14',
    currentTemplateId: 'template-old',
    currentTemplateVersion: 3,
  },
  {
    id: 'job-3',
    name: 'BP Thunder Horse Maintenance',
    projectName: 'BP Thunder Horse',
    facilityName: 'Thunder Horse Platform',
    status: 'completed',
    assignedOperators: ['David Wilson', 'Lisa Brown'],
    scheduledDate: '2024-01-13',
    currentTemplateId: 'template-old',
    currentTemplateVersion: 2,
  },
  {
    id: 'job-4',
    name: 'Chevron Jack/St. Malo',
    projectName: 'Chevron Deep Water',
    facilityName: 'Jack/St. Malo Platform',
    status: 'not_started',
    assignedOperators: ['Alex Turner'],
    scheduledDate: '2024-01-16',
  },
  {
    id: 'job-5',
    name: 'ExxonMobil Hoover Diana',
    projectName: 'ExxonMobil Gulf',
    facilityName: 'Hoover Diana Platform',
    status: 'in_progress',
    assignedOperators: ['Emily Davis', 'Robert Clark'],
    scheduledDate: '2024-01-14',
  },
];

export function AssignToJobsModal({ 
  open, 
  onClose, 
  templateId, 
  templateKey, 
  templateName, 
  onAssign 
}: AssignToJobsModalProps) {
  const [jobs, setJobs] = useState<Job[]>([]);
  const [filteredJobs, setFilteredJobs] = useState<Job[]>([]);
  const [selectedJobs, setSelectedJobs] = useState<Set<string>>(new Set());
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | 'not_started' | 'in_progress' | 'completed'>('all');
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (open) {
      loadJobs();
    }
  }, [open]);

  useEffect(() => {
    filterJobs();
  }, [jobs, searchTerm, statusFilter]);

  const loadJobs = async () => {
    setLoading(true);
    try {
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 500));
      setJobs(MOCK_JOBS);
    } catch (error) {
      console.error('Failed to load jobs:', error);
    } finally {
      setLoading(false);
    }
  };

  const filterJobs = () => {
    let filtered = jobs;

    if (searchTerm) {
      filtered = filtered.filter(job => 
        job.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        job.projectName.toLowerCase().includes(searchTerm.toLowerCase()) ||
        job.facilityName.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    if (statusFilter !== 'all') {
      filtered = filtered.filter(job => job.status === statusFilter);
    }

    setFilteredJobs(filtered);
  };

  const handleJobToggle = (jobId: string) => {
    const newSelected = new Set(selectedJobs);
    if (newSelected.has(jobId)) {
      newSelected.delete(jobId);
    } else {
      newSelected.add(jobId);
    }
    setSelectedJobs(newSelected);
  };

  const handleSelectAll = () => {
    if (selectedJobs.size === filteredJobs.length) {
      setSelectedJobs(new Set());
    } else {
      setSelectedJobs(new Set(filteredJobs.map(job => job.id)));
    }
  };

  const handleAssign = () => {
    onAssign(Array.from(selectedJobs));
  };

  const getStatusIcon = (status: Job['status']) => {
    switch (status) {
      case 'not_started':
        return <Pause className="w-4 h-4 text-gray-400" />;
      case 'in_progress':
        return <Play className="w-4 h-4 text-blue-400" />;
      case 'completed':
        return <CheckCircle className="w-4 h-4 text-green-400" />;
    }
  };

  const getStatusBadge = (status: Job['status']) => {
    switch (status) {
      case 'not_started':
        return <Badge variant="outline">Not Started</Badge>;
      case 'in_progress':
        return <Badge className="bg-blue-600 text-white">In Progress</Badge>;
      case 'completed':
        return <Badge className="bg-green-600 text-white">Completed</Badge>;
    }
  };

  const selectedJobsCount = selectedJobs.size;
  const hasConflicts = Array.from(selectedJobs).some(jobId => {
    const job = jobs.find(j => j.id === jobId);
    return job?.currentTemplateId && job.currentTemplateId !== templateId;
  });

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-4xl max-h-[90vh] overflow-hidden flex flex-col">
        <DialogHeader>
          <DialogTitle className="text-white">Assign Template to Jobs</DialogTitle>
          <DialogDescription className="text-gray-400">
            Select jobs to assign "{templateName}" template to. This will pin the template version 
            and make it available for operators.
          </DialogDescription>
        </DialogHeader>

        <div className="flex-1 space-y-4 overflow-hidden">
          {/* Template Info */}
          <Card className="bg-blue-50 dark:bg-blue-950 border-blue-500">
            <CardContent className="pt-4">
              <div className="flex items-center gap-3">
                <Pin className="w-5 h-5 text-blue-500" />
                <div>
                  <div className="font-medium text-white">{templateName}</div>
                  <div className="text-sm text-blue-300">Key: {templateKey}</div>
                </div>
                <Badge className="bg-blue-600 text-white ml-auto">
                  Will be pinned
                </Badge>
              </div>
            </CardContent>
          </Card>

          {/* Filters */}
          <div className="flex gap-4 items-center">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
              <Input
                placeholder="Search jobs, projects, or facilities..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-10 bg-[#2A2A2A] border-gray-600 text-white"
              />
            </div>
            <div className="flex gap-2">
              {['all', 'not_started', 'in_progress', 'completed'].map(status => (
                <Button
                  key={status}
                  variant={statusFilter === status ? 'default' : 'outline'}
                  size="sm"
                  onClick={() => setStatusFilter(status as any)}
                  className="border-gray-600"
                >
                  {status.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase())}
                </Button>
              ))}
            </div>
          </div>

          {/* Selection Summary */}
          <div className="flex items-center justify-between p-3 bg-[#2A2A2A] border border-gray-600 rounded-lg">
            <div className="flex items-center gap-4">
              <div className="flex items-center gap-2">
                <Checkbox
                  checked={selectedJobs.size === filteredJobs.length && filteredJobs.length > 0}
                  onCheckedChange={handleSelectAll}
                />
                <Label className="text-white">
                  Select all ({filteredJobs.length} jobs)
                </Label>
              </div>
              <div className="text-sm text-gray-400">
                {selectedJobsCount} selected
              </div>
            </div>
            {hasConflicts && (
              <Alert variant="destructive" className="ml-4 p-2">
                <AlertCircle className="w-4 h-4" />
                <AlertDescription className="text-sm">
                  Some selected jobs have different templates
                </AlertDescription>
              </Alert>
            )}
          </div>

          {/* Jobs List */}
          <div className="flex-1 overflow-auto space-y-2">
            {loading ? (
              <div className="text-center py-8 text-gray-400">Loading jobs...</div>
            ) : filteredJobs.length === 0 ? (
              <div className="text-center py-8 text-gray-400">
                No jobs found matching your criteria
              </div>
            ) : (
              filteredJobs.map(job => (
                <Card 
                  key={job.id} 
                  className={`cursor-pointer transition-all hover:bg-gray-800 ${
                    selectedJobs.has(job.id) 
                      ? 'border-orange-500 bg-orange-950' 
                      : 'border-gray-600 bg-[#2A2A2A]'
                  }`}
                  onClick={() => handleJobToggle(job.id)}
                >
                  <CardContent className="p-4">
                    <div className="flex items-center gap-3">
                      <Checkbox
                        checked={selectedJobs.has(job.id)}
                        onCheckedChange={() => handleJobToggle(job.id)}
                      />
                      
                      <div className="flex-1">
                        <div className="flex items-center gap-2 mb-1">
                          <h3 className="font-medium text-white">{job.name}</h3>
                          {getStatusIcon(job.status)}
                          {getStatusBadge(job.status)}
                        </div>
                        
                        <div className="grid grid-cols-3 gap-4 text-sm text-gray-400">
                          <div className="flex items-center gap-1">
                            <MapPin className="w-3 h-3" />
                            {job.facilityName}
                          </div>
                          <div className="flex items-center gap-1">
                            <Calendar className="w-3 h-3" />
                            {new Date(job.scheduledDate).toLocaleDateString()}
                          </div>
                          <div className="flex items-center gap-1">
                            <Users className="w-3 h-3" />
                            {job.assignedOperators.length} operators
                          </div>
                        </div>
                        
                        <div className="text-xs text-gray-500 mt-1">
                          Project: {job.projectName}
                        </div>
                        
                        {job.currentTemplateId && (
                          <div className="mt-2">
                            <Badge variant="outline" className="text-xs">
                              Current: Template v{job.currentTemplateVersion}
                              {job.currentTemplateId !== templateId && (
                                <AlertCircle className="w-3 h-3 ml-1 text-yellow-500" />
                              )}
                            </Badge>
                          </div>
                        )}
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))
            )}
          </div>
        </div>

        <div className="flex justify-between items-center pt-4 border-t border-gray-700">
          <div className="text-sm text-gray-400">
            {selectedJobsCount > 0 && (
              <>Pin template to {selectedJobsCount} job{selectedJobsCount !== 1 ? 's' : ''}</>
            )}
          </div>
          <div className="flex gap-2">
            <Button variant="outline" onClick={onClose} className="border-gray-600 text-gray-300">
              Cancel
            </Button>
            <Button
              onClick={handleAssign}
              disabled={selectedJobsCount === 0}
              className="bg-orange-600 hover:bg-orange-700"
            >
              <Pin className="w-4 h-4 mr-2" />
              Assign Template ({selectedJobsCount})
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}