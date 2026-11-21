import 'package:flutter/material.dart';

/// Palet warna resmi SIMLOG RS Mobile Client berdasarkan `docs/desain.md`.
class AppColors {
  AppColors._();

  // 1. Primary & Brand Accents
  static const Color primaryPurple = Color(0xFF5B50E6);
  static const Color primaryAccent = Color(0xFF6355F6);
  static const Color primaryLight = Color(0xFF766EF8);

  // 2. Gradients
  static const LinearGradient primaryHeroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF5145CD),
      Color(0xFF5B50D8),
      Color(0xFF6554D6),
    ],
  );

  static const LinearGradient secondaryCardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xB3EEEDFE),
      Color(0xFFFFFFFF),
    ],
  );

  // 3. Functional Semantics
  static const Color success = Color(0xFF047857);
  static const Color danger = Color(0xFFB91C1C);
  static const Color warning = Color(0xFF92400E);

  // 4. Category Icon Tints (Quick Actions & Category Tiles)
  static const Color tintBlueBg = Color(0xFFEFF6FF);
  static const Color tintBlue = Color(0xFF2563EB);

  static const Color tintOrangeBg = Color(0xFFFFF7ED);
  static const Color tintOrange = Color(0xFF9A3412);

  static const Color tintVioletBg = Color(0xFFF5F3FF);
  static const Color tintViolet = Color(0xFF7C3AED);

  static const Color tintTealBg = Color(0xFFF0FDFA);
  static const Color tintTeal = Color(0xFF0F766E);

  // 5. Neutrals & Canvas
  static const Color canvas = Color(0xFFF7F8FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFF1F3F9);
  static const Color border = Color(0xFFEDF0F7);

  // 6. Text Semantics
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF526179);
  static const Color textMuted = Color(0xFF596880);
}
