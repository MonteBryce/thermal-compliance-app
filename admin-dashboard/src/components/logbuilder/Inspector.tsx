'use client';

import { useState, useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
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
  Form,
  FormControl,
  FormDescription,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from '@/components/ui/form';
import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from '@/components/ui/accordion';
import { Separator } from '@/components/ui/separator';
import { ScrollArea } from '@/components/ui/scroll-area';
import {
  Plus,
  Trash2,
  Settings,
  Eye,
  EyeOff,
  AlertCircle,
  Info,
} from 'lucide-react';
import { LogField, LogFieldType } from '@/lib/types/logbuilder';

// Validation schema for field configuration
const fieldConfigSchema = z.object({
  label: z.string().min(1, 'Label is required'),
  key: z.string()
    .min(1, 'Key is required')
    .regex(/^[a-zA-Z_][a-zA-Z0-9_]*$/, 'Key must start with letter or underscore and contain only letters, numbers, and underscores'),
  type: z.enum(['text', 'number', 'select', 'checkbox']),
  unit: z.string().optional(),
  required: z.boolean().default(false),
  defaultValue: z.any().optional(),
  validation: z.object({
    min: z.number().optional(),
    max: z.number().optional(),
    pattern: z.string().optional(),
    maxLength: z.number().optional(),
  }).optional(),
  options: z.array(z.object({
    label: z.string(),
    value: z.string(),
  })).optional(),
  visibility: z.object({
    defaultHidden: z.boolean().default(false),
    condition: z.string().optional(),
  }).optional(),
});

type FieldConfigForm = z.infer<typeof fieldConfigSchema>;

interface InspectorProps {
  selectedField?: LogField | null;
  onFieldUpdate?: (field: LogField) => void;
  onFieldCreate?: (field: LogField) => void;
  onClose?: () => void;
}

export function Inspector({ 
  selectedField, 
  onFieldUpdate, 
  onFieldCreate,
  onClose 
}: InspectorProps) {
  const [options, setOptions] = useState<{label: string; value: string}[]>([]);
  const [newOption, setNewOption] = useState({ label: '', value: '' });

  const form = useForm<FieldConfigForm>({
    resolver: zodResolver(fieldConfigSchema),
    defaultValues: {
      label: '',
      key: '',
      type: 'text',
      unit: '',
      required: false,
      defaultValue: '',
      validation: {},
      visibility: {
        defaultHidden: false,
      },
    },
  });

  const watchedType = form.watch('type');

  // Reset form when selected field changes
  useEffect(() => {
    if (selectedField) {
      form.reset({
        label: selectedField.label,
        key: selectedField.key,
        type: selectedField.type,
        unit: selectedField.unit || '',
        required: selectedField.required || false,
        defaultValue: selectedField.defaultValue || '',
        validation: selectedField.validation || {},
        visibility: selectedField.visibility || { defaultHidden: false },
      });
      setOptions(selectedField.options || []);
    } else {
      form.reset();
      setOptions([]);
    }
  }, [selectedField, form]);

  const onSubmit = (data: FieldConfigForm) => {
    const field: LogField = {
      id: selectedField?.id || `field-${Date.now()}`,
      label: data.label,
      key: data.key,
      type: data.type,
      unit: data.unit || undefined,
      required: data.required,
      defaultValue: data.defaultValue || undefined,
      validation: Object.keys(data.validation || {}).length > 0 ? data.validation : undefined,
      options: data.type === 'select' ? options : undefined,
      visibility: data.visibility?.defaultHidden ? data.visibility : undefined,
    };

    if (selectedField) {
      onFieldUpdate?.(field);
    } else {
      onFieldCreate?.(field);
    }
  };

  const handleAddOption = () => {
    if (newOption.label && newOption.value) {
      setOptions([...options, newOption]);
      setNewOption({ label: '', value: '' });
    }
  };

  const handleRemoveOption = (index: number) => {
    setOptions(options.filter((_, i) => i !== index));
  };

  const generateKeyFromLabel = (label: string) => {
    return label
      .toLowerCase()
      .replace(/[^a-zA-Z0-9\s]/g, '')
      .replace(/\s+/g, '_')
      .replace(/^[0-9]/, '_$&');
  };

  const handleLabelChange = (label: string) => {
    form.setValue('label', label);
    
    // Auto-generate key if it's empty or matches the previous auto-generated key
    const currentKey = form.getValues('key');
    if (!currentKey || currentKey === generateKeyFromLabel(form.formState.defaultValues?.label || '')) {
      form.setValue('key', generateKeyFromLabel(label));
    }
  };

  if (!selectedField && !onFieldCreate) {
    return (
      <Card className="w-80 h-full">
        <CardContent className="flex items-center justify-center h-full">
          <div className="text-center space-y-4">
            <Settings className="h-12 w-12 mx-auto text-muted-foreground" />
            <div>
              <h3 className="font-medium">No field selected</h3>
              <p className="text-sm text-muted-foreground">
                Select a field to edit its properties
              </p>
            </div>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className="w-80 h-full">
      <CardHeader>
        <div className="flex items-center justify-between">
          <CardTitle className="text-lg">
            {selectedField ? 'Edit Field' : 'New Field'}
          </CardTitle>
          {onClose && (
            <Button variant="ghost" size="sm" onClick={onClose}>
              ×
            </Button>
          )}
        </div>
      </CardHeader>
      <CardContent className="p-0">
        <ScrollArea className="h-[calc(100vh-120px)] px-6">
          <Form {...form}>
            <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
              {/* Basic Properties */}
              <div className="space-y-4">
                <h4 className="font-medium text-sm">Basic Properties</h4>
                
                <FormField
                  control={form.control}
                  name="label"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Display Label</FormLabel>
                      <FormControl>
                        <Input 
                          {...field} 
                          onChange={(e) => handleLabelChange(e.target.value)}
                          placeholder="Enter field label"
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                <FormField
                  control={form.control}
                  name="key"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Field Key</FormLabel>
                      <FormControl>
                        <Input {...field} placeholder="field_key" />
                      </FormControl>
                      <FormDescription>
                        Firestore field name (letters, numbers, underscores only)
                      </FormDescription>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                <FormField
                  control={form.control}
                  name="type"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Field Type</FormLabel>
                      <Select onValueChange={field.onChange} defaultValue={field.value}>
                        <FormControl>
                          <SelectTrigger>
                            <SelectValue placeholder="Select field type" />
                          </SelectTrigger>
                        </FormControl>
                        <SelectContent>
                          <SelectItem value="text">Text</SelectItem>
                          <SelectItem value="number">Number</SelectItem>
                          <SelectItem value="select">Select Dropdown</SelectItem>
                          <SelectItem value="checkbox">Checkbox</SelectItem>
                        </SelectContent>
                      </Select>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                <FormField
                  control={form.control}
                  name="unit"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Unit (Optional)</FormLabel>
                      <FormControl>
                        <Input {...field} placeholder="°F, scfh, ppm, etc." />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                <FormField
                  control={form.control}
                  name="required"
                  render={({ field }) => (
                    <FormItem className="flex flex-row items-center justify-between rounded-lg border p-3">
                      <div className="space-y-0.5">
                        <FormLabel>Required Field</FormLabel>
                        <FormDescription>
                          Operators must fill this field
                        </FormDescription>
                      </div>
                      <FormControl>
                        <Switch
                          checked={field.value}
                          onCheckedChange={field.onChange}
                        />
                      </FormControl>
                    </FormItem>
                  )}
                />
              </div>

              <Separator />

              {/* Field-specific options */}
              {watchedType === 'select' && (
                <div className="space-y-4">
                  <h4 className="font-medium text-sm">Select Options</h4>
                  
                  <div className="space-y-2">
                    {options.map((option, index) => (
                      <div key={index} className="flex items-center gap-2 p-2 border rounded">
                        <div className="flex-1">
                          <div className="font-medium text-sm">{option.label}</div>
                          <div className="text-xs text-muted-foreground">{option.value}</div>
                        </div>
                        <Button
                          type="button"
                          variant="ghost"
                          size="sm"
                          onClick={() => handleRemoveOption(index)}
                        >
                          <Trash2 className="h-3 w-3" />
                        </Button>
                      </div>
                    ))}
                  </div>

                  <div className="space-y-2 p-3 border rounded-lg bg-muted/30">
                    <Label className="text-sm">Add Option</Label>
                    <div className="space-y-2">
                      <Input
                        placeholder="Option label"
                        value={newOption.label}
                        onChange={(e) => setNewOption({ ...newOption, label: e.target.value })}
                      />
                      <Input
                        placeholder="Option value"
                        value={newOption.value}
                        onChange={(e) => setNewOption({ ...newOption, value: e.target.value })}
                      />
                      <Button
                        type="button"
                        variant="outline"
                        size="sm"
                        onClick={handleAddOption}
                        disabled={!newOption.label || !newOption.value}
                      >
                        <Plus className="h-3 w-3 mr-2" />
                        Add Option
                      </Button>
                    </div>
                  </div>
                </div>
              )}

              <Separator />

              {/* Validation Rules */}
              <Accordion type="single" collapsible>
                <AccordionItem value="validation">
                  <AccordionTrigger className="text-sm">
                    Validation Rules
                  </AccordionTrigger>
                  <AccordionContent className="space-y-4">
                    {(watchedType === 'number') && (
                      <>
                        <FormField
                          control={form.control}
                          name="validation.min"
                          render={({ field }) => (
                            <FormItem>
                              <FormLabel>Minimum Value</FormLabel>
                              <FormControl>
                                <Input 
                                  type="number" 
                                  {...field}
                                  onChange={(e) => field.onChange(e.target.value ? Number(e.target.value) : undefined)}
                                />
                              </FormControl>
                              <FormMessage />
                            </FormItem>
                          )}
                        />

                        <FormField
                          control={form.control}
                          name="validation.max"
                          render={({ field }) => (
                            <FormItem>
                              <FormLabel>Maximum Value</FormLabel>
                              <FormControl>
                                <Input 
                                  type="number" 
                                  {...field}
                                  onChange={(e) => field.onChange(e.target.value ? Number(e.target.value) : undefined)}
                                />
                              </FormControl>
                              <FormMessage />
                            </FormItem>
                          )}
                        />
                      </>
                    )}

                    {watchedType === 'text' && (
                      <>
                        <FormField
                          control={form.control}
                          name="validation.maxLength"
                          render={({ field }) => (
                            <FormItem>
                              <FormLabel>Maximum Length</FormLabel>
                              <FormControl>
                                <Input 
                                  type="number" 
                                  {...field}
                                  onChange={(e) => field.onChange(e.target.value ? Number(e.target.value) : undefined)}
                                />
                              </FormControl>
                              <FormMessage />
                            </FormItem>
                          )}
                        />

                        <FormField
                          control={form.control}
                          name="validation.pattern"
                          render={({ field }) => (
                            <FormItem>
                              <FormLabel>Pattern (Regex)</FormLabel>
                              <FormControl>
                                <Input {...field} placeholder="^[A-Z]+$" />
                              </FormControl>
                              <FormDescription>
                                Regular expression for validation
                              </FormDescription>
                              <FormMessage />
                            </FormItem>
                          )}
                        />
                      </>
                    )}

                    <FormField
                      control={form.control}
                      name="defaultValue"
                      render={({ field }) => (
                        <FormItem>
                          <FormLabel>Default Value</FormLabel>
                          <FormControl>
                            {watchedType === 'checkbox' ? (
                              <Switch
                                checked={field.value}
                                onCheckedChange={field.onChange}
                              />
                            ) : watchedType === 'number' ? (
                              <Input
                                type="number"
                                {...field}
                                onChange={(e) => field.onChange(e.target.value ? Number(e.target.value) : undefined)}
                              />
                            ) : (
                              <Input {...field} />
                            )}
                          </FormControl>
                          <FormMessage />
                        </FormItem>
                      )}
                    />
                  </AccordionContent>
                </AccordionItem>

                <AccordionItem value="visibility">
                  <AccordionTrigger className="text-sm">
                    Visibility Settings
                  </AccordionTrigger>
                  <AccordionContent className="space-y-4">
                    <FormField
                      control={form.control}
                      name="visibility.defaultHidden"
                      render={({ field }) => (
                        <FormItem className="flex flex-row items-center justify-between rounded-lg border p-3">
                          <div className="space-y-0.5">
                            <FormLabel>Hidden by Default</FormLabel>
                            <FormDescription>
                              Show in "More Fields" section
                            </FormDescription>
                          </div>
                          <FormControl>
                            <Switch
                              checked={field.value}
                              onCheckedChange={field.onChange}
                            />
                          </FormControl>
                        </FormItem>
                      )}
                    />

                    <div className="p-3 bg-blue-50 border border-blue-200 rounded-lg">
                      <div className="flex items-start gap-2">
                        <Info className="h-4 w-4 text-blue-600 mt-0.5" />
                        <div className="text-sm text-blue-800">
                          <strong>Hidden Fields:</strong> Some variables like "Tank Refill Flow Rate" 
                          are not shown by default but can be accessed via "More Fields" expandable section.
                        </div>
                      </div>
                    </div>
                  </AccordionContent>
                </AccordionItem>
              </Accordion>

              <Separator />

              {/* Actions */}
              <div className="space-y-2 pb-6">
                <Button type="submit" className="w-full">
                  {selectedField ? 'Update Field' : 'Create Field'}
                </Button>
                
                {selectedField && (
                  <Button 
                    type="button" 
                    variant="outline" 
                    className="w-full"
                    onClick={() => {
                      // Preview field
                      console.log('Preview field:', selectedField);
                    }}
                  >
                    <Eye className="h-4 w-4 mr-2" />
                    Preview Field
                  </Button>
                )}
              </div>
            </form>
          </Form>
        </ScrollArea>
      </CardContent>
    </Card>
  );
}