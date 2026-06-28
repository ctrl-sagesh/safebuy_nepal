import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Beautiful bottom sheet that prompts guest users to sign in.
/// Shows when guest taps on a feature that requires authentication.
class AuthGateSheet {
  static Future<void> show(BuildContext context, {String? feature}) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AuthGateContent(feature: feature),
    );
  }
}

class _AuthGateContent extends StatelessWidget {
  const _AuthGateContent({this.feature});
  final String? feature;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24, 20, 24,
        MediaQuery.paddingOf(context).bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderMedium,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Lock icon
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              size: 36,
              color: AppColors.primary,
            ),
          )
              .animate()
              .scaleXY(begin: 0.5, end: 1.0, duration: 400.ms, curve: Curves.elasticOut),

          const SizedBox(height: 20),

          Text(
            'Sign in to Continue',
            style: AppTextStyles.headlineMedium(),
          ),
          const SizedBox(height: 8),

          Text(
            feature != null
                ? 'You need an account to $feature.'
                : 'Create an account to access this feature.',
            style: AppTextStyles.bodyMedium(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Benefits list
          ..._benefits.map((b) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 16, color: AppColors.trusted),
                    const SizedBox(width: 8),
                    Text(b,
                        style: AppTextStyles.bodySmall()
                            .copyWith(color: AppColors.textPrimary)),
                  ],
                ),
              )),

          const SizedBox(height: 24),

          // Create account button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/auth');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text('Create Account',
                  style: AppTextStyles.button().copyWith(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 10),

          // Sign in link
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/auth');
            },
            child: Text('Already have an account? Sign In',
                style: AppTextStyles.labelMedium()
                    .copyWith(color: AppColors.primary)),
          ),

          // Maybe later
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Maybe Later',
                style: AppTextStyles.labelMedium()
                    .copyWith(color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }

  static const _benefits = [
    'Report fraudulent sellers',
    'Submit reviews for trusted sellers',
    'Track your community impact',
    'Get personalized scam alerts',
  ];
}
