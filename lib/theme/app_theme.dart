import 'package:flutter/material.dart';

/// Central place for the app's color palette and [ThemeData].
class AppColors {
  AppColors._();

  static const Color background = Color(0xFFFFF8E7);
  static const Color purple = Color(0xFF6D28D9);
  static const Color purpleDark = Color(0xFF2E1065);
  static const Color orange = Color(0xFFF97316);
  static const Color cyan = Color(0xFF06B6D4);
  static const Color pink = Color(0xFFEC4899);
  static const Color green = Color(0xFF10B981);
  static const Color slate = Color(0xFF64748B);
  static const Color gold = Color(0xFFFFD65C);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Cairo',
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.light(
      primary: AppColors.purple,
      secondary: AppColors.orange,
      tertiary: AppColors.cyan,
      surface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.purpleDark,
      titleTextStyle: TextStyle(
        color: AppColors.purpleDark,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        fontFamily: 'Changa',
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shadowColor: const Color(0x14000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFF3E8FF)),
      ),
    ),
    chipTheme: ChipThemeData(
      selectedColor: AppColors.purple,
      backgroundColor: const Color(0xFFF3E8FF),
      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Color(0xFFEDE9FE),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
  );
}
