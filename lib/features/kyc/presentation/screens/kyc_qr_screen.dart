import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/popup_helper.dart';
import '../../kyc_draft.dart';

/// KYC Step 2 — upload the eSewa QR code (will be locked).
class KycQrScreen extends StatefulWidget {
  const KycQrScreen({super.key});

  @override
  State<KycQrScreen> createState() => _KycQrScreenState();
}

class _KycQrScreenState extends State<KycQrScreen> {
  bool _whyExpanded = false;

  Future<void> _pick() async {
    final file =
        await pickKycImage(context, source: ImageSource.gallery);
    if (file == null) return;
    final sizeBytes = await file.length();
    if (!mounted) return;
    if (sizeBytes > 2 * 1024 * 1024) {
      PopupHelper.showError(
          context,
          'Upload failed. Maximum file size is 2MB. Please take a '
          'smaller screenshot and try again.');
      return;
    }
    setState(() => KycDraft.instance.qrFile = file);
  }

  @override
  Widget build(BuildContext context) {
    final draft = KycDraft.instance;
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(title: const Text('KYC: Payment QR')),
      body: Column(
        children: [
          const KycStepHeader(step: 2),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              children: [
                // Amber warning
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warningSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lock_rounded,
                          color: AppColors.warning, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Once verified, this QR code is LOCKED to your '
                          'profile. Buyers will only trust this exact QR. '
                          'Changing it later requires an admin-reviewed request.',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: const Color(0xFF5D4A00),
                            height: 1.55,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // How-to illustration
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Where to find your eSewa QR',
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          )),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _step('📲', 'Open\neSewa'),
                          _arrow(),
                          _step('👤', 'Go to\nProfile'),
                          _arrow(),
                          _step('🔳', 'Screenshot\nQR'),
                          _arrow(),
                          _step('⬆️', 'Upload\nhere'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                KycUploadZone(
                  label: 'Tap to upload your eSewa QR code screenshot',
                  icon: Icons.qr_code_2_rounded,
                  file: draft.qrFile,
                  onPick: _pick,
                  onRemove: () =>
                      setState(() => draft.qrFile = null),
                  height: 180,
                ),
                const SizedBox(height: 14),

                // Why we lock the QR — expandable
                InkWell(
                  onTap: () =>
                      setState(() => _whyExpanded = !_whyExpanded),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary50,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('Why we lock the QR',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary900,
                                  )),
                            ),
                            Icon(
                              _whyExpanded
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                        if (_whyExpanded) ...[
                          const SizedBox(height: 8),
                          Text(
                            'In 2023, Nepal Police documented QR-swap fraud '
                            'where scammers sent buyers a different QR code in '
                            'chat, redirecting payments to their own account. '
                            'By locking your official QR to your SafeBuy card, '
                            'buyers can always confirm they are paying YOU. '
                            'Any other QR claiming to be yours is instantly '
                            'exposed as fraud.',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: AppColors.textPrimary,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          KycBottomBar(
            enabled: draft.qrFile != null,
            label: 'Next',
            onNext: () => Navigator.pushNamed(context, '/kyc/selfie'),
            onDisabledTap: () => PopupHelper.showWarning(
                context, 'Please upload your eSewa QR code to continue'),
          ),
        ],
      ),
    );
  }

  Widget _step(String emoji, String label) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(height: 5),
          Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 9.5,
                color: AppColors.textSecondary,
                height: 1.25,
              )),
        ],
      ),
    );
  }

  Widget _arrow() => const Padding(
        padding: EdgeInsets.only(bottom: 18),
        child: Icon(Icons.arrow_forward_rounded,
            size: 15, color: AppColors.borderMedium),
      );
}
