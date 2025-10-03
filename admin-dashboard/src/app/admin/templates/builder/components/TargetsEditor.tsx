'use client';

import React from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Target, AlertTriangle, CheckCircle, Info } from 'lucide-react';
import { Toggles, Targets } from '@/lib/logs/templates/versioned-types';

interface TargetsEditorProps {
  targets: Targets;
  toggles: Toggles;
  gasType: 'methane' | 'pentane';
  onTargetChange: (key: string, value: number) => void;
}

interface TargetField {
  key: keyof Targets;
  label: string;
  unit: string;
  description: string;
  defaultValue: number;
  min: number;
  max: number;
  required: boolean;
  enabledBy: (keyof Toggles)[];
  warningThreshold?: number;
  dangerThreshold?: number;
}

const TARGET_FIELDS: TargetField[] = [
  {
    key: 'h2sPPM',
    label: 'H₂S Threshold',
    unit: 'PPM',
    description: 'Maximum allowable hydrogen sulfide concentration',
    defaultValue: 10,
    min: 0,
    max: 100,
    required: true,
    enabledBy: ['hasH2S'],
    warningThreshold: 5,
    dangerThreshold: 20,
  },
  {
    key: 'benzenePPM',
    label: 'Benzene Threshold',
    unit: 'PPM',
    description: 'Maximum allowable benzene concentration',
    defaultValue: 1,
    min: 0,
    max: 10,
    required: true,
    enabledBy: ['hasBenzene'],
    warningThreshold: 0.5,
    dangerThreshold: 5,
  },
  {
    key: 'lelPct',
    label: 'LEL Threshold',
    unit: '%',
    description: 'Lower explosive limit percentage threshold',
    defaultValue: 10,
    min: 0,
    max: 100,
    required: true,
    enabledBy: ['hasLEL'],
    warningThreshold: 5,
    dangerThreshold: 25,
  },
  {
    key: 'oxygenPct',
    label: 'Oxygen Level',
    unit: '%',
    description: 'Target oxygen percentage for optimal combustion',
    defaultValue: 19.5,
    min: 16,
    max: 23.5,
    required: false,
    enabledBy: ['hasO2'],
    warningThreshold: 18,
    dangerThreshold: 16,
  },
  {
    key: 'tankRefillBBLHR',
    label: 'Tank Refill Rate',
    unit: 'BBL/HR',
    description: 'Maximum tank refill rate during operations',
    defaultValue: 100,
    min: 0,
    max: 1000,
    required: true,
    enabledBy: ['isRefill'],
  },
];

