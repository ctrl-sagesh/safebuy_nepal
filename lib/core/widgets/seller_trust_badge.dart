import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../constants/app_strings.dart';
import '../constants/app_constants.dart';

enum BadgeSize { small, large }

/// SafeBuy Nepal — Trust Verdict Badge
/// Displays the trust verdict with colour-coded shield icon.
/// Red badges pulse to signal urgency.
class SellerTrustBadge extends StatelessWidget {
  const SellerTrustBadge({
    super.key,
    required this.score,
    this.size = BadgeSize.small,
    this.lang = 'en',
    this.animate = true,
  });

  final double score;
  final BadgeSize size;
  final String lang;
  final bool animate;

  String get _verdict {
    if (score >= AppConstants.trustTrusted) return 'trusted';
    if (score >= AppConstants.trustUnverified) return 'unverified';
    return 'high_risk';
  }

  Color get _bgColor => AppColors.trustScoreSurface(score);
  Color get _fgColor => AppColors.trustScoreColor(score);

  IconData get _icon {
    if (score >= AppConstants.trustTrusted) return Icons.verified_user;
    if (score >= AppConstants.trustUnverified) return Icons.shield_outlined;
    return Icons.gpp_bad;
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = size == BadgeSize.small;
    final badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? AppSpacing.sm : AppSpacing.md,
        vertical: isSmall ? AppSpacing.xs : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: _fgColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, color: _fgColor, size: isSmall ? 13 : 18),
          SizedBox(width: isSmall ? 4 : 6),
          Text(
            AppStrings.get(_verdict, lang),
            style: (isSmall
                    ? AppTextStyles.labelSmall(lang: lang)
                    : AppTextStyles.labelMedium(lang: lang))
                .copyWith(
              color: _fgColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    if (!animate) return badge;

    // High risk: pulse animation for urgency
    if (_verdict == 'high_risk') {
      return badge
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 1.0, end: 1.04, duration: 900.ms, curve: Curves.easeInOut);
    }

    // First appearance: scale in
    return badge.animate().scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          duration: 300.ms,
          curve: Curves.elasticOut,
        );
  }
}

/// Circular trust score widget (used in seller profile header).
class TrustScoreCircle extends StatelessWidget {
  const TrustScoreCircle({
    super.key,
    required this.score,
    this.size = 100,
    this.lang = 'en',
    this.animate = true,
  });

  final double score;
  final double size;
  final String lang;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.trustScoreColor(score);
    final circle = SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: size * 0.08,
              backgroundColor: color.withValues(alpha: 0.12),
              color: color,
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                score.toStringAsFixed(0),
                style: AppTextStyles.trustScore(lang: lang).copyWith(
                  color: color,
                  fontSize: size * 0.26,
                ),
              ),
              Text(
                '/100',
                style: AppTextStyles.labelSmall(lang: lang).copyWith(
                  color: AppColors.textSecondary,
                  fontSize: size * 0.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (!animate) return circle;
    return circle
        .animate()
        .scale(begin: const Offset(0.7, 0.7), duration: 500.ms, curve: Curves.elasticOut)
        .fadeIn(duration: 300.ms);
  }
}
