import React, { useCallback, useRef, useState, useEffect } from 'react';
import { useDroppable } from '@dnd-kit/core';
import { useSpring, animated } from '@react-spring/web';
import { cn } from '@/lib/utils';

export interface DynamicDropZoneProps {
  id: string;
  accepts: string[];
  onDrop?: (data: any) => void;
  isActive?: boolean;
  canDrop?: boolean;
  showPreview?: boolean;
  previewContent?: React.ReactNode;
  className?: string;
  children?: React.ReactNode;
  disabled?: boolean;
  'data-testid'?: string;
}

export function DynamicDropZone({
  id,
  accepts,
  onDrop,
  isActive = false,
  canDrop = true,
  showPreview = false,
  previewContent,
  className,
  children,
  disabled = false,
  'data-testid': testId = `dynamic-drop-zone-${id}`,
}: DynamicDropZoneProps) {
  const [isHovered, setIsHovered] = useState(false);
  const [isDragOver, setIsDragOver] = useState(false);
  const [selectedViaKeyboard, setSelectedViaKeyboard] = useState(false);
  const dropZoneRef = useRef<HTMLDivElement>(null);

  // @dnd-kit droppable hook
  const { isOver, setNodeRef, active } = useDroppable({
    id,
    disabled: disabled || !canDrop,
    data: {
      accepts,
    },
  });

  // Combine refs
  const combinedRef = useCallback((node: HTMLDivElement) => {
    dropZoneRef.current = node;
    setNodeRef(node);
  }, [setNodeRef]);

  // Animation for drop zone states
  const dropZoneSpring = useSpring({
    scale: isOver || isActive || selectedViaKeyboard ? 1.02 : 1,
    borderWidth: isOver || isActive ? 3 : 2,
    borderColor: 
      !canDrop || disabled ? '#e5e7eb' :
      isOver || isActive ? '#3b82f6' :
      '#d1d5db',
    backgroundColor: 
      !canDrop || disabled ? '#f9fafb' :
      isOver || isActive ? '#eff6ff' :
      'transparent',
    boxShadow: 
      isOver || isActive 
        ? '0 4px 12px rgba(59, 130, 246, 0.15)' 
        : '0 1px 3px rgba(0, 0, 0, 0.1)',
    config: { tension: 280, friction: 60 },
  });

  // Preview overlay animation
  const previewSpring = useSpring({
    opacity: (showPreview && (isOver || isActive)) ? 1 : 0,
    transform: (showPreview && (isOver || isActive)) 
      ? 'translateY(0px)' 
      : 'translateY(-10px)',
    config: { tension: 280, friction: 60 },
  });

  // Pulse animation for active state
  const pulseSpring = useSpring({
    opacity: isActive ? 0.6 : 0,
    config: { duration: 1000 },
    loop: isActive,
  });

  // Handle drag events
  useEffect(() => {
    setIsDragOver(isOver);
  }, [isOver]);

  // Handle keyboard interactions
  const handleKeyDown = useCallback((event: React.KeyboardEvent) => {
    if (disabled || !canDrop) return;

    switch (event.key) {
      case 'Enter':
      case ' ':
        event.preventDefault();
        setSelectedViaKeyboard(true);
        // Trigger selection state
        break;
      case 'Escape':
        setSelectedViaKeyboard(false);
        break;
    }
  }, [disabled, canDrop]);

  const handleKeyUp = useCallback((event: React.KeyboardEvent) => {
    if (event.key === 'Enter' || event.key === ' ') {
      setTimeout(() => setSelectedViaKeyboard(false), 150);
    }
  }, []);

  // Handle focus events
  const handleFocus = useCallback(() => {
    if (!disabled && canDrop) {
      setIsHovered(true);
    }
  }, [disabled, canDrop]);

  const handleBlur = useCallback(() => {
    setIsHovered(false);
    setSelectedViaKeyboard(false);
  }, []);

  // Determine drop zone state classes
  const getDropZoneClasses = useCallback(() => {
    return cn(
      'drop-zone',
      'relative',
      'min-h-16',
      'rounded-lg',
      'border-2',
      'border-dashed',
      'transition-all',
      'duration-200',
      'focus:outline-none',
      'focus:ring-2',
      'focus:ring-blue-500',
      'focus:ring-offset-2',
      {
        'drop-zone--active': isOver || isActive,
        'drop-zone--disabled': disabled || !canDrop,
        'drop-zone--hovered': isHovered,
        'cursor-pointer': canDrop && !disabled,
        'cursor-not-allowed': disabled || !canDrop,
        'bg-gray-50': disabled || !canDrop,
        'border-gray-300': disabled || !canDrop,
      },
      className
    );
  }, [isOver, isActive, disabled, canDrop, isHovered, className]);

  // Generate ARIA labels
  const getAriaLabel = useCallback(() => {
    if (disabled) return 'Disabled drop zone';
    if (!canDrop) return 'Drop not allowed';
    if (isOver || isActive) return 'Active drop zone';
    return `Drop zone accepting ${accepts.join(', ')}`;
  }, [disabled, canDrop, isOver, isActive, accepts]);

  return (
    <animated.div
      ref={combinedRef}
      data-testid={testId}
      className={getDropZoneClasses()}
      style={dropZoneSpring}
      tabIndex={disabled || !canDrop ? -1 : 0}
      role="button"
      aria-label={getAriaLabel()}
      aria-disabled={disabled || !canDrop}
      aria-selected={selectedViaKeyboard}
      aria-describedby={`${id}-description`}
      onKeyDown={handleKeyDown}
      onKeyUp={handleKeyUp}
      onFocus={handleFocus}
      onBlur={handleBlur}
      onMouseEnter={() => !disabled && canDrop && setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
      onDragOver={(e) => {
        e.preventDefault();
        if (canDrop && !disabled) {
          setIsDragOver(true);
        }
      }}
      onDragLeave={(e) => {
        e.preventDefault();
        // Only set drag over false if leaving the drop zone itself
        if (!dropZoneRef.current?.contains(e.relatedTarget as Node)) {
          setIsDragOver(false);
        }
      }}
      onDrop={(e) => {
        e.preventDefault();
        setIsDragOver(false);
        
        if (onDrop && canDrop && !disabled) {
          const data = e.dataTransfer?.getData('application/json');
          try {
            const parsedData = data ? JSON.parse(data) : null;
            onDrop(parsedData);
          } catch (error) {
            console.warn('Failed to parse drop data:', error);
            onDrop(null);
          }
        }
      }}
    >
      {/* Hidden description for screen readers */}
      <div id={`${id}-description`} className="sr-only">
        {disabled 
          ? 'This drop zone is disabled'
          : !canDrop
          ? 'Dropping is not allowed in this area'
          : `Drop ${accepts.join(' or ')} here`
        }
      </div>

      {/* Pulse animation overlay for active state */}
      {isActive && (
        <animated.div
          className="absolute inset-0 rounded-lg border-2 border-blue-400 pointer-events-none"
          style={pulseSpring}
        />
      )}

      {/* Content */}
      <div className="relative z-10 p-4">
        {children || (
          <div className="flex flex-col items-center justify-center text-center min-h-12">
            <div className="text-sm text-gray-500 mb-1">
              {disabled 
                ? 'Drop zone disabled'
                : !canDrop
                ? 'Drop not allowed'
                : isOver || isActive
                ? 'Release to drop here'
                : `Drop ${accepts.join(' or ')} here`
              }
            </div>
            {(isOver || isActive) && canDrop && !disabled && (
              <div className="text-xs text-blue-600">
                Compatible item detected
              </div>
            )}
          </div>
        )}
      </div>

      {/* Preview overlay */}
      {showPreview && (isOver || isActive) && canDrop && !disabled && (
        <animated.div
          data-testid="drop-zone-preview"
          className="drop-zone__preview absolute inset-0 bg-blue-50 bg-opacity-75 rounded-lg flex items-center justify-center z-20"
          style={previewSpring}
        >
          <div className="bg-white rounded-lg shadow-lg p-4 border-2 border-blue-200">
            {previewContent || (
              <div className="text-sm text-blue-700 font-medium">
                Preview: Item will be placed here
              </div>
            )}
          </div>
        </animated.div>
      )}
    </animated.div>
  );
}

// Higher-order component for enhanced drop zone with additional features
export interface EnhancedDropZoneProps extends DynamicDropZoneProps {
  allowMultiple?: boolean;
  maxItems?: number;
  currentItemCount?: number;
  validationRules?: Array<(item: any) => boolean | string>;
  onValidationError?: (errors: string[]) => void;
}

export function EnhancedDropZone({
  allowMultiple = true,
  maxItems,
  currentItemCount = 0,
  validationRules = [],
  onValidationError,
  onDrop,
  ...props
}: EnhancedDropZoneProps) {
  const handleEnhancedDrop = useCallback((data: any) => {
    const errors: string[] = [];

    // Check item limit
    if (maxItems && currentItemCount >= maxItems) {
      errors.push(`Maximum ${maxItems} items allowed`);
    }

    // Check if multiple items are allowed
    if (!allowMultiple && currentItemCount > 0) {
      errors.push('Only one item allowed');
    }

    // Run validation rules
    validationRules.forEach((rule, index) => {
      const result = rule(data);
      if (typeof result === 'string') {
        errors.push(result);
      } else if (result === false) {
        errors.push(`Validation rule ${index + 1} failed`);
      }
    });

    if (errors.length > 0) {
      onValidationError?.(errors);
      return;
    }

    onDrop?.(data);
  }, [
    allowMultiple,
    maxItems,
    currentItemCount,
    validationRules,
    onValidationError,
    onDrop
  ]);

  const canDrop = props.canDrop && 
    (!maxItems || currentItemCount < maxItems) &&
    (allowMultiple || currentItemCount === 0);

  return (
    <DynamicDropZone
      {...props}
      canDrop={canDrop}
      onDrop={handleEnhancedDrop}
    />
  );
}

export default DynamicDropZone;