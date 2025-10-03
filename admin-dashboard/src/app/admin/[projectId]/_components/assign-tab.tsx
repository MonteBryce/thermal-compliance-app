'use client';

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Label } from '@/components/ui/label';
import { ScrollArea } from '@/components/ui/scroll-area';
import {
  FileText,
  CheckCircle,
  AlertCircle,
  Calendar,
  User,
  Layers,
  Save,
  Eye,
  History,
  Users,
  Settings,
  Activity
} from 'lucide-react';
import { LogTemplate, LogTemplateVersion } from '@/lib/types/logbuilder';
import { Project } from '@/lib/firestore/projects';
import { formatDistanceToNow } from 'date-fns';

interface AssignTabProps {
  project: Project;
}

// Mock templates data
const mockTemplates: LogTemplate[] = [
  {
    id: 'template-001',
    name: 'Texas Methane H2S & Benzene',
    logType: 'thermal',
    status: 'published',
    latestVersion: 2,
    createdBy: 'admin@company.com',
    createdAt: { toDate: () => new Date('2024-01-01') } as any,
    updatedAt: { toDate: () => new Date('2024-01-15') } as any,
    draftSchema: { fields: [], layout: [], meta: {} }
  },
  {
    id: 'template-002',
    name: 'Texas Pentane Standard',
    logType: 'thermal',
    status: 'published',
    latestVersion: 1,
    createdBy: 'supervisor@company.com',
    createdAt: { toDate: () => new Date('2024-01-05') } as any,
    updatedAt: { toDate: () => new Date('2024-01-10') } as any,
    draftSchema: { fields: [], layout: [], meta: {} }
  },
  {
    id: 'template-003',
    name: 'Enhanced H2S Monitoring',
    logType: 'h2s',
    status: 'published',
    latestVersion: 3,
    createdBy: 'admin@company.com',
    createdAt: { toDate: () => new Date('2023-12-20') } as any,
    updatedAt: { toDate: () => new Date('2024-01-12') } as any,
    draftSchema: { fields: [], layout: [], meta: {} }
  }
];

// Mock versions for selected template
const mockVersions: LogTemplateVersion[] = [
  {
    id: 'version-001',
    templateId: 'template-001',
    version: 2,
    schema: {
      fields: [
        { id: '1', key: 'temperature', label: 'Temperature', type: 'number', required: true, unit: '°F' },
        { id: '2', key: 'pressure', label: 'Pressure', type: 'number', required: true, unit: 'psi' },
        { id: '3', key: 'h2s', label: 'H2S Level', type: 'number', required: true, unit: 'ppm' },
        { id: '4', key: 'benzene', label: 'Benzene Level', type: 'number', required: true, unit: 'ppm' },
        { id: '5', key: 'operator', label: 'Operator', type: 'text', required: true },
        { id: '6', key: 'notes', label: 'Notes', type: 'text', required: false }
      ],
      layout: [],
      meta: {}
    },
    changelog: 'Added benzene monitoring fields and updated validation rules for compliance',
    createdBy: 'admin@company.com',
    createdAt: { toDate: () => new Date('2024-01-15') } as any
  },
  {
    id: 'version-002',
    templateId: 'template-001',
    version: 1,
    schema: {
      fields: [
        { id: '1', key: 'temperature', label: 'Temperature', type: 'number', required: true, unit: '°F' },
        { id: '2', key: 'pressure', label: 'Pressure', type: 'number', required: true, unit: 'psi' },
        { id: '3', key: 'h2s', label: 'H2S Level', type: 'number', required: true, unit: 'ppm' },
        { id: '4', key: 'operator', label: 'Operator', type: 'text', required: true }
      ],
      layout: [],
      meta: {}
    },
    changelog: 'Initial template version for thermal logging',
    createdBy: 'supervisor@company.com',
    createdAt: { toDate: () => new Date('2024-01-01') } as any
  }
];

// Mock operators data
const mockOperators = [
  {
    id: '1',
    name: 'John Smith',
    email: 'j.smith@company.com',
    role: 'Senior Operator',
    status: 'active',
    assignedProjects: 3
  },
  {
    id: '2',
    name: 'Maria Wilson',
    email: 'm.wilson@company.com',
    role: 'Operator',
    status: 'active',
    assignedProjects: 2
  },
  {
    id: '3',
    name: 'Robert Davis',
    email: 'r.davis@company.com',
    role: 'Junior Operator',
    status: 'training',
    assignedProjects: 1
  }
];

