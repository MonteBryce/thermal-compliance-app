'use client';

import { useState, useEffect, useCallback, lazy, Suspense } from 'react';
import { useParams } from 'next/navigation';
import {
  DndContext,
  DragEndEvent,
  DragOverEvent,
  DragStartEvent,
  PointerSensor,
  useSensor,
  useSensors,
  DragOverlay,
  closestCorners,
} from '@dnd-kit/core';
import {
  SortableContext,
  verticalListSortingStrategy,
  arrayMove,
} from '@dnd-kit/sortable';
import { LazyWrapper } from '@/components/lazy/lazy-wrapper';

const Palette = lazy(() => import('@/components/logbuilder/Palette').then(mod => ({ default: mod.Palette })));
const VariablePalette = lazy(() => import('@/components/logbuilder/VariablePalette').then(mod => ({ default: mod.VariablePalette })));
import { LogVariable } from '@/lib/types/variable-palette';
const Canvas = lazy(() => import('@/components/logbuilder/Canvas').then(mod => ({ default: mod.Canvas })));
const Inspector = lazy(() => import('@/components/logbuilder/Inspector').then(mod => ({ default: mod.Inspector })));
const TemplateHeaderBar = lazy(() => import('@/components/logbuilder/TemplateHeaderBar').then(mod => ({ default: mod.TemplateHeaderBar })));
import {
  LogTemplate,
  LogSchema,
  LogField,
  LogSection,
  LogLayoutRow,
  VariableCatalog,
  DragItem,
} from '@/lib/types/logbuilder';
import { TemplateService } from '@/lib/firestore/templates';
import { Card } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';

