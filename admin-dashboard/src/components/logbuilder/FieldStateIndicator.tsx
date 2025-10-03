import React, { useState, useEffect, useRef } from 'react';
import { useSpring, animated } from '@react-spring/web';
import { CheckCircle, XCircle, Clock, AlertTriangle, Info, Star } from 'lucide-react';
import { cn } from '@/lib/utils';

export type FieldStatus = 'valid' | 'invalid' | 'pending' | 'warning' | 'info';

export interface ValidationMessage {
  type: FieldStatus;
  message: string;
  details?: string;
}

export interface FieldStateIndicatorProps {
  fieldId: string;
  status: FieldStatus;
  required?: boolean;
  hasValue?: boolean;
  validationMessage?: string;
  validationMessages?: ValidationMessage[];
  showTooltip?: boolean;
  position?: 'top' | 'right' | 'bottom' | 'left';
  onChange?: (status: FieldStatus) => void;
  className?: string;
  'data-testid'?: string;
}

const statusConfig = {
  valid: {
    icon: CheckCircle,
    label: 'Valid',
    color: 'text-green-600',
    bgColor: 'bg-green-100',
    borderColor: 'border-green-300',
    badgeClass: 'badge--success',
    ariaLabel: 'Field validation: valid'
  },
  invalid: {
    icon: XCircle,
    label: 'Invalid',
    color: 'text-red-600',
    bgColor: 'bg-red-100',
    borderColor: 'border-red-300',
    badgeClass: 'badge--error',
    ariaLabel: 'Field validation: invalid'
  },
  pending: {
    icon: Clock,
    label: 'Validating...',
    color: 'text-yellow-600',
    bgColor: 'bg-yellow-100',
    borderColor: 'border-yellow-300',
    badgeClass: 'badge--warning',
    ariaLabel: 'Field validation: pending'
  },
  warning: {
    icon: AlertTriangle,
    label: 'Warning',
    color: 'text-orange-600',
    bgColor: 'bg-orange-100',
    borderColor: 'border-orange-300',
    badgeClass: 'badge--warning',
    ariaLabel: 'Field validation: warning'
  },
  info: {
    icon: Info,
    label: 'Info',
    color: 'text-blue-600',
    bgColor: 'bg-blue-100',
    borderColor: 'border-blue-300',
    badgeClass: 'badge--info',
    ariaLabel: 'Field validation: informational'
  }
} as const;

