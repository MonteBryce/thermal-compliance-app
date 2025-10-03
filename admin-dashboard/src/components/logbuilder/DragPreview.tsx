import React, { useEffect, useState } from 'react';
import { useDraggable, DragOverlay } from '@dnd-kit/core';
import { useSpring, animated } from '@react-spring/web';
import { 
  Type, 
  Hash, 
  Calendar, 
  ToggleLeft, 
  List, 
  FileText,
  ChevronDown,
  Image,
  Mail,
  Phone,
  MapPin,
  Clock,
  Link,
  Calculator
} from 'lucide-react';
import { cn } from '@/lib/utils';

export type FieldType = 
  | 'text' 
  | 'number' 
  | 'date' 
  | 'boolean' 
  | 'select' 
  | 'textarea'
  | 'email'
  | 'phone'
  | 'url'
  | 'time'
  | 'datetime'
  | 'image'
  | 'location'
  | 'calculation';

interface FieldTypeConfig {
  icon: React.ElementType;
  label: string;
  color: string;
  bgColor: string;
  description: string;
}

const fieldTypeConfigs: Record<FieldType, FieldTypeConfig> = {
  text: {
    icon: Type,
    label: 'Text',
    color: 'text-blue-600',
    bgColor: 'bg-blue-50',
    description: 'Single line text input'
  },
  number: {
    icon: Hash,
    label: 'Number',
    color: 'text-green-600',
    bgColor: 'bg-green-50',
    description: 'Numeric input with validation'
  },
  date: {
    icon: Calendar,
    label: 'Date',
    color: 'text-purple-600',
    bgColor: 'bg-purple-50',
    description: 'Date picker input'
  },
  boolean: {
    icon: ToggleLeft,
    label: 'Boolean',
    color: 'text-orange-600',
    bgColor: 'bg-orange-50',
    description: 'Yes/No toggle'
  },
  select: {
    icon: ChevronDown,
    label: 'Select',
    color: 'text-indigo-600',
    bgColor: 'bg-indigo-50',
    description: 'Dropdown selection'
  },
  textarea: {
    icon: FileText,
    label: 'Text Area',
    color: 'text-teal-600',
    bgColor: 'bg-teal-50',
    description: 'Multi-line text input'
  },
  email: {
    icon: Mail,
    label: 'Email',
    color: 'text-pink-600',
    bgColor: 'bg-pink-50',
    description: 'Email address input'
  },
  phone: {
    icon: Phone,
    label: 'Phone',
    color: 'text-cyan-600',
    bgColor: 'bg-cyan-50',
    description: 'Phone number input'
  },
  url: {
    icon: Link,
    label: 'URL',
    color: 'text-gray-600',
    bgColor: 'bg-gray-50',
    description: 'Website URL input'
  },
  time: {
    icon: Clock,
    label: 'Time',
    color: 'text-yellow-600',
    bgColor: 'bg-yellow-50',
    description: 'Time picker input'
  },
  datetime: {
    icon: Calendar,
    label: 'Date & Time',
    color: 'text-purple-600',
    bgColor: 'bg-purple-50',
    description: 'Date and time picker'
  },
  image: {
    icon: Image,
    label: 'Image',
    color: 'text-emerald-600',
    bgColor: 'bg-emerald-50',
    description: 'Image upload field'
  },
  location: {
    icon: MapPin,
    label: 'Location',
    color: 'text-red-600',
    bgColor: 'bg-red-50',
    description: 'Location picker'
  },
  calculation: {
    icon: Calculator,
    label: 'Calculation',
    color: 'text-slate-600',
    bgColor: 'bg-slate-50',
    description: 'Calculated field'
  }
};

export interface DragPreviewProps {
  fieldType: FieldType;
  fieldLabel?: string;
  isDragging?: boolean;
  rotation?: number;
  scale?: number;
  opacity?: number;
  className?: string;
  showDescription?: boolean;
  'data-testid'?: string;
}

