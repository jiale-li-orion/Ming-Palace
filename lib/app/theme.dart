import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Ming Palace App Theme  (Project.md §3 – outdoor mobile viewing constraints)
// ---------------------------------------------------------------------------
//
// Design rationale:
//   - **High contrast** — text is cream-on-near-black for direct-sunlight
//     readability at the Ming Palace Ruins site.
//   - **Chinese red accent** (#8B0000) — historical reference to Ming Dynasty
//     palace architecture.
//   - **Large type** — body ≥ 16 sp, titles ≥ 20 sp for arm's-length mobile
//     viewing.
//   - **System font** — Flutter's default Material font stack includes CJK
//     fallback via Noto Sans CJK on most Android devices.
// ---------------------------------------------------------------------------

/// App-wide colour constants.
abstract final class AppColors {
  static const Color primary = Color(0xFF8B0000); // Chinese / Ming red
  static const Color primaryLight = Color(0xFFB22222); // firebrick
  static const Color background = Color(0xFF1A1A1A); // near-black
  static const Color surface = Color(0xFF2D2D2D); // dark card
  static const Color surfaceVariant = Color(0xFF3A3A3A);
  static const Color textPrimary = Color(0xFFFFF8E7); // cream
  static const Color textSecondary = Color(0xFFBDBDBD); // light grey
  static const Color textDisabled = Color(0xFF757575);
  static const Color error = Color(0xFFCF6679);
  static const Color divider = Color(0xFF424242);
}

/// The single [ThemeData] used across the entire app.
///
/// Call [AppTheme.darkTheme] wherever a `ThemeData` is required
/// (e.g. `MaterialApp(theme: AppTheme.darkTheme)`).
abstract final class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      // ---- colour scheme ---------------------------------------------------
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.textPrimary,
        secondary: AppColors.primaryLight,
        onSecondary: AppColors.textPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: Colors.black,
        outline: AppColors.divider,
      ),
      scaffoldBackgroundColor: AppColors.background,

      // ---- typography ------------------------------------------------------
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 18,
          color: AppColors.textPrimary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          color: AppColors.textPrimary,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: 0.5,
        ),
      ),

      // ---- components ------------------------------------------------------
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: 24,
      ),
    );
  }
}
