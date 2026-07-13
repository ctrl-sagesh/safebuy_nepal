import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/popup_helper.dart';
import '../../../../core/widgets/verification_card.dart';
import '../../../../models/leaderboard_model.dart';
import '../../../../services/leaderboard_service.dart';

/// Home tab — hero card, quick actions, featured sellers, alerts, tips.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onSearchTap});

  /// Switches the shell to the Search tab.
  final VoidCallback? onSearchTap;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool get _isGuest => FirebaseAuth.instance.currentUser == null;

  List<LeaderboardEntryModel>? _featured;
  bool _featuredFailed = false;

  List<Map<String, dynamic>>? _alerts;
  bool _alertsFailed = false;

  final _tipsController = PageController(viewportFraction: 0.92);
  int _tipIndex = 0;
  Timer? _tipsTimer;

  static const _tips = [
    ('💡', 'Never pay 100% advance to a seller you have not verified.'),
    ('🔍', 'Search the seller on SafeBuy before every purchase.'),
    ('📸', 'Always keep payment and chat screenshots as evidence.'),
    ('🔒', 'Only trust QR codes shown on a SafeBuy verification card.'),
    ('🚚', 'Prefer Cash on Delivery whenever a seller offers it.'),
  ];

  @override
  void initState() {
    super.initState();
    _loadFeatured();
    _loadAlerts();
    _tipsTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_tipsController.hasClients) return;
      _tipIndex = (_tipIndex + 1) % _tips.length;
      _tipsController.animateToPage(
        _tipIndex,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _tipsTimer?.cancel();
    _tipsController.dispose();
    super.dispose();
  }

  Future<void> _loadFeatured() async {
    try {
      final list = await LeaderboardService().getLeaderboard(limit: 5);
      if (mounted) setState(() => _featured = list);
    } catch (_) {
      if (mounted) {
        setState(() {
          _featured = [];
          _featuredFailed = true;
        });
        PopupHelper.showWarning(context, 'Could not load featured sellers');
      }
    }
  }

  Future<void> _loadAlerts() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('community_alerts')
          .orderBy('createdAt', descending: true)
          .limit(3)
          .get();
      if (mounted) {
        setState(() => _alerts = snap.docs.map((d) => d.data()).toList());
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _alerts = [];
          _alertsFailed = true;
        });
      }
    }
  }

  void _guarded(String route) {
    HapticFeedback.mediumImpact();
    if (_isGuest) {
      PopupHelper.showAuthGateBottomSheet(context);
    } else {
      Navigator.pushNamed(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning! 👋'
        : hour < 17
            ? 'Good afternoon! 👋'
            : 'Good evening! 👋';

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: false,
        title: Row(
          children: [
            const Icon(Icons.shield_rounded,
                color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            Text('SafeBuy Nepal',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                )),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Ask SafeGuard AI',
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => Navigator.pushNamed(context, '/safeguard'),
          ),
          if (_isGuest) ...[
            Container(
              margin: const EdgeInsets.symmetric(vertical: 14),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text('Guest',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  )),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/auth'),
              child: const Text('Sign In'),
            ),
          ] else ...[
            _NotificationBell(userId: user?.uid),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/profile'),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary50,
                  child: Text(
                    (user?.displayName?.isNotEmpty == true
                            ? user!.displayName![0]
                            : 'U')
                        .toUpperCase(),
                    style: GoogleFonts.poppins(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await Future.wait([_loadFeatured(), _loadAlerts()]);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            // ── Hero card ─────────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(greeting,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 4),
                  Text('Verify before you pay — every time.',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12.5,
                      )),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _statPill('1,247', 'Verified'),
                      const SizedBox(width: 8),
                      _statPill('389', 'Reports'),
                      const SizedBox(width: 8),
                      _statPill('Rs 2.1M', 'Saved'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Search bar → jumps to Search tab
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onSearchTap?.call();
                    },
                    child: Container(
                      height: 48,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded,
                              color: AppColors.primary),
                          const SizedBox(width: 10),
                          Text(
                            'Search by phone, eSewa ID, or @handle…',
                            style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05),

            // ── Quick actions ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.flag_rounded,
                      label: 'Report\nFraud',
                      gradient: AppColors.riskGradient,
                      onTap: () => _guarded('/report'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.storefront_rounded,
                      label: 'Register\nBusiness',
                      gradient: AppColors.trustGradient,
                      onTap: () => _guarded('/register-business'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.menu_book_rounded,
                      label: 'How It\nWorks',
                      gradient: AppColors.primaryGradient,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pushNamed(context, '/guide');
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ── Featured verified sellers ────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Top Verified Sellers This Month',
                        style: GoogleFonts.poppins(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        )),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/leaderboard'),
                    child: const Text('See All'),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 148,
              child: _featured == null
                  ? _horizontalShimmer()
                  : _featured!.isEmpty
                      ? _emptyBox(_featuredFailed
                          ? 'Could not load sellers right now'
                          : 'No verified sellers yet — be the first!')
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _featured!.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, i) {
                            final e = _featured![i];
                            return _FeaturedSellerCard(entry: e, rank: i + 1)
                                .animate(delay: (i * 60).ms)
                                .fadeIn()
                                .slideX(begin: 0.08);
                          },
                        ),
            ),

            // ── Recent community alerts ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
              child: Text('Recent Community Alerts',
                  style: GoogleFonts.poppins(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  )),
            ),
            if (_alerts == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: List.generate(
                    2,
                    (_) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _shimmerBox(height: 68),
                    ),
                  ),
                ),
              )
            else if (_alerts!.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _emptyBox(_alertsFailed
                    ? 'Could not load alerts right now'
                    : '✅ No active alerts in your area'),
              )
            else
              ..._alerts!.asMap().entries.map((entry) {
                final a = entry.value;
                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.highRiskBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.campaign_rounded,
                            color: AppColors.highRisk, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a['title'] as String? ?? 'Community alert',
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              a['body'] as String? ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: (entry.key * 60).ms).fadeIn().slideX(
                      begin: 0.05,
                    );
              }),

            // ── Safety tips carousel ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Text('Safety Tips',
                  style: GoogleFonts.poppins(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  )),
            ),
            SizedBox(
              height: 86,
              child: PageView.builder(
                controller: _tipsController,
                itemCount: _tips.length,
                onPageChanged: (i) => _tipIndex = i,
                itemBuilder: (context, i) {
                  final (emoji, text) = _tips[i];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 26)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            text,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statPill(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                )),
            Text(label,
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 10.5,
                )),
          ],
        ),
      ),
    );
  }

  Widget _horizontalShimmer() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (_, _) => _shimmerBox(width: 200, height: 140),
    );
  }

  Widget _shimmerBox({double? width, double height = 100}) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _emptyBox(String text) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      alignment: Alignment.center,
      child: Text(text,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
          )),
    );
  }
}

