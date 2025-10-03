'use client';

import React from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Switch } from '@/components/ui/switch';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Shield, Gauge, RefreshCw, Clock, CheckCircle, Flame, Info } from 'lucide-react';
import { Toggles } from '@/lib/logs/templates/versioned-types';

interface TogglePanelProps {
  toggles: Toggles;
  gasType: 'methane' | 'pentane';
  onToggleChange: (key: string, value: boolean) => void;
}

interface ToggleOption {
  key: keyof Toggles;
  label: string;
  description: string;
  icon: React.ReactNode;
  gasTypes: ('methane' | 'pentane')[];
  requiresTarget?: boolean;
  conflicts?: (keyof Toggles)[];
  category: 'monitoring' | 'operation' | 'reporting';
}

const TOGGLE_OPTIONS: ToggleOption[] = [
  {
    key: 'hasH2S',
    label: 'H₂S Monitoring',
    description: 'Monitor hydrogen sulfide levels with safety thresholds',
    icon: <Shield className="w-5 h-5" />,
    gasTypes: ['methane', 'pentane'],
    requiresTarget: true,
    category: 'monitoring',
  },
  {
    key: 'hasBenzene',
    label: 'Benzene Monitoring',
    description: 'Monitor benzene concentration for environmental compliance',
    icon: <Shield className="w-5 h-5" />,
    gasTypes: ['methane', 'pentane'],
    requiresTarget: true,
    category: 'monitoring',
  },
  {
    key: 'hasLEL',
    label: 'LEL Monitoring',
    description: 'Lower explosive limit monitoring for safety',
    icon: <Gauge className="w-5 h-5" />,
    gasTypes: ['pentane'],
    requiresTarget: true,
    category: 'monitoring',
  },
  {
    key: 'hasO2',
    label: 'Oxygen Monitoring',
    description: 'Monitor oxygen levels for combustion efficiency',
    icon: <Flame className="w-5 h-5" />,
    gasTypes: ['methane', 'pentane'],
    category: 'monitoring',
  },
  {
    key: 'isRefill',
    label: 'Tank Refill Operations',
    description: 'Include tank refill rate monitoring and controls',
    icon: <RefreshCw className="w-5 h-5" />,
    gasTypes: ['methane', 'pentane'],
    requiresTarget: true,
    category: 'operation',
  },
  {
    key: 'is12hr',
    label: '12-Hour Extended Monitoring',
    description: 'Extended monitoring periods with start/stop times',
    icon: <Clock className="w-5 h-5" />,
    gasTypes: ['methane', 'pentane'],
    conflicts: ['isRefill'],
    category: 'operation',
  },
  {
    key: 'isFinal',
    label: 'Final Inspection',
    description: 'Include supervisor signatures and final approval',
    icon: <CheckCircle className="w-5 h-5" />,
    gasTypes: ['methane', 'pentane'],
    category: 'reporting',
  },
];

export function TogglePanel({ toggles, gasType, onToggleChange }: TogglePanelProps) {
  const availableToggles = TOGGLE_OPTIONS.filter(option => 
    option.gasTypes.includes(gasType)
  );

  const getTogglesByCategory = (category: string) =>
    availableToggles.filter(option => option.category === category);

  const isToggleDisabled = (option: ToggleOption) => {
    if (option.conflicts) {
      return option.conflicts.some(conflictKey => toggles[conflictKey]);
    }
    return false;
  };

  const getConflictMessage = (option: ToggleOption) => {
    if (option.conflicts) {
      const activeConflicts = option.conflicts.filter(key => toggles[key]);
      if (activeConflicts.length > 0) {
        const conflictLabels = activeConflicts.map(key => 
          TOGGLE_OPTIONS.find(opt => opt.key === key)?.label
        );
        return `Conflicts with: ${conflictLabels.join(', ')}`;
      }
    }
    return null;
  };

  const categories = [
    { id: 'monitoring', title: 'Safety Monitoring', description: 'Gas detection and safety parameters' },
    { id: 'operation', title: 'Operations', description: 'Operational modes and procedures' },
    { id: 'reporting', title: 'Reporting', description: 'Documentation and compliance' },
  ];

  return (
    <div className="space-y-6">
      <Alert className="bg-blue-50 dark:bg-blue-950 border-blue-500">
        <Info className="w-4 h-4" />
        <AlertDescription>
          Toggle features to customize your template. Each toggle adds specific fields and validation rules 
          to your thermal log. Required targets will be configured in the next tab.
        </AlertDescription>
      </Alert>

      {categories.map(category => {
        const categoryToggles = getTogglesByCategory(category.id);
        
        return (
          <Card key={category.id} className="bg-[#2A2A2A] border-gray-600">
            <CardHeader>
              <CardTitle className="text-white">{category.title}</CardTitle>
              <CardDescription className="text-gray-400">
                {category.description}
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              {categoryToggles.map(option => {
                const isEnabled = toggles[option.key];
                const isDisabled = isToggleDisabled(option);
                const conflictMessage = getConflictMessage(option);

                return (
                  <div key={option.key} className="space-y-2">
                    <div className={`flex items-center justify-between p-4 rounded-lg border transition-all ${
                      isEnabled 
                        ? 'border-orange-500 bg-orange-50 dark:bg-orange-950' 
                        : isDisabled
                        ? 'border-gray-600 bg-gray-100 dark:bg-gray-800 opacity-50'
                        : 'border-gray-600 bg-[#1E1E1E] hover:border-gray-500'
                    }`}>
                      <div className="flex items-center gap-3">
                        <div className={`p-2 rounded-lg ${
                          isEnabled 
                            ? 'bg-orange-600 text-white' 
                            : 'bg-gray-600 text-gray-300'
                        }`}>
                          {option.icon}
                        </div>
                        <div className="flex-1">
                          <div className="flex items-center gap-2">
                            <Label 
                              htmlFor={option.key}
                              className={`font-medium ${isEnabled ? 'text-white' : 'text-gray-300'}`}
                            >
                              {option.label}
                            </Label>
                            {option.requiresTarget && (
                              <Badge variant="outline" className="text-xs">
                                Requires Target
                              </Badge>
                            )}
                          </div>
                          <p className={`text-sm ${isEnabled ? 'text-gray-300' : 'text-gray-400'}`}>
                            {option.description}
                          </p>
                        </div>
                      </div>
                      <Switch
                        id={option.key}
                        checked={isEnabled}
                        onCheckedChange={(checked) => onToggleChange(option.key, checked)}
                        disabled={isDisabled}
                      />
                    </div>
                    
                    {conflictMessage && (
                      <Alert variant="destructive" className="mt-2">
                        <AlertDescription className="text-sm">
                          {conflictMessage}
                        </AlertDescription>
                      </Alert>
                    )}
                  </div>
                );
              })}
            </CardContent>
          </Card>
        );
      })}

      {/* Active Configuration Summary */}
      {Object.values(toggles).some(Boolean) && (
        <Card className="bg-green-50 dark:bg-green-950 border-green-500">
          <CardHeader>
            <CardTitle className="text-white">Active Configuration</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex flex-wrap gap-2">
              {Object.entries(toggles).map(([key, value]) => 
                value && (
                  <Badge key={key} className="bg-green-600 text-white">
                    {TOGGLE_OPTIONS.find(opt => opt.key === key)?.label || key}
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