'use client';

import { useState, useEffect, useCallback, useRef } from 'react';
import { Command, CommandEmpty, CommandGroup, CommandInput, CommandItem, CommandList } from '@/components/ui/command';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Check, ChevronDown, Lightbulb, Loader2 } from 'lucide-react';
import { LogField } from '@/lib/types/logbuilder';
import { generateFieldSuggestions, FieldSuggestion } from '@/lib/services/openai';
import { cn } from '@/lib/utils';

interface FieldTypeaheadProps {
  value: string;
  onChange: (value: string) => void;
  field?: LogField;
  existingFields?: LogField[];
  templateType?: string;
  industryContext?: string;
  placeholder?: string;
  disabled?: boolean;
  className?: string;
  type: 'label' | 'key' | 'helpText';
}

interface CachedSuggestion {
  suggestion: string;
  confidence: number;
  source: 'ai' | 'pattern' | 'history';
  lastUsed: number;
}

export function FieldTypeahead({
  value,
  onChange,
  field,
  existingFields = [],
  templateType = 'thermal-log',
  industryContext = 'industrial',
  placeholder,
  disabled = false,
  className,
  type,
}: FieldTypeaheadProps) {
  const [open, setOpen] = useState(false);
  const [searchTerm, setSearchTerm] = useState(value);
  const [suggestions, setSuggestions] = useState<CachedSuggestion[]>([]);
  const [aiSuggestions, setAiSuggestions] = useState<FieldSuggestion[]>([]);
  const [isLoadingAI, setIsLoadingAI] = useState(false);
  const [selectedIndex, setSelectedIndex] = useState(-1);
  
  const debounceTimer = useRef<NodeJS.Timeout>();
  const cacheKey = `field-typeahead-${type}-${templateType}`;

  // Load cached suggestions from localStorage
  useEffect(() => {
    const cached = localStorage.getItem(cacheKey);
    if (cached) {
      try {
        const parsed = JSON.parse(cached);
        setSuggestions(parsed);
      } catch (error) {
        console.warn('Failed to parse cached suggestions:', error);
      }
    }
  }, [cacheKey]);

  // Generate pattern-based suggestions
  const generatePatternSuggestions = useCallback((): CachedSuggestion[] => {
    const patterns: { [key: string]: string[] } = {
      label: [
        'Temperature Reading',
        'Pressure Reading', 
        'Flow Rate',
        'Operating Hours',
        'Maintenance Date',
        'Inspector Name',
        'Serial Number',
        'Model Number',
        'Calibration Date',
        'Location',
        'Comments',
        'Status',
        'Equipment ID',
        'Reading Time',
        'Alarm Status'
      ],
      key: [
        'temp_reading',
        'pressure_reading',
        'flow_rate', 
        'operating_hours',
        'maintenance_date',
        'inspector_name',
        'serial_number',
        'model_number',
        'calibration_date',
        'location',
        'comments',
        'status',
        'equipment_id',
        'reading_time',
        'alarm_status'
      ],
      helpText: [
        'Enter the current temperature reading in degrees Fahrenheit',
        'Record the current pressure reading from the gauge',
        'Measure the flow rate in cubic feet per minute',
        'Total operating hours since last maintenance',
        'Date of last scheduled maintenance',
        'Name of the qualified inspector',
        'Equipment serial number from nameplate',
        'Equipment model number from nameplate',
        'Date of last calibration check',
        'Physical location or zone identifier',
        'Additional notes or observations',
        'Current operational status',
        'Unique equipment identifier',
        'Time when reading was taken',
        'Current alarm or warning status'
      ]
    };

    return (patterns[type] || []).map((suggestion, index) => ({
      suggestion,
      confidence: 0.8 - (index * 0.02), // Higher confidence for earlier suggestions
      source: 'pattern' as const,
      lastUsed: 0
    }));
  }, [type]);

  // Debounced AI suggestion generation
  const generateAISuggestions = useCallback(async () => {
    if (!field || searchTerm.length < 2 || isLoadingAI) return;
    
    setIsLoadingAI(true);
    try {
      const result = await generateFieldSuggestions({
        templateType,
        existingFields,
        industryContext,
        complianceRequirements: ['EPA', 'OSHA']
      });
      
      setAiSuggestions(result.suggestions);
    } catch (error) {
      console.error('Failed to generate AI suggestions:', error);
    } finally {
      setIsLoadingAI(false);
    }
  }, [field, searchTerm, templateType, existingFields, industryContext, isLoadingAI]);

  // Debounced search and AI suggestion generation
  useEffect(() => {
    if (debounceTimer.current) {
      clearTimeout(debounceTimer.current);
    }

    debounceTimer.current = setTimeout(() => {
      if (open && searchTerm !== value) {
        generateAISuggestions();
      }
    }, 500);

    return () => {
      if (debounceTimer.current) {
        clearTimeout(debounceTimer.current);
      }
    };
  }, [searchTerm, open, value, generateAISuggestions]);

  // Filter suggestions based on search term
  const filteredSuggestions = useCallback(() => {
    const patternSuggestions = generatePatternSuggestions();
    const allSuggestions = [...suggestions, ...patternSuggestions];
    
    if (!searchTerm || searchTerm.length < 2) {
      return allSuggestions.slice(0, 10);
    }

    const filtered = allSuggestions.filter(s => 
      s.suggestion.toLowerCase().includes(searchTerm.toLowerCase())
    );

    return filtered
      .sort((a, b) => b.confidence - a.confidence)
      .slice(0, 8);
  }, [searchTerm, suggestions, generatePatternSuggestions]);

  // Handle suggestion selection
  const handleSuggestionSelect = useCallback((suggestion: string) => {
    onChange(suggestion);
    setSearchTerm(suggestion);
    setOpen(false);
    
    // Update suggestion cache with usage
    const updatedSuggestions = [...suggestions];
    const existingIndex = updatedSuggestions.findIndex(s => s.suggestion === suggestion);
    
    if (existingIndex >= 0) {
      updatedSuggestions[existingIndex] = {
        ...updatedSuggestions[existingIndex],
        lastUsed: Date.now(),
        confidence: Math.min(1.0, updatedSuggestions[existingIndex].confidence + 0.1)
      };
    } else {
      updatedSuggestions.push({
        suggestion,
        confidence: 0.9,
        source: 'history',
        lastUsed: Date.now()
      });
    }
    
    // Keep only the most recent 50 suggestions
    const sortedSuggestions = updatedSuggestions
      .sort((a, b) => b.lastUsed - a.lastUsed)
      .slice(0, 50);
    
    setSuggestions(sortedSuggestions);
    localStorage.setItem(cacheKey, JSON.stringify(sortedSuggestions));
  }, [onChange, suggestions, cacheKey]);

  // Handle keyboard navigation
  const handleKeyDown = useCallback((e: React.KeyboardEvent) => {
    if (!open) return;
    
    const filtered = filteredSuggestions();
    
    switch (e.key) {
      case 'ArrowDown':
        e.preventDefault();
        setSelectedIndex(prev => Math.min(prev + 1, filtered.length - 1));
        break;
      case 'ArrowUp':
        e.preventDefault();
        setSelectedIndex(prev => Math.max(prev - 1, -1));
        break;
      case 'Enter':
        e.preventDefault();
        if (selectedIndex >= 0 && selectedIndex < filtered.length) {
          handleSuggestionSelect(filtered[selectedIndex].suggestion);
        }
        break;
      case 'Escape':
        e.preventDefault();
        setOpen(false);
        setSelectedIndex(-1);
        break;
    }
  }, [open, selectedIndex, filteredSuggestions, handleSuggestionSelect]);

  // Sync searchTerm with value prop
  useEffect(() => {
    if (value !== searchTerm && !open) {
      setSearchTerm(value);
    }
  }, [value, open, searchTerm]);

  const filtered = filteredSuggestions();
  const hasAISuggestions = aiSuggestions.length > 0;

  return (
    <div className={cn('relative', className)}>
      <Popover open={open} onOpenChange={setOpen}>
        <PopoverTrigger asChild>
          <div className="relative">
            <Input
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              onKeyDown={handleKeyDown}
              onFocus={() => setOpen(true)}
              placeholder={placeholder || `Enter field ${type}...`}
              disabled={disabled}
              className="pr-8"
            />
            <Button
              variant="ghost"
              size="sm"
              className="absolute right-0 top-0 h-full px-2 hover:bg-transparent"
              onClick={() => setOpen(!open)}
              disabled={disabled}
            >
              <ChevronDown className={cn("h-4 w-4 transition-transform", open && "rotate-180")} />
            </Button>
          </div>
        </PopoverTrigger>
        
        <PopoverContent className="w-full p-0" align="start">
          <Command>
            <CommandList>
              {filtered.length === 0 && !isLoadingAI ? (
                <CommandEmpty>No suggestions found</CommandEmpty>
              ) : (
                <>
                  {/* Pattern and cached suggestions */}
                  {filtered.length > 0 && (
                    <CommandGroup heading="Suggestions">
                      {filtered.map((suggestion, index) => (
                        <CommandItem
                          key={`${suggestion.source}-${index}`}
                          value={suggestion.suggestion}
                          onSelect={() => handleSuggestionSelect(suggestion.suggestion)}
                          className={cn(
                            'cursor-pointer',
                            selectedIndex === index && 'bg-accent'
                          )}
                        >
                          <div className="flex items-center justify-between w-full">
                            <span>{suggestion.suggestion}</span>
                            <div className="flex items-center gap-2">
                              <Badge 
                                variant={suggestion.source === 'ai' ? 'default' : 'secondary'}
                                className="text-xs"
                              >
                                {suggestion.source}
                              </Badge>
                              {suggestion.source === 'ai' && (
                                <Lightbulb className="h-3 w-3 text-orange-500" />
                              )}
                            </div>
                          </div>
                        </CommandItem>
                      ))}
                    </CommandGroup>
                  )}

                  {/* AI suggestions */}
                  {hasAISuggestions && (
                    <CommandGroup heading="AI Suggestions">
                      {aiSuggestions.slice(0, 3).map((suggestion, index) => {
                        const fieldValue = type === 'label' ? suggestion.field.label :
                                         type === 'key' ? suggestion.field.key :
                                         suggestion.reasoning;
                        
                        return (
                          <CommandItem
                            key={`ai-${index}`}
                            value={fieldValue}
                            onSelect={() => handleSuggestionSelect(fieldValue)}
                            className="cursor-pointer"
                          >
                            <div className="flex items-center justify-between w-full">
                              <div className="flex-1">
                                <div className="font-medium">{fieldValue}</div>
                                {suggestion.reasoning && (
                                  <div className="text-xs text-muted-foreground truncate">
                                    {suggestion.reasoning}
                                  </div>
                                )}
                              </div>
                              <div className="flex items-center gap-2">
                                <Badge variant="default" className="text-xs">
                                  {Math.round(suggestion.confidence * 100)}%
                                </Badge>
                                <Lightbulb className="h-3 w-3 text-orange-500" />
                              </div>
                            </div>
                          </CommandItem>
                        );
                      })}
                    </CommandGroup>
                  )}

                  {/* Loading state */}
                  {isLoadingAI && (
                    <div className="flex items-center justify-center p-4">
                      <Loader2 className="h-4 w-4 animate-spin mr-2" />
                      <span className="text-sm text-muted-foreground">
                        Generating AI suggestions...
                      </span>
                    </div>
                  )}
                </>
              )}
            </CommandList>
          </Command>
        </PopoverContent>
      </Popover>
    </div>
  );
}