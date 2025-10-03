'use client';

import { useState, useEffect } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Textarea } from '@/components/ui/textarea';
import { Badge } from '@/components/ui/badge';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { 
  Save, 
  Upload, 
  Download, 
  CheckCircle, 
  AlertCircle, 
  FileText,
  ArrowLeft,
  RefreshCw
} from 'lucide-react';
import { MetricDesignerPanel } from '@/components/template/MetricDesignerPanel';
import { TemplateGridPreview } from '@/components/template/TemplateGridPreview';
import { StructureValidationPanel } from '@/components/template/StructureValidationPanel';
import { TemplateService } from '@/lib/services/template.service';
import { LogTemplate, TemplateMetric, StructureCheckResult, createDefaultTemplate, DEFAULT_HOURS, DEFAULT_HOUR_GROUPS } from '@/lib/types/template';

export default function LogTemplateEditor() {
  const params = useParams();
  const router = useRouter();
  const projectId = params.projectId as string;
  
  const [template, setTemplate] = useState<LogTemplate | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [isValidating, setIsValidating] = useState(false);
  const [hasUnsavedChanges, setHasUnsavedChanges] = useState(false);
  const [structureCheck, setStructureCheck] = useState<StructureCheckResult | null>(null);
  const [selectedLogType, setSelectedLogType] = useState('methane_hourly');
  
  const templateService = TemplateService.getInstance();

  useEffect(() => {
    loadTemplate();
  }, [selectedLogType]);

  const loadTemplate = async () => {
    setIsLoading(true);
    try {
      const loadedTemplate = await templateService.getTemplate(selectedLogType);
      if (loadedTemplate) {
        setTemplate(loadedTemplate);
      } else {
        // Create new template
        const newTemplate = createDefaultTemplate(selectedLogType);
        setTemplate(newTemplate);
        setHasUnsavedChanges(true);
      }
    } catch (error) {
      console.error('Error loading template:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleMetricsChange = (metrics: TemplateMetric[]) => {
    if (!template) return;
    
    setTemplate(prev => ({
      ...prev!,
      metrics
    }));
    setHasUnsavedChanges(true);
  };

  const handleTemplateMetadataChange = (field: string, value: any) => {
    if (!template) return;
    
    setTemplate(prev => ({
      ...prev!,
      [field]: value
    }));
    setHasUnsavedChanges(true);
  };

  const handleSaveTemplate = async () => {
    if (!template) return;
    
    setIsSaving(true);
    try {
      await templateService.saveTemplate(template, 'admin'); // TODO: Get from auth
      setHasUnsavedChanges(false);
      
      // Show success message
      const message = document.createElement('div');
      message.className = 'fixed top-4 right-4 bg-green-600 text-white px-4 py-2 rounded-lg z-50';
      message.textContent = `Template saved successfully (v${template.version + 1})`;
      document.body.appendChild(message);
      setTimeout(() => document.body.removeChild(message), 3000);
      
    } catch (error) {
      console.error('Error saving template:', error);
      
      // Show error message
      const message = document.createElement('div');
      message.className = 'fixed top-4 right-4 bg-red-600 text-white px-4 py-2 rounded-lg z-50';
      message.textContent = 'Failed to save template';
      document.body.appendChild(message);
      setTimeout(() => document.body.removeChild(message), 3000);
    } finally {
      setIsSaving(false);
    }
  };


  const exportTemplate = () => {
    if (!template) return;
    
    const dataStr = JSON.stringify(template, null, 2);
    const dataBlob = new Blob([dataStr], { type: 'application/json' });
    const url = URL.createObjectURL(dataBlob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `${template.logType}_template_v${template.version}.json`;
    link.click();
    URL.revokeObjectURL(url);
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-[#111111] flex items-center justify-center">
        <div className="text-center">
          <RefreshCw className="h-8 w-8 animate-spin text-orange-500 mx-auto mb-4" />
          <p className="text-gray-400">Loading template...</p>
        </div>
      </div>
    );
  }

  if (!template) {
    return (
      <div className="min-h-screen bg-[#111111] flex items-center justify-center">
        <div className="text-center">
          <AlertCircle className="h-8 w-8 text-red-500 mx-auto mb-4" />
          <p className="text-gray-400">Failed to load template</p>
          <Button onClick={loadTemplate} className="mt-4">
            Retry
          </Button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#111111]">
      {/* Header */}
      <div className="bg-[#1E1E1E] border-b border-gray-800 p-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <Button
              variant="ghost"
              onClick={() => router.back()}
              className="text-gray-400 hover:text-white"
            >
              <ArrowLeft className="h-4 w-4 mr-2" />
              Back
            </Button>
            
            <div>
              <h1 className="text-xl font-bold text-white">Log Template Editor</h1>
              <p className="text-gray-400 text-sm">Project: {projectId}</p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            {hasUnsavedChanges && (
              <Badge className="bg-yellow-600 text-white border-0">
                Unsaved Changes
              </Badge>
            )}
            
            <Badge className="bg-blue-600 text-white border-0">
              v{template.version}
            </Badge>

            <Button
              onClick={exportTemplate}
              variant="outline"
              size="sm"
              className="border-gray-600 text-gray-300 hover:bg-gray-800"
            >
              <Download className="h-4 w-4 mr-2" />
              Export
            </Button>

            <Button
              onClick={handleSaveTemplate}
              disabled={isSaving || !hasUnsavedChanges}
              className="bg-orange-600 hover:bg-orange-700 text-white"
            >
              {isSaving ? (
                <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
              ) : (
                <Save className="h-4 w-4 mr-2" />
              )}
              Save Template
            </Button>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="flex h-[calc(100vh-80px)]">
        {/* Left Panel - Metrics Designer */}
        <div className="w-80 border-r border-gray-800 flex flex-col">
          {/* Template Metadata */}
          <Card className="bg-[#1E1E1E] border-gray-800 rounded-none border-b">
            <CardHeader>
              <CardTitle className="text-white text-sm">Template Settings</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              {/* Log Type */}
              <div>
                <Label className="text-gray-300 text-sm">Log Type</Label>
                <Select 
                  value={selectedLogType} 
                  onValueChange={setSelectedLogType}
                >
                  <SelectTrigger className="bg-gray-800 border-gray-700 text-white text-sm">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent className="bg-gray-800 border-gray-700">
                    <SelectItem value="methane_hourly" className="text-white">
                      Methane Hourly
                    </SelectItem>
                    <SelectItem value="benzene_12hr" className="text-white">
                      Benzene 12HR
                    </SelectItem>
                    <SelectItem value="custom" className="text-white">
                      Custom Template
                    </SelectItem>
                  </SelectContent>
                </Select>
              </div>

              {/* Display Name */}
              <div>
                <Label className="text-gray-300 text-sm">Display Name</Label>
                <Input
                  value={template.displayName}
                  onChange={(e) => handleTemplateMetadataChange('displayName', e.target.value)}
                  className="bg-gray-800 border-gray-700 text-white text-sm"
                />
              </div>

              {/* Description */}
              <div>
                <Label className="text-gray-300 text-sm">Description</Label>
                <Textarea
                  value={template.description || ''}
                  onChange={(e) => handleTemplateMetadataChange('description', e.target.value)}
                  className="bg-gray-800 border-gray-700 text-white text-sm h-20"
                  placeholder="Template description..."
                />
              </div>

            </CardContent>
          </Card>

          {/* Metrics Designer */}
          <div className="flex-1 overflow-hidden">
            <MetricDesignerPanel
              metrics={template.metrics}
              onMetricsChange={handleMetricsChange}
            />
          </div>
        </div>

        {/* Right Panel - Grid Preview */}
        <div className="flex-1 overflow-auto p-4">
          <div className="space-y-4">
            {/* Preview Header */}
            <Card className="bg-[#1E1E1E] border-gray-800">
              <CardHeader>
                <div className="flex items-center justify-between">
                  <div>
                    <CardTitle className="text-white">Template Preview</CardTitle>
                    <p className="text-gray-400 text-sm">
                      Live preview of how the template will appear to operators
                    </p>
                  </div>
                  <div className="flex items-center gap-2">
                    <Badge className="bg-purple-600 text-white border-0">
                      Live Preview
                    </Badge>
                    <Badge className="bg-gray-600 text-white border-0">
                      {template.metrics.filter(m => m.visible).length} visible metrics
                    </Badge>
                  </div>
                </div>
              </CardHeader>
            </Card>

            {/* Grid Preview */}
            <TemplateGridPreview
              template={template}
              isEditable={false}
              showMetadata={true}
            />

            {/* Structure Validation */}
            <StructureValidationPanel
              template={template}
              onValidationComplete={setStructureCheck}
            />

            {/* Structure Check Results */}
            {structureCheck && !structureCheck.passed && (
              <Card className="bg-[#1E1E1E] border-red-600">
                <CardHeader>
                  <CardTitle className="text-red-400 flex items-center gap-2">
                    <AlertCircle className="h-5 w-5" />
                    Structure Validation Issues
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-3">
                    {structureCheck.mismatches.map((mismatch, index) => (
                      <div 
                        key={index}
                        className={`p-3 rounded border ${
                          mismatch.severity === 'error' 
                            ? 'border-red-600 bg-red-900/20' 
                            : 'border-yellow-600 bg-yellow-900/20'
                        }`}
                      >
                        <div className="flex items-center gap-2 mb-1">
                          <Badge 
                            className={`text-xs ${
                              mismatch.severity === 'error' 
                                ? 'bg-red-600 text-white' 
                                : 'bg-yellow-600 text-white'
                            } border-0`}
                          >
                            {mismatch.severity}
                          </Badge>
                          <span className="text-white text-sm font-medium">
                            {mismatch.type.replace('_', ' ')}
                          </span>
                        </div>
                        <p className="text-gray-300 text-sm">
                          Expected: {mismatch.expected}
                        </p>
                        <p className="text-gray-300 text-sm">
                          Actual: {mismatch.actual}
                        </p>
                        {mismatch.suggestion && (
                          <p className="text-blue-300 text-sm mt-1">
                            💡 {mismatch.suggestion}
                          </p>
                        )}
                      </div>
                    ))}
                    
                    {structureCheck.warnings.length > 0 && (
                      <div className="border-t border-gray-700 pt-3">
                        <h4 className="text-yellow-400 text-sm font-medium mb-2">Warnings:</h4>
                        {structureCheck.warnings.map((warning, index) => (
                          <p key={index} className="text-gray-300 text-sm">
                            ⚠️ {warning}
                          </p>
                        ))}
                      </div>
                    )}
                  </div>
                </CardContent>
              </Card>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}