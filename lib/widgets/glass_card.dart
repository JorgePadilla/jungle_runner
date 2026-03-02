import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// A reusable frosted glass card with customizable blur, opacity, and border.
///
/// ```dart
/// GlassCard(
///   borderRadius: 16,
///   child: Text('Hello'),
/// )
/// ```
class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final Color? borderColor;
  final double borderWidth;
  final bool glowBorder;
  final Color glowColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 12.0,
    this.opacity = 0.12,
    this.borderRadius = GameConstants.radiusLg,
    this.borderColor,
    this.borderWidth = 1.0,
    this.glowBorder = false,
    this.glowColor = GameConstants.accent,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: glowBorder
            ? [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.3),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.1),
                  blurRadius: 32,
                  spreadRadius: 2,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ??
                    (glowBorder
                        ? glowColor.withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.15)),
                width: borderWidth,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
