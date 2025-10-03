'use client';

import { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { ScrollArea } from '@/components/ui/scroll-area';
import {
  Search,
  Type,
  Hash,
  List,
  CheckSquare,
  Plus,
  GripVertical,
} from 'lucide-react';
import { useDraggable } from '@dnd-kit/core';
import { VariableCatalog, LogFieldType, LogField } from '@/lib/types/logbuilder';
import { TemplateService } from '@/lib/firestore/templates';

interface PaletteProps {
  onFieldSelect?: (field: LogField) => void;
}

/**
 * Draggable field item from variables catalog
 */
function DraggableVariable({ variable }: { variable: VariableCatalog }) {
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
    opacity: isDragging ? 0.8 : undefined,
  } : undefined;

  const getTypeIcon = (type: LogFieldType) => {
    switch (type) {
      case 'text': return <Type className="h-3 w-3" />;
      case 'number': return <Hash className="h-3 w-3" />;
      case 'select': return <List className="h-3 w-3" />;
      case 'checkbox': return <CheckSquare className="h-3 w-3" />;
      default: return <Type className="h-3 w-3" />;
    }
  };

  return (
    <div
      ref={setNodeRef}
      style={style}
      {...listeners}
      {...attributes}
      className={`p-3 border rounded-lg cursor-grab hover:bg-muted/50 transition-colors ${
        isDragging ? 'shadow-lg border-primary' : 'border-border'
      }`}
    >
      <div className="flex items-start gap-2">
        <GripVertical className="h-4 w-4 text-muted-foreground mt-0.5" />
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-1">
            {getTypeIcon(variable.type)}
            <span className="font-medium text-sm truncate">{variable.label}</span>
          </div>
          <div className="text-xs text-muted-foreground space-y-1">
            <div className="font-mono bg-muted px-1 rounded">{variable.key}</div>
            {variable.unit && (
              <Badge variant="outline" className="text-xs">
                {variable.unit}
              </Badge>
            )}
            {variable.category && (
              <Badge variant="secondary" className="text-xs">
                {variable.category}
              </Badge>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

/**
 * Draggable basic control
 */
function DraggableControl({ 
  type, 
  label, 
  icon 
}: { 
  type: LogFieldType; 
  label: string; 
  icon: React.ReactNode;
}) {
  const { attributes, listeners, setNodeRef, transform, isDragging } = useDraggable({
    id: `control-${type}`,
    data: {
      type: 'control',
      fieldType: type,
    },
  });

  const style = transform ? {
    transform: `translate3d(${transform.x}px, ${transform.y}px, 0)`,
    zIndex: isDragging ? 1000 : undefined,
    opacity: isDragging ? 0.8 : undefined,
  } : undefined;

  return (
    <div
      ref={setNodeRef}
      style={style}
      {...listeners}
      {...attributes}
      className={`p-3 border rounded-lg cursor-grab hover:bg-muted/50 transition-colors ${
        isDragging ? 'shadow-lg border-primary' : 'border-border'
      }`}
    >
      <div className="flex items-center gap-2">
        <GripVertical className="h-4 w-4 text-muted-foreground" />
        {icon}
        <span className="font-medium text-sm">{label}</span>
      </div>
    </div>
  );
}

export function Palette({ onFieldSelect }: PaletteProps) {
  const [variables, setVariables] = useState<VariableCatalog[]>([]);
  const [filteredVariables, setFilteredVariables] = useState<VariableCatalog[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [loading, setLoading] = useState(true);

  const templateService = new TemplateService();

  useEffect(() => {
    loadVariables();
  }, []);

  useEffect(() => {
    filterVariables();
  }, [variables, searchTerm, selectedCategory]);

  const loadVariables = async () => {
    try {
      setLoading(true);
      const variablesData = await templateService.getVariablesCatalog();
      setVariables(variablesData);
    } catch (error) {
      console.error('Error loading variables:', error);
    } finally {
      setLoading(false);
    }
  };

  const filterVariables = () => {
    let filtered = variables;

    // Filter by search term
    if (searchTerm) {
      const term = searchTerm.toLowerCase();
      filtered = filtered.filter(
        variable =>
          variable.label.toLowerCase().includes(term) ||
          variable.key.toLowerCase().includes(term) ||
          variable.category?.toLowerCase().includes(term)
      );
    }

    // Filter by category
    if (selectedCategory !== 'all') {
      filtered = filtered.filter(variable => variable.category === selectedCategory);
    }

    setFilteredVariables(filtered);
  };

  const categories = ['all', ...new Set(variables.map(v => v.category).filter(Boolean))];

  const basicControls = [
    { type: 'text' as LogFieldType, label: 'Text Field', icon: <Type className="h-4 w-4" /> },
    { type: 'number' as LogFieldType, label: 'Number Field', icon: <Hash className="h-4 w-4" /> },
    { type: 'select' as LogFieldType, label: 'Select Dropdown', icon: <List className="h-4 w-4" /> },
    { type: 'checkbox' as LogFieldType, label: 'Checkbox', icon: <CheckSquare className="h-4 w-4" /> },
  ];

  return (
    <Card className="w-80 h-full">
      <CardHeader>
        <CardTitle className="text-lg">Field Palette</CardTitle>
      </CardHeader>
      <CardContent className="p-0">
        <Tabs defaultValue="variables" className="h-full">
          <TabsList className="grid w-full grid-cols-2 mx-4">
            <TabsTrigger value="variables">Variables</TabsTrigger>
            <TabsTrigger value="controls">Controls</TabsTrigger>
          </TabsList>

          <TabsContent value="variables" className="mt-4 px-4 h-full">
            <div className="space-y-4">
              {/* Search */}
              <div className="relative">
                <Search className="absolute left-2 top-2.5 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder="Search variables..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-8"
                />
              </div>

              {/* Category Filter */}
              <div className="flex flex-wrap gap-1">
                {categories.map(category => (
                  <Button
                    key={category}
                    variant={selectedCategory === category ? 'default' : 'outline'}
                    size="sm"
                    onClick={() => setSelectedCategory(category)}
                    className="text-xs h-7"
                  >
                    {category === 'all' ? 'All' : category}
                  </Button>
                ))}
              </div>

              {/* Variables List */}
              <ScrollArea className="h-[calc(100vh-300px)]">
                <div className="space-y-2 pr-4">
                  {loading ? (
                    <div className="text-center py-8 text-muted-foreground">
                      Loading variables...
                    </div>
                  ) : filteredVariables.length === 0 ? (
                    <div className="text-center py-8 text-muted-foreground">
                      {searchTerm || selectedCategory !== 'all' 
                        ? 'No variables match your filter'
                        : 'No variables available'
                      }
                    </div>
                  ) : (
                    filteredVariables.map(variable => (
                      <DraggableVariable key={variable.id} variable={variable} />
                    ))
                  )}
                </div>
              </ScrollArea>

              {/* Add Variable Button */}
              <Button
                variant="outline"
                size="sm"
                className="w-full"
                onClick={() => {
                  // Open modal to create new variable
                  console.log('Create new variable');
                }}
              >
                <Plus className="h-4 w-4 mr-2" />
                Add Variable
              </Button>
            </div>
          </TabsContent>

          <TabsContent value="controls" className="mt-4 px-4">
            <div className="space-y-4">
              <div className="text-sm text-muted-foreground">
                Drag these basic controls to create new fields
              </div>
              
              <ScrollArea className="h-[calc(100vh-300px)]">
                <div className="space-y-2 pr-4">
                  {basicControls.map(control => (
                    <DraggableControl
                      key={control.type}
                      type={control.type}
                      label={control.label}
                      icon={control.icon}
                    />
                  ))}
                </div>
              </ScrollArea>

              <div className="text-xs text-muted-foreground p-2 bg-muted/50 rounded">
                <strong>Tip:</strong> Use Variables tab for pre-configured fields with validation rules. 
                Use Controls tab to create custom fields from scratch.
              </div>
            </div>
          </TabsContent>
        </Tabs>
      </CardContent>
    </Card>
  );
}