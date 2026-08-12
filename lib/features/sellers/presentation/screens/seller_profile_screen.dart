import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/popup_helper.dart';
import '../../../../core/widgets/dhaka_pattern.dart';
import '../../../../core/widgets/loyalty_badge.dart';
import '../../../../core/widgets/pulse_glow.dart';
import '../../../../core/widgets/verification_card.dart';
import '../../../../models/report_model.dart';
import '../../../../models/review_model.dart';
import '../../../../models/seller_model.dart';
import '../../../../services/firestore_service.dart';

/// Full seller profile: trust arc, verification status, card preview,
/// tabs for reviews / reports / about.
class SellerProfileScreen extends ConsumerStatefulWidget {
  const SellerProfileScreen({super.key, required this.sellerId});

  final String sellerId;

  @override
  ConsumerState<SellerProfileScreen> createState() =>
      _SellerProfileScreenState();
}

class _SellerProfileScreenState
    extends ConsumerState<SellerProfileScreen>
    with TickerProviderStateMixin {
  SellerModel? _seller;
  bool _failed = false;
  List<ReviewModel>? _reviews;
  List<ReportModel>? _reports;
  int _tab = 0;
  int _reviewsShown = 5;

  late final AnimationController _arc = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  /// Small 1→1.05→1 pulse once the score arc finishes counting up.
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  bool get _isGuest => FirebaseAuth.instance.currentUser == null;

  /// The signed-in user's own report against this seller, if any —
  /// unlocks the "Escalate to Nepal Police" flow on high-risk profiles.
  ReportModel? get _myReport {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _reports == null) return null;
    for (final r in _reports!) {
      if (r.reporterId == uid) return r;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _arc.dispose();
    _settle.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final fs = ref.read(firestoreServiceProvider);
    try {
      final seller = await fs.getSellerById(widget.sellerId);
      if (!mounted) return;
      if (seller == null) {
        setState(() => _failed = true);
        PopupHelper.showError(
            context, 'Could not load seller information. Try again.');
        return;
      }
      setState(() => _seller = seller);
      _arc.forward().whenComplete(() {
        if (mounted) _settle.forward(from: 0);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
      PopupHelper.showError(
          context, 'Could not load seller information. Try again.');
      return;
    }

    try {
      final reviews = await fs.getReviewsForSeller(widget.sellerId);
      if (mounted) setState(() => _reviews = reviews);
    } catch (_) {
      if (mounted) {
        setState(() => _reviews = const []);
        PopupHelper.showError(context, 'Could not load reviews');
      }
    }
    try {
      final reports = await fs.getReportsForSeller(widget.sellerId);
      if (mounted) setState(() => _reports = reports);
    } catch (_) {
      if (mounted) {
        setState(() => _reports = const []);
        PopupHelper.showError(context, 'Could not load reports');
      }
    }
  }

  // ── WhatsApp fraud-warning share ─────────────────────────────────────────────

  String _warningText(SellerModel s) {
    final total = (_reports ?? const <ReportModel>[])
        .fold<double>(0, (sum, r) => sum + r.amountLost);
    final platforms = <String>[
      if (s.tiktokHandle?.isNotEmpty == true) 'TikTok',
      if (s.instagramHandle?.isNotEmpty == true) 'Instagram',
      if (s.facebookHandle?.isNotEmpty == true) 'Facebook',
    ];
    final verifyUrl = 'safebuy-nepal.vercel.app/verify?phone=${s.phone}';
    return 'FRAUD WARNING - SafeBuy Nepal\n\n'
        'Seller: ${s.displayName}\n'
        'Platform: ${platforms.isEmpty ? 'Social commerce' : platforms.join(' / ')}\n'
        'Trust Rating: HIGH RISK - ${s.trustScore.round()}/100\n'
        'Fraud Reports: ${s.scamReportCount} verified complaints\n'
        'Total Reported Lost: NPR ${NumberFormat('#,##0').format(total)}\n\n'
        'Verify any seller before paying:\n'
        '$verifyUrl\n\n'
        '- Shared via SafeBuy Nepal';
  }

  Future<void> _shareOnWhatsApp(SellerModel s) async {
    HapticFeedback.mediumImpact();
    final text = _warningText(s);
    final uri =
        Uri.parse('whatsapp://send?text=${Uri.encodeComponent(text)}');
    try {
      final ok = await launchUrl(uri);
      if (!ok) throw Exception('whatsapp unavailable');
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return;
      PopupHelper.showSuccess(context,
          'Warning text copied. WhatsApp is not installed, paste it anywhere.');
    }
  }

  Future<void> _copyWarning(SellerModel s) async {
    HapticFeedback.lightImpact();
    await Clipboard.setData(ClipboardData(text: _warningText(s)));
    if (!mounted) return;
    PopupHelper.showSuccess(context, 'Warning text copied to clipboard');
  }

  Widget _verdictChip(SellerModel s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.trustScoreSurface(s.trustScore),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        s.trustVerdict == 'trusted'
            ? '✓ TRUSTED'
            : s.trustVerdict == 'high_risk'
                ? '✕ HIGH RISK'
                : '? UNVERIFIED',
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.trustScoreColor(s.trustScore),
        ),
      ),
    );
  }

  LinearGradient get _verdictGradient {
    switch (_seller?.trustVerdict) {
      case 'trusted':
        return AppColors.trustGradient;
      case 'high_risk':
        return AppColors.riskGradient;
      default:
        return const LinearGradient(
          colors: [Color(0xFFF57F17), Color(0xFFFF8F00)],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Scaffold(
        appBar: AppBar(title: const Text('Seller Profile')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 56, color: AppColors.grey400),
              const SizedBox(height: 12),
              Text('Could not load this seller',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  setState(() => _failed = false);
                  _load();
                },
                style:
                    OutlinedButton.styleFrom(minimumSize: const Size(160, 46)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final s = _seller;
    if (s == null) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final isOwn = FirebaseAuth.instance.currentUser != null &&
        s.linkedUserId == FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 230,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(gradient: _verdictGradient),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const AnimatedDhakaPattern(opacity: 0.04),
                    SafeArea(
                      child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 28),
                      Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: TierStyle.color(s.verificationTier),
                            width: 3,
                          ),
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        child: s.profileImageUrl?.isNotEmpty == true
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: s.profileImageUrl!,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, _, _) => const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 36),
                                ),
                              )
                            : const Icon(Icons.person,
                                color: Colors.white, size: 36),
                      ),
                      const SizedBox(height: 10),
                      Text(s.displayName,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          )),
                      Text(
                        [
                          if (s.businessCategory != null)
                            s.businessCategory!,
                          if (s.verificationDistrict.isNotEmpty)
                            s.verificationDistrict,
                        ].join(' · '),
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // Trust score card
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      AnimatedBuilder(
                        animation: Listenable.merge([_arc, _settle]),
                        builder: (context, _) {
                          final t = Curves.easeOutCubic
                              .transform(_arc.value);
                          final settleScale = 1 +
                              0.05 *
                                  math.sin(math.pi * _settle.value);
                          return Transform.scale(
                            scale: settleScale,
                            child: SizedBox(
                            width: 110,
                            height: 110,
                            child: CustomPaint(
                              painter: _ArcPainter(
                                progress:
                                    t * (s.trustScore / 100),
                                color: AppColors.trustScoreColor(
                                    s.trustScore),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      (s.trustScore * t)
                                          .round()
                                          .toString(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color:
                                            AppColors.trustScoreColor(
                                                s.trustScore),
                                      ),
                                    ),
                                    Text('/100',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: AppColors.textMuted,
                                        )),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                s.trustVerdict == 'high_risk'
                                    ? PulseGlow.danger(
                                        color: AppColors.highRisk,
                                        child: _verdictChip(s),
                                      )
                                    : PulseGlow(
                                        color: AppColors.trustScoreColor(
                                            s.trustScore),
                                        duration: Duration(
                                            milliseconds:
                                                s.trustVerdict == 'trusted'
                                                    ? 2000
                                                    : 3000),
                                        child: _verdictChip(s),
                                      ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              s.verificationDate != null
                                  ? 'Last verified: ${DateFormat('dd MMM yyyy').format(s.verificationDate!)}'
                                  : 'Not yet KYC verified',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _miniStat('⭐', '${s.reviewCount}'),
                                _miniStat('📋', '${s.scamReportCount}'),
                                _miniStat('📦', '${s.totalOrders}'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Verdict explanation — warning or confidence message
                if (s.trustVerdict == 'high_risk')
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.highRiskBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.highRisk
                              .withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_rounded,
                                color: AppColors.highRisk, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'This seller has received '
                                '${s.scamReportCount} fraud '
                                'complaint${s.scamReportCount == 1 ? '' : 's'}',
                                style: GoogleFonts.poppins(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.highRisk,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'We recommend NOT paying this seller. Read '
                          'the complaints below before making any '
                          'decision.',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: AppColors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (s.trustVerdict == 'high_risk')
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _shareOnWhatsApp(s),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 44),
                            ),
                            icon: const Icon(Icons.share_rounded, size: 16),
                            label: const Text('Share on WhatsApp',
                                style: TextStyle(fontSize: 12.5)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _copyWarning(s),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.highRisk,
                              side: const BorderSide(
                                  color: AppColors.highRisk),
                              minimumSize: const Size(0, 44),
                            ),
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            label: const Text('Copy Warning Text',
                                style: TextStyle(fontSize: 12.5)),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (s.trustVerdict == 'high_risk' && _myReport != null)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pushNamed(
                          context,
                          '/cybercrime-report',
                          arguments: {
                            'reportId': _myReport!.reportId,
                            'sellerId': s.sellerId,
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.local_police_rounded, size: 18),
                      label: const Text('Escalate to Nepal Police'),
                    ),
                  ),
                if (s.trustVerdict == 'trusted')
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.trustedBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color:
                              AppColors.trusted.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      'This seller has been active for '
                      '${(DateTime.now().difference(s.accountCreatedAt).inDays / 30).floor()} '
                      'months. The community has left ${s.reviewCount} '
                      'review${s.reviewCount == 1 ? '' : 's'}, and '
                      '${s.scamReportCount == 0 ? 'there are zero fraud complaints on record' : 'only ${s.scamReportCount} complaint(s) exist'}.',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: AppColors.textPrimary,
                        height: 1.55,
                      ),
                    ),
                  ),

                // Verification status card
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(TierStyle.icon(s.verificationTier),
                              color: TierStyle.color(s.verificationTier),
                              size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '${TierStyle.label(s.verificationTier)} TIER',
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: TierStyle.color(s.verificationTier),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _checkRow('Phone verified',
                          s.phone.isNotEmpty && s.isVerified),
                      _checkRow('Identity verified', s.isKycVerified),
                      _checkRow('Location verified',
                          s.verificationDistrict.isNotEmpty),
                      _checkRow(
                          'Social media linked',
                          (s.tiktokHandle?.isNotEmpty ?? false) ||
                              (s.instagramHandle?.isNotEmpty ?? false) ||
                              (s.facebookHandle?.isNotEmpty ?? false)),
                      if (LoyaltyBadge.tierFor(s) != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(children: [LoyaltyBadge(seller: s)]),
                        ),
                      const SizedBox(height: 6),
                      _kv('Registered',
                          DateFormat('dd MMM yyyy').format(s.accountCreatedAt)),
                      if (s.verificationExpiry != null)
                        _kv(
                          s.isReverificationOverdue
                              ? '⚠ Re-verification'
                              : 'Re-verification due',
                          DateFormat('dd MMM yyyy')
                              .format(s.verificationExpiry!),
                        ),
                      if (s.verificationTier == 'none')
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'This seller has not completed identity '
                            'verification. Exercise caution with advance payments.',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: AppColors.textMuted,
                              height: 1.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Card preview (verified sellers only)
                if (s.isKycVerified)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pushNamed(context, '/seller/card',
                          arguments: {'sellerId': s.sellerId});
                    },
                    child: Hero(
                      tag: 'safebuy_card_${s.sellerId}',
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: SafebuyVerificationCard(
                            seller: s,
                            width:
                                MediaQuery.sizeOf(context).width - 32),
                      ),
                    ),
                  ),

                const SizedBox(height: 14),
              ],
            ),
          ),

          // Sticky tab bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              selected: _tab,
              counts: (
                _reviews?.length ?? 0,
                _reports?.length ?? 0,
              ),
              onChanged: (i) => setState(() => _tab = i),
            ),
          ),

          SliverToBoxAdapter(child: _buildTabContent(s)),
          SliverToBoxAdapter(child: SizedBox(height: isOwn ? 24 : 90)),
        ],
      ),

      // Fixed bottom report bar
      bottomSheet: isOwn
          ? null
          : Container(
              padding: EdgeInsets.fromLTRB(16, 10, 16,
                  MediaQuery.paddingOf(context).bottom + 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                    top: BorderSide(color: AppColors.borderLight)),
              ),
              child: SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    if (_isGuest) {
                      PopupHelper.showAuthGateBottomSheet(context);
                    } else {
                      Navigator.pushNamed(context, '/report', arguments: {
                        'sellerId': s.sellerId,
                        'phone': s.phone,
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.highRisk,
                    minimumSize: const Size(0, 50),
                  ),
                  icon: const Icon(Icons.flag_rounded, size: 18),
                  label: Text(_isGuest
                      ? 'Sign in to Report'
                      : 'Report This Seller'),
                ),
              ),
            ),
    );
  }

  Widget _buildTabContent(SellerModel s) {
    switch (_tab) {
      case 0:
        return _reviewsTab();
      case 1:
        return _reportsTab();
      default:
        return _aboutTab(s);
    }
  }

  Widget _reviewsTab() {
    if (_reviews == null) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (_reviews!.isEmpty) {
      return _empty('No reviews yet',
          'Be the first to review this seller after a purchase.');
    }
    final sorted = [..._reviews!]
      ..sort((a, b) => b.rating.compareTo(a.rating));
    final topId = sorted.first.reviewId;
    final shown = _reviews!.take(_reviewsShown).toList();
    return Column(
      children: [
        ...shown.map((r) => _ReviewCard(
              review: r,
              isTop: r.reviewId == topId && r.rating >= 4,
            )),
        if (_reviews!.length > _reviewsShown)
          Padding(
            padding: const EdgeInsets.all(12),
            child: OutlinedButton(
              onPressed: () =>
                  setState(() => _reviewsShown += 5),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(180, 44)),
              child: const Text('Load More'),
            ),
          ),
      ],
    );
  }

  Widget _reportsTab() {
    if (_reports == null) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (_reports!.isEmpty) {
      return _empty('✅ No fraud complaints on record',
          'This seller has a clean history.');
    }

    // Verified sellers get 48 hours to answer their newest complaint.
    ReportModel? awaiting;
    if (_seller?.isVerified == true) {
      final unresponded = _reports!
          .where((r) =>
              (r.sellerResponse ?? '').isEmpty &&
              r.status != 'flagged_false')
          .toList()
        ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      if (unresponded.isNotEmpty) awaiting = unresponded.first;
    }

    return Column(children: [
      if (awaiting != null) _ResponseCountdownCard(report: awaiting),
      ..._reports!.map((r) => _ReportCard(r)),
    ]);
  }

  Widget _aboutTab(SellerModel s) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (s.description?.isNotEmpty == true) ...[
            Text('About',
                style: GoogleFonts.poppins(
                    fontSize: 14.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(s.description!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.6,
                )),
            const SizedBox(height: 14),
          ],
          _kv('Category', s.businessCategory ?? 'Not specified'),
          _kv(
              'District',
              s.verificationDistrict.isNotEmpty
                  ? s.verificationDistrict
                  : 'Not verified'),
          _kv('Member since',
              DateFormat('MMMM yyyy').format(s.accountCreatedAt)),
          _kv('Phone', s.phone.isNotEmpty ? s.phone : '-'),
          if (s.esewaId?.isNotEmpty == true) _kv('eSewa ID', s.esewaId!),
          if (s.tiktokHandle?.isNotEmpty == true)
            _kv('TikTok', '@${s.tiktokHandle}'),
          if (s.instagramHandle?.isNotEmpty == true)
            _kv('Instagram', '@${s.instagramHandle}'),
          if (s.facebookHandle?.isNotEmpty == true)
            _kv('Facebook', s.facebookHandle!),
        ],
      ),
    );
  }

  Widget _empty(String title, String sub) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(sub,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 12.5, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _miniStat(String emoji, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Text('$emoji $value',
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          )),
    );
  }

  Widget _checkRow(String label, bool done) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.cancel_outlined,
            size: 16,
            color: done ? AppColors.trusted : AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Text(label,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              )),
          const Spacer(),
          Text(done ? 'Done' : 'Not verified',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: done ? AppColors.trusted : AppColors.textMuted,
              )),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(k,
                style: GoogleFonts.inter(
                    fontSize: 12.5, color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(v,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                )),
          ),
        ],
      ),
    );
  }
}

