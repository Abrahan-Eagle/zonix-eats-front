import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zonix/features/utils/app_colors.dart';

const Color stitchPrimary = AppColors.blue;
const Color stitchBgLight = AppColors.scaffoldBgLight;
const Color stitchBgDark = AppColors.backgroundDark;
const Color stitchSurfaceDark = AppColors.grayDark;
const Color stitchCardCream = AppColors.stitchCardCream;
const Color stitchNavBg = AppColors.stitchNavBg;
const Color stitchNavActive = AppColors.blue;
const Color stitchSlate400 = AppColors.stitchSlate400;

ThemeData buildStitchLightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    primaryColor: stitchPrimary,
    scaffoldBackgroundColor: stitchBgLight,
    appBarTheme: AppBarTheme(
      backgroundColor: stitchPrimary,
      foregroundColor: AppColors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        color: AppColors.white,
        fontWeight: FontWeight.bold,
        fontSize: 22,
      ),
      iconTheme: const IconThemeData(color: AppColors.white),
    ),
    colorScheme: const ColorScheme.light(
      primary: stitchPrimary,
      secondary: AppColors.orange,
      error: AppColors.red,
      surface: stitchBgLight,
      onPrimary: AppColors.white,
      onSurface: AppColors.stitchTextDark,
    ),
    cardColor: stitchCardCream,
    cardTheme: CardThemeData(
      color: stitchCardCream,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: stitchPrimary,
        foregroundColor: AppColors.white,
        minimumSize: const Size(0, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 48),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: stitchPrimary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: stitchBgLight,
      selectedItemColor: stitchNavActive,
      unselectedItemColor: stitchSlate400,
      type: BottomNavigationBarType.fixed,
    ),
  );
}

ThemeData buildStitchDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    primaryColor: stitchPrimary,
    scaffoldBackgroundColor: stitchBgDark,
    appBarTheme: AppBarTheme(
      backgroundColor: stitchBgDark,
      foregroundColor: AppColors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        color: AppColors.white,
        fontWeight: FontWeight.bold,
        fontSize: 22,
      ),
      iconTheme: const IconThemeData(color: AppColors.white),
    ),
    colorScheme: const ColorScheme.dark(
      primary: stitchPrimary,
      secondary: AppColors.orangeCoral,
      error: AppColors.red,
      surface: stitchSurfaceDark,
      onPrimary: AppColors.white,
      onSurface: AppColors.white,
    ),
    cardColor: stitchSurfaceDark,
    cardTheme: CardThemeData(
      color: stitchSurfaceDark,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: stitchPrimary,
        foregroundColor: AppColors.white,
        minimumSize: const Size(0, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 48),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: stitchPrimary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: stitchSurfaceDark,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: stitchNavBg,
      selectedItemColor: stitchNavActive,
      unselectedItemColor: stitchSlate400,
      type: BottomNavigationBarType.fixed,
    ),
  );
}
