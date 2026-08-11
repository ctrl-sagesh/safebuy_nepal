import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/phone_extractor.dart';
import '../../../../core/widgets/nepal_logo.dart';
import '../../../../models/seller_model.dart';
import '../../../../services/firestore_service.dart';

/// Quick Verify — the full-screen result shown when SafeBuy Nepal is opened
/// from another app's share sheet (a selected phone number or @handle).
/// It looks the seller up immediately and shows the trust verdict, so the
/// buyer never loses the context of the chat they came from.
class ShareResultScreen extends ConsumerStatefulWidget {
  const ShareResultScreen({super.key, this.initialQuery});

  /// The shared text's extracted identifier. Null/invalid → manual field.
  final String? initialQuery;

  @override
  ConsumerState<ShareResultScreen> createState() => _ShareResultScreenState();
}

enum _State { loading, found, notFound, error, manual }

class _ShareResultScreenState extends ConsumerState<ShareResultScreen>
    with TickerProviderStateMixin {
  final _manualCtrl = TextEditingController();

  _State _state = _State.loading;
  SellerModel? _seller;
  String _query = '';
  double _amountLost = 0;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  late final AnimationController _arc = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  @override
  void initState() {
    super.initState();
    final q = widget.initialQuery;
    if (PhoneExtractor.isValid(q)) {
      _query = q!;
      _lookup(q);
    } else {
      _state = _State.manual;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _arc.dispose();
    _manualCtrl.dispose();
    super.dispose();
  }

  Future<void> _lookup(String query) async {
    setState(() {
      _state = _State.loading;
      _query = query;
    });
    final fs = ref.read(firestoreServiceProvider);
    try {
      final seller = await fs.searchSeller(query);
      if (!mounted) return;
      if (seller == null) {
        setState(() => _state = _State.notFound);
        return;
      }
      // Best-effort loss total (needs auth; falls back to count-only).
      double total = 0;
      try {
        final reports = await fs.getReportsForSeller(seller.sellerId);
        total = reports
            .where((r) => r.status != 'flagged_false')
            .fold<double>(0, (s, r) => s + r.amountLost);
      } catch (_) {
        total = 0;
      }
      if (!mounted) return;
      setState(() {
        _seller = seller;
        _amountLost = total;
        _state = _State.found;
      });
      _arc.forward(from: 0);
    } catch (_) {
      if (mounted) setState(() => _state = _State.error);
    }
  }

  void _close() {
    // Return the user to the app they came from.
    SystemNavigator.pop();
  }

  // ── Verdict palette ──────────────────────────────────────────────────────────

  ({Color bg, Color fg, IconData icon, String label}) get _verdict {
    switch (_seller?.trustVerdict) {
      case 'trusted':
        return (
          bg: const Color(0xFFE8F5E9),
          fg: const Color(0xFF2E7D32),
          icon: Icons.verified_rounded,
          label: 'TRUSTED SELLER',
        );
      case 'high_risk':
        return (
          bg: const Color(0xFFFFEBEE),
          fg: const Color(0xFFC62828),
          icon: Icons.dangerous_rounded,
          label: 'HIGH RISK: DO NOT PAY',
        );
      default:
        return (
          bg: const Color(0xFFFFF8E1),
          fg: const Color(0xFFE65100),
          icon: Icons.warning_amber_rounded,
          label: 'UNVERIFIED SELLER',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 44,
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: Center(child: NepalLogo(size: 32)),
        ),
        title: Text('Quick Verify',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            )),
        actions: [
          IconButton(
            onPressed: _close,
            icon: const Icon(Icons.close_rounded, color: Color(0xFF1A1A1A)),
            tooltip: 'Close',
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE0E0E0)),
        ),
      ),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    switch (_state) {
      case _State.loading:
        return _loading();
      case _State.found:
        return _found(_seller!);
      case _State.notFound:
        return _notFound();
      case _State.error:
        return _error();
      case _State.manual:
        return _manual();
    }
  }

  // ── Loading ──────────────────────────────────────────────────────────────────

  Widget _loading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: Tween(begin: 1.0, end: 1.1).animate(
                CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
            child: const NepalLogo(size: 72),
          ),
          const SizedBox(height: 18),
          Text('Checking seller...',
              style:
                  GoogleFonts.inter(fontSize: 14, color: const Color(0xFF666666))),
          const SizedBox(height: 24),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFECECEC)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Found ────────────────────────────────────────────────────────────────────

  Widget _found(SellerModel s) {
    final v = _verdict;
    final months =
        (DateTime.now().difference(s.accountCreatedAt).inDays / 30)
            .floor()
            .clamp(0, 999);
    final isHighRisk = s.trustVerdict == 'high_risk';
    final isTrusted = s.trustVerdict == 'trusted';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Verdict banner
              Container(
                height: 80,
                color: v.bg,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(v.icon, size: 40, color: v.fg),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(v.label,
                              style: GoogleFonts.poppins(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color: v.fg,
                              )),
                          Text('Trust Rating: ${s.trustScore.round()}/100',
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF666666))),
                        ],
                      ),
                    ),
                    _scoreCircle(s.trustScore, v.fg),
                  ],
                ),
              ),

              // Seller details
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.displayName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A1A),
                        )),
                    const SizedBox(height: 2),
                    Text(_query,
                        style: GoogleFonts.inter(
                            fontSize: 13, color: const Color(0xFF666666))),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _chip('${s.reviewCount} Reviews',
                            const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
                        _chip('$months Months Active',
                            const Color(0xFFEFF6FF), AppColors.primary),
                        if (s.scamReportCount > 0)
                          _chip('${s.scamReportCount} Complaints',
                              const Color(0xFFFFEBEE), const Color(0xFFC62828)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(_tierIcon(s.verificationTier),
                            size: 16, color: const Color(0xFF6A1B9A)),
                        const SizedBox(width: 6),
                        Text('${_tierLabel(s.verificationTier)} tier',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6A1B9A),
                            )),
                      ],
                    ),
                    if (isHighRisk) ...[
                      const SizedBox(height: 14),
                      _box(
                        bg: const Color(0xFFFFEBEE),
                        border: const Color(0xFFEF9A9A),
                        color: const Color(0xFFC62828),
                        text: _amountLost > 0
                            ? '${s.scamReportCount} fraud complaint${s.scamReportCount == 1 ? '' : 's'} have been filed against this seller totalling NPR ${NumberFormat('#,##0').format(_amountLost)}.'
                            : '${s.scamReportCount} fraud complaint${s.scamReportCount == 1 ? '' : 's'} have been filed against this seller.',
                      ),
                    ],
                    if (isTrusted) ...[
                      const SizedBox(height: 14),
                      _box(
                        bg: const Color(0xFFE8F5E9),
                        border: const Color(0xFFA5D6A7),
                        color: const Color(0xFF2E7D32),
                        text:
                            'This seller has a clean record with ${s.reviewCount} verified review${s.reviewCount == 1 ? '' : 's'} and zero complaints.',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _foundButtons(s, isHighRisk),
      ],
    );
  }

  Widget _foundButtons(SellerModel s, bool isHighRisk) {
    void openProfile() => Navigator.pushReplacementNamed(context, '/seller',
        arguments: {'sellerId': s.sellerId});

    if (isHighRisk) {
      return Column(
        children: [
          _primaryBtn('Report This Seller', const Color(0xFFC62828), () {
            Navigator.pushReplacementNamed(context, '/report', arguments: {
              'sellerId': s.sellerId,
              'phone': s.phone,
            });
          }),
          const SizedBox(height: 10),
          _outlineBtn('View Full Profile', openProfile),
        ],
      );
    }
    return Column(
      children: [
        _primaryBtn('View Full Profile', AppColors.primary, openProfile),
        const SizedBox(height: 10),
        _outlineBtn('Search Another Number',
            () => setState(() => _state = _State.manual)),
      ],
    );
  }

  // ── Not found ────────────────────────────────────────────────────────────────

  Widget _notFound() {
    const tips = [
      'Ask for a video call showing the real product',
      'Start with a small test order under NPR 500',
      'Screenshot everything before paying',
      'Never pay the full amount before dispatch proof',
    ];
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_rounded,
                size: 60, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 18),
        Text('Seller not found on SafeBuy Nepal',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            )),
        const SizedBox(height: 8),
        Center(
          child: SizedBox(
            width: 280,
            child: Text(
              'They may not be registered yet. This does not mean they are fraudulent.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFF666666), height: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(12),
            border: const Border(
                left: BorderSide(color: Color(0xFFE65100), width: 4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Safety tips for unverified sellers:',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFE65100),
                  )),
              const SizedBox(height: 10),
              ...tips.map((t) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.only(left: 10),
                    decoration: const BoxDecoration(
                      border: Border(
                          left: BorderSide(
                              color: Color(0xFFE65100), width: 2)),
                    ),
                    child: Text(t,
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF555555),
                            height: 1.4)),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _outlineBtn('Report if Scammed', () {
          Navigator.pushReplacementNamed(context, '/report',
              arguments: {'prefill': _query});
        }, color: const Color(0xFFC62828)),
        const SizedBox(height: 10),
        _outlineBtn('Search Another',
            () => setState(() => _state = _State.manual)),
      ],
    );
  }

  // ── Error ────────────────────────────────────────────────────────────────────

  Widget _error() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 64, color: Color(0xFF9E9E9E)),
          const SizedBox(height: 14),
          Text('Could not connect',
              style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A))),
          const SizedBox(height: 6),
          Text('Check your internet connection and try again',
              style:
                  GoogleFonts.inter(fontSize: 13, color: const Color(0xFF666666))),
          const SizedBox(height: 20),
          SizedBox(
            width: 180,
            child: _primaryBtn('Retry', AppColors.primary,
                () => _lookup(_query)),
          ),
        ],
      ),
    );
  }

  // ── Manual field ─────────────────────────────────────────────────────────────

  Widget _manual() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 12),
        Center(child: NepalLogo(size: 56)),
        const SizedBox(height: 16),
        Text('Verify a seller',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            )),
        const SizedBox(height: 6),
        Text('Enter a phone number or @handle to check their trust rating.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 13, color: const Color(0xFF666666), height: 1.5)),
        const SizedBox(height: 20),
        TextField(
          controller: _manualCtrl,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: (v) => _submitManual(),
          style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF1A1A1A)),
          decoration: const InputDecoration(
            hintText: '98XXXXXXXX or @handle',
            prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF9E9E9E)),
          ),
        ),
        const SizedBox(height: 14),
        _primaryBtn('Check Seller', AppColors.primary, _submitManual),
      ],
    );
  }

  void _submitManual() {
    final q = _manualCtrl.text.trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    _lookup(q.startsWith('@') ? q : q.replaceAll(RegExp(r'\D'), ''));
  }

  // ── Small builders ───────────────────────────────────────────────────────────

  Widget _scoreCircle(double score, Color color) {
    return AnimatedBuilder(
      animation: _arc,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(_arc.value);
        return SizedBox(
          width: 48,
          height: 48,
          child: CustomPaint(
            painter: _MiniArcPainter(progress: t * (score / 100), color: color),
            child: Center(
              child: Text('${(score * t).round()}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color,
                  )),
            ),
          ),
        );
      },
    );
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  Widget _box(
      {required Color bg,
      required Color border,
      required Color color,
      required String text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Text(text,
          style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
              height: 1.45)),
    );
  }

  Widget _primaryBtn(String label, Color color, VoidCallback onTap) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
        ),
        child: Text(label,
            style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _outlineBtn(String label, VoidCallback onTap,
      {Color color = AppColors.primary}) {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 1.5),
          minimumSize: const Size(double.infinity, 50),
        ),
        child: Text(label,
            style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }

  IconData _tierIcon(String tier) {
    switch (tier) {
      case 'premium':
        return Icons.workspace_premium_rounded;
      case 'verified':
        return Icons.verified_user_rounded;
      case 'basic':
        return Icons.how_to_reg_rounded;
      default:
        return Icons.person_outline_rounded;
    }
  }

  String _tierLabel(String tier) {
    switch (tier) {
      case 'premium':
        return 'Premium';
      case 'verified':
        return 'Verified';
      case 'basic':
        return 'Basic';
      default:
        return 'Unverified';
    }
  }
}

// Small circular progress arc for the compact verdict score.
class _MiniArcPainter extends CustomPainter {
  _MiniArcPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    const stroke = 4.0;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = color.withValues(alpha: 0.18);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    final r = rect.deflate(stroke / 2 + 1);
    canvas.drawArc(r, -math.pi / 2, 2 * math.pi, false, track);
    canvas.drawArc(r, -math.pi / 2, 2 * math.pi * progress, false, arc);
  }

  @override
  bool shouldRepaint(_MiniArcPainter old) =>
      old.progress != progress || old.color != color;
}