export function TargetsEditor({ targets, toggles, gasType, onTargetChange }: TargetsEditorProps) {
  const availableTargets = TARGET_FIELDS.filter(field =>
    field.enabledBy.some(toggle => toggles[toggle])
  );

  const getFieldStatus = (field: TargetField, value: number | undefined) => {
    if (value === undefined || value === null) {
      return field.required ? 'error' : 'none';
    }

    if (value < field.min || value > field.max) {
      return 'error';
    }

    if (field.dangerThreshold && value >= field.dangerThreshold) {
      return 'danger';
    }

    if (field.warningThreshold && value >= field.warningThreshold) {
      return 'warning';
    }

    return 'good';
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'error': return 'text-red-500 border-red-500';
      case 'danger': return 'text-red-400 border-red-400';
      case 'warning': return 'text-yellow-400 border-yellow-400';
      case 'good': return 'text-green-400 border-green-400';
      default: return 'text-gray-400 border-gray-600';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'error':
      case 'danger':
        return <AlertTriangle className="w-4 h-4" />;
      case 'warning':
        return <AlertTriangle className="w-4 h-4" />;
      case 'good':
        return <CheckCircle className="w-4 h-4" />;
      default:
        return <Target className="w-4 h-4" />;
    }
  };

  const hasRequiredTargets = availableTargets
    .filter(field => field.required)
    .every(field => targets[field.key] !== undefined && targets[field.key] !== null);

  const applyDefaults = () => {
    const updates: Partial<Targets> = {};
    availableTargets.forEach(field => {
      if (targets[field.key] === undefined || targets[field.key] === null) {
        updates[field.key] = field.defaultValue;
      }
    });
    
    Object.entries(updates).forEach(([key, value]) => {
      onTargetChange(key, value);
    });
  };

  if (availableTargets.length === 0) {
    return (
      <Card className="bg-[#2A2A2A] border-gray-600">
        <CardContent className="pt-6">
          <div className="text-center py-8">
            <Target className="w-12 h-12 text-gray-400 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-white mb-2">No Targets Required</h3>
            <p className="text-gray-400">
              The current configuration doesn't require any threshold targets.
              Enable monitoring features in the Toggles tab to configure targets.
            </p>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-6">
      <Alert className="bg-blue-50 dark:bg-blue-950 border-blue-500">
        <Info className="w-4 h-4" />
        <AlertDescription>
          Set threshold values for enabled monitoring features. These targets will be used for 
          validation and alerts during data entry. Values outside safe ranges will trigger warnings.
        </AlertDescription>
      </Alert>

      {!hasRequiredTargets && (
        <Alert variant="destructive">
          <AlertTriangle className="w-4 h-4" />
          <AlertDescription className="flex items-center justify-between">
            <span>Some required targets are missing. Set values for all required fields.</span>
            <button
              onClick={applyDefaults}
              className="ml-4 px-3 py-1 bg-orange-600 text-white rounded text-sm hover:bg-orange-700"
            >
              Apply Defaults
            </button>
          </AlertDescription>
        </Alert>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {availableTargets.map(field => {
          const value = targets[field.key];
          const status = getFieldStatus(field, value);
          const statusColor = getStatusColor(status);

          return (
            <Card key={field.key} className={`bg-[#2A2A2A] border-2 ${statusColor.split(' ')[1]}`}>
              <CardHeader className="pb-3">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <div className={`${statusColor.split(' ')[0]}`}>
                      {getStatusIcon(status)}
                    </div>
                    <CardTitle className="text-white text-base">{field.label}</CardTitle>
                    {field.required && (
                      <Badge variant="destructive" className="text-xs">
                        Required
                      </Badge>
                    )}
                  </div>
                  <Badge variant="outline" className="text-xs">
                    {field.unit}
                  </Badge>
                </div>
                <CardDescription className="text-gray-400 text-sm">
                  {field.description}
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor={field.key} className="text-white">
                    Target Value
                  </Label>
                  <div className="relative">
                    <Input
                      id={field.key}
                      type="number"
                      min={field.min}
                      max={field.max}
                      step="0.1"
                      value={value || ''}
                      onChange={(e) => onTargetChange(field.key, parseFloat(e.target.value) || 0)}
                      placeholder={`${field.defaultValue} ${field.unit}`}
                      className={`bg-[#1E1E1E] border pr-12 ${statusColor}`}
                    />
                    <div className="absolute right-3 top-1/2 transform -translate-y-1/2 text-xs text-gray-400">
                      {field.unit}
                    </div>
                  </div>
                  <div className="flex justify-between text-xs text-gray-400">
                    <span>Min: {field.min}</span>
                    <span>Max: {field.max}</span>
                  </div>
                </div>

                {/* Status Messages */}
                {status === 'error' && (
                  <div className="text-red-400 text-sm">
                    {value === undefined || value === null 
                      ? 'Value is required'
                      : `Value must be between ${field.min} and ${field.max} ${field.unit}`
                    }
                  </div>
                )}

                {status === 'danger' && field.dangerThreshold && (
                  <div className="text-red-400 text-sm">
                    ⚠️ High risk value (≥{field.dangerThreshold} {field.unit})
                  </div>
                )}

                {status === 'warning' && field.warningThreshold && (
                  <div className="text-yellow-400 text-sm">
                    ⚠️ Elevated value (≥{field.warningThreshold} {field.unit})
                  </div>
                )}

                {status === 'good' && (
                  <div className="text-green-400 text-sm">
                    ✓ Value within safe range
                  </div>
                )}

                {/* Quick Set Buttons */}
                <div className="flex gap-2">
                  <button
                    onClick={() => onTargetChange(field.key, field.defaultValue)}
                    className="px-2 py-1 text-xs bg-gray-600 text-white rounded hover:bg-gray-500"
                  >
                    Default ({field.defaultValue})
                  </button>
                  {field.warningThreshold && (
                    <button
                      onClick={() => onTargetChange(field.key, field.warningThreshold)}
                      className="px-2 py-1 text-xs bg-yellow-600 text-white rounded hover:bg-yellow-500"
                    >
                      Warning ({field.warningThreshold})
                    </button>
                  )}
                </div>
              </CardContent>
            </Card>
          );
        })}
      </div>

      {/* Summary */}
      <Card className="bg-green-50 dark:bg-green-950 border-green-500">
        <CardHeader>
          <CardTitle className="text-white">Targets Summary</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-center">
            <div>
              <div className="text-2xl font-bold text-white">
                {availableTargets.length}
              </div>
              <div className="text-sm text-gray-400">Total Targets</div>
            </div>
            <div>
              <div className="text-2xl font-bold text-orange-400">
                {availableTargets.filter(f => f.required).length}
              </div>
              <div className="text-sm text-gray-400">Required</div>
            </div>
            <div>
              <div className="text-2xl font-bold text-green-400">
                {availableTargets.filter(f => targets[f.key] !== undefined).length}
              </div>
              <div className="text-sm text-gray-400">Configured</div>
            </div>
            <div>
              <div className="text-2xl font-bold text-blue-400">
                {availableTargets.filter(f => {
                  const value = targets[f.key];
                  return value !== undefined && getFieldStatus(f, value) === 'good';
                }).length}
              </div>
              <div className="text-sm text-gray-400">Valid</div>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}