export function FieldStateIndicator({
  fieldId,
  status,
  required = false,
  hasValue = false,
  validationMessage = '',
  validationMessages = [],
  showTooltip = true,
  position = 'top',
  onChange,
  className,
  'data-testid': testId = `field-state-indicator-${fieldId}`,
}: FieldStateIndicatorProps) {
  const [isHovered, setIsHovered] = useState(false);
  const [isTooltipVisible, setIsTooltipVisible] = useState(false);
  const [isAnimating, setIsAnimating] = useState(false);
  const previousStatus = useRef<FieldStatus>(status);
  const indicatorRef = useRef<HTMLDivElement>(null);
  const tooltipRef = useRef<HTMLDivElement>(null);

  const config = statusConfig[status];
  const Icon = config.icon;

  // Animation for status changes
  const statusSpring = useSpring({
    scale: isAnimating ? 1.1 : 1,
    opacity: 1,
    transform: `rotate(${isAnimating ? 5 : 0}deg)`,
    config: { tension: 280, friction: 60 },
    onRest: () => setIsAnimating(false),
  });

  // Tooltip animation
  const tooltipSpring = useSpring({
    opacity: isTooltipVisible ? 1 : 0,
    transform: isTooltipVisible 
      ? 'translateY(0px) scale(1)' 
      : 'translateY(-8px) scale(0.95)',
    config: { tension: 280, friction: 60 },
  });

  // Badge pulse animation for pending status
  const pulseSpring = useSpring({
    opacity: status === 'pending' ? 0.7 : 1,
    config: { duration: 1000 },
    loop: status === 'pending',
  });

  // Handle status change animations
  useEffect(() => {
    if (previousStatus.current !== status) {
      setIsAnimating(true);
      previousStatus.current = status;
      onChange?.(status);
    }
  }, [status, onChange]);

  // Handle tooltip visibility
  useEffect(() => {
    let timeoutId: NodeJS.Timeout;
    
    if (isHovered && showTooltip && (validationMessage || validationMessages.length > 0)) {
      timeoutId = setTimeout(() => setIsTooltipVisible(true), 300);
    } else {
      setIsTooltipVisible(false);
    }

    return () => {
      if (timeoutId) clearTimeout(timeoutId);
    };
  }, [isHovered, showTooltip, validationMessage, validationMessages]);

  // Get all validation messages
  const allMessages = validationMessages.length > 0 
    ? validationMessages 
    : validationMessage 
    ? [{ type: status, message: validationMessage }] 
    : [];

  // Position classes for tooltip
  const getTooltipPositionClasses = () => {
    switch (position) {
      case 'top':
        return 'bottom-full left-1/2 transform -translate-x-1/2 mb-2';
      case 'right':
        return 'left-full top-1/2 transform -translate-y-1/2 ml-2';
      case 'bottom':
        return 'top-full left-1/2 transform -translate-x-1/2 mt-2';
      case 'left':
        return 'right-full top-1/2 transform -translate-y-1/2 mr-2';
      default:
        return 'bottom-full left-1/2 transform -translate-x-1/2 mb-2';
    }
  };

  // Tooltip arrow classes
  const getTooltipArrowClasses = () => {
    switch (position) {
      case 'top':
        return 'top-full left-1/2 transform -translate-x-1/2 border-t-gray-800 border-l-transparent border-r-transparent border-b-transparent';
      case 'right':
        return 'right-full top-1/2 transform -translate-y-1/2 border-r-gray-800 border-t-transparent border-b-transparent border-l-transparent';
      case 'bottom':
        return 'bottom-full left-1/2 transform -translate-x-1/2 border-b-gray-800 border-l-transparent border-r-transparent border-t-transparent';
      case 'left':
        return 'left-full top-1/2 transform -translate-y-1/2 border-l-gray-800 border-t-transparent border-b-transparent border-r-transparent';
      default:
        return 'top-full left-1/2 transform -translate-x-1/2 border-t-gray-800 border-l-transparent border-r-transparent border-b-transparent';
    }
  };

  return (
    <div
      ref={indicatorRef}
      data-testid={testId}
      className={cn(
        'field-state-indicator',
        'relative',
        'inline-flex',
        'items-center',
        'gap-2',
        `field-state--${status}`,
        className
      )}
      aria-label={config.ariaLabel}
      aria-describedby={allMessages.length > 0 ? `validation-message-${fieldId}` : undefined}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
      onFocus={() => setIsHovered(true)}
      onBlur={() => setIsHovered(false)}
    >
      {/* Required indicator */}
      {required && (
        <span
          data-testid="required-indicator"
          className="required-indicator text-red-500 text-sm font-medium"
          aria-label="Required field"
        >
          *
        </span>
      )}

      {/* Status badge */}
      <animated.div
        data-testid="field-badge"
        className={cn(
          'badge',
          'inline-flex',
          'items-center',
          'gap-1',
          'px-2',
          'py-1',
          'rounded-full',
          'text-xs',
          'font-medium',
          'border',
          config.color,
          config.bgColor,
          config.borderColor,
          config.badgeClass,
          'transition-all',
          'duration-200',
          'cursor-help',
          {
            'hover:shadow-sm': showTooltip && (validationMessage || validationMessages.length > 0),
          }
        )}
        style={status === 'pending' ? pulseSpring : statusSpring}
        tabIndex={showTooltip && allMessages.length > 0 ? 0 : -1}
        role={showTooltip && allMessages.length > 0 ? 'button' : undefined}
        aria-expanded={isTooltipVisible}
        aria-haspopup={showTooltip && allMessages.length > 0 ? 'true' : undefined}
      >
        <Icon 
          size={12} 
          className={cn(
            config.color,
            status === 'pending' && 'animate-spin'
          )} 
        />
        <span>{config.label}</span>
      </animated.div>

      {/* Tooltip */}
      {showTooltip && allMessages.length > 0 && (
        <animated.div
          ref={tooltipRef}
          data-testid="validation-tooltip"
          className={cn(
            'absolute',
            'z-50',
            'pointer-events-none',
            getTooltipPositionClasses()
          )}
          style={{
            ...tooltipSpring,
            pointerEvents: isTooltipVisible ? 'auto' : 'none',
          }}
          role="tooltip"
          aria-hidden={!isTooltipVisible}
        >
          <div className="bg-gray-800 text-white text-sm rounded-lg py-2 px-3 shadow-lg max-w-64">
            {/* Validation messages */}
            <div id={`validation-message-${fieldId}`} className="space-y-1">
              {allMessages.map((msg, index) => (
                <div key={index} className="flex items-start gap-2">
                  {msg.type !== status && (
                    <div className={cn(
                      'w-2 h-2 rounded-full mt-1.5 flex-shrink-0',
                      statusConfig[msg.type].bgColor.replace('bg-', 'bg-opacity-100 bg-')
                    )} />
                  )}
                  <div>
                    <div className="font-medium">{msg.message}</div>
                    {msg.details && (
                      <div className="text-gray-300 text-xs mt-0.5">
                        {msg.details}
                      </div>
                    )}
                  </div>
                </div>
              ))}
            </div>

            {/* Tooltip arrow */}
            <div
              className={cn(
                'absolute',
                'w-0',
                'h-0',
                'border-4',
                getTooltipArrowClasses()
              )}
            />
          </div>
        </animated.div>
      )}
    </div>
  );
}

