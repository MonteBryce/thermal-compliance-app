import React, { useEffect, useState, useRef, useCallback } from 'react';
import { useSpring, animated } from '@react-spring/web';
import { 
  Copy, 
  Trash2, 
  Edit3, 
  Settings,
  Move,
  Lock,
  Unlock,
  Eye,
  EyeOff,
  MoreVertical,
  Layers,
  Link2,
  Unlink,
  ChevronUp,
  ChevronDown
} from 'lucide-react';
import { cn } from '@/lib/utils';
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from '@/components/ui/tooltip';

export interface ToolbarAction {
  id: string;
  label: string;
  icon: React.ElementType;
  shortcut?: string;
  onClick: () => void;
  disabled?: boolean;
  hidden?: boolean;
  destructive?: boolean;
}

export interface ContextAwareToolbarProps {
  selectedFieldId?: string | null;
  selectedFieldType?: string;
  position?: { x: number; y: number } | null;
  actions?: ToolbarAction[];
  showDefaultActions?: boolean;
  floating?: boolean;
  responsive?: boolean;
  onDuplicate?: () => void;
  onDelete?: () => void;
  onEdit?: () => void;
  onSettings?: () => void;
  onMove?: () => void;
  onToggleLock?: (locked: boolean) => void;
  onToggleVisibility?: (visible: boolean) => void;
  className?: string;
  'data-testid'?: string;
}

const defaultActions: ToolbarAction[] = [
  {
    id: 'duplicate',
    label: 'Duplicate',
    icon: Copy,
    shortcut: 'Ctrl+D',
    onClick: () => {}
  },
  {
    id: 'edit',
    label: 'Edit',
    icon: Edit3,
    shortcut: 'Enter',
    onClick: () => {}
  },
  {
    id: 'settings',
    label: 'Settings',
    icon: Settings,
    shortcut: 'Ctrl+,',
    onClick: () => {}
  },
  {
    id: 'delete',
    label: 'Delete',
    icon: Trash2,
    shortcut: 'Delete',
    onClick: () => {},
    destructive: true
  }
];

