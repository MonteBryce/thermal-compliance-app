import React, { useMemo, useEffect, useState } from 'react';
import { useSpring, animated } from '@react-spring/web';
import {
  BarChart3,
  Clock,
  CheckCircle,
  AlertCircle,
  Activity,
  Layers,
  Hash,
  Type,
  Calendar,
  ToggleLeft,
  List,
  FileText,
  Calculator,
  TrendingUp,
  Zap
} from 'lucide-react';
import { cn } from '@/lib/utils';
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from '@/components/ui/tooltip';

export interface FieldTypeCount {
  type: string;
  count: number;
  icon?: React.ElementType;
  color?: string;
}

export interface TemplateMetrics {
  totalFields: number;
  requiredFields: number;
  optionalFields: number;
  conditionalFields: number;
  calculatedFields: number;
  validationRules: number;
  estimatedTime?: number; // in minutes
  complexity?: 'simple' | 'moderate' | 'complex' | 'advanced';
  completeness?: number; // percentage
}

export interface TemplateStatisticsProps {
  fields: any[];
  metrics?: TemplateMetrics;
  showBreakdown?: boolean;
  showEstimates?: boolean;
  showComplexity?: boolean;
  compact?: boolean;
  animated?: boolean;
  className?: string;
  'data-testid'?: string;
}

const fieldTypeIcons: Record<string, React.ElementType> = {
  text: Type,
  number: Hash,
  date: Calendar,
  boolean: ToggleLeft,
  select: List,
  textarea: FileText,
  calculation: Calculator
};

const fieldTypeColors: Record<string, string> = {
  text: 'text-blue-600',
  number: 'text-green-600',
  date: 'text-purple-600',
  boolean: 'text-orange-600',
  select: 'text-indigo-600',
  textarea: 'text-teal-600',
  calculation: 'text-slate-600'
};

const complexityConfig = {
  simple: {
    label: 'Simple',
    color: 'text-green-600',
    bgColor: 'bg-green-50',
    icon: CheckCircle,
    description: 'Basic template with straightforward fields'
  },
  moderate: {
    label: 'Moderate',
    color: 'text-yellow-600',
    bgColor: 'bg-yellow-50',
    icon: Activity,
    description: 'Standard template with some complex features'
  },
  complex: {
    label: 'Complex',
    color: 'text-orange-600',
    bgColor: 'bg-orange-50',
    icon: AlertCircle,
    description: 'Advanced template with many interdependencies'
  },
  advanced: {
    label: 'Advanced',
    color: 'text-red-600',
    bgColor: 'bg-red-50',
    icon: Zap,
    description: 'Expert-level template with sophisticated logic'
  }
};

