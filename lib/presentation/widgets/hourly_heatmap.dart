import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';

/// Feature 2 (Unique): Hourly Activity Heatmap Widget
/// Shows notification distribution across 24 hours of the day
class HourlyHeatmap extends StatelessWidget {
  final List<int> hourlyData; // 24 elements
  final int peakHour;

  const HourlyHeatmap({
    super.key,
    required this.hourlyData,
    required this.peakHour,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final maxVal = hourlyData.reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Heatmap Grid
        SizedBox(
          height: 80,
          child: Row(
            children: List.generate(24, (hour) {
              final intensity = maxVal > 0 ? hourlyData[hour] / maxVal : 0.0;
              final isActive = hour == peakHour && maxVal > 0;

              return Expanded(
                child: Tooltip(
                  message: l10n.heatmapTooltip(_formatHour(hour), hourlyData[hour]),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300 + hour * 20),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 0.5),
                    decoration: BoxDecoration(
                      color: AppColors.heatmapColor(intensity, isDark),
                      borderRadius: BorderRadius.circular(4),
                      border: isActive
                          ? Border.all(
                              color: AppColors.accent,
                              width: 1.5,
                            )
                          : null,
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.3),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        // Hour labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '00:00',
              style: TextStyle(
                fontSize: 9,
                color: isDark ? AppColors.textTertiary : AppColors.textSecondaryLight,
              ),
            ),
            Text(
              '06:00',
              style: TextStyle(
                fontSize: 9,
                color: isDark ? AppColors.textTertiary : AppColors.textSecondaryLight,
              ),
            ),
            Text(
              '12:00',
              style: TextStyle(
                fontSize: 9,
                color: isDark ? AppColors.textTertiary : AppColors.textSecondaryLight,
              ),
            ),
            Text(
              '18:00',
              style: TextStyle(
                fontSize: 9,
                color: isDark ? AppColors.textTertiary : AppColors.textSecondaryLight,
              ),
            ),
            Text(
              '23:00',
              style: TextStyle(
                fontSize: 9,
                color: isDark ? AppColors.textTertiary : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Legend
        Row(
          children: [
            Text(
              l10n.heatmapLess,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? AppColors.textTertiary : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(width: 6),
            ...List.generate(5, (i) {
              final colors = isDark
                  ? [
                      AppColors.heatmapEmpty,
                      AppColors.heatmapLow,
                      AppColors.heatmapMedium,
                      AppColors.heatmapHigh,
                      AppColors.heatmapMax,
                    ]
                  : [
                      AppColors.heatmapEmptyLight,
                      AppColors.heatmapLowLight,
                      AppColors.heatmapMediumLight,
                      AppColors.heatmapHighLight,
                      AppColors.heatmapMaxLight,
                    ];
              return Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: colors[i],
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
            const SizedBox(width: 6),
            Text(
              l10n.heatmapMore,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? AppColors.textTertiary : AppColors.textSecondaryLight,
              ),
            ),
            const Spacer(),
            if (maxVal > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.heatmapPeak(_formatHour(peakHour)),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _formatHour(int hour) {
    return '${hour.toString().padLeft(2, '0')}:00';
  }
}
