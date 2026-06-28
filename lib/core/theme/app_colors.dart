import 'package:flutter/material.dart';

/// SafeBuy Nepal — Design System Color Tokens
/// All colors across the app MUST reference these constants only.
abstract final class AppColors {
  // ── Primary Palette ──────────────────────────────────────────────────────────
  static const primary      = Color(0xFF1565C0);
  static const primaryDark  = Color(0xFF0D47A1);
  static const primaryLight = Color(0xFF1976D2);
  static const accentBlue   = Color(0xFF42A5F5);
  static const accentCyan   = Color(0xFF00BCD4);

  // Material-style tonal palette (for chips, surfaces, etc.)
  static const primary50  = Color(0xFFE3F2FD);
  static const primary100 = Color(0xFFBBDEFB);
  static const primary200 = Color(0xFF90CAF9);
  static const primary400 = Color(0xFF42A5F5);
  static const primary700 = Color(0xFF0D47A1);
  static const primary900 = Color(0xFF0A2F6B);

  // ── Background Colors ────────────────────────────────────────────────────────
  static const bgPrimary   = Color(0xFFFFFFFF);
  static const bgSecondary = Color(0xFFF5F7FA);
  static const bgCard      = Color(0xFFFFFFFF);
  static const bgDark      = Color(0xFF0A1628);
  static const bgSurface   = Color(0xFFEEF2F7);

  // Aliases for legacy references
  static const background     = bgSecondary;
  static const surface        = bgPrimary;
  static const surfaceVariant = Color(0xFFF0F4FF);

  // ── Trust Verdict ─────────────────────────────────────────────────────────────
  static const trusted           = Color(0xFF00C853);
  static const trustedBg         = Color(0xFFE8F5E9);
  static const trustedSurface    = trustedBg;
  static const unverified        = Color(0xFFFF8F00);
  static const unverifiedBg      = Color(0xFFFFF8E1);
  static const unverifiedSurface = unverifiedBg;
  static const highRisk          = Color(0xFFD32F2F);
  static const highRiskBg        = Color(0xFFFFEBEE);
  static const highRiskSurface   = highRiskBg;

  // ── Text Colors ──────────────────────────────────────────────────────────────
  static const textPrimary   = Color(0xFF0A1628);
  static const textSecondary = Color(0xFF4A5568);
  static const textMuted     = Color(0xFF9AA5B4);
  static const textWhite     = Color(0xFFFFFFFF);
  static const textBlue      = Color(0xFF1565C0);
  static const textDisabled  = textMuted;
  static const textOnDark    = Color(0xFFFFFFFF);
  static const textOnDark70  = Color(0xB3FFFFFF); // 70% white

  // ── Border & Shadow ──────────────────────────────────────────────────────────
  static const borderLight  = Color(0xFFE2E8F0);
  static const borderMedium = Color(0xFFCBD5E0);
  static const divider      = borderLight;
  static const shadowColor  = Color(0x1F1565C0); // rgba(21,101,192,0.12)

  // ── Semantic ──────────────────────────────────────────────────────────────────
  static const success        = Color(0xFF388E3C);
  static const successSurface = Color(0xFFE8F5E9);
  static const warning        = Color(0xFFF57F17);
  static const warningSurface = Color(0xFFFFF8E1);
  static const error          = Color(0xFFD32F2F);
  static const errorSurface   = Color(0xFFFFEBEE);
  static const info           = Color(0xFF0277BD);
  static const infoSurface    = Color(0xFFE1F5FE);

  // ── Accent ───────────────────────────────────────────────────────────────────
  static const accent = Color(0xFFFF8F00); // amber 800

  // ── Neutral Palette ──────────────────────────────────────────────────────────
  static const grey50  = Color(0xFFF9FAFB);
  static const grey100 = Color(0xFFF3F4F6);
  static const grey200 = Color(0xFFE5E7EB);
  static const grey300 = Color(0xFFD1D5DB);
  static const grey400 = Color(0xFF9CA3AF);
  static const grey500 = Color(0xFF6B7280);
  static const grey700 = Color(0xFF374151);
  static const grey900 = Color(0xFF111827);

  // ── Shimmer ───────────────────────────────────────────────────────────────────
  static const shimmerBase      = Color(0xFFE2E8F0);
  static const shimmerHighlight = Color(0xFFF5F7FA);

  // ── Gradients ─────────────────────────────────────────────────────────────────
  static const primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const heroGradient = LinearGradient(
    colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1976D2)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const cardGradient = LinearGradient(
    colors: [bgPrimary, bgSecondary],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const trustGradient = LinearGradient(
    colors: [Color(0xFF00C853), Color(0xFF00E676)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const riskGradient = LinearGradient(
    colors: [Color(0xFFD32F2F), Color(0xFFF44336)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Score gradient helper ────────────────────────────────────────────────────
  static Color trustScoreColor(double score) {
    if (score >= 80) return trusted;
    if (score >= 50) return unverified;
    return highRisk;
  }

  static Color trustScoreSurface(double score) {
    if (score >= 80) return trustedSurface;
    if (score >= 50) return unverifiedSurface;
    return highRiskSurface;
  }
}
