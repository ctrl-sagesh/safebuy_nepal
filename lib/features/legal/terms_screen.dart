import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

/// Full terms of service.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Terms of Service')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
        children: const [
          _TermsSection(
            n: '1',
            title: 'Acceptance of Terms',
            body: 'By creating an account or browsing SafeBuy Nepal you '
                'agree to these terms. If you do not agree, please do '
                'not use the platform.',
          ),
          _TermsSection(
            n: '2',
            title: 'Platform Purpose and Limitations',
            body: 'SafeBuy Nepal provides community information only. We '
                'are not a transaction mediator, escrow service, or '
                'payment provider. Trust verdicts are one factor in your '
                'decision, not the only factor. A high score is not a '
                'guarantee, and a missing record is not proof of safety.',
          ),
          _TermsSection(
            n: '3',
            title: 'For Buyers',
            body: 'Reports must be truthful and based on your genuine '
                'personal experience. Submitting false reports leads to '
                'report removal, account suspension, and possible '
                'liability under Nepali law.',
          ),
          _TermsSection(
            n: '4',
            title: 'For Sellers',
            body: 'All KYC information must be accurate and belong to '
                'you. By verifying, you agree that your payment QR is '
                'locked to your profile and that changes require an '
                'admin-reviewed request. Verification requires renewal '
                'every 6 months. Confirmed fraud results in immediate '
                'badge revocation and a permanent record.',
          ),
          _TermsSection(
            n: '5',
            title: 'Prohibited Conduct',
            body: '• Submitting false reports\n'
                '• Posting fake reviews\n'
                '• Manipulating trust scores\n'
                '• Operating multiple accounts\n'
                '• Harassing sellers or reporters',
          ),
          _TermsSection(
            n: '6',
            title: 'Verification Disclaimer',
            body: 'Verification confirms a seller\'s identity at the time '
                'of verification only. It is not a guarantee of future '
                'behaviour or product quality.',
          ),
          _TermsSection(
            n: '7',
            title: 'Law Enforcement Cooperation',
            body: 'We share data with authorities upon a valid legal '
                'order. For fraud exceeding NPR 50,000, we proactively '
                'prepare an evidence package for the Nepal Police '
                'Cybercrime Bureau.',
          ),
          _TermsSection(
            n: '8',
            title: 'Limitation of Liability',
            body: 'SafeBuy Nepal is provided "as is". We are not liable '
                'for losses arising from transactions between buyers and '
                'sellers, or from decisions made using platform '
                'information.',
          ),
          _TermsSection(
            n: '9',
            title: 'Governing Law',
            body: 'These terms are governed by the laws of Nepal.',
          ),
          _TermsSection(
            n: '10',
            title: 'Contact',
            body: 'sageshadhikari@gmail.com',
          ),
        ],
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  const _TermsSection({
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
