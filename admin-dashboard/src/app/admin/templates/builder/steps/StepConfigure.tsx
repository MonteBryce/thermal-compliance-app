'use client';

import React, { useState, useRef } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Badge } from '@/components/ui/badge';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Upload, Eye, Settings, FileSpreadsheet, AlertCircle, CheckCircle } from 'lucide-react';
import { LiveExcelPreview } from '../components/LiveExcelPreview';
import { ExcelPreview } from '@/components/excel/ExcelPreview';
import { TogglePanel } from '../components/TogglePanel';
import { TargetsEditor } from '../components/TargetsEditor';
import { MASTER_FIELDS, filterFieldsByConditions } from '@/lib/logs/templates/versioned-types';

interface StepConfigureProps {
  state: any;
  updateState: (updates: any) => void;
}

export function StepConfigure({ state, updateState }: StepConfigureProps) {
  const [uploadedFile, setUploadedFile] = useState<File | null>(null);
  const [uploading, setUploading] = useState(false);
  const [uploadError, setUploadError] = useState<string | null>(null);
  const [diffHasErrors, setDiffHasErrors] = useState(false);
  const [diffHasWarnings, setDiffHasWarnings] = useState(false);
  const [compareToBlank, setCompareToBlank] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Get filtered fields based on current configuration
  const filteredFields = filterFieldsByConditions(MASTER_FIELDS, state.gasType, state.toggles);
  const requiredFields = filteredFields.filter(f => f.required);
  const optionalFields = filteredFields.filter(f => !f.required);

  // Handle diff status changes from ExcelPreview
  const handleDiffStatusChange = (hasErrors: boolean, hasWarnings: boolean) => {
    setDiffHasErrors(hasErrors);
    setDiffHasWarnings(hasWarnings);
    
    // Update parent state with validation status
    updateState({ 
      validationErrors: hasErrors,
      validationWarnings: hasWarnings 
    });
  };

  // Handle cell click from ExcelPreview
  const handleCellClick = (cellRef: string, cellData: any) => {
    console.log('Cell clicked:', cellRef, cellData);
    // Could open a cell editor or show details
  };

  const handleFileUpload = async (file: File) => {
    if (!file.name.match(/\.(xlsx|xls)$/i)) {
      setUploadError('Please select an Excel file (.xlsx or .xls)');
      return;
    }

    setUploading(true);
    setUploadError(null);
    
    try {
      // TODO: Implement actual file upload to storage
      // For now, simulate upload
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      const mockPath = `templates/${Date.now()}_${file.name}`;
      updateState({ excelTemplatePath: mockPath });
      setUploadedFile(file);
    } catch (error) {
      setUploadError('Failed to upload file. Please try again.');
    } finally {
      setUploading(false);
    }
  };

  const handleToggleChange = (key: string, value: boolean) => {
    updateState({
      toggles: { ...state.toggles, [key]: value }
    });
  };

  const handleTargetChange = (key: string, value: number) => {
    updateState({
      targets: { ...state.targets, [key]: value }
    });
  };

  const getConfigurationSummary = () => {
    const enabled = Object.entries(state.toggles).filter(([_, value]) => value);
    const targets = Object.entries(state.targets).filter(([_, value]) => value != null);
    
    return {
      totalFields: filteredFields.length,
      requiredFields: requiredFields.length,
      optionalFields: optionalFields.length,
      enabledFeatures: enabled.length,
      configuredTargets: targets.length,
    };
  };

  const summary = getConfigurationSummary();

  return (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
      {/* Configuration Panel */}
      <div className="lg:col-span-2 space-y-6">
        <Tabs defaultValue="toggles" className="w-full">
          <TabsList className="grid w-full grid-cols-3">
            <TabsTrigger value="toggles" className="flex items-center gap-2">
              <Settings className="w-4 h-4" />
              Toggles
            </TabsTrigger>
            <TabsTrigger value="targets" className="flex items-center gap-2">
              <AlertCircle className="w-4 h-4" />
              Targets
            </TabsTrigger>
            <TabsTrigger value="excel" className="flex items-center gap-2">
              <FileSpreadsheet className="w-4 h-4" />
              Excel Template
            </TabsTrigger>
          </TabsList>

          <TabsContent value="toggles" className="mt-6">
            <TogglePanel
              toggles={state.toggles}
              gasType={state.gasType}
              onToggleChange={handleToggleChange}
            />
          </TabsContent>

          <TabsContent value="targets" className="mt-6">
            <TargetsEditor
              targets={state.targets}
              toggles={state.toggles}
              gasType={state.gasType}
              onTargetChange={handleTargetChange}
            />
          </TabsContent>

          <TabsContent value="excel" className="mt-6">
            <Card className="bg-[#2A2A2A] border-gray-600">
              <CardHeader>
                <CardTitle className="text-white">Excel Template Upload</CardTitle>
                <CardDescription className="text-gray-400">
                  Upload your blank Excel template for field mapping and preview
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                {uploadError && (
                  <Alert variant="destructive">
                    <AlertCircle className="w-4 h-4" />
                    <AlertDescription>{uploadError}</AlertDescription>
                  </Alert>
                )}

                {!state.excelTemplatePath ? (
                  <div className="border-2 border-dashed border-gray-600 rounded-lg p-8 text-center">
                    <FileSpreadsheet className="w-12 h-12 text-gray-400 mx-auto mb-4" />
                    <h3 className="text-lg font-medium text-white mb-2">
                      Upload Excel Template
                    </h3>
                    <p className="text-gray-400 mb-4">
                      Select your blank thermal log Excel template
                    </p>
                    <Button
                      onClick={() => fileInputRef.current?.click()}
                      disabled={uploading}
                      className="bg-orange-600 hover:bg-orange-700"
                    >
                      <Upload className="w-4 h-4 mr-2" />
                      {uploading ? 'Uploading...' : 'Choose File'}
                    </Button>
                    <input
                      ref={fileInputRef}
                      type="file"
                      accept=".xlsx,.xls"
                      className="hidden"
                      onChange={(e) => e.target.files?.[0] && handleFileUpload(e.target.files[0])}
                    />
                  </div>
                ) : (
                  <div className="space-y-4">
                    <div className="flex items-center gap-2 text-green-400">
                      <CheckCircle className="w-5 h-5" />
                      <span>Excel template uploaded successfully</span>
                    </div>
                    <div className="bg-[#1E1E1E] border border-gray-700 rounded-lg p-4">
                      <div className="flex items-center justify-between">
                        <div>
                          <p className="text-white font-medium">
                            {uploadedFile?.name || 'Template file'}
                          </p>
                          <p className="text-gray-400 text-sm">
                            {uploadedFile ? `${(uploadedFile.size / 1024).toFixed(1)} KB` : 'Uploaded'}
                          </p>
                        </div>
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => fileInputRef.current?.click()}
                          className="border-gray-600 text-gray-300"
                        >
                          Replace
                        </Button>
                      </div>
                    </div>
                    <input
                      ref={fileInputRef}
                      type="file"
                      accept=".xlsx,.xls"
                      className="hidden"
                      onChange={(e) => e.target.files?.[0] && handleFileUpload(e.target.files[0])}
                    />
                  </div>
                )}

                <div className="bg-blue-50 dark:bg-blue-950 border border-blue-500 rounded-lg p-4">
                  <h4 className="text-white font-medium mb-2">Template Requirements</h4>
                  <ul className="text-sm text-gray-300 space-y-1">
                    <li>• Operation range should be B12:N28</li>
                    <li>• Include column headers for all field types</li>
                    <li>• Use standard Excel formatting</li>
                    <li>• Save as .xlsx format</li>
                  </ul>
                </div>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </div>

      {/* Preview and Summary Panel */}
      <div className="space-y-6">
        {/* Configuration Summary */}
        <Card className="bg-[#2A2A2A] border-gray-600">
          <CardHeader>
            <CardTitle className="text-white">Configuration Summary</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-2 gap-4 text-sm">
              <div>
                <span className="text-gray-400">Total Fields</span>
                <div className="text-2xl font-bold text-white">{summary.totalFields}</div>
              </div>
              <div>
                <span className="text-gray-400">Required</span>
                <div className="text-2xl font-bold text-orange-400">{summary.requiredFields}</div>
              </div>
              <div>
                <span className="text-gray-400">Features</span>
                <div className="text-2xl font-bold text-blue-400">{summary.enabledFeatures}</div>
              </div>
              <div>
                <span className="text-gray-400">Targets</span>
                <div className="text-2xl font-bold text-green-400">{summary.configuredTargets}</div>
              </div>
            </div>

            <div className="space-y-2">
              <Label className="text-white">Gas Type</Label>
              <Badge className="bg-blue-600 text-white">
                {state.gasType.toUpperCase()}
              </Badge>
            </div>

            {Object.entries(state.toggles).some(([_, value]) => value) && (
              <div className="space-y-2">
                <Label className="text-white">Enabled Features</Label>
                <div className="flex flex-wrap gap-1">
                  {Object.entries(state.toggles).map(([key, value]) => 
                    value && (
                      <Badge key={key} variant="outline" className="border-green-500 text-green-300 text-xs">
                        {key.replace(/([A-Z])/g, ' $1').replace(/^./, str => str.toUpperCase())}
                      </Badge>
                    )
                  )}
                </div>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Excel Preview with Validation */}
        {state.excelTemplatePath && (
          <div className="space-y-4">
            {/* Validation Status */}
            <Card className="bg-[#2A2A2A] border-gray-600">
              <CardHeader>
                <CardTitle className="text-white flex items-center gap-2">
                  <CheckCircle className="w-5 h-5" />
                  Validation Status
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-gray-300">Compare to Blank Template</span>
                  <Switch
                    checked={compareToBlank}
                    onCheckedChange={setCompareToBlank}
                  />
                </div>
                
                {compareToBlank && (
                  <div className="space-y-2">
                    {diffHasErrors && (
                      <Alert variant="destructive">
                        <AlertCircle className="h-4 w-4" />
                        <AlertDescription>
                          Template has critical errors. Publish/Assign is blocked until resolved.
                        </AlertDescription>
                      </Alert>
                    )}
                    
                    {diffHasWarnings && !diffHasErrors && (
                      <Alert className="border-yellow-500 text-yellow-600">
                        <AlertCircle className="h-4 w-4" />
                        <AlertDescription>
                          Template has warnings. Review changes before publishing.
                        </AlertDescription>
                      </Alert>
                    )}
                    
                    {!diffHasErrors && !diffHasWarnings && compareToBlank && (
                      <Alert className="border-green-500 text-green-600">
                        <CheckCircle className="h-4 w-4" />
                        <AlertDescription>
                          Template validation passed. Ready for publish/assign.
                        </AlertDescription>
                      </Alert>
                    )}
                  </div>
                )}
              </CardContent>
            </Card>

            {/* Excel Preview */}
            <ExcelPreview
              excelPath={state.excelTemplatePath}
              operationRange="B12:N28"
              gasType={state.gasType}
              toggles={state.toggles}
              targets={state.targets}
              compareToBlank={compareToBlank}
              onDiffStatusChange={handleDiffStatusChange}
              onCellClick={handleCellClick}
              height={400}
              className="bg-[#2A2A2A] border-gray-600"
            />
          </div>
        )}

        {/* Field List */}
        <Card className="bg-[#2A2A2A] border-gray-600">
          <CardHeader>
            <CardTitle className="text-white">Field Configuration</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {requiredFields.length > 0 && (
              <div>
                <h4 className="text-sm font-medium text-white mb-2">Required Fields</h4>
                <div className="space-y-1">
                  {requiredFields.map(field => (
                    <div key={field.key} className="text-sm text-gray-300 flex justify-between">
                      <span>{field.label}</span>
                      {field.unit && (
                        <Badge variant="outline" className="text-xs">
                          {field.unit}
                        </Badge>
                      )}
                    </div>
                  ))}
                </div>
              </div>
            )}

            {optionalFields.length > 0 && (
              <div>
                <h4 className="text-sm font-medium text-white mb-2">Optional Fields</h4>
                <div className="space-y-1">
                  {optionalFields.map(field => (
                    <div key={field.key} className="text-sm text-gray-400 flex justify-between">
                      <span>{field.label}</span>
                      {field.unit && (
                        <Badge variant="outline" className="text-xs">
                          {field.unit}
                        </Badge>
                      )}
                    </div>
                  ))}
                </div>
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}