import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════
// CORE: App Theme — Udemy-inspired professional palette
// ═══════════════════════════════════════════════════════════
class AppTheme {
  AppTheme._();

  // Colours
  static const Color primary    = Color(0xFF1A73E8);
  static const Color secondary  = Color(0xFF0D47A1);
  static const Color accent     = Color(0xFFF5A623);
  static const Color success    = Color(0xFF2ECC71);
  static const Color error      = Color(0xFFE74C3C);
  static const Color warning    = Color(0xFFF39C12);
  static const Color bg         = Color(0xFFF8F9FF);
  static const Color cardBg     = Color(0xFFFFFFFF);
  static const Color textDark   = Color(0xFF1A1A2E);
  static const Color textGrey   = Color(0xFF6B7280);
  static const Color divider    = Color(0xFFE5E7EB);
  static const Color shimmerBase= Color(0xFFE0E0E0);
  static const Color shimmerHigh= Color(0xFFF5F5F5);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      secondary: secondary,
      error: error,
      background: bg,
      surface: cardBg,
    ),
    scaffoldBackgroundColor: bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: textDark,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textDark,
      ),
      iconTheme: IconThemeData(color: textDark),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 15),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error),
      ),
      hintStyle: const TextStyle(color: textGrey, fontSize: 14),
      labelStyle: const TextStyle(color: textGrey, fontFamily: 'Poppins'),
    ),
    cardTheme: CardThemeData(
  color: cardBg,
  elevation: 2,
  shadowColor: Colors.black.withOpacity(0.08),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  clipBehavior: Clip.antiAlias,
),
    chipTheme: ChipThemeData(
      backgroundColor: primary.withOpacity(0.1),
      selectedColor: primary,
      labelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primary,
      unselectedItemColor: textGrey,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontFamily: 'Poppins', fontSize: 11),
      elevation: 8,
    ),
    textTheme: const TextTheme(
      displayLarge : TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800, color: textDark),
      displayMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: textDark),
      headlineLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: textDark),
      headlineMedium:TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: textDark),
      titleLarge   : TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: textDark),
      titleMedium  : TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, color: textDark),
      bodyLarge    : TextStyle(fontFamily: 'Poppins', color: textDark),
      bodyMedium   : TextStyle(fontFamily: 'Poppins', color: textGrey),
      labelLarge   : TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
    ),
    dividerTheme: const DividerThemeData(color: divider, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentTextStyle: const TextStyle(fontFamily: 'Poppins'),
    ),
  );
}
