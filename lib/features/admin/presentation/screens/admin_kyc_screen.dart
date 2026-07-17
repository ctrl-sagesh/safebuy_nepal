import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/popup_helper.dart';
import '../../../../models/kyc_submission_model.dart';
import '../../../../services/kyc_service.dart';

/// Admin-only panel to review pending KYC submissions.
class AdminKycScreen extends StatefulWidget {
  const AdminKycScreen({super.key});

  @override
  State<AdminKycScreen> createState() => _AdminKycScreenState();
}

class _AdminKycScreenState extends State<AdminKycScreen> {
  String _filter = 'pending';
  final _kyc = KycService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(title: const Text('KYC Review Panel')),
      body: Column(
        children: [
          // Filter tabs
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: ['pending', 'approved', 'rejected'].map((f) {
                final selected = _filter == f;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => _filter = f),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.borderLight),
                        ),
                        child: Text(f.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            )),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: StreamBuilder<List<KycSubmissionModel>>(
              stream: _kyc.watchSubmissions(status: _filter),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text('Could not load submissions',
                        style: GoogleFonts.inter(
                            color: AppColors.textSecondary)),
                  );
                }
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary));
                }
                final subs = snap.data!;
                if (subs.isEmpty) {
                  return Center(
                    child: Text('No $_filter submissions',
                        style: GoogleFonts.inter(
                            color: AppColors.textSecondary)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: subs.length,
                  itemBuilder: (context, i) =>
                      _SubmissionCard(submission: subs[i], kyc: _kyc),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmissionCard extends StatefulWidget {
  const _SubmissionCard({required this.submission, required this.kyc});

  final KycSubmissionModel submission;
  final KycService kyc;

  @override
  State<_SubmissionCard> createState() => _SubmissionCardState();
}

class _SubmissionCardState extends State<_SubmissionCard> {
  bool _expanded = false;

  Future<void> _approve(String tier) async {
    await PopupHelper.showConfirmDialog(
      context,
      title: 'Approve as ${tier.toUpperCase()}?',
      message: 'This will issue a SafeBuy Verified badge and generate '
          'their verification card.',
      confirmLabel: 'Approve',
      onConfirm: () async {
        PopupHelper.showLoadingDialog(context, 'Processing approval...');
        try {
          await widget.kyc.approveSubmission(
            submission: widget.submission,
            tier: tier,
            adminId: FirebaseAuth.instance.currentUser?.uid ?? 'admin',
          );
          if (!mounted) return;
          PopupHelper.hideLoadingDialog(context);
          PopupHelper.showSuccess(
              context,
              'Seller approved as $tier. Card generated and '
              'notification sent.');
        } catch (_) {
          if (!mounted) return;
          PopupHelper.hideLoadingDialog(context);
          PopupHelper.showError(
              context, 'Approval failed. Please try again.');
        }
      },
    );
  }

  Future<void> _reject() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Reject Submission',
            style: GoogleFonts.poppins(
                fontSize: 17, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Rejection reason (required)…',
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                foregroundColor: AppColors.grey500,
                side: const BorderSide(color: AppColors.borderMedium)),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) {
                PopupHelper.showWarning(
                    ctx, 'Please provide a rejection reason');
                return;
              }
              Navigator.pop(ctx);
              PopupHelper.showLoadingDialog(context, 'Rejecting...');
              try {
                await widget.kyc.rejectSubmission(
                  submission: widget.submission,
                  reason: controller.text.trim(),
                  adminId:
                      FirebaseAuth.instance.currentUser?.uid ?? 'admin',
                );
                if (!mounted) return;
                PopupHelper.hideLoadingDialog(context);
                PopupHelper.showSuccess(
                    context, 'Submission rejected. Seller notified.');
              } catch (_) {
                if (!mounted) return;
                PopupHelper.hideLoadingDialog(context);
                PopupHelper.showError(
                    context, 'Rejection failed. Please try again.');
              }
            },
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 44),
                backgroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _viewImage(String url, String title) {
    if (url.isEmpty) {
      PopupHelper.showInfo(context, 'No $title uploaded');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(title),
          ),
          body: PhotoView(imageProvider: CachedNetworkImageProvider(url)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.submission;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Seller: ${s.sellerId}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.robotoMono(
                        fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              Text(DateFormat('dd MMM, HH:mm').format(s.submittedAt),
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _docChip('🤳 Selfie', s.selfieUrl, 'Selfie'),
              _docChip('🪪 PAN', s.panCardUrl, 'PAN Card'),
              _docChip('🔳 QR', s.qrCodeUrlSubmitted, 'QR Code'),
              ...s.locationPhotoUrls.asMap().entries.map((e) =>
                  _docChip('📍 Loc ${e.key + 1}', e.value,
                      'Location photo ${e.key + 1}')),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(_expanded ? 'Hide details ▲' : 'Show details ▼',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600)),
          ),
          if (_expanded) ...[
            const SizedBox(height: 8),
            _kv('PAN number', s.panNumberSubmitted),
            _kv('Gmail', s.gmailAccountSubmitted),
            _kv(
                'GPS',
                s.locationLat != 0
                    ? '${s.locationLat.toStringAsFixed(5)}, ${s.locationLng.toStringAsFixed(5)}'
                    : 'Not captured'),
            if (s.rejectionReason.isNotEmpty)
              _kv('Rejection', s.rejectionReason),
          ],
          if (s.isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () => _approve('verified'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.trusted,
                          minimumSize: const Size(0, 42)),
                      child: Text('Verified',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () => _approve('premium'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          minimumSize: const Size(0, 42)),
                      child: Text('Premium',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: OutlinedButton(
                      onPressed: _reject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side:
                            const BorderSide(color: AppColors.error),
                        minimumSize: const Size(0, 42),
                      ),
                      child: Text('Reject',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _docChip(String label, String url, String title) {
    final has = url.isNotEmpty;
    return InkWell(
      onTap: () => _viewImage(url, title),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: has ? AppColors.primary50 : AppColors.grey100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text('$label ${has ? '👁' : '-'}',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: has ? AppColors.primary : AppColors.textMuted,
            )),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(k,
                style: GoogleFonts.inter(
                    fontSize: 11.5, color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(v.isEmpty ? '-' : v,
                style: GoogleFonts.inter(
                    fontSize: 11.5, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
