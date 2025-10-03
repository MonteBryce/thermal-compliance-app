import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Custom page transitions for enhanced navigation experience
class RouteTransitions {
  
  /// Slide transition from right to left (default forward navigation)
  static Page<T> slideTransition<T extends Object?>(
    BuildContext context,
    GoRouterState state,
    Widget child, {
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: animation.drive(
            Tween(begin: const Offset(1.0, 0.0), end: Offset.zero).chain(
              CurveTween(curve: Curves.easeInOut),
            ),
          ),
          child: child,
        );
      },
    );
  }
  
  /// Fade transition for modal-like screens
  static Page<T> fadeTransition<T extends Object?>(
    BuildContext context,
    GoRouterState state,
    Widget child, {
    Duration duration = const Duration(milliseconds: 250),
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation.drive(
            CurveTween(curve: Curves.easeInOut),
          ),
          child: child,
        );
      },
    );
  }
  
  /// Scale transition for important screens
  static Page<T> scaleTransition<T extends Object?>(
    BuildContext context,
    GoRouterState state,
    Widget child, {
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: animation.drive(
            Tween(begin: 0.8, end: 1.0).chain(
              CurveTween(curve: Curves.elasticOut),
            ),
          ),
          child: FadeTransition(
            opacity: animation.drive(
              CurveTween(curve: Curves.easeIn),
            ),
            child: child,
          ),
        );
      },
    );
  }
  
  /// Slide up transition for bottom sheet-like screens
  static Page<T> slideUpTransition<T extends Object?>(
    BuildContext context,
    GoRouterState state,
    Widget child, {
    Duration duration = const Duration(milliseconds: 350),
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: animation.drive(
            Tween(begin: const Offset(0.0, 1.0), end: Offset.zero).chain(
              CurveTween(curve: Curves.easeOutCubic),
            ),
          ),
          child: child,
        );
      },
    );
  }
  
  /// Rotation + fade transition for special screens
  static Page<T> rotationTransition<T extends Object?>(
    BuildContext context,
    GoRouterState state,
    Widget child, {
    Duration duration = const Duration(milliseconds: 500),
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return RotationTransition(
          turns: animation.drive(
            Tween(begin: 0.1, end: 0.0).chain(
              CurveTween(curve: Curves.elasticOut),
            ),
          ),
          child: FadeTransition(
            opacity: animation.drive(
              CurveTween(curve: Curves.easeInOut),
            ),
            child: child,
          ),
        );
      },
    );
  }
  
  /// No transition (instant)
  static Page<T> noTransition<T extends Object?>(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) {
    return NoTransitionPage<T>(
      key: state.pageKey,
      child: child,
    );
  }
  
  /// Get appropriate transition based on route type
  static Page<T> getTransitionForRoute<T extends Object?>(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) {
    final location = state.matchedLocation;
    
    // Entry forms get slide up transition
    if (location.contains('/entry/')) {
      return slideUpTransition<T>(context, state, child);
    }
    
    // System metrics gets scale transition
    if (location.contains('systemMetrics') || location.contains('finalReadings')) {
      return scaleTransition<T>(context, state, child);
    }
    
    // Review screens get fade transition
    if (location.contains('/review')) {
      return fadeTransition<T>(context, state, child);
    }
    
    // Project summary gets rotation transition (special)
    if (location.contains('/summary')) {
      return rotationTransition<T>(context, state, child);
    }
    
    // Default slide transition for all others
    return slideTransition<T>(context, state, child);
  }
}

/// Loading page widget for async route loading
class LoadingPage extends StatelessWidget {
  final String? message;
  final Color? backgroundColor;

  const LoadingPage({
    super.key,
    this.message,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? const Color(0xFF0B132B),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Enhanced page with custom transitions and loading states
class EnhancedPage<T> extends Page<T> {
  final Widget child;
  final bool isLoading;
  final String? loadingMessage;
  final Duration transitionDuration;
  final RouteTransitionsBuilder? transitionsBuilder;

  const EnhancedPage({
    required this.child,
    this.isLoading = false,
    this.loadingMessage,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.transitionsBuilder,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  @override
  Route<T> createRoute(BuildContext context) {
    return PageRouteBuilder<T>(
      settings: this,
      pageBuilder: (context, animation, secondaryAnimation) {
        if (isLoading) {
          return LoadingPage(message: loadingMessage);
        }
        return child;
      },
      transitionDuration: transitionDuration,
      reverseTransitionDuration: transitionDuration,
      transitionsBuilder: transitionsBuilder ?? _defaultTransitionsBuilder,
    );
  }

  Widget _defaultTransitionsBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: animation.drive(
        Tween(begin: const Offset(1.0, 0.0), end: Offset.zero).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
      ),
      child: child,
    );
  }
}