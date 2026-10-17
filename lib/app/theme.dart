import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color teal = Color(0xFF0E8F8C);
  static const Color tealLight = Color(0xFFE0F4F3);
  static const Color deepBlue = Color(0xFF12355B);
  static const Color background = Color(0xFFF7FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF16263A);
  static const Color textSecondary = Color(0xFF55657A);
  static const Color border = Color(0xFFE2E8F0);
  static const Color shadow = Color(0x140B2540);
  static const Color danger = Color(0xFFB3261E);
  static const Color dangerLight = Color(0xFFFDECEA);
  static const Color warning = Color(0xFF8A5A00);
  static const Color warningLight = Color(0xFFFFF4DB);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.teal).copyWith(
    primary: AppColors.teal,
    secondary: AppColors.deepBlue,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.deepBlue,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.tealLight,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: AppColors.deepBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    chipTheme: const ChipThemeData(
      selectedColor: AppColors.tealLight,
      checkmarkColor: AppColors.teal,
    ),
  );
}