export function DragPreview({
  fieldType,
  fieldLabel,
  isDragging = false,
  rotation = 0,
  scale = 1,
  opacity = 1,
  className,
  showDescription = true,
  'data-testid': testId = 'drag-preview'
}: DragPreviewProps) {
  const [isClient, setIsClient] = useState(false);
  const config = fieldTypeConfigs[fieldType];
  const Icon = config.icon;

  useEffect(() => {
    setIsClient(true);
  }, []);

  // Animation spring for drag effects
  const springProps = useSpring({
    transform: `scale(${isDragging ? scale * 1.05 : scale}) rotate(${isDragging ? rotation : 0}deg)`,
    opacity: isDragging ? opacity * 0.8 : opacity,
    config: { tension: 300, friction: 25 }
  });

  // Accessibility announcement
  useEffect(() => {
    if (isDragging && isClient) {
      const announcement = document.createElement('div');
      announcement.setAttribute('role', 'status');
      announcement.setAttribute('aria-live', 'polite');
      announcement.className = 'sr-only';
      announcement.textContent = `Dragging ${fieldLabel || config.label} field`;
      document.body.appendChild(announcement);
      
      return () => {
        if (announcement.parentNode) {
          announcement.parentNode.removeChild(announcement);
        }
      };
    }
  }, [isDragging, fieldLabel, config.label, isClient]);

  return (
    <animated.div
      style={springProps}
      className={cn(
        'drag-preview',
        'flex items-center gap-3 p-3 rounded-lg border-2',
        'transition-all duration-200',
        isDragging ? 'shadow-2xl cursor-grabbing' : 'shadow-md cursor-grab',
        config.bgColor,
        `border-${config.color.replace('text-', '')}`,
        isDragging && 'drag-preview--active',
        className
      )}
      data-testid={testId}
      role="img"
      aria-label={`${fieldLabel || config.label} field preview`}
    >
      <div className={cn(
        'drag-preview__icon',
        'p-2 rounded',
        config.bgColor,
        config.color
      )}>
        <Icon className="w-5 h-5" />
      </div>
      
      <div className="drag-preview__content flex-1">
        <div className={cn(
          'drag-preview__label',
          'font-medium text-sm',
          config.color
        )}>
          {fieldLabel || config.label}
        </div>
        {showDescription && (
          <div className="drag-preview__description text-xs text-gray-500 mt-0.5">
            {config.description}
          </div>
        )}
      </div>

      {isDragging && (
        <div className="drag-preview__badge ml-2">
          <span className={cn(
            'inline-flex items-center px-2 py-0.5 rounded text-xs font-medium',
            config.bgColor,
            config.color
          )}>
            Dragging
          </span>
        </div>
      )}
    </animated.div>
  );
}

export interface DragOverlayPreviewProps {
  activeId: string | null;
  activeData?: any;
  className?: string;
}

export function DragOverlayPreview({
  activeId,
  activeData,
  className
}: DragOverlayPreviewProps) {
  if (!activeId || !activeData) return null;

  return (
    <DragOverlay>
      <DragPreview
        fieldType={activeData.fieldType || 'text'}
        fieldLabel={activeData.label}
        isDragging={true}
        rotation={3}
        scale={1.1}
        opacity={0.9}
        className={className}
      />
    </DragOverlay>
  );
}

// Hook for using drag preview with @dnd-kit
export function useDragPreview(fieldType: FieldType, fieldLabel?: string) {
  const [isDragging, setIsDragging] = useState(false);
  
  const { attributes, listeners, setNodeRef, transform, isDragging: dndIsDragging } = useDraggable({
    id: `${fieldType}-${fieldLabel || 'field'}`,
    data: {
      fieldType,
      label: fieldLabel
    }
  });

  useEffect(() => {
    setIsDragging(dndIsDragging);
  }, [dndIsDragging]);

  return {
    dragProps: {
      ref: setNodeRef,
      ...attributes,
      ...listeners
    },
    isDragging,
    previewProps: {
      fieldType,
      fieldLabel,
      isDragging
    }
  };
}