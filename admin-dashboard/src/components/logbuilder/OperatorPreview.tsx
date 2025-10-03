'use client';

import { useState, useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { Badge } from '@/components/ui/badge';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from '@/components/ui/collapsible';
import { Separator } from '@/components/ui/separator';
import { ScrollArea } from '@/components/ui/scroll-area';
import {
  ChevronDown,
  Eye,
  EyeOff,
  Clock,
  Save,
  AlertCircle,
  CheckCircle,
  Key,
} from 'lucide-react';
import { LogSchema, LogField, OperatorPreviewConfig } from '@/lib/types/logbuilder';

interface OperatorPreviewProps {
  schema: LogSchema;
  config?: OperatorPreviewConfig;
  onConfigChange?: (config: OperatorPreviewConfig) => void;
}

/**
 * Generate validation schema from LogField
 */
function createFieldValidation(field: LogField) {
  let validation: any = z.any();

  switch (field.type) {
    case 'number':
      validation = z.number();
      if (field.validation?.min !== undefined) {
        validation = validation.min(field.validation.min);
      }
      if (field.validation?.max !== undefined) {
        validation = validation.max(field.validation.max);
      }
      break;
    
    case 'text':
      validation = z.string();
      if (field.validation?.maxLength) {
        validation = validation.max(field.validation.maxLength);
      }
      if (field.validation?.pattern) {
        validation = validation.regex(new RegExp(field.validation.pattern));
      }
      break;
    
    case 'select':
      if (field.options && field.options.length > 0) {
        validation = z.enum(field.options.map(opt => opt.value) as [string, ...string[]]);
      }
      break;
    
    case 'checkbox':
      validation = z.boolean();
      break;
  }

  if (field.required) {
    validation = validation.refine((val: any) => {
      if (field.type === 'checkbox') return val === true;
      if (field.type === 'number') return val !== undefined && val !== null;
      return val !== undefined && val !== null && val !== '';
    }, 'This field is required');
  } else {
    validation = validation.optional();
  }

  return validation;
}

/**
 * Operator-style field component
 */
function OperatorField({ 
  field, 
  value, 
  onChange, 
  error, 
  showKey = false 
}: {
  field: LogField;
  value: any;
  onChange: (value: any) => void;
  error?: string;
  showKey?: boolean;
}) {
  const renderInput = () => {
    switch (field.type) {
      case 'number':
        return (
          <Input
            type="number"
            value={value || ''}
            onChange={(e) => onChange(e.target.value ? Number(e.target.value) : undefined)}
            placeholder={field.defaultValue?.toString() || ''}
            className={error ? 'border-red-500' : ''}
          />
        );
      
      case 'text':
        return (
          <Input
            type="text"
            value={value || ''}
            onChange={(e) => onChange(e.target.value)}
            placeholder={field.defaultValue?.toString() || ''}
            className={error ? 'border-red-500' : ''}
          />
        );
      
      case 'select':
        return (
          <Select value={value || ''} onValueChange={onChange}>
            <SelectTrigger className={error ? 'border-red-500' : ''}>
              <SelectValue placeholder="Select an option" />
            </SelectTrigger>
            <SelectContent>
              {field.options?.map((option) => (
                <SelectItem key={option.value} value={option.value}>
                  {option.label}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        );
      
      case 'checkbox':
        return (
          <div className="flex items-center space-x-2">
            <Switch
              checked={value || false}
              onCheckedChange={onChange}
            />
            <span className="text-sm">{value ? 'Yes' : 'No'}</span>
          </div>
        );
      
      default:
        return (
          <Input
            value={value || ''}
            onChange={(e) => onChange(e.target.value)}
            className={error ? 'border-red-500' : ''}
          />
        );
    }
  };

  return (
    <div className="space-y-2">
      <div className="flex items-center gap-2">
        <Label htmlFor={field.id} className="text-sm font-medium">
          {field.label}
          {field.required && <span className="text-red-500 ml-1">*</span>}
        </Label>
        {field.unit && (
          <Badge variant="secondary" className="text-xs">
            {field.unit}
          </Badge>
        )}
      </div>
      
      {renderInput()}
      
      {showKey && (
        <div className="flex items-center gap-1 text-xs text-muted-foreground">
          <Key className="h-3 w-3" />
          <code className="bg-muted px-1 rounded">{field.key}</code>
        </div>
      )}
      
      {error && (
        <div className="flex items-center gap-1 text-xs text-red-600">
          <AlertCircle className="h-3 w-3" />
          {error}
        </div>
      )}
    </div>
  );
}

/**
 * Hour selector component (Flutter-style)
 */
function HourSelector({ 
  selectedHour, 
  onHourChange 
}: { 
  selectedHour: number; 
  onHourChange: (hour: number) => void;
}) {
  const hours = Array.from({ length: 24 }, (_, i) => i);

  return (
    <Card className="mb-6">
      <CardHeader className="pb-3">
        <CardTitle className="text-lg flex items-center gap-2">
          <Clock className="h-5 w-5" />
          Select Hour
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="grid grid-cols-6 gap-2">
          {hours.map((hour) => (
            <Button
              key={hour}
              variant={selectedHour === hour ? 'default' : 'outline'}
              size="sm"
              onClick={() => onHourChange(hour)}
              className="h-10"
            >
              {hour.toString().padStart(2, '0')}:00
            </Button>
          ))}
        </div>
        <div className="mt-3 text-sm text-muted-foreground">
          Current: <strong>{selectedHour.toString().padStart(2, '0')}:00</strong>
        </div>
      </CardContent>
    </Card>
  );
}

export function OperatorPreview({ 
  schema, 
  config = {
    showKeys: false,
    selectedHour: 0,
    expandMoreFields: false,
    theme: 'light',
  },
  onConfigChange 
}: OperatorPreviewProps) {
  const [formData, setFormData] = useState<Record<string, any>>({});
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isMoreFieldsOpen, setIsMoreFieldsOpen] = useState(config.expandMoreFields);

  // Create validation schema from fields
  const validationSchema = z.object(
    schema.fields.reduce((acc, field) => {
      acc[field.key] = createFieldValidation(field);
      return acc;
    }, {} as Record<string, any>)
  );

  type FormData = z.infer<typeof validationSchema>;

  const form = useForm<FormData>({
    resolver: zodResolver(validationSchema),
    defaultValues: schema.fields.reduce((acc, field) => {
      acc[field.key] = field.defaultValue;
      return acc;
    }, {} as Record<string, any>),
  });

  useEffect(() => {
    setIsMoreFieldsOpen(config.expandMoreFields);
  }, [config.expandMoreFields]);

  const updateConfig = (updates: Partial<OperatorPreviewConfig>) => {
    const newConfig = { ...config, ...updates };
    onConfigChange?.(newConfig);
  };

  const handleFieldChange = (fieldKey: string, value: any) => {
    setFormData(prev => ({ ...prev, [fieldKey]: value }));
    form.setValue(fieldKey as any, value);
    
    // Clear error when field changes
    if (errors[fieldKey]) {
      setErrors(prev => {
        const newErrors = { ...prev };
        delete newErrors[fieldKey];
        return newErrors;
      });
    }
  };

  const handleValidation = async () => {
    try {
      await form.trigger();
      const formErrors = form.formState.errors;
      const errorMessages: Record<string, string> = {};
      
      Object.keys(formErrors).forEach(key => {
        const error = formErrors[key as keyof typeof formErrors];
        if (error?.message) {
          errorMessages[key] = error.message;
        }
      });
      
      setErrors(errorMessages);
      
      if (Object.keys(errorMessages).length === 0) {
        console.log('Form valid! Data:', formData);
      }
    } catch (error) {
      console.error('Validation failed:', error);
    }
  };

  // Separate visible and hidden fields
  const visibleFields = schema.fields.filter(field => !field.visibility?.defaultHidden);
  const hiddenFields = schema.fields.filter(field => field.visibility?.defaultHidden);

  // Group fields by section and row
  const renderSection = (section: any) => {
    return (
      <Card key={section.id} className="mb-4">
        {section.title && (
          <CardHeader className="pb-3">
            <CardTitle className="text-lg">{section.title}</CardTitle>
          </CardHeader>
        )}
        <CardContent className="space-y-4">
          {section.rows.map((row: any, rowIndex: number) => (
            <div key={rowIndex} className="grid grid-cols-12 gap-4">
              {row.columns.map((column: any, colIndex: number) => {
                const field = schema.fields.find(f => f.id === column.fieldId);
                if (!field) return null;

                const colSpan = column.width || 6;
                return (
                  <div key={colIndex} className={`col-span-${colSpan}`}>
                    <OperatorField
                      field={field}
                      value={formData[field.key]}
                      onChange={(value) => handleFieldChange(field.key, value)}
                      error={errors[field.key]}
                      showKey={config.showKeys}
                    />
                  </div>
                );
              })}
            </div>
          ))}
        </CardContent>
      </Card>
    );
  };

  return (
    <div className="max-w-4xl mx-auto p-6">
      {/* Preview Controls */}
      <Card className="mb-6 bg-blue-50 border-blue-200">
        <CardHeader className="pb-3">
          <CardTitle className="text-lg flex items-center gap-2">
            <Eye className="h-5 w-5" />
            Operator Preview
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="flex items-center justify-between">
              <Label htmlFor="show-keys" className="text-sm">Show Firestore Keys</Label>
              <Switch
                id="show-keys"
                checked={config.showKeys}
                onCheckedChange={(checked) => updateConfig({ showKeys: checked })}
              />
            </div>
            
            <div className="flex items-center justify-between">
              <Label htmlFor="expand-more" className="text-sm">Expand More Fields</Label>
              <Switch
                id="expand-more"
                checked={config.expandMoreFields}
                onCheckedChange={(checked) => {
                  updateConfig({ expandMoreFields: checked });
                  setIsMoreFieldsOpen(checked);
                }}
              />
            </div>

            <Button
              variant="outline"
              size="sm"
              onClick={handleValidation}
              className="h-9"
            >
              <CheckCircle className="h-4 w-4 mr-2" />
              Validate Form
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Hour Selector */}
      <HourSelector
        selectedHour={config.selectedHour}
        onHourChange={(hour) => updateConfig({ selectedHour: hour })}
      />

      {/* Form Sections */}
      <div className="space-y-4">
        {schema.layout.map(renderSection)}
        
        {/* More Fields Section */}
        {hiddenFields.length > 0 && (
          <Collapsible open={isMoreFieldsOpen} onOpenChange={setIsMoreFieldsOpen}>
            <Card>
              <CollapsibleTrigger asChild>
                <CardHeader className="cursor-pointer hover:bg-muted/50 transition-colors">
                  <div className="flex items-center justify-between">
                    <CardTitle className="text-lg">
                      More Fields ({hiddenFields.length})
                    </CardTitle>
                    <ChevronDown 
                      className={`h-5 w-5 transition-transform ${
                        isMoreFieldsOpen ? 'rotate-180' : ''
                      }`} 
                    />
                  </div>
                </CardHeader>
              </CollapsibleTrigger>
              <CollapsibleContent>
                <CardContent className="pt-0">
                  <div className="text-sm text-muted-foreground mb-4">
                    Optional fields that are not shown by default
                  </div>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    {hiddenFields.map((field) => (
                      <OperatorField
                        key={field.id}
                        field={field}
                        value={formData[field.key]}
                        onChange={(value) => handleFieldChange(field.key, value)}
                        error={errors[field.key]}
                        showKey={config.showKeys}
                      />
                    ))}
                  </div>
                </CardContent>
              </CollapsibleContent>
            </Card>
          </Collapsible>
        )}
      </div>

      {/* Form Actions (Flutter-style) */}
      <Card className="mt-6 bg-green-50 border-green-200">
        <CardContent className="pt-6">
          <div className="flex justify-between items-center">
            <div className="text-sm text-green-800">
              <strong>Hour {config.selectedHour.toString().padStart(2, '0')}:00</strong> - 
              Ready to save entry
            </div>
            <Button className="bg-green-600 hover:bg-green-700">
              <Save className="h-4 w-4 mr-2" />
              Save Entry
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Validation Summary */}
      {Object.keys(errors).length > 0 && (
        <Card className="mt-4 border-red-200 bg-red-50">
          <CardContent className="pt-6">
            <div className="flex items-start gap-2">
              <AlertCircle className="h-5 w-5 text-red-600 mt-0.5" />
              <div>
                <h4 className="font-medium text-red-800 mb-2">Validation Errors</h4>
                <ul className="space-y-1 text-sm text-red-700">
                  {Object.entries(errors).map(([fieldKey, error]) => {
                    const field = schema.fields.find(f => f.key === fieldKey);
                    return (
                      <li key={fieldKey}>
                        <strong>{field?.label || fieldKey}:</strong> {error}
                      </li>
                    );
                  })}
                </ul>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Debug Info (when keys are shown) */}
      {config.showKeys && (
        <Card className="mt-4 bg-gray-50 border-gray-200">
          <CardHeader>
            <CardTitle className="text-sm">Debug: Form Data</CardTitle>
          </CardHeader>
          <CardContent>
            <pre className="text-xs overflow-auto">
              {JSON.stringify(formData, null, 2)}
            </pre>
          </CardContent>
        </Card>
      )}
    </div>
  );
}