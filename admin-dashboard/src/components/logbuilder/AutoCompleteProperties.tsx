import React, { useState, useCallback } from 'react';
import { Wand2, Loader2 } from 'lucide-react';
import { LogField } from '@/lib/types/logbuilder';
import { generateFieldProperties } from '@/lib/services/openai';
import { cn } from '@/lib/utils';

export interface FieldProperties {
  label?: string;
  helpText?: string;
  validation?: {
    required?: boolean;
    min?: number;
    max?: number;
    pattern?: string;
  };
  unit?: string;
  placeholder?: string;
}

export interface AutoCompletePropertiesProps {
  field: LogField;
  onPropertiesGenerated: (properties: FieldProperties) => void;
  onError: (error: Error) => void;
  isLoading?: boolean;
  disabled?: boolean;
  className?: string;
}

export function AutoCompleteProperties({
  field,
  onPropertiesGenerated,
  onError,
  isLoading = false,
  disabled = false,
  className,
}: AutoCompletePropertiesProps) {
  const [internalLoading, setInternalLoading] = useState(false);
  const [generatedProperties, setGeneratedProperties] = useState<FieldProperties | null>(null);

  const loading = isLoading || internalLoading;

  // Generate field properties using AI
  const handleGenerateProperties = useCallback(async () => {
    if (loading || disabled) return;

    setInternalLoading(true);

    try {
      const properties = await generateFieldProperties(field);
      setGeneratedProperties(properties);
      onPropertiesGenerated(properties);
    } catch (error) {
      console.error('Property generation failed:', error);
      onError(error instanceof Error ? error : new Error('Property generation failed'));
    } finally {
      setInternalLoading(false);
    }
  }, [field, loading, disabled, onPropertiesGenerated, onError]);

  return (
    <div
      data-testid="auto-complete-properties"
      className={cn(
        'auto-complete-properties',
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
      <div className="flex items-center justify-between">
        <div>
          <h3 className="text-lg font-semibold text-gray-900">Smart Property Suggestions</h3>
          <p className="text-sm text-gray-600">Field: {field.label || field.key}</p>
        </div>
      </div>

      {/* Generate Button */}
      <button
        type="button"
        onClick={handleGenerateProperties}
        disabled={loading || disabled}
        className={cn(
          'flex items-center gap-2 px-4 py-2 rounded-lg font-medium transition-all duration-200',
          'focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2',
          loading || disabled
            ? 'bg-gray-100 text-gray-400 cursor-not-allowed'
            : 'bg-blue-600 text-white hover:bg-blue-700'
        )}
      >
        {loading ? (
          <>
            <Loader2 className="w-4 h-4 animate-spin" />
            <span>Generating properties...</span>
          </>
        ) : (
          <>
            <Wand2 className="w-4 h-4" />
            <span>Generate Properties</span>
          </>
        )}
      </button>

      {/* Generated Properties Display */}
      {generatedProperties && (
        <div className="space-y-3 p-3 bg-gray-50 rounded-lg">
          <h4 className="font-medium text-gray-900">Generated Properties:</h4>
          
          {generatedProperties.label && (
            <div><strong>Label:</strong> {generatedProperties.label}</div>
          )}
          
          {generatedProperties.helpText && (
            <div><strong>Help Text:</strong> {generatedProperties.helpText}</div>
          )}
          
          {generatedProperties.unit && (
            <div><strong>Unit:</strong> {generatedProperties.unit}</div>
          )}
          
          {generatedProperties.placeholder && (
            <div><strong>Placeholder:</strong> {generatedProperties.placeholder}</div>
          )}
          
          {generatedProperties.validation && Object.keys(generatedProperties.validation).length > 0 && (
            <div>
              <strong>Validation:</strong>
              <ul className="ml-4 text-sm">
                {generatedProperties.validation.required && <li>• Required field</li>}
                {generatedProperties.validation.min !== undefined && <li>• Min: {generatedProperties.validation.min}</li>}
                {generatedProperties.validation.max !== undefined && <li>• Max: {generatedProperties.validation.max}</li>}
                {generatedProperties.validation.pattern && <li>• Pattern: {generatedProperties.validation.pattern}</li>}
              </ul>
            </div>
          )}
        </div>
      )}
    </div>
  );
}

export default AutoCompleteProperties;