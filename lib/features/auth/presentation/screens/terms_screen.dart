import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('SafeBuy Nepal Terms of Service',
              style: AppTextStyles.titleLarge()),
          const SizedBox(height: AppSpacing.xs),
          Text('Effective: 2026-05-18',
              style: AppTextStyles.bodySmall()
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.lg),
          _section('1. Truthful reporting',
              'You may only submit fraud reports based on your genuine personal experience. False reporting is a violation of these terms and may constitute defamation under Nepal law.'),
          _section('2. Consequences of false reporting',
              'If a report you submit is conclusively flagged as false by a seller and verified by SafeBuy moderators, your account may be suspended. Repeated false reports may be referred to law enforcement.'),
          _section('3. Seller obligations',
              'Sellers who register a business commit to authentic representation of their accounts. SafeBuy reserves the right to revoke verified badges and trust score for fraudulent registrations.'),
          _section('4. Trust score disclaimer',
              'SafeBuy trust scores are advisory community metrics, not financial guarantees. Buyers should always exercise independent judgment before payment.'),
          _section('5. Liability',
              'SafeBuy Nepal is a community information platform. We do not mediate refunds, recover funds, or guarantee outcomes. We are not liable for losses arising from transactions facilitated outside our platform.'),
          _section('6. Account termination',
              'You may delete your account at any time. SafeBuy may suspend accounts for violations of these terms after notice.'),
        ],
      ),
    );
  }

  Widget _section(String title, String body) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.titleSmall()),
            const SizedBox(height: AppSpacing.xs),
            Text(body, style: AppTextStyles.bodyMedium()),
          ],
        ),
      );
}