// ── Quick action card ──────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: AppColors.primary.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 8),
              Text(label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.25,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Featured seller card ───────────────────────────────────────────────────────

class _FeaturedSellerCard extends StatelessWidget {
  const _FeaturedSellerCard({required this.entry, required this.rank});

  final LeaderboardEntryModel entry;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final tierColor = TierStyle.color(entry.verificationTier);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pushNamed(context, '/seller',
              arguments: {'sellerId': entry.sellerId});
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: tierColor, width: 2),
                      color: AppColors.primary50,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      entry.displayName.isNotEmpty
                          ? entry.displayName[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.poppins(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    rank == 1
                        ? '🥇'
                        : rank == 2
                            ? '🥈'
                            : rank == 3
                                ? '🥉'
                                : '#$rank',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(entry.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  )),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(TierStyle.icon(entry.verificationTier),
                      size: 13, color: tierColor),
                  const SizedBox(width: 4),
                  Text(TierStyle.label(entry.verificationTier),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: tierColor,
                      )),
                  const Spacer(),
                  const Icon(Icons.star_rounded,
                      size: 14, color: Color(0xFFF5B400)),
                  Text(
                    entry.averageRating.toStringAsFixed(1),
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Notification bell with live unread badge ────────────────────────────────────

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({this.userId});

  final String? userId;

  @override
  Widget build(BuildContext context) {
    final bell = IconButton(
      icon: const Icon(Icons.notifications_none_rounded),
      tooltip: 'Notifications',
      onPressed: () => Navigator.pushNamed(context, '/notifications'),
    );
    if (userId == null) return bell;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .snapshots(),
      builder: (context, snap) {
        final count = snap.hasData ? snap.data!.docs.length : 0;
        if (count == 0) return bell;
        return Stack(
          alignment: Alignment.center,
          children: [
            bell,
            Positioned(
              top: 10,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                constraints:
                    const BoxConstraints(minWidth: 18, minHeight: 18),
                decoration: BoxDecoration(
                  color: AppColors.highRisk,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
