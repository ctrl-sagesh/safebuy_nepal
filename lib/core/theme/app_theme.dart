import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

final ThemeData appTheme = _buildTheme();

ThemeData _buildTheme() {
  final base = ThemeData(useMaterial3: true);
  return base.copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      error: AppColors.error,
      surface: AppColors.surface,
    ),
    scaffoldBackgroundColor: AppColors.bgSecondary,

    // ── AppBar ──────────────────────────────────────────────────────────────────
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bgPrimary,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      titleTextStyle: GoogleFonts.poppins(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
    ),

    // ── Elevated Button ─────────────────────────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        disabledBackgroundColor: AppColors.grey200,
        disabledForegroundColor: AppColors.grey400,
        elevation: 2,
        shadowColor: AppColors.shadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: AppSpacing.xl,
        ),
        minimumSize: const Size(double.infinity, 56),
        textStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    ),

    // ── Outlined Button ─────────────────────────────────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        disabledForegroundColor: AppColors.grey400,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: AppSpacing.xl,
        ),
        minimumSize: const Size(double.infinity, 56),
        textStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    ),

    // ── Text Button ──────────────────────────────────────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    ),

    // ── Input ─────────────────────────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgPrimary,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 15,
      ),
      hintStyle: GoogleFonts.inter(
        color: AppColors.textMuted,
        fontSize: 14,
      ),
      labelStyle: GoogleFonts.inter(
        color: AppColors.textSecondary,
        fontSize: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.borderLight, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.borderLight, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      prefixIconColor: AppColors.primary,
      suffixIconColor: AppColors.textMuted,
    ),

    // ── Card ─────────────────────────────────────────────────────────────────────
    cardTheme: CardThemeData(
      color: AppColors.bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      margin: EdgeInsets.zero,
    ),

    // ── Navigation Bar ────────────────────────────────────────────────────────────
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.bgPrimary,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.primary.withValues(alpha: 0.1),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return GoogleFonts.inter(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? AppColors.primary : AppColors.textMuted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? AppColors.primary : AppColors.textMuted,
          size: 22,
        );
      }),
    ),

    // ── Chip ──────────────────────────────────────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.primary50,
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.primary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      side: BorderSide.none,
    ),

    // ── Divider ───────────────────────────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: AppColors.borderLight,
      thickness: 1,
      space: 1,
    ),

    // ── Text Theme ────────────────────────────────────────────────────────────────
    textTheme: GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 32),
      displayMedium: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 28),
      displaySmall: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 24),
      headlineLarge: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 22),
      headlineMedium: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 20),
      headlineSmall: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
      titleLarge: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 17),
      titleMedium: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 16),
    ),
  );
}