export function TemplateStatistics({
  fields,
  metrics,
  showBreakdown = true,
  showEstimates = true,
  showComplexity = true,
  compact = false,
  animated = true,
  className,
  'data-testid': testId = 'template-statistics'
}: TemplateStatisticsProps) {
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    setIsVisible(true);
  }, []);

  // Calculate field type breakdown
  const fieldTypeBreakdown = useMemo(() => {
    const breakdown: Record<string, number> = {};
    
    fields.forEach(field => {
      const type = field.type || 'text';
      breakdown[type] = (breakdown[type] || 0) + 1;
    });
    
    return Object.entries(breakdown).map(([type, count]) => ({
      type,
      count,
      icon: fieldTypeIcons[type] || Type,
      color: fieldTypeColors[type] || 'text-gray-600'
    }));
  }, [fields]);

  // Calculate metrics if not provided
  const calculatedMetrics = useMemo(() => {
    if (metrics) return metrics;
    
    const totalFields = fields.length;
    const requiredFields = fields.filter(f => f.required).length;
    const optionalFields = totalFields - requiredFields;
    const conditionalFields = fields.filter(f => f.conditional).length;
    const calculatedFields = fields.filter(f => f.type === 'calculation').length;
    const validationRules = fields.reduce((sum, f) => sum + (f.validations?.length || 0), 0);
    
    // Estimate completion time (2 minutes per required field, 1 minute per optional)
    const estimatedTime = requiredFields * 2 + optionalFields * 1;
    
    // Calculate complexity
    let complexity: 'simple' | 'moderate' | 'complex' | 'advanced' = 'simple';
    if (totalFields > 50 || validationRules > 30 || conditionalFields > 10) {
      complexity = 'advanced';
    } else if (totalFields > 30 || validationRules > 20 || conditionalFields > 5) {
      complexity = 'complex';
    } else if (totalFields > 15 || validationRules > 10 || conditionalFields > 2) {
      complexity = 'moderate';
    }
    
    // Calculate completeness (mock - in real app would check actual field values)
    const completeness = Math.round((requiredFields / totalFields) * 100);
    
    return {
      totalFields,
      requiredFields,
      optionalFields,
      conditionalFields,
      calculatedFields,
      validationRules,
      estimatedTime,
      complexity,
      completeness
    };
  }, [fields, metrics]);

  // Animation springs
  const fadeIn = useSpring({
    opacity: animated && isVisible ? 1 : 0,
    transform: animated && isVisible ? 'translateY(0px)' : 'translateY(-10px)',
    config: { tension: 300, friction: 25 }
  });

  const progressSpring = useSpring({
    width: `${calculatedMetrics.completeness}%`,
    config: { tension: 200, friction: 20 }
  });

  const complexityInfo = calculatedMetrics.complexity 
    ? complexityConfig[calculatedMetrics.complexity] 
    : complexityConfig.simple;
  const ComplexityIcon = complexityInfo.icon;

  return (
    <TooltipProvider>
      <animated.div
        style={animated ? fadeIn : {}}
        className={cn(
          'template-statistics',
          'p-4 bg-white rounded-lg border shadow-sm',
          compact && 'template-statistics--compact p-3',
          className
        )}
        data-testid={testId}
      >
        {/* Header */}
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <BarChart3 className="w-5 h-5 text-gray-600" />
            <h3 className="font-semibold text-gray-900">
              Template Statistics
            </h3>
          </div>
          <div className="text-sm text-gray-500">
            {calculatedMetrics.totalFields} fields
          </div>
        </div>

        {/* Main Metrics */}
        <div className={cn(
          'grid gap-3 mb-4',
          compact ? 'grid-cols-2' : 'grid-cols-2 md:grid-cols-4'
        )}>
          <div className="metric-card">
            <div className="text-2xl font-bold text-gray-900">
              {calculatedMetrics.totalFields}
            </div>
            <div className="text-xs text-gray-500">Total Fields</div>
          </div>
          
          <div className="metric-card">
            <div className="text-2xl font-bold text-orange-600">
              {calculatedMetrics.requiredFields}
            </div>
            <div className="text-xs text-gray-500">Required</div>
          </div>
          
          {!compact && (
            <>
              <div className="metric-card">
                <div className="text-2xl font-bold text-blue-600">
                  {calculatedMetrics.optionalFields}
                </div>
                <div className="text-xs text-gray-500">Optional</div>
              </div>
              
              <div className="metric-card">
                <div className="text-2xl font-bold text-purple-600">
                  {calculatedMetrics.validationRules}
                </div>
                <div className="text-xs text-gray-500">Validations</div>
              </div>
            </>
          )}
        </div>

        {/* Field Type Breakdown */}
        {showBreakdown && fieldTypeBreakdown.length > 0 && (
          <div className="mb-4">
            <div className="text-sm font-medium text-gray-700 mb-2">
              Field Types
            </div>
            <div className="flex flex-wrap gap-2">
              {fieldTypeBreakdown.map(({ type, count, icon: Icon, color }) => (
                <Tooltip key={type}>
                  <TooltipTrigger asChild>
                    <div className={cn(
                      'field-type-badge',
                      'flex items-center gap-1.5 px-2.5 py-1 rounded-md',
                      'bg-gray-50 border border-gray-200',
                      'cursor-default'
                    )}>
                      <Icon className={cn('w-3.5 h-3.5', color)} />
                      <span className="text-sm font-medium text-gray-700">
                        {count}
                      </span>
                    </div>
                  </TooltipTrigger>
                  <TooltipContent>
                    {count} {type} field{count !== 1 ? 's' : ''}
                  </TooltipContent>
                </Tooltip>
              ))}
            </div>
          </div>
        )}

        {/* Estimated Time */}
        {showEstimates && calculatedMetrics.estimatedTime && (
          <div className="mb-4">
            <div className="flex items-center justify-between mb-1">
              <div className="flex items-center gap-2">
                <Clock className="w-4 h-4 text-gray-500" />
                <span className="text-sm text-gray-700">
                  Estimated Completion
                </span>
              </div>
              <span className="text-sm font-medium text-gray-900">
                {calculatedMetrics.estimatedTime < 60
                  ? `${calculatedMetrics.estimatedTime} min`
                  : `${Math.round(calculatedMetrics.estimatedTime / 60)} hr ${calculatedMetrics.estimatedTime % 60} min`
                }
              </span>
            </div>
          </div>
        )}

        {/* Complexity Score */}
        {showComplexity && calculatedMetrics.complexity && (
          <div className="mb-4">
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm text-gray-700">Template Complexity</span>
              <Tooltip>
                <TooltipTrigger asChild>
                  <div className={cn(
                    'flex items-center gap-1.5 px-2.5 py-1 rounded-md',
                    complexityInfo.bgColor
                  )}>
                    <ComplexityIcon className={cn('w-4 h-4', complexityInfo.color)} />
                    <span className={cn('text-sm font-medium', complexityInfo.color)}>
                      {complexityInfo.label}
                    </span>
                  </div>
                </TooltipTrigger>
                <TooltipContent>
                  {complexityInfo.description}
                </TooltipContent>
              </Tooltip>
            </div>
          </div>
        )}

        {/* Completeness Bar */}
        {!compact && calculatedMetrics.completeness !== undefined && (
          <div>
            <div className="flex items-center justify-between mb-1">
              <span className="text-sm text-gray-700">Completeness</span>
              <span className="text-sm font-medium text-gray-900">
                {calculatedMetrics.completeness}%
              </span>
            </div>
            <div className="w-full h-2 bg-gray-200 rounded-full overflow-hidden">
              <animated.div
                style={progressSpring}
                className={cn(
                  'h-full rounded-full',
                  calculatedMetrics.completeness === 100 ? 'bg-green-500' :
                  calculatedMetrics.completeness >= 75 ? 'bg-blue-500' :
                  calculatedMetrics.completeness >= 50 ? 'bg-yellow-500' :
                  'bg-red-500'
                )}
              />
            </div>
          </div>
        )}
      </animated.div>
    </TooltipProvider>
  );
}

