'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import {
  ArrowLeft,
  Save,
  Eye,
  Upload,
  Copy,
  Archive,
  History,
  Share,
  AlertCircle,
  CheckCircle,
} from 'lucide-react';
import { LogTemplate, LogSchema } from '@/lib/types/logbuilder';
import { TemplateService } from '@/lib/firestore/templates';
import { validateSchema } from '@/lib/utils/schemaDiff';

interface TemplateHeaderBarProps {
  template: LogTemplate;
  schema: LogSchema;
  onSave?: () => void;
  onPublish?: (changelog: string) => void;
  hasUnsavedChanges?: boolean;
  isSaving?: boolean;
}

export function TemplateHeaderBar({
  template,
  schema,
  onSave,
  onPublish,
  hasUnsavedChanges = false,
  isSaving = false,
}: TemplateHeaderBarProps) {
  const router = useRouter();
  const [showPublishDialog, setShowPublishDialog] = useState(false);
  const [changelog, setChangelog] = useState('');
  const [publishing, setPublishing] = useState(false);

  const templateService = new TemplateService();
  const validation = validateSchema(schema);

  const handleSave = async () => {
    if (onSave) {
      onSave();
    }
  };

  const handlePublish = async () => {
    if (!changelog.trim()) return;

    try {
      setPublishing(true);
      await templateService.publishTemplate(
        template.id,
        changelog,
        'current-user' // TODO: Get from auth context
      );
      
      if (onPublish) {
        onPublish(changelog);
      }
      
      setShowPublishDialog(false);
      setChangelog('');
    } catch (error) {
      console.error('Error publishing template:', error);
    } finally {
      setPublishing(false);
    }
  };

  const handleDuplicate = async () => {
    try {
      const newName = `${template.name} (Copy)`;
      const templateId = await templateService.duplicateTemplate(
        template.id,
        newName,
        'current-user'
      );
      router.push(`/admin/log-builder/${templateId}/edit`);
    } catch (error) {
      console.error('Error duplicating template:', error);
    }
  };

  const handleArchive = async () => {
    try {
      await templateService.archiveTemplate(template.id);
      router.push('/admin/log-builder');
    } catch (error) {
      console.error('Error archiving template:', error);
    }
  };

  const getStatusBadge = () => {
    switch (template.status) {
      case 'draft':
        return <Badge variant="secondary">Draft</Badge>;
      case 'published':
        return <Badge className="bg-green-500">Published v{template.latestVersion}</Badge>;
      case 'archived':
        return <Badge variant="outline">Archived</Badge>;
      default:
        return null;
    }
  };

  return (
    <Card className="border-b rounded-none bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <CardContent className="pt-6">
        <div className="flex items-center justify-between">
          {/* Left: Navigation and Template Info */}
          <div className="flex items-center gap-4">
            <Button
              variant="ghost"
              size="sm"
              onClick={() => router.push('/admin/log-builder')}
            >
              <ArrowLeft className="h-4 w-4 mr-2" />
              Back to Templates
            </Button>
            
            <div className="border-l pl-4">
              <h1 className="text-xl font-semibold">{template.name}</h1>
              <div className="flex items-center gap-2 text-sm text-muted-foreground">
                <span>{template.logType}</span>
                {getStatusBadge()}
                {hasUnsavedChanges && (
                  <Badge variant="outline" className="text-amber-600 border-amber-600">
                    Unsaved Changes
                  </Badge>
                )}
              </div>
            </div>
          </div>

          {/* Right: Actions */}
          <div className="flex items-center gap-2">
            {/* Validation Status */}
            <div className="flex items-center gap-2 mr-4">
              {validation.isValid ? (
                <div className="flex items-center gap-1 text-green-600">
                  <CheckCircle className="h-4 w-4" />
                  <span className="text-sm">Valid</span>
                </div>
              ) : (
                <div className="flex items-center gap-1 text-red-600">
                  <AlertCircle className="h-4 w-4" />
                  <span className="text-sm">{validation.errors.length} errors</span>
                </div>
              )}
            </div>

            <Button
              variant="outline"
              size="sm"
              onClick={() => router.push(`/admin/log-builder/${template.id}/preview`)}
            >
              <Eye className="h-4 w-4 mr-2" />
              Preview
            </Button>

            <Button
              variant="outline"
              size="sm"
              onClick={() => router.push(`/admin/log-builder/${template.id}/history`)}
            >
              <History className="h-4 w-4 mr-2" />
              History
            </Button>

            <Button
              variant="outline"
              size="sm"
              onClick={handleDuplicate}
            >
              <Copy className="h-4 w-4 mr-2" />
              Duplicate
            </Button>

            <Button
              variant="outline"
              size="sm"
              onClick={handleSave}
              disabled={isSaving || !hasUnsavedChanges}
            >
              <Save className="h-4 w-4 mr-2" />
              {isSaving ? 'Saving...' : 'Save Draft'}
            </Button>

            {template.status === 'draft' && (
              <Dialog open={showPublishDialog} onOpenChange={setShowPublishDialog}>
                <DialogTrigger asChild>
                  <Button
                    disabled={!validation.isValid || publishing}
                    className="bg-green-600 hover:bg-green-700"
                  >
                    <Upload className="h-4 w-4 mr-2" />
                    Publish
                  </Button>
                </DialogTrigger>
                <DialogContent>
                  <DialogHeader>
                    <DialogTitle>Publish Template</DialogTitle>
                    <DialogDescription>
                      Publishing will create version {template.latestVersion + 1} and make this template 
                      available for assignment to jobs. This action cannot be undone.
                    </DialogDescription>
                  </DialogHeader>
                  
                  <div className="space-y-4">
                    <div>
                      <Label htmlFor="changelog">Changelog</Label>
                      <Textarea
                        id="changelog"
                        value={changelog}
                        onChange={(e) => setChangelog(e.target.value)}
                        placeholder="Describe what changed in this version..."
                        rows={4}
                      />
                    </div>

                    {validation.warnings.length > 0 && (
                      <div className="p-3 bg-amber-50 border border-amber-200 rounded-lg">
                        <div className="flex items-start gap-2">
                          <AlertCircle className="h-4 w-4 text-amber-600 mt-0.5" />
                          <div>
                            <h4 className="text-sm font-medium text-amber-800">Warnings</h4>
                            <ul className="mt-1 text-sm text-amber-700 space-y-1">
                              {validation.warnings.map((warning, index) => (
                                <li key={index}>• {warning}</li>
                              ))}
                            </ul>
                          </div>
                        </div>
                      </div>
                    )}
                  </div>

                  <DialogFooter>
                    <Button
                      variant="outline"
                      onClick={() => setShowPublishDialog(false)}
                      disabled={publishing}
                    >
                      Cancel
                    </Button>
                    <Button
                      onClick={handlePublish}
                      disabled={!changelog.trim() || publishing}
                      className="bg-green-600 hover:bg-green-700"
                    >
                      {publishing ? 'Publishing...' : `Publish v${template.latestVersion + 1}`}
                    </Button>
                  </DialogFooter>
                </DialogContent>
              </Dialog>
            )}

            {template.status !== 'archived' && (
              <Button
                variant="outline"
                size="sm"
                onClick={handleArchive}
                className="text-destructive border-destructive hover:bg-destructive hover:text-destructive-foreground"
              >
                <Archive className="h-4 w-4 mr-2" />
                Archive
              </Button>
            )}
          </div>
        </div>

        {/* Validation Errors */}
        {!validation.isValid && (
          <div className="mt-4 p-3 bg-red-50 border border-red-200 rounded-lg">
            <div className="flex items-start gap-2">
              <AlertCircle className="h-4 w-4 text-red-600 mt-0.5" />
              <div>
                <h4 className="text-sm font-medium text-red-800 mb-1">
                  Template has validation errors:
                </h4>
                <ul className="text-sm text-red-700 space-y-1">
                  {validation.errors.map((error, index) => (
                    <li key={index}>• {error}</li>
                  ))}
                </ul>
              </div>
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  );
}