export function AssignTab({ project }: AssignTabProps) {
  const [templates, setTemplates] = useState<LogTemplate[]>([]);
  const [versions, setVersions] = useState<LogTemplateVersion[]>([]);
  const [selectedTemplateId, setSelectedTemplateId] = useState<string>('');
  const [selectedVersion, setSelectedVersion] = useState<number | null>(null);
  const [loading, setLoading] = useState(true);
  const [assigning, setAssigning] = useState(false);
  const [showConfirmDialog, setShowConfirmDialog] = useState(false);

  useEffect(() => {
    // TODO: Replace with real Firestore calls
    const loadData = async () => {
      try {
        setLoading(true);
        // Simulate API call
        await new Promise(resolve => setTimeout(resolve, 500));
        setTemplates(mockTemplates);
        
        // Pre-select current template if assigned
        if (project.assignedTemplateId) {
          setSelectedTemplateId(project.assignedTemplateId);
          setSelectedVersion(project.assignedVersion || null);
        }
      } catch (error) {
        console.error('Error loading data:', error);
      } finally {
        setLoading(false);
      }
    };

    loadData();
  }, [project.id]);

  useEffect(() => {
    if (selectedTemplateId) {
      // TODO: Load versions for selected template
      setVersions(mockVersions);
      
      // Auto-select latest version if none selected
      if (!selectedVersion && mockVersions.length > 0) {
        setSelectedVersion(mockVersions[0].version);
      }
    } else {
      setVersions([]);
      setSelectedVersion(null);
    }
  }, [selectedTemplateId]);

  const handleAssignTemplate = async () => {
    if (!project || !selectedTemplateId || selectedVersion === null) return;

    try {
      setAssigning(true);
      // TODO: Implement actual assignment logic
      console.log('Assigning template:', selectedTemplateId, 'version:', selectedVersion);
      
      setShowConfirmDialog(false);
      // Show success message or navigate
    } catch (error) {
      console.error('Error assigning template:', error);
    } finally {
      setAssigning(false);
    }
  };

  const selectedTemplate = templates.find(t => t.id === selectedTemplateId);
  const selectedVersionData = versions.find(v => v.version === selectedVersion);

  const hasChanges = project && (
    project.assignedTemplateId !== selectedTemplateId ||
    project.assignedVersion !== selectedVersion
  );

  if (loading) {
    return (
      <div className="p-6 space-y-6">
        <div className="h-8 bg-[#1E1E1E] rounded animate-pulse" />
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div className="h-96 bg-[#1E1E1E] rounded animate-pulse" />
          <div className="h-96 bg-[#1E1E1E] rounded animate-pulse" />
        </div>
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-white">Template & Operator Assignment</h2>
          <p className="text-gray-400">
            Configure which template and operators are assigned to this project
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="outline" className="border-gray-600 text-gray-300">
            <History className="h-4 w-4 mr-2" />
            View History
          </Button>
          <Button
            onClick={() => setShowConfirmDialog(true)}
            disabled={!hasChanges || !selectedTemplateId || selectedVersion === null}
            className="bg-orange-600 hover:bg-orange-700"
          >
            <Save className="h-4 w-4 mr-2" />
            Save Assignment
          </Button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Left: Current Status & Template Selection */}
        <div className="space-y-6">
          {/* Current Assignment Status */}
          <Card className="bg-[#1E1E1E] border-gray-800">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Activity className="h-5 w-5" />
                Current Assignment
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              {project.assignedTemplateId ? (
                <div className="p-4 bg-green-950/30 border border-green-800 rounded-lg">
                  <div className="flex items-center gap-2 mb-3">
                    <CheckCircle className="h-5 w-5 text-green-400" />
                    <span className="font-medium text-green-400">Currently Assigned</span>
                  </div>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <div className="text-sm font-medium text-green-400">Template</div>
                      <div className="text-white">
                        {templates.find(t => t.id === project.assignedTemplateId)?.name || 'Unknown Template'}
                      </div>
                    </div>
                    <div>
                      <div className="text-sm font-medium text-green-400">Version</div>
                      <div className="text-white">v{project.assignedVersion}</div>
                    </div>
                    <div className="col-span-2">
                      <div className="text-sm font-medium text-green-400">Assigned</div>
                      <div className="text-white">
                        {project.assignedAt && formatDistanceToNow(project.assignedAt.toDate(), { addSuffix: true })}
                      </div>
                    </div>
                  </div>
                </div>
              ) : (
                <div className="p-4 bg-amber-950/30 border border-amber-600 rounded-lg">
                  <div className="flex items-center gap-2 mb-2">
                    <AlertCircle className="h-5 w-5 text-amber-400" />
                    <span className="font-medium text-amber-400">No Template Assigned</span>
                  </div>
                  <p className="text-amber-300 text-sm">
                    This project doesn't have a template assigned. Select one below to configure operators.
                  </p>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Template Selection */}
          <Card className="bg-[#1E1E1E] border-gray-800">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <FileText className="h-5 w-5" />
                Select Template
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <Label htmlFor="template-select">Template</Label>
                <Select value={selectedTemplateId} onValueChange={setSelectedTemplateId}>
                  <SelectTrigger className="bg-gray-800 border-gray-600">
                    <SelectValue placeholder="Choose a template" />
                  </SelectTrigger>
                  <SelectContent>
                    {templates.map((template) => (
                      <SelectItem key={template.id} value={template.id}>
                        <div className="flex items-center justify-between w-full">
                          <span className="text-white">{template.name}</span>
                          <Badge variant="secondary" className="ml-2">
                            {template.logType}
                          </Badge>
                        </div>
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              {selectedTemplateId && (
                <div>
                  <Label htmlFor="version-select">Version</Label>
                  <Select 
                    value={selectedVersion?.toString() || ''} 
                    onValueChange={(value) => setSelectedVersion(Number(value))}
                  >
                    <SelectTrigger className="bg-gray-800 border-gray-600">
                      <SelectValue placeholder="Choose a version" />
                    </SelectTrigger>
                    <SelectContent>
                      {versions.map((version) => (
                        <SelectItem key={version.version} value={version.version.toString()}>
                          <div className="flex items-center justify-between w-full">
                            <span className="text-white">Version {version.version}</span>
                            <span className="text-xs text-gray-400 ml-2">
                              {formatDistanceToNow(version.createdAt.toDate(), { addSuffix: true })}
                            </span>
                          </div>
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              )}

              {hasChanges && (
                <div className="p-3 bg-blue-950/30 border border-blue-600 rounded-lg">
                  <div className="flex items-center gap-2">
                    <AlertCircle className="h-4 w-4 text-blue-400" />
                    <span className="text-blue-400 text-sm font-medium">Changes pending</span>
                  </div>
                  <p className="text-blue-300 text-sm mt-1">
                    Click "Save Assignment" to apply your changes.
                  </p>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Operator Assignment */}
          <Card className="bg-[#1E1E1E] border-gray-800">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Users className="h-5 w-5" />
                Assigned Operators
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                {mockOperators.map((operator) => (
                  <div key={operator.id} className="flex items-center justify-between p-3 bg-gray-800/50 rounded-lg">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 bg-gray-700 rounded-full flex items-center justify-center">
                        <User className="h-4 w-4" />
                      </div>
                      <div>
                        <div className="font-medium text-white">{operator.name}</div>
                        <div className="text-sm text-gray-400">{operator.role}</div>
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      <Badge 
                        className={
                          operator.status === 'active' 
                            ? 'bg-green-600' 
                            : 'bg-amber-500'
                        }
                      >
                        {operator.status}
                      </Badge>
                      <Button variant="ghost" size="sm">
                        <Settings className="h-3 w-3" />
                      </Button>
                    </div>
                  </div>
                ))}
              </div>
              <Button variant="outline" size="sm" className="w-full mt-4">
                <Users className="h-4 w-4 mr-2" />
                Manage Operators
              </Button>
            </CardContent>
          </Card>
        </div>

        {/* Right: Template Preview */}
        <div className="space-y-6">
          {selectedTemplate && selectedVersionData ? (
            <>
              {/* Template Details */}
              <Card className="bg-[#1E1E1E] border-gray-800">
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <Eye className="h-5 w-5" />
                    Template Preview
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div>
                    <Label className="text-sm font-medium">Name</Label>
                    <div className="text-lg text-white">{selectedTemplate.name}</div>
                  </div>
                  <div>
                    <Label className="text-sm font-medium">Log Type</Label>
                    <Badge variant="secondary">{selectedTemplate.logType}</Badge>
                  </div>
                  <div>
                    <Label className="text-sm font-medium">Version</Label>
                    <div className="text-white">v{selectedVersionData.version}</div>
                  </div>
                  <div>
                    <Label className="text-sm font-medium">Created</Label>
                    <div className="text-sm text-gray-400">
                      {formatDistanceToNow(selectedVersionData.createdAt.toDate(), { addSuffix: true })}
                      <span className="ml-2">by {selectedVersionData.createdBy}</span>
                    </div>
                  </div>
                  
                  {selectedVersionData.changelog && (
                    <div>
                      <Label className="text-sm font-medium">Changelog</Label>
                      <div className="text-sm bg-gray-800 p-3 rounded-lg text-gray-300">
                        {selectedVersionData.changelog}
                      </div>
                    </div>
                  )}
                </CardContent>
              </Card>

              {/* Schema Preview */}
              <Card className="bg-[#1E1E1E] border-gray-800">
                <CardHeader>
                  <CardTitle>Form Fields ({selectedVersionData.schema.fields.length})</CardTitle>
                </CardHeader>
                <CardContent>
                  <ScrollArea className="h-64">
                    <div className="space-y-2">
                      {selectedVersionData.schema.fields.map((field) => (
                        <div key={field.id} className="flex items-center justify-between p-2 border border-gray-700 rounded">
                          <div>
                            <div className="font-medium text-sm text-white">{field.label}</div>
                            <div className="text-xs text-gray-400 font-mono">
                              {field.key}
                            </div>
                          </div>
                          <div className="flex items-center gap-1">
                            <Badge variant="outline" className="text-xs">
                              {field.type}
                            </Badge>
                            {field.required && (
                              <Badge variant="destructive" className="text-xs">
                                Required
                              </Badge>
                            )}
                            {field.unit && (
                              <Badge variant="secondary" className="text-xs">
                                {field.unit}
                              </Badge>
                            )}
                          </div>
                        </div>
                      ))}
                    </div>
                  </ScrollArea>
                  
                  <div className="mt-4 pt-4 border-t border-gray-700">
                    <Button variant="outline" className="w-full">
                      <Eye className="h-4 w-4 mr-2" />
                      Full Preview
                    </Button>
                  </div>
                </CardContent>
              </Card>
            </>
          ) : (
            <Card className="bg-[#1E1E1E] border-gray-800">
              <CardContent className="flex items-center justify-center h-64">
                <div className="text-center text-gray-400">
                  <FileText className="h-12 w-12 mx-auto mb-4 opacity-20" />
                  <p>Select a template to see preview</p>
                </div>
              </CardContent>
            </Card>
          )}
        </div>
      </div>

      {/* Confirmation Dialog */}
      <Dialog open={showConfirmDialog} onOpenChange={setShowConfirmDialog}>
        <DialogContent className="bg-[#1E1E1E] border-gray-800">
          <DialogHeader>
            <DialogTitle className="text-white">Confirm Assignment</DialogTitle>
            <DialogDescription className="text-gray-400">
              This will assign the selected template and version to the project. Operators will use this 
              template for data entry.
            </DialogDescription>
          </DialogHeader>
          
          <div className="space-y-4">
            <div className="p-4 bg-gray-800 rounded-lg">
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <span className="font-medium text-gray-300">Project:</span>
                  <div className="font-mono text-white">{project.projectNumber}</div>
                </div>
                <div>
                  <span className="font-medium text-gray-300">Template:</span>
                  <div className="text-white">{selectedTemplate?.name}</div>
                </div>
                <div>
                  <span className="font-medium text-gray-300">Version:</span>
                  <div className="text-white">v{selectedVersion}</div>
                </div>
                <div>
                  <span className="font-medium text-gray-300">Log Type:</span>
                  <div className="text-white">{selectedTemplate?.logType}</div>
                </div>
              </div>
            </div>

            {project.assignedTemplateId && (
              <div className="p-3 bg-amber-950/30 border border-amber-600 rounded-lg">
                <div className="flex items-start gap-2">
                  <AlertCircle className="h-4 w-4 text-amber-400 mt-0.5" />
                  <div className="text-sm text-amber-300">
                    <strong>Note:</strong> This will replace the currently assigned template. 
                    The change will be recorded in the project history.
                  </div>
                </div>
              </div>
            )}
          </div>

          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setShowConfirmDialog(false)}
              disabled={assigning}
            >
              Cancel
            </Button>
            <Button
              onClick={handleAssignTemplate}
              disabled={assigning}
              className="bg-orange-600 hover:bg-orange-700"
            >
              {assigning ? 'Assigning...' : 'Confirm Assignment'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}