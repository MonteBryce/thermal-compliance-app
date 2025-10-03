'use client';

import { useState, useEffect, useCallback, useMemo, useRef } from 'react';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { Command, CommandEmpty, CommandGroup, CommandInput, CommandItem, CommandList } from '@/components/ui/command';
import { Badge } from '@/components/ui/badge';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Checkbox } from '@/components/ui/checkbox';
import {
  Search,
  X,
  Clock,
  Filter,
  ChevronDown,
  Tag,
  Type,
  Hash,
  Calendar,
  List as ListIcon,
  CheckSquare,
  FileText,
} from 'lucide-react';
import { LogVariable } from '@/lib/types/variable-palette';
import { cn } from '@/lib/utils';

interface SearchFilter {
  dataType?: string;
  categories?: string[];
  tags?: string[];
  excelColumnRange?: { start: string; end: string };
}

interface VariableSearchProps {
  variables: LogVariable[];
  onSearch: (results: LogVariable[]) => void;
  onFilterChange?: (filters: SearchFilter) => void;
  placeholder?: string;
  enableFilters?: boolean;
  enableHistory?: boolean;
  enableSuggestions?: boolean;
  enableRegex?: boolean;
  enableBooleanOperators?: boolean;
  enableFieldSearch?: boolean;
  enableWildcards?: boolean;
  highlightMatches?: boolean;
  className?: string;
}

