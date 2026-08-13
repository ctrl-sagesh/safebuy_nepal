import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/services/festival_alert_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dhaka_pattern.dart';
import '../../../../core/widgets/nepal_logo.dart';
import '../../../../core/utils/popup_helper.dart';
import '../../../../core/widgets/verification_card.dart';
import '../../../../models/leaderboard_model.dart';
import '../../../../services/leaderboard_service.dart';

/// Home tab — one job: get the user to search a seller before paying.
/// Hero search card → alerts strip → two actions → trusted sellers →
/// recent alerts → safety tips.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onSearchTap});

  /// Switches the shell to the Search tab; when [query] is given the
  /// search runs immediately with that text.
  final void Function([String? query])? onSearchTap;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool get _isGuest => FirebaseAuth.instance.currentUser == null;

  /// The active festival window (the service also surfaces the Dashain
  /// season banner during development).
  final String? _festival = FestivalAlertService.activeFestival();

  List<LeaderboardEntryModel>? _featured;
  bool _featuredFailed = false;

  List<Map<String, dynamic>>? _alerts;
  bool _alertsFailed = false;

  /// One-time hint teaching the Android share-to-verify shortcut.
  bool _showShareTip = false;
  static const _prefShareTipDismissed = 'share_tip_dismissed_v1';

  static const _tips = [
    ('💡', 'Never pay 100% advance to a seller you have not verified.'),
    ('🔍', 'Search the seller on SafeBuy before every purchase.'),
    ('📸', 'Always keep payment and chat screenshots as evidence.'),
    ('🔒', 'Only trust QR codes shown on a SafeBuy verification card.'),
    ('🚚', 'Prefer Cash on Delivery whenever a seller offers it.'),
  ];

  static const _exampleSearches = [
    '9841234567',
    '@priyafashions',
    '9881234571',
  ];

  @override
  void initState() {
    super.initState();
    _loadFeatured();
    _loadAlerts();
    _maybeShowShareTip();
  }

  Future<void> _maybeShowShareTip() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getBool(_prefShareTipDismissed) ?? false;
      if (!dismissed && mounted) setState(() => _showShareTip = true);
    } catch (_) {}
  }

  Future<void> _dismissShareTip() async {
    setState(() => _showShareTip = false);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefShareTipDismissed, true);
    } catch (_) {}
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

  /// Body of the hero search card (title, search bar, example chips).
  Widget _heroContent(String firstName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          !_isGuest && firstName.isNotEmpty
              ? 'Namaste, $firstName'
              : 'Verify Before You Pay',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text('Search any seller before sending eSewa payment',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
            )),
        const SizedBox(height: 16),

        // Search bar → jumps to Search tab with keyboard open
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onSearchTap?.call();
          },
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Phone number, @handle, or eSewa ID...',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text('Search',
                    style: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    )),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Tappable example searches
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _exampleSearches.map((q) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onSearchTap?.call(q);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Try: $q',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        )),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
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
    final firstName = (user?.displayName ?? '').trim().split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const SafeBuyWordmark(height: 30),
        actions: [
          IconButton(
            tooltip: 'Help',
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => Navigator.pushNamed(context, '/safeguard'),
          ),
          if (_isGuest)
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/auth'),
              child: const Text('Sign In'),
            )
          else
            _NotificationBell(userId: user?.uid),
          const SizedBox(width: 6),
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
            // ── Hero search card ──────────────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    const Positioned.fill(
                        child: AnimatedDhakaPattern(opacity: 0.06)),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: _heroContent(firstName),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05),

            // ── One-time share-to-verify tip ──────────────────────────────
            if (_showShareTip)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary100),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.ios_share_rounded,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tip: Select any phone number in WhatsApp or TikTok, '
                        'tap Share, and choose SafeBuy Nepal to verify instantly.',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          height: 1.45,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _dismissShareTip,
                      borderRadius: BorderRadius.circular(14),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close_rounded,
                            size: 16, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.1),

            // ── Festival fraud-alert banner ───────────────────────────────
            if (_festival != null &&
                !FestivalAlertService.dismissedThisSession)
              _FestivalBanner(
                festival: _festival,
                onVerify: () {
                  HapticFeedback.mediumImpact();
                  widget.onSearchTap?.call();
                },
                onDismiss: () {
                  FestivalAlertService.dismissedThisSession = true;
                  setState(() {});
                },
              ),

            // ── Active alerts strip ───────────────────────────────────────
            if (_alerts != null && _alerts!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: InkWell(
                  onTap: () => Navigator.pushNamed(context, '/alerts'),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.warningSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color:
                              AppColors.warning.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.campaign_rounded,
                            color: AppColors.warning, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${_alerts!.length} active fraud '
                            'alert${_alerts!.length == 1 ? '' : 's'} in Nepal',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.warning, size: 22),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Two clear actions ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.flag_rounded,
                      accent: AppColors.highRisk,
                      title: 'Report a Fraud',
                      subtitle: 'Were you scammed? Help protect others',
                      onTap: () => _guarded('/report'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.storefront_rounded,
                      accent: AppColors.trusted,
                      title: 'Register Business',
                      subtitle: 'Get verified and build buyer trust',
                      onTap: () => _guarded('/register-business'),
                    ),
                  ),
                ],
              ),
            ),

            // ── Trusted sellers this month ────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Trusted Sellers This Month',
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text('Verified by the SafeBuy Nepal community',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                  )),
            ),
            SizedBox(
              height: 148,
              child: _featured == null
                  ? _horizontalShimmer()
                  : _featured!.isEmpty
                      ? _emptyBox(_featuredFailed
                          ? 'Could not load sellers. Check your '
                              'connection and pull down to retry.'
                          : 'No verified sellers yet. Run a business? '
                              'Register it and be the first.')
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

            // ── Community safety alerts (last 3) ─────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Community Safety Alerts',
                        style: GoogleFonts.poppins(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        )),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/alerts'),
                    child: const Text('View All'),
                  ),
                ],
              ),
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
                    ? 'Could not load alerts. Check your connection '
                        'and pull down to retry.'
                    : 'No active alerts right now. The community '
                        'is safe today.'),
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
                              (a['body'] ?? a['description'] ?? '')
                                  as String,
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
            const SizedBox(
              height: 86,
              child: _TipsTicker(tips: _HomeScreenState._tips),
            ),

            // ── Learn more ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: InkWell(
                onTap: () => Navigator.pushNamed(context, '/guide'),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.menu_book_rounded,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'New here? Learn how SafeBuy Nepal works',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
            ),
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

