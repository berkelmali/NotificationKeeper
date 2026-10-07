import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography uses the platform font (Roboto on Android).
///
/// This used to be google_fonts' Inter, fetched at runtime from
/// fonts.gstatic.com. Release builds have no INTERNET permission, so on a
/// real phone the fetch failed on every launch - logging an unhandled
/// exception - and Inter never loaded; users always saw the fallback. Debug
/// builds did reach Google's servers, which contradicts the app's
/// "no external servers" promise. Dropping it changes nothing users have
/// ever seen and removes the only network call the app made.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primaryStart,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryStart,
        secondary: AppColors.accent,
        surface: AppColors.surfaceLight,
        error: AppColors.error,
      ),
      textTheme: ThemeData.light().textTheme,
      cardTheme: const CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryStart,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryStart,
        secondary: AppColors.accent,
        surface: AppColors.surfaceDark,
        error: AppColors.error,
      ),
      textTheme: ThemeData.dark().textTheme,
      cardTheme: const CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
      ),
    );
  }
}
