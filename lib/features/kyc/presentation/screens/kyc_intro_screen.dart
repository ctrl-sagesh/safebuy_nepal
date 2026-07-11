import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/popup_helper.dart';
import '../../../../services/firestore_service.dart';
import '../../kyc_draft.dart';

/// KYC entry point — explains the three verification tiers.
class KycIntroScreen extends ConsumerStatefulWidget {
  const KycIntroScreen({super.key});

  @override
  ConsumerState<KycIntroScreen> createState() => _KycIntroScreenState();
}

class _KycIntroScreenState extends ConsumerState<KycIntroScreen> {
  bool _checking = false;

  Future<void> _start() async {
    HapticFeedback.mediumImpact();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      PopupHelper.showAuthGateBottomSheet(context);
      return;
    }
    setState(() => _checking = true);
    try {
      final fs = ref.read(firestoreServiceProvider);
      final me = await fs.getUserById(user.uid);
      if (!mounted) return;

      if (me?.linkedSellerId == null) {
        PopupHelper.showWarning(context,
            'Register your business first, then start verification.');
        Navigator.pushNamed(context, '/register-business');
        return;
      }
      final seller = await fs.getSellerById(me!.linkedSellerId!);
      if (!mounted) return;

      if (seller?.kycStatus == 'pending') {
        PopupHelper.showInfo(
            context,
            'Your KYC is currently under review. We will notify you '
            'within 24-48 hours.');
        return;
      }
      if (seller?.kycStatus == 'verified') {
        PopupHelper.showInfo(context,
            'You are already verified! View your SafeBuy card on your dashboard.');
        return;
      }
      KycDraft.instance.reset();
      Navigator.pushNamed(context, '/kyc/gmail');
    } catch (_) {
      if (mounted) {
        PopupHelper.showError(
            context, 'Could not check your status. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(title: const Text('Get SafeBuy Verified')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text('Protect your business and build buyer trust',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.5,
              )),
          const SizedBox(height: 18),

          _tierCard(
            index: 0,
            emoji: '🔵',
            title: 'Basic',
            color: AppColors.primary,
            requirements: const [
              'Phone + email verified',
              'Business details completed',
            ],
            benefits: const [
              'Blue Basic badge',
              'Listed in search results',
            ],
          ),
          _tierCard(
            index: 1,
            emoji: '🟢',
            title: 'Verified',
            color: AppColors.trusted,
            requirements: const [
              'Everything in Basic',
              'Selfie with citizenship card',
              'eSewa QR locked',
              'Gmail account linked',
            ],
            benefits: const [
              'Green Verified badge + card',
              'QR protection against swap fraud',
              'Higher trust score weighting',
            ],
          ),
          _tierCard(
            index: 2,
            emoji: '🏆',
            title: 'Premium',
            color: const Color(0xFFD4AF37),
            requirements: const [
              'Everything in Verified',
              'PAN card verified',
              'Business location photos + GPS',
            ],
            benefits: const [
              'Gold Premium card',
              'Leaderboard eligibility',
              'Featured seller placement',
            ],
          ),

          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '🔒 Your documents are reviewed by a human admin and are '
              'never shown publicly. Verification takes 24-48 hours '
              'and is valid for 6 months.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.primary900,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton(
                onPressed: _checking ? null : _start,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                child: _checking
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Start Verification'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tierCard({
    required int index,
    required String emoji,
    required String title,
    required Color color,
    required List<String> requirements,
    required List<String> benefits,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  )),
            ],
          ),
          const SizedBox(height: 10),
          Text('REQUIREMENTS',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.textMuted,
              )),
          const SizedBox(height: 4),
          ...requirements.map((r) => _line('•', r)),
          const SizedBox(height: 8),
          Text('BENEFITS',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.textMuted,
              )),
          const SizedBox(height: 4),
          ...benefits.map((b) => _line('✓', b, color: color)),
        ],
      ),
    )
        .animate(delay: (index * 120).ms)
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.06);
  }

  Widget _line(String bullet, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$bullet ',
              style: TextStyle(
                  color: color ?? AppColors.textSecondary,
                  fontWeight: FontWeight.w700)),
          Expanded(
            child: Text(text,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: AppColors.textPrimary,
                  height: 1.45,
                )),
          ),
        ],
      ),
    );
  }
}
