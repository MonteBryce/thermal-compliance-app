import React, { useEffect, useState, useRef, useCallback } from 'react';
import { useSpring, animated } from '@react-spring/web';
import { X, CheckCircle, XCircle, AlertTriangle, Info, Undo2 } from 'lucide-react';
import { cn } from '@/lib/utils';

export type ToastType = 'success' | 'error' | 'warning' | 'info';
export type ToastPosition = 'top-right' | 'top-left' | 'bottom-right' | 'bottom-left' | 'top-center' | 'bottom-center';

export interface ToastNotificationProps {
  id: string;
  type: ToastType;
  title: string;
  message: string;
  duration?: number; // 0 for permanent
  showUndo?: boolean;
  undoLabel?: string;
  position?: ToastPosition;
  className?: string;
  onDismiss: (id: string) => void;
  onUndo?: () => void;
  'data-testid'?: string;
}

const toastConfig = {
  success: {
    icon: CheckCircle,
    bgColor: 'bg-green-50',
    borderColor: 'border-green-200',
    textColor: 'text-green-800',
    iconColor: 'text-green-600',
    className: 'toast--success',
    ariaLive: 'polite' as const,
  },
  error: {
    icon: XCircle,
    bgColor: 'bg-red-50',
    borderColor: 'border-red-200',
    textColor: 'text-red-800',
    iconColor: 'text-red-600',
    className: 'toast--error',
    ariaLive: 'assertive' as const,
  },
  warning: {
    icon: AlertTriangle,
    bgColor: 'bg-yellow-50',
    borderColor: 'border-yellow-200',
    textColor: 'text-yellow-800',
    iconColor: 'text-yellow-600',
    className: 'toast--warning',
    ariaLive: 'polite' as const,
  },
  info: {
    icon: Info,
    bgColor: 'bg-blue-50',
    borderColor: 'border-blue-200',
    textColor: 'text-blue-800',
    iconColor: 'text-blue-600',
    className: 'toast--info',
    ariaLive: 'polite' as const,
  },
} as const;

