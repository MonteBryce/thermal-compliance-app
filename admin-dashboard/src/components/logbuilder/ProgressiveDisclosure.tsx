import React, { useState, useRef, useCallback, useEffect } from 'react';
import { useSpring, animated } from '@react-spring/web';
import { ChevronDown, ChevronRight, Settings, Info, HelpCircle, Eye, EyeOff } from 'lucide-react';
import { cn } from '@/lib/utils';

export type DisclosureLevel = 1 | 2 | 3 | 4 | 5;
export type DisclosureVariant = 'default' | 'card' | 'sidebar' | 'toolbar' | 'contextual';

export interface ProgressiveDisclosureProps {
  title: string;
  level?: DisclosureLevel;
  variant?: DisclosureVariant;
  defaultExpanded?: boolean;
  disabled?: boolean;
  icon?: React.ComponentType<{ size?: number; className?: string }>;
  badge?: string | number;
  subtitle?: string;
  children: React.ReactNode;
  className?: string;
  headerClassName?: string;
  contentClassName?: string;
  onToggle?: (expanded: boolean) => void;
  onFocus?: () => void;
  onBlur?: () => void;
  'data-testid'?: string;
}

const levelConfig = {
  1: { fontSize: 'text-lg', fontWeight: 'font-semibold', padding: 'p-4', spacing: 'space-y-4' },
  2: { fontSize: 'text-base', fontWeight: 'font-medium', padding: 'p-3', spacing: 'space-y-3' },
  3: { fontSize: 'text-sm', fontWeight: 'font-medium', padding: 'p-2', spacing: 'space-y-2' },
  4: { fontSize: 'text-sm', fontWeight: 'font-normal', padding: 'p-2', spacing: 'space-y-2' },
  5: { fontSize: 'text-xs', fontWeight: 'font-normal', padding: 'p-1', spacing: 'space-y-1' },
} as const;

const variantConfig = {
  default: {
    container: 'border border-gray-200 rounded-lg bg-white shadow-sm',
    header: 'hover:bg-gray-50 border-b border-gray-100',
    content: 'bg-white',
  },
  card: {
    container: 'bg-white rounded-xl border border-gray-100 shadow-md hover:shadow-lg transition-shadow',
    header: 'hover:bg-gray-50 rounded-t-xl',
    content: 'bg-gray-50 rounded-b-xl',
  },
  sidebar: {
    container: 'bg-gray-900 text-white rounded-lg',
    header: 'hover:bg-gray-800',
    content: 'bg-gray-800',
  },
  toolbar: {
    container: 'bg-blue-600 text-white rounded-lg shadow-lg',
    header: 'hover:bg-blue-700',
    content: 'bg-blue-50 text-gray-900',
  },
  contextual: {
    container: 'border-l-4 border-blue-500 bg-blue-50 rounded-r-lg',
    header: 'hover:bg-blue-100',
    content: 'bg-white border-l-4 border-blue-200',
  },
} as const;