// ── Review card ────────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review, required this.isTop});

  final ReviewModel review;
  final bool isTop;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTop ? const Color(0xFFD4AF37) : AppColors.borderLight,
          width: isTop ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: AppColors.primary50,
                child: Text(
                  review.reviewerDisplayName.isNotEmpty
                      ? review.reviewerDisplayName[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.poppins(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.reviewerDisplayName,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        )),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < review.rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 14,
                          color: const Color(0xFFF5B400),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isTop)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('🏆 Top Review',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF8B6914),
                      )),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (review.productName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('Purchased: ${review.productName}',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  )),
            ),
          Text(review.comment,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.55,
              )),
          if (review.productImageUrl.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    backgroundColor: Colors.black,
                    appBar: AppBar(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white),
                    body: PhotoView(
                      imageProvider: CachedNetworkImageProvider(
                          review.productImageUrl),
                    ),
                  ),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: review.productImageUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              if (review.isVerifiedPurchase)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.trustedBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Verified Purchase ✓',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.trusted,
                      )),
                ),
              const Spacer(),
              Text(
                DateFormat('dd MMM yyyy').format(review.createdAt),
                style: GoogleFonts.inter(
                    fontSize: 10.5, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Report card ────────────────────────────────────────────────────────────────

class _ReportCard extends StatefulWidget {
  const _ReportCard(this.report);

  final ReportModel report;

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.report;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
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
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.highRiskBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  r.incidentType.replaceAll('_', ' ').toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.highRisk,
                  ),
                ),
              ),
              const Spacer(),
              Text('NPR ${r.amountLost.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.highRisk,
                  )),
            ],
          ),
          const SizedBox(height: 8),
          Text(r.description,
              maxLines: _expanded ? null : 2,
              overflow: _expanded ? null : TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.55,
              )),
          if (r.sellerResponse?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Seller response',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        )),
                    const SizedBox(height: 3),
                    Text(r.sellerResponse!,
                        maxLines: _expanded ? null : 2,
                        overflow:
                            _expanded ? null : TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                          height: 1.5,
                        )),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Text('🛡️ ${r.anonymizedReporter}',
                  style: GoogleFonts.inter(
                      fontSize: 10.5, color: AppColors.textMuted)),
              const Spacer(),
              Text(
                '${r.status.toUpperCase()} · ${DateFormat('dd MMM yyyy').format(r.submittedAt)}',
                style: GoogleFonts.inter(
                    fontSize: 10.5, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 48-hour seller response countdown ──────────────────────────────────────────

/// Amber countdown while the seller's 48h response window is open;
/// turns red once the window has expired without a response.
class _ResponseCountdownCard extends StatefulWidget {
  const _ResponseCountdownCard({required this.report});

  final ReportModel report;

  @override
  State<_ResponseCountdownCard> createState() =>
      _ResponseCountdownCardState();
}

class _ResponseCountdownCardState extends State<_ResponseCountdownCard> {
  static const _window = Duration(hours: 48);
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Keep the remaining time fresh while the tab stays open.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(widget.report.submittedAt);
    final expired = elapsed >= _window;
    final remaining = expired ? Duration.zero : _window - elapsed;
    final color = expired ? AppColors.highRisk : AppColors.unverified;
    final bg = expired ? AppColors.highRiskBg : AppColors.unverifiedBg;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                expired
                    ? Icons.timer_off_rounded
                    : Icons.hourglass_bottom_rounded,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  expired
                      ? 'Seller did not respond within 48 hours'
                      : 'Seller has ${remaining.inHours}h '
                          '${remaining.inMinutes % 60}m to respond',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (expired)
            Text(
              'This negatively affects their trust rating.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (elapsed.inMinutes / _window.inMinutes)
                    .clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: Colors.white,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Verified sellers get 48 hours to publicly answer the '
              'newest complaint before their trust rating is affected.',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Trust arc painter ──────────────────────────────────────────────────────────

class _ArcPainter extends CustomPainter {
  _ArcPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    const stroke = 10.0;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = AppColors.borderLight;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;

    final r = rect.deflate(stroke / 2 + 2);
    canvas.drawArc(r, -math.pi / 2, 2 * math.pi, false, track);
    canvas.drawArc(r, -math.pi / 2, 2 * math.pi * progress, false, arc);
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress || old.color != color;
}

// ── Sticky tab bar delegate ────────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate({
    required this.selected,
    required this.counts,
    required this.onChanged,
  });

  final int selected;
  final (int, int) counts;
  final ValueChanged<int> onChanged;

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlaps) {
    final labels = [
      'Reviews (${counts.$1})',
      'Complaints (${counts.$2})',
      'About',
    ];
    return Container(
      color: AppColors.bgSecondary,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: List.generate(3, (i) {
            final active = selected == i;
            return Expanded(
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onChanged(i);
                },
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(3),
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color:
                        active ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(labels[i],
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: active
                            ? Colors.white
                            : AppColors.textSecondary,
                      )),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) =>
      old.selected != selected || old.counts != counts;
}
