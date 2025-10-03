'use client';

import React, { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Flame, Beaker, Clock, RefreshCw, Shield, Gauge, CheckCircle2 } from 'lucide-react';
import { VersionedTemplateService } from '@/lib/logs/templates/versioned-service';
import { FacilityPreset, Toggles, Targets } from '@/lib/logs/templates/versioned-types';

interface StepPickBaseProps {
  state: any;
  updateState: (updates: any) => void;
}

interface VariantOption {
  id: string;
  name: string;
  description: string;
  icon: React.ReactNode;
  toggles: Partial<Toggles>;
  gasTypes: ('methane' | 'pentane')[];
  popular?: boolean;
}

const FUEL_TYPES = [
  {
    id: 'methane',
    name: 'Methane',
    description: 'Natural gas, biogas, landfill gas',
    icon: <Flame className="w-5 h-5" />,
    color: 'blue',
  },
  {
    id: 'pentane',
    name: 'Pentane',
    description: 'Pentane vapor, hydrocarbon gas',
    icon: <Beaker className="w-5 h-5" />,
    color: 'purple',
  },
];

const VARIANT_OPTIONS: VariantOption[] = [
  {
    id: 'hourly',
    name: 'Hourly Standard',
    description: 'Standard hourly thermal readings',
    icon: <Clock className="w-5 h-5" />,
    toggles: {},
    gasTypes: ['methane', 'pentane'],
    popular: true,
  },
  {
    id: '12hr',
    name: '12-Hour Extended',
    description: 'Extended 12-hour monitoring periods',
    icon: <Clock className="w-5 h-5" />,
    toggles: { is12hr: true },
    gasTypes: ['methane', 'pentane'],
  },
  {
    id: 'refill',
    name: 'Tank Refill',
    description: 'Tank refill operations monitoring',
    icon: <RefreshCw className="w-5 h-5" />,
    toggles: { isRefill: true },
    gasTypes: ['methane', 'pentane'],
  },
  {
    id: 'lel',
    name: 'LEL Monitoring',
    description: 'Lower explosive limit monitoring',
    icon: <Gauge className="w-5 h-5" />,
    toggles: { hasLEL: true },
    gasTypes: ['pentane'],
  },
  {
    id: 'oxygen',
    name: 'O₂ Monitoring',
    description: 'Oxygen level monitoring',
    icon: <Shield className="w-5 h-5" />,
    toggles: { hasO2: true },
    gasTypes: ['methane', 'pentane'],
  },
  {
    id: 'h2s_benzene',
    name: 'H₂S + Benzene',
    description: 'Hydrogen sulfide and benzene monitoring',
    icon: <Shield className="w-5 h-5" />,
    toggles: { hasH2S: true, hasBenzene: true },
    gasTypes: ['methane', 'pentane'],
  },
  {
    id: 'final',
    name: 'Final Inspection',
    description: 'Final inspection with signatures',
    icon: <CheckCircle2 className="w-5 h-5" />,
    toggles: { isFinal: true },
    gasTypes: ['methane', 'pentane'],
  },
];

