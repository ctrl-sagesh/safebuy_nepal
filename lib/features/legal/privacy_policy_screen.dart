import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

/// Full privacy policy.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
        children: const [
          _PolicySection(
            n: '1',
            title: 'Who We Are',
            body: 'SafeBuy Nepal is a community-driven seller trust '
                'verification platform developed by Sagesh Adhikari as a '
                'BSc thesis project at Softwarica College affiliated with '
                'Coventry University UK.',
          ),
          _PolicySection(
            n: '2',
            title: 'Information We Collect from Buyers',
            body: '• Phone number\n'
                '• Name\n'
                '• Reports you submit\n'
                '• Search history (stored on your device only)',
          ),
          _PolicySection(
            n: '3',
            title: 'Information We Collect from Sellers',
            body: '• Phone number and business information\n'
                '• Social media handles\n'
                '• Gmail account (KYC)\n'
                '• Selfie photo (KYC only)\n'
                '• Citizenship card (KYC only)\n'
                '• PAN card and number (KYC only)\n'
                '• Location photos and GPS (KYC only)\n'
                '• eSewa QR code',
          ),
          _PolicySection(
            n: '4',
            title: 'How We Use Information',
            body: 'Authentication, KYC processing, trust score '
                'calculation, and fraud prevention. Your data is never '
                'sold and never used for advertising.',
          ),
          _PolicySection(
            n: '5',
            title: 'What Buyers See About Sellers',
            body: 'Visible: business name, category, verification tier, '
                'registration date, district only (never full address), '
                'trust score, reviews, reports, locked QR code, and card '
                'ID.\n\n'
                'NEVER shown: PAN number, citizenship number, full '
                'address, GPS coordinates, Gmail, or selfie.',
          ),
          _PolicySection(
            n: '6',
            title: 'Data Retention',
            body: '• Account data: while your account is active\n'
                '• KYC documents: 3 years after account closure\n'
                '• Fraud reports: permanent (anonymised on request)\n'
                '• Reviews: permanent',
          ),
          _PolicySection(
            n: '7',
            title: 'Your Rights',
            body: 'You may request a copy of your data, deletion of your '
                'account, correction of inaccurate information, and '
                'withdrawal of consent at any time.',
          ),
          _PolicySection(
            n: '8',
            title: 'Data Security',
            body: 'All traffic is encrypted with HTTPS/TLS. Documents are '
                'stored in Firebase Storage with role-based security '
                'rules. Only authorised admins can access KYC documents.',
          ),
          _PolicySection(
            n: '9',
            title: 'Contact',
            body: 'sageshadhikari@gmail.com',
          ),
          _PolicySection(
            n: '10',
            title: 'Governing Law',
            body: 'This policy is governed by the Privacy Act 2018 '
                '(Ekantata Sambandhi Ain 2075) and the Electronic '
                'Transactions Act 2063 of Nepal.',
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({
    required this.n,
    required this.title,
    required this.body,
  });

  final String n;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$n. $title',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 6),
          Text(body,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.65,
              )),
        ],
      ),
    );
  }
}
