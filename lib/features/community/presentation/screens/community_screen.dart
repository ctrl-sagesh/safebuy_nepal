import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../utils/constants.dart' show AppColors;

// ── Data Models ──────────────────────────────────────────────────────────────

class _MonthData {
  final String label;
  final double value;
  const _MonthData(this.label, this.value);
}

class _ScamType {
  final String name;
  final double percent;
  final Color color;
  const _ScamType(this.name, this.percent, this.color);
}

class _TimelineEvent {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String time;
  const _TimelineEvent({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.time,
  });
}

// ── Constants ────────────────────────────────────────────────────────────────

const _monthlyData = [
  _MonthData('Nov', 42),
  _MonthData('Dec', 58),
  _MonthData('Jan', 35),
  _MonthData('Feb', 67),
  _MonthData('Mar', 81),
  _MonthData('Apr', 74),
];

const _scamTypes = [
  _ScamType('No Delivery', 0.35, Color(AppColors.highRisk)),
  _ScamType('Fake Products', 0.28, Color(AppColors.accent)),
  _ScamType('Payment Fraud', 0.20, Color(AppColors.primary)),
  _ScamType('Account Impersonation', 0.12, Color(AppColors.secondary)),
  _ScamType('Other', 0.05, Color(AppColors.textGrey)),
];

const _timelineEvents = [
  _TimelineEvent(
    icon: Icons.verified_outlined,
    color: Color(AppColors.trusted),
    title: 'Report verified by moderator',
    subtitle: 'Seller "QuickDeals_NP" flagged as high risk',
    time: '12 min ago',
  ),
  _TimelineEvent(
    icon: Icons.flag_outlined,
    color: Color(AppColors.highRisk),
    title: 'Seller flagged for review',
    subtitle: '3 new reports against "FashionHub_KTM"',
    time: '1 hr ago',
  ),
  _TimelineEvent(
    icon: Icons.storefront_outlined,
    color: Color(AppColors.primary),
    title: 'New seller registered',
    subtitle: '"TechMart_Pokhara" joined the platform',
    time: '2 hrs ago',
  ),
  _TimelineEvent(
    icon: Icons.shield_outlined,
    color: Color(AppColors.trusted),
    title: 'Seller trust score updated',
    subtitle: '"GadgetZone_NP" promoted to Trusted',
    time: '3 hrs ago',
  ),
  _TimelineEvent(
    icon: Icons.report_outlined,
    color: Color(AppColors.accent),
    title: 'Community report submitted',
    subtitle: 'Payment fraud reported on "DealKing_BRT"',
    time: '5 hrs ago',
  ),
];

