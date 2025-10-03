import React, { useEffect, useRef, useState, useCallback } from 'react';
import { useSpring, animated, useTransition, useChain, useSpringRef } from '@react-spring/web';
import { cn } from '@/lib/utils';

export type AnimationType = 'fade' | 'scale' | 'slide' | 'bounce' | 'pulse' | 'shake' | 'rotate' | 'flip';
export type SlideDirection = 'up' | 'down' | 'left' | 'right';
export type EasingType = 'gentle' | 'wobbly' | 'stiff' | 'slow' | 'molasses';

export interface MicroAnimationProps {
  children: React.ReactNode;
  type: AnimationType;
  direction?: SlideDirection;
  duration?: number;
  delay?: number;
  trigger?: boolean;
  loop?: boolean;
  easing?: EasingType;
  disabled?: boolean;
  onComplete?: () => void;
  onStart?: () => void;
  className?: string;
  'data-testid'?: string;
}

// Enhanced spring configs
const configs = {
  gentle: { tension: 280, friction: 60 },
  wobbly: { tension: 180, friction: 12 },
  stiff: { tension: 210, friction: 20 },
  slow: { tension: 280, friction: 120 },
  molasses: { tension: 280, friction: 200 },
};

// Reduced motion detection
const useReducedMotion = () => {
  const [prefersReducedMotion, setPrefersReducedMotion] = useState(false);

  useEffect(() => {
    const mediaQuery = window.matchMedia('(prefers-reduced-motion: reduce)');
    setPrefersReducedMotion(mediaQuery.matches);

    const handleChange = (event: MediaQueryListEvent) => {
      setPrefersReducedMotion(event.matches);
    };

    mediaQuery.addEventListener('change', handleChange);
    return () => mediaQuery.removeEventListener('change', handleChange);
  }, []);

  return prefersReducedMotion;
};

