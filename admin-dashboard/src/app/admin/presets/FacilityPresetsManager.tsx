'use client';

import React, { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Plus, Edit, Trash2, MapPin, Settings } from 'lucide-react';
import { VersionedTemplateService } from '@/lib/logs/templates/versioned-service';
import { FacilityPreset, Toggles, Targets } from '@/lib/logs/templates/versioned-types';
import { LIBRARY_TEMPLATES, LibraryTemplate } from '@/lib/logs/templates/library-seed';

const SAMPLE_FACILITIES = [
  { id: 'marathon-gbr', name: 'Marathon GBR Platform' },
  { id: 'shell-perdido', name: 'Shell Perdido Platform' },
  { id: 'bp-thunder', name: 'BP Thunder Horse' },
  { id: 'chevron-jack', name: 'Chevron Jack/St. Malo' },
  { id: 'exxon-hoover', name: 'ExxonMobil Hoover Diana' },
];

export function FacilityPresetsManager() {
  const [presets, setPresets] = useState<FacilityPreset[]>([]);
  const [loading, setLoading] = useState(true);
  const [showCreateDialog, setShowCreateDialog] = useState(false);
  const [editingPreset, setEditingPreset] = useState<FacilityPreset | null>(null);
  
  const [formData, setFormData] = useState({
    name: '',
    facilityId: '',
    gasType: 'methane' as 'methane' | 'pentane',
    toggles: {
      hasH2S: false,
      hasBenzene: false,
      hasLEL: false,
      hasO2: false,
      isRefill: false,
      is12hr: false,
      isFinal: false,
    } as Toggles,
    targets: {} as Targets,
    suggestedTemplateId: '',
  });

  useEffect(() => {
    loadPresets();
  }, []);

  const loadPresets = async () => {
    try {
      const loadedPresets = await VersionedTemplateService.getFacilityPresets();
      setPresets(loadedPresets);
    } catch (error) {
      console.error('Failed to load presets:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async () => {
    try {
      const presetData = {
        ...formData,
        createdBy: 'admin', // TODO: Get from auth context
      };

      await VersionedTemplateService.createFacilityPreset(presetData);
      
      setShowCreateDialog(false);
      setEditingPreset(null);
      resetForm();
      await loadPresets();
    } catch (error) {
      console.error('Failed to save preset:', error);
    }
  };

  const resetForm = () => {
    setFormData({
      name: '',
      facilityId: '',
      gasType: 'methane',
      toggles: {
        hasH2S: false,
        hasBenzene: false,
        hasLEL: false,
        hasO2: false,
        isRefill: false,
        is12hr: false,
        isFinal: false,
      },
      targets: {},
      suggestedTemplateId: '',
    });
  };

  const handleEdit = (preset: FacilityPreset) => {
    setFormData({
      name: preset.name,
      facilityId: preset.facilityId,
      gasType: preset.gasType,
      toggles: preset.toggles,
      targets: preset.targets,
      suggestedTemplateId: (preset as any).suggestedTemplateId || '',
    });
    setEditingPreset(preset);
    setShowCreateDialog(true);
  };

  const updateToggle = (key: keyof Toggles, value: boolean) => {
    setFormData(prev => ({
      ...prev,
      toggles: { ...prev.toggles, [key]: value }
    }));
  };

  const updateTarget = (key: keyof Targets, value: number) => {
    setFormData(prev => ({
      ...prev,
      targets: { ...prev.targets, [key]: value }
    }));
  };

  const enabledFeatures = Object.entries(formData.toggles).filter(([_, value]) => value);
  const requiredTargets = enabledFeatures.filter(([key]) => 
    ['hasH2S', 'hasBenzene', 'hasLEL', 'isRefill'].includes(key)
  );

  // Get matching templates based on current configuration
  const getMatchingTemplates = () => {
    return LIBRARY_TEMPLATES.filter(template => {
      // Match gas type
      if (template.gasType !== formData.gasType) return false;
      
      // Check if template toggles are compatible
      const templateToggles = template.version.toggles;
      const formToggles = formData.toggles;
      
      // Template should have all features that are enabled in form
      for (const [key, enabled] of Object.entries(formToggles)) {
        if (enabled && !templateToggles[key as keyof Toggles]) {
          return false;
        }
      }
      
      return true;
    }).sort((a, b) => b.popularity - a.popularity);
  };

  const matchingTemplates = getMatchingTemplates();
  const selectedTemplate = LIBRARY_TEMPLATES.find(t => t.id === formData.suggestedTemplateId);

  const handleTemplateSelect = (templateId: string) => {
    const template = LIBRARY_TEMPLATES.find(t => t.id === templateId);
    if (template) {
      setFormData(prev => ({
        ...prev,
        suggestedTemplateId: templateId,
        // Auto-fill toggles from template if they're compatible
        toggles: {
          ...prev.toggles,
          ...template.version.toggles,
        },
        targets: {
          ...prev.targets,
          ...template.version.targets,
        },
      }));
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold text-white">Facility Presets</h1>
          <p className="text-gray-400 mt-1">
            Manage default configurations for different facilities
          </p>
        </div>
        <Dialog open={showCreateDialog} onOpenChange={setShowCreateDialog}>
          <DialogTrigger asChild>
            <Button className="bg-orange-600 hover:bg-orange-700" onClick={resetForm}>
              <Plus className="w-4 h-4 mr-2" />
              New Preset
            </Button>
          </DialogTrigger>
          <DialogContent className="max-w-2xl">
            <DialogHeader>
              <DialogTitle>
                {editingPreset ? 'Edit Facility Preset' : 'Create Facility Preset'}
              </DialogTitle>
              <DialogDescription>
                Configure default settings for a specific facility that can be applied to new templates.
              </DialogDescription>
            </DialogHeader>
            
            <div className="space-y-6">
              {/* Basic Info */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label htmlFor="preset-name">Preset Name</Label>
                  <Input
                    id="preset-name"
                    value={formData.name}
                    onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
                    placeholder="e.g., Marathon GBR Standard"
                  />
                </div>
                <div>
                  <Label htmlFor="facility">Facility</Label>
                  <Select 
                    value={formData.facilityId} 
                    onValueChange={(value) => setFormData(prev => ({ ...prev, facilityId: value }))}
                  >
                    <SelectTrigger>
                      <SelectValue placeholder="Select facility" />
                    </SelectTrigger>
                    <SelectContent>
                      {SAMPLE_FACILITIES.map(facility => (
                        <SelectItem key={facility.id} value={facility.id}>
                          {facility.name}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              </div>

              <div>
                <Label>Gas Type</Label>
                <div className="flex gap-4 mt-2">
                  {(['methane', 'pentane'] as const).map(type => (
                    <label key={type} className="flex items-center gap-2 cursor-pointer">
                      <input
                        type="radio"
                        name="gasType"
                        value={type}
                        checked={formData.gasType === type}
                        onChange={(e) => setFormData(prev => ({ ...prev, gasType: e.target.value as any }))}
                      />
                      <span className="text-white capitalize">{type}</span>
                    </label>
                  ))}
                </div>
              </div>

              {/* Toggles */}
              <div>
                <Label>Features</Label>
                <div className="grid grid-cols-2 gap-3 mt-2">
                  {Object.entries(formData.toggles).map(([key, value]) => (
                    <label key={key} className="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={value}
                        onChange={(e) => updateToggle(key as keyof Toggles, e.target.checked)}
                      />
                      <span className="text-white">
                        {key.replace(/([A-Z])/g, ' $1').replace(/^./, str => str.toUpperCase())}
                      </span>
                    </label>
                  ))}
                </div>
              </div>

              {/* Targets */}
              {requiredTargets.length > 0 && (
                <div>
                  <Label>Targets</Label>
                  <div className="grid grid-cols-2 gap-4 mt-2">
                    {requiredTargets.map(([key]) => {
                      const targetKey = key === 'hasH2S' ? 'h2sPPM' : 
                                       key === 'hasBenzene' ? 'benzenePPM' :
                                       key === 'hasLEL' ? 'lelPct' : 
                                       key === 'isRefill' ? 'tankRefillBBLHR' : null;
                      
                      if (!targetKey) return null;
                      
                      return (
                        <div key={targetKey}>
                          <Label className="text-sm">
                            {targetKey.replace(/([A-Z])/g, ' $1').replace(/^./, str => str.toUpperCase())}
                          </Label>
                          <Input
                            type="number"
                            value={formData.targets[targetKey as keyof Targets] || ''}
                            onChange={(e) => updateTarget(targetKey as keyof Targets, parseFloat(e.target.value) || 0)}
                            placeholder="0"
                          />
                        </div>
                      );
                    })}
                  </div>
                </div>
              )}

              {/* Suggested Template */}
              <div>
                <Label>Suggested Template (Optional)</Label>
                <p className="text-sm text-gray-400 mb-2">
                  Recommend a template from the library that matches this facility's typical configuration
                </p>
                <Select 
                  value={formData.suggestedTemplateId} 
                  onValueChange={handleTemplateSelect}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Select a template..." />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="">No suggestion</SelectItem>
                    {matchingTemplates.map(template => (
                      <SelectItem key={template.id} value={template.id}>
                        <div className="flex items-center gap-2">
                          <span>{template.name}</span>
                          <Badge className="bg-blue-600 text-white text-xs">
                            {template.gasType.toUpperCase()}
                          </Badge>
                        </div>
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                
                {selectedTemplate && (
                  <div className="mt-2 p-3 bg-green-950 border border-green-500 rounded-lg">
                    <div className="flex items-center gap-2 mb-2">
                      <Badge className="bg-green-600 text-white text-xs">
                        Suggested
                      </Badge>
                      <span className="text-sm font-medium text-white">{selectedTemplate.name}</span>
                    </div>
                    <p className="text-xs text-green-200">{selectedTemplate.description}</p>
                    <div className="flex flex-wrap gap-1 mt-2">
                      {selectedTemplate.tags.slice(0, 3).map(tag => (
                        <Badge key={tag} variant="outline" className="text-xs border-green-500 text-green-300">
                          {tag}
                        </Badge>
                      ))}
                    </div>
                  </div>
                )}
                
                {matchingTemplates.length === 0 && formData.gasType && (
                  <div className="mt-2 p-3 bg-yellow-950 border border-yellow-500 rounded-lg">
                    <p className="text-xs text-yellow-200">
                      No templates found matching the current {formData.gasType} configuration. 
                      Consider adjusting toggles or leave without suggestion.
                    </p>
                  </div>
                )}
              </div>

              {/* Preview */}
              {enabledFeatures.length > 0 && (
                <div className="bg-blue-50 dark:bg-blue-950 border border-blue-500 rounded-lg p-4">
                  <h4 className="font-medium text-white mb-2">Configuration Preview</h4>
                  <div className="flex flex-wrap gap-2">
                    <Badge className="bg-blue-600 text-white">
                      {formData.gasType.toUpperCase()}
                    </Badge>
                    {enabledFeatures.map(([key]) => (
                      <Badge key={key} variant="outline" className="border-blue-500 text-blue-300">
                        {key.replace(/([A-Z])/g, ' $1').replace(/^./, str => str.toUpperCase())}
                      </Badge>
                    ))}
                    {selectedTemplate && (
                      <Badge className="bg-green-600 text-white">
                        Template: {selectedTemplate.name}
                      </Badge>
                    )}
                  </div>
                </div>
              )}

              <div className="flex justify-end gap-2">
                <Button variant="outline" onClick={() => setShowCreateDialog(false)}>
                  Cancel
                </Button>
                <Button onClick={handleSave} className="bg-orange-600 hover:bg-orange-700">
                  {editingPreset ? 'Update' : 'Create'} Preset
                </Button>
              </div>
            </div>
          </DialogContent>
        </Dialog>
      </div>

      {/* Presets List */}
      {loading ? (
        <div className="text-center py-12 text-gray-400">Loading presets...</div>
      ) : presets.length === 0 ? (
        <Card className="bg-[#1E1E1E] border border-gray-800">
          <CardContent className="text-center py-12">
            <Settings className="w-12 h-12 text-gray-400 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-white mb-2">No Facility Presets</h3>
            <p className="text-gray-400 mb-4">
              Create presets to quickly apply standard configurations to new templates.
            </p>
            <Button 
              onClick={() => setShowCreateDialog(true)}
              className="bg-orange-600 hover:bg-orange-700"
            >
              <Plus className="w-4 h-4 mr-2" />
              Create First Preset
            </Button>
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {presets.map(preset => {
            const facility = SAMPLE_FACILITIES.find(f => f.id === preset.facilityId);
            const enabledFeatures = Object.entries(preset.toggles).filter(([_, value]) => value);
            
            return (
              <Card key={preset.id} className="bg-[#1E1E1E] border border-gray-800">
                <CardHeader>
                  <div className="flex items-start justify-between">
                    <div>
                      <CardTitle className="text-white">{preset.name}</CardTitle>
                      <CardDescription className="flex items-center gap-1 text-gray-400">
                        <MapPin className="w-3 h-3" />
                        {facility?.name || preset.facilityId}
                      </CardDescription>
                    </div>
                    <div className="flex gap-1">
                      <Button 
                        variant="ghost" 
                        size="icon"
                        onClick={() => handleEdit(preset)}
                        className="h-8 w-8"
                      >
                        <Edit className="w-3 h-3" />
                      </Button>
                      <Button 
                        variant="ghost" 
                        size="icon"
                        className="h-8 w-8 text-red-400 hover:text-red-300"
                      >
                        <Trash2 className="w-3 h-3" />
                      </Button>
                    </div>
                  </div>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="flex items-center gap-2">
                    <Badge className="bg-blue-600 text-white">
                      {preset.gasType.toUpperCase()}
                    </Badge>
                    <Badge variant="outline">
                      {enabledFeatures.length} features
                    </Badge>
                  </div>
                  
                  {enabledFeatures.length > 0 && (
                    <div>
                      <div className="text-sm font-medium text-gray-300 mb-2">Enabled Features</div>
                      <div className="flex flex-wrap gap-1">
                        {enabledFeatures.map(([key]) => (
                          <Badge key={key} variant="outline" className="text-xs border-green-500 text-green-300">
                            {key.replace(/([A-Z])/g, ' $1').replace(/^./, str => str.toUpperCase())}
                          </Badge>
                        ))}
                      </div>
                    </div>
                  )}
                  
                  {Object.keys(preset.targets).length > 0 && (
                    <div>
                      <div className="text-sm font-medium text-gray-300 mb-2">Targets</div>
                      <div className="space-y-1">
                        {Object.entries(preset.targets).map(([key, value]) => 
                          value != null && (
                            <div key={key} className="flex justify-between text-xs">
                              <span className="text-gray-400">
                                {key.replace(/([A-Z])/g, ' $1').replace(/^./, str => str.toUpperCase())}
                              </span>
                              <span className="text-white">
                                {value} {key.includes('PPM') ? 'PPM' : key.includes('Pct') ? '%' : 'BBL/HR'}
                              </span>
                            </div>
                          )
                        )}
                      </div>
                    </div>
                  )}
                </CardContent>
              </Card>
            );
          })}
        </div>
      )}
    </div>
  );
}