export function ToastNotification({
  id,
  type,
  title,
  message,
  duration = 5000,
  showUndo = false,
  undoLabel = 'Undo',
  position = 'top-right',
  className,
  onDismiss,
  onUndo,
  'data-testid': testId = `toast-notification-${id}`,
}: ToastNotificationProps) {
  const [isVisible, setIsVisible] = useState(true);
  const [isPaused, setIsPaused] = useState(false);
  const [progress, setProgress] = useState(100);
  const timeoutRef = useRef<NodeJS.Timeout>();
  const startTimeRef = useRef<number>(Date.now());
  const pausedTimeRef = useRef<number>(0);
  const intervalRef = useRef<NodeJS.Timeout>();

  const config = toastConfig[type];
  const Icon = config.icon;

  // Slide-in animation
  const slideSpring = useSpring({
    opacity: isVisible ? 1 : 0,
    transform: isVisible 
      ? 'translateX(0px) scale(1)' 
      : position.includes('right')
      ? 'translateX(100px) scale(0.95)'
      : 'translateX(-100px) scale(0.95)',
    config: { tension: 280, friction: 60 },
  });

  // Progress bar animation
  const progressSpring = useSpring({
    width: `${progress}%`,
    config: { duration: 100 },
  });

  // Handle auto-dismiss
  const startDismissTimer = useCallback(() => {
    if (duration === 0) return;

    timeoutRef.current = setTimeout(() => {
      setIsVisible(false);
      setTimeout(() => onDismiss(id), 300); // Wait for animation
    }, duration);

    // Start progress countdown
    const interval = 50;
    const totalSteps = duration / interval;
    let currentStep = 0;

    intervalRef.current = setInterval(() => {
      if (!isPaused) {
        currentStep++;
        const newProgress = Math.max(0, 100 - (currentStep / totalSteps) * 100);
        setProgress(newProgress);
      }
    }, interval);

    startTimeRef.current = Date.now();
  }, [duration, id, isPaused, onDismiss]);

  const clearDismissTimer = useCallback(() => {
    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
      timeoutRef.current = undefined;
    }
    if (intervalRef.current) {
      clearInterval(intervalRef.current);
      intervalRef.current = undefined;
    }
  }, []);

  const pauseDismissTimer = useCallback(() => {
    if (!isPaused && timeoutRef.current) {
      clearDismissTimer();
      pausedTimeRef.current = Date.now();
      setIsPaused(true);
    }
  }, [isPaused, clearDismissTimer]);

  const resumeDismissTimer = useCallback(() => {
    if (isPaused && duration > 0) {
      const elapsedTime = pausedTimeRef.current - startTimeRef.current;
      const remainingTime = Math.max(0, duration - elapsedTime);
      
      if (remainingTime > 0) {
        timeoutRef.current = setTimeout(() => {
          setIsVisible(false);
          setTimeout(() => onDismiss(id), 300);
        }, remainingTime);

        // Resume progress countdown
        const interval = 50;
        const totalSteps = remainingTime / interval;
        let currentStep = 0;
        const currentProgress = progress;

        intervalRef.current = setInterval(() => {
          currentStep++;
          const newProgress = Math.max(0, currentProgress - (currentStep / totalSteps) * currentProgress);
          setProgress(newProgress);
        }, interval);
      }
      
      setIsPaused(false);
    }
  }, [isPaused, duration, progress, id, onDismiss]);

  // Initialize auto-dismiss
  useEffect(() => {
    startDismissTimer();
    return clearDismissTimer;
  }, [startDismissTimer, clearDismissTimer]);

  // Handle manual dismiss
  const handleDismiss = useCallback(() => {
    clearDismissTimer();
    setIsVisible(false);
    setTimeout(() => onDismiss(id), 300);
  }, [clearDismissTimer, id, onDismiss]);

  // Handle undo action
  const handleUndo = useCallback(() => {
    clearDismissTimer();
    onUndo?.();
    setIsVisible(false);
    setTimeout(() => onDismiss(id), 300);
  }, [clearDismissTimer, onUndo, id, onDismiss]);

  return (
    <animated.div
      data-testid={testId}
      style={slideSpring}
      className={cn(
        'toast-notification',
        'relative',
        'max-w-sm',
        'w-full',
        'bg-white',
        'border',
        'rounded-lg',
        'shadow-lg',
        'overflow-hidden',
        config.bgColor,
        config.borderColor,
        config.className,
        className
      )}
      role={type === 'error' ? 'alert' : 'status'}
      aria-live={config.ariaLive}
      aria-atomic="true"
      onMouseEnter={pauseDismissTimer}
      onMouseLeave={resumeDismissTimer}
      onFocus={pauseDismissTimer}
      onBlur={resumeDismissTimer}
    >
      {/* Progress bar */}
      {duration > 0 && (
        <div className="absolute top-0 left-0 right-0 h-1 bg-black bg-opacity-10">
          <animated.div
            className={cn(
              'h-full',
              'transition-colors',
              'duration-200',
              config.iconColor.replace('text-', 'bg-')
            )}
            style={progressSpring}
          />
        </div>
      )}

      {/* Content */}
      <div className="p-4">
        <div className="flex items-start">
          {/* Icon */}
          <div className="flex-shrink-0">
            <Icon 
              size={20} 
              className={cn(config.iconColor, 'mt-0.5')} 
            />
          </div>

          {/* Message */}
          <div className="ml-3 flex-1 min-w-0">
            <p className={cn('text-sm font-medium', config.textColor)}>
              {title}
            </p>
            <p className={cn('mt-1 text-sm', config.textColor, 'opacity-90')}>
              {message}
            </p>
          </div>

          {/* Actions */}
          <div className="ml-4 flex-shrink-0 flex items-center gap-2">
            {/* Undo button */}
            {showUndo && (
              <button
                type="button"
                className={cn(
                  'inline-flex',
                  'items-center',
                  'gap-1',
                  'px-2',
                  'py-1',
                  'text-xs',
                  'font-medium',
                  'rounded',
                  'border',
                  'transition-colors',
                  'duration-200',
                  'focus:outline-none',
                  'focus:ring-2',
                  'focus:ring-offset-2',
                  config.textColor,
                  config.borderColor,
                  'hover:bg-opacity-10',
                  'focus:ring-blue-500'
                )}
                onClick={handleUndo}
                aria-label={undoLabel}
              >
                <Undo2 size={12} />
                <span>{undoLabel}</span>
              </button>
            )}

            {/* Dismiss button */}
            <button
              type="button"
              className={cn(
                'inline-flex',
                'rounded-md',
                'p-1.5',
                'transition-colors',
                'duration-200',
                'focus:outline-none',
                'focus:ring-2',
                'focus:ring-offset-2',
                config.textColor,
                'hover:bg-black',
                'hover:bg-opacity-10',
                'focus:ring-blue-500'
              )}
              onClick={handleDismiss}
              aria-label="Dismiss notification"
            >
              <X size={16} />
            </button>
          </div>
        </div>
      </div>
    </animated.div>
  );
}

