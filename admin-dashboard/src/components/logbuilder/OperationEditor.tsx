'use client';

import React, { useState } from 'react';
import { DndContext, closestCenter, KeyboardSensor, PointerSensor, useSensor, useSensors, DragEndEvent } from '@dnd-kit/core';
import { arrayMove, SortableContext, sortableKeyboardCoordinates, verticalListSortingStrategy } from '@dnd-kit/sortable';
import { useSortable } from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import { Field, isMandatoryField } from '@/lib/logs/templates/types';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog';
import { Eye, EyeOff, GripVertical, Lock, Plus, Trash2, Edit2 } from 'lucide-react';
import { cn } from '@/lib/utils';

interface OperationEditorProps {
  fields: Field[];
  onFieldsChange: (fields: Field[]) => void;
  className?: string;
}

interface SortableFieldProps {
  field: Field;
  onToggleVisibility: () => void;
  onToggleRequired: () => void;
  onEdit: () => void;
  onRemove: () => void;
}

function SortableField({ field, onToggleVisibility, onToggleRequired, onEdit, onRemove }: SortableFieldProps) {
  const isMandatory = isMandatoryField(field.excelKey);
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging
  } = useSortable({ id: field.id, disabled: isMandatory });

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
    opacity: isDragging ? 0.5 : 1,
  };

  return (
    <div
      ref={setNodeRef}
      style={style}
      className={cn(
        "flex items-center gap-3 p-3 bg-white border rounded-lg",
        isDragging && "shadow-lg",
        isMandatory && "bg-gray-50"
      )}
    >
      <div
        {...attributes}
        {...listeners}
        className={cn(
          "cursor-grab hover:cursor-grabbing",
          isMandatory && "cursor-not-allowed opacity-50"
        )}
      >
        {isMandatory ? <Lock className="w-4 h-4 text-gray-400" /> : <GripVertical className="w-4 h-4 text-gray-400" />}
      </div>
      
      <div className="flex-1">
        <div className="font-medium text-sm">{field.label}</div>
        {field.unit && <div className="text-xs text-gray-500">Unit: {field.unit}</div>}
        {field.excelKey && <div className="text-xs text-gray-400">Key: {field.excelKey}</div>}
      </div>
      
      <div className="flex items-center gap-2">
        <Button
          variant="ghost"
          size="icon"
          onClick={onToggleVisibility}
          disabled={isMandatory}
          title={field.visible ? "Hide field" : "Show field"}
        >
          {field.visible ? <Eye className="w-4 h-4" /> : <EyeOff className="w-4 h-4" />}
        </Button>
        
        <div className="flex items-center gap-1">
          <Label htmlFor={`required-${field.id}`} className="text-xs">Req</Label>
          <Switch
            id={`required-${field.id}`}
            checked={field.required}
            onCheckedChange={onToggleRequired}
            disabled={isMandatory}
          />
        </div>
        
        <Button
          variant="ghost"
          size="icon"
          onClick={onEdit}
          disabled={isMandatory}
        >
          <Edit2 className="w-4 h-4" />
        </Button>
        
        <Button
          variant="ghost"
          size="icon"
          onClick={onRemove}
          disabled={isMandatory}
        >
          <Trash2 className="w-4 h-4" />
        </Button>
      </div>
    </div>
  );
}

