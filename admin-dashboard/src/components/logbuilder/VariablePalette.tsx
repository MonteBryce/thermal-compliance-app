'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip';
import {
  Search,
  X,
  Star,
  Plus,
  Edit,
  Trash2,
  GripVertical,
  Type,
  Hash,
  Calendar,
  List,
  CheckSquare,
  FileText,
  Clock,
  Filter,
  ChevronDown,
} from 'lucide-react';
import { useDraggable } from '@dnd-kit/core';
import { LogVariable, VariableFilter, DEFAULT_CATEGORIES } from '@/lib/types/variable-palette';
import { cn } from '@/lib/utils';
import { VariableCreateModal } from './VariableCreateModal';
import { VariableEditModal } from './VariableEditModal';

interface VariablePaletteProps {
  variables: LogVariable[];
  onAddVariable: (variable: LogVariable) => void;
  onToggleFavorite?: (variableId: string) => void;
  onCreateVariable?: (variable: Omit<LogVariable, 'id'>) => void;
  onEditVariable?: (variableId: string, updates: Partial<LogVariable>) => void;
  onDeleteVariable?: (variableId: string) => void;
  className?: string;
}

function DraggableVariableCard({ 
  variable, 
  isSelected,
  isFavorite,
  onAdd,
  onToggleFavorite,
  onEdit,
  onDelete 
}: {
  variable: LogVariable;
  isSelected: boolean;
  isFavorite: boolean;
  onAdd: () => void;
  onToggleFavorite: () => void;
  onEdit: () => void;
  onDelete: () => void;
}) {
  const { attributes, listeners, setNodeRef, transform, isDragging } = useDraggable({
    id: `variable-${variable.id}`,
    data: {
      type: 'variable',
      variable,
    },
  });

  const style = transform ? {
    transform: `translate3d(${transform.x}px, ${transform.y}px, 0)`,
    zIndex: isDragging ? 1000 : undefined,
    opacity: isDragging ? 0.5 : undefined,
  } : undefined;

  const getTypeIcon = (type: string) => {
    switch (type) {
      case 'text': return <Type className="h-3 w-3" />;
      case 'number': return <Hash className="h-3 w-3" />;
      case 'date': return <Calendar className="h-3 w-3" />;
      case 'select': return <List className="h-3 w-3" />;
      case 'checkbox': return <CheckSquare className="h-3 w-3" />;
      case 'textarea': return <FileText className="h-3 w-3" />;
      default: return <Type className="h-3 w-3" />;
    }
  };

  return (
    <div
      ref={setNodeRef}
      style={style}
      {...listeners}
      {...attributes}
      data-testid="variable-card"
      className={cn(
        "p-3 border rounded-lg cursor-grab transition-all duration-200",
        isDragging && "shadow-lg border-primary cursor-grabbing",
        isSelected && "border-primary bg-primary/5",
        !isDragging && !isSelected && "border-border hover:border-primary/50 hover:bg-muted/50"
      )}
      draggable
      tabIndex={0}
      onKeyDown={(e) => {
        if (e.key === 'Enter') onAdd();
        if (e.key === 'f' || e.key === 'F') onToggleFavorite();
      }}
    >
      <div className="flex items-start gap-2">
        <GripVertical className="h-4 w-4 text-muted-foreground mt-0.5 flex-shrink-0" />
        <div className="flex-1 min-w-0">
          <div className="flex items-center justify-between gap-2 mb-1">
            <div className="flex items-center gap-2 flex-1 min-w-0">
              {getTypeIcon(variable.dataType)}
              <span data-testid="variable-name" className="font-medium text-sm truncate">
                {variable.name}
              </span>
            </div>
            <div className="flex items-center gap-1">
              <TooltipProvider>
                <Tooltip>
                  <TooltipTrigger asChild>
                    <Button
                      size="icon"
                      variant="ghost"
                      className="h-6 w-6"
                      onClick={(e) => {
                        e.stopPropagation();
                        onToggleFavorite();
                      }}
                      aria-label="Toggle favorite"
                    >
                      <Star className={cn("h-3 w-3", isFavorite && "fill-yellow-500 text-yellow-500")} />
                    </Button>
                  </TooltipTrigger>
                  <TooltipContent>
                    {isFavorite ? 'Remove from favorites' : 'Add to favorites'}
                  </TooltipContent>
                </Tooltip>
              </TooltipProvider>
            </div>
          </div>
          <div className="text-xs text-muted-foreground space-y-1">
            <div className="flex flex-wrap gap-1">
              <Badge variant="secondary" className="text-xs">
                {variable.category}
              </Badge>
              <Badge variant="outline" className="text-xs">
                {variable.dataType}
              </Badge>
              {variable.excelColumn && (
                <Badge variant="outline" className="text-xs">
                  Column {variable.excelColumn}
                </Badge>
              )}
            </div>
            {variable.description && (
              <div className="text-xs line-clamp-1">{variable.description}</div>
            )}
            {variable.tags && variable.tags.length > 0 && (
              <div className="flex flex-wrap gap-1">
                {variable.tags.slice(0, 3).map(tag => (
                  <span key={tag} className="text-xs text-muted-foreground">
                    #{tag}
                  </span>
                ))}
                {variable.tags.length > 3 && (
                  <span className="text-xs text-muted-foreground">
                    +{variable.tags.length - 3}
                  </span>
                )}
              </div>
            )}
          </div>
          <div className="flex items-center gap-1 mt-2">
            <Button
              size="sm"
              variant="outline"
              className="h-7 text-xs flex-1"
              onClick={(e) => {
                e.stopPropagation();
                onAdd();
              }}
              aria-label="Add variable"
            >
              <Plus className="h-3 w-3 mr-1" />
              Add
            </Button>
            <Button
              size="icon"
              variant="ghost"
              className="h-7 w-7"
              onClick={(e) => {
                e.stopPropagation();
                onEdit();
              }}
              aria-label="Edit variable"
            >
              <Edit className="h-3 w-3" />
            </Button>
            <Button
              size="icon"
              variant="ghost"
              className="h-7 w-7"
              onClick={(e) => {
                e.stopPropagation();
                onDelete();
              }}
              aria-label="Delete variable"
            >
              <Trash2 className="h-3 w-3" />
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
}

export function VariablePalette({
  variables,
  onAddVariable,
  onToggleFavorite,
  onCreateVariable,
  onEditVariable,
  onDeleteVariable,
  className,
}: VariablePaletteProps) {
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [activeTab, setActiveTab] = useState<'all' | 'favorites' | 'recent'>('all');
  const [favorites, setFavorites] = useState<string[]>([]);
  const [recentlyUsed, setRecentlyUsed] = useState<string[]>([]);
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [editingVariable, setEditingVariable] = useState<LogVariable | null>(null);
  const [selectedVariables, setSelectedVariables] = useState<string[]>([]);

  useEffect(() => {
    const storedFavorites = localStorage.getItem('variablePalette.favorites');
    const storedRecent = localStorage.getItem('variablePalette.recent');
    
    if (storedFavorites) {
      setFavorites(JSON.parse(storedFavorites));
    }
    if (storedRecent) {
      setRecentlyUsed(JSON.parse(storedRecent));
    }
  }, []);

  const handleToggleFavorite = useCallback((variableId: string) => {
    setFavorites(prev => {
      const newFavorites = prev.includes(variableId)
        ? prev.filter(id => id !== variableId)
        : [...prev, variableId];
      
      localStorage.setItem('variablePalette.favorites', JSON.stringify(newFavorites));
      return newFavorites;
    });
    
    onToggleFavorite?.(variableId);
  }, [onToggleFavorite]);

  const handleAddVariable = useCallback((variable: LogVariable) => {
    setRecentlyUsed(prev => {
      const newRecent = [variable.id, ...prev.filter(id => id !== variable.id)].slice(0, 10);
      localStorage.setItem('variablePalette.recent', JSON.stringify(newRecent));
      return newRecent;
    });
    
    onAddVariable(variable);
  }, [onAddVariable]);

  const handleCreateVariable = useCallback((variableData: Omit<LogVariable, 'id'>) => {
    onCreateVariable?.(variableData);
    setIsCreateModalOpen(false);
  }, [onCreateVariable]);

  const handleEditVariable = useCallback((variable: LogVariable) => {
    setEditingVariable(variable);
    setIsEditModalOpen(true);
  }, []);

  const handleSaveEdit = useCallback((variableId: string, updates: Partial<LogVariable>) => {
    onEditVariable?.(variableId, updates);
    setIsEditModalOpen(false);
    setEditingVariable(null);
  }, [onEditVariable]);

  const handleDeleteVariable = useCallback((variableId: string) => {
    if (confirm('Are you sure you want to delete this variable?')) {
      onDeleteVariable?.(variableId);
    }
  }, [onDeleteVariable]);

  const filteredVariables = useMemo(() => {
    let filtered = [...variables];

    if (searchTerm) {
      const term = searchTerm.toLowerCase();
      filtered = filtered.filter(variable => {
        const searchableText = [
          variable.name,
          variable.description,
          variable.category,
          ...(variable.tags || []),
        ].join(' ').toLowerCase();
        
        return searchableText.includes(term);
      });
    }

    if (selectedCategory !== 'all') {
      filtered = filtered.filter(v => v.category === selectedCategory);
    }

    if (activeTab === 'favorites') {
      filtered = filtered.filter(v => favorites.includes(v.id));
    } else if (activeTab === 'recent') {
      const recentVariables = recentlyUsed
        .map(id => filtered.find(v => v.id === id))
        .filter(Boolean) as LogVariable[];
      
      filtered = recentVariables;
    }

    return filtered;
  }, [variables, searchTerm, selectedCategory, activeTab, favorites, recentlyUsed]);

  const categories = useMemo(() => {
    const uniqueCategories = new Set(variables.map(v => v.category));
    return ['all', ...Array.from(uniqueCategories)];
  }, [variables]);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.key === 'n') {
        e.preventDefault();
        setIsCreateModalOpen(true);
      }
      if ((e.ctrlKey || e.metaKey) && e.key === 'f') {
        e.preventDefault();
        document.getElementById('variable-search')?.focus();
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);

  return (
    <>
      <Card className={cn("w-80 h-full", className)}>
        <CardHeader className="pb-3">
          <div className="flex items-center justify-between">
            <CardTitle className="text-lg">Variables</CardTitle>
            <Button
              size="sm"
              onClick={() => setIsCreateModalOpen(true)}
              aria-label="Create new variable"
            >
              <Plus className="h-4 w-4 mr-1" />
              Create Variable
            </Button>
          </div>
        </CardHeader>
        <CardContent className="p-4 pt-0">
          <div className="space-y-4">
            <div className="relative">
              <Search className="absolute left-2 top-2.5 h-4 w-4 text-muted-foreground" />
              <Input
                id="variable-search"
                placeholder="Search variables..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-8 pr-8"
                aria-label="Search variables"
                role="search"
              />
              {searchTerm && (
                <Button
                  size="icon"
                  variant="ghost"
                  className="absolute right-1 top-1 h-7 w-7"
                  onClick={() => setSearchTerm('')}
                  aria-label="Clear search"
                >
                  <X className="h-3 w-3" />
                </Button>
              )}
            </div>

            <Select
              value={selectedCategory}
              onValueChange={setSelectedCategory}
              aria-label="Category filter"
            >
              <SelectTrigger className="w-full">
                <SelectValue>
                  {selectedCategory === 'all' ? 'All Categories' : selectedCategory}
                </SelectValue>
              </SelectTrigger>
              <SelectContent>
                {categories.map(category => (
                  <SelectItem key={category} value={category}>
                    {category === 'all' ? 'All Categories' : category}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>

            <Tabs value={activeTab} onValueChange={(v) => setActiveTab(v as any)}>
              <TabsList className="grid w-full grid-cols-3">
                <TabsTrigger value="all">All</TabsTrigger>
                <TabsTrigger value="favorites" aria-label="Favorites">
                  <Star className="h-3 w-3 mr-1" />
                  Favorites
                </TabsTrigger>
                <TabsTrigger value="recent" aria-label="Recent">
                  <Clock className="h-3 w-3 mr-1" />
                  Recent
                </TabsTrigger>
              </TabsList>

              <TabsContent value={activeTab} className="mt-4">
                <ScrollArea className="h-[calc(100vh-320px)]">
                  <a href="#variable-list" className="sr-only">Skip to variables</a>
                  <div id="variable-list" className="space-y-2 pr-3">
                    {filteredVariables.length === 0 ? (
                      <div className="text-center py-8 text-muted-foreground">
                        {searchTerm || selectedCategory !== 'all' ? (
                          <>
                            <p>No variables found</p>
                            <p className="text-xs mt-1">Try adjusting your search or filters</p>
                          </>
                        ) : activeTab === 'favorites' ? (
                          <>
                            <p>No favorite variables</p>
                            <p className="text-xs mt-1">Star variables to add them to favorites</p>
                          </>
                        ) : activeTab === 'recent' ? (
                          <>
                            <p>No recently used variables</p>
                            <p className="text-xs mt-1">Add variables to see them here</p>
                          </>
                        ) : (
                          <>
                            <p>No variables available</p>
                            <p className="text-xs mt-1">Create your first variable to get started</p>
                          </>
                        )}
                      </div>
                    ) : (
                      filteredVariables.map(variable => (
                        <DraggableVariableCard
                          key={variable.id}
                          variable={variable}
                          isSelected={selectedVariables.includes(variable.id)}
                          isFavorite={favorites.includes(variable.id)}
                          onAdd={() => handleAddVariable(variable)}
                          onToggleFavorite={() => handleToggleFavorite(variable.id)}
                          onEdit={() => handleEditVariable(variable)}
                          onDelete={() => handleDeleteVariable(variable.id)}
                        />
                      ))
                    )}
                  </div>
                  <div role="status" aria-live="polite" aria-atomic="true" className="sr-only">
                    {filteredVariables.length} variable{filteredVariables.length !== 1 ? 's' : ''} found
                  </div>
                </ScrollArea>
              </TabsContent>
            </Tabs>
          </div>
        </CardContent>
      </Card>

      {isCreateModalOpen && (
        <VariableCreateModal
          isOpen={isCreateModalOpen}
          onClose={() => setIsCreateModalOpen(false)}
          onCreate={handleCreateVariable}
          categories={DEFAULT_CATEGORIES}
        />
      )}

      {isEditModalOpen && editingVariable && (
        <VariableEditModal
          isOpen={isEditModalOpen}
          variable={editingVariable}
          onClose={() => {
            setIsEditModalOpen(false);
            setEditingVariable(null);
          }}
          onSave={(updates) => handleSaveEdit(editingVariable.id, updates)}
          categories={DEFAULT_CATEGORIES}
        />
      )}
    </>
  );
}