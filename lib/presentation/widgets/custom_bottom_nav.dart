import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    // New feature: labels are now built from AppLocalizations at runtime
    // instead of a static const list, since translated strings aren't
    // compile-time constants.
    final items = [
      _NavItem(icon: Icons.dashboard_rounded, label: l10n.dashboardTitle),
      _NavItem(icon: Icons.history_rounded, label: l10n.archiveTitle),
      _NavItem(icon: Icons.apps_rounded, label: l10n.navAppsLabel),
      _NavItem(icon: Icons.settings_rounded, label: l10n.settingsTitle),
    ];

    // The one surface that really floats over moving content (extendBody: true
    // lets the list scroll underneath), so it is also the one place a backdrop
    // blur is visible - frosted glass instead of a near-opaque slab.
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      // The shadow sits outside the clip, or ClipRRect would cut it off.
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceDark.withValues(alpha: 0.72)
                    : Colors.white.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? AppColors.cardBorder
                      : AppColors.cardBorderLight,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final isSelected = index == currentIndex;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTap(index),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: isSelected
                              ? AppColors.primaryGradient
                              : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                item.icon,
                                key: ValueKey('${item.label}_$isSelected'),
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                          ? AppColors.textTertiary
                                          : AppColors.textSecondaryLight),
                                size: isSelected ? 24 : 22,
                              ),
                            ),
                            const SizedBox(height: 4),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontSize: isSelected ? 11 : 10,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                          ? AppColors.textTertiary
                                          : AppColors.textSecondaryLight),
                              ),
                              child: Text(item.label),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}