export function MicroAnimation({
  children,
  type,
  direction = 'up',
  duration = 300,
  delay = 0,
  trigger = true,
  loop = false,
  easing = 'gentle',
  disabled = false,
  onComplete,
  onStart,
  className,
  'data-testid': testId = 'micro-animation',
}: MicroAnimationProps) {
  const prefersReducedMotion = useReducedMotion();
  const [isActive, setIsActive] = useState(false);
  const [hasCompleted, setHasCompleted] = useState(false);

  const shouldAnimate = trigger && !disabled && (!prefersReducedMotion || type === 'fade');
  const springConfig = configs[easing];

  // Animation spring based on type
  const getAnimationSpring = useCallback(() => {
    const baseConfig = {
      ...springConfig,
      ...(duration !== 300 && { duration }),
    };

    switch (type) {
      case 'fade':
        return useSpring({
          opacity: shouldAnimate ? 1 : 0,
          config: baseConfig,
          delay,
          loop,
          onStart: () => {
            setIsActive(true);
            onStart?.();
          },
          onRest: () => {
            setIsActive(false);
            setHasCompleted(true);
            onComplete?.();
          },
        });

      case 'scale':
        return useSpring({
          transform: shouldAnimate ? 'scale(1)' : 'scale(0.95)',
          opacity: shouldAnimate ? 1 : 0,
          config: baseConfig,
          delay,
          loop,
          onStart: () => {
            setIsActive(true);
            onStart?.();
          },
          onRest: () => {
            setIsActive(false);
            setHasCompleted(true);
            onComplete?.();
          },
        });

      case 'slide':
        const slideTransforms = {
          up: shouldAnimate ? 'translateY(0px)' : 'translateY(20px)',
          down: shouldAnimate ? 'translateY(0px)' : 'translateY(-20px)',
          left: shouldAnimate ? 'translateX(0px)' : 'translateX(20px)',
          right: shouldAnimate ? 'translateX(0px)' : 'translateX(-20px)',
        };
        
        return useSpring({
          transform: slideTransforms[direction],
          opacity: shouldAnimate ? 1 : 0,
          config: baseConfig,
          delay,
          loop,
          onStart: () => {
            setIsActive(true);
            onStart?.();
          },
          onRest: () => {
            setIsActive(false);
            setHasCompleted(true);
            onComplete?.();
          },
        });

      case 'bounce':
        return useSpring({
          transform: shouldAnimate ? 'scale(1) translateY(0px)' : 'scale(1.1) translateY(-5px)',
          config: { ...springConfig, tension: 300, friction: 10 },
          delay,
          loop,
          onStart: () => {
            setIsActive(true);
            onStart?.();
          },
          onRest: () => {
            setIsActive(false);
            setHasCompleted(true);
            onComplete?.();
          },
        });

      case 'pulse':
        return useSpring({
          transform: shouldAnimate ? 'scale(1)' : 'scale(1.05)',
          config: { duration: 600 },
          delay,
          loop: true,
          onStart: () => {
            setIsActive(true);
            onStart?.();
          },
        });

      case 'shake':
        return useSpring({
          transform: shouldAnimate ? 'translateX(0px)' : 'translateX(2px)',
          config: { tension: 300, friction: 10 },
          delay,
          loop: shouldAnimate ? { reverse: true } : false,
          onStart: () => {
            setIsActive(true);
            onStart?.();
          },
          onRest: () => {
            setIsActive(false);
            setHasCompleted(true);
            onComplete?.();
          },
        });

      case 'rotate':
        return useSpring({
          transform: shouldAnimate ? 'rotate(0deg)' : 'rotate(5deg)',
          config: baseConfig,
          delay,
          loop,
          onStart: () => {
            setIsActive(true);
            onStart?.();
          },
          onRest: () => {
            setIsActive(false);
            setHasCompleted(true);
            onComplete?.();
          },
        });

      case 'flip':
        return useSpring({
          transform: shouldAnimate ? 'rotateY(0deg)' : 'rotateY(180deg)',
          config: baseConfig,
          delay,
          loop,
          onStart: () => {
            setIsActive(true);
            onStart?.();
          },
          onRest: () => {
            setIsActive(false);
            setHasCompleted(true);
            onComplete?.();
          },
        });

      default:
        return useSpring({
          opacity: shouldAnimate ? 1 : 0,
          config: baseConfig,
          delay,
          loop,
        });
    }
  }, [type, direction, shouldAnimate, springConfig, duration, delay, loop, onStart, onComplete]);

  const animationSpring = getAnimationSpring();

  // Apply reduced motion overrides
  const finalStyle = prefersReducedMotion && type !== 'fade' 
    ? { opacity: shouldAnimate ? 1 : 0 }
    : animationSpring;

  return (
    <animated.div
      data-testid={testId}
      style={finalStyle}
      className={cn(
        'micro-animation',
        `animation--${type}`,
        {
          [`animation--${type}-${direction}`]: type === 'slide',
          'animation--active': isActive,
          'animation--completed': hasCompleted,
          'animation--reduced-motion': prefersReducedMotion,
          'animation--delayed': delay > 0,
          'animation--loop': loop,
        },
        className
      )}
      aria-hidden="true" // Hide decorative animations from screen readers
    >
      {children}
    </animated.div>
  );
}

// Staggered animation component for lists
export interface StaggeredAnimationProps {
  children: React.ReactNode[];
  type?: AnimationType;
  direction?: SlideDirection;
  staggerDelay?: number;
  trigger?: boolean;
  className?: string;
}

export function StaggeredAnimation({
  children,
  type = 'fade',
  direction = 'up',
  staggerDelay = 100,
  trigger = true,
  className,
}: StaggeredAnimationProps) {
  const transitions = useTransition(trigger ? children : [], {
    from: type === 'fade' 
      ? { opacity: 0 } 
      : { opacity: 0, transform: 'translateY(20px)' },
    enter: type === 'fade'
      ? { opacity: 1 }
      : { opacity: 1, transform: 'translateY(0px)' },
    leave: type === 'fade'
      ? { opacity: 0 }
      : { opacity: 0, transform: 'translateY(-20px)' },
    config: configs.gentle,
    trail: staggerDelay,
  });

  return (
    <div className={cn('staggered-animation', className)}>
      {transitions((style, item, _, index) => (
        <animated.div key={index} style={style}>
          {item}
        </animated.div>
      ))}
    </div>
  );
}

// Sequence animation for coordinated effects
export interface AnimationSequenceProps {
  steps: Array<{
    component: React.ReactNode;
    type: AnimationType;
    direction?: SlideDirection;
    delay?: number;
  }>;
  trigger?: boolean;
  className?: string;
}

