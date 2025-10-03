import React, { useState, useMemo, useCallback } from 'react';
import { 
  CheckCircle, 
  XCircle, 
  Edit, 
  ThumbsUp, 
  ThumbsDown, 
  Filter, 
  TrendingUp,
  AlertCircle,
  Info,
  Zap
} from 'lucide-react';
import { LogField } from '@/lib/types/logbuilder';
import { FieldSuggestion } from './AIFieldSuggestionEngine';
import { cn } from '@/lib/utils';

export interface FieldRecommendation extends FieldSuggestion {
  id: string;
  category: string;
  priority: 'high' | 'medium' | 'low';
}

export interface SmartFieldRecommendationsProps {
  recommendations: FieldRecommendation[];
  onAcceptRecommendation: (id: string) => void;
  onRejectRecommendation: (id: string) => void;
  onModifyRecommendation?: (id: string, field: LogField) => void;
  showDetails?: boolean;
  confidenceThreshold?: number;
  className?: string;
}

const categoryConfig = {
  measurements: { 
    label: 'Measurements', 
    color: 'blue',
    icon: TrendingUp,
    description: 'Quantitative data fields'
  },
  personnel: { 
    label: 'Personnel', 
    color: 'green',
    icon: CheckCircle,
    description: 'User and operator information'
  },
  compliance: { 
    label: 'Compliance', 
    color: 'purple',
    icon: AlertCircle,
    description: 'Regulatory and safety requirements'
  },
  metadata: { 
    label: 'Metadata', 
    color: 'gray',
    icon: Info,
    description: 'Context and reference information'
  },
  quality: { 
    label: 'Quality', 
    color: 'orange',
    icon: Zap,
    description: 'Quality assurance and control'
  },
};

const priorityConfig = {
  high: { label: 'High Priority', color: 'red', weight: 3 },
  medium: { label: 'Medium Priority', color: 'yellow', weight: 2 },
  low: { label: 'Low Priority', color: 'gray', weight: 1 },
};

