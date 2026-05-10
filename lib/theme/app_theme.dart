import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF29ABE2);
  static const primaryDark = Color(0xFF1A8FBF);
  static const primaryLight = Color(0xFFE8F5FD);
  static const primarySurface = Color(0xFFF0F9FE);
  static const success = Color(0xFF27AE60);
  static const successLight = Color(0xFFE8F8F0);
  static const warning = Color(0xFFF39C12);
  static const warningLight = Color(0xFFFEF5E7);
  static const danger = Color(0xFFE74C3C);
  static const dangerLight = Color(0xFFFDEBE9);
  static const purple = Color(0xFF8E44AD);
  static const purpleLight = Color(0xFFF5EEF8);
  static const textDark = Color(0xFF1C2B3A);
  static const textMedium = Color(0xFF5A7184);
  static const textLight = Color(0xFF9FB3C8);
  static const background = Color(0xFFF5FAFD);
  static const cardBg = Color(0xFFFFFFFF);
  static const divider = Color(0xFFE8EFF5);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.primaryDark,
          surface: AppColors.cardBg,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textDark,
          elevation: 0,
          scrolledUnderElevation: 1,
          shadowColor: AppColors.divider,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.cardBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.divider),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          extendedPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.primarySurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          labelStyle: const TextStyle(color: AppColors.textMedium, fontSize: 13),
          hintStyle: const TextStyle(color: AppColors.textLight),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          space: 1,
          thickness: 1,
        ),
      );
}
