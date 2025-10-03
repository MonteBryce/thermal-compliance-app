'use client';

import React, { useState, useEffect, useCallback, useRef } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Separator } from '@/components/ui/separator';
import { 
  Wand2, 
  Brain, 
  TrendingUp, 
  Lightbulb, 
  CheckCircle, 
  XCircle, 
  Clock,
  Sparkles
} from 'lucide-react';

import { FieldTypeahead } from './FieldTypeahead';
import { LogField, FieldType } from '@/lib/types/logbuilder';
import { FieldPatternRecognition, SmartDefaults } from '@/lib/services/field-pattern-recognition';
import { TemplatePatternRecognition, PatternMatchResult } from '@/lib/services/template-pattern-recognition';
import { SuggestionLearningSystem, SuggestionMetrics } from '@/lib/services/suggestion-learning-system';
import { cn } from '@/lib/utils';

interface SmartFieldBuilderProps {
  existingFields: LogField[];
  templateType?: string;
  industryContext?: string;
  onFieldAdd: (field: Partial<LogField>) => void;
  onPatternApply: (fields: LogField[]) => void;
  className?: string;
}

interface SmartFieldSuggestion {
  key: string;
  label: string;
  type: FieldType;
  confidence: number;
  reasoning: string;
  source: 'pattern' | 'ai' | 'learned';
  defaults?: SmartDefaults;
}