// ── Main Screen ──────────────────────────────────────────────────────────────

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(context),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 20),
                _buildHeroCard()
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.15, end: 0),
                const SizedBox(height: 20),
                _buildStatsGrid()
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 150.ms)
                    .slideY(begin: 0.15, end: 0),
                const SizedBox(height: 24),
                _buildSectionTitle('Monthly Trends', Icons.trending_up_rounded)
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 250.ms),
                const SizedBox(height: 12),
                _buildMonthlyChart()
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 300.ms)
                    .slideY(begin: 0.1, end: 0),
                const SizedBox(height: 24),
                _buildSectionTitle(
                        'Top Reported Scam Types', Icons.pie_chart_rounded)
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 400.ms),
                const SizedBox(height: 12),
                _buildScamTypesCard()
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 450.ms)
                    .slideY(begin: 0.1, end: 0),
                const SizedBox(height: 24),
                _buildSectionTitle(
                        'Recent Community Actions', Icons.history_rounded)
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 550.ms),
                const SizedBox(height: 12),
                _buildTimeline()
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 600.ms)
                    .slideY(begin: 0.1, end: 0),
                const SizedBox(height: 24),
                _buildSectionTitle(
                        'Your Contribution', Icons.emoji_events_rounded)
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 700.ms),
                const SizedBox(height: 12),
                _buildContributionCard()
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 750.ms)
                    .slideY(begin: 0.1, end: 0),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────

  SliverAppBar _buildHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      stretch: true,
      backgroundColor: const Color(AppColors.gradStart),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: const Text(
          'Community Impact',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.3,
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
                Color(AppColors.secondary),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -20,
                child: Icon(
                  Icons.shield_rounded,
                  size: 180,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              Positioned(
                right: 50,
                bottom: 20,
                child: Icon(
                  Icons.people_rounded,
                  size: 60,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hero Card ────────────────────────────────────────────────────────────

  Widget _buildHeroCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(AppColors.gradStart),
            Color(AppColors.gradEnd),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(AppColors.primary).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.security_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Scams Prevented',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '156',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.savings_rounded,
                    color: Colors.white70, size: 20),
                const SizedBox(width: 10),
                const Text(
                  'NPR 2,145,800',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'saved',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats Grid ───────────────────────────────────────────────────────────

  Widget _buildStatsGrid() {
    final stats = [
      _StatItem(
        label: 'Reports Filed',
        value: '389',
        icon: Icons.description_outlined,
        color: const Color(AppColors.highRisk),
        trend: '+12%',
      ),
      _StatItem(
        label: 'Sellers Verified',
        value: '1,247',
        icon: Icons.verified_user_outlined,
        color: const Color(AppColors.trusted),
        trend: '+8%',
      ),
      _StatItem(
        label: 'Money Saved',
        value: 'NPR 2.1M',
        icon: Icons.account_balance_wallet_outlined,
        color: const Color(AppColors.accent),
        trend: '+23%',
      ),
      _StatItem(
        label: 'Active Users',
        value: '5,432',
        icon: Icons.people_outline_rounded,
        color: const Color(AppColors.primary),
        trend: '+18%',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.55,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: stat.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(stat.icon, color: stat.color, size: 20),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(AppColors.trusted)
                          .withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      stat.trend,
                      style: const TextStyle(
                        color: Color(AppColors.trusted),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stat.value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(AppColors.textDark),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stat.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(AppColors.textGrey)
                          .withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 500.ms, delay: (200 + index * 100).ms)
            .scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1, 1),
              delay: (200 + index * 100).ms,
              duration: 400.ms,
              curve: Curves.easeOutBack,
            );
      },
    );
  }

  // ── Section Title ────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(AppColors.primary)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(AppColors.textDark),
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  // ── Monthly Chart ────────────────────────────────────────────────────────

  Widget _buildMonthlyChart() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Reports per month',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(AppColors.textGrey),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      const Color(AppColors.primary).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Last 6 months',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: CustomPaint(
              size: const Size(double.infinity, 180),
              painter: _BarChartPainter(data: _monthlyData),
            ),
          ),
        ],
      ),
    );
  }

  // ── Scam Types ───────────────────────────────────────────────────────────

  Widget _buildScamTypesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: List.generate(_scamTypes.length, (index) {
          final scam = _scamTypes[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < _scamTypes.length - 1 ? 16 : 0,
            ),
            child: _buildProgressRow(scam),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: (500 + index * 80).ms)
              .slideX(begin: -0.1, end: 0, delay: (500 + index * 80).ms);
        }),
      ),
    );
  }

  Widget _buildProgressRow(_ScamType scam) {
    final percentage = (scam.percent * 100).toInt();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              scam.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(AppColors.textDark),
              ),
            ),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: scam.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                color: scam.color.withValues(alpha: 0.08),
              ),
              FractionallySizedBox(
                widthFactor: scam.percent,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: LinearGradient(
                      colors: [
                        scam.color,
                        scam.color.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Timeline ─────────────────────────────────────────────────────────────

  Widget _buildTimeline() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: List.generate(_timelineEvents.length, (index) {
          final event = _timelineEvents[index];
          final isLast = index == _timelineEvents.length - 1;
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline indicator
                Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: event.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(event.icon, size: 18, color: event.color),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: const Color(AppColors.divider),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                // Content
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(AppColors.textDark),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          event.subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(AppColors.textGrey),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.time,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(AppColors.textGrey)
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: (650 + index * 100).ms)
              .slideX(begin: 0.08, end: 0, delay: (650 + index * 100).ms);
        }),
      ),
    );
  }

  // ── Contribution Card ────────────────────────────────────────────────────

  Widget _buildContributionCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(AppColors.trusted),
            const Color(AppColors.trusted).withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(AppColors.trusted).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Impact',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Thank you for keeping the community safe!',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildContributionStat(
                  'Reports Filed',
                  '7',
                  Icons.description_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildContributionStat(
                  'Scams Caught',
                  '3',
                  Icons.gpp_good_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildContributionStat(
                  'Helped Users',
                  '12',
                  Icons.people_outline_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                SizedBox(width: 6),
                Text(
                  'Top 15% Contributor',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContributionStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat Item Model ──────────────────────────────────────────────────────────

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
  });
}

// ── Bar Chart CustomPainter ──────────────────────────────────────────────────

class _BarChartPainter extends CustomPainter {
  final List<_MonthData> data;
  const _BarChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = data.map((d) => d.value).reduce(math.max);
    final barCount = data.length;
    final barWidth = (size.width - (barCount + 1) * 14) / barCount;
    final chartHeight = size.height - 30; // space for labels

    // Grid lines
    final gridPaint = Paint()
      ..color = const Color(AppColors.divider)
      ..strokeWidth = 0.8;
    for (var i = 0; i <= 4; i++) {
      final y = chartHeight * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Bar gradient colors
    const barGradients = [
      [Color(0xFF1565C0), Color(0xFF42A5F5)],
      [Color(0xFF0D47A1), Color(0xFF1E88E5)],
      [Color(0xFFFF8F00), Color(0xFFFFCA28)],
      [Color(0xFF2E7D32), Color(0xFF66BB6A)],
      [Color(0xFFC62828), Color(0xFFEF5350)],
      [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
    ];

    for (var i = 0; i < barCount; i++) {
      final x = 14.0 + i * (barWidth + 14);
      final barHeight = (data[i].value / maxVal) * (chartHeight - 10);
      final y = chartHeight - barHeight;

      // Bar with gradient
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(6),
      );
      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: barGradients[i % barGradients.length],
      );
      final barPaint = Paint()
        ..shader = gradient.createShader(
          Rect.fromLTWH(x, y, barWidth, barHeight),
        );
      canvas.drawRRect(rect, barPaint);

      // Soft shadow under bar
      final shadowPaint = Paint()
        ..color = barGradients[i % barGradients.length][0]
            .withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + 2, y + 4, barWidth - 4, barHeight),
          const Radius.circular(6),
        ),
        shadowPaint,
      );

      // Value text above bar
      final valuePainter = TextPainter(
        text: TextSpan(
          text: data[i].value.toInt().toString(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: barGradients[i % barGradients.length][0],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      valuePainter.paint(
        canvas,
        Offset(x + (barWidth - valuePainter.width) / 2, y - 16),
      );

      // Month label
      final labelPainter = TextPainter(
        text: TextSpan(
          text: data[i].label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(AppColors.textGrey),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelPainter.paint(
        canvas,
        Offset(x + (barWidth - labelPainter.width) / 2, chartHeight + 8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