export function AnimationSequence({
  steps,
  trigger = true,
  className,
}: AnimationSequenceProps) {
  const [currentStep, setCurrentStep] = useState(0);
  const [isSequenceActive, setIsSequenceActive] = useState(false);

  useEffect(() => {
    if (trigger && !isSequenceActive) {
      setIsSequenceActive(true);
      setCurrentStep(0);
    }
  }, [trigger, isSequenceActive]);

  const handleStepComplete = useCallback(() => {
    if (currentStep < steps.length - 1) {
      setCurrentStep(prev => prev + 1);
    } else {
      setIsSequenceActive(false);
    }
  }, [currentStep, steps.length]);

  return (
    <div className={cn('animation-sequence', className)}>
      {steps.map((step, index) => (
        <MicroAnimation
          key={index}
          type={step.type}
          direction={step.direction}
          delay={step.delay}
          trigger={isSequenceActive && index <= currentStep}
          onComplete={index === currentStep ? handleStepComplete : undefined}
        >
          {step.component}
        </MicroAnimation>
      ))}
    </div>
  );
}

// Morphing animation for state transitions
export interface MorphingAnimationProps {
  states: Array<{
    key: string;
    component: React.ReactNode;
  }>;
  currentState: string;
  morphDuration?: number;
  className?: string;
}

export function MorphingAnimation({
  states,
  currentState,
  morphDuration = 300,
  className,
}: MorphingAnimationProps) {
  const transitions = useTransition(
    states.find(state => state.key === currentState),
    {
      from: { opacity: 0, transform: 'scale(0.9)' },
      enter: { opacity: 1, transform: 'scale(1)' },
      leave: { opacity: 0, transform: 'scale(1.1)' },
      config: { duration: morphDuration },
    }
  );

  return (
    <div className={cn('morphing-animation', 'relative', className)}>
      {transitions((style, item) => (
        item && (
          <animated.div
            key={item.key}
            style={style}
            className="absolute inset-0"
          >
            {item.component}
          </animated.div>
        )
      ))}
    </div>
  );
}

// Particle animation for celebration effects
export interface ParticleAnimationProps {
  count?: number;
  duration?: number;
  colors?: string[];
  trigger?: boolean;
  className?: string;
}

export function ParticleAnimation({
  count = 20,
  duration = 2000,
  colors = ['#3b82f6', '#10b981', '#f59e0b', '#ef4444'],
  trigger = false,
  className,
}: ParticleAnimationProps) {
  const [particles] = useState(() =>
    Array.from({ length: count }, (_, i) => ({
      id: i,
      color: colors[i % colors.length],
      delay: Math.random() * 500,
      angle: (360 / count) * i,
      distance: 50 + Math.random() * 50,
    }))
  );

  const particleTransitions = useTransition(trigger ? particles : [], {
    from: (particle) => ({
      opacity: 0,
      transform: `translate(0px, 0px) scale(0)`,
    }),
    enter: (particle) => ({
      opacity: 1,
      transform: `translate(${Math.cos(particle.angle * Math.PI / 180) * particle.distance}px, ${Math.sin(particle.angle * Math.PI / 180) * particle.distance}px) scale(1)`,
    }),
    leave: {
      opacity: 0,
      transform: `translate(0px, -100px) scale(0)`,
    },
    config: { duration: duration / 2 },
    trail: 50,
  });

  return (
    <div className={cn('particle-animation', 'relative', 'pointer-events-none', className)}>
      {particleTransitions((style, particle) => (
        <animated.div
          key={particle.id}
          style={{
            ...style,
            backgroundColor: particle.color,
          }}
          className="absolute w-2 h-2 rounded-full top-1/2 left-1/2"
        />
      ))}
    </div>
  );
}

// Performance monitoring hook
export function useAnimationPerformance(animationName: string) {
  const startTime = useRef<number>(0);
  const frameCount = useRef<number>(0);

  const startMonitoring = useCallback(() => {
    startTime.current = performance.now();
    frameCount.current = 0;
    
    const monitor = () => {
      frameCount.current++;
      if (performance.now() - startTime.current < 1000) {
        requestAnimationFrame(monitor);
      } else {
        const fps = frameCount.current;
        console.log(`Animation "${animationName}" FPS: ${fps}`);
      }
    };
    
    requestAnimationFrame(monitor);
  }, [animationName]);

  return { startMonitoring };
}

export default MicroAnimation;