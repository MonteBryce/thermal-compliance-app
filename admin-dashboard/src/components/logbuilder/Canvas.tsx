'use client';

import { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import {
  Plus,
  Trash2,
  GripVertical,
  MoreVertical,
  Copy,
  Move,
  Settings,
} from 'lucide-react';
import { useDroppable, useDraggable } from '@dnd-kit/core';
import { useSortable } from '@dnd-kit/sortable';
import { SortableContext, verticalListSortingStrategy, arrayMove } from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import { LogSchema, LogSection, LogLayoutRow, LogField } from '@/lib/types/logbuilder';

interface CanvasProps {
  schema: LogSchema;
  onSchemaChange: (schema: LogSchema) => void;
  onFieldSelect?: (field: LogField, event?: React.MouseEvent) => void;
  selectedFieldId?: string;
  selectedFieldIds?: string[];
  onClearSelection?: () => void;
  onCopyFields?: () => void;
  onPasteFields?: () => void;
  onDuplicateFields?: () => void;
  onBulkDelete?: () => void;
  clipboardCount?: number;
}

/**
 * Draggable and sortable field component
 */
function SortableField({ 
  field, 
  columnWidth = 6, 
  isSelected = false,
  isMultiSelected = false,
  onSelect,
  onRemove 
}: {
  field: LogField;
  columnWidth?: number;
  isSelected?: boolean;
  isMultiSelected?: boolean;
  onSelect?: (event?: React.MouseEvent) => void;
  onRemove?: () => void;
}) {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging,
  } = useSortable({ 
    id: field.id,
    data: {
      type: 'field',
      field: field
    }
  });

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
    opacity: isDragging ? 0.3 : 1,
    zIndex: isDragging ? 1000 : 'auto',
  };

  const getFieldTypeIcon = () => {
    switch (field.type) {
      case 'text': return '📝';
      case 'number': return '🔢';
      case 'select': return '📋';
      case 'checkbox': return '☑️';
      default: return '📄';
    }
  };

  return (
    <div
      ref={setNodeRef}
      style={style}
      className={`col-span-${columnWidth} min-h-[80px]`}
      onClick={(e) => onSelect?.(e)}
    >
      <div
        className={`p-3 border rounded-lg transition-all duration-200 cursor-pointer ${
          isSelected 
            ? 'border-primary bg-primary/5 shadow-lg shadow-primary/20 ring-1 ring-primary/30' 
            : isMultiSelected
            ? 'border-orange-400 bg-orange-50 shadow-md shadow-orange-400/20 ring-1 ring-orange-400/30'
            : 'border-border hover:border-primary/50 hover:bg-muted/50 hover:shadow-md hover:shadow-primary/10'
        } ${isDragging ? 'ring-2 ring-primary/50 shadow-xl' : ''}`}
      >
        <div className="flex items-start justify-between mb-2">
          <div className="flex items-center gap-2">
            <div
              {...attributes}
              {...listeners}
              className="cursor-grab hover:text-primary"
            >
              <GripVertical className="h-4 w-4" />
            </div>
            <span className="text-lg">{getFieldTypeIcon()}</span>
            <div className="flex-1 min-w-0">
              <div className="font-medium text-sm truncate">{field.label}</div>
              <div className="text-xs text-muted-foreground font-mono">{field.key}</div>
            </div>
          </div>
          
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" size="sm" className="h-6 w-6 p-0">
                <MoreVertical className="h-3 w-3" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
              <DropdownMenuItem onClick={onSelect}>
                <Settings className="h-4 w-4 mr-2" />
                Edit
              </DropdownMenuItem>
              <DropdownMenuItem>
                <Copy className="h-4 w-4 mr-2" />
                Duplicate
              </DropdownMenuItem>
              <DropdownMenuItem>
                <Move className="h-4 w-4 mr-2" />
                Move to Section
              </DropdownMenuItem>
              <DropdownMenuItem 
                className="text-destructive"
                onClick={(e) => {
                  e.stopPropagation();
                  onRemove?.();
                }}
              >
                <Trash2 className="h-4 w-4 mr-2" />
                Remove
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        </div>

        <div className="space-y-1">
          {field.unit && (
            <Badge variant="secondary" className="text-xs">
              {field.unit}
            </Badge>
          )}
          {field.required && (
            <Badge variant="destructive" className="text-xs">
              Required
            </Badge>
          )}
          {field.visibility?.defaultHidden && (
            <Badge variant="outline" className="text-xs">
              Hidden
            </Badge>
          )}
        </div>
      </div>
    </div>
  );
}

