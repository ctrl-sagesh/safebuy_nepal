import 'dart:io';
import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/popup_helper.dart';
import '../../../../core/widgets/verification_card.dart';
import '../../../../models/seller_model.dart';
import '../../../../services/firestore_service.dart';

/// Full-screen SafeBuy verification card with share / download / renewal.
class VerificationCardScreen extends ConsumerStatefulWidget {
  const VerificationCardScreen({super.key, required this.sellerId});

  final String sellerId;

  @override
  ConsumerState<VerificationCardScreen> createState() =>
      _VerificationCardScreenState();
}

class _VerificationCardScreenState
    extends ConsumerState<VerificationCardScreen> {
  final _cardKey = GlobalKey();
  SellerModel? _seller;
  bool _failed = false;

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
      if (!mounted) return;
      if (s == null) {
        setState(() => _failed = true);
        PopupHelper.showError(
            context, 'Could not load this verification card.');
      } else {
        setState(() => _seller = s);
        if (s.isReverificationOverdue) {
          PopupHelper.showWarning(
              context,
              'This verification has expired. The seller may need '
              'to re-verify.');
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
      PopupHelper.showError(
          context, 'Could not load this verification card.');
    }
  }

  Future<void> _share(SellerModel s) async {
    HapticFeedback.mediumImpact();
    final text = 'SafeBuy Nepal Verified Seller\n'
        '${s.displayName}\n'
        'Card ID: ${s.safebuyCardId}\n'
        'Verify at: safebuy-nepal.vercel.app';
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      PopupHelper.showSuccess(
          context, 'Card details copied — paste anywhere to share');
    }
  }

  Future<void> _download() async {
    HapticFeedback.mediumImpact();
    try {
      final boundary = _cardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('no boundary');
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw Exception('no bytes');
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
          '${dir.path}/safebuy_card_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      if (mounted) {
        PopupHelper.showSuccess(context, 'Card saved to your device');
      }
    } catch (_) {
      if (mounted) {
        PopupHelper.showError(context,
            'Could not save card. Please check storage permissions.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final s = _seller;
    final isOwner = s != null && uid != null && s.linkedUserId == uid;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        foregroundColor: Colors.white,
        title: const Text('SafeBuy Verification Card'),
        titleTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: _failed
          ? Center(
              child: OutlinedButton(
                onPressed: () {
                  setState(() => _failed = false);
                  _load();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  minimumSize: const Size(140, 46),
                ),
                child: const Text('Retry'),
              ),
            )
          : s == null
              ? const Center(
                  child:
                      CircularProgressIndicator(color: Colors.white))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Hero(
                        tag: 'safebuy_card_${s.sellerId}',
                        child: RepaintBoundary(
                          key: _cardKey,
                          child:
                              SafebuyVerificationCard(seller: s, width: 340),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Status
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: s.isReverificationOverdue
                              ? AppColors.warning.withValues(alpha: 0.18)
                              : AppColors.trusted.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          s.isReverificationOverdue
                              ? '⚠ EXPIRED'
                              : s.isKycVerified
                                  ? '● ACTIVE'
                                  : '◌ PENDING VERIFICATION',
                          style: GoogleFonts.poppins(
                            color: s.isReverificationOverdue
                                ? AppColors.warning
                                : AppColors.trusted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),

                      if (isOwner) ...[
                        // Renewal countdown
                        if (s.verificationExpiry != null) ...[
                          CircularPercentIndicator(
                            radius: 52,
                            lineWidth: 8,
                            percent: _renewalPercent(s),
                            progressColor:
                                TierStyle.color(s.verificationTier),
                            backgroundColor: Colors.white12,
                            circularStrokeCap: CircularStrokeCap.round,
                            center: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${_daysLeft(s)}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text('days left',
                                    style: GoogleFonts.inter(
                                      color: Colors.white54,
                                      fontSize: 10,
                                    )),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Re-verification due '
                            '${DateFormat('dd MMM yyyy').format(s.verificationExpiry!)}',
                            style: GoogleFonts.inter(
                                color: Colors.white54, fontSize: 12),
                          ),
                          const SizedBox(height: 22),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: _actionBtn(
                                icon: Icons.share_rounded,
                                label: 'Share Your Card',
                                onTap: () => _share(s),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _actionBtn(
                                icon: Icons.download_rounded,
                                label: 'Download Card',
                                onTap: _download,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pushNamed(
                                context, '/kyc/change-qr',
                                arguments: {'sellerId': s.sellerId}),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.warning,
                              side: const BorderSide(
                                  color: AppColors.warning),
                              minimumSize: const Size(0, 50),
                            ),
                            icon: const Icon(Icons.qr_code_2_rounded,
                                size: 18),
                            label: const Text('Request QR Change'),
                          ),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: _actionBtn(
                                icon: Icons.person_search_rounded,
                                label: 'View Full Profile',
                                onTap: () => Navigator.pushNamed(
                                    context, '/seller', arguments: {
                                  'sellerId': s.sellerId
                                }),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _actionBtn(
                                icon: Icons.flag_rounded,
                                label: 'Report Seller',
                                color: AppColors.highRisk,
                                onTap: () {
                                  if (uid == null) {
                                    PopupHelper
                                        .showAuthGateBottomSheet(
                                            context);
                                  } else {
                                    Navigator.pushNamed(
                                        context, '/report',
                                        arguments: {
                                          'sellerId': s.sellerId,
                                          'phone': s.phone,
                                        });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  double _renewalPercent(SellerModel s) {
    if (s.verificationDate == null || s.verificationExpiry == null) {
      return 0;
    }
    final total = s.verificationExpiry!
        .difference(s.verificationDate!)
        .inDays
        .clamp(1, 100000);
    final left =
        s.verificationExpiry!.difference(DateTime.now()).inDays;
    return (left / total).clamp(0.0, 1.0);
  }

  int _daysLeft(SellerModel s) {
    if (s.verificationExpiry == null) return 0;
    return s.verificationExpiry!
        .difference(DateTime.now())
        .inDays
        .clamp(0, 999);
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return SizedBox(
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.6)),
          minimumSize: const Size(0, 50),
        ),
        icon: Icon(icon, size: 18),
        label: Text(label,
            style: GoogleFonts.inter(
                fontSize: 12.5, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