export function ProgressiveDisclosure({
  title,
  level = 1,
  variant = 'default',
  defaultExpanded = false,
  disabled = false,
  icon: Icon,
  badge,
  subtitle,
  children,
  className,
  headerClassName,
  contentClassName,
  onToggle,
  onFocus,
  onBlur,
  'data-testid': testId = 'progressive-disclosure',
}: ProgressiveDisclosureProps) {
  const [isExpanded, setIsExpanded] = useState(defaultExpanded);
  const [isFocused, setIsFocused] = useState(false);
  const [contentHeight, setContentHeight] = useState(0);
  const contentRef = useRef<HTMLDivElement>(null);
  const buttonRef = useRef<HTMLButtonElement>(null);
  const uniqueId = useRef(`disclosure-${Math.random().toString(36).substr(2, 9)}`);

  const levelStyles = levelConfig[level];
  const variantStyles = variantConfig[variant];

  // Measure content height for smooth animations
  useEffect(() => {
    if (contentRef.current) {
      const height = contentRef.current.scrollHeight;
      setContentHeight(height);
    }
  }, [children, isExpanded]);

  // Spring animation for content expansion
  const contentSpring = useSpring({
    height: isExpanded ? contentHeight : 0,
    opacity: isExpanded ? 1 : 0,
    config: { tension: 280, friction: 60 },
  });

  // Spring animation for chevron rotation
  const chevronSpring = useSpring({
    transform: isExpanded ? 'rotate(90deg)' : 'rotate(0deg)',
    config: { tension: 280, friction: 60 },
  });

  // Spring animation for header hover/focus states
  const headerSpring = useSpring({
    scale: isFocused ? 1.01 : 1,
    config: { tension: 280, friction: 60 },
  });

  // Handle toggle
  const handleToggle = useCallback((event: React.MouseEvent | React.KeyboardEvent) => {
    event.preventDefault();
    
    if (disabled) return;

    const newExpanded = !isExpanded;
    setIsExpanded(newExpanded);
    onToggle?.(newExpanded);
  }, [isExpanded, disabled, onToggle]);

  // Handle keyboard navigation
  const handleKeyDown = useCallback((event: React.KeyboardEvent) => {
    if (disabled) return;

    switch (event.key) {
      case 'Enter':
      case ' ':
        handleToggle(event);
        break;
      case 'Escape':
        if (isExpanded) {
          setIsExpanded(false);
          onToggle?.(false);
        }
        break;
      case 'ArrowDown':
        if (!isExpanded) {
          event.preventDefault();
          setIsExpanded(true);
          onToggle?.(true);
        }
        break;
      case 'ArrowUp':
        if (isExpanded) {
          event.preventDefault();
          setIsExpanded(false);
          onToggle?.(false);
        }
        break;
    }
  }, [disabled, isExpanded, handleToggle, onToggle]);

  // Handle focus events
  const handleFocus = useCallback(() => {
    if (!disabled) {
      setIsFocused(true);
      onFocus?.();
    }
  }, [disabled, onFocus]);

  const handleBlur = useCallback(() => {
    setIsFocused(false);
    onBlur?.();
  }, [onBlur]);

  return (
    <div
      data-testid={testId}
      className={cn(
        'progressive-disclosure',
        variantStyles.container,
        levelStyles.spacing,
        {
          'opacity-50 cursor-not-allowed': disabled,
          'disclosure--expanded': isExpanded,
          'disclosure--focused': isFocused,
        },
        className
      )}
    >
      {/* Header */}
      <animated.button
        ref={buttonRef}
        type="button"
        className={cn(
          'disclosure-header',
          'w-full',
          'flex',
          'items-center',
          'justify-between',
          'text-left',
          'transition-colors',
          'duration-200',
          'focus:outline-none',
          'focus:ring-2',
          'focus:ring-blue-500',
          'focus:ring-offset-2',
          levelStyles.padding,
          levelStyles.fontSize,
          levelStyles.fontWeight,
          variantStyles.header,
          {
            'cursor-not-allowed': disabled,
            'cursor-pointer': !disabled,
            'rounded-lg': !isExpanded,
            'rounded-t-lg': isExpanded,
          },
          headerClassName
        )}
        style={headerSpring}
        onClick={handleToggle}
        onKeyDown={handleKeyDown}
        onFocus={handleFocus}
        onBlur={handleBlur}
        disabled={disabled}
        aria-expanded={isExpanded}
        aria-controls={`${uniqueId.current}-content`}
        aria-describedby={subtitle ? `${uniqueId.current}-subtitle` : undefined}
        id={`${uniqueId.current}-trigger`}
      >
        <div className="flex items-center gap-3 min-w-0 flex-1">
          {/* Icon */}
          {Icon && (
            <div className="flex-shrink-0">
              <Icon 
                size={level === 1 ? 20 : level === 2 ? 18 : 16} 
                className="text-current" 
              />
            </div>
          )}

          {/* Title and subtitle */}
          <div className="min-w-0 flex-1">
            <div className="flex items-center gap-2">
              <span className="truncate">{title}</span>
              {badge && (
                <span className={cn(
                  'inline-flex',
                  'items-center',
                  'px-2',
                  'py-0.5',
                  'rounded-full',
                  'text-xs',
                  'font-medium',
                  'bg-blue-100',
                  'text-blue-800'
                )}>
                  {badge}
                </span>
              )}
            </div>
            {subtitle && (
              <p 
                id={`${uniqueId.current}-subtitle`}
                className="text-xs text-gray-500 mt-1"
              >
                {subtitle}
              </p>
            )}
          </div>
        </div>

        {/* Chevron */}
        <div className="flex-shrink-0 ml-2">
          <animated.div style={chevronSpring}>
            <ChevronRight 
              size={level === 1 ? 20 : level === 2 ? 18 : 16} 
              className="text-gray-400" 
            />
          </animated.div>
        </div>
      </animated.button>

      {/* Content */}
      <animated.div
        style={{
          ...contentSpring,
          overflow: 'hidden',
        }}
        className={cn(
          'disclosure-content',
          {
            'disclosure--expanding': isExpanded && contentHeight > 0,
            'disclosure--collapsing': !isExpanded,
          }
        )}
      >
        <div
          ref={contentRef}
          data-testid="disclosure-content"
          id={`${uniqueId.current}-content`}
          role="region"
          aria-labelledby={`${uniqueId.current}-trigger`}
          className={cn(
            levelStyles.padding,
            variantStyles.content,
            'rounded-b-lg',
            contentClassName
          )}
        >
          {children}
        </div>
      </animated.div>
    </div>
  );
}

// Contextual toolbar that appears based on user context
export interface ContextualToolbarProps {
  isVisible: boolean;
  position?: 'top' | 'bottom' | 'left' | 'right';
  tools: Array<{
    id: string;
    label: string;
    icon: React.ComponentType<{ size?: number; className?: string }>;
    action: () => void;
    disabled?: boolean;
    badge?: string | number;
  }>;
  className?: string;
}