/**
 * Droppable row component
 */
function DropRow({ 
  row, 
  sectionId, 
  rowIndex, 
  fields, 
  selectedFieldId,
  selectedFieldIds = [],
  onFieldSelect,
  onRowUpdate,
  onRowRemove,
  onFieldRemove 
}: {
  row: LogLayoutRow;
  sectionId: string;
  rowIndex: number;
  fields: LogField[];
  selectedFieldId?: string;
  selectedFieldIds?: string[];
  onFieldSelect?: (field: LogField, event?: React.MouseEvent) => void;
  onRowUpdate: (rowIndex: number, row: LogLayoutRow) => void;
  onRowRemove: (rowIndex: number) => void;
  onFieldRemove: (fieldId: string) => void;
}) {
  const { isOver, setNodeRef } = useDroppable({
    id: `row-${sectionId}-${rowIndex}`,
    data: {
      type: 'row',
      sectionId,
      rowIndex,
    },
  });

  const fieldsInRow = row.columns.map(col => {
    const field = fields.find(f => f.id === col.fieldId);
    return { field, width: col.width || 6 };
  }).filter(item => item.field);

  return (
    <div
      ref={setNodeRef}
      className={`min-h-[100px] p-2 border-2 border-dashed rounded-lg transition-all duration-200 ${
        isOver 
          ? 'border-primary bg-primary/10 shadow-lg transform scale-[1.02]' 
          : 'border-muted-foreground/25 hover:border-muted-foreground/50 hover:bg-muted/25'
      }`}
    >
      <div className="flex items-center justify-between mb-2">
        <span className="text-xs text-muted-foreground">Row {rowIndex + 1}</span>
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="ghost" size="sm" className="h-6 w-6 p-0">
              <MoreVertical className="h-3 w-3" />
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end">
            <DropdownMenuItem>
              <Plus className="h-4 w-4 mr-2" />
              Add Column
            </DropdownMenuItem>
            <DropdownMenuItem 
              className="text-destructive"
              onClick={() => onRowRemove(rowIndex)}
            >
              <Trash2 className="h-4 w-4 mr-2" />
              Delete Row
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>

      {fieldsInRow.length > 0 ? (
        <div className="grid grid-cols-12 gap-2">
          <SortableContext items={fieldsInRow.map(item => item.field!.id)}>
            {fieldsInRow.map(({ field, width }) => (
              <SortableField
                key={field!.id}
                field={field!}
                columnWidth={width}
                isSelected={selectedFieldId === field!.id}
                isMultiSelected={selectedFieldIds.includes(field!.id)}
                onSelect={(e) => onFieldSelect?.(field!, e)}
                onRemove={() => onFieldRemove(field!.id)}
              />
            ))}
          </SortableContext>
        </div>
      ) : (
        <div className={`flex items-center justify-center h-16 text-muted-foreground text-sm transition-all ${
          isOver 
            ? 'text-primary font-medium' 
            : 'group-hover:text-foreground'
        }`}>
          {isOver ? (
            <div className="flex items-center gap-2">
              <div className="w-2 h-2 bg-primary rounded-full animate-pulse"></div>
              <span>Drop fields here</span>
              <div className="w-2 h-2 bg-primary rounded-full animate-pulse"></div>
            </div>
          ) : (
            'Drop fields here'
          )}
        </div>
      )}
    </div>
  );
}

