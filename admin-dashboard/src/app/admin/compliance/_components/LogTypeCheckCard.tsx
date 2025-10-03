'use client';

import { useEffect, useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { CheckCircle, AlertTriangle, FileType } from 'lucide-react';

interface LogTemplate {
  id: string;
  name: string;
  type: 'H2S' | 'Benzene' | 'Combined' | 'Temperature';
  requiredFields: string[];
  optionalFields: string[];
  frequency: 'hourly' | 'daily' | 'continuous';
}

interface LogTypeCheckCardProps {
  jobId?: string | null;
  onStatusChange?: (status: 'red' | 'amber' | 'green', delta: number) => void;
}

export function LogTypeCheckCard({ jobId, onStatusChange }: LogTypeCheckCardProps) {
  const [selectedTemplate, setSelectedTemplate] = useState<LogTemplate | null>(null);
  const [permitRequiredType, setPermitRequiredType] = useState<string>('H2S');
  const [isMatching, setIsMatching] = useState(true);
  const [availableTemplates] = useState<LogTemplate[]>([
    {
      id: 'h2s-standard',
      name: 'H2S Standard Monitoring',
      type: 'H2S',
      requiredFields: ['exhaustTemp', 'flow', 'h2sPpm'],
      optionalFields: ['pressure', 'notes'],
      frequency: 'hourly',
    },
    {
      id: 'benzene-standard',
      name: 'Benzene Standard Monitoring',
      type: 'Benzene',
      requiredFields: ['exhaustTemp', 'flow', 'benzenePpm'],
      optionalFields: ['pressure', 'notes'],
      frequency: 'hourly',
    },
    {
      id: 'combined-monitoring',
      name: 'Combined H2S & Benzene',
      type: 'Combined',
      requiredFields: ['exhaustTemp', 'flow', 'h2sPpm', 'benzenePpm'],
      optionalFields: ['pressure', 'notes'],
      frequency: 'hourly',
    },
    {
      id: 'temp-only',
      name: 'Temperature Only',
      type: 'Temperature',
      requiredFields: ['exhaustTemp', 'flow'],
      optionalFields: ['pressure', 'notes'],
      frequency: 'hourly',
    },
  ]);

  useEffect(() => {
    if (jobId) {
      // Mock data - would normally fetch from job configuration
      const currentTemplate = availableTemplates[0]; // H2S Standard
      setSelectedTemplate(currentTemplate);
      
      // Check if template matches permit requirements
      const matches = currentTemplate.type === permitRequiredType;
      setIsMatching(matches);
      
      if (!matches) {
        onStatusChange?.('amber', 1);
      } else {
        onStatusChange?.('green', 1);
      }
    }
  }, [jobId]);

  const getStatusIcon = () => {
    if (isMatching) {
      return <CheckCircle className="h-4 w-4 text-green-500" />;
    } else {
      return <AlertTriangle className="h-4 w-4 text-amber-500" />;
    }
  };

  const getStatusBadge = () => {
    if (isMatching) {
      return <Badge className="bg-green-500">✓ Match</Badge>;
    } else {
      return <Badge className="bg-amber-500">⚠ Mismatch</Badge>;
    }
  };

  const getTypeColor = (type: LogTemplate['type']) => {
    switch (type) {
      case 'H2S':
        return 'bg-blue-100 text-blue-800';
      case 'Benzene':
        return 'bg-purple-100 text-purple-800';
      case 'Combined':
        return 'bg-indigo-100 text-indigo-800';
      case 'Temperature':
        return 'bg-orange-100 text-orange-800';
    }
  };

  if (!jobId) {
    return (
      <Card className="col-span-1">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <FileType className="h-5 w-5" />
            Log Type Check
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="text-center py-8 text-muted-foreground">
            Select a job to check log type
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className="col-span-1">
      <CardHeader className="flex flex-row items-center justify-between">
        <CardTitle className="flex items-center gap-2">
          <FileType className="h-5 w-5" />
          Log Type Check
        </CardTitle>
        {getStatusBadge()}
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {/* Current Template */}
          {selectedTemplate && (
            <div className="space-y-3">
              <div>
                <div className="flex items-center gap-2 mb-2">
                  {getStatusIcon()}
                  <span className="text-sm font-medium">Selected Template</span>
                </div>
                <div className="p-3 border rounded-lg">
                  <div className="flex items-center justify-between mb-2">
                    <span className="font-medium">{selectedTemplate.name}</span>
                    <Badge className={getTypeColor(selectedTemplate.type)}>
                      {selectedTemplate.type}
                    </Badge>
                  </div>
                  <div className="text-xs text-muted-foreground space-y-1">
                    <div>Frequency: {selectedTemplate.frequency}</div>
                    <div>Required: {selectedTemplate.requiredFields.join(', ')}</div>
                    <div>Optional: {selectedTemplate.optionalFields.join(', ')}</div>
                  </div>
                </div>
              </div>
              
              {/* Permit Requirement */}
              <div>
                <div className="text-sm font-medium mb-2">Permit Requirement</div>
                <div className="p-3 bg-muted rounded-lg">
                  <div className="flex items-center justify-between">
                    <span>Required Log Type:</span>
                    <Badge className={getTypeColor(permitRequiredType as LogTemplate['type'])}>
                      {permitRequiredType}
                    </Badge>
                  </div>
                </div>
              </div>
              
              {/* Validation Result */}
              {!isMatching && (
                <div className="p-3 bg-amber-50 border border-amber-200 rounded-lg">
                  <div className="flex items-center gap-2 mb-2">
                    <AlertTriangle className="h-4 w-4 text-amber-600" />
                    <span className="text-sm font-medium text-amber-800">Template Mismatch</span>
                  </div>
                  <div className="text-xs text-amber-700">
                    The selected log template does not match the permit requirements. 
                    Consider switching to a {permitRequiredType} template.
                  </div>
                </div>
              )}
              
              {isMatching && (
                <div className="p-3 bg-green-50 border border-green-200 rounded-lg">
                  <div className="flex items-center gap-2">
                    <CheckCircle className="h-4 w-4 text-green-600" />
                    <span className="text-sm text-green-800">Template matches permit requirements</span>
                  </div>
                </div>
              )}
            </div>
          )}
        </div>
      </CardContent>
    </Card>
  );
}