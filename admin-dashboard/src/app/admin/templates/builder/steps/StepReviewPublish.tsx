'use client';

import React, { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Badge } from '@/components/ui/badge';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Textarea } from '@/components/ui/textarea';
import { Label } from '@/components/ui/label';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { 
  Eye, 
  GitCompare, 
  Rocket, 
  Save, 
  Copy, 
  Users, 
  CheckCircle, 
  AlertCircle, 
  History,
  FileText,
  Settings,
  Target
} from 'lucide-react';
import { VersionDiffViewer } from '../components/VersionDiffViewer';
import { AssignToJobsModal } from '../components/AssignToJobsModal';
import { VersionedTemplateService } from '@/lib/logs/templates/versioned-service';
import { LogTemplate, TemplateVersion, filterFieldsByConditions, MASTER_FIELDS } from '@/lib/logs/templates/versioned-types';

interface StepReviewPublishProps {
  state: any;
  updateState: (updates: any) => void;
  onComplete: (action: 'draft' | 'publish') => Promise<void>;
  template: LogTemplate | null;
  currentVersion: TemplateVersion | null;
}

export function StepReviewPublish({ 
  state, 
  updateState, 
  onComplete, 
  template, 
  currentVersion 
}: StepReviewPublishProps) {
  const [changelog, setChangelog] = useState('');
  const [showAssignModal, setShowAssignModal] = useState(false);
  const [showDiffModal, setShowDiffModal] = useState(false);
  const [validationResult, setValidationResult] = useState<{ valid: boolean; errors: string[] }>({ valid: true, errors: [] });
  const [isValidating, setIsValidating] = useState(false);

  useEffect(() => {
    validateTemplate();
  }, [state]);

  const validateTemplate = async () => {
    setIsValidating(true);
    
    try {
      // Get filtered fields based on current configuration
      const filteredFields = filterFieldsByConditions(MASTER_FIELDS, state.gasType, state.toggles);
      
      const mockVersion: TemplateVersion = {
        version: currentVersion?.version ? currentVersion.version + 1 : 1,
        status: 'draft',
        toggles: state.toggles,
        gasType: state.gasType,
        fields: filteredFields,
        targets: state.targets,
        ui: {
          groups: ['core', 'monitoring', 'operator'],
          layout: 'standard',
        },
        excelTemplatePath: state.excelTemplatePath,
        operationRange: {
          start: 'B12',
          end: 'N28',
          sheet: 'Sheet1',
        },
        createdAt: Date.now(),
        createdBy: 'admin',
        hash: '',
      };

      const validation = VersionedTemplateService.validateVersion(mockVersion);
      setValidationResult(validation);
    } catch (error) {
      setValidationResult({ 
        valid: false, 
        errors: ['Validation failed: ' + (error instanceof Error ? error.message : 'Unknown error')] 
      });
    } finally {
      setIsValidating(false);
    }
  };

  const getVersionLabel = () => {
    if (state.isEditing && currentVersion) {
      return `Will save as v${currentVersion.version + 1} derived from v${currentVersion.version}`;
    }
    return 'Will save as v1 (initial version)';
  };

  const handlePublish = async () => {
    if (!validationResult.valid) return;
    await onComplete('publish');
  };

  const handleSaveDraft = async () => {
    await onComplete('draft');
  };

  const handleDuplicate = () => {
    // Navigate to create new version
    const params = new URLSearchParams({
      mode: 'clone',
      templateId: template?.id || '',
      versionId: currentVersion?.id || '',
    });
    window.location.href = `/admin/templates/builder?${params.toString()}`;
  };

  // Calculate configuration summary
  const filteredFields = filterFieldsByConditions(MASTER_FIELDS, state.gasType, state.toggles);
  const requiredFields = filteredFields.filter(f => f.required);
  const enabledFeatures = Object.entries(state.toggles).filter(([_, value]) => value);
  const configuredTargets = Object.entries(state.targets).filter(([_, value]) => value != null);

  return (
    <div className="space-y-6">
      {/* Version Info Banner */}
      <Alert className="bg-blue-50 dark:bg-blue-950 border-blue-500">
        <History className="w-4 h-4" />
        <AlertDescription>
          <strong>{getVersionLabel()}</strong>
          {state.derivedFromVersion && (
            <span className="ml-2 text-sm text-gray-400">
              (Derived from v{state.derivedFromVersion})
            </span>
          )}
        </AlertDescription>
      </Alert>

      {/* Validation Status */}
      {isValidating ? (
        <Alert>
          <AlertCircle className="w-4 h-4" />
          <AlertDescription>Validating template configuration...</AlertDescription>
        </Alert>
      ) : validationResult.valid ? (
        <Alert className="bg-green-50 dark:bg-green-950 border-green-500">
          <CheckCircle className="w-4 h-4" />
          <AlertDescription>
            Template configuration is valid and ready for publishing.
          </AlertDescription>
        </Alert>
      ) : (
        <Alert variant="destructive">
          <AlertCircle className="w-4 h-4" />
          <AlertDescription>
            <div>
              <strong>Validation Issues:</strong>
              <ul className="list-disc list-inside mt-1">
                {validationResult.errors.map((error, index) => (
                  <li key={index} className="text-sm">{error}</li>
                ))}
              </ul>
            </div>
          </AlertDescription>
        </Alert>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Review Content */}
        <div className="lg:col-span-2">
          <Tabs defaultValue="summary" className="w-full">
            <TabsList className="grid w-full grid-cols-3">
              <TabsTrigger value="summary">Summary</TabsTrigger>
              <TabsTrigger value="diff">Changes</TabsTrigger>
              <TabsTrigger value="preview">Preview</TabsTrigger>
            </TabsList>

            <TabsContent value="summary" className="mt-6">
              <div className="space-y-6">
                {/* Basic Info */}
                <Card className="bg-[#2A2A2A] border-gray-600">
                  <CardHeader>
                    <CardTitle className="text-white flex items-center gap-2">
                      <FileText className="w-5 h-5" />
                      Template Information
                    </CardTitle>
                  </CardHeader>
                  <CardContent className="space-y-4">
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <Label className="text-gray-400">Name</Label>
                        <div className="text-white font-medium">{state.name}</div>
                      </div>
                      <div>
                        <Label className="text-gray-400">Key</Label>
                        <div className="text-white font-mono text-sm">{state.templateKey}</div>
                      </div>
                      <div>
                        <Label className="text-gray-400">Gas Type</Label>
                        <Badge className="bg-blue-600 text-white">
                          {state.gasType.toUpperCase()}
                        </Badge>
                      </div>
                      <div>
                        <Label className="text-gray-400">Family</Label>
                        <Badge variant="outline">
                          {state.gasFamily}
                        </Badge>
                      </div>
                    </div>
                  </CardContent>
                </Card>

                {/* Configuration */}
                <Card className="bg-[#2A2A2A] border-gray-600">
                  <CardHeader>
                    <CardTitle className="text-white flex items-center gap-2">
                      <Settings className="w-5 h-5" />
                      Configuration
                    </CardTitle>
                  </CardHeader>
                  <CardContent className="space-y-4">
                    <div className="grid grid-cols-4 gap-4 text-center">
                      <div>
                        <div className="text-2xl font-bold text-white">{filteredFields.length}</div>
                        <div className="text-sm text-gray-400">Total Fields</div>
                      </div>
                      <div>
                        <div className="text-2xl font-bold text-orange-400">{requiredFields.length}</div>
                        <div className="text-sm text-gray-400">Required</div>
                      </div>
                      <div>
                        <div className="text-2xl font-bold text-blue-400">{enabledFeatures.length}</div>
                        <div className="text-sm text-gray-400">Features</div>
                      </div>
                      <div>
                        <div className="text-2xl font-bold text-green-400">{configuredTargets.length}</div>
                        <div className="text-sm text-gray-400">Targets</div>
                      </div>
                    </div>

                    {enabledFeatures.length > 0 && (
                      <div>
                        <Label className="text-gray-400">Enabled Features</Label>
                        <div className="flex flex-wrap gap-2 mt-2">
                          {enabledFeatures.map(([key, _]) => (
                            <Badge key={key} variant="outline" className="border-green-500 text-green-300">
                              {key.replace(/([A-Z])/g, ' $1').replace(/^./, str => str.toUpperCase())}
                            </Badge>
                          ))}
                        </div>
                      </div>
                    )}
                  </CardContent>
                </Card>

                {/* Targets */}
                {configuredTargets.length > 0 && (
                  <Card className="bg-[#2A2A2A] border-gray-600">
                    <CardHeader>
                      <CardTitle className="text-white flex items-center gap-2">
                        <Target className="w-5 h-5" />
                        Threshold Targets
                      </CardTitle>
                    </CardHeader>
                    <CardContent>
                      <div className="grid grid-cols-2 gap-4">
                        {configuredTargets.map(([key, value]) => (
                          <div key={key} className="flex justify-between items-center">
                            <span className="text-gray-300">
                              {key.replace(/([A-Z])/g, ' $1').replace(/^./, str => str.toUpperCase())}
                            </span>
                            <Badge variant="outline">
                              {value} {key.includes('PPM') ? 'PPM' : key.includes('Pct') ? '%' : 'BBL/HR'}
                            </Badge>
                          </div>
                        ))}
                      </div>
                    </CardContent>
                  </Card>
                )}
              </div>
            </TabsContent>

            <TabsContent value="diff" className="mt-6">
              {currentVersion ? (
                <VersionDiffViewer
                  templateId={template?.id || ''}
                  oldVersionId={currentVersion.id || ''}
                  newState={state}
                />
              ) : (
                <Card className="bg-[#2A2A2A] border-gray-600">
                  <CardContent className="pt-6">
                    <div className="text-center py-8">
                      <GitCompare className="w-12 h-12 text-gray-400 mx-auto mb-4" />
                      <h3 className="text-lg font-medium text-white mb-2">New Template</h3>
                      <p className="text-gray-400">
                        This is a new template. No previous version to compare against.
                      </p>
                    </div>
                  </CardContent>
                </Card>
              )}
            </TabsContent>

            <TabsContent value="preview" className="mt-6">
              <Card className="bg-[#2A2A2A] border-gray-600">
                <CardHeader>
                  <CardTitle className="text-white">Excel Structure Preview</CardTitle>
                  <CardDescription className="text-gray-400">
                    Final Excel structure that will be used for data entry
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="bg-white rounded-lg p-4 overflow-auto max-h-64">
                    <table className="min-w-full text-xs">
                      <thead>
                        <tr className="bg-gray-100">
                          <th className="border border-gray-300 px-2 py-1">Time</th>
                          <th className="border border-gray-300 px-2 py-1">Date</th>
                          {filteredFields.map(field => (
                            <th key={field.key} className="border border-gray-300 px-2 py-1">
                              {field.label}
                              {field.unit && ` (${field.unit})`}
                              {field.required && <span className="text-red-500">*</span>}
                            </th>
                          ))}
                        </tr>
                      </thead>
                      <tbody>
                        {Array.from({ length: 5 }, (_, i) => (
                          <tr key={i}>
                            <td className="border border-gray-300 px-2 py-1 bg-gray-50">
                              {(i).toString().padStart(2, '0')}:00
                            </td>
                            <td className="border border-gray-300 px-2 py-1 bg-gray-50">
                              MM/DD/YYYY
                            </td>
                            {filteredFields.map(field => (
                              <td key={field.key} className="border border-gray-300 px-2 py-1 bg-blue-50">
                                ---
                              </td>
                            ))}
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                  <div className="mt-4 text-sm text-gray-400">
                    Sample showing first 5 hours. Actual template will include full operation range.
                  </div>
                </CardContent>
              </Card>
            </TabsContent>
          </Tabs>
        </div>

        {/* Actions Sidebar */}
        <div className="space-y-6">
          {/* Changelog */}
          <Card className="bg-[#2A2A2A] border-gray-600">
            <CardHeader>
              <CardTitle className="text-white">Changelog</CardTitle>
              <CardDescription className="text-gray-400">
                Describe what changed in this version
              </CardDescription>
            </CardHeader>
            <CardContent>
              <Textarea
                value={changelog}
                onChange={(e) => setChangelog(e.target.value)}
                placeholder="e.g., Added H2S monitoring, updated target thresholds..."
                className="bg-[#1E1E1E] border-gray-600 text-white"
                rows={4}
              />
            </CardContent>
          </Card>

          {/* Actions */}
          <Card className="bg-[#2A2A2A] border-gray-600">
            <CardHeader>
              <CardTitle className="text-white">Actions</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <Button
                onClick={handleSaveDraft}
                variant="outline"
                className="w-full border-gray-600 text-gray-300 hover:bg-gray-700"
              >
                <Save className="w-4 h-4 mr-2" />
                Save Draft
              </Button>

              <Button
                onClick={handlePublish}
                disabled={!validationResult.valid}
                className="w-full bg-orange-600 hover:bg-orange-700"
              >
                <Rocket className="w-4 h-4 mr-2" />
                Publish (Active)
              </Button>

              {template && currentVersion && (
                <Button
                  onClick={handleDuplicate}
                  variant="outline"
                  className="w-full border-gray-600 text-gray-300 hover:bg-gray-700"
                >
                  <Copy className="w-4 h-4 mr-2" />
                  Duplicate as New
                </Button>
              )}

              <Button
                onClick={() => setShowAssignModal(true)}
                disabled={!validationResult.valid}
                variant="outline"
                className="w-full border-blue-600 text-blue-300 hover:bg-blue-700"
              >
                <Users className="w-4 h-4 mr-2" />
                Assign to Jobs
              </Button>
            </CardContent>
          </Card>

          {/* Version Info */}
          <Card className="bg-[#2A2A2A] border-gray-600">
            <CardHeader>
              <CardTitle className="text-white">Version Information</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="flex justify-between">
                <span className="text-gray-400">Version</span>
                <Badge>
                  {currentVersion ? `v${currentVersion.version + 1}` : 'v1'}
                </Badge>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-400">Status</span>
                <Badge variant="outline">
                  Draft
                </Badge>
              </div>
              {state.derivedFromVersion && (
                <div className="flex justify-between">
                  <span className="text-gray-400">Derived from</span>
                  <Badge variant="outline">
                    v{state.derivedFromVersion}
                  </Badge>
                </div>
              )}
              <div className="flex justify-between">
                <span className="text-gray-400">Fields</span>
                <span className="text-white">{filteredFields.length}</span>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Assign to Jobs Modal */}
      <AssignToJobsModal
        open={showAssignModal}
        onClose={() => setShowAssignModal(false)}
        templateId={template?.id || ''}
        templateKey={state.templateKey}
        templateName={state.name}
        onAssign={(jobIds) => {
          // TODO: Handle assignment
          console.log('Assigning to jobs:', jobIds);
          setShowAssignModal(false);
        }}
      />
    </div>
  );
}