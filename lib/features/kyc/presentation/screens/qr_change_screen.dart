import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/popup_helper.dart';
import '../../../../models/seller_model.dart';
import '../../../../services/firestore_service.dart';
import '../../../../services/kyc_service.dart';
import '../../kyc_draft.dart';

/// Request to change a locked payment QR — admin reviewed.
class QrChangeScreen extends ConsumerStatefulWidget {
  const QrChangeScreen({super.key, required this.sellerId});

  final String sellerId;

  @override
  ConsumerState<QrChangeScreen> createState() => _QrChangeScreenState();
}

class _QrChangeScreenState extends ConsumerState<QrChangeScreen> {
  SellerModel? _seller;
  String? _reason;
  File? _newQr;
  final _explanation = TextEditingController();
  bool _submitting = false;

  static const _reasons = [
    'I changed my eSewa account',
    'My eSewa account was compromised',
    'Switching to a business eSewa account',
    'Other (explain below)',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await ref
          .read(firestoreServiceProvider)
          .getSellerById(widget.sellerId);
      if (mounted) setState(() => _seller = s);
    } catch (_) {
      if (mounted) {
        PopupHelper.showError(
            context, 'Could not load your current QR details.');
      }
    }
  }

  @override
  void dispose() {
    _explanation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reason == null) {
      PopupHelper.showWarning(
          context, 'Please select a reason for the change');
      return;
    }
    if (_newQr == null) {
      PopupHelper.showWarning(
          context, 'Please upload your new QR code screenshot');
      return;
    }
    if (_explanation.text.trim().length < 50) {
      PopupHelper.showWarning(context,
          'Please explain your reason (minimum 50 characters)');
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      PopupHelper.showError(
          context, 'Session expired. Please sign in again.');
      return;
    }

    setState(() => _submitting = true);
    PopupHelper.showLoadingDialog(context, 'Submitting request...');
    try {
      final kyc = KycService();
      final url =
          await kyc.uploadQrCode(userId: user.uid, file: _newQr!);
      await kyc.submitQrChangeRequest(
        sellerId: widget.sellerId,
        userId: user.uid,
        reason: _reason!,
        explanation: _explanation.text.trim(),
        newQrUrl: url,
      );
      if (!mounted) return;
      PopupHelper.hideLoadingDialog(context);
      PopupHelper.showSuccess(
          context, 'Request submitted. Processing takes 24-48 hours.');
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      PopupHelper.hideLoadingDialog(context);
      PopupHelper.showError(
          context, 'Could not submit request. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _seller;
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(title: const Text('Request QR Change')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        children: [
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
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.warning),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Changing your locked QR is a serious action. Buyers '
                    'trust the QR on your card. Every change request is '
                    'manually reviewed and logged to prevent fraud.',
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

          // Current QR with locked overlay
          if (s != null && s.qrCodeUrl.isNotEmpty) ...[
            Text('Current QR',
                style: GoogleFonts.poppins(
                    fontSize: 13.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: s.qrCodeUrl,
                      width: 130,
                      height: 130,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => Container(
                        width: 130,
                        height: 130,
                        color: Colors.white,
                        child: const Icon(Icons.qr_code_2_rounded,
                            size: 80),
                      ),
                    ),
                  ),
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text('LOCKED 🔒',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        )),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          Text('Reason for change *',
              style: GoogleFonts.poppins(
                  fontSize: 13.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ..._reasons.map((r) => RadioListTile<String>(
                value: r,
                // ignore: deprecated_member_use
                groupValue: _reason,
                // ignore: deprecated_member_use
                onChanged: (v) => setState(() => _reason = v),
                title: Text(r, style: GoogleFonts.inter(fontSize: 13)),
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                dense: true,
              )),
          const SizedBox(height: 10),

          Text('New QR code *',
              style: GoogleFonts.poppins(
                  fontSize: 13.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          KycUploadZone(
            label: 'Upload your new eSewa QR screenshot',
            icon: Icons.qr_code_2_rounded,
            file: _newQr,
            onPick: () async {
              final f = await pickKycImage(context,
                  source: ImageSource.gallery);
              if (f != null) setState(() => _newQr = f);
            },
            onRemove: () => setState(() => _newQr = null),
            height: 140,
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _explanation,
            maxLines: 4,
            maxLength: 400,
            decoration: InputDecoration(
              labelText: 'Explain your reason (min 50 characters) *',
              alignLabelWithHint: true,
              counterText:
                  '${_explanation.text.trim().length}/50 minimum',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: const Text('Submit Request'),
            ),
          ),
        ],
      ),
    );
  }
}