export function ContextualToolbar({
  isVisible,
  position = 'top',
  tools,
  className,
}: ContextualToolbarProps) {
  const toolbarSpring = useSpring({
    opacity: isVisible ? 1 : 0,
    transform: isVisible 
      ? 'translateY(0px) scale(1)' 
      : position === 'top'
      ? 'translateY(-10px) scale(0.95)'
      : 'translateY(10px) scale(0.95)',
    config: { tension: 280, friction: 60 },
  });

  const positionClasses = {
    top: 'top-0 left-1/2 transform -translate-x-1/2 -translate-y-full',
    bottom: 'bottom-0 left-1/2 transform -translate-x-1/2 translate-y-full',
    left: 'left-0 top-1/2 transform -translate-x-full -translate-y-1/2',
    right: 'right-0 top-1/2 transform translate-x-full -translate-y-1/2',
  };

  return (
    <animated.div
      style={{
        ...toolbarSpring,
        pointerEvents: isVisible ? 'auto' : 'none',
      }}
      className={cn(
        'contextual-toolbar',
        'absolute',
        'z-50',
        'bg-white',
        'border',
        'border-gray-200',
        'rounded-lg',
        'shadow-lg',
        'p-1',
        'flex',
        'gap-1',
        positionClasses[position],
        className
      )}
    >
      {tools.map((tool) => (
        <button
          key={tool.id}
          type="button"
          className={cn(
            'relative',
            'flex',
            'items-center',
            'gap-2',
            'px-3',
            'py-2',
            'text-sm',
            'font-medium',
            'text-gray-700',
            'rounded-md',
            'hover:bg-gray-100',
            'focus:outline-none',
            'focus:ring-2',
            'focus:ring-blue-500',
            'transition-colors',
            'duration-200',
            {
              'opacity-50 cursor-not-allowed': tool.disabled,
              'cursor-pointer': !tool.disabled,
            }
          )}
          onClick={tool.action}
          disabled={tool.disabled}
          title={tool.label}
        >
          <tool.icon size={16} className="flex-shrink-0" />
          <span className="hidden sm:inline">{tool.label}</span>
          {tool.badge && (
            <span className="absolute -top-1 -right-1 bg-red-500 text-white text-xs rounded-full w-5 h-5 flex items-center justify-center">
              {tool.badge}
            </span>
          )}
        </button>
      ))}
    </animated.div>
  );
}

// Smart panel that adapts content based on selection
export interface SmartPanelProps {
  selectedItem?: {
    id: string;
    type: string;
    name: string;
    data: any;
  };
  panels: Record<string, React.ComponentType<{ data: any }>>;
  emptyState?: React.ReactNode;
  className?: string;
}

export function SmartPanel({
  selectedItem,
  panels,
  emptyState,
  className,
}: SmartPanelProps) {
  const panelSpring = useSpring({
    opacity: selectedItem ? 1 : 0.5,
    transform: selectedItem ? 'scale(1)' : 'scale(0.98)',
    config: { tension: 280, friction: 60 },
  });

  const PanelComponent = selectedItem ? panels[selectedItem.type] : null;

  return (
    <animated.div
      style={panelSpring}
      className={cn(
        'smart-panel',
        'bg-white',
        'border',
        'border-gray-200',
        'rounded-lg',
        'p-4',
        className
      )}
    >
      {selectedItem && PanelComponent ? (
        <div>
          <div className="mb-4 pb-2 border-b border-gray-100">
            <h3 className="text-lg font-semibold text-gray-900">
              {selectedItem.name}
            </h3>
            <p className="text-sm text-gray-500 capitalize">
              {selectedItem.type}
            </p>
          </div>
          <PanelComponent data={selectedItem.data} />
        </div>
      ) : (
        emptyState || (
          <div className="flex flex-col items-center justify-center py-12 text-gray-500">
            <Settings size={48} className="mb-4 opacity-50" />
            <p className="text-lg font-medium mb-2">No Item Selected</p>
            <p className="text-sm text-center">
              Select an item to view its properties and options
            </p>
          </div>
        )
      )}
    </animated.div>
  );
}

// Accordion group for managing multiple disclosures
export interface AccordionGroupProps {
  allowMultiple?: boolean;
  children: React.ReactElement<ProgressiveDisclosureProps>[];
  className?: string;
}

export function AccordionGroup({
  allowMultiple = false,
  children,
  className,
}: AccordionGroupProps) {
  const [expandedItems, setExpandedItems] = useState<Set<string>>(new Set());

  const handleToggle = useCallback((index: number, expanded: boolean) => {
    setExpandedItems(prev => {
      const newSet = new Set(prev);
      const key = `item-${index}`;
      
      if (expanded) {
        if (!allowMultiple) {
          newSet.clear();
        }
        newSet.add(key);
      } else {
        newSet.delete(key);
      }
      
      return newSet;
    });
  }, [allowMultiple]);

  return (
    <div className={cn('accordion-group', 'space-y-2', className)}>
      {React.Children.map(children, (child, index) => {
        const key = `item-${index}`;
        const isExpanded = expandedItems.has(key);
        
        return React.cloneElement(child, {
          defaultExpanded: isExpanded,
          onToggle: (expanded: boolean) => {
            handleToggle(index, expanded);
            child.props.onToggle?.(expanded);
          },
        });
      })}
    </div>
  );
}

export default ProgressiveDisclosure;