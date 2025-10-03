'use client';

import { useState, useEffect } from 'react';
import { useParams, useRouter } from 'next/navigation';
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
  ArrowLeft,
  History,
  Eye,
  FileText,
  Calendar,
  User,
  Settings,
  ExternalLink,
  Clock,
  Layers,
} from 'lucide-react';
import { Project } from '@/lib/firestore/projects';
import { LogTemplateVersion } from '@/lib/types/logbuilder';
import { ProjectService } from '@/lib/firestore/projects';
import { TemplateService } from '@/lib/firestore/templates';
import { formatDistanceToNow, format } from 'date-fns';

interface TemplateUsageWithDetails {
  templateId: string;
  templateName: string;
  version: number;
  assignedAt: Date;
  assignedBy: string;
  versionDetails?: LogTemplateVersion;
}

export default function LogHistoryPage() {
  const params = useParams();
  const router = useRouter();
  const projectId = params.projectId as string;

  const [project, setProject] = useState<Project | null>(null);
  const [templateHistory, setTemplateHistory] = useState<TemplateUsageWithDetails[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedTemplate, setSelectedTemplate] = useState<TemplateUsageWithDetails | null>(null);

  const projectService = new ProjectService();
  const templateService = new TemplateService();

  useEffect(() => {
    loadData();
  }, [projectId]);

  const loadData = async () => {
    try {
      setLoading(true);
      const projectData = await projectService.getProject(projectId);
      
      if (projectData) {
        setProject(projectData);
        
        // Load version details for each template usage
        const historyWithDetails = await Promise.all(
          projectData.usedTemplates.map(async (usage) => {
            try {
              const versionDetails = await templateService.getTemplateVersion(
                usage.templateId,
                usage.version
              );
              return {
                ...usage,
                assignedAt: usage.assignedAt.toDate(),
                versionDetails,
              };
            } catch (error) {
              console.error(`Error loading version details for ${usage.templateId}:`, error);
              return {
                ...usage,
                assignedAt: usage.assignedAt.toDate(),
              };
            }
          })
        );

        // Sort by assignment date (newest first)
        historyWithDetails.sort((a, b) => b.assignedAt.getTime() - a.assignedAt.getTime());
        setTemplateHistory(historyWithDetails);
      }
    } catch (error) {
      console.error('Error loading data:', error);
    } finally {
      setLoading(false);
    }
  };

  const getStatusBadge = (usage: TemplateUsageWithDetails) => {
    const isCurrentlyAssigned = project?.assignedTemplateId === usage.templateId && 
                               project?.assignedVersion === usage.version;
    
    if (isCurrentlyAssigned) {
      return <Badge className="bg-green-500">Currently Active</Badge>;
    } else {
      return <Badge variant="outline">Historical</Badge>;
    }
  };

  const handleViewTemplate = (templateId: string) => {
    router.push(`/admin/log-builder/${templateId}/preview`);
  };

  const handleAssignNewTemplate = () => {
    router.push(`/admin/projects/${projectId}/assign-log`);
  };

  if (loading) {
    return (
      <div className="container mx-auto p-6 space-y-6">
        <div className="h-8 bg-muted rounded animate-pulse" />
        <div className="h-96 bg-muted rounded animate-pulse" />
      </div>
    );
  }

  if (!project) {
    return (
      <div className="container mx-auto p-6">
        <Card className="p-8 text-center">
          <h2 className="text-xl font-semibold mb-2">Project Not Found</h2>
          <p className="text-muted-foreground">
            The project you're looking for doesn't exist or you don't have permission to view it.
          </p>
        </Card>
      </div>
    );
  }

  return (
    <div className="container mx-auto p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Button
            variant="ghost"
            onClick={() => router.push('/admin/projects')}
          >
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back to Projects
          </Button>
          <div>
            <h1 className="text-3xl font-bold">Template Assignment History</h1>
            <p className="text-muted-foreground">
              Track all template assignments for this project
            </p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            onClick={handleAssignNewTemplate}
          >
            <Settings className="h-4 w-4 mr-2" />
            Assign Template
          </Button>
        </div>
      </div>

      {/* Project Information */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Layers className="h-5 w-5" />
            Project Information
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <div>
              <div className="text-sm font-medium text-muted-foreground">Project Number</div>
              <div className="text-lg font-mono">{project.projectNumber}</div>
            </div>
            <div>
              <div className="text-sm font-medium text-muted-foreground">Facility</div>
              <div>{project.facility}</div>
            </div>
            <div>
              <div className="text-sm font-medium text-muted-foreground">Tank ID</div>
              <div className="font-mono">{project.tankId}</div>
            </div>
            <div>
              <div className="text-sm font-medium text-muted-foreground">Total Assignments</div>
              <div className="text-lg font-semibold">{templateHistory.length}</div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Current Assignment */}
      {project.assignedTemplateId && (
        <Card className="border-green-200 bg-green-50">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-green-800">
              <FileText className="h-5 w-5" />
              Currently Assigned Template
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div>
                <div className="text-sm font-medium text-green-700">Template</div>
                <div className="text-green-900">
                  {templateHistory.find(t => 
                    t.templateId === project.assignedTemplateId && 
                    t.version === project.assignedVersion
                  )?.templateName || 'Unknown Template'}
                </div>
              </div>
              <div>
                <div className="text-sm font-medium text-green-700">Version</div>
                <div className="text-green-900">v{project.assignedVersion}</div>
              </div>
              <div>
                <div className="text-sm font-medium text-green-700">Assigned</div>
                <div className="text-green-900">
                  {project.assignedAt && formatDistanceToNow(project.assignedAt.toDate(), { addSuffix: true })}
                </div>
              </div>
            </div>
            <div className="mt-4">
              <Button
                variant="outline"
                size="sm"
                onClick={() => handleViewTemplate(project.assignedTemplateId!)}
                className="border-green-600 text-green-700 hover:bg-green-100"
              >
                <Eye className="h-4 w-4 mr-2" />
                Preview Current Template
              </Button>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Assignment History */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <History className="h-5 w-5" />
            Assignment History
            <Badge variant="secondary">{templateHistory.length}</Badge>
          </CardTitle>
        </CardHeader>
        <CardContent>
          {templateHistory.length === 0 ? (
            <div className="text-center py-8 text-muted-foreground">
              <History className="h-12 w-12 mx-auto mb-4 opacity-20" />
              <p>No template assignments found</p>
              <Button
                variant="outline"
                className="mt-4"
                onClick={handleAssignNewTemplate}
              >
                <Settings className="h-4 w-4 mr-2" />
                Assign First Template
              </Button>
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
                        <div className="font-medium">{usage.templateName}</div>
                        {usage.versionDetails && (
                          <div className="text-sm text-muted-foreground">
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
                        <div>{format(usage.assignedAt, 'MMM dd, yyyy')}</div>
                        <div className="text-sm text-muted-foreground">
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
                          <DialogContent className="max-w-2xl">
                            <DialogHeader>
                              <DialogTitle>Template Details</DialogTitle>
                              <DialogDescription>
                                {usage.templateName} v{usage.version}
                              </DialogDescription>
                            </DialogHeader>
                            
                            {usage.versionDetails && (
                              <div className="space-y-4">
                                <div className="grid grid-cols-2 gap-4">
                                  <div>
                                    <div className="text-sm font-medium">Assigned</div>
                                    <div className="text-sm text-muted-foreground">
                                      {format(usage.assignedAt, 'PPP')} by {usage.assignedBy}
                                    </div>
                                  </div>
                                  <div>
                                    <div className="text-sm font-medium">Version Created</div>
                                    <div className="text-sm text-muted-foreground">
                                      {format(usage.versionDetails.createdAt.toDate(), 'PPP')}
                                    </div>
                                  </div>
                                </div>
                                
                                {usage.versionDetails.changelog && (
                                  <div>
                                    <div className="text-sm font-medium mb-2">Changelog</div>
                                    <div className="text-sm bg-muted p-3 rounded-lg">
                                      {usage.versionDetails.changelog}
                                    </div>
                                  </div>
                                )}

                                <div>
                                  <div className="text-sm font-medium mb-2">
                                    Form Fields ({usage.versionDetails.schema.fields.length})
                                  </div>
                                  <ScrollArea className="h-48 border rounded-lg">
                                    <div className="p-3 space-y-2">
                                      {usage.versionDetails.schema.fields.map((field) => (
                                        <div key={field.id} className="flex items-center justify-between text-sm">
                                          <div>
                                            <span className="font-medium">{field.label}</span>
                                            <span className="text-muted-foreground ml-2 font-mono">
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
                                  <Button
                                    variant="outline"
                                    onClick={() => handleViewTemplate(usage.templateId)}
                                  >
                                    <ExternalLink className="h-4 w-4 mr-2" />
                                    Open in Builder
                                  </Button>
                                </div>
                              </div>
                            )}
                          </DialogContent>
                        </Dialog>
                        
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => handleViewTemplate(usage.templateId)}
                        >
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

/**
 * URL: http://localhost:3000/admin/projects/[projectId]/log-history
 * 
 * This page shows the complete history of template assignments for a project.
 * Features:
 * - Project information display
 * - Current active template highlight
 * - Chronological assignment history
 * - Template version details in modal
 * - Direct links to template builder/preview
 * - Assignment attribution and timestamps
 * - Field listing for each template version
 */