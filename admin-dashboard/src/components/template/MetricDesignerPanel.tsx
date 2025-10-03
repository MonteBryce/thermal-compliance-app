'use client';

import { useState } from 'react';
import { DndContext, closestCenter, KeyboardSensor, PointerSensor, useSensor, useSensors } from '@dnd-kit/core';
import { arrayMove, SortableContext, sortableKeyboardCoordinates, verticalListSortingStrategy } from '@dnd-kit/sortable';
import { useSortable } from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Checkbox } from '@/components/ui/checkbox';
import { Badge } from '@/components/ui/badge';
import { 
  GripVertical, 
  Plus, 
  Edit, 
  Trash2, 
  Eye, 
  EyeOff,
  Thermometer,
  Gauge,
  Wind,
  Droplets,
  Clock,
  Hash,
  Percent,
  Calendar,
  Type,
  CheckSquare
} from 'lucide-react';
import { TemplateMetric } from '@/lib/types/template';

interface MetricDesignerPanelProps {
  metrics: TemplateMetric[];
  onMetricsChange: (metrics: TemplateMetric[]) => void;
  onAddMetric?: (metric: TemplateMetric) => void;
  onEditMetric?: (metric: TemplateMetric) => void;
  onDeleteMetric?: (metricKey: string) => void;
}

interface SortableMetricItemProps {
  metric: TemplateMetric;
  onToggleVisibility: (key: string) => void;
  onEdit: (metric: TemplateMetric) => void;
  onDelete: (key: string) => void;
}

function SortableMetricItem({ metric, onToggleVisibility, onEdit, onDelete }: SortableMetricItemProps) {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging
  } = useSortable({ id: metric.key });

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
    opacity: isDragging ? 0.5 : 1,
  };

  const getMetricIcon = (metric: TemplateMetric) => {
    const iconClass = "h-4 w-4";
    switch (metric.category) {
      case 'primary':
        return <Thermometer className={`${iconClass} text-red-400`} />;
      case 'flow':
        return <Wind className={`${iconClass} text-cyan-400`} />;
      case 'pressure':
        return <Gauge className={`${iconClass} text-blue-400`} />;
      case 'composition':
        return <Droplets className={`${iconClass} text-purple-400`} />;
      default:
        return <Clock className={`${iconClass} text-gray-400`} />;
    }
  };

  const getCategoryColor = (category?: string) => {
    switch (category) {
      case 'primary': return 'bg-red-600 text-white';
      case 'flow': return 'bg-cyan-600 text-white';
      case 'pressure': return 'bg-blue-600 text-white';
      case 'composition': return 'bg-purple-600 text-white';
      default: return 'bg-gray-600 text-white';
    }
  };

  return (
    <div
      ref={setNodeRef}
      style={style}
      className="flex items-center gap-3 p-3 bg-gray-800 rounded-lg border border-gray-700 hover:border-gray-600 transition-colors"
    >
      {/* Drag Handle */}
      <div 
        {...attributes} 
        {...listeners}
        className="cursor-grab active:cursor-grabbing p-1 hover:bg-gray-700 rounded"
      >
        <GripVertical className="h-4 w-4 text-gray-400" />
      </div>

      {/* Visibility Toggle */}
      <button
        onClick={() => onToggleVisibility(metric.key)}
        className="p-1 hover:bg-gray-700 rounded"
      >
        {metric.visible ? (
          <Eye className="h-4 w-4 text-green-400" />
        ) : (
          <EyeOff className="h-4 w-4 text-gray-500" />
        )}
      </button>

      {/* Metric Info */}
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2 mb-1">
          {getMetricIcon(metric)}
          <span className={`text-sm font-medium ${metric.visible ? 'text-white' : 'text-gray-500'}`}>
            {metric.label}
          </span>
          {metric.required && (
            <span className="text-red-400 text-xs">*</span>
          )}
        </div>
        <div className="flex items-center gap-2 text-xs text-gray-400">
          <Badge className={`text-xs ${getCategoryColor(metric.category)} border-0`}>
            {metric.category || 'other'}
          </Badge>
          {metric.unit && (
            <span className="text-orange-300">({metric.unit})</span>
          )}
          <span>Order: {metric.order}</span>
        </div>
      </div>

      {/* Actions */}
      <div className="flex items-center gap-1">
        <button
          onClick={() => onEdit(metric)}
          className="p-1 hover:bg-gray-700 rounded"
        >
          <Edit className="h-4 w-4 text-gray-400 hover:text-white" />
        </button>
        <button
          onClick={() => onDelete(metric.key)}
          className="p-1 hover:bg-gray-700 rounded"
        >
          <Trash2 className="h-4 w-4 text-gray-400 hover:text-red-400" />
        </button>
      </div>
    </div>
  );
}

