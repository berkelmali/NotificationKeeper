import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class DateHeader extends StatelessWidget {
  final String label;

  const DateHeader({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.primaryStart.withValues(alpha: 0.15)
                  : AppColors.primaryStart.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primaryStart.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.primaryStart,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 0.5,
              color: isDark ? AppColors.cardBorder : AppColors.cardBorderLight,
            ),
          ),
        ],
      ),
    );
  }
}