export function StepPickBase({ state, updateState }: StepPickBaseProps) {
  const [facilityPresets, setFacilityPresets] = useState<FacilityPreset[]>([]);
  const [selectedVariants, setSelectedVariants] = useState<string[]>([]);
  const [loadingPresets, setLoadingPresets] = useState(true);

  useEffect(() => {
    loadFacilityPresets();
  }, []);

  const loadFacilityPresets = async () => {
    try {
      const presets = await VersionedTemplateService.getFacilityPresets();
      setFacilityPresets(presets);
    } catch (error) {
      console.error('Failed to load facility presets:', error);
    } finally {
      setLoadingPresets(false);
    }
  };

  const handleFuelTypeChange = (gasFamily: 'methane' | 'pentane') => {
    updateState({
      gasFamily,
      gasType: gasFamily,
      // Clear variants that don't support this gas type
      toggles: {},
    });
    setSelectedVariants([]);
  };

  const handleVariantToggle = (variantId: string) => {
    const variant = VARIANT_OPTIONS.find(v => v.id === variantId);
    if (!variant) return;

    const isSelected = selectedVariants.includes(variantId);
    
    if (isSelected) {
      // Remove variant
      setSelectedVariants(prev => prev.filter(id => id !== variantId));
      const newToggles = { ...state.toggles };
      Object.keys(variant.toggles).forEach(key => {
        delete newToggles[key as keyof Toggles];
      });
      updateState({ toggles: newToggles });
    } else {
      // Add variant
      setSelectedVariants(prev => [...prev, variantId]);
      updateState({
        toggles: { ...state.toggles, ...variant.toggles }
      });
    }
  };

  const applyFacilityPreset = (presetId: string) => {
    const preset = facilityPresets.find(p => p.id === presetId);
    if (!preset) return;

    updateState({
      gasType: preset.gasType,
      gasFamily: preset.gasType,
      toggles: preset.toggles,
      targets: preset.targets,
      facilityPresetId: presetId,
    });

    // Update selected variants based on preset toggles
    const matchingVariants = VARIANT_OPTIONS.filter(variant => {
      return Object.entries(variant.toggles).every(([key, value]) => 
        preset.toggles[key as keyof Toggles] === value
      );
    });
    setSelectedVariants(matchingVariants.map(v => v.id));
  };

  const generateTemplateKey = (name: string, gasType: string, variants: string[]) => {
    const baseName = name.toLowerCase().replace(/[^a-z0-9]/g, '_');
    const variantSuffix = variants.length > 0 ? `_${variants.join('_')}` : '';
    return `${baseName}_${gasType}${variantSuffix}`;
  };

  const handleNameChange = (name: string) => {
    updateState({
      name,
      templateKey: generateTemplateKey(name, state.gasType, selectedVariants),
    });
  };

  const availableVariants = VARIANT_OPTIONS.filter(variant => 
    variant.gasTypes.includes(state.gasFamily)
  );

  return (
    <div className="space-y-6">
      {/* Template Basic Info */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="space-y-4">
          <div>
            <Label htmlFor="template-name" className="text-white">Template Name</Label>
            <Input
              id="template-name"
              value={state.name}
              onChange={(e) => handleNameChange(e.target.value)}
              placeholder="e.g., Marathon GBR Thermal Log"
              className="bg-[#2A2A2A] border-gray-600 text-white"
            />
          </div>
          <div>
            <Label htmlFor="template-key" className="text-white">Template Key</Label>
            <Input
              id="template-key"
              value={state.templateKey}
              onChange={(e) => updateState({ templateKey: e.target.value })}
              placeholder="e.g., marathon_gbr_methane"
              className="bg-[#2A2A2A] border-gray-600 text-white font-mono text-sm"
            />
            <p className="text-xs text-gray-400 mt-1">
              Used for API references and job assignments
            </p>
          </div>
        </div>

        {/* Facility Presets */}
        <div className="space-y-4">
          <Label className="text-white">Apply Facility Preset (Optional)</Label>
          {loadingPresets ? (
            <div className="text-gray-400">Loading presets...</div>
          ) : facilityPresets.length > 0 ? (
            <Select onValueChange={applyFacilityPreset}>
              <SelectTrigger className="bg-[#2A2A2A] border-gray-600 text-white">
                <SelectValue placeholder="Choose a facility preset" />
              </SelectTrigger>
              <SelectContent>
                {facilityPresets.map(preset => (
                  <SelectItem key={preset.id} value={preset.id!}>
                    <div className="flex items-center gap-2">
                      <span>{preset.name}</span>
                      <Badge variant="outline" className="text-xs">
                        {preset.gasType}
                      </Badge>
                    </div>
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          ) : (
            <div className="text-gray-400 text-sm">
              No facility presets available. Configure manually below.
            </div>
          )}
        </div>
      </div>

      {/* Fuel Type Selection */}
      <div className="space-y-4">
        <Label className="text-white text-lg">Fuel Type</Label>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {FUEL_TYPES.map(fuel => (
            <Card
              key={fuel.id}
              className={`cursor-pointer transition-all hover:scale-105 ${
                state.gasFamily === fuel.id
                  ? `border-${fuel.color}-500 bg-${fuel.color}-50 dark:bg-${fuel.color}-950`
                  : 'border-gray-600 bg-[#2A2A2A] hover:border-gray-500'
              }`}
              onClick={() => handleFuelTypeChange(fuel.id as 'methane' | 'pentane')}
            >
              <CardHeader className="pb-3">
                <div className="flex items-center gap-3">
                  <div className={`p-2 rounded-lg ${
                    state.gasFamily === fuel.id
                      ? `bg-${fuel.color}-600 text-white`
                      : 'bg-gray-600 text-gray-300'
                  }`}>
                    {fuel.icon}
                  </div>
                  <div>
                    <CardTitle className="text-white">{fuel.name}</CardTitle>
                    <CardDescription className="text-gray-400">
                      {fuel.description}
                    </CardDescription>
                  </div>
                </div>
              </CardHeader>
            </Card>
          ))}
        </div>
      </div>

      {/* Variant Selection */}
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <Label className="text-white text-lg">Monitoring Variants</Label>
          <p className="text-sm text-gray-400">
            Select multiple variants to combine features
          </p>
        </div>
        
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {availableVariants.map(variant => {
            const isSelected = selectedVariants.includes(variant.id);
            return (
              <Card
                key={variant.id}
                className={`cursor-pointer transition-all hover:scale-102 ${
                  isSelected
                    ? 'border-orange-500 bg-orange-50 dark:bg-orange-950'
                    : 'border-gray-600 bg-[#2A2A2A] hover:border-gray-500'
                }`}
                onClick={() => handleVariantToggle(variant.id)}
              >
                <CardHeader className="pb-2">
                  <div className="flex items-start justify-between">
                    <div className="flex items-center gap-3">
                      <div className={`p-2 rounded-lg ${
                        isSelected
                          ? 'bg-orange-600 text-white'
                          : 'bg-gray-600 text-gray-300'
                      }`}>
                        {variant.icon}
                      </div>
                      <div>
                        <CardTitle className="text-sm text-white">
                          {variant.name}
                        </CardTitle>
                        {variant.popular && (
                          <Badge className="bg-green-600 text-white text-xs">
                            Popular
                          </Badge>
                        )}
                      </div>
                    </div>
                    {isSelected && (
                      <CheckCircle2 className="w-5 h-5 text-orange-500" />
                    )}
                  </div>
                </CardHeader>
                <CardContent className="pt-0">
                  <CardDescription className="text-gray-400 text-sm">
                    {variant.description}
                  </CardDescription>
                </CardContent>
              </Card>
            );
          })}
        </div>
      </div>

      {/* Selected Configuration Preview */}
      {Object.keys(state.toggles).some(key => state.toggles[key]) && (
        <Card className="bg-blue-50 dark:bg-blue-950 border-blue-500">
          <CardHeader>
            <CardTitle className="text-white">Configuration Preview</CardTitle>
            <CardDescription className="text-gray-400">
              Based on your selections, this template will include:
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="flex flex-wrap gap-2">
              <Badge className="bg-blue-600 text-white">
                {state.gasType} monitoring
              </Badge>
              {Object.entries(state.toggles).map(([key, value]) => 
                value && (
                  <Badge key={key} variant="outline" className="border-blue-500 text-blue-300">
                    {key.replace(/([A-Z])/g, ' $1').replace(/^./, str => str.toUpperCase())}
                  </Badge>
                )
              )}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}