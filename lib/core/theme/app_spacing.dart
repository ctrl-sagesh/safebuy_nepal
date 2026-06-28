/// SafeBuy Nepal — Spacing System
/// Use ONLY these constants for padding, margin, gap, and border-radius values.
abstract final class AppSpacing {
  // ── Base scale ────────────────────────────────────────────────────────────────
  static const double xs   =  4.0;
  static const double sm   =  8.0;
  static const double md   = 12.0;
  static const double lg   = 16.0;
  static const double xl   = 24.0;
  static const double xxl  = 32.0;
  static const double xxxl = 48.0;
  static const double huge = 64.0;

  // ── Screen horizontal padding ─────────────────────────────────────────────────
  static const double screenH = lg;   // 16px
  static const double screenV = lg;   // 16px

  // ── Card internal padding ─────────────────────────────────────────────────────
  static const double cardPadding = lg; // 16px

  // ── Border radii ─────────────────────────────────────────────────────────────
  static const double radiusXs  =  4.0;
  static const double radiusSm  =  8.0;
  static const double radiusMd  = 12.0;
  static const double radiusLg  = 16.0;
  static const double radiusXl  = 20.0;
  static const double radiusXxl = 24.0;
  static const double radiusFull = 100.0; // pill shape

  // ── Icon sizes ────────────────────────────────────────────────────────────────
  static const double iconXs = 14.0;
  static const double iconSm = 18.0;
  static const double iconMd = 22.0;
  static const double iconLg = 28.0;
  static const double iconXl = 36.0;
  static const double iconXxl = 48.0;

  // ── Minimum tap target (accessibility) ───────────────────────────────────────
  static const double minTapTarget = 48.0;

  // ── List item separator ───────────────────────────────────────────────────────
  static const double listItemGap = sm; // 8px
  static const double sectionGap  = xl; // 24px
}