export function SmartFieldBuilder({
  existingFields,
  templateType = 'thermal-log',
  industryContext = 'industrial',
  onFieldAdd,
  onPatternApply,
  className
}: SmartFieldBuilderProps) {
  const [currentField, setCurrentField] = useState<Partial<LogField>>({});
  const [smartSuggestions, setSmartSuggestions] = useState<SmartFieldSuggestion[]>([]);
  const [patternMatches, setPatternMatches] = useState<PatternMatchResult[]>([]);
  const [learningMetrics, setLearningMetrics] = useState<SuggestionMetrics | null>(null);
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [activeTab, setActiveTab] = useState('builder');

  const learningSystem = useRef(SuggestionLearningSystem.getInstance());
  const suggestionStartTime = useRef<number>(0);

  // Initialize learning system and analyze existing fields
  useEffect(() => {
    analyzeExistingFields();
    loadLearningMetrics();
  }, [existingFields]);

  const analyzeExistingFields = useCallback(async () => {
    setIsAnalyzing(true);
    
    try {
      // Analyze patterns in existing fields
      const patterns = TemplatePatternRecognition.analyzeExistingFields(existingFields);
      setPatternMatches(patterns);
      
      // Generate smart field suggestions based on patterns
      const suggestions: SmartFieldSuggestion[] = [];
      
      for (const pattern of patterns.slice(0, 3)) { // Top 3 patterns
        for (const suggestedFieldKey of pattern.suggestedFields.slice(0, 3)) { // Top 3 fields per pattern
          const patternField = pattern.pattern.fields.find(f => f.key === suggestedFieldKey);
          if (patternField) {
            suggestions.push({
              key: patternField.key,
              label: patternField.label,
              type: patternField.type,
              confidence: pattern.matchScore,
              reasoning: `Suggested by ${pattern.pattern.name} pattern`,
              source: 'pattern'
            });
          }
        }
      }
      
      setSmartSuggestions(suggestions);
      
    } catch (error) {
      console.error('Failed to analyze existing fields:', error);
    } finally {
      setIsAnalyzing(false);
    }
  }, [existingFields]);

  const loadLearningMetrics = useCallback(() => {
    try {
      const metrics = learningSystem.current.getSuggestionMetrics();
      setLearningMetrics(metrics);
    } catch (error) {
      console.error('Failed to load learning metrics:', error);
    }
  }, []);

  const handleFieldNameChange = useCallback((value: string) => {
    setCurrentField(prev => ({ ...prev, key: value, label: value }));
    
    // Analyze field name for smart defaults
    if (value.length > 2) {
      const defaults = FieldPatternRecognition.analyzeFieldName(value);
      if (defaults) {
        setCurrentField(prev => ({
          ...prev,
          type: defaults.type,
          unit: defaults.unit,
          validation: defaults.validation,
          placeholder: defaults.placeholder
        }));
      }
    }
  }, []);

  const handleFieldLabelChange = useCallback((value: string) => {
    setCurrentField(prev => ({ ...prev, label: value }));
    
    // Analyze label for additional smart defaults
    if (value.length > 2 && currentField.key) {
      const defaults = FieldPatternRecognition.analyzeFieldName(currentField.key, value);
      if (defaults && defaults.confidence > 0.8) {
        setCurrentField(prev => ({
          ...prev,
          type: defaults.type,
          unit: defaults.unit,
          validation: defaults.validation,
          placeholder: defaults.placeholder
        }));
      }
    }
  }, [currentField.key]);

  const handleSuggestionAccept = useCallback((suggestion: SmartFieldSuggestion) => {
    const startTime = Date.now();
    suggestionStartTime.current = startTime;
    
    // Record suggestion shown
    const suggestionId = learningSystem.current.recordSuggestionShown({
      templateType,
      industryContext,
      fieldKey: suggestion.key,
      fieldLabel: suggestion.label,
      suggestion: {
        type: 'field_name',
        value: suggestion.label,
        source: suggestion.source === 'learned' ? 'history' : suggestion.source,
        confidence: suggestion.confidence
      }
    });

    // Apply suggestion to current field
    const newField: Partial<LogField> = {
      key: suggestion.key,
      label: suggestion.label,
      type: suggestion.type,
      ...suggestion.defaults
    };

    setCurrentField(newField);
    
    // Record acceptance
    setTimeout(() => {
      learningSystem.current.recordSuggestionResponse(
        suggestionId,
        true,
        undefined,
        newField,
        Date.now() - startTime
      );
    }, 100);
  }, [templateType, industryContext]);

  const handleAddField = useCallback(() => {
    if (!currentField.key || !currentField.label || !currentField.type) {
      return;
    }

    const field: Partial<LogField> = {
      ...currentField,
      id: `field-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`
    };

    // Record field creation
    learningSystem.current.recordFieldCreated(field as LogField, {
      templateType,
      industryContext
    });

    onFieldAdd(field);
    setCurrentField({});
    
    // Refresh analysis
    setTimeout(() => {
      analyzeExistingFields();
      loadLearningMetrics();
    }, 500);
  }, [currentField, templateType, industryContext, onFieldAdd, analyzeExistingFields, loadLearningMetrics]);

  const handlePatternApply = useCallback((pattern: PatternMatchResult) => {
    const result = TemplatePatternRecognition.applyPatternToTemplate(
      pattern.pattern,
      existingFields
    );

    onPatternApply(result.newFields);

    // Record pattern usage
    TemplatePatternRecognition.recordPatternUsage(
      pattern.pattern.id,
      result.newFields.map(f => f.key),
      [],
      `Applied ${pattern.pattern.name} pattern`
    );

    // Refresh analysis
    setTimeout(() => {
      analyzeExistingFields();
      loadLearningMetrics();
    }, 500);
  }, [existingFields, onPatternApply, analyzeExistingFields, loadLearningMetrics]);

  return (
    <Card className={cn('w-full', className)}>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Sparkles className="h-5 w-5 text-orange-500" />
          Smart Field Builder
        </CardTitle>
        <CardDescription>
          AI-powered field creation with pattern recognition and learning
        </CardDescription>
      </CardHeader>
      
      <CardContent>
        <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-4">
          <TabsList className="grid w-full grid-cols-4">
            <TabsTrigger value="builder">Builder</TabsTrigger>
            <TabsTrigger value="suggestions">
              Suggestions
              {smartSuggestions.length > 0 && (
                <Badge variant="secondary" className="ml-1">
                  {smartSuggestions.length}
                </Badge>
              )}
            </TabsTrigger>
            <TabsTrigger value="patterns">
              Patterns
              {patternMatches.length > 0 && (
                <Badge variant="secondary" className="ml-1">
                  {patternMatches.length}
                </Badge>
              )}
            </TabsTrigger>
            <TabsTrigger value="insights">
              Insights
            </TabsTrigger>
          </TabsList>

          {/* Field Builder Tab */}
          <TabsContent value="builder" className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <label className="text-sm font-medium">Field Name</label>
                <FieldTypeahead
                  value={currentField.key || ''}
                  onChange={handleFieldNameChange}
                  field={currentField as LogField}
                  existingFields={existingFields}
                  templateType={templateType}
                  industryContext={industryContext}
                  type="key"
                  placeholder="Enter field name (e.g., chamber_temp)"
                />
              </div>
              
              <div className="space-y-2">
                <label className="text-sm font-medium">Field Label</label>
                <FieldTypeahead
                  value={currentField.label || ''}
                  onChange={handleFieldLabelChange}
                  field={currentField as LogField}
                  existingFields={existingFields}
                  templateType={templateType}
                  industryContext={industryContext}
                  type="label"
                  placeholder="Enter field label (e.g., Chamber Temperature)"
                />
              </div>
            </div>

            {currentField.key && (
              <div className="mt-4 p-4 bg-gray-50 rounded-lg">
                <h4 className="font-medium mb-2">Smart Defaults Applied</h4>
                <div className="grid grid-cols-2 gap-2 text-sm">
                  <div>Type: <Badge variant="outline">{currentField.type || 'text'}</Badge></div>
                  {currentField.unit && <div>Unit: <Badge variant="outline">{currentField.unit}</Badge></div>}
                  {currentField.validation && (
                    <div className="col-span-2">
                      Validation: {JSON.stringify(currentField.validation)}
                    </div>
                  )}
                </div>
              </div>
            )}

            <Button 
              onClick={handleAddField}
              disabled={!currentField.key || !currentField.label}
              className="w-full"
            >
              <Wand2 className="h-4 w-4 mr-2" />
              Add Smart Field
            </Button>
          </TabsContent>

          {/* Suggestions Tab */}
          <TabsContent value="suggestions" className="space-y-4">
            {isAnalyzing ? (
              <div className="flex items-center justify-center p-8">
                <Brain className="h-6 w-6 animate-pulse mr-2" />
                <span>Analyzing patterns...</span>
              </div>
            ) : (
              <div className="space-y-3">
                {smartSuggestions.map((suggestion, index) => (
                  <Card key={`${suggestion.source}-${index}`} className="cursor-pointer hover:bg-gray-50" onClick={() => handleSuggestionAccept(suggestion)}>
                    <CardContent className="p-4">
                      <div className="flex items-start justify-between">
                        <div className="flex-1">
                          <h4 className="font-medium">{suggestion.label}</h4>
                          <p className="text-sm text-gray-600 mb-2">{suggestion.reasoning}</p>
                          <div className="flex items-center gap-2">
                            <Badge variant="secondary">{suggestion.type}</Badge>
                            <Badge variant={
                              suggestion.source === 'ai' ? 'default' :
                              suggestion.source === 'learned' ? 'secondary' : 'outline'
                            }>
                              {suggestion.source}
                            </Badge>
                            <div className="text-xs text-gray-500">
                              {Math.round(suggestion.confidence * 100)}% confidence
                            </div>
                          </div>
                        </div>
                        <Lightbulb className="h-5 w-5 text-orange-500" />
                      </div>
                    </CardContent>
                  </Card>
                ))}
                
                {smartSuggestions.length === 0 && (
                  <div className="text-center py-8 text-gray-500">
                    <Lightbulb className="h-8 w-8 mx-auto mb-2 opacity-50" />
                    <p>No specific suggestions available.</p>
                    <p className="text-sm">Try adding more fields to see pattern-based recommendations.</p>
                  </div>
                )}
              </div>
            )}
          </TabsContent>

          {/* Patterns Tab */}
          <TabsContent value="patterns" className="space-y-4">
            <div className="space-y-3">
              {patternMatches.map((match, index) => (
                <Card key={index} className="cursor-pointer hover:bg-gray-50" onClick={() => handlePatternApply(match)}>
                  <CardContent className="p-4">
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <h4 className="font-medium">{match.pattern.name}</h4>
                        <p className="text-sm text-gray-600 mb-2">{match.pattern.description}</p>
                        <p className="text-xs text-gray-500 mb-2">{match.reasoning}</p>
                        <div className="flex items-center gap-2">
                          <Badge variant="outline">{match.pattern.category}</Badge>
                          <div className="text-xs text-gray-500">
                            +{match.suggestedFields.length} fields
                          </div>
                          <div className="text-xs text-gray-500">
                            {Math.round(match.matchScore * 100)}% match
                          </div>
                        </div>
                      </div>
                      <Button variant="ghost" size="sm">
                        Apply Pattern
                      </Button>
                    </div>
                  </CardContent>
                </Card>
              ))}
              
              {patternMatches.length === 0 && (
                <div className="text-center py-8 text-gray-500">
                  <Brain className="h-8 w-8 mx-auto mb-2 opacity-50" />
                  <p>No pattern matches found.</p>
                  <p className="text-sm">Add more fields to discover applicable patterns.</p>
                </div>
              )}
            </div>
          </TabsContent>

          {/* Learning Insights Tab */}
          <TabsContent value="insights" className="space-y-4">
            {learningMetrics ? (
              <div className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <Card>
                    <CardContent className="p-4">
                      <div className="flex items-center justify-between">
                        <div>
                          <p className="text-sm text-gray-600">Acceptance Rate</p>
                          <p className="text-2xl font-bold text-green-600">
                            {Math.round(learningMetrics.acceptanceRate * 100)}%
                          </p>
                        </div>
                        <CheckCircle className="h-8 w-8 text-green-500" />
                      </div>
                    </CardContent>
                  </Card>
                  
                  <Card>
                    <CardContent className="p-4">
                      <div className="flex items-center justify-between">
                        <div>
                          <p className="text-sm text-gray-600">Avg Decision Time</p>
                          <p className="text-2xl font-bold">
                            {Math.round(learningMetrics.averageDecisionTime / 1000)}s
                          </p>
                        </div>
                        <Clock className="h-8 w-8 text-blue-500" />
                      </div>
                    </CardContent>
                  </Card>
                  
                  <Card>
                    <CardContent className="p-4">
                      <div className="flex items-center justify-between">
                        <div>
                          <p className="text-sm text-gray-600">Total Suggestions</p>
                          <p className="text-2xl font-bold">{learningMetrics.totalSuggestions}</p>
                        </div>
                        <TrendingUp className="h-8 w-8 text-orange-500" />
                      </div>
                    </CardContent>
                  </Card>
                </div>

                <Separator />

                <div>
                  <h4 className="font-medium mb-3">Top Accepted Patterns</h4>
                  <div className="space-y-2">
                    {learningMetrics.topAcceptedPatterns.slice(0, 5).map((pattern, index) => (
                      <div key={index} className="flex items-center justify-between p-2 bg-green-50 rounded">
                        <span className="text-sm">{pattern.pattern}</span>
                        <Badge variant="secondary">
                          {Math.round(pattern.acceptanceRate * 100)}%
                        </Badge>
                      </div>
                    ))}
                  </div>
                </div>

                {learningMetrics.improvementTrends.length > 0 && (
                  <div>
                    <h4 className="font-medium mb-3">Learning Trend (Last 7 Days)</h4>
                    <div className="text-sm text-gray-600">
                      Average acceptance rate is{' '}
                      {Math.round(
                        learningMetrics.improvementTrends.reduce((acc, trend) => acc + trend.acceptanceRate, 0) / 
                        learningMetrics.improvementTrends.length * 100
                      )}%
                    </div>
                  </div>
                )}
              </div>
            ) : (
              <div className="text-center py-8 text-gray-500">
                <TrendingUp className="h-8 w-8 mx-auto mb-2 opacity-50" />
                <p>No learning data available yet.</p>
                <p className="text-sm">Use suggestions to start building learning insights.</p>
              </div>
            )}
          </TabsContent>
        </Tabs>
      </CardContent>
    </Card>
  );
}