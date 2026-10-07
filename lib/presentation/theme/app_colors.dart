import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary & Accent Colors
  static const Color primaryStart = Color(0xFF6366F1); // Indigo
  static const Color primaryEnd = Color(0xFF8B5CF6);   // Purple
  static const Color accent = Color(0xFF06B6D4);       // Cyan
  static const Color warning = Color(0xFFF59E0B);      // Amber
  static const Color success = Color(0xFF10B981);      // Emerald
  static const Color error = Color(0xFFEF4444);        // Red
  static const Color info = Color(0xFF3B82F6);         // Blue

  // Dark Theme Colors
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color cardDark = Color(0xFF334155);
  static const Color cardBorder = Color(0xFF475569);

  // Light Theme Colors
  static const Color backgroundLight = Color(0xFFF8FAFC);
  // NOTE: surfaceLight is the LIGHT theme's white surface, not "a lighter
  // surface for dark mode". Thirteen dark-theme branches used it that way and
  // painted white boxes into the dark UI (date button, filter chips, message
  // box, tag chip). For a raised surface in dark mode use cardDark.
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFF1F5F9);
  static const Color cardBorderLight = Color(0xE2E8F0FF);

  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textTertiary = Color(0xFF64748B);
  static const Color textSecondaryLight = Color(0xFF64748B);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryStart, primaryEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [backgroundDark, surfaceDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Tag Colors
  static const List<Color> tagColors = [
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFF06B6D4),
    Color(0xFF3B82F6),
  ];

  // Heatmap Colors (Dark)
  static const Color heatmapEmpty = Color(0xFF1E293B);
  static const Color heatmapLow = Color(0xFF312E81);
  static const Color heatmapMedium = Color(0xFF4338CA);
  static const Color heatmapHigh = Color(0xFF6366F1);
  static const Color heatmapMax = Color(0xFF818CF8);

  // Heatmap Colors (Light)
  static const Color heatmapEmptyLight = Color(0xFFE2E8F0);
  static const Color heatmapLowLight = Color(0xFFC7D2FE);
  static const Color heatmapMediumLight = Color(0xFFA5B4FC);
  static const Color heatmapHighLight = Color(0xFF818CF8);
  static const Color heatmapMaxLight = Color(0xFF6366F1);

  static Color heatmapColor(double intensity, bool isDark) {
    if (intensity <= 0.0) return isDark ? heatmapEmpty : heatmapEmptyLight;
    if (intensity <= 0.25) return isDark ? heatmapLow : heatmapLowLight;
    if (intensity <= 0.50) return isDark ? heatmapMedium : heatmapMediumLight;
    if (intensity <= 0.75) return isDark ? heatmapHigh : heatmapHighLight;
    return isDark ? heatmapMax : heatmapMaxLight;
  }

  static Color colorForPackage(String packageName) {
    final hash = packageName.hashCode.abs();
    return tagColors[hash % tagColors.length];
  }
}
