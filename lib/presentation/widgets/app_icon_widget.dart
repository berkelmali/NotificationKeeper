import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

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
    final name = (appName != null && appName!.isNotEmpty)
        ? appName!
        : packageName.split('.').last;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final bgColor = AppColors.colorForPackage(packageName);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: bgColor.withValues(alpha: 0.4),
          width: 1,
        ),
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
}