export function ContextAwareToolbar({
  selectedFieldId,
  selectedFieldType,
  position,
  actions = defaultActions,
  showDefaultActions = true,
  floating = true,
  responsive = true,
  onDuplicate,
  onDelete,
  onEdit,
  onSettings,
  onMove,
  onToggleLock,
  onToggleVisibility,
  className,
  'data-testid': testId = 'context-toolbar'
}: ContextAwareToolbarProps) {
  const [isVisible, setIsVisible] = useState(false);
  const [isCompact, setIsCompact] = useState(false);
  const [isLocked, setIsLocked] = useState(false);
  const [isFieldVisible, setIsFieldVisible] = useState(true);
  const toolbarRef = useRef<HTMLDivElement>(null);

  // Calculate toolbar position
  const calculatePosition = useCallback(() => {
    if (!position || !toolbarRef.current) return { x: 0, y: 0 };
    
    const toolbar = toolbarRef.current;
    const rect = toolbar.getBoundingClientRect();
    const viewportWidth = window.innerWidth;
    const viewportHeight = window.innerHeight;
    
    let x = position.x;
    let y = position.y - rect.height - 10; // Position above by default
    
    // Adjust if toolbar would go off-screen
    if (x + rect.width > viewportWidth) {
      x = viewportWidth - rect.width - 10;
    }
    if (x < 10) {
      x = 10;
    }
    if (y < 10) {
      y = position.y + 40; // Position below if no room above
    }
    
    return { x, y };
  }, [position]);

  // Animation spring
  const springProps = useSpring({
    opacity: isVisible ? 1 : 0,
    transform: isVisible ? 'scale(1) translateY(0px)' : 'scale(0.95) translateY(-10px)',
    config: { tension: 300, friction: 25 }
  });

  // Show/hide toolbar based on selection
  useEffect(() => {
    setIsVisible(!!selectedFieldId && !!position);
  }, [selectedFieldId, position]);

  // Handle responsive behavior
  useEffect(() => {
    if (!responsive) return;
    
    const handleResize = () => {
      setIsCompact(window.innerWidth < 640);
    };
    
    handleResize();
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, [responsive]);

  // Keyboard shortcuts
  useEffect(() => {
    if (!selectedFieldId) return;
    
    const handleKeyDown = (e: KeyboardEvent) => {
      const action = actions.find(a => {
        if (!a.shortcut) return false;
        const keys = a.shortcut.toLowerCase().split('+');
        const ctrlRequired = keys.includes('ctrl');
        const shiftRequired = keys.includes('shift');
        const altRequired = keys.includes('alt');
        const key = keys[keys.length - 1];
        
        return (
          (ctrlRequired === e.ctrlKey || ctrlRequired === e.metaKey) &&
          shiftRequired === e.shiftKey &&
          altRequired === e.altKey &&
          e.key.toLowerCase() === key
        );
      });
      
      if (action && !action.disabled) {
        e.preventDefault();
        action.onClick();
      }
    };
    
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [selectedFieldId, actions]);

  // Build toolbar actions
  const toolbarActions = showDefaultActions ? [
    ...defaultActions.map(action => ({
      ...action,
      onClick: () => {
        switch (action.id) {
          case 'duplicate':
            onDuplicate?.();
            break;
          case 'edit':
            onEdit?.();
            break;
          case 'settings':
            onSettings?.();
            break;
          case 'delete':
            onDelete?.();
            break;
          default:
            action.onClick();
        }
      }
    })),
    ...actions.filter(a => !defaultActions.find(d => d.id === a.id))
  ] : actions;

  if (!selectedFieldId || !position) return null;

  const toolbarPosition = floating ? calculatePosition() : { x: 0, y: 0 };

  return (
    <TooltipProvider>
      <animated.div
        ref={toolbarRef}
        style={{
          ...springProps,
          ...(floating ? {
            position: 'fixed',
            left: `${toolbarPosition.x}px`,
            top: `${toolbarPosition.y}px`,
            zIndex: 1000
          } : {})
        }}
        className={cn(
          'context-toolbar',
          'flex items-center gap-1 p-1.5 bg-white rounded-lg shadow-lg border',
          'transition-all duration-200',
          isCompact && 'context-toolbar--compact',
          className
        )}
        data-testid={testId}
        role="toolbar"
        aria-label={`Toolbar for ${selectedFieldType || 'selected'} field`}
      >
        {/* Main Actions */}
        <div className="flex items-center gap-0.5">
          {toolbarActions.filter(a => !a.hidden).map(action => {
            const Icon = action.icon;
            
            return (
              <Tooltip key={action.id}>
                <TooltipTrigger asChild>
                  <button
                    className={cn(
                      'toolbar-action',
                      'p-2 rounded hover:bg-gray-100 transition-colors',
                      'focus:outline-none focus:ring-2 focus:ring-blue-500',
                      action.destructive && 'hover:bg-red-50 hover:text-red-600',
                      action.disabled && 'opacity-50 cursor-not-allowed'
                    )}
                    onClick={action.onClick}
                    disabled={action.disabled}
                    aria-label={action.label}
                    data-testid={`toolbar-action-${action.id}`}
                  >
                    <Icon className="w-4 h-4" />
                  </button>
                </TooltipTrigger>
                <TooltipContent>
                  <div className="flex items-center gap-2">
                    <span>{action.label}</span>
                    {action.shortcut && (
                      <kbd className="px-1.5 py-0.5 text-xs bg-gray-100 rounded">
                        {action.shortcut}
                      </kbd>
                    )}
                  </div>
                </TooltipContent>
              </Tooltip>
            );
          })}
        </div>

        {/* Separator */}
        {onMove && <div className="w-px h-6 bg-gray-200" />}

        {/* Additional Actions */}
        {(onMove || onToggleLock || onToggleVisibility) && (
          <div className="flex items-center gap-0.5">
            {onMove && (
              <Tooltip>
                <TooltipTrigger asChild>
                  <button
                    className="toolbar-action p-2 rounded hover:bg-gray-100 transition-colors"
                    onClick={onMove}
                    aria-label="Move field"
                    data-testid="toolbar-action-move"
                  >
                    <Move className="w-4 h-4" />
                  </button>
                </TooltipTrigger>
                <TooltipContent>Move (Hold Alt)</TooltipContent>
              </Tooltip>
            )}
            
            {onToggleLock && (
              <Tooltip>
                <TooltipTrigger asChild>
                  <button
                    className="toolbar-action p-2 rounded hover:bg-gray-100 transition-colors"
                    onClick={() => {
                      setIsLocked(!isLocked);
                      onToggleLock(!isLocked);
                    }}
                    aria-label={isLocked ? 'Unlock field' : 'Lock field'}
                    data-testid="toolbar-action-lock"
                  >
                    {isLocked ? <Unlock className="w-4 h-4" /> : <Lock className="w-4 h-4" />}
                  </button>
                </TooltipTrigger>
                <TooltipContent>{isLocked ? 'Unlock' : 'Lock'}</TooltipContent>
              </Tooltip>
            )}
            
            {onToggleVisibility && (
              <Tooltip>
                <TooltipTrigger asChild>
                  <button
                    className="toolbar-action p-2 rounded hover:bg-gray-100 transition-colors"
                    onClick={() => {
                      setIsFieldVisible(!isFieldVisible);
                      onToggleVisibility(!isFieldVisible);
                    }}
                    aria-label={isFieldVisible ? 'Hide field' : 'Show field'}
                    data-testid="toolbar-action-visibility"
                  >
                    {isFieldVisible ? <Eye className="w-4 h-4" /> : <EyeOff className="w-4 h-4" />}
                  </button>
                </TooltipTrigger>
                <TooltipContent>{isFieldVisible ? 'Hide' : 'Show'}</TooltipContent>
              </Tooltip>
            )}
          </div>
        )}

        {/* More Options (Compact Mode) */}
        {isCompact && (
          <>
            <div className="w-px h-6 bg-gray-200" />
            <Tooltip>
              <TooltipTrigger asChild>
                <button
                  className="toolbar-action p-2 rounded hover:bg-gray-100 transition-colors"
                  aria-label="More options"
                  data-testid="toolbar-action-more"
                >
                  <MoreVertical className="w-4 h-4" />
                </button>
              </TooltipTrigger>
              <TooltipContent>More Options</TooltipContent>
            </Tooltip>
          </>
        )}
      </animated.div>
    </TooltipProvider>
  );
}

// Hook for managing toolbar state
export function useContextToolbar() {
  const [selectedFieldId, setSelectedFieldId] = useState<string | null>(null);
  const [selectedFieldType, setSelectedFieldType] = useState<string | undefined>();
  const [position, setPosition] = useState<{ x: number; y: number } | null>(null);

  const selectField = useCallback((fieldId: string, fieldType?: string, element?: HTMLElement) => {
    setSelectedFieldId(fieldId);
    setSelectedFieldType(fieldType);
    
    if (element) {
      const rect = element.getBoundingClientRect();
      setPosition({
        x: rect.left + rect.width / 2,
        y: rect.top
      });
    }
  }, []);

  const clearSelection = useCallback(() => {
    setSelectedFieldId(null);
    setSelectedFieldType(undefined);
    setPosition(null);
  }, []);

  return {
    selectedFieldId,
    selectedFieldType,
    position,
    selectField,
    clearSelection
  };
}