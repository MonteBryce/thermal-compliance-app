'use client';

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
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
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog';
import { ScrollArea } from '@/components/ui/scroll-area';
import {
  History,
  Eye,
  FileText,
  Calendar,
  User,
  Settings,
  ExternalLink,
  Clock,
  Layers,
  Plus,
  Download,
  Filter,
  Activity
} from 'lucide-react';
import { Project } from '@/lib/firestore/projects';
import { LogTemplateVersion } from '@/lib/types/logbuilder';
import { TemplateService } from '@/lib/firestore/templates';
import { formatDistanceToNow, format } from 'date-fns';

interface LogsTabProps {
  project: Project;
}

interface TemplateUsageWithDetails {
  templateId: string;
  templateName: string;
  version: number;
  assignedAt: Date;
  assignedBy: string;
  versionDetails?: LogTemplateVersion;
}

// Mock data for demonstration
const mockTemplateHistory: TemplateUsageWithDetails[] = [
  {
    templateId: 'template-001',
    templateName: 'Texas Methane H2S & Benzene',
    version: 2,
    assignedAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
    assignedBy: 'admin@company.com',
    versionDetails: {
      id: 'version-001',
      templateId: 'template-001',
      version: 2,
      schema: {
        fields: [
          { id: '1', key: 'temperature', label: 'Temperature', type: 'number', required: true, unit: '°F' },
          { id: '2', key: 'pressure', label: 'Pressure', type: 'number', required: true, unit: 'psi' },
          { id: '3', key: 'h2s', label: 'H2S Level', type: 'number', required: true, unit: 'ppm' },
          { id: '4', key: 'benzene', label: 'Benzene Level', type: 'number', required: true, unit: 'ppm' },
          { id: '5', key: 'operator', label: 'Operator', type: 'text', required: true }
        ],
        layout: [],
        meta: {}
      },
      changelog: 'Added benzene monitoring fields and updated validation rules',
      createdBy: 'admin@company.com',
      createdAt: { toDate: () => new Date(Date.now() - 3 * 24 * 60 * 60 * 1000) } as any
    }
  },
  {
    templateId: 'template-001',
    templateName: 'Texas Methane H2S & Benzene',
    version: 1,
    assignedAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
    assignedBy: 'supervisor@company.com',
    versionDetails: {
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
      createdAt: { toDate: () => new Date(Date.now() - 8 * 24 * 60 * 60 * 1000) } as any
    }
  }
];

// Mock log entries
const mockLogEntries = [
  {
    id: '1',
    timestamp: new Date(Date.now() - 30 * 60 * 1000),
    operator: 'J.Smith',
    temperature: 185,
    pressure: 15.2,
    h2s: 12,
    benzene: 0.8,
    status: 'valid'
  },
  {
    id: '2',
    timestamp: new Date(Date.now() - 90 * 60 * 1000),
    operator: 'J.Smith',
    temperature: 187,
    pressure: 15.4,
    h2s: 14,
    benzene: 0.9,
    status: 'valid'
  },
  {
    id: '3',
    timestamp: new Date(Date.now() - 150 * 60 * 1000),
    operator: 'M.Wilson',
    temperature: 189,
    pressure: 15.6,
    h2s: 25,
    benzene: 1.1,
    status: 'warning'
  }
];