/**
 * Sortable Section component with rows
 */
function SortableSection({ 
  section, 
  fields, 
  selectedFieldId,
  selectedFieldIds = [],
  onFieldSelect,
  onSectionUpdate,
  onSectionRemove,
  onSectionDuplicate,
  onFieldRemove 
}: {
  section: LogSection;
  fields: LogField[];
  selectedFieldId?: string;
  selectedFieldIds?: string[];
  onFieldSelect?: (field: LogField, event?: React.MouseEvent) => void;
  onSectionUpdate: (section: LogSection) => void;
  onSectionRemove: () => void;
  onSectionDuplicate?: () => void;
  onFieldRemove: (fieldId: string) => void;
}) {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging,
  } = useSortable({ 
    id: section.id,
    data: {
      type: 'section',
      section: section
    }
  });

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
    opacity: isDragging ? 0.5 : 1,
  };
  const [editingTitle, setEditingTitle] = useState(false);
  const [titleValue, setTitleValue] = useState(section.title || '');

  const handleTitleSave = () => {
    onSectionUpdate({
      ...section,
      title: titleValue,
    });
    setEditingTitle(false);
  };

  const handleAddRow = () => {
    onSectionUpdate({
      ...section,
      rows: [
        ...section.rows,
        {
          id: `row-${Date.now()}`,
          columns: [],
        },
      ],
    });
  };

  const handleRowUpdate = (rowIndex: number, updatedRow: LogLayoutRow) => {
    const newRows = [...section.rows];
    newRows[rowIndex] = updatedRow;
    onSectionUpdate({
      ...section,
      rows: newRows,
    });
  };

  const handleRowRemove = (rowIndex: number) => {
    onSectionUpdate({
      ...section,
      rows: section.rows.filter((_, index) => index !== rowIndex),
    });
  };

  return (
    <Card 
      ref={setNodeRef} 
      style={style} 
      className={`mb-4 ${isDragging ? 'shadow-xl ring-2 ring-primary/50' : ''}`}
    >
      <CardHeader className="pb-3">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div
              {...attributes}
              {...listeners}
              className="cursor-grab hover:text-primary p-1 rounded hover:bg-muted"
              title="Drag to reorder section"
            >
              <GripVertical className="h-4 w-4" />
            </div>
            {editingTitle ? (
              <Input
                value={titleValue}
                onChange={(e) => setTitleValue(e.target.value)}
                onBlur={handleTitleSave}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') handleTitleSave();
                  if (e.key === 'Escape') {
                    setTitleValue(section.title || '');
                    setEditingTitle(false);
                  }
                }}
                className="text-lg font-semibold"
                autoFocus
              />
            ) : (
              <CardTitle 
                className="cursor-pointer hover:text-primary"
                onClick={() => setEditingTitle(true)}
              >
                {section.title || 'Untitled Section'}
              </CardTitle>
            )}
          </div>
          
          <div className="flex items-center gap-2">
            <Button variant="outline" size="sm" onClick={handleAddRow}>
              <Plus className="h-4 w-4 mr-2" />
              Add Row
            </Button>
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button variant="ghost" size="sm">
                  <MoreVertical className="h-4 w-4" />
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end">
                <DropdownMenuItem onClick={() => setEditingTitle(true)}>
                  <Settings className="h-4 w-4 mr-2" />
                  Rename Section
                </DropdownMenuItem>
                <DropdownMenuItem onClick={onSectionDuplicate}>
                  <Copy className="h-4 w-4 mr-2" />
                  Duplicate Section
                </DropdownMenuItem>
                <DropdownMenuItem 
                  className="text-destructive"
                  onClick={onSectionRemove}
                >
                  <Trash2 className="h-4 w-4 mr-2" />
                  Delete Section
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </div>
        </div>
      </CardHeader>
      <CardContent>
        <div className="space-y-3">
          {section.rows.map((row, rowIndex) => (
            <DropRow
              key={row.id}
              row={row}
              sectionId={section.id}
              rowIndex={rowIndex}
              fields={fields}
              selectedFieldId={selectedFieldId}
              selectedFieldIds={selectedFieldIds}
              onFieldSelect={onFieldSelect}
              onRowUpdate={handleRowUpdate}
              onRowRemove={handleRowRemove}
              onFieldRemove={onFieldRemove}
            />
          ))}
          
          {section.rows.length === 0 && (
            <div className="text-center py-8 text-muted-foreground">
              <div className="mb-2">This section is empty</div>
              <Button variant="outline" size="sm" onClick={handleAddRow}>
                <Plus className="h-4 w-4 mr-2" />
                Add First Row
              </Button>
            </div>
          )}
        </div>
      </CardContent>
    </Card>
  );
}

