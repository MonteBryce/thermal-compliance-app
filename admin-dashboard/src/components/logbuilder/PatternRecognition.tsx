import React, { useState, useCallback } from 'react';
import { TrendingUp, Loader2, Users, BarChart3 } from 'lucide-react';
import { LogTemplate } from '@/lib/types/logbuilder';
import { cn } from '@/lib/utils';

export interface TemplatePattern {
  commonFields: Array<{
    key: string;
    usage: number;
    templates: string[];
  }>;
  suggestedGroupings: Array<{
    name: string;
    fields: string[];
  }>;
  fieldRelationships: Array<{
    primary: string;
    related: string[];
    correlation: number;
  }>;
}

export interface PatternRecognitionProps {
  existingTemplates: LogTemplate[];
  currentTemplate: { type: string; fields: any[] };
  onPatternsDetected: (patterns: TemplatePattern) => void;
  onError: (error: Error) => void;
  className?: string;
}

// Mock ML service for pattern recognition
async function recognizeTemplatePatterns(templates: LogTemplate[]): Promise<TemplatePattern> {
  // Simulate AI processing delay
  await new Promise(resolve => setTimeout(resolve, 1000));

  // Simple pattern analysis
  const fieldUsage = new Map<string, { count: number; templates: string[] }>();
  
  templates.forEach(template => {
    template.draftSchema.fields.forEach(field => {
      const existing = fieldUsage.get(field.key) || { count: 0, templates: [] };
      existing.count++;
      existing.templates.push(template.id || 'unknown');
      fieldUsage.set(field.key, existing);
    });
  });

  const commonFields = Array.from(fieldUsage.entries())
    .map(([key, data]) => ({
      key,
      usage: data.count / templates.length,
      templates: data.templates
    }))
    .filter(field => field.usage >= 0.3)
    .sort((a, b) => b.usage - a.usage);

  return {
    commonFields,
    suggestedGroupings: [
      {
        name: 'Job Information',
        fields: ['jobNumber', 'operatorName', 'logDate']
      },
      {
        name: 'Thermal Readings',
        fields: ['temperatureReading', 'pressureReading', 'flowRate']
      }
    ],
    fieldRelationships: [
      {
        primary: 'temperatureReading',
        related: ['pressureReading', 'flowRate'],
        correlation: 0.87
      }
    ]
  };
}

export function PatternRecognition({
  existingTemplates,
  currentTemplate,
  onPatternsDetected,
  onError,
  className,
}: PatternRecognitionProps) {
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [patterns, setPatterns] = useState<TemplatePattern | null>(null);

  const handleAnalyzePatterns = useCallback(async () => {
    if (isAnalyzing) return;

    setIsAnalyzing(true);

    try {
      const detectedPatterns = await recognizeTemplatePatterns(existingTemplates);
      setPatterns(detectedPatterns);
      onPatternsDetected(detectedPatterns);
    } catch (error) {
      console.error('Pattern analysis failed:', error);
      onError(error instanceof Error ? error : new Error('Pattern analysis failed'));
    } finally {
      setIsAnalyzing(false);
    }
  }, [existingTemplates, isAnalyzing, onPatternsDetected, onError]);

  return (
    <div
      data-testid="pattern-recognition"
      className={cn(
        'pattern-recognition',
        'bg-white',
        'border',
        'border-gray-200',
        'rounded-lg',
        'p-4',
        'space-y-4',
        className
      )}
    >
      {/* Header */}
      <div className="flex items-center gap-3">
        <div className="p-2 bg-indigo-100 rounded-lg">
          <TrendingUp className="w-5 h-5 text-indigo-600" />
        </div>
        <div>
          <h3 className="text-lg font-semibold text-gray-900">Template Pattern Analysis</h3>
          <p className="text-sm text-gray-600">
            Learn from {existingTemplates.length} existing templates
          </p>
        </div>
      </div>

      {/* Analyze Button */}
      <button
        type="button"
        onClick={handleAnalyzePatterns}
        disabled={isAnalyzing || existingTemplates.length === 0}
        className={cn(
          'flex items-center gap-2 px-4 py-2 rounded-lg font-medium transition-colors',
          'focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2',
          isAnalyzing || existingTemplates.length === 0
            ? 'bg-gray-100 text-gray-400 cursor-not-allowed'
            : 'bg-indigo-600 text-white hover:bg-indigo-700'
        )}
      >
        {isAnalyzing ? (
          <>
            <Loader2 className="w-4 h-4 animate-spin" />
            <span>Analyzing patterns...</span>
          </>
        ) : (
          <>
            <BarChart3 className="w-4 h-4" />
            <span>Analyze Patterns</span>
          </>
        )}
      </button>

      {/* Results */}
      {patterns && (
        <div className="space-y-4 p-3 bg-gray-50 rounded-lg">
          <h4 className="font-medium text-gray-900">Pattern Analysis Results:</h4>

          {/* Common Fields */}
          {patterns.commonFields.length > 0 && (
            <div>
              <h5 className="text-sm font-medium text-gray-700 mb-2">Common Fields:</h5>
              <div className="space-y-1">
                {patterns.commonFields.slice(0, 5).map(field => (
                  <div key={field.key} className="flex justify-between text-sm">
                    <span>{field.key}</span>
                    <span className="text-gray-500">{Math.round(field.usage * 100)}% usage</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Suggested Groupings */}
          {patterns.suggestedGroupings.length > 0 && (
            <div>
              <h5 className="text-sm font-medium text-gray-700 mb-2">Suggested Groupings:</h5>
              <div className="space-y-1">
                {patterns.suggestedGroupings.map(group => (
                  <div key={group.name} className="text-sm">
                    <strong>{group.name}:</strong> {group.fields.join(', ')}
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Field Relationships */}
          {patterns.fieldRelationships.length > 0 && (
            <div>
              <h5 className="text-sm font-medium text-gray-700 mb-2">Field Relationships:</h5>
              <div className="space-y-1">
                {patterns.fieldRelationships.map((rel, index) => (
                  <div key={index} className="text-sm">
                    <strong>{rel.primary}</strong> often appears with: {rel.related.join(', ')}
                    <span className="text-gray-500 ml-2">
                      ({Math.round(rel.correlation * 100)}% correlation)
                    </span>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      )}

      {existingTemplates.length === 0 && (
        <div className="text-center py-4 text-gray-500 text-sm">
          No existing templates available for pattern analysis
        </div>
      )}
    </div>
  );
}

export default PatternRecognition;