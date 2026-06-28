import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'custom_button.dart';

/// SafeBuy Nepal — Error State Widget
/// Shown when an async operation fails.
class ErrorStateWidget extends StatelessWidget {
  const ErrorStateWidget({
    super.key,
    this.message,
    required this.onRetry,
    this.lang = 'en',
  });

  final String? message;
  final VoidCallback onRetry;
  final String lang;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.errorSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: AppSpacing.iconXxl,
                color: AppColors.error,
              ),
            )
                .animate()
                .shake(duration: 500.ms, hz: 3)
                .fadeIn(duration: 300.ms),
            const SizedBox(height: AppSpacing.xl),
            Text(
              lang == 'ne' ? 'केही गलत भयो' : 'Something went wrong',
              style: AppTextStyles.titleMedium(lang: lang),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message ??
                  (lang == 'ne'
                      ? 'कृपया पुनः प्रयास गर्नुहोस्।'
                      : 'Please check your connection and try again.'),
              style: AppTextStyles.bodyMedium(lang: lang).copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            CustomButton(
              label: lang == 'ne' ? 'पुनः प्रयास' : 'Try Again',
              onPressed: onRetry,
              width: 160,
              lang: lang,
            ),
          ],
        ),
      ),
    );
  }
}