export function LogsTab({ project }: LogsTabProps) {
  const [templateHistory, setTemplateHistory] = useState<TemplateUsageWithDetails[]>([]);
  const [selectedTemplate, setSelectedTemplate] = useState<TemplateUsageWithDetails | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // TODO: Replace with real Firestore calls
    const loadData = async () => {
      try {
        setLoading(true);
        // Simulate API call
        await new Promise(resolve => setTimeout(resolve, 500));
        setTemplateHistory(mockTemplateHistory);
      } catch (error) {
        console.error('Error loading template history:', error);
      } finally {
        setLoading(false);
      }
    };

    loadData();
  }, [project.id]);

  const getStatusBadge = (usage: TemplateUsageWithDetails) => {
    const isCurrentlyAssigned = project?.assignedTemplateId === usage.templateId && 
                               project?.assignedVersion === usage.version;
    
    if (isCurrentlyAssigned) {
      return <Badge className="bg-green-500">Currently Active</Badge>;
    } else {
      return <Badge variant="outline">Historical</Badge>;
    }
  };

  const getLogStatusBadge = (status: string) => {
    switch (status) {
      case 'valid':
        return <Badge className="bg-green-600">Valid</Badge>;
      case 'warning':
        return <Badge className="bg-amber-500">Warning</Badge>;
      case 'error':
        return <Badge variant="destructive">Error</Badge>;
      default:
        return <Badge variant="outline">Unknown</Badge>;
    }
  };

  if (loading) {
    return (
      <div className="p-6 space-y-6">
        <div className="h-8 bg-[#1E1E1E] rounded animate-pulse" />
        <div className="h-96 bg-[#1E1E1E] rounded animate-pulse" />
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6">
      {/* Header Actions */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-white">Project Logs</h2>
          <p className="text-gray-400">
            View log entries and template assignment history for this project
          </p>
        </div>
        <div className="flex items-center gap-3">
          <Button variant="outline" className="border-gray-600 text-gray-300">
            <Filter className="h-4 w-4 mr-2" />
            Filter
          </Button>
          <Button variant="outline" className="border-gray-600 text-gray-300">
            <Download className="h-4 w-4 mr-2" />
            Export
          </Button>
          <Button className="bg-orange-600 hover:bg-orange-700">
            <Plus className="h-4 w-4 mr-2" />
            Add Entry
          </Button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Current Template Status */}
        <Card className="bg-[#1E1E1E] border-gray-800">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <FileText className="h-5 w-5 text-green-400" />
              Current Template
            </CardTitle>
          </CardHeader>
          <CardContent>
            {project.assignedTemplateId ? (
              <div className="space-y-4">
                <div className="p-4 bg-green-950/30 border border-green-800 rounded-lg">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <div className="text-sm font-medium text-green-400">Template</div>
                      <div className="text-white">
                        {templateHistory.find(t => 
                          t.templateId === project.assignedTemplateId && 
                          t.version === project.assignedVersion
                        )?.templateName || 'Unknown Template'}
                      </div>
                    </div>
                    <div>
                      <div className="text-sm font-medium text-green-400">Version</div>
                      <div className="text-white">v{project.assignedVersion}</div>
                    </div>
                    <div>
                      <div className="text-sm font-medium text-green-400">Assigned</div>
                      <div className="text-white">
                        {project.assignedAt && formatDistanceToNow(project.assignedAt.toDate(), { addSuffix: true })}
                      </div>
                    </div>
                    <div>
                      <div className="text-sm font-medium text-green-400">Fields</div>
                      <div className="text-white">
                        {templateHistory.find(t => 
                          t.templateId === project.assignedTemplateId && 
                          t.version === project.assignedVersion
                        )?.versionDetails?.schema.fields.length || 0} fields
                      </div>
                    </div>
                  </div>
                </div>
                <Button variant="outline" size="sm" className="w-full">
                  <Eye className="h-4 w-4 mr-2" />
                  Preview Template
                </Button>
              </div>
            ) : (
              <div className="text-center py-8 text-gray-400">
                <FileText className="h-12 w-12 mx-auto mb-4 opacity-20" />
                <p>No template assigned</p>
                <Button size="sm" className="mt-4">
                  <Settings className="h-4 w-4 mr-2" />
                  Assign Template
                </Button>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Recent Log Entries */}
        <Card className="bg-[#1E1E1E] border-gray-800">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Activity className="h-5 w-5 text-blue-400" />
              Recent Entries
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {mockLogEntries.map((entry) => (
                <div key={entry.id} className="flex items-center justify-between p-3 bg-gray-800/50 rounded-lg">
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="text-white font-medium">{entry.operator}</span>
                      {getLogStatusBadge(entry.status)}
                    </div>
                    <div className="text-sm text-gray-400">
                      {formatDistanceToNow(entry.timestamp, { addSuffix: true })}
                    </div>
                  </div>
                  <div className="text-right">
                    <div className="text-white text-sm font-mono">
                      {entry.temperature}°F, {entry.pressure} psi
                    </div>
                    <div className="text-gray-400 text-xs">
                      H2S: {entry.h2s}ppm
                    </div>
                  </div>
                </div>
              ))}
            </div>
            <Button variant="outline" size="sm" className="w-full mt-4">
              View All Entries
            </Button>
          </CardContent>
        </Card>
      </div>

      {/* Template Assignment History */}
      <Card className="bg-[#1E1E1E] border-gray-800">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <History className="h-5 w-5" />
            Template Assignment History
            <Badge variant="secondary">{templateHistory.length}</Badge>
          </CardTitle>
        </CardHeader>
        <CardContent>
          {templateHistory.length === 0 ? (
            <div className="text-center py-8 text-gray-400">
              <History className="h-12 w-12 mx-auto mb-4 opacity-20" />
              <p>No template assignments found</p>
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Template</TableHead>
                  <TableHead>Version</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Assigned</TableHead>
                  <TableHead>Assigned By</TableHead>
                  <TableHead>Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {templateHistory.map((usage, index) => (
                  <TableRow key={`${usage.templateId}-${usage.version}-${index}`}>
                    <TableCell>
                      <div>
                        <div className="font-medium text-white">{usage.templateName}</div>
                        {usage.versionDetails && (
                          <div className="text-sm text-gray-400">
                            {usage.versionDetails.schema.fields.length} fields
                          </div>
                        )}
                      </div>
                    </TableCell>
                    <TableCell>
                      <div className="font-mono">v{usage.version}</div>
                    </TableCell>
                    <TableCell>{getStatusBadge(usage)}</TableCell>
                    <TableCell>
                      <div>
                        <div className="text-white">{format(usage.assignedAt, 'MMM dd, yyyy')}</div>
                        <div className="text-sm text-gray-400">
                          {format(usage.assignedAt, 'HH:mm')}
                        </div>
                      </div>
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center gap-1">
                        <User className="h-3 w-3" />
                        <span className="text-sm">{usage.assignedBy}</span>
                      </div>
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center gap-2">
                        <Dialog>
                          <DialogTrigger asChild>
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => setSelectedTemplate(usage)}
                            >
                              <Eye className="h-3 w-3" />
                            </Button>
                          </DialogTrigger>
                          <DialogContent className="max-w-2xl bg-[#1E1E1E] border-gray-800">
                            <DialogHeader>
                              <DialogTitle className="text-white">Template Details</DialogTitle>
                              <DialogDescription className="text-gray-400">
                                {usage.templateName} v{usage.version}
                              </DialogDescription>
                            </DialogHeader>
                            
                            {usage.versionDetails && (
                              <div className="space-y-4">
                                <div className="grid grid-cols-2 gap-4">
                                  <div>
                                    <div className="text-sm font-medium text-white">Assigned</div>
                                    <div className="text-sm text-gray-400">
                                      {format(usage.assignedAt, 'PPP')} by {usage.assignedBy}
                                    </div>
                                  </div>
                                  <div>
                                    <div className="text-sm font-medium text-white">Version Created</div>
                                    <div className="text-sm text-gray-400">
                                      {format(usage.versionDetails.createdAt.toDate(), 'PPP')}
                                    </div>
                                  </div>
                                </div>
                                
                                {usage.versionDetails.changelog && (
                                  <div>
                                    <div className="text-sm font-medium text-white mb-2">Changelog</div>
                                    <div className="text-sm bg-gray-800 p-3 rounded-lg text-gray-300">
                                      {usage.versionDetails.changelog}
                                    </div>
                                  </div>
                                )}

                                <div>
                                  <div className="text-sm font-medium text-white mb-2">
                                    Form Fields ({usage.versionDetails.schema.fields.length})
                                  </div>
                                  <ScrollArea className="h-48 border border-gray-700 rounded-lg">
                                    <div className="p-3 space-y-2">
                                      {usage.versionDetails.schema.fields.map((field) => (
                                        <div key={field.id} className="flex items-center justify-between text-sm">
                                          <div>
                                            <span className="font-medium text-white">{field.label}</span>
                                            <span className="text-gray-400 ml-2 font-mono">
                                              {field.key}
                                            </span>
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
                                          </div>
                                        </div>
                                      ))}
                                    </div>
                                  </ScrollArea>
                                </div>

                                <div className="flex gap-2">
                                  <Button variant="outline">
                                    <ExternalLink className="h-4 w-4 mr-2" />
                                    Open in Builder
                                  </Button>
                                </div>
                              </div>
                            )}
                          </DialogContent>
                        </Dialog>
                        
                        <Button variant="ghost" size="sm">
                          <ExternalLink className="h-3 w-3" />
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>
    </div>
  );
}