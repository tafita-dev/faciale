import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFF0047AB);
  static const Color background = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF000000);
  static const Color accent = Color(0xFFF5F5F5);
  static const Color success = Color(0xFF28A745);
  static const Color error = Color(0xFFDC3545);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.background,
        onSurface: AppColors.text,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold),
        displayMedium: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold),
        bodyLarge: const TextStyle(color: AppColors.text),
        bodyMedium: const TextStyle(color: AppColors.text),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        backgroundColor: AppColors.background,
      ),
    );
  }
}