export function SmartFieldRecommendations({
  recommendations,
  onAcceptRecommendation,
  onRejectRecommendation,
  onModifyRecommendation,
  showDetails = true,
  confidenceThreshold = 0.5,
  className,
}: SmartFieldRecommendationsProps) {
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [sortBy, setSortBy] = useState<'confidence' | 'priority' | 'category'>('confidence');
  const [expandedRecommendation, setExpandedRecommendation] = useState<string | null>(null);

  // Filter and sort recommendations
  const processedRecommendations = useMemo(() => {
    let filtered = recommendations.filter(rec => 
      rec.confidence >= confidenceThreshold &&
      (selectedCategory === 'all' || rec.category === selectedCategory)
    );

    // Sort recommendations
    filtered.sort((a, b) => {
      switch (sortBy) {
        case 'confidence':
          return b.confidence - a.confidence;
        case 'priority':
          return priorityConfig[b.priority].weight - priorityConfig[a.priority].weight;
        case 'category':
          return a.category.localeCompare(b.category);
        default:
          return 0;
      }
    });

    return filtered;
  }, [recommendations, confidenceThreshold, selectedCategory, sortBy]);

  // Group recommendations by category
  const groupedRecommendations = useMemo(() => {
    const groups: Record<string, FieldRecommendation[]> = {};
    
    processedRecommendations.forEach(rec => {
      if (!groups[rec.category]) {
        groups[rec.category] = [];
      }
      groups[rec.category].push(rec);
    });

    return groups;
  }, [processedRecommendations]);

  // Get confidence color class
  const getConfidenceColor = useCallback((confidence: number) => {
    if (confidence >= 0.8) return 'text-green-600 bg-green-50';
    if (confidence >= 0.6) return 'text-blue-600 bg-blue-50';
    if (confidence >= 0.4) return 'text-yellow-600 bg-yellow-50';
    return 'text-red-600 bg-red-50';
  }, []);

  // Handle recommendation modification
  const handleModify = useCallback((recommendation: FieldRecommendation) => {
    if (onModifyRecommendation) {
      onModifyRecommendation(recommendation.id, recommendation.field);
    }
  }, [onModifyRecommendation]);

  return (
    <div
      data-testid="smart-recommendations"
      className={cn('smart-recommendations space-y-6', className)}
    >
      {/* Header and Controls */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h3 className="text-lg font-semibold text-gray-900">Smart Recommendations</h3>
          <p className="text-sm text-gray-600">
            AI-powered field suggestions based on your template context
          </p>
        </div>

        <div className="flex items-center gap-3">
          {/* Confidence threshold slider */}
          <div className="flex items-center gap-2">
            <label className="text-sm text-gray-600">Min Confidence:</label>
            <input
              type="range"
              role="slider"
              aria-label="Confidence threshold"
              min="0"
              max="100"
              value={Math.round(confidenceThreshold * 100)}
              onChange={(e) => {
                // This would be handled by parent component
                console.log('Confidence threshold:', parseInt(e.target.value) / 100);
              }}
              className="w-20"
            />
            <span className="text-sm font-medium text-gray-700 w-8">
              {Math.round(confidenceThreshold * 100)}%
            </span>
          </div>

          {/* Category filter */}
          <select
            value={selectedCategory}
            onChange={(e) => setSelectedCategory(e.target.value)}
            className="px-3 py-1 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="all">All Categories</option>
            {Object.entries(categoryConfig).map(([key, config]) => (
              <option key={key} value={key}>
                {config.label}
              </option>
            ))}
          </select>

          {/* Sort control */}
          <select
            value={sortBy}
            onChange={(e) => setSortBy(e.target.value as any)}
            className="px-3 py-1 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="confidence">By Confidence</option>
            <option value="priority">By Priority</option>
            <option value="category">By Category</option>
          </select>
        </div>
      </div>

      {/* Recommendations List */}
      {processedRecommendations.length === 0 ? (
        <div className="text-center py-12 bg-gray-50 rounded-lg">
          <Filter className="w-12 h-12 text-gray-400 mx-auto mb-4" />
          <h4 className="text-lg font-medium text-gray-900 mb-2">No recommendations found</h4>
          <p className="text-gray-600 max-w-md mx-auto">
            Try adjusting your confidence threshold or category filter to see more suggestions.
          </p>
        </div>
      ) : (
        <div className="space-y-6">
          {/* Summary */}
          <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
            <div className="flex items-center gap-2 mb-2">
              <Info className="w-5 h-5 text-blue-600" />
              <span className="font-medium text-blue-900">
                {processedRecommendations.length} Recommendations Found
              </span>
            </div>
            <div className="text-sm text-blue-700">
              Average confidence: {Math.round(
                processedRecommendations.reduce((sum, rec) => sum + rec.confidence, 0) / 
                processedRecommendations.length * 100
              )}% • 
              Categories: {Object.keys(groupedRecommendations).map(cat => 
                categoryConfig[cat as keyof typeof categoryConfig]?.label || cat
              ).join(', ')}
            </div>
          </div>

          {/* Grouped Recommendations */}
          {Object.entries(groupedRecommendations).map(([category, categoryRecs]) => {
            const categoryConf = categoryConfig[category as keyof typeof categoryConfig];
            const CategoryIcon = categoryConf?.icon || Info;
            
            return (
              <div key={category} className="space-y-3">
                {/* Category Header */}
                <div className="flex items-center gap-3 border-b border-gray-200 pb-2">
                  <div className={cn(
                    'p-1 rounded',
                    `bg-${categoryConf?.color || 'gray'}-100`
                  )}>
                    <CategoryIcon className={cn(
                      'w-4 h-4',
                      `text-${categoryConf?.color || 'gray'}-600`
                    )} />
                  </div>
                  <div>
                    <h4 className="font-medium text-gray-900">
                      {categoryConf?.label || category}
                    </h4>
                    <p className="text-xs text-gray-600">
                      {categoryConf?.description} • {categoryRecs.length} suggestions
                    </p>
                  </div>
                </div>

                {/* Category Recommendations */}
                <div className="grid gap-3">
                  {categoryRecs.map((recommendation) => (
                    <div
                      key={recommendation.id}
                      data-testid={`recommendation-${recommendation.id}`}
                      className="bg-white border border-gray-200 rounded-lg p-4 hover:shadow-sm transition-shadow"
                      aria-label={`Field recommendation: ${recommendation.field.label}, confidence ${Math.round(recommendation.confidence * 100)}%`}
                    >
                      {/* Recommendation Header */}
                      <div className="flex items-start justify-between mb-3">
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2 mb-1">
                            <h5 className="font-medium text-gray-900 truncate">
                              {recommendation.field.label}
                            </h5>
                            <span className={cn(
                              'px-2 py-0.5 rounded text-xs font-medium',
                              `bg-${priorityConfig[recommendation.priority].color}-100`,
                              `text-${priorityConfig[recommendation.priority].color}-700`
                            )}>
                              {priorityConfig[recommendation.priority].label}
                            </span>
                          </div>
                          <div className="flex items-center gap-3 text-sm text-gray-600">
                            <span>Type: {recommendation.field.type}</span>
                            {recommendation.field.unit && (
                              <span>Unit: {recommendation.field.unit}</span>
                            )}
                            <span
                              data-testid={`confidence-${Math.round(recommendation.confidence * 100)}`}
                              className={cn(
                                'px-2 py-0.5 rounded text-xs font-medium',
                                getConfidenceColor(recommendation.confidence),
                                recommendation.confidence >= 0.8 ? 'confidence--high' : 
                                recommendation.confidence >= 0.6 ? 'confidence--medium' : 'confidence--low'
                              )}
                            >
                              {Math.round(recommendation.confidence * 100)}% confidence
                            </span>
                          </div>
                        </div>

                        {/* Action Buttons */}
                        <div className="flex items-center gap-1 ml-4">
                          <button
                            type="button"
                            onClick={() => onAcceptRecommendation(recommendation.id)}
                            className="p-2 text-green-600 hover:bg-green-50 rounded-lg transition-colors"
                            title="Accept recommendation"
                            aria-label="Accept recommendation"
                            aria-describedby={`rec-${recommendation.id}-details`}
                          >
                            <ThumbsUp className="w-4 h-4" />
                          </button>
                          
                          {onModifyRecommendation && (
                            <button
                              type="button"
                              onClick={() => handleModify(recommendation)}
                              className="p-2 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                              title="Modify recommendation"
                              aria-label="Modify recommendation"
                            >
                              <Edit className="w-4 h-4" />
                            </button>
                          )}

                          <button
                            type="button"
                            onClick={() => onRejectRecommendation(recommendation.id)}
                            className="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                            title="Reject recommendation"
                            aria-label="Reject recommendation"
                          >
                            <ThumbsDown className="w-4 h-4" />
                          </button>
                        </div>
                      </div>

                      {/* Recommendation Content */}
                      <div className="space-y-2">
                        <p className="text-sm text-gray-700">
                          {recommendation.reasoning}
                        </p>

                        {recommendation.complianceRelevance && (
                          <div className="bg-purple-50 border border-purple-200 rounded p-2">
                            <div className="flex items-center gap-2 text-purple-700 text-xs font-medium mb-1">
                              <AlertCircle className="w-3 h-3" />
                              Compliance Relevance
                            </div>
                            <p className="text-xs text-purple-600">
                              {recommendation.complianceRelevance}
                            </p>
                          </div>
                        )}

                        {/* Field Details (expandable) */}
                        {showDetails && (
                          <div className="border-t border-gray-100 pt-2 mt-2">
                            <button
                              type="button"
                              onClick={() => setExpandedRecommendation(
                                expandedRecommendation === recommendation.id ? null : recommendation.id
                              )}
                              className="text-xs text-blue-600 hover:text-blue-800 font-medium"
                            >
                              {expandedRecommendation === recommendation.id ? 'Hide' : 'Show'} field details
                            </button>
                            
                            {expandedRecommendation === recommendation.id && (
                              <div className="mt-2 p-2 bg-gray-50 rounded text-xs">
                                <div className="grid grid-cols-2 gap-2">
                                  <div>
                                    <span className="font-medium">Key:</span> {recommendation.field.key}
                                  </div>
                                  <div>
                                    <span className="font-medium">Type:</span> {recommendation.field.type}
                                  </div>
                                  {recommendation.field.unit && (
                                    <div>
                                      <span className="font-medium">Unit:</span> {recommendation.field.unit}
                                    </div>
                                  )}
                                  {recommendation.field.validation?.required && (
                                    <div>
                                      <span className="font-medium">Required:</span> Yes
                                    </div>
                                  )}
                                </div>
                              </div>
                            )}
                          </div>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Bulk Actions */}
      {processedRecommendations.length > 0 && (
        <div className="border-t border-gray-200 pt-4">
          <div className="flex items-center justify-between">
            <div className="text-sm text-gray-600">
              {processedRecommendations.length} recommendations shown
            </div>
            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={() => {
                  processedRecommendations
                    .filter(rec => rec.confidence >= 0.8)
                    .forEach(rec => onAcceptRecommendation(rec.id));
                }}
                className="px-3 py-1 text-sm bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
              >
                Accept High Confidence
              </button>
              <button
                type="button"
                onClick={() => {
                  processedRecommendations
                    .filter(rec => rec.confidence < 0.5)
                    .forEach(rec => onRejectRecommendation(rec.id));
                }}
                className="px-3 py-1 text-sm bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
              >
                Reject Low Confidence
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default SmartFieldRecommendations;