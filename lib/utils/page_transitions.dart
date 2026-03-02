import 'package:flutter/material.dart';
import 'constants.dart';

/// Slide up from bottom — ideal for modals, settings, bottom sheets.
///
/// Usage:
/// ```dart
/// Navigator.push(context, SlideUpTransition(page: SettingsScreen()));
/// ```
class SlideUpTransition extends PageRouteBuilder {
  final Widget page;

  SlideUpTransition({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: GameConstants.durationPageTransition,
          reverseTransitionDuration: GameConstants.durationMedium,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(curved),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.5, end: 1.0).animate(curved),
                child: child,
              ),
            );
          },
        );
}

/// Fade + slight scale — ideal for main navigation, screen swaps.
///
/// Usage:
/// ```dart
/// Navigator.push(context, FadeScaleTransition(page: HomeScreen()));
/// ```
class FadeScaleTransition extends PageRouteBuilder {
  final Widget page;

  FadeScaleTransition({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: GameConstants.durationPageTransition,
          reverseTransitionDuration: GameConstants.durationMedium,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
                child: child,
              ),
            );
          },
        );
}

/// Slide left — ideal for forward navigation (menu → shop, etc.).
///
/// Usage:
/// ```dart
/// Navigator.push(context, SlideLeftTransition(page: ShopScreen()));
/// ```
class SlideLeftTransition extends PageRouteBuilder {
  final Widget page;

  SlideLeftTransition({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: GameConstants.durationPageTransition,
          reverseTransitionDuration: GameConstants.durationMedium,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(curved),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.6, end: 1.0).animate(curved),
                child: child,
              ),
            );
          },
        );
}
