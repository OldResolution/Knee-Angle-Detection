import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors (Kinetic Sanctuary)
  static const Color primaryDark = Color(0xFF524587);
  static const Color primary = Color(0xFF6A5BA1);
  static const Color surface1 = Color(0xFFF6ECF8);
  static const Color surface2 = Color(0xFFF2F2F6);
  static const Color success = Color(0xFF8B7D14); // Olive green
  static const Color error = Color(0xFFB72A2A); // Red
  static const Color textPrimary = Color(0xFF1E1B2E);
  static const Color textSecondary = Color(0xFF6B6680);
  static const Color background = Colors.white;

  // Spacing (8pt system)
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing16 = 16.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;

  // Theme Data
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.manropeTextTheme();

    return ThemeData(
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: primaryDark,
        surface: background,
        error: error,
      ),
      scaffoldBackgroundColor: background,
      useMaterial3: true,
      
      // Typography
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displayMedium: baseTextTheme.displayMedium?.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.bold, // Headline MD
          color: textPrimary,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600, // Headline SM
          color: textPrimary,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimary,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textPrimary,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.normal, // Caption
          color: textSecondary,
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface1,
        contentPadding: const EdgeInsets.symmetric(horizontal: spacing16, vertical: spacing16),
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
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        prefixIconColor: primary,
        suffixIconColor: primary,
        hintStyle: const TextStyle(color: textSecondary),
      ),

      // Buttons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: spacing16, horizontal: spacing24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 16, 
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: spacing16, horizontal: spacing24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 16, 
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.w600, 
            fontSize: 16,
          ),
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: surface1,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        margin: const EdgeInsets.all(spacing8),
      ),

      // Icons
      iconTheme: const IconThemeData(
        color: primary,
        size: 24,
      ),
    );
  }
}
