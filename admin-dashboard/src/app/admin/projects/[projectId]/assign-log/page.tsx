'use client';

import { useState, useEffect } from 'react';
import { useParams, useRouter } from 'next/navigation';
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
import { Separator } from '@/components/ui/separator';
import { ScrollArea } from '@/components/ui/scroll-area';
import {
  ArrowLeft,
  FileText,
  CheckCircle,
  AlertCircle,
  Calendar,
  User,
  Layers,
  Save,
  Eye,
  History,
} from 'lucide-react';
import { LogTemplate, LogTemplateVersion } from '@/lib/types/logbuilder';
import { Project } from '@/lib/firestore/projects';
import { TemplateService } from '@/lib/firestore/templates';
import { ProjectService } from '@/lib/firestore/projects';
import { formatDistanceToNow } from 'date-fns';

export default function AssignLogPage() {
  const params = useParams();
  const router = useRouter();
  const projectId = params.projectId as string;

  const [project, setProject] = useState<Project | null>(null);
  const [templates, setTemplates] = useState<LogTemplate[]>([]);
  const [versions, setVersions] = useState<LogTemplateVersion[]>([]);
  const [selectedTemplateId, setSelectedTemplateId] = useState<string>('');
  const [selectedVersion, setSelectedVersion] = useState<number | null>(null);
  const [loading, setLoading] = useState(true);
  const [assigning, setAssigning] = useState(false);
  const [showConfirmDialog, setShowConfirmDialog] = useState(false);

  const templateService = new TemplateService();
  const projectService = new ProjectService();

  useEffect(() => {
    loadData();
  }, [projectId]);

  useEffect(() => {
    if (selectedTemplateId) {
      loadVersions();
    } else {
      setVersions([]);
      setSelectedVersion(null);
    }
  }, [selectedTemplateId]);

  const loadData = async () => {
    try {
      setLoading(true);
      const [projectData, templatesData] = await Promise.all([
        projectService.getProject(projectId),
        templateService.getTemplates({ status: 'published' }),
      ]);

      if (projectData) {
        setProject(projectData);
        // Pre-select current template if assigned
        if (projectData.assignedTemplateId) {
          setSelectedTemplateId(projectData.assignedTemplateId);
          setSelectedVersion(projectData.assignedVersion || null);
        }
      }
      setTemplates(templatesData);
    } catch (error) {
      console.error('Error loading data:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadVersions = async () => {
    try {
      const versionsData = await templateService.getTemplateVersions(selectedTemplateId);
      setVersions(versionsData);
      
      // Auto-select latest version if none selected
      if (!selectedVersion && versionsData.length > 0) {
        setSelectedVersion(versionsData[0].version);
      }
    } catch (error) {
      console.error('Error loading versions:', error);
    }
  };

  const handleAssignTemplate = async () => {
    if (!project || !selectedTemplateId || selectedVersion === null) return;

    try {
      setAssigning(true);
      const template = templates.find(t => t.id === selectedTemplateId);
      
      await projectService.assignTemplate(
        project.id,
        selectedTemplateId,
        template?.name || 'Unknown Template',
        selectedVersion,
        'current-user' // TODO: Get from auth context
      );

      setShowConfirmDialog(false);
      router.push(`/admin/projects/${projectId}/log-history`);
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
      <div className="container mx-auto p-6 space-y-6">
        <div className="h-8 bg-muted rounded animate-pulse" />
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div className="h-96 bg-muted rounded animate-pulse" />
          <div className="h-96 bg-muted rounded animate-pulse" />
        </div>
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
            <h1 className="text-3xl font-bold">Assign Log Template</h1>
            <p className="text-muted-foreground">
              Configure which template operators use for this project
            </p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            onClick={() => router.push(`/admin/projects/${projectId}/log-history`)}
          >
            <History className="h-4 w-4 mr-2" />
            View History
          </Button>
          <Button
            onClick={() => setShowConfirmDialog(true)}
            disabled={!hasChanges || !selectedTemplateId || selectedVersion === null}
          >
            <Save className="h-4 w-4 mr-2" />
            Assign Template
          </Button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Left: Project Info & Template Selection */}
        <div className="space-y-6">
          {/* Project Information */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Layers className="h-5 w-5" />
                Project Information
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <Label className="text-sm font-medium">Project Number</Label>
                <div className="text-lg font-mono">{project.projectNumber}</div>
              </div>
              <div>
                <Label className="text-sm font-medium">Facility</Label>
                <div>{project.facility}</div>
              </div>
              <div>
                <Label className="text-sm font-medium">Tank ID</Label>
                <div className="font-mono">{project.tankId}</div>
              </div>
              
              {project.assignedTemplateId && (
                <div className="p-3 bg-blue-50 border border-blue-200 rounded-lg">
                  <div className="flex items-center gap-2 mb-2">
                    <CheckCircle className="h-4 w-4 text-blue-600" />
                    <span className="font-medium text-blue-800">Currently Assigned</span>
                  </div>
                  <div className="text-sm text-blue-700">
                    {templates.find(t => t.id === project.assignedTemplateId)?.name || 'Unknown Template'} 
                    <span className="ml-2">v{project.assignedVersion}</span>
                  </div>
                  {project.assignedAt && (
                    <div className="text-xs text-blue-600 mt-1">
                      Assigned {formatDistanceToNow(project.assignedAt.toDate(), { addSuffix: true })}
                    </div>
                  )}
                </div>
              )}
            </CardContent>
          </Card>

          {/* Template Selection */}
          <Card>
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
                  <SelectTrigger>
                    <SelectValue placeholder="Choose a template" />
                  </SelectTrigger>
                  <SelectContent>
                    {templates.map((template) => (
                      <SelectItem key={template.id} value={template.id}>
                        <div className="flex items-center justify-between w-full">
                          <span>{template.name}</span>
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
                    <SelectTrigger>
                      <SelectValue placeholder="Choose a version" />
                    </SelectTrigger>
                    <SelectContent>
                      {versions.map((version) => (
                        <SelectItem key={version.version} value={version.version.toString()}>
                          <div className="flex items-center justify-between w-full">
                            <span>Version {version.version}</span>
                            <span className="text-xs text-muted-foreground ml-2">
                              {formatDistanceToNow(version.createdAt.toDate(), { addSuffix: true })}
                            </span>
                          </div>
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              )}
            </CardContent>
          </Card>
        </div>

        {/* Right: Template Preview */}
        <div className="space-y-6">
          {selectedTemplate && selectedVersionData ? (
            <>
              {/* Template Details */}
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <Eye className="h-5 w-5" />
                    Template Details
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div>
                    <Label className="text-sm font-medium">Name</Label>
                    <div className="text-lg">{selectedTemplate.name}</div>
                  </div>
                  <div>
                    <Label className="text-sm font-medium">Log Type</Label>
                    <Badge variant="secondary">{selectedTemplate.logType}</Badge>
                  </div>
                  <div>
                    <Label className="text-sm font-medium">Version</Label>
                    <div>v{selectedVersionData.version}</div>
                  </div>
                  <div>
                    <Label className="text-sm font-medium">Created</Label>
                    <div className="text-sm text-muted-foreground">
                      {formatDistanceToNow(selectedVersionData.createdAt.toDate(), { addSuffix: true })}
                      <span className="ml-2">by {selectedVersionData.createdBy}</span>
                    </div>
                  </div>
                  
                  {selectedVersionData.changelog && (
                    <div>
                      <Label className="text-sm font-medium">Changelog</Label>
                      <div className="text-sm bg-muted p-3 rounded-lg">
                        {selectedVersionData.changelog}
                      </div>
                    </div>
                  )}
                </CardContent>
              </Card>

              {/* Schema Preview */}
              <Card>
                <CardHeader>
                  <CardTitle>Form Fields</CardTitle>
                </CardHeader>
                <CardContent>
                  <ScrollArea className="h-64">
                    <div className="space-y-2">
                      {selectedVersionData.schema.fields.map((field) => (
                        <div key={field.id} className="flex items-center justify-between p-2 border rounded">
                          <div>
                            <div className="font-medium text-sm">{field.label}</div>
                            <div className="text-xs text-muted-foreground font-mono">
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
                  
                  <div className="mt-4 pt-4 border-t">
                    <Button
                      variant="outline"
                      className="w-full"
                      onClick={() => router.push(`/admin/log-builder/${selectedTemplateId}/preview`)}
                    >
                      <Eye className="h-4 w-4 mr-2" />
                      Preview Template
                    </Button>
                  </div>
                </CardContent>
              </Card>
            </>
          ) : (
            <Card>
              <CardContent className="flex items-center justify-center h-64">
                <div className="text-center text-muted-foreground">
                  <FileText className="h-12 w-12 mx-auto mb-4 opacity-20" />
                  <p>Select a template to see details</p>
                </div>
              </CardContent>
            </Card>
          )}
        </div>
      </div>

      {/* Confirmation Dialog */}
      <Dialog open={showConfirmDialog} onOpenChange={setShowConfirmDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Confirm Template Assignment</DialogTitle>
            <DialogDescription>
              This will assign the selected template to the project. Operators will use this 
              template for data entry.
            </DialogDescription>
          </DialogHeader>
          
          <div className="space-y-4">
            <div className="p-4 bg-muted rounded-lg">
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <span className="font-medium">Project:</span>
                  <div className="font-mono">{project.projectNumber}</div>
                </div>
                <div>
                  <span className="font-medium">Template:</span>
                  <div>{selectedTemplate?.name}</div>
                </div>
                <div>
                  <span className="font-medium">Version:</span>
                  <div>v{selectedVersion}</div>
                </div>
                <div>
                  <span className="font-medium">Log Type:</span>
                  <div>{selectedTemplate?.logType}</div>
                </div>
              </div>
            </div>

            {project.assignedTemplateId && (
              <div className="p-3 bg-amber-50 border border-amber-200 rounded-lg">
                <div className="flex items-start gap-2">
                  <AlertCircle className="h-4 w-4 text-amber-600 mt-0.5" />
                  <div className="text-sm text-amber-800">
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
            >
              {assigning ? 'Assigning...' : 'Assign Template'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

/**
 * URL: http://localhost:3000/admin/projects/[projectId]/assign-log
 * 
 * This page allows administrators to assign log templates to projects.
 * Features:
 * - Project information display
 * - Template selection (published templates only)
 * - Version selection with changelog
 * - Template preview and field listing
 * - Assignment confirmation with history tracking
 * - Current assignment status display
 */