// =============================================================================
// BONUS FEATURE: Advanced Page Transitions
// =============================================================================
// This file implements custom page route transitions for smoother navigation
// between forum screens. Instead of the default platform-specific transitions,
// we use custom animations that feel more polished and app-specific.
//
// TRANSITION TYPES:
// 1. FadeScalePageRoute: Fade in with subtle scale - for detail pages
// 2. SlideUpPageRoute: Slide up from bottom - for modal-like screens
// 3. SharedAxisPageRoute: Shared axis transition - for hierarchical navigation
// 4. HeroPageRoute: Supports Hero animations between screens
//
// USAGE:
// Instead of MaterialPageRoute, use these custom routes:
//   Navigator.push(context, FadeScalePageRoute(page: DetailPage()));
//   Navigator.push(context, SlideUpPageRoute(page: FormPage()));
//
// CUSTOMIZATION:
// Each route accepts optional duration and curve parameters for fine-tuning.
// =============================================================================

import 'package:flutter/material.dart';

/// Page route with fade and scale transition
/// Best used for navigating to detail pages
class FadeScalePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;
  final Curve curve;

  FadeScalePageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeOutCubic,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Fade animation
            final fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: curve,
            ));

            // Scale animation (subtle scale from 0.95 to 1.0)
            final scaleAnimation = Tween<double>(
              begin: 0.95,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: curve,
            ));

            return FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(
                scale: scaleAnimation,
                child: child,
              ),
            );
          },
        );
}

/// Page route with slide up from bottom transition
/// Best used for form pages, modals, and action sheets
class SlideUpPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;
  final Curve curve;

  SlideUpPageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 350),
    this.curve = Curves.easeOutCubic,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Slide from bottom
            final slideAnimation = Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: curve,
            ));

            // Subtle fade for polish
            final fadeAnimation = Tween<double>(
              begin: 0.5,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
            ));

            return SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
        );
}

/// Page route with horizontal slide and fade transition
/// Best used for hierarchical navigation (list -> detail)
class SlideRightPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;
  final Curve curve;

  SlideRightPageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 350),
    this.curve = Curves.easeOutCubic,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Slide from right
            final slideAnimation = Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: curve,
            ));

            // Fade in
            final fadeAnimation = Tween<double>(
              begin: 0.3,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
            ));

            // Previous page slides left slightly
            final secondarySlideAnimation = Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-0.15, 0),
            ).animate(CurvedAnimation(
              parent: secondaryAnimation,
              curve: curve,
            ));

            return SlideTransition(
              position: secondarySlideAnimation,
              child: SlideTransition(
                position: slideAnimation,
                child: FadeTransition(
                  opacity: fadeAnimation,
                  child: child,
                ),
              ),
            );
          },
        );
}

/// Page route optimized for Hero animations
/// Provides a clean fade that doesn't interfere with Hero transitions
class HeroPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  HeroPageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 500),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Simple fade that lets Hero animations shine
            final fadeAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            );

            return FadeTransition(
              opacity: fadeAnimation,
              child: child,
            );
          },
        );
}

/// Page route with a bounce effect
/// Best used for celebratory or attention-grabbing transitions
class BouncePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  BouncePageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 600),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Scale with elastic bounce
            final scaleAnimation = Tween<double>(
              begin: 0.8,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.elasticOut,
            ));

            // Fade in quickly
            final fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
            ));

            return FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(
                scale: scaleAnimation,
                child: child,
              ),
            );
          },
        );
}

/// Helper class with static methods for creating page transitions
/// Usage: ForumPageTransitions.fadeIn(MyPage())
class ForumPageTransitions {
  /// Create a fade-in page route
  static PageRouteBuilder<T> fadeIn<T>(Widget page) {
    return FadeScalePageRoute<T>(page: page);
  }

  /// Create a slide-from-right page route
  static PageRouteBuilder<T> slideFromRight<T>(Widget page) {
    return SlideRightPageRoute<T>(page: page);
  }

  /// Create a slide-up page route (for modals/forms)
  static PageRouteBuilder<T> slideUp<T>(Widget page) {
    return SlideUpPageRoute<T>(page: page);
  }

  /// Create a hero-friendly page route
  static PageRouteBuilder<T> hero<T>(Widget page) {
    return HeroPageRoute<T>(page: page);
  }

  /// Create a bounce page route
  static PageRouteBuilder<T> bounce<T>(Widget page) {
    return BouncePageRoute<T>(page: page);
  }
}

/// Helper extension for easier navigation with custom transitions
extension ForumNavigation on NavigatorState {
  /// Push with fade-scale transition (for detail pages)
  Future<T?> pushFadeScale<T>(Widget page) {
    return push<T>(FadeScalePageRoute(page: page));
  }

  /// Push with slide-up transition (for forms/modals)
  Future<T?> pushSlideUp<T>(Widget page) {
    return push<T>(SlideUpPageRoute(page: page));
  }

  /// Push with slide-right transition (for hierarchical navigation)
  Future<T?> pushSlideRight<T>(Widget page) {
    return push<T>(SlideRightPageRoute(page: page));
  }

  /// Push with hero-friendly transition
  Future<T?> pushHero<T>(Widget page) {
    return push<T>(HeroPageRoute(page: page));
  }
}

/// Animated container that can be used inside detail pages
/// to animate content as it appears
class AnimatedPageContent extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const AnimatedPageContent({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  State<AnimatedPageContent> createState() => _AnimatedPageContentState();
}

class _AnimatedPageContentState extends State<AnimatedPageContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Start animation after delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
