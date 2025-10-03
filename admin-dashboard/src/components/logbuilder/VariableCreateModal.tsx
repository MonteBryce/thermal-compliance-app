'use client';

import { useState } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Checkbox } from '@/components/ui/checkbox';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Badge } from '@/components/ui/badge';
import { Plus, X, AlertCircle } from 'lucide-react';
import { LogVariable, VariableCategory } from '@/lib/types/variable-palette';
import { cn } from '@/lib/utils';

interface VariableCreateModalProps {
  isOpen: boolean;
  onClose: () => void;
  onCreate: (variable: Omit<LogVariable, 'id'>) => void;
  categories: VariableCategory[];
}

export function VariableCreateModal({
  isOpen,
  onClose,
  onCreate,
  categories,
}: VariableCreateModalProps) {
  const [formData, setFormData] = useState<Partial<LogVariable>>({
    name: '',
    category: '',
    dataType: 'text',
    description: '',
    excelColumn: '',
    tags: [],
    validation: {
      required: false,
    },
    options: [],
  });
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [tagInput, setTagInput] = useState('');
  const [optionInput, setOptionInput] = useState({ label: '', value: '' });
  const [customRuleInput, setCustomRuleInput] = useState({ rule: '', message: '' });

  const validate = () => {
    const newErrors: Record<string, string> = {};
    
    if (!formData.name?.trim()) {
      newErrors.name = 'Variable name is required';
    } else if (formData.name.length < 2) {
      newErrors.name = 'Variable name must be at least 2 characters';
    }
    
    if (!formData.category) {
      newErrors.category = 'Category is required';
    }
    
    if (formData.excelColumn && !/^[A-Z]{1,3}$/.test(formData.excelColumn)) {
      newErrors.excelColumn = 'Excel column must be 1-3 uppercase letters (e.g., A, AB, AAA)';
    }
    
    if (formData.dataType === 'number') {
      if (formData.validation?.min !== undefined && 
          formData.validation?.max !== undefined && 
          formData.validation.min > formData.validation.max) {
        newErrors.validation = 'Minimum value cannot be greater than maximum value';
      }
    }
    
    if (formData.dataType === 'select' && (!formData.options || formData.options.length === 0)) {
      newErrors.options = 'Select fields must have at least one option';
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = () => {
    if (!validate()) return;
    
    onCreate({
      name: formData.name!,
      category: formData.category!,
      dataType: formData.dataType as any,
      description: formData.description,
      excelColumn: formData.excelColumn,
      tags: formData.tags,
      validation: formData.validation,
      options: formData.options,
      defaultValue: formData.defaultValue,
      unit: formData.unit,
      formula: formData.formula,
      dependsOn: formData.dependsOn,
      isFavorite: false,
      lastUsed: null,
    });
    
    resetForm();
    onClose();
  };

  const resetForm = () => {
    setFormData({
      name: '',
      category: '',
      dataType: 'text',
      description: '',
      excelColumn: '',
      tags: [],
      validation: {
        required: false,
      },
      options: [],
    });
    setErrors({});
    setTagInput('');
    setOptionInput({ label: '', value: '' });
    setCustomRuleInput({ rule: '', message: '' });
  };

  const addTag = () => {
    if (tagInput.trim() && !formData.tags?.includes(tagInput.trim())) {
      setFormData(prev => ({
        ...prev,
        tags: [...(prev.tags || []), tagInput.trim()],
      }));
      setTagInput('');
    }
  };

  const removeTag = (tag: string) => {
    setFormData(prev => ({
      ...prev,
      tags: prev.tags?.filter(t => t !== tag),
    }));
  };

  const addOption = () => {
    if (optionInput.label.trim() && optionInput.value.trim()) {
      setFormData(prev => ({
        ...prev,
        options: [...(prev.options || []), { ...optionInput }],
      }));
      setOptionInput({ label: '', value: '' });
      setErrors(prev => ({ ...prev, options: '' }));
    }
  };

  const removeOption = (index: number) => {
    setFormData(prev => ({
      ...prev,
      options: prev.options?.filter((_, i) => i !== index),
    }));
  };

  const addCustomRule = () => {
    if (customRuleInput.rule.trim() && customRuleInput.message.trim()) {
      setFormData(prev => ({
        ...prev,
        validation: {
          ...prev.validation,
          customRules: [
            ...(prev.validation?.customRules || []),
            { ...customRuleInput },
          ],
        },
      }));
      setCustomRuleInput({ rule: '', message: '' });
    }
  };

  const removeCustomRule = (index: number) => {
    setFormData(prev => ({
      ...prev,
      validation: {
        ...prev.validation,
        customRules: prev.validation?.customRules?.filter((_, i) => i !== index),
      },
    }));
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Create New Variable</DialogTitle>
        </DialogHeader>

        <Tabs defaultValue="basic" className="w-full">
          <TabsList className="grid w-full grid-cols-3">
            <TabsTrigger value="basic">Basic Info</TabsTrigger>
            <TabsTrigger value="validation">Validation</TabsTrigger>
            <TabsTrigger value="advanced">Advanced</TabsTrigger>
          </TabsList>

          <TabsContent value="basic" className="space-y-4 mt-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label htmlFor="name">
                  Variable Name <span className="text-destructive">*</span>
                </Label>
                <Input
                  id="name"
                  value={formData.name}
                  onChange={(e) => {
                    setFormData(prev => ({ ...prev, name: e.target.value }));
                    setErrors(prev => ({ ...prev, name: '' }));
                  }}
                  placeholder="e.g., Temperature Reading"
                  aria-invalid={!!errors.name}
                  aria-describedby={errors.name ? 'name-error' : undefined}
                />
                {errors.name && (
                  <p id="name-error" className="text-sm text-destructive mt-1">
                    {errors.name}
                  </p>
                )}
              </div>

              <div>
                <Label htmlFor="category">
                  Category <span className="text-destructive">*</span>
                </Label>
                <Select
                  value={formData.category}
                  onValueChange={(value) => {
                    setFormData(prev => ({ ...prev, category: value }));
                    setErrors(prev => ({ ...prev, category: '' }));
                  }}
                >
                  <SelectTrigger id="category" aria-invalid={!!errors.category}>
                    <SelectValue placeholder="Select a category" />
                  </SelectTrigger>
                  <SelectContent>
                    {categories.map(cat => (
                      <SelectItem key={cat.name} value={cat.name}>
                        {cat.name}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                {errors.category && (
                  <p className="text-sm text-destructive mt-1">{errors.category}</p>
                )}
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label htmlFor="dataType">
                  Data Type <span className="text-destructive">*</span>
                </Label>
                <Select
                  value={formData.dataType}
                  onValueChange={(value) => 
                    setFormData(prev => ({ ...prev, dataType: value as any }))
                  }
                >
                  <SelectTrigger id="dataType">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="text">Text</SelectItem>
                    <SelectItem value="number">Number</SelectItem>
                    <SelectItem value="date">Date</SelectItem>
                    <SelectItem value="select">Select Dropdown</SelectItem>
                    <SelectItem value="checkbox">Checkbox</SelectItem>
                    <SelectItem value="textarea">Textarea</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div>
                <Label htmlFor="excelColumn">Excel Column</Label>
                <Input
                  id="excelColumn"
                  value={formData.excelColumn}
                  onChange={(e) => {
                    const value = e.target.value.toUpperCase();
                    setFormData(prev => ({ ...prev, excelColumn: value }));
                    setErrors(prev => ({ ...prev, excelColumn: '' }));
                  }}
                  placeholder="e.g., A, AB, AAA"
                  maxLength={3}
                  aria-invalid={!!errors.excelColumn}
                />
                {errors.excelColumn && (
                  <p className="text-sm text-destructive mt-1">{errors.excelColumn}</p>
                )}
              </div>
            </div>

            <div>
              <Label htmlFor="description">Description</Label>
              <Textarea
                id="description"
                value={formData.description}
                onChange={(e) => 
                  setFormData(prev => ({ ...prev, description: e.target.value }))
                }
                placeholder="Brief description of what this variable captures..."
                rows={3}
              />
            </div>

            <div>
              <Label htmlFor="tags">Tags</Label>
              <div className="flex gap-2 mb-2">
                <Input
                  id="tags"
                  value={tagInput}
                  onChange={(e) => setTagInput(e.target.value)}
                  placeholder="Enter tag and press Enter"
                  onKeyDown={(e) => {
                    if (e.key === 'Enter') {
                      e.preventDefault();
                      addTag();
                    }
                  }}
                />
                <Button type="button" onClick={addTag} size="sm">
                  Add Tag
                </Button>
              </div>
              <div className="flex flex-wrap gap-1">
                {formData.tags?.map(tag => (
                  <Badge key={tag} variant="secondary">
                    {tag}
                    <button
                      onClick={() => removeTag(tag)}
                      className="ml-1 hover:text-destructive"
                      aria-label={`Remove tag ${tag}`}
                    >
                      <X className="h-3 w-3" />
                    </button>
                  </Badge>
                ))}
              </div>
            </div>

            {formData.dataType === 'select' && (
              <div>
                <Label>Options {errors.options && <span className="text-destructive">*</span>}</Label>
                <div className="space-y-2">
                  <div className="flex gap-2">
                    <Input
                      placeholder="Label"
                      value={optionInput.label}
                      onChange={(e) => 
                        setOptionInput(prev => ({ ...prev, label: e.target.value }))
                      }
                    />
                    <Input
                      placeholder="Value"
                      value={optionInput.value}
                      onChange={(e) => 
                        setOptionInput(prev => ({ ...prev, value: e.target.value }))
                      }
                    />
                    <Button type="button" onClick={addOption} size="sm">
                      <Plus className="h-4 w-4" />
                    </Button>
                  </div>
                  {errors.options && (
                    <p className="text-sm text-destructive">{errors.options}</p>
                  )}
                  <div className="space-y-1">
                    {formData.options?.map((option, index) => (
                      <div key={index} className="flex items-center gap-2 p-2 bg-muted rounded">
                        <span className="flex-1 text-sm">
                          {option.label} ({option.value})
                        </span>
                        <button
                          onClick={() => removeOption(index)}
                          className="text-destructive-foreground hover:text-destructive"
                          aria-label={`Remove option ${option.label}`}
                        >
                          <X className="h-4 w-4" />
                        </button>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            )}
          </TabsContent>

          <TabsContent value="validation" className="space-y-4 mt-4">
            <div className="flex items-center space-x-2">
              <Checkbox
                id="required"
                checked={formData.validation?.required || false}
                onCheckedChange={(checked) => 
                  setFormData(prev => ({
                    ...prev,
                    validation: { ...prev.validation, required: !!checked },
                  }))
                }
              />
              <Label htmlFor="required">Required Field</Label>
            </div>

            {formData.dataType === 'text' && (
              <>
                <div>
                  <Label htmlFor="maxLength">Maximum Length</Label>
                  <Input
                    id="maxLength"
                    type="number"
                    value={formData.validation?.maxLength || ''}
                    onChange={(e) => 
                      setFormData(prev => ({
                        ...prev,
                        validation: {
                          ...prev.validation,
                          maxLength: e.target.value ? parseInt(e.target.value) : undefined,
                        },
                      }))
                    }
                    placeholder="e.g., 100"
                  />
                </div>
                <div>
                  <Label htmlFor="pattern">Regex Pattern</Label>
                  <Input
                    id="pattern"
                    value={formData.validation?.pattern || ''}
                    onChange={(e) => 
                      setFormData(prev => ({
                        ...prev,
                        validation: { ...prev.validation, pattern: e.target.value },
                      }))
                    }
                    placeholder="e.g., ^[A-Z0-9]+$"
                  />
                </div>
              </>
            )}

            {formData.dataType === 'number' && (
              <>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <Label htmlFor="min">Minimum Value</Label>
                    <Input
                      id="min"
                      type="number"
                      value={formData.validation?.min ?? ''}
                      onChange={(e) => 
                        setFormData(prev => ({
                          ...prev,
                          validation: {
                            ...prev.validation,
                            min: e.target.value ? parseFloat(e.target.value) : undefined,
                          },
                        }))
                      }
                      placeholder="e.g., 0"
                    />
                  </div>
                  <div>
                    <Label htmlFor="max">Maximum Value</Label>
                    <Input
                      id="max"
                      type="number"
                      value={formData.validation?.max ?? ''}
                      onChange={(e) => 
                        setFormData(prev => ({
                          ...prev,
                          validation: {
                            ...prev.validation,
                            max: e.target.value ? parseFloat(e.target.value) : undefined,
                          },
                        }))
                      }
                      placeholder="e.g., 100"
                    />
                  </div>
                </div>
                {errors.validation && (
                  <div className="flex items-center gap-2 text-sm text-destructive">
                    <AlertCircle className="h-4 w-4" />
                    {errors.validation}
                  </div>
                )}
              </>
            )}

            <div>
              <Label>Custom Validation Rules</Label>
              <div className="space-y-2">
                <div className="grid grid-cols-[1fr,1fr,auto] gap-2">
                  <Input
                    placeholder="Rule (JavaScript expression)"
                    value={customRuleInput.rule}
                    onChange={(e) => 
                      setCustomRuleInput(prev => ({ ...prev, rule: e.target.value }))
                    }
                  />
                  <Input
                    placeholder="Error message"
                    value={customRuleInput.message}
                    onChange={(e) => 
                      setCustomRuleInput(prev => ({ ...prev, message: e.target.value }))
                    }
                  />
                  <Button type="button" onClick={addCustomRule} size="sm">
                    <Plus className="h-4 w-4" />
                  </Button>
                </div>
                <div className="space-y-1">
                  {formData.validation?.customRules?.map((rule, index) => (
                    <div key={index} className="flex items-start gap-2 p-2 bg-muted rounded text-sm">
                      <div className="flex-1">
                        <code className="text-xs">{rule.rule}</code>
                        <p className="text-muted-foreground mt-1">{rule.message}</p>
                      </div>
                      <button
                        onClick={() => removeCustomRule(index)}
                        className="text-destructive-foreground hover:text-destructive"
                        aria-label="Remove rule"
                      >
                        <X className="h-4 w-4" />
                      </button>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </TabsContent>

          <TabsContent value="advanced" className="space-y-4 mt-4">
            <div>
              <Label htmlFor="defaultValue">Default Value</Label>
              <Input
                id="defaultValue"
                value={formData.defaultValue || ''}
                onChange={(e) => 
                  setFormData(prev => ({ ...prev, defaultValue: e.target.value }))
                }
                placeholder="Default value for this field"
              />
            </div>

            <div>
              <Label htmlFor="unit">Unit of Measurement</Label>
              <Input
                id="unit"
                value={formData.unit || ''}
                onChange={(e) => 
                  setFormData(prev => ({ ...prev, unit: e.target.value }))
                }
                placeholder="e.g., °F, PSI, gallons"
              />
            </div>

            <div>
              <Label htmlFor="formula">Formula</Label>
              <Textarea
                id="formula"
                value={formData.formula || ''}
                onChange={(e) => 
                  setFormData(prev => ({ ...prev, formula: e.target.value }))
                }
                placeholder="e.g., ${temperature} * 1.8 + 32"
                rows={3}
              />
              <p className="text-xs text-muted-foreground mt-1">
                Use ${`{variableName}`} to reference other variables
              </p>
            </div>

            <div>
              <Label htmlFor="dependsOn">Dependencies</Label>
              <Input
                id="dependsOn"
                value={formData.dependsOn?.join(', ') || ''}
                onChange={(e) => {
                  const deps = e.target.value
                    .split(',')
                    .map(d => d.trim())
                    .filter(Boolean);
                  setFormData(prev => ({ ...prev, dependsOn: deps }));
                }}
                placeholder="Comma-separated list of variable IDs"
              />
              <p className="text-xs text-muted-foreground mt-1">
                Variables that this field depends on
              </p>
            </div>
          </TabsContent>
        </Tabs>

        <DialogFooter className="mt-6">
          <Button variant="outline" onClick={onClose}>
            Cancel
          </Button>
          <Button onClick={handleSubmit} aria-label="Save variable">
            Create Variable
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}