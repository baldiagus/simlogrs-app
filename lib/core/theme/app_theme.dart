import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static const List<String> fontFallbacks = [
    'Roboto',
    'sans-serif',
  ];

  /// Tema terang global aplikasi (Material 3): warna, tipografi, kartu, app bar, tombol, dan input.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Plus Jakarta Sans',
      fontFamilyFallback: fontFallbacks,
      scaffoldBackgroundColor: AppColors.canvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryPurple,
        primary: AppColors.primaryPurple,
        surface: AppColors.surface,
        error: AppColors.danger,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        onPrimary: AppColors.surface,
        onError: AppColors.surface,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 32,
          height: 1.15,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 22,
          height: 1.25,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 18,
          height: 1.3,
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 16,
          height: 1.35,
        ),
        titleSmall: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          height: 1.45,
        ),
        bodySmall: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.3),
        labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.25),
        labelLarge: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          height: 1.3,
        ),
      ).apply(
        fontFamily: 'Plus Jakarta Sans',
        fontFamilyFallback: fontFallbacks,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          height: 1.3,
          fontFamily: 'Plus Jakarta Sans',
        ),
        iconTheme: IconThemeData(
          color: AppColors.textPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPurple,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.3,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: AppColors.primaryPurple)),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(foregroundColor: AppColors.primaryPurple)),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primaryPurple,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, fontWeight: FontWeight.w600, height: 1.3),
        unselectedLabelStyle: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, fontWeight: FontWeight.w600, height: 1.3),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceSecondary,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
        helperStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
        errorStyle: const TextStyle(color: AppColors.danger, fontSize: 12, height: 1.4),
        errorMaxLines: 3,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryPurple, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.danger, width: 1),
        ),
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 14,
          fontFamily: 'Plus Jakarta Sans',
        ),
      ),
    );
  }
}
