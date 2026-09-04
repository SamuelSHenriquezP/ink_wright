import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Light Mode Colors (Monochrome B&W Minimalist)
  static const Color lightBgPrimary = Color(0xFFFAFAFA);
  static const Color lightSurfaceCard = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF111111);
  static const Color lightTextSecondary = Color(0xFF666666);
  static const Color lightAccentMint = Color(0xFF000000); // Main Accent is pure sleek black
  static const Color lightAccentMintLight = Color(0xFFF4F4F5);
  static const Color lightBorderSubtle = Color(0xFFE4E4E7);
  static const Color lightDivider = Color(0xFFEEEEEE);

  // Dark Mode Colors (Monochrome B&W Minimalist)
  static const Color darkBgPrimary = Color(0xFF121212);
  static const Color darkSurfaceCard = Color(0xFF1C1C1E);
  static const Color darkTextPrimary = Color(0xFFF4F4F5);
  static const Color darkTextSecondary = Color(0xFFA1A1AA);
  static const Color darkAccentMint = Color(0xFFFFFFFF); // Main Accent is crisp white
  static const Color darkAccentMintLight = Color(0xFF27272A);
  static const Color darkBorderSubtle = Color(0xFF27272A);

  // Radii
  static const double cardRadius = 18.0;
  static const double pillRadius = 30.0;
  static const double sheetRadius = 24.0;

  // Soft UI Shadows
  static List<BoxShadow> getSoftShadow(bool isDark) {
    if (isDark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.02),
          blurRadius: 1,
          offset: const Offset(0, -1),
        ),
      ];
    }
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.02),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ];
  }

  // Light Theme Data
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBgPrimary,
      colorScheme: const ColorScheme.light(
        primary: lightAccentMint,
        onPrimary: Colors.white,
        surface: lightSurfaceCard,
        onSurface: lightTextPrimary,
        secondary: lightAccentMintLight,
        outline: lightBorderSubtle,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          color: lightTextPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: lightTextPrimary,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: lightTextPrimary,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: lightTextSecondary,
          fontSize: 14,
          height: 1.4,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          color: lightTextPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightSurfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: lightBorderSubtle, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: lightDivider,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // Dark Theme Data
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBgPrimary,
      colorScheme: const ColorScheme.dark(
        primary: darkAccentMint,
        onPrimary: Colors.black,
        surface: darkSurfaceCard,
        onSurface: darkTextPrimary,
        secondary: darkAccentMintLight,
        outline: darkBorderSubtle,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          color: darkTextPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: darkTextPrimary,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: darkTextPrimary,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: darkTextSecondary,
          fontSize: 14,
          height: 1.4,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          color: darkTextPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: darkBorderSubtle, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: darkBorderSubtle,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // Editor Typography Style (Serif Paper Style)
  static TextStyle editorStyle({required bool isDark, double fontSize = 16.5}) {
    return GoogleFonts.lora(
      fontSize: fontSize,
      height: 1.65,
      color: isDark ? darkTextPrimary : lightTextPrimary,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
    );
  }
}
