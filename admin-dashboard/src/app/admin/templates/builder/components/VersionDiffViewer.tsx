'use client';

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Plus, Minus, Edit, AlertCircle, CheckCircle } from 'lucide-react';
import { VersionedTemplateService } from '@/lib/logs/templates/versioned-service';
import { VersionDiff, FieldSpec, filterFieldsByConditions, MASTER_FIELDS } from '@/lib/logs/templates/versioned-types';

interface VersionDiffViewerProps {
  templateId: string;
  oldVersionId: string;
  newState: any;
}

export function VersionDiffViewer({ templateId, oldVersionId, newState }: VersionDiffViewerProps) {
  const [diff, setDiff] = useState<VersionDiff | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    computeDiff();
  }, [templateId, oldVersionId, newState]);

  const computeDiff = async () => {
    try {
      setLoading(true);
      
      // Create a mock new version based on current state
      const newFields = filterFieldsByConditions(MASTER_FIELDS, newState.gasType, newState.toggles);
      const newVersion = {
        version: 999, // Temporary version number
        status: 'draft' as const,
        toggles: newState.toggles,
        gasType: newState.gasType,
        fields: newFields,
        targets: newState.targets,
        ui: {
          groups: ['core', 'monitoring', 'operator'],
          layout: 'standard' as const,
        },
        excelTemplatePath: newState.excelTemplatePath,
        operationRange: {
          start: 'B12',
          end: 'N28',
          sheet: 'Sheet1',
        },
        createdAt: Date.now(),
        createdBy: 'admin',
        hash: '',
      };

      // For now, simulate diff computation
      // In real implementation, this would call the service
      const mockDiff = await computeMockDiff(newVersion);
      setDiff(mockDiff);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to compute diff');
    } finally {
      setLoading(false);
    }
  };

  const computeMockDiff = async (newVersion: any): Promise<VersionDiff> => {
    // Simulate getting the old version and computing differences
    // This is a simplified mock - real implementation would fetch from Firestore
    const oldFields = MASTER_FIELDS.filter(f => 
      f.showIf?.gasType ? f.showIf.gasType === newState.gasType : true
    ).slice(0, 5); // Mock: fewer fields in old version

    const fieldsAdded = newVersion.fields.filter((newField: FieldSpec) => 
      !oldFields.some(oldField => oldField.key === newField.key)
    );

    const fieldsRemoved = oldFields.filter((oldField: FieldSpec) => 
      !newVersion.fields.some((newField: FieldSpec) => newField.key === oldField.key)
    );

    const fieldsModified: VersionDiff['fieldsModified'] = [];
    newVersion.fields.forEach((newField: FieldSpec) => {
      const oldField = oldFields.find(f => f.key === newField.key);
      if (oldField && (oldField.label !== newField.label || oldField.unit !== newField.unit)) {
        fieldsModified.push({
          field: newField,
          changes: {
            label: oldField.label !== newField.label ? 
              { from: oldField.label, to: newField.label } : undefined,
            unit: oldField.unit !== newField.unit ? 
              { from: oldField.unit, to: newField.unit } : undefined,
          },
        });
      }
    });

    // Mock toggle changes
    const oldToggles = { hasH2S: false, hasBenzene: false, hasLEL: false, hasO2: false, isRefill: false, is12hr: false, isFinal: false };
    const togglesChanged: VersionDiff['togglesChanged'] = {};
    Object.entries(newVersion.toggles).forEach(([key, newValue]) => {
      const oldValue = oldToggles[key as keyof typeof oldToggles];
      if (oldValue !== newValue) {
        togglesChanged[key] = { from: oldValue, to: newValue };
      }
    });

    // Mock target changes
    const oldTargets = { h2sPPM: 5, benzenePPM: 1 };
    const targetsChanged: VersionDiff['targetsChanged'] = {};
    Object.entries(newVersion.targets).forEach(([key, newValue]) => {
      const oldValue = oldTargets[key as keyof typeof oldTargets];
      if (oldValue !== newValue && newValue !== undefined && oldValue !== undefined) {
        targetsChanged[key] = { from: oldValue, to: newValue };
      }
    });

    return {
      fieldsAdded,
      fieldsRemoved,
      fieldsModified,
      togglesChanged,
      targetsChanged,
    };
  };

  if (loading) {
    return (
      <Card className="bg-[#2A2A2A] border-gray-600">
        <CardContent className="pt-6">
          <div className="text-center py-8 text-gray-400">
            Computing changes...
          </div>
        </CardContent>
      </Card>
    );
  }

  if (error) {
    return (
      <Alert variant="destructive">
        <AlertCircle className="w-4 h-4" />
        <AlertDescription>{error}</AlertDescription>
      </Alert>
    );
  }

  if (!diff) {
    return (
      <Card className="bg-[#2A2A2A] border-gray-600">
        <CardContent className="pt-6">
          <div className="text-center py-8 text-gray-400">
            No changes detected
          </div>
        </CardContent>
      </Card>
    );
  }

  const hasChanges = diff.fieldsAdded.length > 0 || 
                    diff.fieldsRemoved.length > 0 || 
                    diff.fieldsModified.length > 0 ||
                    Object.keys(diff.togglesChanged).length > 0 ||
                    Object.keys(diff.targetsChanged).length > 0;

  if (!hasChanges) {
    return (
      <Alert className="bg-blue-50 dark:bg-blue-950 border-blue-500">
        <CheckCircle className="w-4 h-4" />
        <AlertDescription>
          No changes detected. The new version is identical to the current version.
        </AlertDescription>
      </Alert>
    );
  }

  return (
    <div className="space-y-6">
      {/* Summary */}
      <Card className="bg-[#2A2A2A] border-gray-600">
        <CardHeader>
          <CardTitle className="text-white">Change Summary</CardTitle>
          <CardDescription className="text-gray-400">
            Overview of modifications from the previous version
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-5 gap-4 text-center">
            <div className="bg-green-950 border border-green-500 rounded-lg p-3">
              <div className="text-lg font-bold text-green-400">{diff.fieldsAdded.length}</div>
              <div className="text-xs text-green-300">Added</div>
            </div>
            <div className="bg-red-950 border border-red-500 rounded-lg p-3">
              <div className="text-lg font-bold text-red-400">{diff.fieldsRemoved.length}</div>
              <div className="text-xs text-red-300">Removed</div>
            </div>
            <div className="bg-blue-950 border border-blue-500 rounded-lg p-3">
              <div className="text-lg font-bold text-blue-400">{diff.fieldsModified.length}</div>
              <div className="text-xs text-blue-300">Modified</div>
            </div>
            <div className="bg-purple-950 border border-purple-500 rounded-lg p-3">
              <div className="text-lg font-bold text-purple-400">{Object.keys(diff.togglesChanged).length}</div>
              <div className="text-xs text-purple-300">Toggles</div>
            </div>
            <div className="bg-orange-950 border border-orange-500 rounded-lg p-3">
              <div className="text-lg font-bold text-orange-400">{Object.keys(diff.targetsChanged).length}</div>
              <div className="text-xs text-orange-300">Targets</div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Detailed Changes */}
      <Tabs defaultValue="fields" className="w-full">
        <TabsList className="grid w-full grid-cols-3">
          <TabsTrigger value="fields">Field Changes</TabsTrigger>
          <TabsTrigger value="toggles">Toggle Changes</TabsTrigger>
          <TabsTrigger value="targets">Target Changes</TabsTrigger>
        </TabsList>

        <TabsContent value="fields" className="mt-6 space-y-4">
          {/* Added Fields */}
          {diff.fieldsAdded.length > 0 && (
            <Card className="bg-green-950 border-green-500">
              <CardHeader>
                <CardTitle className="text-white flex items-center gap-2">
                  <Plus className="w-5 h-5 text-green-400" />
                  Added Fields ({diff.fieldsAdded.length})
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  {diff.fieldsAdded.map(field => (
                    <div key={field.key} className="flex items-center justify-between p-3 bg-green-900 rounded-lg">
                      <div>
                        <div className="text-white font-medium">{field.label}</div>
                        <div className="text-green-300 text-sm">{field.key}</div>
                      </div>
                      <div className="flex gap-2">
                        {field.unit && (
                          <Badge variant="outline" className="border-green-400 text-green-300">
                            {field.unit}
                          </Badge>
                        )}
                        {field.required && (
                          <Badge className="bg-red-600 text-white">Required</Badge>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          )}

          {/* Removed Fields */}
          {diff.fieldsRemoved.length > 0 && (
            <Card className="bg-red-950 border-red-500">
              <CardHeader>
                <CardTitle className="text-white flex items-center gap-2">
                  <Minus className="w-5 h-5 text-red-400" />
                  Removed Fields ({diff.fieldsRemoved.length})
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  {diff.fieldsRemoved.map(field => (
                    <div key={field.key} className="flex items-center justify-between p-3 bg-red-900 rounded-lg">
                      <div>
                        <div className="text-white font-medium line-through">{field.label}</div>
                        <div className="text-red-300 text-sm">{field.key}</div>
                      </div>
                      <div className="flex gap-2">
                        {field.unit && (
                          <Badge variant="outline" className="border-red-400 text-red-300">
                            {field.unit}
                          </Badge>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          )}

          {/* Modified Fields */}
          {diff.fieldsModified.length > 0 && (
            <Card className="bg-blue-950 border-blue-500">
              <CardHeader>
                <CardTitle className="text-white flex items-center gap-2">
                  <Edit className="w-5 h-5 text-blue-400" />
                  Modified Fields ({diff.fieldsModified.length})
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {diff.fieldsModified.map(({ field, changes }) => (
                    <div key={field.key} className="p-3 bg-blue-900 rounded-lg">
                      <div className="text-white font-medium mb-2">{field.label}</div>
                      <div className="space-y-1">
                        {Object.entries(changes).map(([property, change]) => 
                          change && (
                            <div key={property} className="text-sm">
                              <span className="text-blue-300 capitalize">{property}:</span>
                              <span className="text-red-300 ml-2">{change.from || 'none'}</span>
                              <span className="text-gray-400 mx-2">→</span>
                              <span className="text-green-300">{change.to || 'none'}</span>
                            </div>
                          )
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          )}

          {diff.fieldsAdded.length === 0 && diff.fieldsRemoved.length === 0 && diff.fieldsModified.length === 0 && (
            <Card className="bg-[#2A2A2A] border-gray-600">
              <CardContent className="pt-6">
                <div className="text-center py-8 text-gray-400">
                  No field changes
                </div>
              </CardContent>
            </Card>
          )}
        </TabsContent>

        <TabsContent value="toggles" className="mt-6">
          {Object.keys(diff.togglesChanged).length > 0 ? (
            <Card className="bg-purple-950 border-purple-500">
              <CardHeader>
                <CardTitle className="text-white">Toggle Changes</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  {Object.entries(diff.togglesChanged).map(([key, change]) => (
                    <div key={key} className="flex items-center justify-between p-3 bg-purple-900 rounded-lg">
                      <div className="text-white font-medium">
                        {key.replace(/([A-Z])/g, ' $1').replace(/^./, str => str.toUpperCase())}
                      </div>
                      <div className="flex items-center gap-2">
                        <Badge variant={change.from ? 'default' : 'outline'}>
                          {change.from ? 'Enabled' : 'Disabled'}
                        </Badge>
                        <span className="text-gray-400">→</span>
                        <Badge variant={change.to ? 'default' : 'outline'}>
                          {change.to ? 'Enabled' : 'Disabled'}
                        </Badge>
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          ) : (
            <Card className="bg-[#2A2A2A] border-gray-600">
              <CardContent className="pt-6">
                <div className="text-center py-8 text-gray-400">
                  No toggle changes
                </div>
              </CardContent>
            </Card>
          )}
        </TabsContent>

        <TabsContent value="targets" className="mt-6">
          {Object.keys(diff.targetsChanged).length > 0 ? (
            <Card className="bg-orange-950 border-orange-500">
              <CardHeader>
                <CardTitle className="text-white">Target Changes</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  {Object.entries(diff.targetsChanged).map(([key, change]) => (
                    <div key={key} className="flex items-center justify-between p-3 bg-orange-900 rounded-lg">
                      <div className="text-white font-medium">
                        {key.replace(/([A-Z])/g, ' $1').replace(/^./, str => str.toUpperCase())}
                      </div>
                      <div className="flex items-center gap-2">
                        <Badge variant="outline" className="border-orange-400 text-orange-300">
                          {change.from}
                        </Badge>
                        <span className="text-gray-400">→</span>
                        <Badge variant="outline" className="border-orange-400 text-orange-300">
                          {change.to}
                        </Badge>
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          ) : (
            <Card className="bg-[#2A2A2A] border-gray-600">
              <CardContent className="pt-6">
                <div className="text-center py-8 text-gray-400">
                  No target changes
                </div>
              </CardContent>
            </Card>
          )}
        </TabsContent>
      </Tabs>
    </div>
  );
}