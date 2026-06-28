import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// SafeBuy Nepal — Typography System
/// Headings: Poppins | Body: Inter | Nepali: Noto Sans Devanagari
abstract final class AppTextStyles {
  // ── Display ───────────────────────────────────────────────────────────────────
  static TextStyle displayLarge({String lang = 'en'}) => _heading(
        fontSize: 32, fontWeight: FontWeight.w700, lang: lang,
      );

  static TextStyle displayMedium({String lang = 'en'}) => _heading(
        fontSize: 28, fontWeight: FontWeight.w700, lang: lang,
      );

  static TextStyle displaySmall({String lang = 'en'}) => _heading(
        fontSize: 24, fontWeight: FontWeight.w600, lang: lang,
      );

  // ── Headline ──────────────────────────────────────────────────────────────────
  static TextStyle headlineLarge({String lang = 'en'}) => _heading(
        fontSize: 22, fontWeight: FontWeight.w600, lang: lang,
      );

  static TextStyle headlineMedium({String lang = 'en'}) => _heading(
        fontSize: 20, fontWeight: FontWeight.w600, lang: lang,
      );

  static TextStyle headlineSmall({String lang = 'en'}) => _heading(
        fontSize: 18, fontWeight: FontWeight.w600, lang: lang,
      );

  // ── Title ─────────────────────────────────────────────────────────────────────
  static TextStyle titleLarge({String lang = 'en'}) => _heading(
        fontSize: 17, fontWeight: FontWeight.w500, lang: lang,
      );

  static TextStyle titleMedium({String lang = 'en'}) => _heading(
        fontSize: 16, fontWeight: FontWeight.w500, lang: lang,
      );

  static TextStyle titleSmall({String lang = 'en'}) => _heading(
        fontSize: 14, fontWeight: FontWeight.w600, height: 1.4, lang: lang,
      );

  // ── Body (Inter) ──────────────────────────────────────────────────────────────
  static TextStyle bodyLarge({String lang = 'en'}) => _body(
        fontSize: 16, fontWeight: FontWeight.w400, height: 1.6,
        color: AppColors.textSecondary, lang: lang,
      );

  static TextStyle bodyMedium({String lang = 'en'}) => _body(
        fontSize: 14, fontWeight: FontWeight.w400, height: 1.5,
        color: AppColors.textSecondary, lang: lang,
      );

  static TextStyle bodySmall({String lang = 'en'}) => _body(
        fontSize: 12, fontWeight: FontWeight.w400, height: 1.5,
        color: AppColors.textMuted, lang: lang,
      );

  // ── Label (Inter) ─────────────────────────────────────────────────────────────
  static TextStyle labelLarge({String lang = 'en'}) => _body(
        fontSize: 14, fontWeight: FontWeight.w600,
        letterSpacing: 0.1, height: 1.3, lang: lang,
      );

  static TextStyle labelMedium({String lang = 'en'}) => _body(
        fontSize: 13, fontWeight: FontWeight.w500,
        letterSpacing: 0.1, height: 1.3,
        color: AppColors.textSecondary, lang: lang,
      );

  static TextStyle labelSmall({String lang = 'en'}) => _body(
        fontSize: 11, fontWeight: FontWeight.w500,
        letterSpacing: 0.5, height: 1.3,
        color: AppColors.textMuted, lang: lang,
      );

  // ── Special ───────────────────────────────────────────────────────────────────
  static TextStyle trustScore({String lang = 'en'}) => _heading(
        fontSize: 28, fontWeight: FontWeight.w800, height: 1.0, lang: lang,
      );

  static TextStyle button({String lang = 'en'}) => _heading(
        fontSize: 15, fontWeight: FontWeight.w600,
        letterSpacing: 0.2, height: 1.2, lang: lang,
      );

  static TextStyle caption({String lang = 'en'}) => _body(
        fontSize: 11, fontWeight: FontWeight.w400,
        color: AppColors.textSecondary, height: 1.4, lang: lang,
      );

  // ── Private factories ─────────────────────────────────────────────────────────

  /// Headings use Poppins (or Noto Sans Devanagari for Nepali)
  static TextStyle _heading({
    required double fontSize,
    required FontWeight fontWeight,
    double height = 1.3,
    double letterSpacing = 0.0,
    Color color = AppColors.textPrimary,
    required String lang,
  }) {
    if (lang == 'ne') {
      return GoogleFonts.notoSansDevanagari(
        fontSize: fontSize, fontWeight: fontWeight,
        height: height, letterSpacing: letterSpacing, color: color,
      );
    }
    return GoogleFonts.poppins(
      fontSize: fontSize, fontWeight: fontWeight,
      height: height, letterSpacing: letterSpacing, color: color,
    );
  }

  /// Body text uses Inter (or Noto Sans Devanagari for Nepali)
  static TextStyle _body({
    required double fontSize,
    required FontWeight fontWeight,
    double height = 1.5,
    double letterSpacing = 0.0,
    Color color = AppColors.textPrimary,
    required String lang,
  }) {
    if (lang == 'ne') {
      return GoogleFonts.notoSansDevanagari(
        fontSize: fontSize, fontWeight: fontWeight,
        height: height, letterSpacing: letterSpacing, color: color,
      );
    }
    return GoogleFonts.inter(
      fontSize: fontSize, fontWeight: fontWeight,
      height: height, letterSpacing: letterSpacing, color: color,
    );
  }
}