export function Canvas({ 
  schema, 
  onSchemaChange, 
  onFieldSelect, 
  selectedFieldId,
  selectedFieldIds = [],
  onClearSelection,
  onCopyFields,
  onPasteFields,
  onDuplicateFields,
  onBulkDelete,
  clipboardCount = 0
}: CanvasProps) {
  const handleAddSection = () => {
    const newSection: LogSection = {
      id: `section-${Date.now()}`,
      title: `Section ${schema.layout.length + 1}`,
      rows: [],
    };

    onSchemaChange({
      ...schema,
      layout: [...schema.layout, newSection],
    });
  };

  const handleSectionUpdate = (sectionIndex: number, updatedSection: LogSection) => {
    const newLayout = [...schema.layout];
    newLayout[sectionIndex] = updatedSection;
    onSchemaChange({
      ...schema,
      layout: newLayout,
    });
  };

  const handleSectionRemove = (sectionIndex: number) => {
    onSchemaChange({
      ...schema,
      layout: schema.layout.filter((_, index) => index !== sectionIndex),
    });
  };

  const handleSectionDuplicate = (sectionIndex: number) => {
    const sectionToDuplicate = schema.layout[sectionIndex];
    
    // Get all field IDs used in this section
    const fieldsToClone: string[] = [];
    sectionToDuplicate.rows.forEach(row => {
      row.columns.forEach(col => {
        fieldsToClone.push(col.fieldId);
      });
    });

    // Clone the fields with new IDs
    const fieldIdMap: { [oldId: string]: string } = {};
    const clonedFields = fieldsToClone.map(fieldId => {
      const originalField = schema.fields.find(f => f.id === fieldId);
      if (!originalField) return null;
      
      const newId = `field-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
      fieldIdMap[fieldId] = newId;
      
      return {
        ...originalField,
        id: newId,
        key: `${originalField.key}_copy_${Math.random().toString(36).substr(2, 4)}`,
        label: `${originalField.label} (Copy)`
      };
    }).filter(Boolean) as LogField[];

    // Clone the section with updated field references
    const clonedSection: LogSection = {
      ...sectionToDuplicate,
      id: `section-${Date.now()}`,
      title: `${sectionToDuplicate.title} (Copy)`,
      rows: sectionToDuplicate.rows.map(row => ({
        ...row,
        id: `row-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
        columns: row.columns.map(col => ({
          ...col,
          fieldId: fieldIdMap[col.fieldId] || col.fieldId
        }))
      }))
    };

    // Insert the duplicated section after the original
    const newLayout = [...schema.layout];
    newLayout.splice(sectionIndex + 1, 0, clonedSection);

    onSchemaChange({
      ...schema,
      fields: [...schema.fields, ...clonedFields],
      layout: newLayout,
    });
  };

  const handleFieldRemove = (fieldId: string) => {
    // Remove field from schema
    const newFields = schema.fields.filter(f => f.id !== fieldId);
    
    // Remove field from layout
    const newLayout = schema.layout.map(section => ({
      ...section,
      rows: section.rows.map(row => ({
        ...row,
        columns: row.columns.filter(col => col.fieldId !== fieldId),
      })),
    }));

    onSchemaChange({
      ...schema,
      fields: newFields,
      layout: newLayout,
    });
  };

  return (
    <div 
      className="flex-1 p-6 overflow-y-auto" 
      onClick={(e) => {
        // Clear selection if clicking on canvas background
        if (e.target === e.currentTarget || (e.target as HTMLElement).closest('.canvas-background')) {
          onClearSelection?.();
        }
      }}
    >
      <div className="max-w-4xl mx-auto canvas-background">
        <div className="flex items-center justify-between mb-6">
          <div>
            <h2 className="text-2xl font-bold">Form Builder</h2>
            <div className="flex items-center gap-4">
              <p className="text-muted-foreground">
                Drag fields from the palette to build your form layout
              </p>
              {selectedFieldIds.length > 0 && (
                <Badge variant="secondary" className="ml-2">
                  {selectedFieldIds.length} selected
                </Badge>
              )}
            </div>
          </div>
          <div className="flex items-center gap-2">
            {selectedFieldIds.length > 0 && (
              <>
                <Button 
                  variant="outline" 
                  size="sm"
                  onClick={onCopyFields}
                  title="Copy selected fields (Ctrl+C)"
                >
                  <Copy className="h-4 w-4 mr-2" />
                  Copy
                </Button>
                {clipboardCount > 0 && (
                  <Button 
                    variant="outline" 
                    size="sm"
                    onClick={onPasteFields}
                    title={`Paste ${clipboardCount} field${clipboardCount > 1 ? 's' : ''} (Ctrl+V)`}
                  >
                    <Move className="h-4 w-4 mr-2" />
                    Paste ({clipboardCount})
                  </Button>
                )}
                <Button 
                  variant="outline" 
                  size="sm"
                  onClick={onDuplicateFields}
                  title="Duplicate selected fields (Ctrl+D)"
                >
                  <Copy className="h-4 w-4 mr-2" />
                  Duplicate
                </Button>
                <Button 
                  variant="destructive" 
                  size="sm"
                  onClick={onBulkDelete}
                  title="Delete selected fields (Delete)"
                >
                  <Trash2 className="h-4 w-4 mr-2" />
                  Delete
                </Button>
                <Button 
                  variant="outline" 
                  size="sm"
                  onClick={onClearSelection}
                  title="Clear selection (Escape)"
                >
                  Clear Selection
                </Button>
              </>
            )}
            <Button onClick={handleAddSection}>
              <Plus className="h-4 w-4 mr-2" />
              Add Section
            </Button>
          </div>
        </div>

        {schema.layout.length > 0 ? (
          <div className="space-y-4">
            <SortableContext 
              items={schema.layout.map(section => section.id)} 
              strategy={verticalListSortingStrategy}
            >
              {schema.layout.map((section, index) => (
                <SortableSection
                  key={section.id}
                  section={section}
                  fields={schema.fields}
                  selectedFieldId={selectedFieldId}
                  selectedFieldIds={selectedFieldIds}
                  onFieldSelect={onFieldSelect}
                  onSectionUpdate={(updatedSection) => handleSectionUpdate(index, updatedSection)}
                  onSectionRemove={() => handleSectionRemove(index)}
                  onSectionDuplicate={() => handleSectionDuplicate(index)}
                  onFieldRemove={handleFieldRemove}
                />
              ))}
            </SortableContext>
          </div>
        ) : (
          <Card className="border-dashed border-2 border-muted-foreground/25">
            <CardContent className="flex flex-col items-center justify-center py-16">
              <div className="text-center space-y-4">
                <div className="text-6xl opacity-20">📋</div>
                <div>
                  <h3 className="text-lg font-medium">Start building your form</h3>
                  <p className="text-muted-foreground">
                    Add sections and drag fields from the palette to create your layout
                  </p>
                </div>
                <Button onClick={handleAddSection}>
                  <Plus className="h-4 w-4 mr-2" />
                  Add First Section
                </Button>
              </div>
            </CardContent>
          </Card>
        )}
      </div>
    </div>
  );
}