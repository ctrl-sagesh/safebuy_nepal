import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../utils/constants.dart' show AppColors;

// ---------------------------------------------------------------------------
// Data models for the feed
// ---------------------------------------------------------------------------

class _ScamAlert {
  final String title;
  final String description;
  final String timeAgo;
  final String severity; // 'critical', 'high', 'medium'
  final IconData icon;

  const _ScamAlert({
    required this.title,
    required this.description,
    required this.timeAgo,
    required this.severity,
    required this.icon,
  });
}

class _SafetyTip {
  final String title;
  final String body;
  final IconData icon;
  final int colorIndex;

  const _SafetyTip({
    required this.title,
    required this.body,
    required this.icon,
    required this.colorIndex,
  });
}

class _ScamCategory {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _ScamCategory({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });
}

class _DidYouKnowFact {
  final String stat;
  final String detail;
  final IconData icon;

  const _DidYouKnowFact({
    required this.stat,
    required this.detail,
    required this.icon,
  });
}

// ---------------------------------------------------------------------------
// Hard-coded data
// ---------------------------------------------------------------------------

const _alerts = <_ScamAlert>[
  _ScamAlert(
    title: 'Fake Cosmetics Seller',
    description:
        'TikTok seller "glamour_np" reported 15 times for shipping counterfeit cosmetics. Victims paid via eSewa with no refund.',
    timeAgo: '12 min ago',
    severity: 'critical',
    icon: Icons.warning_amber_rounded,
  ),
  _ScamAlert(
    title: 'Advance-Payment Scam',
    description:
        'New advance-payment scam targeting Daraz sellers. Scammer orders high-value items and requests bank transfer outside the platform.',
    timeAgo: '47 min ago',
    severity: 'critical',
    icon: Icons.account_balance_wallet_outlined,
  ),
  _ScamAlert(
    title: 'eSewa Reversal Fraud',
    description:
        'eSewa payment reversal fraud increasing in Kathmandu Valley. Scammers exploit delayed settlement windows to claw back funds.',
    timeAgo: '2 hr ago',
    severity: 'high',
    icon: Icons.sync_problem_rounded,
  ),
  _ScamAlert(
    title: 'Instagram Clone Pages',
    description:
        'Multiple clone pages impersonating "kathmandu_kicks" sneaker store on Instagram. Victims receive empty parcels from Pokhara.',
    timeAgo: '3 hr ago',
    severity: 'high',
    icon: Icons.content_copy_rounded,
  ),
  _ScamAlert(
    title: 'Fake Delivery SMS',
    description:
        'Phishing SMS claiming "Your parcel is held at customs, pay Rs 499 to release." Links lead to credential-harvesting sites.',
    timeAgo: '5 hr ago',
    severity: 'medium',
    icon: Icons.sms_failed_rounded,
  ),
  _ScamAlert(
    title: 'Khalti QR Code Swap',
    description:
        'Vendors in Thamel swapping legitimate Khalti QR stickers with their own. Always verify merchant name before confirming payment.',
    timeAgo: '8 hr ago',
    severity: 'medium',
    icon: Icons.qr_code_2_rounded,
  ),
];

const _tips = <_SafetyTip>[
  _SafetyTip(
    title: 'Verify Before Paying',
    body: 'Always verify the seller on SafeBuy before sending any advance payment.',
    icon: Icons.verified_user_rounded,
    colorIndex: 0,
  ),
  _SafetyTip(
    title: 'Check Trust Score',
    body: 'Check the SafeBuy trust score before ordering. Anything below 60 is risky.',
    icon: Icons.score_rounded,
    colorIndex: 1,
  ),
  _SafetyTip(
    title: 'Never Share OTP',
    body: 'Never share your OTP or banking PIN with any seller, no matter the reason.',
    icon: Icons.lock_outline_rounded,
    colorIndex: 2,
  ),
  _SafetyTip(
    title: 'Use Platform Payments',
    body: 'Pay through official platform checkout instead of direct bank transfer.',
    icon: Icons.payment_rounded,
    colorIndex: 3,
  ),
  _SafetyTip(
    title: 'Screenshot Everything',
    body: 'Save screenshots of chats, listings, and payment receipts as evidence.',
    icon: Icons.screenshot_monitor_rounded,
    colorIndex: 0,
  ),
  _SafetyTip(
    title: 'Spot Fake Reviews',
    body: 'Be wary of sellers with only 5-star reviews posted on the same day.',
    icon: Icons.rate_review_outlined,
    colorIndex: 1,
  ),
  _SafetyTip(
    title: 'Verify Social Proof',
    body: 'Check if the seller has a physical address and active customer community.',
    icon: Icons.storefront_rounded,
    colorIndex: 2,
  ),
  _SafetyTip(
    title: 'Report Suspicious Activity',
    body: 'Report scams on SafeBuy to protect the community. Your report stays anonymous.',
    icon: Icons.flag_rounded,
    colorIndex: 3,
  ),
];