// Toast container for managing multiple toasts
export interface ToastContainerProps {
  toasts: Array<Omit<ToastNotificationProps, 'onDismiss'>>;
  position?: ToastPosition;
  maxToasts?: number;
  onDismiss: (id: string) => void;
  onUndo?: (id: string) => void;
  className?: string;
}

export function ToastContainer({
  toasts,
  position = 'top-right',
  maxToasts = 5,
  onDismiss,
  onUndo,
  className,
}: ToastContainerProps) {
  const visibleToasts = toasts.slice(-maxToasts);

  const getPositionClasses = () => {
    switch (position) {
      case 'top-right':
        return 'top-4 right-4';
      case 'top-left':
        return 'top-4 left-4';
      case 'bottom-right':
        return 'bottom-4 right-4';
      case 'bottom-left':
        return 'bottom-4 left-4';
      case 'top-center':
        return 'top-4 left-1/2 transform -translate-x-1/2';
      case 'bottom-center':
        return 'bottom-4 left-1/2 transform -translate-x-1/2';
      default:
        return 'top-4 right-4';
    }
  };

  return (
    <div
      className={cn(
        'toast-container',
        'fixed',
        'z-50',
        'flex',
        'flex-col',
        'gap-2',
        'pointer-events-none',
        getPositionClasses(),
        className
      )}
      aria-live="polite"
      aria-label="Notifications"
    >
      {visibleToasts.map((toast) => (
        <div key={toast.id} className="pointer-events-auto">
          <ToastNotification
            {...toast}
            position={position}
            onDismiss={onDismiss}
            onUndo={onUndo ? () => onUndo(toast.id) : toast.onUndo}
          />
        </div>
      ))}
    </div>
  );
}

// Hook for managing toast state
export function useToastNotifications() {
  const [toasts, setToasts] = useState<Array<Omit<ToastNotificationProps, 'onDismiss'>>>([]);

  const addToast = useCallback((toast: Omit<ToastNotificationProps, 'id' | 'onDismiss'>) => {
    const id = Math.random().toString(36).substr(2, 9);
    setToasts(prev => [...prev, { ...toast, id }]);
    return id;
  }, []);

  const removeToast = useCallback((id: string) => {
    setToasts(prev => prev.filter(toast => toast.id !== id));
  }, []);

  const clearToasts = useCallback(() => {
    setToasts([]);
  }, []);

  // Convenience methods
  const showSuccess = useCallback((title: string, message: string, options?: Partial<ToastNotificationProps>) => {
    return addToast({ type: 'success', title, message, ...options });
  }, [addToast]);

  const showError = useCallback((title: string, message: string, options?: Partial<ToastNotificationProps>) => {
    return addToast({ type: 'error', title, message, duration: 0, ...options });
  }, [addToast]);

  const showWarning = useCallback((title: string, message: string, options?: Partial<ToastNotificationProps>) => {
    return addToast({ type: 'warning', title, message, ...options });
  }, [addToast]);

  const showInfo = useCallback((title: string, message: string, options?: Partial<ToastNotificationProps>) => {
    return addToast({ type: 'info', title, message, ...options });
  }, [addToast]);

  return {
    toasts,
    addToast,
    removeToast,
    clearToasts,
    showSuccess,
    showError,
    showWarning,
    showInfo,
  };
}

export default ToastNotification;