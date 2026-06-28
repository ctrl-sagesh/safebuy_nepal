import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'custom_button.dart';

enum EmptyVariant {
  noResults,
  noReviews,
  noReports,
  noActivity,
  offline,
}

/// SafeBuy Nepal — Empty State Widget
/// Shows illustration + title + subtitle + optional action button.
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.variant,
    this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.lang = 'en',
  });

  final EmptyVariant variant;
  final String? title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final (icon, color, defaultTitle, defaultSubtitle) = _config;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: AppSpacing.iconXxl, color: color),
            )
                .animate()
                .scale(
                  begin: const Offset(0.6, 0.6),
                  duration: 400.ms,
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: 300.ms),
            const SizedBox(height: AppSpacing.xl),
            Text(
              title ?? defaultTitle,
              style: AppTextStyles.titleMedium(lang: lang),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle ?? defaultSubtitle,
              style: AppTextStyles.bodyMedium(lang: lang).copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2, end: 0),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              CustomButton(
                label: actionLabel!,
                onPressed: onAction,
                width: 180,
                lang: lang,
              ).animate().fadeIn(delay: 200.ms),
            ],
          ],
        ),
      ),
    );
  }

  (IconData, Color, String, String) get _config => switch (variant) {
        EmptyVariant.noResults => (
            Icons.search_off,
            AppColors.primary,
            lang == 'ne' ? 'कुनै विक्रेता भेटिएन' : 'No Seller Found',
            lang == 'ne'
                ? 'यो विक्रेता हाम्रो डेटाबेसमा छैन।'
                : 'This seller is not in our database yet.',
          ),
        EmptyVariant.noReviews => (
            Icons.rate_review_outlined,
            AppColors.trusted,
            lang == 'ne' ? 'कुनै समीक्षा छैन' : 'No Reviews Yet',
            lang == 'ne'
                ? 'यो विक्रेतालाई पहिलो समीक्षा दिनुहोस्।'
                : 'Be the first to leave a review.',
          ),
        EmptyVariant.noReports => (
            Icons.check_circle_outline,
            AppColors.trusted,
            lang == 'ne' ? 'कुनै रिपोर्ट छैन' : 'No Reports Filed',
            lang == 'ne'
                ? 'यो विक्रेताविरुद्ध कुनै रिपोर्ट छैन।'
                : 'No fraud reports have been filed against this seller.',
          ),
        EmptyVariant.noActivity => (
            Icons.inbox_outlined,
            AppColors.grey500,
            lang == 'ne' ? 'कुनै गतिविधि छैन' : 'No Recent Activity',
            lang == 'ne'
                ? 'हालका गतिविधिहरू यहाँ देखिनेछन्।'
                : 'Recent activity will appear here.',
          ),
        EmptyVariant.offline => (
            Icons.wifi_off,
            AppColors.warning,
            lang == 'ne' ? 'इन्टरनेट छैन' : 'No Internet Connection',
            lang == 'ne'
                ? 'क्यास गरिएको डेटा देखाइँदैछ।'
                : 'Showing cached data. Connect to see live information.',
          ),
      };
}