export default function TemplateEditPage() {
  const params = useParams();
  const templateId = params.templateId as string;

  const [template, setTemplate] = useState<LogTemplate | null>(null);
  const [schema, setSchema] = useState<LogSchema>({
    fields: [],
    layout: [],
    meta: {},
  });
  const [selectedField, setSelectedField] = useState<LogField | null>(null);
  const [selectedFieldIds, setSelectedFieldIds] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [hasUnsavedChanges, setHasUnsavedChanges] = useState(false);
  const [activeId, setActiveId] = useState<string | null>(null);
  const [draggedItem, setDraggedItem] = useState<any>(null);
  const [clipboardFields, setClipboardFields] = useState<LogField[]>([]);
  const [schemaHistory, setSchemaHistory] = useState<LogSchema[]>([]);
  const [historyIndex, setHistoryIndex] = useState(-1);
  const [isRedoing, setIsRedoing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [variables, setVariables] = useState<LogVariable[]>([]);

  const templateService = new TemplateService();

  // Mock variables for testing Variable Palette
  const mockVariables: LogVariable[] = [
    {
      id: 'var-1',
      name: 'Job Number',
      category: 'Job Info',
      dataType: 'text',
      excelColumn: 'A',
      description: 'Unique job identifier for tracking work orders',
      tags: ['required', 'identifier', 'tracking'],
      isFavorite: false,
      lastUsed: null,
      validation: { required: true, maxLength: 20 },
    },
    {
      id: 'var-2',
      name: 'Temperature Reading',
      category: 'Thermal',
      dataType: 'number',
      excelColumn: 'B',
      description: 'Temperature measurement in degrees Fahrenheit',
      tags: ['thermal', 'measurement', 'critical'],
      isFavorite: true,
      lastUsed: new Date('2025-01-15'),
      validation: { required: true, min: 32, max: 2000 },
      unit: '°F',
    },
    {
      id: 'var-3',
      name: 'Equipment ID',
      category: 'Equipment',
      dataType: 'text',
      excelColumn: 'C',
      description: 'Unique identifier for thermal oxidizer equipment',
      tags: ['equipment', 'asset', 'required'],
      isFavorite: false,
      lastUsed: new Date('2025-01-10'),
      validation: { required: true, pattern: '^[A-Z0-9-]+$' },
    },
    {
      id: 'var-4',
      name: 'Operator Name',
      category: 'Personnel',
      dataType: 'text',
      excelColumn: 'D',
      description: 'Name of the person performing the thermal log',
      tags: ['personnel', 'required'],
      isFavorite: false,
      lastUsed: null,
      validation: { required: true, maxLength: 50 },
    },
    {
      id: 'var-5',
      name: 'Pressure Reading',
      category: 'Thermal',
      dataType: 'number',
      excelColumn: 'E',
      description: 'Pressure measurement in pounds per square inch',
      tags: ['thermal', 'measurement'],
      isFavorite: true,
      lastUsed: new Date('2025-01-12'),
      validation: { required: true, min: 0, max: 500 },
      unit: 'PSI',
    },
    {
      id: 'var-6',
      name: 'Flow Rate',
      category: 'Thermal',
      dataType: 'number',
      excelColumn: 'F',
      description: 'Air flow rate in cubic feet per minute',
      tags: ['thermal', 'measurement', 'flow'],
      isFavorite: false,
      lastUsed: new Date('2025-01-08'),
      validation: { required: true, min: 0, max: 10000 },
      unit: 'CFM',
    },
    {
      id: 'var-7',
      name: 'Compliance Status',
      category: 'Compliance',
      dataType: 'select',
      excelColumn: 'G',
      description: 'Current compliance status of the thermal oxidizer',
      tags: ['compliance', 'required', 'status'],
      isFavorite: true,
      lastUsed: new Date('2025-01-18'),
      validation: { required: true },
      options: [
        { label: 'Compliant', value: 'compliant' },
        { label: 'Non-Compliant', value: 'non_compliant' },
        { label: 'Under Review', value: 'under_review' },
      ],
    },
    {
      id: 'var-8',
      name: 'Log Date',
      category: 'Job Info',
      dataType: 'date',
      excelColumn: 'H',
      description: 'Date when the thermal log was performed',
      tags: ['required', 'timestamp', 'date'],
      isFavorite: true,
      lastUsed: new Date('2025-01-20'),
      validation: { required: true },
    },
    {
      id: 'var-9',
      name: 'Additional Notes',
      category: 'General',
      dataType: 'textarea',
      excelColumn: 'I',
      description: 'Any additional observations or notes',
      tags: ['notes', 'optional'],
      isFavorite: false,
      lastUsed: new Date('2025-01-05'),
      validation: { maxLength: 1000 },
    },
  ];

  const sensors = useSensors(
    useSensor(PointerSensor, {
      activationConstraint: {
        distance: 8,
      },
    })
  );

  useEffect(() => {
    loadTemplate();
    // Initialize mock variables for testing
    setVariables(mockVariables);
  }, [templateId]);


  const handleSectionReorder = (activeSectionId: string, overSectionId: string) => {
    if (activeSectionId === overSectionId) return;

    setSchema(prevSchema => {
      const activeIndex = prevSchema.layout.findIndex(s => s.id === activeSectionId);
      const overIndex = prevSchema.layout.findIndex(s => s.id === overSectionId);

      if (activeIndex === -1 || overIndex === -1) return prevSchema;

      const newLayout = arrayMove(prevSchema.layout, activeIndex, overIndex);

      return {
        ...prevSchema,
        layout: newLayout
      };
    });

    setHasUnsavedChanges(true);
  };

  const loadTemplate = async () => {
    try {
      setLoading(true);
      const templateData = await templateService.getTemplate(templateId);
      if (templateData) {
        setTemplate(templateData);
        setSchema(templateData.draftSchema);
      }
    } catch (error) {
      console.error('Error loading template:', error);
      
      // Fallback to mock data for testing Variable Palette
      const mockTemplate: LogTemplate = {
        id: templateId,
        name: templateId === 'template-1' ? 'Hourly Thermal Oxidizer Log' : 
              templateId === 'template-2' ? 'Daily Maintenance Log' : 
              templateId === 'template-3' ? 'Weekly Thermal Summary' : 
              'Sample Template',
        logType: 'thermal_sample',
        status: 'draft',
        latestVersion: 0,
        createdBy: 'admin@thermallog.com',
        createdAt: { toDate: () => new Date() } as any,
        updatedAt: { toDate: () => new Date() } as any,
        draftSchema: {
          fields: [
            {
              id: 'field-1',
              key: 'jobNumber',
              label: 'Job Number',
              type: 'text',
              required: true,
              validation: { maxLength: 20 },
            },
            {
              id: 'field-2',
              key: 'temperatureReading',
              label: 'Temperature (°F)',
              type: 'number',
              unit: '°F',
              required: true,
              validation: { min: 32, max: 2000 },
            },
          ],
          layout: [
            {
              id: 'section-1',
              title: 'Sample Section',
              rows: [
                {
                  id: 'row-1',
                  columns: [
                    { fieldId: 'field-1', width: 6 },
                    { fieldId: 'field-2', width: 6 },
                  ],
                },
              ],
            },
          ],
          meta: {
            description: 'Sample template for testing Variable Palette',
            hourFormat: '24h',
          },
        },
      };
      
      setTemplate(mockTemplate);
      setSchema(mockTemplate.draftSchema);
      console.log('✅ Loaded mock template for testing Variable Palette');
    } finally {
      setLoading(false);
    }
  };

  const saveToHistory = useCallback((schema: LogSchema) => {
    setSchemaHistory(prev => {
      // Remove any future history if we're not at the end
      const newHistory = prev.slice(0, historyIndex + 1);
      // Add new state
      newHistory.push(schema);
      // Limit history to 50 items
      if (newHistory.length > 50) {
        newHistory.shift();
        return newHistory;
      }
      return newHistory;
    });
    setHistoryIndex(prev => {
      const newIndex = Math.min(prev + 1, 49);
      return newIndex;
    });
  }, [historyIndex]);

  const handleSchemaChange = useCallback((newSchema: LogSchema) => {
    try {
      setError(null);
      
      // Save current schema to history before changing (if not redoing)
      if (!isRedoing) {
        saveToHistory(schema);
      }
      
      setSchema(newSchema);
      setHasUnsavedChanges(true);
    } catch (error) {
      console.error('Error updating schema:', error);
      setError('Failed to update form layout. Please try again.');
    }
  }, [schema, saveToHistory, isRedoing]);

  const handleUndo = useCallback(() => {
    if (historyIndex > 0) {
      setIsRedoing(true);
      const previousSchema = schemaHistory[historyIndex - 1];
      setSchema(previousSchema);
      setHistoryIndex(prev => prev - 1);
      setHasUnsavedChanges(true);
      setTimeout(() => setIsRedoing(false), 10);
    }
  }, [schemaHistory, historyIndex]);

  const handleRedo = useCallback(() => {
    if (historyIndex < schemaHistory.length - 1) {
      setIsRedoing(true);
      const nextSchema = schemaHistory[historyIndex + 1];
      setSchema(nextSchema);
      setHistoryIndex(prev => prev + 1);
      setHasUnsavedChanges(true);
      setTimeout(() => setIsRedoing(false), 10);
    }
  }, [schemaHistory, historyIndex]);

  const handleFieldSelect = useCallback((field: LogField, event?: React.MouseEvent) => {
    setSelectedField(field);
    
    // Handle multi-select with Ctrl/Cmd + click
    if (event?.ctrlKey || event?.metaKey) {
      setSelectedFieldIds(prev => {
        if (prev.includes(field.id)) {
          return prev.filter(id => id !== field.id);
        } else {
          return [...prev, field.id];
        }
      });
    } else {
      setSelectedFieldIds([field.id]);
    }
  }, []);

  const handleClearSelection = useCallback(() => {
    setSelectedField(null);
    setSelectedFieldIds([]);
  }, []);

  const handleSelectAll = useCallback(() => {
    const allFieldIds = schema.fields.map(f => f.id);
    setSelectedFieldIds(allFieldIds);
  }, [schema.fields]);

  const handleBulkDelete = useCallback(() => {
    if (selectedFieldIds.length === 0) return;

    // Remove fields from schema
    const newFields = schema.fields.filter(f => !selectedFieldIds.includes(f.id));
    
    // Remove fields from layout
    const newLayout = schema.layout.map(section => ({
      ...section,
      rows: section.rows.map(row => ({
        ...row,
        columns: row.columns.filter(col => !selectedFieldIds.includes(col.fieldId)),
      })),
    }));

    handleSchemaChange({
      ...schema,
      fields: newFields,
      layout: newLayout,
    });

    setSelectedFieldIds([]);
    setSelectedField(null);
  }, [selectedFieldIds, schema, handleSchemaChange]);

  const handleCopyFields = useCallback(() => {
    if (selectedFieldIds.length === 0) return;

    const fieldsToCopy = schema.fields.filter(f => selectedFieldIds.includes(f.id));
    setClipboardFields(fieldsToCopy);
  }, [selectedFieldIds, schema.fields]);

  const handlePasteFields = useCallback((targetSectionId?: string, targetRowIndex?: number) => {
    if (clipboardFields.length === 0) return;

    // Create new field instances with unique IDs
    const newFields = clipboardFields.map(field => ({
      ...field,
      id: `field-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
      key: `${field.key}_copy_${Math.random().toString(36).substr(2, 4)}`,
      label: `${field.label} (Copy)`
    }));

    // Determine where to paste
    let pasteSectionId = targetSectionId;
    let pasteRowIndex = targetRowIndex;

    // If no target specified, create a new section
    if (!pasteSectionId) {
      const newSection: LogSection = {
        id: `section-${Date.now()}`,
        title: `Pasted Fields ${schema.layout.length + 1}`,
        rows: [
          {
            id: `row-${Date.now()}`,
            columns: newFields.map(field => ({ fieldId: field.id, width: 6 }))
          }
        ]
      };

      handleSchemaChange({
        ...schema,
        fields: [...schema.fields, ...newFields],
        layout: [...schema.layout, newSection]
      });
      return;
    }

    // Add to existing section/row
    const newLayout = [...schema.layout];
    const sectionIndex = newLayout.findIndex(s => s.id === pasteSectionId);
    if (sectionIndex === -1) return;

    const section = { ...newLayout[sectionIndex] };
    
    if (pasteRowIndex !== undefined && pasteRowIndex < section.rows.length) {
      // Add to existing row
      const row = { ...section.rows[pasteRowIndex] };
      row.columns = [
        ...row.columns,
        ...newFields.map(field => ({ fieldId: field.id, width: 6 }))
      ];
      section.rows = [...section.rows];
      section.rows[pasteRowIndex] = row;
    } else {
      // Add to new row
      section.rows = [
        ...section.rows,
        {
          id: `row-${Date.now()}`,
          columns: newFields.map(field => ({ fieldId: field.id, width: 6 }))
        }
      ];
    }

    newLayout[sectionIndex] = section;

    handleSchemaChange({
      ...schema,
      fields: [...schema.fields, ...newFields],
      layout: newLayout
    });
  }, [clipboardFields, schema, handleSchemaChange]);

  const handleDuplicateFields = useCallback(() => {
    handleCopyFields();
    // Small delay to ensure clipboard is updated
    setTimeout(() => handlePasteFields(), 10);
  }, [handleCopyFields, handlePasteFields]);

  const handleFieldUpdate = useCallback((updatedField: LogField) => {
    setSchema(prevSchema => ({
      ...prevSchema,
      fields: prevSchema.fields.map(field =>
        field.id === updatedField.id ? updatedField : field
      ),
    }));
    setHasUnsavedChanges(true);
  }, []);

  const handleFieldCreate = useCallback((newField: LogField) => {
    setSchema(prevSchema => ({
      ...prevSchema,
      fields: [...prevSchema.fields, newField],
    }));
    setHasUnsavedChanges(true);
    setSelectedField(null);
  }, []);

  // Keyboard shortcuts for multi-select operations - moved after all handlers are defined
  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      // Ctrl/Cmd + A: Select all fields
      if ((event.ctrlKey || event.metaKey) && event.key === 'a') {
        event.preventDefault();
        handleSelectAll();
      }
      
      // Escape: Clear selection
      if (event.key === 'Escape') {
        event.preventDefault();
        handleClearSelection();
      }
      
      // Delete: Delete selected fields
      if (event.key === 'Delete' && selectedFieldIds.length > 0) {
        event.preventDefault();
        handleBulkDelete();
      }

      // Ctrl/Cmd + C: Copy selected fields
      if ((event.ctrlKey || event.metaKey) && event.key === 'c' && selectedFieldIds.length > 0) {
        event.preventDefault();
        handleCopyFields();
      }

      // Ctrl/Cmd + V: Paste fields
      if ((event.ctrlKey || event.metaKey) && event.key === 'v' && clipboardFields.length > 0) {
        event.preventDefault();
        handlePasteFields();
      }

      // Ctrl/Cmd + D: Duplicate selected fields
      if ((event.ctrlKey || event.metaKey) && event.key === 'd' && selectedFieldIds.length > 0) {
        event.preventDefault();
        handleDuplicateFields();
      }

      // Ctrl/Cmd + Z: Undo
      if ((event.ctrlKey || event.metaKey) && event.key === 'z' && !event.shiftKey) {
        event.preventDefault();
        handleUndo();
      }

      // Ctrl/Cmd + Shift + Z or Ctrl/Cmd + Y: Redo
      if (((event.ctrlKey || event.metaKey) && event.key === 'z' && event.shiftKey) ||
          ((event.ctrlKey || event.metaKey) && event.key === 'y')) {
        event.preventDefault();
        handleRedo();
      }
    };

    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, [handleSelectAll, handleClearSelection, handleBulkDelete, handleCopyFields, handlePasteFields, handleDuplicateFields, handleUndo, handleRedo, selectedFieldIds, clipboardFields]);

  const handleSave = async () => {
    if (!template) return;

    try {
      setError(null);
      setSaving(true);
      await templateService.updateDraftSchema(template.id, schema);
      setHasUnsavedChanges(false);
    } catch (error) {
      console.error('Error saving template:', error);
      setError('Failed to save template. Please try again.');
    } finally {
      setSaving(false);
    }
  };

  const handlePublish = async (changelog: string) => {
    if (!template) return;

    try {
      setError(null);
      const newVersion = await templateService.publishTemplate(
        template.id,
        changelog,
        'current-user' // TODO: Get from auth context
      );
      
      // Reload template to get updated status
      await loadTemplate();
    } catch (error) {
      console.error('Error publishing template:', error);
      setError('Failed to publish template. Please try again.');
    }
  };

  const handleDragStart = (event: DragStartEvent) => {
    setActiveId(event.active.id as string);
    setDraggedItem(event.active.data.current);
  };

  const handleDragOver = (event: DragOverEvent) => {
    // Handle drag over logic for visual feedback
  };

  const handleDragEnd = (event: DragEndEvent) => {
    const { active, over } = event;
    
    if (!over) {
      setActiveId(null);
      setDraggedItem(null);
      return;
    }

    const activeData = active.data.current;
    const overData = over.data.current;

    // Handle variable/control drop onto canvas
    if (activeData?.type === 'variable' || activeData?.type === 'control') {
      handleDropFromPalette(activeData, overData);
    }
    // Handle section reordering
    else if (activeData?.type === 'section' && overData?.type === 'section') {
      handleSectionReorder(active.id as string, over.id as string);
    }
    // Handle field reordering within canvas
    else if (activeData && (active.id.toString().startsWith('field-') || activeData.type === 'field')) {
      // Check if dropping on another field or a droppable row
      if (over.id.toString().startsWith('field-')) {
        handleFieldReorder(active.id as string, over.id as string, overData);
      } else if (overData?.type === 'row') {
        // Moving field to a different row
        const activeLocation = findFieldInLayout(schema, active.id as string);
        if (activeLocation && (activeLocation.sectionId !== overData.sectionId || activeLocation.rowIndex !== overData.rowIndex)) {
          moveFieldToRow(active.id as string, overData.sectionId, overData.rowIndex);
        }
      }
    }

    setActiveId(null);
    setDraggedItem(null);
  };

  const handleDropFromPalette = (dragData: any, dropData: any) => {
    let newField: LogField;

    if (dragData.type === 'variable') {
      const variable: VariableCatalog = dragData.variable;
      newField = {
        id: `field-${Date.now()}`,
        key: variable.key,
        label: variable.label,
        type: variable.type,
        unit: variable.unit,
        required: false,
        validation: variable.validation,
        options: variable.options,
      };
    } else if (dragData.type === 'control') {
      newField = {
        id: `field-${Date.now()}`,
        key: `field_${Date.now()}`,
        label: `New ${dragData.fieldType} Field`,
        type: dragData.fieldType,
        required: false,
      };
    } else {
      return;
    }

    // Determine where to place the field
    if (dropData?.type === 'row') {
      // Add to specific row
      const { sectionId, rowIndex } = dropData;
      addFieldToRow(newField, sectionId, rowIndex);
    } else {
      // Add to a new section/row
      addFieldToNewSection(newField);
    }

    setHasUnsavedChanges(true);
  };

  const addFieldToRow = (field: LogField, sectionId: string, rowIndex: number) => {
    setSchema(prevSchema => {
      const newFields = [...prevSchema.fields, field];
      const newLayout = prevSchema.layout.map(section => {
        if (section.id === sectionId) {
          const newRows = [...section.rows];
          newRows[rowIndex] = {
            ...newRows[rowIndex],
            columns: [
              ...newRows[rowIndex].columns,
              { fieldId: field.id, width: 6 },
            ],
          };
          return { ...section, rows: newRows };
        }
        return section;
      });

      return {
        ...prevSchema,
        fields: newFields,
        layout: newLayout,
      };
    });
  };

  const addFieldToNewSection = (field: LogField) => {
    setSchema(prevSchema => {
      const newSection: LogSection = {
        id: `section-${Date.now()}`,
        title: `Section ${prevSchema.layout.length + 1}`,
        rows: [
          {
            id: `row-${Date.now()}`,
            columns: [{ fieldId: field.id, width: 12 }],
          },
        ],
      };

      return {
        ...prevSchema,
        fields: [...prevSchema.fields, field],
        layout: [...prevSchema.layout, newSection],
      };
    });
  };

  const handleFieldReorder = (activeId: string, overId: string, overData: any) => {
    if (activeId === overId) return;

    const activeField = findFieldInLayout(schema, activeId);
    const overField = findFieldInLayout(schema, overId);
    
    if (!activeField || !overField) return;

    // If dropping in same row, reorder within row
    if (activeField.sectionId === overField.sectionId && activeField.rowIndex === overField.rowIndex) {
      reorderFieldsInSameRow(activeId, overId, activeField.sectionId, activeField.rowIndex);
    }
    // If dropping in different row/section, move field
    else {
      moveFieldBetweenRows(activeId, overId, activeField, overField);
    }
  };

  const findFieldInLayout = (schema: LogSchema, fieldId: string) => {
    for (let sectionIndex = 0; sectionIndex < schema.layout.length; sectionIndex++) {
      const section = schema.layout[sectionIndex];
      for (let rowIndex = 0; rowIndex < section.rows.length; rowIndex++) {
        const row = section.rows[rowIndex];
        const columnIndex = row.columns.findIndex(col => col.fieldId === fieldId);
        if (columnIndex !== -1) {
          return {
            sectionId: section.id,
            sectionIndex,
            rowIndex,
            columnIndex,
            column: row.columns[columnIndex]
          };
        }
      }
    }
    return null;
  };

  const reorderFieldsInSameRow = (activeId: string, overId: string, sectionId: string, rowIndex: number) => {
    setSchema(prevSchema => {
      const newLayout = [...prevSchema.layout];
      const sectionIndex = newLayout.findIndex(s => s.id === sectionId);
      if (sectionIndex === -1) return prevSchema;

      const section = { ...newLayout[sectionIndex] };
      const row = { ...section.rows[rowIndex] };
      const columns = [...row.columns];

      const activeIndex = columns.findIndex(col => col.fieldId === activeId);
      const overIndex = columns.findIndex(col => col.fieldId === overId);

      if (activeIndex === -1 || overIndex === -1) return prevSchema;

      // Use arrayMove from @dnd-kit/sortable
      const reorderedColumns = arrayMove(columns, activeIndex, overIndex);
      
      row.columns = reorderedColumns;
      section.rows = [...section.rows];
      section.rows[rowIndex] = row;
      newLayout[sectionIndex] = section;

      return {
        ...prevSchema,
        layout: newLayout
      };
    });

    setHasUnsavedChanges(true);
  };

  const moveFieldBetweenRows = (activeId: string, overId: string, activeLocation: any, overLocation: any) => {
    setSchema(prevSchema => {
      const newLayout = [...prevSchema.layout];
      
      // Remove from source location
      const sourceSectionIndex = newLayout.findIndex(s => s.id === activeLocation.sectionId);
      if (sourceSectionIndex === -1) return prevSchema;
      
      const sourceSection = { ...newLayout[sourceSectionIndex] };
      const sourceRow = { ...sourceSection.rows[activeLocation.rowIndex] };
      const sourceColumns = [...sourceRow.columns];
      
      const activeColumn = sourceColumns[activeLocation.columnIndex];
      sourceColumns.splice(activeLocation.columnIndex, 1);
      
      sourceRow.columns = sourceColumns;
      sourceSection.rows = [...sourceSection.rows];
      sourceSection.rows[activeLocation.rowIndex] = sourceRow;
      newLayout[sourceSectionIndex] = sourceSection;
      
      // Add to target location
      const targetSectionIndex = newLayout.findIndex(s => s.id === overLocation.sectionId);
      if (targetSectionIndex === -1) return prevSchema;
      
      const targetSection = { ...newLayout[targetSectionIndex] };
      const targetRow = { ...targetSection.rows[overLocation.rowIndex] };
      const targetColumns = [...targetRow.columns];
      
      // Insert before the over field
      const overIndex = targetColumns.findIndex(col => col.fieldId === overId);
      if (overIndex === -1) {
        targetColumns.push(activeColumn);
      } else {
        targetColumns.splice(overIndex, 0, activeColumn);
      }
      
      targetRow.columns = targetColumns;
      targetSection.rows = [...targetSection.rows];
      targetSection.rows[overLocation.rowIndex] = targetRow;
      newLayout[targetSectionIndex] = targetSection;
      
      return {
        ...prevSchema,
        layout: newLayout
      };
    });

    setHasUnsavedChanges(true);
  };

  const moveFieldToRow = (fieldId: string, targetSectionId: string, targetRowIndex: number) => {
    const activeLocation = findFieldInLayout(schema, fieldId);
    if (!activeLocation) return;

    setSchema(prevSchema => {
      const newLayout = [...prevSchema.layout];
      
      // Remove from source location
      const sourceSectionIndex = newLayout.findIndex(s => s.id === activeLocation.sectionId);
      if (sourceSectionIndex === -1) return prevSchema;
      
      const sourceSection = { ...newLayout[sourceSectionIndex] };
      const sourceRow = { ...sourceSection.rows[activeLocation.rowIndex] };
      const sourceColumns = [...sourceRow.columns];
      
      const activeColumn = sourceColumns[activeLocation.columnIndex];
      sourceColumns.splice(activeLocation.columnIndex, 1);
      
      sourceRow.columns = sourceColumns;
      sourceSection.rows = [...sourceSection.rows];
      sourceSection.rows[activeLocation.rowIndex] = sourceRow;
      newLayout[sourceSectionIndex] = sourceSection;
      
      // Add to target location
      const targetSectionIndex = newLayout.findIndex(s => s.id === targetSectionId);
      if (targetSectionIndex === -1) return prevSchema;
      
      const targetSection = { ...newLayout[targetSectionIndex] };
      const targetRow = { ...targetSection.rows[targetRowIndex] };
      const targetColumns = [...targetRow.columns];
      
      // Add to end of target row
      targetColumns.push(activeColumn);
      
      targetRow.columns = targetColumns;
      targetSection.rows = [...targetSection.rows];
      targetSection.rows[targetRowIndex] = targetRow;
      newLayout[targetSectionIndex] = targetSection;
      
      return {
        ...prevSchema,
        layout: newLayout
      };
    });

    setHasUnsavedChanges(true);
  };

  if (loading) {
    return (
      <div className="h-screen flex flex-col">
        <div className="border-b p-6">
          <Skeleton className="h-8 w-64" />
        </div>
        <div className="flex-1 flex">
          <Skeleton className="w-80 h-full" />
          <Skeleton className="flex-1 h-full" />
          <Skeleton className="w-80 h-full" />
        </div>
      </div>
    );
  }

  if (!template) {
    return (
      <div className="h-screen flex items-center justify-center">
        <Card className="p-8 text-center">
          <h2 className="text-xl font-semibold mb-2">Template Not Found</h2>
          <p className="text-muted-foreground">
            The template you're looking for doesn't exist or you don't have permission to view it.
          </p>
        </Card>
      </div>
    );
  }

  return (
    <DndContext
      sensors={sensors}
      collisionDetection={closestCorners}
      onDragStart={handleDragStart}
      onDragOver={handleDragOver}
      onDragEnd={handleDragEnd}
    >
      <div className="h-screen flex flex-col bg-background">
        {/* Header */}
        <LazyWrapper>
          <TemplateHeaderBar
            template={template}
            schema={schema}
            onSave={handleSave}
            onPublish={handlePublish}
            hasUnsavedChanges={hasUnsavedChanges}
            isSaving={saving}
            onUndo={handleUndo}
            onRedo={handleRedo}
            canUndo={historyIndex > 0}
            canRedo={historyIndex < schemaHistory.length - 1}
            error={error}
            onClearError={() => setError(null)}
          />
        </LazyWrapper>

        {/* Main Content */}
        <div className="flex-1 flex overflow-hidden">
          {/* Left Palette */}
          <div className="w-80 border-r bg-muted/20">
            <LazyWrapper>
              <VariablePalette
                variables={variables}
                onAddVariable={(variable) => {
                  const newField: LogField = {
                    id: `field-${Date.now()}`,
                    key: variable.name.toLowerCase().replace(/\s+/g, '_'),
                    label: variable.name,
                    type: variable.dataType as any,
                    unit: variable.unit,
                    required: variable.validation?.required,
                    validation: variable.validation,
                    options: variable.options,
                    defaultValue: variable.defaultValue,
                  };
                  setSchema(prev => ({ ...prev, fields: [...prev.fields, newField] }));
                  setHasUnsavedChanges(true);
                }}
                onToggleFavorite={(variableId) => {
                  setVariables(prev =>
                    prev.map(v => v.id === variableId ? { ...v, isFavorite: !v.isFavorite } : v)
                  );
                }}
                onCreateVariable={(variableData) => {
                  const newVariable: LogVariable = { ...variableData, id: `var-${Date.now()}` };
                  setVariables(prev => [...prev, newVariable]);
                }}
                onEditVariable={(variableId, updates) => {
                  setVariables(prev => prev.map(v => v.id === variableId ? { ...v, ...updates } : v));
                }}
                onDeleteVariable={(variableId) => {
                  setVariables(prev => prev.filter(v => v.id !== variableId));
                }}
              />
            </LazyWrapper>
          </div>

          {/* Center Canvas */}
          <div className="flex-1 overflow-y-auto">
            <LazyWrapper>
              <Canvas
                schema={schema}
                onSchemaChange={handleSchemaChange}
                onFieldSelect={handleFieldSelect}
                selectedFieldId={selectedField?.id}
                selectedFieldIds={selectedFieldIds}
                onClearSelection={handleClearSelection}
                onCopyFields={handleCopyFields}
                onPasteFields={handlePasteFields}
                onDuplicateFields={handleDuplicateFields}
                onBulkDelete={handleBulkDelete}
                clipboardCount={clipboardFields.length}
              />
            </LazyWrapper>
          </div>

          {/* Right Inspector */}
          <div className="w-80 border-l bg-muted/20">
            <LazyWrapper>
              <Inspector
                selectedField={selectedField}
                onFieldUpdate={handleFieldUpdate}
                onFieldCreate={handleFieldCreate}
                onClose={() => setSelectedField(null)}
              />
            </LazyWrapper>
          </div>
        </div>

        {/* Enhanced Drag Overlay */}
        <DragOverlay dropAnimation={null}>
          {activeId && draggedItem ? (
            <div className="p-3 bg-background border-2 border-primary rounded-lg shadow-xl opacity-95 transform rotate-3 scale-105 transition-transform">
              <div className="flex items-center gap-3">
                {draggedItem.type === 'variable' ? (
                  <>
                    <div className="w-8 h-8 bg-blue-100 rounded-lg flex items-center justify-center">
                      <span className="text-lg">📋</span>
                    </div>
                    <div className="flex flex-col">
                      <span className="font-medium text-sm">{draggedItem.variable.label}</span>
                      <code className="text-xs text-muted-foreground bg-muted px-2 py-1 rounded">
                        {draggedItem.variable.key}
                      </code>
                      {draggedItem.variable.unit && (
                        <Badge variant="secondary" className="text-xs w-fit mt-1">
                          {draggedItem.variable.unit}
                        </Badge>
                      )}
                    </div>
                  </>
                ) : draggedItem.type === 'control' ? (
                  <>
                    <div className="w-8 h-8 bg-green-100 rounded-lg flex items-center justify-center">
                      <span className="text-lg">
                        {draggedItem.fieldType === 'text' ? '📝' :
                         draggedItem.fieldType === 'number' ? '🔢' :
                         draggedItem.fieldType === 'select' ? '📋' :
                         draggedItem.fieldType === 'checkbox' ? '☑️' : '📄'}
                      </span>
                    </div>
                    <div className="flex flex-col">
                      <span className="font-medium text-sm">New {draggedItem.fieldType} Field</span>
                      <span className="text-xs text-muted-foreground">Drop to add to form</span>
                    </div>
                  </>
                ) : draggedItem.type === 'field' ? (
                  <>
                    <div className="w-8 h-8 bg-orange-100 rounded-lg flex items-center justify-center">
                      <GripVertical className="h-4 w-4" />
                    </div>
                    <div className="flex flex-col">
                      <span className="font-medium text-sm">
                        {schema.fields.find(f => f.id === activeId)?.label}
                      </span>
                      <span className="text-xs text-muted-foreground">
                        {selectedFieldIds.length > 1 
                          ? `Moving ${selectedFieldIds.length} fields`
                          : 'Reordering field'
                        }
                      </span>
                      {schema.fields.find(f => f.id === activeId)?.unit && (
                        <Badge variant="outline" className="text-xs w-fit mt-1">
                          {schema.fields.find(f => f.id === activeId)?.unit}
                        </Badge>
                      )}
                    </div>
                  </>
                ) : null}
                
                {/* Drag indicator */}
                <div className="ml-auto">
                  <div className="flex flex-col gap-1">
                    <div className="w-1 h-1 bg-primary rounded-full"></div>
                    <div className="w-1 h-1 bg-primary rounded-full"></div>
                    <div className="w-1 h-1 bg-primary rounded-full"></div>
                  </div>
                </div>
              </div>
            </div>
          ) : null}
        </DragOverlay>
      </div>
    </DndContext>
  );
}

/**
 * URL: http://localhost:3000/admin/log-builder/[templateId]/edit
 * 
 * This page provides the main drag-and-drop interface for building form templates.
 * Features:
 * - Left: Palette with variables catalog and basic controls
 * - Center: Canvas with 12-grid system for layout
 * - Right: Inspector for field configuration
 * - Header: Save, publish, preview, and validation actions
 * - Full DnD support with visual feedback
 */