interface MetricFormData {
  key: string;
  label: string;
  unit?: string;
  required: boolean;
  visible: boolean;
  category: 'primary' | 'flow' | 'pressure' | 'composition' | 'other';
  notes?: string;
}

function MetricDialog({ 
  metric, 
  isOpen, 
  onClose, 
  onSave,
  title = "Edit Metric"
}: {
  metric?: TemplateMetric;
  isOpen: boolean;
  onClose: () => void;
  onSave: (metric: TemplateMetric) => void;
  title?: string;
}) {
  const [formData, setFormData] = useState<MetricFormData>(() => ({
    key: metric?.key || '',
    label: metric?.label || '',
    unit: metric?.unit || '',
    required: metric?.required || false,
    visible: metric?.visible !== false,
    category: metric?.category || 'other',
    notes: metric?.notes || ''
  }));

  const handleSave = () => {
    if (!formData.key || !formData.label) return;

    const newMetric: TemplateMetric = {
      key: formData.key,
      label: formData.label,
      unit: formData.unit || undefined,
      required: formData.required,
      visible: formData.visible,
      category: formData.category,
      notes: formData.notes || undefined,
      order: metric?.order || 0
    };

    onSave(newMetric);
    onClose();
  };

  const getFieldTypeIcon = (type: string) => {
    switch (type) {
      case 'primary': return <Thermometer className="h-4 w-4" />;
      case 'flow': return <Wind className="h-4 w-4" />;
      case 'pressure': return <Gauge className="h-4 w-4" />;
      case 'composition': return <Droplets className="h-4 w-4" />;
      default: return <Hash className="h-4 w-4" />;
    }
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="bg-[#1E1E1E] border-gray-800 text-white">
        <DialogHeader>
          <DialogTitle className="text-white">{title}</DialogTitle>
        </DialogHeader>
        
        <div className="space-y-4">
          {/* Key */}
          <div>
            <Label className="text-gray-300">Key</Label>
            <Input
              value={formData.key}
              onChange={(e) => setFormData(prev => ({ ...prev, key: e.target.value }))}
              placeholder="metric_key"
              className="bg-gray-800 border-gray-700 text-white"
              disabled={!!metric} // Don't allow editing key for existing metrics
            />
          </div>

          {/* Label */}
          <div>
            <Label className="text-gray-300">Label</Label>
            <Input
              value={formData.label}
              onChange={(e) => setFormData(prev => ({ ...prev, label: e.target.value }))}
              placeholder="Metric Label"
              className="bg-gray-800 border-gray-700 text-white"
            />
          </div>

          {/* Unit */}
          <div>
            <Label className="text-gray-300">Unit (optional)</Label>
            <Input
              value={formData.unit}
              onChange={(e) => setFormData(prev => ({ ...prev, unit: e.target.value }))}
              placeholder="°F, PPM, BBL/HR, etc."
              className="bg-gray-800 border-gray-700 text-white"
            />
          </div>

          {/* Category */}
          <div>
            <Label className="text-gray-300">Category</Label>
            <Select 
              value={formData.category} 
              onValueChange={(value) => setFormData(prev => ({ ...prev, category: value as any }))}
            >
              <SelectTrigger className="bg-gray-800 border-gray-700 text-white">
                <SelectValue />
              </SelectTrigger>
              <SelectContent className="bg-gray-800 border-gray-700">
                <SelectItem value="primary" className="text-white">
                  <div className="flex items-center gap-2">
                    <Thermometer className="h-4 w-4 text-red-400" />
                    Primary
                  </div>
                </SelectItem>
                <SelectItem value="flow" className="text-white">
                  <div className="flex items-center gap-2">
                    <Wind className="h-4 w-4 text-cyan-400" />
                    Flow
                  </div>
                </SelectItem>
                <SelectItem value="pressure" className="text-white">
                  <div className="flex items-center gap-2">
                    <Gauge className="h-4 w-4 text-blue-400" />
                    Pressure
                  </div>
                </SelectItem>
                <SelectItem value="composition" className="text-white">
                  <div className="flex items-center gap-2">
                    <Droplets className="h-4 w-4 text-purple-400" />
                    Composition
                  </div>
                </SelectItem>
                <SelectItem value="other" className="text-white">
                  <div className="flex items-center gap-2">
                    <Clock className="h-4 w-4 text-gray-400" />
                    Other
                  </div>
                </SelectItem>
              </SelectContent>
            </Select>
          </div>

          {/* Toggles */}
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <Label className="text-gray-300">Required</Label>
              <Switch
                checked={formData.required}
                onCheckedChange={(checked) => setFormData(prev => ({ ...prev, required: checked }))}
              />
            </div>
            <div className="flex items-center justify-between">
              <Label className="text-gray-300">Visible</Label>
              <Switch
                checked={formData.visible}
                onCheckedChange={(checked) => setFormData(prev => ({ ...prev, visible: checked }))}
              />
            </div>
          </div>

          {/* Notes */}
          <div>
            <Label className="text-gray-300">Notes (optional)</Label>
            <Input
              value={formData.notes}
              onChange={(e) => setFormData(prev => ({ ...prev, notes: e.target.value }))}
              placeholder="Additional notes about this metric"
              className="bg-gray-800 border-gray-700 text-white"
            />
          </div>

          {/* Save Button */}
          <div className="flex justify-end gap-2 pt-4">
            <Button 
              variant="outline" 
              onClick={onClose}
              className="border-gray-600 text-gray-300 hover:bg-gray-800"
            >
              Cancel
            </Button>
            <Button 
              onClick={handleSave}
              disabled={!formData.key || !formData.label}
              className="bg-orange-600 hover:bg-orange-700 text-white"
            >
              Save Metric
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}

export function MetricDesignerPanel({ 
  metrics, 
  onMetricsChange, 
  onAddMetric, 
  onEditMetric, 
  onDeleteMetric 
}: MetricDesignerPanelProps) {
  const [editingMetric, setEditingMetric] = useState<TemplateMetric | null>(null);
  const [showAddDialog, setShowAddDialog] = useState(false);
  const [showAllMetrics, setShowAllMetrics] = useState(false);

  const sensors = useSensors(
    useSensor(PointerSensor),
    useSensor(KeyboardSensor, {
      coordinateGetter: sortableKeyboardCoordinates,
    })
  );

  const sortedMetrics = [...metrics].sort((a, b) => a.order - b.order);
  const visibleMetrics = showAllMetrics ? sortedMetrics : sortedMetrics.filter(m => m.visible);

  const handleDragEnd = (event: any) => {
    const { active, over } = event;

    if (active.id !== over.id) {
      const oldIndex = sortedMetrics.findIndex(m => m.key === active.id);
      const newIndex = sortedMetrics.findIndex(m => m.key === over.id);
      
      const reorderedMetrics = arrayMove(sortedMetrics, oldIndex, newIndex);
      
      // Update order values
      const updatedMetrics = reorderedMetrics.map((metric, index) => ({
        ...metric,
        order: index + 1
      }));

      onMetricsChange(updatedMetrics);
    }
  };

  const handleToggleVisibility = (key: string) => {
    const updatedMetrics = metrics.map(metric => 
      metric.key === key 
        ? { ...metric, visible: !metric.visible }
        : metric
    );
    onMetricsChange(updatedMetrics);
  };

  const handleEditMetric = (metric: TemplateMetric) => {
    const updatedMetrics = metrics.map(m => 
      m.key === metric.key ? metric : m
    );
    onMetricsChange(updatedMetrics);
    setEditingMetric(null);
    onEditMetric?.(metric);
  };

  const handleAddMetric = (metric: TemplateMetric) => {
    const newMetric = {
      ...metric,
      order: Math.max(...metrics.map(m => m.order), 0) + 1
    };
    onMetricsChange([...metrics, newMetric]);
    setShowAddDialog(false);
    onAddMetric?.(newMetric);
  };

  const handleDeleteMetric = (key: string) => {
    const updatedMetrics = metrics.filter(m => m.key !== key);
    onMetricsChange(updatedMetrics);
    onDeleteMetric?.(key);
  };

  const visibleCount = metrics.filter(m => m.visible).length;
  const totalCount = metrics.length;

  return (
    <Card className="bg-[#1E1E1E] border-gray-800 h-full">
      <CardHeader>
        <div className="flex items-center justify-between">
          <div>
            <CardTitle className="text-white">Metrics Designer</CardTitle>
            <p className="text-gray-400 text-sm mt-1">
              {visibleCount} of {totalCount} metrics visible
            </p>
          </div>
          <Button
            onClick={() => setShowAddDialog(true)}
            size="sm"
            className="bg-orange-600 hover:bg-orange-700 text-white"
          >
            <Plus className="h-4 w-4 mr-1" />
            Add Metric
          </Button>
        </div>
      </CardHeader>

      <CardContent className="space-y-4">
        {/* Controls */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Checkbox
              id="show-all"
              checked={showAllMetrics}
              onCheckedChange={setShowAllMetrics}
            />
            <Label htmlFor="show-all" className="text-gray-300 text-sm">
              Show hidden metrics
            </Label>
          </div>
          <Badge className="bg-blue-600 text-white border-0">
            Drag to reorder
          </Badge>
        </div>

        {/* Metrics List */}
        <div className="space-y-2 max-h-[600px] overflow-y-auto">
          <DndContext
            sensors={sensors}
            collisionDetection={closestCenter}
            onDragEnd={handleDragEnd}
          >
            <SortableContext 
              items={visibleMetrics.map(m => m.key)} 
              strategy={verticalListSortingStrategy}
            >
              {visibleMetrics.map((metric) => (
                <SortableMetricItem
                  key={metric.key}
                  metric={metric}
                  onToggleVisibility={handleToggleVisibility}
                  onEdit={setEditingMetric}
                  onDelete={handleDeleteMetric}
                />
              ))}
            </SortableContext>
          </DndContext>

          {visibleMetrics.length === 0 && (
            <div className="text-center py-8 text-gray-500">
              <Clock className="h-12 w-12 mx-auto mb-4 text-gray-600" />
              <p>No metrics to display</p>
              <p className="text-sm">
                {showAllMetrics ? 'No metrics defined' : 'All metrics are hidden'}
              </p>
            </div>
          )}
        </div>

        {/* Category Summary */}
        <div className="border-t border-gray-700 pt-4">
          <h4 className="text-sm font-medium text-gray-300 mb-2">Visible by Category</h4>
          <div className="grid grid-cols-2 gap-2 text-xs">
            {['primary', 'flow', 'pressure', 'composition', 'other'].map(category => {
              const count = metrics.filter(m => m.visible && (m.category || 'other') === category).length;
              return (
                <div key={category} className="flex justify-between text-gray-400">
                  <span className="capitalize">{category}:</span>
                  <span>{count}</span>
                </div>
              );
            })}
          </div>
        </div>
      </CardContent>

      {/* Edit Dialog */}
      <MetricDialog
        metric={editingMetric || undefined}
        isOpen={editingMetric !== null}
        onClose={() => setEditingMetric(null)}
        onSave={handleEditMetric}
        title="Edit Metric"
      />

      {/* Add Dialog */}
      <MetricDialog
        isOpen={showAddDialog}
        onClose={() => setShowAddDialog(false)}
        onSave={handleAddMetric}
        title="Add New Metric"
      />
    </Card>
  );
}