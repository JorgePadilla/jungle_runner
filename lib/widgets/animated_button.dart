import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';

/// A reusable animated game button with scale-press, optional glow pulse,
/// haptic feedback, icon, label, and optional subtitle.
///
/// ```dart
/// AnimatedButton(
///   label: 'PLAY',
///   icon: Icons.play_arrow,
///   onTap: () => startGame(),
///   gradient: GameConstants.accentGradient,
/// )
/// ```
class AnimatedButton extends StatefulWidget {
  final String label;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onTap;
  final LinearGradient? gradient;
  final Color? color;
  final Color textColor;
  final double height;
  final double? width;
  final double borderRadius;
  final bool pulse;
  final bool haptic;
  final double fontSize;
  final EdgeInsetsGeometry? padding;

  const AnimatedButton({
    super.key,
    required this.label,
    this.subtitle,
    this.icon,
    this.onTap,
    this.gradient,
    this.color,
    this.textColor = Colors.white,
    this.height = 52,
    this.width,
    this.borderRadius = GameConstants.radiusMd,
    this.pulse = false,
    this.haptic = true,
    this.fontSize = 15,
    this.padding,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: GameConstants.durationFast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.pulse && widget.onTap != null) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse && widget.onTap != null && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.pulse && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _scaleController.forward();

  void _onTapUp(TapUpDetails _) {
    _scaleController.reverse();
    if (widget.haptic) HapticFeedback.lightImpact();
    widget.onTap?.call();
  }

  void _onTapCancel() => _scaleController.reverse();

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onTap != null;
    final effectiveColor = widget.color ?? GameConstants.accent;

    return MultiAnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _pulseAnimation]),
      builder: (context, child) {
        final glowOpacity = widget.pulse ? _pulseAnimation.value * 0.4 : 0.0;
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: effectiveColor.withValues(
                      alpha: enabled ? 0.3 + glowOpacity : 0.1),
                  blurRadius: 12 + (glowOpacity * 16),
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTapDown: enabled ? _onTapDown : null,
        onTapUp: enabled ? _onTapUp : null,
        onTapCancel: enabled ? _onTapCancel : null,
        child: AnimatedOpacity(
          duration: GameConstants.durationFast,
          opacity: enabled ? 1.0 : 0.5,
          child: Container(
            height: widget.subtitle != null ? widget.height + 18 : widget.height,
            width: widget.width,
            padding: widget.padding ??
                const EdgeInsets.symmetric(
                    horizontal: GameConstants.spacingLg,
                    vertical: GameConstants.spacingSm),
            decoration: BoxDecoration(
              gradient: enabled
                  ? widget.gradient
                  : null,
              color: enabled
                  ? (widget.gradient == null ? effectiveColor : null)
                  : Colors.grey,
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: widget.textColor, size: 20),
                      const SizedBox(width: GameConstants.spacingSm),
                    ],
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: widget.fontSize,
                        fontWeight: FontWeight.w800,
                        color: widget.textColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: widget.textColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A helper that rebuilds when any of N listenables change.
class MultiAnimatedBuilder extends StatelessWidget {
  final Listenable animation;
  final TransitionBuilder builder;
  final Widget? child;

  const MultiAnimatedBuilder({
    super.key,
    required this.animation,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: animation,
      builder: (context, _) => builder(context, child),
    );
  }
}