export function OperationEditor({ fields, onFieldsChange, className }: OperationEditorProps) {
  const [editingField, setEditingField] = useState<Field | null>(null);
  const [showAddDialog, setShowAddDialog] = useState(false);
  const [newField, setNewField] = useState<Partial<Field>>({
    type: 'number',
    visible: true,
    required: false
  });

  const sensors = useSensors(
    useSensor(PointerSensor),
    useSensor(KeyboardSensor, {
      coordinateGetter: sortableKeyboardCoordinates,
    })
  );

  const handleDragEnd = (event: DragEndEvent) => {
    const { active, over } = event;
    if (active.id !== over?.id) {
      const oldIndex = fields.findIndex(f => f.id === active.id);
      const newIndex = fields.findIndex(f => f.id === over?.id);
      onFieldsChange(arrayMove(fields, oldIndex, newIndex));
    }
  };

  const handleToggleVisibility = (fieldId: string) => {
    onFieldsChange(
      fields.map(f => f.id === fieldId ? { ...f, visible: !f.visible } : f)
    );
  };

  const handleToggleRequired = (fieldId: string) => {
    onFieldsChange(
      fields.map(f => f.id === fieldId ? { ...f, required: !f.required } : f)
    );
  };

  const handleEditField = (field: Field) => {
    setEditingField(field);
  };

  const handleSaveEdit = () => {
    if (editingField) {
      onFieldsChange(
        fields.map(f => f.id === editingField.id ? editingField : f)
      );
      setEditingField(null);
    }
  };

  const handleRemoveField = (fieldId: string) => {
    onFieldsChange(fields.filter(f => f.id !== fieldId));
  };

  const handleAddField = () => {
    const field: Field = {
      id: `custom-${Date.now()}`,
      label: newField.label || 'New Field',
      type: newField.type as Field['type'],
      unit: newField.unit,
      required: newField.required || false,
      visible: newField.visible !== false,
      excelKey: `custom_${Date.now()}`
    };
    onFieldsChange([...fields, field]);
    setNewField({ type: 'number', visible: true, required: false });
    setShowAddDialog(false);
  };

  return (
    <div className={cn("space-y-4", className)}>
      <div className="flex justify-between items-center mb-4">
        <h3 className="text-lg font-semibold">Operation Fields</h3>
        <Button onClick={() => setShowAddDialog(true)} size="sm">
          <Plus className="w-4 h-4 mr-2" />
          Add Custom Field
        </Button>
      </div>

      {fields.length === 0 ? (
        <div className="text-center py-12 bg-gray-50 border-2 border-dashed border-gray-300 rounded-lg">
          <div className="text-gray-400 mb-4">📋</div>
          <h3 className="text-lg font-medium text-gray-900 mb-2">No operation fields yet</h3>
          <p className="text-gray-500 mb-4">Add fields that operators will fill out in the Excel template</p>
          <Button onClick={() => setShowAddDialog(true)} className="bg-blue-600 hover:bg-blue-700">
            <Plus className="w-4 h-4 mr-2" />
            Add Your First Field
          </Button>
        </div>
      ) : (
        <DndContext
          sensors={sensors}
          collisionDetection={closestCenter}
          onDragEnd={handleDragEnd}
        >
          <SortableContext items={fields.map(f => f.id)} strategy={verticalListSortingStrategy}>
            <div className="space-y-2">
              {fields.map(field => (
                <SortableField
                  key={field.id}
                  field={field}
                  onToggleVisibility={() => handleToggleVisibility(field.id)}
                  onToggleRequired={() => handleToggleRequired(field.id)}
                  onEdit={() => handleEditField(field)}
                  onRemove={() => handleRemoveField(field.id)}
                />
              ))}
            </div>
          </SortableContext>
        </DndContext>
      )}

      <Dialog open={!!editingField} onOpenChange={() => setEditingField(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Edit Field</DialogTitle>
          </DialogHeader>
          {editingField && (
            <div className="space-y-4">
              <div>
                <Label htmlFor="edit-label">Label</Label>
                <Input
                  id="edit-label"
                  value={editingField.label}
                  onChange={e => setEditingField({ ...editingField, label: e.target.value })}
                />
              </div>
              <div>
                <Label htmlFor="edit-unit">Unit</Label>
                <Input
                  id="edit-unit"
                  value={editingField.unit || ''}
                  onChange={e => setEditingField({ ...editingField, unit: e.target.value })}
                />
              </div>
              {editingField.type === 'number' && (
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <Label htmlFor="edit-min">Min Value</Label>
                    <Input
                      id="edit-min"
                      type="number"
                      value={editingField.rules?.min || ''}
                      onChange={e => setEditingField({
                        ...editingField,
                        rules: { ...editingField.rules, min: Number(e.target.value) }
                      })}
                    />
                  </div>
                  <div>
                    <Label htmlFor="edit-max">Max Value</Label>
                    <Input
                      id="edit-max"
                      type="number"
                      value={editingField.rules?.max || ''}
                      onChange={e => setEditingField({
                        ...editingField,
                        rules: { ...editingField.rules, max: Number(e.target.value) }
                      })}
                    />
                  </div>
                </div>
              )}
            </div>
          )}
          <DialogFooter>
            <Button variant="outline" onClick={() => setEditingField(null)}>Cancel</Button>
            <Button onClick={handleSaveEdit}>Save Changes</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog open={showAddDialog} onOpenChange={setShowAddDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Add Custom Field</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <Label htmlFor="new-label">Label</Label>
              <Input
                id="new-label"
                value={newField.label || ''}
                onChange={e => setNewField({ ...newField, label: e.target.value })}
              />
            </div>
            <div>
              <Label htmlFor="new-type">Type</Label>
              <Select
                value={newField.type}
                onValueChange={value => setNewField({ ...newField, type: value as Field['type'] })}
              >
                <SelectTrigger id="new-type">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="number">Number</SelectItem>
                  <SelectItem value="text">Text</SelectItem>
                  <SelectItem value="boolean">Boolean</SelectItem>
                  <SelectItem value="computed">Computed</SelectItem>
                </SelectContent>
              </Select>
            </div>
            {newField.type === 'number' && (
              <div>
                <Label htmlFor="new-unit">Unit</Label>
                <Input
                  id="new-unit"
                  value={newField.unit || ''}
                  onChange={e => setNewField({ ...newField, unit: e.target.value })}
                />
              </div>
            )}
            <div className="flex items-center gap-2">
              <Switch
                id="new-required"
                checked={newField.required || false}
                onCheckedChange={checked => setNewField({ ...newField, required: checked })}
              />
              <Label htmlFor="new-required">Required field</Label>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowAddDialog(false)}>Cancel</Button>
            <Button onClick={handleAddField}>Add Field</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}