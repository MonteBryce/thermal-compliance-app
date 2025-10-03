import React, { useState, useCallback, useEffect } from 'react';
import { Brain, Zap, CheckCircle, AlertCircle, Loader2, Lightbulb, Target } from 'lucide-react';
import { LogField } from '@/lib/types/logbuilder';
import { generateFieldSuggestions, checkServiceHealth } from '@/lib/services/openai';
import { cn } from '@/lib/utils';

export interface FieldSuggestion {
  field: LogField;
  confidence: number;
  reasoning: string;
  complianceRelevance?: string;
}

export interface AIFieldSuggestionEngineProps {
  templateType: string;
  existingFields: LogField[];
  industryContext: string;
  complianceRequirements?: string[];
  onSuggestionsGenerated: (suggestions: FieldSuggestion[]) => void;
  onError: (error: Error) => void;
  isLoading?: boolean;
  disabled?: boolean;
  maxSuggestions?: number;
  className?: string;
}

export function AIFieldSuggestionEngine({
  templateType,
  existingFields,
  industryContext,
  complianceRequirements = [],
  onSuggestionsGenerated,
  onError,
  isLoading = false,
  disabled = false,
  maxSuggestions = 8,
  className,
}: AIFieldSuggestionEngineProps) {
  const [internalLoading, setInternalLoading] = useState(false);
  const [serviceHealth, setServiceHealth] = useState<{
    available: boolean;
    latency: number;
  } | null>(null);
  const [generationStats, setGenerationStats] = useState<{
    totalGenerated: number;
    acceptanceRate: number;
    averageConfidence: number;
  }>({ totalGenerated: 0, acceptanceRate: 0, averageConfidence: 0 });

  const loading = isLoading || internalLoading;

  // Check AI service health on mount
  useEffect(() => {
    const checkHealth = async () => {
      try {
        const health = await checkServiceHealth();
        setServiceHealth({
          available: health.available,
          latency: health.latency
        });
      } catch (error) {
        setServiceHealth({ available: false, latency: 0 });
      }
    };

    checkHealth();
  }, []);

  // Generate field suggestions
  const handleGenerateSuggestions = useCallback(async () => {
    if (loading || disabled) return;

    setInternalLoading(true);

    try {
      const result = await generateFieldSuggestions({
        templateType,
        existingFields,
        industryContext,
        complianceRequirements,
      });

      const limitedSuggestions = result.suggestions.slice(0, maxSuggestions);
      
      // Update generation statistics
      setGenerationStats(prev => ({
        totalGenerated: prev.totalGenerated + limitedSuggestions.length,
        acceptanceRate: prev.acceptanceRate, // Updated externally when suggestions are accepted
        averageConfidence: limitedSuggestions.reduce((sum, s) => sum + s.confidence, 0) / limitedSuggestions.length || 0
      }));

      onSuggestionsGenerated(limitedSuggestions);
    } catch (error) {
      console.error('Field suggestion generation failed:', error);
      onError(error instanceof Error ? error : new Error('AI service unavailable'));
    } finally {
      setInternalLoading(false);
    }
  }, [
    templateType,
    existingFields,
    industryContext,
    complianceRequirements,
    maxSuggestions,
    loading,
    disabled,
    onSuggestionsGenerated,
    onError
  ]);

  // Auto-trigger suggestions when context changes
  useEffect(() => {
    if (existingFields.length > 0 && existingFields.length < 3) {
      // Auto-suggest for new templates with few fields
      handleGenerateSuggestions();
    }
  }, [existingFields.length, handleGenerateSuggestions]);

  // Get contextual insights
  const getContextInsights = useCallback(() => {
    const insights: string[] = [];

    if (existingFields.length === 0) {
      insights.push('Starting fresh - AI will suggest essential fields for your template');
    } else if (existingFields.length < 5) {
      insights.push(`With ${existingFields.length} fields, consider adding core measurements and metadata`);
    } else {
      insights.push('Template looks comprehensive - AI will suggest optimization and compliance fields');
    }

    if (complianceRequirements.length > 0) {
      insights.push(`Compliance focus: ${complianceRequirements.join(', ')} requirements`);
    }

    return insights;
  }, [existingFields.length, complianceRequirements]);

  return (
    <div
      data-testid="ai-suggestion-engine"
      className={cn(
        'ai-suggestion-engine',
        'bg-gradient-to-br',
        'from-blue-50',
        'to-indigo-50',
        'border',
        'border-blue-200',
        'rounded-xl',
        'p-6',
        'space-y-6',
        className
      )}
    >
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="p-2 bg-blue-100 rounded-lg">
            <Brain className="w-6 h-6 text-blue-600" />
          </div>
          <div>
            <h3 className="text-lg font-semibold text-gray-900">AI Field Suggestions</h3>
            <p className="text-sm text-gray-600">Intelligent recommendations based on context</p>
          </div>
        </div>

        {/* Service health indicator */}
        {serviceHealth && (
          <div className={cn(
            'flex items-center gap-2 px-3 py-1 rounded-full text-xs font-medium',
            serviceHealth.available
              ? 'bg-green-100 text-green-700'
              : 'bg-red-100 text-red-700'
          )}>
            <div className={cn(
              'w-2 h-2 rounded-full',
              serviceHealth.available ? 'bg-green-500' : 'bg-red-500'
            )} />
            {serviceHealth.available 
              ? `AI Ready (${serviceHealth.latency}ms)` 
              : 'AI Offline'
            }
          </div>
        )}
      </div>

      {/* Context Information */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-white rounded-lg p-4 border border-gray-200">
          <div className="flex items-center gap-2 mb-2">
            <Target className="w-4 h-4 text-blue-600" />
            <span className="font-medium text-gray-900">Template Context</span>
          </div>
          <div className="space-y-1 text-sm text-gray-600">
            <div>Current Fields: {existingFields.length}</div>
            <div>Template: {templateType}</div>
            <div>Industry: {industryContext}</div>
          </div>
        </div>

        <div className="bg-white rounded-lg p-4 border border-gray-200">
          <div className="flex items-center gap-2 mb-2">
            <CheckCircle className="w-4 h-4 text-green-600" />
            <span className="font-medium text-gray-900">Generation Stats</span>
          </div>
          <div className="space-y-1 text-sm text-gray-600">
            <div>Generated: {generationStats.totalGenerated}</div>
            <div>Avg Confidence: {Math.round(generationStats.averageConfidence * 100)}%</div>
            <div>Acceptance: {Math.round(generationStats.acceptanceRate * 100)}%</div>
          </div>
        </div>

        <div className="bg-white rounded-lg p-4 border border-gray-200">
          <div className="flex items-center gap-2 mb-2">
            <Lightbulb className="w-4 h-4 text-yellow-600" />
            <span className="font-medium text-gray-900">AI Insights</span>
          </div>
          <div className="space-y-1 text-xs text-gray-600">
            {getContextInsights().map((insight, index) => (
              <div key={index}>• {insight}</div>
            ))}
          </div>
        </div>
      </div>

      {/* Generation Controls */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <button
            type="button"
            onClick={handleGenerateSuggestions}
            disabled={loading || disabled || !serviceHealth?.available}
            className={cn(
              'flex items-center gap-2 px-4 py-2 rounded-lg font-medium transition-all duration-200',
              'focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2',
              loading || disabled || !serviceHealth?.available
                ? 'bg-gray-100 text-gray-400 cursor-not-allowed'
                : 'bg-blue-600 text-white hover:bg-blue-700 shadow-sm hover:shadow-md'
            )}
          >
            {loading ? (
              <>
                <Loader2 className="w-4 h-4 animate-spin" />
                <span>Generating suggestions...</span>
              </>
            ) : (
              <>
                <Zap className="w-4 h-4" />
                <span>Generate Suggestions</span>
              </>
            )}
          </button>

          {/* Quick actions */}
          <div className="flex items-center gap-2 text-sm text-gray-500">
            <span>Max suggestions:</span>
            <select
              value={maxSuggestions}
              onChange={(e) => {
                // This would be handled by parent component
                console.log('Max suggestions changed:', e.target.value);
              }}
              className="px-2 py-1 border border-gray-300 rounded text-sm focus:outline-none focus:ring-1 focus:ring-blue-500"
              disabled={loading}
            >
              <option value={3}>3</option>
              <option value={5}>5</option>
              <option value={8}>8</option>
              <option value={10}>10</option>
            </select>
          </div>
        </div>

        {/* Compliance indicators */}
        {complianceRequirements.length > 0 && (
          <div className="flex items-center gap-2">
            {complianceRequirements.map((req) => (
              <span
                key={req}
                className="px-2 py-1 bg-purple-100 text-purple-700 text-xs font-medium rounded"
              >
                {req}
              </span>
            ))}
          </div>
        )}
      </div>

      {/* Loading State */}
      {loading && (
        <div className="bg-white rounded-lg border-2 border-dashed border-blue-200 p-8">
          <div className="flex flex-col items-center justify-center space-y-4">
            <div data-testid="ai-loading-spinner" className="relative">
              <Loader2 className="w-8 h-8 text-blue-600 animate-spin" />
              <Brain className="w-4 h-4 text-blue-400 absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2" />
            </div>
            <div className="text-center">
              <div className="text-lg font-medium text-gray-900 mb-1">
                Generating AI suggestions...
              </div>
              <div className="text-sm text-gray-600">
                Analyzing template context and generating intelligent field recommendations
              </div>
            </div>
            <div className="flex items-center gap-2 text-xs text-gray-500">
              <div className="flex items-center gap-1">
                <div className="w-1 h-1 bg-blue-400 rounded-full animate-pulse"></div>
                <span>Analyzing context</span>
              </div>
              <div className="flex items-center gap-1">
                <div className="w-1 h-1 bg-blue-400 rounded-full animate-pulse" style={{ animationDelay: '0.2s' }}></div>
                <span>Generating suggestions</span>
              </div>
              <div className="flex items-center gap-1">
                <div className="w-1 h-1 bg-blue-400 rounded-full animate-pulse" style={{ animationDelay: '0.4s' }}></div>
                <span>Validating compliance</span>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Service unavailable state */}
      {!serviceHealth?.available && !loading && (
        <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
          <div className="flex items-center gap-2 text-yellow-800 mb-2">
            <AlertCircle className="w-5 h-5" />
            <span className="font-medium">AI Service Unavailable</span>
          </div>
          <p className="text-sm text-yellow-700 mb-3">
            The AI suggestion service is currently offline. You can still create fields manually 
            or try again later.
          </p>
          <button
            type="button"
            onClick={() => window.location.reload()}
            className="px-3 py-1 bg-yellow-100 text-yellow-800 text-sm rounded border border-yellow-300 hover:bg-yellow-200 transition-colors"
          >
            Retry Connection
          </button>
        </div>
      )}
    </div>
  );
}

export default AIFieldSuggestionEngine;