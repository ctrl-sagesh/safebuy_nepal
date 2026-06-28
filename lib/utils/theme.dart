import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(AppColors.primary),
    primary: const Color(AppColors.primary),
    secondary: const Color(AppColors.secondary),
    surface: const Color(AppColors.background),
  ),
  scaffoldBackgroundColor: const Color(AppColors.background),
  textTheme: GoogleFonts.poppinsTextTheme(),
  appBarTheme: AppBarTheme(
    backgroundColor: const Color(AppColors.primary),
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: GoogleFonts.poppins(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(AppColors.primary),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
      elevation: 2,
      textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
      side: const BorderSide(color: Color(AppColors.primary)),
      textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(AppColors.divider)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(AppColors.divider)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(AppColors.primary), width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    prefixIconColor: const Color(AppColors.primary),
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 0,
    shadowColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: Color(AppColors.divider), width: 1),
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: const Color(AppColors.primary).withValues(alpha: 0.08),
    labelStyle: GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: const Color(AppColors.primary),
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: Colors.white,
    indicatorColor: const Color(AppColors.primary).withValues(alpha: 0.12),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(AppColors.primary),
        );
      }
      return GoogleFonts.poppins(fontSize: 11, color: const Color(AppColors.textGrey));
    }),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(color: Color(AppColors.primary));
      }
      return const IconThemeData(color: Color(AppColors.textGrey));
    }),
  ),
);
