import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

final ThemeData appTheme = _buildTheme();

// Contrast tokens used across all form/selection UI. Text on white must
// stay dark; Material fallbacks are never allowed to tint form text.
const _inkStrong = Color(0xFF1A1A1A); // headings, input text
const _inkLabel = Color(0xFF555555); // field labels
const _inkHint = Color(0xFF9E9E9E); // placeholders, muted icons
const _borderIdle = Color(0xFFE0E0E0);

ThemeData _buildTheme() {
  final base = ThemeData(useMaterial3: true);
  return base.copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      error: AppColors.error,
      surface: AppColors.surface,
      onSurface: _inkStrong,
    ),
    scaffoldBackgroundColor: AppColors.bgSecondary,
    // Dropdown menus paint on canvasColor; keep it pure white so menu
    // items are always dark-on-white.
    canvasColor: Colors.white,

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
    // Explicit dark-on-white styling: labels #555555, input text #1A1A1A,
    // placeholders #9E9E9E, idle borders #E0E0E0, focus #1565C0.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 15,
      ),
      hintStyle: GoogleFonts.inter(
        color: _inkHint,
        fontSize: 14,
      ),
      labelStyle: GoogleFonts.inter(
        color: _inkLabel,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: GoogleFonts.inter(
        color: AppColors.primary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _borderIdle, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _borderIdle, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFC62828), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFC62828), width: 2),
      ),
      prefixIconColor: _inkHint,
      suffixIconColor: _inkHint,
    ),

    // ── Dropdown menus ───────────────────────────────────────────────────────────
    // Every dropdown: white sheet, dark #1A1A1A items, capped height.
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
        maximumSize: WidgetStatePropertyAll(Size.fromHeight(300)),
      ),
      textStyle: GoogleFonts.inter(
        color: _inkStrong,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),

    // ── Dialogs & sheets: white surfaces, dark text ──────────────────────────────
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.poppins(
        color: _inkStrong,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: GoogleFonts.inter(
        color: AppColors.textSecondary,
        fontSize: 14,
        height: 1.5,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: Colors.white,
    ),
    listTileTheme: ListTileThemeData(
      textColor: _inkStrong,
      iconColor: _inkLabel,
      titleTextStyle: GoogleFonts.inter(
        color: _inkStrong,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      subtitleTextStyle: GoogleFonts.inter(
        color: _inkLabel,
        fontSize: 12.5,
      ),
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
    // Every style carries an explicit dark color so no widget (dropdown
    // items, dialogs, sheets) can inherit a tinted Material fallback.
    textTheme: GoogleFonts.interTextTheme()
        .apply(bodyColor: _inkStrong, displayColor: _inkStrong)
        .copyWith(
      displayLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.w700, fontSize: 32, color: _inkStrong),
      displayMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.w700, fontSize: 28, color: _inkStrong),
      displaySmall: GoogleFonts.poppins(
          fontWeight: FontWeight.w600, fontSize: 24, color: _inkStrong),
      headlineLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.w600, fontSize: 22, color: _inkStrong),
      headlineMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.w600, fontSize: 20, color: _inkStrong),
      headlineSmall: GoogleFonts.poppins(
          fontWeight: FontWeight.w600, fontSize: 18, color: _inkStrong),
      titleLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.w500, fontSize: 17, color: _inkStrong),
      titleMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.w500, fontSize: 16, color: _inkStrong),
    ),
  );
}
