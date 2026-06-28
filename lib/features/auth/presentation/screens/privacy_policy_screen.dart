import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('SafeBuy Nepal Privacy Policy',
              style: AppTextStyles.titleLarge()),
          const SizedBox(height: AppSpacing.xs),
          Text('Effective: 2026-05-18',
              style: AppTextStyles.bodySmall()
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.lg),
          _section(
            '1. What we collect',
            'We collect your phone number (for OTP authentication), seller identifiers you report (phone, eSewa ID, social handles), and evidence files you upload (payment screenshots, chat screenshots). We do not collect government IDs, location data, or contacts.',
          ),
          _section(
            '2. How trust scores are calculated',
            'Trust scores are an algorithmic aggregate of: verified fraud reports (40 %), verification status (25 %), authentic reviews (20 %), dispute response (10 %), and account age (5 %). The score is informational only and is not a legal judgment.',
          ),
          _section(
            '3. Your rights',
            'You may request data deletion at any time from Settings → Delete Account. We will anonymise your reports (preserving fraud record integrity) and delete your authentication credentials.',
          ),
          _section(
            '4. Evidence security',
            'Evidence files are stored in Firebase Storage, served only via signed URLs that expire within one hour. Only the report submitter, the reported seller, and admin moderators can view evidence.',
          ),
          _section(
            '5. Compliance',
            'This service complies with Nepal Electronic Transactions Act 2063 (2008) and follows GDPR-aligned data minimisation principles voluntarily.',
          ),
          _section(
            '6. Contact',
            'Privacy questions: privacy@safebuy.np\nFraud reports about SafeBuy itself: abuse@safebuy.np',
          ),
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
