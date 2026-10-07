import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

/// A lockout countdown as m:ss (h:mm:ss past an hour) - the same in every
/// language. Rounds up, so a fresh 30-second lockout reads 0:30, not 0:29.
String formatLockoutTime(Duration left) {
  final total = (left.inMilliseconds / 1000).ceil();
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = (total % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
}

/// Numeric PIN entry for the vault: dots that fill as you type, a keypad with
/// haptic ticks, a shake on a wrong PIN, and an optional fingerprint key.
///
/// The parent owns verification. It submits through [onSubmit] and reports a
/// wrong PIN by incrementing [errorSignal], which shakes and clears the pad.
class PinPad extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? errorText;
  final String submitLabel;
  final bool enabled;
  final int minLength;
  final int maxLength;
  final ValueChanged<String> onSubmit;
  final VoidCallback? onBiometric;
  final String? biometricLabel;
  final String deleteLabel;
  final Widget? footer;
  final int errorSignal;

  const PinPad({
    super.key,
    required this.title,
    required this.onSubmit,
    required this.submitLabel,
    required this.deleteLabel,
    this.subtitle,
    this.errorText,
    this.enabled = true,
    this.minLength = 4,
    this.maxLength = 8,
    this.onBiometric,
    this.biometricLabel,
    this.footer,
    this.errorSignal = 0,
  });

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> with SingleTickerProviderStateMixin {
  String _digits = '';
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(covariant PinPad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorSignal != oldWidget.errorSignal) {
      HapticFeedback.heavyImpact();
      setState(() => _digits = '');
      if (!MediaQuery.of(context).disableAnimations) _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _add(String digit) {
    if (!widget.enabled || _digits.length >= widget.maxLength) return;
    HapticFeedback.selectionClick();
    setState(() => _digits += digit);
  }

  void _backspace() {
    if (!widget.enabled || _digits.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _digits = _digits.substring(0, _digits.length - 1));
  }

  void _submit() {
    if (!widget.enabled || _digits.length < widget.minLength) return;
    widget.onSubmit(_digits);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final hasError = widget.errorText != null;
    final dotCount = math.max(widget.minLength, _digits.length);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.title,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textColor),
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.subtitle!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
          ),
        ],
        const SizedBox(height: 28),

        // Dots, shaken sideways on a wrong PIN.
        AnimatedBuilder(
          animation: _shake,
          builder: (context, child) {
            final t = _shake.value;
            final dx = math.sin(t * math.pi * 6) * 14 * (1 - t);
            return Transform.translate(offset: Offset(dx, 0), child: child);
          },
          child: Semantics(
            label: '${_digits.length}',
            excludeSemantics: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(dotCount, (i) {
                final filled = i < _digits.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOutBack,
                  margin: const EdgeInsets.symmetric(horizontal: 7),
                  width: filled ? 16 : 14,
                  height: filled ? 16 : 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled
                        ? (hasError ? AppColors.error : AppColors.primaryStart)
                        : Colors.transparent,
                    border: Border.all(
                      color: hasError ? AppColors.error : AppColors.textTertiary,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        SizedBox(
          height: 36,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: hasError
                  ? Text(
                      widget.errorText!,
                      key: ValueKey(widget.errorText),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),

        // Keypad.
        Opacity(
          opacity: widget.enabled ? 1 : 0.4,
          child: Column(
            children: [
              for (final row in const [
                ['1', '2', '3'],
                ['4', '5', '6'],
                ['7', '8', '9'],
              ])
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [for (final d in row) _Key(label: d, onTap: () => _add(d))],
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  widget.onBiometric != null
                      ? _Key(
                          icon: Icons.fingerprint_rounded,
                          semanticLabel: widget.biometricLabel,
                          onTap: widget.enabled ? widget.onBiometric! : () {},
                          accent: true,
                        )
                      : const SizedBox(width: _Key.size + 24, height: _Key.size + 16),
                  _Key(label: '0', onTap: () => _add('0')),
                  _Key(
                    icon: Icons.backspace_outlined,
                    semanticLabel: widget.deleteLabel,
                    onTap: _backspace,
                    onLongPress: () => setState(() => _digits = ''),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 3 * (_Key.size + 24),
          child: FilledButton(
            onPressed: widget.enabled && _digits.length >= widget.minLength ? _submit : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryStart,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(widget.submitLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
        if (widget.footer != null) ...[const SizedBox(height: 8), widget.footer!],
      ],
    );
  }
}

class _Key extends StatelessWidget {
  static const double size = 68;

  final String? label;
  final IconData? icon;
  final String? semanticLabel;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool accent;

  const _Key({
    this.label,
    this.icon,
    this.semanticLabel,
    required this.onTap,
    this.onLongPress,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Semantics(
        button: true,
        label: semanticLabel ?? label,
        excludeSemantics: true,
        child: Material(
          color: accent
              ? AppColors.primaryStart.withValues(alpha: 0.18)
              : (isDark ? AppColors.cardDark.withValues(alpha: 0.6) : AppColors.cardLight),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            onLongPress: onLongPress,
            child: SizedBox(
              width: size,
              height: size,
              child: Center(
                child: icon != null
                    ? Icon(icon, size: 28, color: accent ? AppColors.primaryStart : AppColors.textSecondary)
                    : Text(
                        label!,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
