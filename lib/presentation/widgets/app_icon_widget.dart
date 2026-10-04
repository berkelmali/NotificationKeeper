import 'package:flutter/material.dart';
import '../providers/app_registry.dart';
import '../theme/app_colors.dart';

/// An app's real launcher icon, from Android via [AppRegistry].
///
/// Until the icon has been fetched (or for an app that is no longer
/// installed) it shows a tinted initial, then cross-fades to the real icon.
class AppIconWidget extends StatelessWidget {
  final String packageName;
  final String? appName;
  final double size;
  final double? fontSize;

  const AppIconWidget({
    super.key,
    required this.packageName,
    this.appName,
    this.size = 40,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final icon = context.appIcon(packageName);
    final Widget child;

    if (icon != null) {
      child = Image.memory(
        icon,
        key: const ValueKey('icon'),
        width: size,
        height: size,
        // Decode at the size it is drawn, not the 144px it was rendered at.
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
      );
    } else {
      final name = (appName != null && appName!.isNotEmpty)
          ? appName!
          : context.appLabel(packageName);
      final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
      final bgColor = AppColors.colorForPackage(packageName);
      child = Container(
        key: const ValueKey('initial'),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(size * 0.28),
          border: Border.all(color: bgColor.withValues(alpha: 0.4), width: 1),
        ),
        child: Center(
          child: Text(
            initial,
            style: TextStyle(
              color: bgColor,
              fontWeight: FontWeight.bold,
              fontSize: fontSize ?? (size * 0.45),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: AnimatedSwitcher(
        duration: MediaQuery.of(context).disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 220),
        child: child,
      ),
    );
  }
}