// Hook for calculating template statistics
export function useTemplateStatistics(fields: any[]) {
  const [metrics, setMetrics] = useState<TemplateMetrics>({
    totalFields: 0,
    requiredFields: 0,
    optionalFields: 0,
    conditionalFields: 0,
    calculatedFields: 0,
    validationRules: 0
  });

  useEffect(() => {
    const totalFields = fields.length;
    const requiredFields = fields.filter(f => f.required).length;
    const optionalFields = totalFields - requiredFields;
    const conditionalFields = fields.filter(f => f.conditional).length;
    const calculatedFields = fields.filter(f => f.type === 'calculation').length;
    const validationRules = fields.reduce((sum, f) => sum + (f.validations?.length || 0), 0);
    
    const estimatedTime = requiredFields * 2 + optionalFields * 1;
    
    let complexity: 'simple' | 'moderate' | 'complex' | 'advanced' = 'simple';
    if (totalFields > 50 || validationRules > 30 || conditionalFields > 10) {
      complexity = 'advanced';
    } else if (totalFields > 30 || validationRules > 20 || conditionalFields > 5) {
      complexity = 'complex';
    } else if (totalFields > 15 || validationRules > 10 || conditionalFields > 2) {
      complexity = 'moderate';
    }
    
    const completeness = totalFields > 0 
      ? Math.round((fields.filter(f => f.value).length / totalFields) * 100)
      : 0;
    
    setMetrics({
      totalFields,
      requiredFields,
      optionalFields,
      conditionalFields,
      calculatedFields,
      validationRules,
      estimatedTime,
      complexity,
      completeness
    });
  }, [fields]);

  return metrics;
}