export function VariableSearch({
  variables,
  onSearch,
  onFilterChange,
  placeholder = 'Search variables...',
  enableFilters = false,
  enableHistory = false,
  enableSuggestions = false,
  enableRegex = false,
  enableBooleanOperators = false,
  enableFieldSearch = false,
  enableWildcards = false,
  highlightMatches = false,
  className,
}: VariableSearchProps) {
  const [searchTerm, setSearchTerm] = useState('');
  const [debouncedSearchTerm, setDebouncedSearchTerm] = useState('');
  const [filters, setFilters] = useState<SearchFilter>({});
  const [searchHistory, setSearchHistory] = useState<string[]>([]);
  const [showHistory, setShowHistory] = useState(false);
  const [showSuggestions, setShowSuggestions] = useState(false);
  const [selectedSuggestionIndex, setSelectedSuggestionIndex] = useState(-1);
  const searchInputRef = useRef<HTMLInputElement>(null);
  const debounceTimer = useRef<NodeJS.Timeout>();

  useEffect(() => {
    const storedHistory = localStorage.getItem('variableSearch.history');
    if (storedHistory) {
      setSearchHistory(JSON.parse(storedHistory));
    }
  }, []);

  useEffect(() => {
    if (debounceTimer.current) {
      clearTimeout(debounceTimer.current);
    }

    debounceTimer.current = setTimeout(() => {
      setDebouncedSearchTerm(searchTerm);
    }, 300);

    return () => {
      if (debounceTimer.current) {
        clearTimeout(debounceTimer.current);
      }
    };
  }, [searchTerm]);

  useEffect(() => {
    performSearch(debouncedSearchTerm, filters);
  }, [debouncedSearchTerm, filters, variables]);

  const performSearch = useCallback((term: string, currentFilters: SearchFilter) => {
    let results = [...variables];

    if (term) {
      if (enableRegex && term.startsWith('/') && term.endsWith('/')) {
        try {
          const regex = new RegExp(term.slice(1, -1), 'i');
          results = results.filter(v => 
            regex.test(v.name) || 
            regex.test(v.description || '') ||
            regex.test(v.category)
          );
        } catch (e) {
          console.error('Invalid regex:', e);
        }
      } else if (enableBooleanOperators) {
        const processBoolean = (searchQuery: string) => {
          const parts = searchQuery.split(/\s+(AND|OR)\s+/i);
          if (parts.length === 3) {
            const [left, operator, right] = parts;
            const leftMatches = variables.filter(v => matchesSearch(v, left));
            const rightMatches = variables.filter(v => matchesSearch(v, right));
            
            if (operator.toUpperCase() === 'AND') {
              results = leftMatches.filter(v => rightMatches.includes(v));
            } else {
              results = [...new Set([...leftMatches, ...rightMatches])];
            }
          } else {
            results = results.filter(v => matchesSearch(v, term));
          }
        };
        processBoolean(term);
      } else if (enableFieldSearch && term.includes(':')) {
        const [field, value] = term.split(':');
        results = results.filter(v => {
          switch (field.toLowerCase()) {
            case 'category':
              return v.category.toLowerCase().includes(value.toLowerCase());
            case 'type':
            case 'datatype':
              return v.dataType.toLowerCase().includes(value.toLowerCase());
            case 'tag':
              return v.tags?.some(t => t.toLowerCase().includes(value.toLowerCase()));
            case 'column':
              return v.excelColumn?.toLowerCase() === value.toLowerCase();
            default:
              return matchesSearch(v, value);
          }
        });
      } else if (enableWildcards) {
        const wildcardToRegex = (pattern: string) => {
          const escaped = pattern.replace(/[.+^${}()|[\]\\]/g, '\\$&');
          const withWildcards = escaped
            .replace(/\*/g, '.*')
            .replace(/\?/g, '.');
          return new RegExp(`^${withWildcards}$`, 'i');
        };
        
        const regex = wildcardToRegex(term);
        results = results.filter(v => 
          regex.test(v.name) || 
          regex.test(v.description || '')
        );
      } else {
        results = performFuzzySearch(results, term);
      }
    }

    if (currentFilters.dataType && currentFilters.dataType !== 'all') {
      results = results.filter(v => v.dataType === currentFilters.dataType);
    }

    if (currentFilters.categories && currentFilters.categories.length > 0) {
      results = results.filter(v => currentFilters.categories!.includes(v.category));
    }

    if (currentFilters.tags && currentFilters.tags.length > 0) {
      results = results.filter(v => 
        v.tags?.some(tag => currentFilters.tags!.includes(tag))
      );
    }

    if (currentFilters.excelColumnRange) {
      const { start, end } = currentFilters.excelColumnRange;
      results = results.filter(v => {
        if (!v.excelColumn) return false;
        return v.excelColumn >= start && v.excelColumn <= end;
      });
    }

    onSearch(results);
  }, [variables, onSearch, enableRegex, enableBooleanOperators, enableFieldSearch, enableWildcards]);

  const matchesSearch = (variable: LogVariable, term: string): boolean => {
    const searchableText = [
      variable.name,
      variable.description,
      variable.category,
      ...(variable.tags || []),
    ].join(' ').toLowerCase();
    
    return searchableText.includes(term.toLowerCase());
  };

  const performFuzzySearch = (items: LogVariable[], term: string): LogVariable[] => {
    const termLower = term.toLowerCase();
    const scored = items.map(item => {
      let score = 0;
      const nameLower = item.name.toLowerCase();
      const descLower = (item.description || '').toLowerCase();
      
      if (nameLower === termLower) score += 100;
      else if (nameLower.startsWith(termLower)) score += 50;
      else if (nameLower.includes(termLower)) score += 25;
      
      if (descLower.includes(termLower)) score += 10;
      
      if (item.tags?.some(tag => tag.toLowerCase().includes(termLower))) score += 5;
      
      const words = termLower.split(' ');
      if (words.every(word => nameLower.includes(word))) score += 15;
      
      return { item, score };
    });
    
    return scored
      .filter(s => s.score > 0)
      .sort((a, b) => b.score - a.score)
      .map(s => s.item);
  };

  const handleSearchSubmit = (value: string) => {
    if (enableHistory && value) {
      const newHistory = [value, ...searchHistory.filter(h => h !== value)].slice(0, 10);
      setSearchHistory(newHistory);
      localStorage.setItem('variableSearch.history', JSON.stringify(newHistory));
    }
  };

  const handleFilterChange = (newFilters: SearchFilter) => {
    setFilters(newFilters);
    onFilterChange?.(newFilters);
  };

  const suggestions = useMemo(() => {
    if (!enableSuggestions || !searchTerm || searchTerm.length < 2) return [];
    
    return performFuzzySearch(variables, searchTerm).slice(0, 5);
  }, [enableSuggestions, searchTerm, variables]);

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (!enableSuggestions || !showSuggestions) return;

    if (e.key === 'ArrowDown') {
      e.preventDefault();
      setSelectedSuggestionIndex(prev => 
        prev < suggestions.length - 1 ? prev + 1 : 0
      );
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      setSelectedSuggestionIndex(prev => 
        prev > 0 ? prev - 1 : suggestions.length - 1
      );
    } else if (e.key === 'Enter' && selectedSuggestionIndex >= 0) {
      e.preventDefault();
      const selected = suggestions[selectedSuggestionIndex];
      if (selected) {
        setSearchTerm(selected.name);
        setShowSuggestions(false);
        handleSearchSubmit(selected.name);
      }
    } else if (e.key === 'Escape') {
      setShowSuggestions(false);
      setSelectedSuggestionIndex(-1);
    }
  };

  const HighlightedText = ({ text, highlight }: { text: string; highlight: string }) => {
    if (!highlightMatches || !highlight) return <>{text}</>;
    
    const parts = text.split(new RegExp(`(${highlight})`, 'gi'));
    return (
      <>
        {parts.map((part, i) => 
          part.toLowerCase() === highlight.toLowerCase() ? (
            <mark key={i} className="bg-yellow-200">{part}</mark>
          ) : (
            <span key={i}>{part}</span>
          )
        )}
      </>
    );
  };

  return (
    <div className={cn("space-y-3", className)}>
      <div className="relative">
        <Search className="absolute left-2 top-2.5 h-4 w-4 text-muted-foreground" />
        <Input
          ref={searchInputRef}
          placeholder={placeholder}
          value={searchTerm}
          onChange={(e) => {
            setSearchTerm(e.target.value);
            if (enableSuggestions) setShowSuggestions(true);
          }}
          onKeyDown={handleKeyDown}
          onFocus={() => {
            if (enableHistory && !searchTerm) setShowHistory(true);
            if (enableSuggestions && searchTerm) setShowSuggestions(true);
          }}
          onBlur={() => {
            setTimeout(() => {
              setShowHistory(false);
              setShowSuggestions(false);
            }, 200);
          }}
          className="pl-8 pr-20"
          aria-label="Search variables"
          role="search"
        />
        
        <div className="absolute right-1 top-1 flex items-center gap-1">
          {searchTerm && (
            <Button
              size="icon"
              variant="ghost"
              className="h-7 w-7"
              onClick={() => setSearchTerm('')}
              aria-label="Clear search"
            >
              <X className="h-3 w-3" />
            </Button>
          )}
          
          {enableHistory && (
            <Button
              size="icon"
              variant="ghost"
              className="h-7 w-7"
              onClick={() => setShowHistory(!showHistory)}
              aria-label="Search history"
            >
              <Clock className="h-3 w-3" />
            </Button>
          )}
          
          {enableFilters && (
            <Popover>
              <PopoverTrigger asChild>
                <Button
                  size="icon"
                  variant="ghost"
                  className="h-7 w-7"
                  aria-label="Search filters"
                >
                  <Filter className="h-3 w-3" />
                </Button>
              </PopoverTrigger>
              <PopoverContent className="w-80">
                <div className="space-y-4">
                  <div>
                    <Label htmlFor="dataType">Data Type</Label>
                    <Select
                      value={filters.dataType || 'all'}
                      onValueChange={(value) => 
                        handleFilterChange({ ...filters, dataType: value })
                      }
                    >
                      <SelectTrigger id="dataType">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="all">All Types</SelectItem>
                        <SelectItem value="text">Text</SelectItem>
                        <SelectItem value="number">Number</SelectItem>
                        <SelectItem value="date">Date</SelectItem>
                        <SelectItem value="select">Select</SelectItem>
                        <SelectItem value="checkbox">Checkbox</SelectItem>
                        <SelectItem value="textarea">Textarea</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>

                  <div>
                    <Label>Categories</Label>
                    <Popover>
                      <PopoverTrigger asChild>
                        <Button
                          variant="outline"
                          className="w-full justify-between"
                          aria-label="Select categories"
                        >
                          {filters.categories?.length 
                            ? `${filters.categories.length} selected` 
                            : 'Select categories'}
                          <ChevronDown className="h-4 w-4 opacity-50" />
                        </Button>
                      </PopoverTrigger>
                      <PopoverContent className="w-80">
                        <div className="space-y-2">
                          {Array.from(new Set(variables.map(v => v.category))).map(category => (
                            <div key={category} className="flex items-center space-x-2">
                              <Checkbox
                                id={`cat-${category}`}
                                checked={filters.categories?.includes(category)}
                                onCheckedChange={(checked) => {
                                  const newCategories = checked
                                    ? [...(filters.categories || []), category]
                                    : filters.categories?.filter(c => c !== category) || [];
                                  handleFilterChange({ ...filters, categories: newCategories });
                                }}
                                aria-label={category}
                              />
                              <Label htmlFor={`cat-${category}`} className="text-sm">
                                {category}
                              </Label>
                            </div>
                          ))}
                        </div>
                      </PopoverContent>
                    </Popover>
                  </div>

                  <div>
                    <Label htmlFor="tags">Filter by Tags</Label>
                    <div className="flex flex-wrap gap-1 mt-2">
                      <Input
                        id="tags"
                        placeholder="Enter tag and press Enter"
                        onKeyDown={(e) => {
                          if (e.key === 'Enter') {
                            e.preventDefault();
                            const input = e.currentTarget;
                            const tag = input.value.trim();
                            if (tag) {
                              handleFilterChange({
                                ...filters,
                                tags: [...(filters.tags || []), tag],
                              });
                              input.value = '';
                            }
                          }
                        }}
                      />
                      <div className="flex flex-wrap gap-1 mt-2">
                        {filters.tags?.map(tag => (
                          <Badge key={tag} variant="secondary" className="text-xs">
                            {tag}
                            <button
                              onClick={() => 
                                handleFilterChange({
                                  ...filters,
                                  tags: filters.tags?.filter(t => t !== tag),
                                })
                              }
                              className="ml-1"
                            >
                              <X className="h-3 w-3" />
                            </button>
                          </Badge>
                        ))}
                      </div>
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-2">
                    <div>
                      <Label htmlFor="columnStart">Column Start</Label>
                      <Input
                        id="columnStart"
                        placeholder="A"
                        value={filters.excelColumnRange?.start || ''}
                        onChange={(e) => 
                          handleFilterChange({
                            ...filters,
                            excelColumnRange: {
                              start: e.target.value.toUpperCase(),
                              end: filters.excelColumnRange?.end || '',
                            },
                          })
                        }
                        maxLength={2}
                      />
                    </div>
                    <div>
                      <Label htmlFor="columnEnd">Column End</Label>
                      <Input
                        id="columnEnd"
                        placeholder="Z"
                        value={filters.excelColumnRange?.end || ''}
                        onChange={(e) => 
                          handleFilterChange({
                            ...filters,
                            excelColumnRange: {
                              start: filters.excelColumnRange?.start || '',
                              end: e.target.value.toUpperCase(),
                            },
                          })
                        }
                        maxLength={2}
                      />
                    </div>
                  </div>
                </div>
              </PopoverContent>
            </Popover>
          )}
        </div>

        {enableHistory && showHistory && searchHistory.length > 0 && (
          <div className="absolute top-full left-0 right-0 mt-1 bg-background border rounded-md shadow-lg z-50">
            <div className="p-2">
              <div className="text-xs text-muted-foreground mb-2">Recent searches</div>
              {searchHistory.map((item, index) => (
                <button
                  key={index}
                  className="w-full text-left px-2 py-1 hover:bg-muted rounded text-sm"
                  onClick={() => {
                    setSearchTerm(item);
                    setShowHistory(false);
                  }}
                  aria-label={item}
                >
                  <Clock className="inline h-3 w-3 mr-2 text-muted-foreground" />
                  {item}
                </button>
              ))}
            </div>
          </div>
        )}

        {enableSuggestions && showSuggestions && suggestions.length > 0 && (
          <div 
            className="absolute top-full left-0 right-0 mt-1 bg-background border rounded-md shadow-lg z-50"
            role="listbox"
          >
            <div className="p-2">
              {suggestions.map((variable, index) => (
                <div
                  key={variable.id}
                  className={cn(
                    "px-2 py-2 hover:bg-muted rounded cursor-pointer",
                    index === selectedSuggestionIndex && "bg-muted"
                  )}
                  onClick={() => {
                    setSearchTerm(variable.name);
                    setShowSuggestions(false);
                    handleSearchSubmit(variable.name);
                  }}
                  role="option"
                  aria-selected={index === selectedSuggestionIndex}
                >
                  <div className="font-medium text-sm">
                    {highlightMatches ? (
                      <HighlightedText text={variable.name} highlight={searchTerm} />
                    ) : (
                      variable.name
                    )}
                  </div>
                  {variable.description && (
                    <div className="text-xs text-muted-foreground line-clamp-1">
                      {highlightMatches ? (
                        <HighlightedText text={variable.description} highlight={searchTerm} />
                      ) : (
                        variable.description
                      )}
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>
        )}
      </div>

      {highlightMatches && searchTerm && (
        <div className="sr-only">
          Results are highlighted with the search term: {searchTerm}
        </div>
      )}
    </div>
  );
}