// ── Action card with accent top border ─────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: accent.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border(
              top: BorderSide(color: accent, width: 3),
              left: const BorderSide(color: AppColors.borderLight),
              right: const BorderSide(color: AppColors.borderLight),
              bottom: const BorderSide(color: AppColors.borderLight),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent, size: 21),
              ),
              const SizedBox(height: 10),
              Text(title,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  )),
              const SizedBox(height: 3),
              Text(subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    height: 1.4,
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

// ── Festival fraud-alert banner ────────────────────────────────────────────────

/// Red dismissible warning shown under the hero while a festival shopping
/// window is active (fraud complaints spike around festivals).
class _FestivalBanner extends StatelessWidget {
  const _FestivalBanner({
    required this.festival,
    required this.onVerify,
    required this.onDismiss,
  });

  final String festival;
  final VoidCallback onVerify;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDC143C), Color(0xFF8B0000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDC143C).withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text('$festival Season Fraud Alert',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    )),
              ),
              InkWell(
                onTap: onDismiss,
                borderRadius: BorderRadius.circular(14),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded,
                      color: Colors.white70, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Dashain season brings a significant increase in social commerce '
            'fraud across Nepal. Exercise extra caution when buying from new '
            'or unverified sellers. Always verify on SafeBuy Nepal before '
            'making any payment.',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 38,
            child: ElevatedButton(
              onPressed: onVerify,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF8B0000),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: Text('Verify a Seller Now',
                  style: GoogleFonts.inter(
                      fontSize: 12.5, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.15);
  }
}

// ── Continuously scrolling safety-tips ticker ─────────────────────────────────

/// Endless left-scrolling row of tip cards. Touching the row pauses the
/// scroll; releasing resumes it.
class _TipsTicker extends StatefulWidget {
  const _TipsTicker({required this.tips});

  final List<(String, String)> tips;

  @override
  State<_TipsTicker> createState() => _TipsTickerState();
}

class _TipsTickerState extends State<_TipsTicker>
    with SingleTickerProviderStateMixin {
  static const _pxPerSecond = 32.0;

  final _scroll = ScrollController();
  late final Ticker _ticker = createTicker(_onTick);
  Duration _last = Duration.zero;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (_paused || !_scroll.hasClients || dt <= 0 || dt > 0.5) return;
    _scroll.jumpTo(_scroll.offset + _pxPerSecond * dt);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _paused = true,
      onPointerUp: (_) => _paused = false,
      onPointerCancel: (_) => _paused = false,
      child: ListView.builder(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemBuilder: (context, i) {
          final (emoji, text) = widget.tips[i % widget.tips.length];
          return Container(
            width: MediaQuery.sizeOf(context).width * 0.78,
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
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
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
    );
  }
}