final _categories = <_ScamCategory>[
  _ScamCategory(
    label: 'Fake Products',
    count: 342,
    color: const Color(0xFFE53935),
    icon: Icons.inventory_2_outlined,
  ),
  _ScamCategory(
    label: 'Payment Fraud',
    count: 218,
    color: const Color(0xFFFF8F00),
    icon: Icons.credit_card_off_rounded,
  ),
  _ScamCategory(
    label: 'Non-Delivery',
    count: 187,
    color: const Color(0xFF7B1FA2),
    icon: Icons.local_shipping_outlined,
  ),
  _ScamCategory(
    label: 'Account Clone',
    count: 129,
    color: const Color(0xFF00897B),
    icon: Icons.person_off_rounded,
  ),
  _ScamCategory(
    label: 'Phishing',
    count: 94,
    color: const Color(0xFF1565C0),
    icon: Icons.phishing_rounded,
  ),
];

const _facts = <_DidYouKnowFact>[
  _DidYouKnowFact(
    stat: '73%',
    detail: 'of online shopping scams in Nepal originate from social media platforms.',
    icon: Icons.pie_chart_rounded,
  ),
  _DidYouKnowFact(
    stat: 'Rs 4.2Cr',
    detail: 'was lost to e-commerce fraud in Nepal in the last 12 months alone.',
    icon: Icons.money_off_rounded,
  ),
  _DidYouKnowFact(
    stat: '1 in 5',
    detail: 'Nepali online shoppers have experienced at least one scam incident.',
    icon: Icons.people_outline_rounded,
  ),
  _DidYouKnowFact(
    stat: '48 hrs',
    detail: 'is the average time before a fraudulent seller deletes their account.',
    icon: Icons.timer_outlined,
  ),
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class NewsFeedScreen extends ConsumerWidget {
  const NewsFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildGradientAppBar(context),
          SliverToBoxAdapter(child: _buildLiveAlerts(context)),
          SliverToBoxAdapter(child: _buildSafetyTips(context)),
          SliverToBoxAdapter(child: _buildTrendingCategories(context)),
          SliverToBoxAdapter(child: _buildDidYouKnow(context)),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Gradient SliverAppBar
  // -------------------------------------------------------------------------

  Widget _buildGradientAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      stretch: true,
      backgroundColor: const Color(AppColors.gradStart),
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 16),
        title: Text(
          'Scam Alerts & Safety',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 0.3,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(AppColors.gradStart),
                Color(AppColors.gradEnd),
                Color(0xFF1E88E5),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -30,
                right: -40,
                child: _glassCircle(130, 0.08),
              ),
              Positioned(
                bottom: 10,
                left: -20,
                child: _glassCircle(90, 0.06),
              ),
              Positioned(
                top: 40,
                left: 60,
                child: _glassCircle(50, 0.10),
              ),
              // Shield icon
              Center(
                child: Icon(
                  Icons.shield_rounded,
                  size: 60,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // LIVE ALERTS — Horizontal carousel
  // -------------------------------------------------------------------------

  Widget _buildLiveAlerts(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.notifications_active_rounded,
            label: 'LIVE ALERTS',
            badgeColor: const Color(AppColors.highRisk),
            trailing: _liveBadge(),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideX(begin: -0.05, end: 0),
          const SizedBox(height: 14),
          SizedBox(
            height: 200,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _alerts.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (_, i) => _alertCard(_alerts[i], i),
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertCard(_ScamAlert alert, int index) {
    final isRed = alert.severity == 'critical';
    final isOrange = alert.severity == 'high';
    final gradColors = isRed
        ? [const Color(0xFFC62828), const Color(0xFFE53935)]
        : isOrange
            ? [const Color(0xFFE65100), const Color(0xFFFF8F00)]
            : [const Color(0xFFFF8F00), const Color(0xFFFFA726)];

    return Container(
      width: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradColors,
        ),
        boxShadow: [
          BoxShadow(
            color: gradColors.first.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Glass circle decoration
          Positioned(
            top: -20,
            right: -20,
            child: _glassCircle(80, 0.12),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(alert.icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        alert.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Text(
                    alert.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.90),
                      fontSize: 12.5,
                      height: 1.45,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: Colors.white.withValues(alpha: 0.70),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      alert.timeAgo,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.70),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        alert.severity.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: (80 * index).ms)
        .slideX(begin: 0.15, end: 0, curve: Curves.easeOut);
  }

  // -------------------------------------------------------------------------
  // SAFETY TIPS
  // -------------------------------------------------------------------------

  Widget _buildSafetyTips(BuildContext context) {
    const tipGradients = <List<Color>>[
      [Color(0xFF00897B), Color(0xFF26A69A)], // teal
      [Color(0xFF1565C0), Color(0xFF42A5F5)], // blue
      [Color(0xFF2E7D32), Color(0xFF66BB6A)], // green
      [Color(0xFF00838F), Color(0xFF4DD0E1)], // cyan
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.health_and_safety_rounded,
            label: 'Safety Tips',
            badgeColor: const Color(AppColors.trusted),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideX(begin: -0.05, end: 0),
          const SizedBox(height: 14),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _tips.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final tip = _tips[i];
              final colors = tipGradients[tip.colorIndex];
              return _tipCard(tip, colors, i);
            },
          ),
        ],
      ),
    );
  }

  Widget _tipCard(_SafetyTip tip, List<Color> colors, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Left accent bar
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: colors,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: colors,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: colors.first.withValues(alpha: 0.30),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(tip.icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tip.title,
                          style: const TextStyle(
                            color: Color(AppColors.textDark),
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tip.body,
                          style: const TextStyle(
                            color: Color(AppColors.textGrey),
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms, delay: (60 * index).ms)
        .slideY(begin: 0.08, end: 0, curve: Curves.easeOut);
  }

  // -------------------------------------------------------------------------
  // TRENDING SCAM TYPES — Circular indicators
  // -------------------------------------------------------------------------

  Widget _buildTrendingCategories(BuildContext context) {
    final total = _categories.fold<int>(0, (s, c) => s + c.count);

    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.trending_up_rounded,
            label: 'Trending Scam Types',
            badgeColor: const Color(AppColors.accent),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideX(begin: -0.05, end: 0),
          const SizedBox(height: 18),
          // Ring chart + legend
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Circular chart
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CustomPaint(
                    painter: _RingChartPainter(_categories, total),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            total.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                              color: Color(AppColors.textDark),
                            ),
                          ),
                          const Text(
                            'Reports',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(AppColors.textGrey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // Legend
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _categories.asMap().entries.map((e) {
                      final cat = e.value;
                      final pct = (cat.count / total * 100).round();
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: cat.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(cat.icon, color: cat.color, size: 16),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                cat.label,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(AppColors.textDark),
                                ),
                              ),
                            ),
                            Text(
                              '$pct%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: cat.color,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // DID YOU KNOW?
  // -------------------------------------------------------------------------

  Widget _buildDidYouKnow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.lightbulb_outline_rounded,
            label: 'Did You Know?',
            badgeColor: const Color(0xFF6A1B9A),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideX(begin: -0.05, end: 0),
          const SizedBox(height: 14),
          SizedBox(
            height: 160,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _facts.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (_, i) => _factCard(_facts[i], i),
            ),
          ),
        ],
      ),
    );
  }

  Widget _factCard(_DidYouKnowFact fact, int index) {
    const gradients = <List<Color>>[
      [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
      [Color(0xFF283593), Color(0xFF5C6BC0)],
      [Color(0xFF00695C), Color(0xFF4DB6AC)],
      [Color(0xFFC62828), Color(0xFFEF5350)],
    ];
    final colors = gradients[index % gradients.length];

    return Container(
      width: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.30),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: -15,
            right: -15,
            child: _glassCircle(70, 0.10),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  fact.icon,
                  color: Colors.white.withValues(alpha: 0.85),
                  size: 28,
                ),
                const SizedBox(height: 10),
                Text(
                  fact.stat,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  fact.detail,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: (90 * index).ms)
        .slideX(begin: 0.12, end: 0, curve: Curves.easeOut);
  }

  // -------------------------------------------------------------------------
  // Shared helpers
  // -------------------------------------------------------------------------

  static Widget _glassCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String label,
    required Color badgeColor,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: badgeColor, size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: Color(AppColors.textDark),
              fontWeight: FontWeight.w800,
              fontSize: 17,
              letterSpacing: 0.2,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing,
          ],
        ],
      ),
    );
  }

  Widget _liveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(AppColors.highRisk),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fade(begin: 0.7, end: 1.0, duration: 900.ms);
  }
}

// ---------------------------------------------------------------------------
// Custom painter — Donut / Ring chart
// ---------------------------------------------------------------------------

class _RingChartPainter extends CustomPainter {
  final List<_ScamCategory> categories;
  final int total;

  _RingChartPainter(this.categories, this.total);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 16.0;
    const gapAngle = 0.04; // radians gap between slices

    double startAngle = -pi / 2;

    for (final cat in categories) {
      final sweep = (cat.count / total) * 2 * pi - gapAngle;
      final paint = Paint()
        ..color = cat.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweep,
        false,
        paint,
      );

      startAngle += sweep + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _RingChartPainter oldDelegate) => false;
}