// Compound component for field state with progress
export interface FieldProgressIndicatorProps {
  fieldId: string;
  status: FieldStatus;
  progress?: number; // 0-100
  required?: boolean;
  label?: string;
  className?: string;
}

export function FieldProgressIndicator({
  fieldId,
  status,
  progress = 0,
  required = false,
  label,
  className,
}: FieldProgressIndicatorProps) {
  const progressSpring = useSpring({
    width: `${progress}%`,
    config: { tension: 280, friction: 60 },
  });

  const config = statusConfig[status];

  return (
    <div
      className={cn(
        'field-progress-indicator',
        'flex',
        'items-center',
        'gap-3',
        className
      )}
    >
      <FieldStateIndicator
        fieldId={fieldId}
        status={status}
        required={required}
        showTooltip={false}
      />
      
      {label && (
        <span className="text-sm font-medium text-gray-700 min-w-0 flex-1">
          {label}
        </span>
      )}

      <div className="flex-1 bg-gray-200 rounded-full h-2 overflow-hidden">
        <animated.div
          className={cn(
            'h-full',
            'rounded-full',
            'transition-colors',
            'duration-200',
            config.bgColor.replace('100', '500')
          )}
          style={progressSpring}
        />
      </div>

      <span className="text-xs text-gray-500 min-w-[3rem] text-right">
        {Math.round(progress)}%
      </span>
    </div>
  );
}

// Batch indicator for multiple field states
export interface FieldBatchIndicatorProps {
  fields: Array<{
    id: string;
    status: FieldStatus;
    label?: string;
    required?: boolean;
  }>;
  showSummary?: boolean;
  className?: string;
}

export function FieldBatchIndicator({
  fields,
  showSummary = true,
  className,
}: FieldBatchIndicatorProps) {
  const summary = fields.reduce(
    (acc, field) => {
      acc[field.status] = (acc[field.status] || 0) + 1;
      acc.total++;
      if (field.required) acc.required++;
      return acc;
    },
    { valid: 0, invalid: 0, pending: 0, warning: 0, info: 0, total: 0, required: 0 }
  );

  return (
    <div className={cn('field-batch-indicator', 'space-y-3', className)}>
      {/* Summary */}
      {showSummary && (
        <div className="bg-gray-50 rounded-lg p-3">
          <div className="flex items-center justify-between mb-2">
            <h4 className="text-sm font-medium text-gray-900">Field Status Summary</h4>
            <span className="text-xs text-gray-500">
              {summary.total} fields ({summary.required} required)
            </span>
          </div>
          
          <div className="flex flex-wrap gap-2">
            {Object.entries(statusConfig).map(([status, config]) => {
              const count = summary[status as FieldStatus];
              if (count === 0) return null;
              
              return (
                <div
                  key={status}
                  className={cn(
                    'flex',
                    'items-center',
                    'gap-1',
                    'px-2',
                    'py-1',
                    'rounded',
                    'text-xs',
                    config.bgColor,
                    config.color
                  )}
                >
                  <config.icon size={10} />
                  <span>{count}</span>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Individual fields */}
      <div className="space-y-2">
        {fields.map((field) => (
          <div
            key={field.id}
            className="flex items-center justify-between p-2 bg-white border rounded-lg"
          >
            <div className="flex items-center gap-3">
              <FieldStateIndicator
                fieldId={field.id}
                status={field.status}
                required={field.required}
                showTooltip={false}
              />
              <span className="text-sm text-gray-700">
                {field.label || field.id}
              </span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

export default FieldStateIndicator;