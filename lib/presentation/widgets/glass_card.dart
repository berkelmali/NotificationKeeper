import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

/// The app's card surface.
///
/// [blur] used to be always on: every card in a scrolling list ran a
/// `BackdropFilter`, one of the most expensive things Flutter can draw (a
/// separate layer plus a read-back of everything behind it) - while sitting at
/// 70-80 % opacity over a flat background, where the blur is all but invisible.
/// It is now opt-in, for surfaces that actually float over moving content.
///
/// Tappable cards press in slightly, so a tap is felt before the next screen
/// appears; with reduced motion turned on they skip the animation.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double borderRadius;
  final Border? border;
  final Color? color;
  final bool blur;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius = 16.0,
    this.border,
    this.color,
    this.blur = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = color ??
        (isDark
            ? AppColors.surfaceDark.withValues(alpha: blur ? 0.7 : 0.92)
            : AppColors.surfaceLight.withValues(alpha: blur ? 0.8 : 0.96));

    final cardBorder = border ??
        Border.all(
          color: isDark ? AppColors.cardBorder : AppColors.cardBorderLight,
          width: 1,
        );

    final radius = BorderRadius.circular(borderRadius);
    final inner = Padding(padding: padding ?? const EdgeInsets.all(16), child: child);

    final Widget content = Container(
      margin: margin,
      decoration: BoxDecoration(color: cardColor, borderRadius: radius, border: cardBorder),
      child: blur
          ? ClipRRect(
              borderRadius: radius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: inner,
              ),
            )
          : inner,
    );

    if (onTap == null) return content;
    return _Pressable(onTap: onTap!, child: content);
  }
}

class _Pressable extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _Pressable({required this.onTap, required this.child});

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressed = false;

  void _set(bool pressed) {
    if (_pressed != pressed) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapCancel: () => _set(false),
      onTapUp: (_) => _set(false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed && !reduceMotion ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
