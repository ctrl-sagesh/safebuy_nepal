import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/data/nepal_scam_data.dart';
import '../../../../core/theme/app_colors.dart';

/// Documented social-commerce fraud cases, statistics, and buyer rights.
class ScamNewsScreen extends StatelessWidget {
  const ScamNewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Scam Reports Nepal'),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            labelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w700, fontSize: 12.5),
            tabs: const [
              Tab(text: 'Cases'),
              Tab(text: 'Statistics'),
              Tab(text: 'Your Rights'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_CasesTab(), _StatsTab(), _RightsTab()],
        ),
      ),
    );
  }
}

// ── Header card shared by tabs ─────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🔴 Social Commerce Fraud in Nepal',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 4),
          Text(
            'Documented cases and official statistics. Data from '
            'Nepal Police and government sources',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cases tab ──────────────────────────────────────────────────────────────────

class _CasesTab extends StatefulWidget {
  const _CasesTab();

  @override
  State<_CasesTab> createState() => _CasesTabState();
}

class _CasesTabState extends State<_CasesTab> {
  String _filter = 'All';

  static const _filters = [
    'All',
    'TikTok',
    'Instagram',
    'Facebook',
    'Statistics'
  ];

  @override
  Widget build(BuildContext context) {
    final cases = NepalScamNewsData.scamCases.where((c) {
      if (_filter == 'All') return true;
      if (_filter == 'Statistics') {
        return c['category'] == 'Statistics' ||
            c['category'] == 'Regulatory';
      }
      return c['platform'] == _filter;
    }).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 30),
      children: [
        const _HeaderCard(),

        // Top stats row
        SizedBox(
          height: 82,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            itemCount: 4,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final s = NepalScamNewsData.scamStats[i];
              return Container(
                width: 150,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.highRiskBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s['stat']!,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.highRisk,
                        )),
                    Expanded(
                      child: Text(s['label']!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          )),
                    ),
                  ],
                ),
              ).animate(delay: (i * 80).ms).fadeIn().slideX(begin: 0.1);
            },
          ),
        ),
        const SizedBox(height: 12),

        // Filter chips
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final f = _filters[i];
              final selected = _filter == f;
              return InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _filter = f);
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color:
                        selected ? AppColors.primary : AppColors.grey100,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(f,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? Colors.white
                            : AppColors.textSecondary,
                      )),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),

        ...cases.asMap().entries.map((e) =>
            _CaseCard(data: e.value)
                .animate(delay: (e.key * 60).ms)
                .fadeIn()
                .slideY(begin: 0.04)),
      ],
    );
  }
}

class _CaseCard extends StatefulWidget {
  const _CaseCard({required this.data});

  final Map<String, String> data;

  @override
  State<_CaseCard> createState() => _CaseCardState();
}

class _CaseCardState extends State<_CaseCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final hasAmount = d['amountLost'] != 'N/A';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _chip(d['category']!, AppColors.highRisk),
              const SizedBox(width: 6),
              _chip(d['platform']!, AppColors.primary),
            ],
          ),
          const SizedBox(height: 8),
          Text(d['headline']!,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.35,
              )),
          const SizedBox(height: 6),
          Text('${d['date']} · ${d['district']}',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: AppColors.textMuted,
              )),
          const SizedBox(height: 6),
          Row(
            children: [
              if (hasAmount)
                Text('Amount Lost: ${d['amountLost']}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.highRisk,
                    )),
              if (hasAmount) const SizedBox(width: 12),
              if (d['victims'] != 'N/A')
                Text('Victims: ${d['victims']}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warning,
                    )),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Text(
              d['body']!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            secondChild: Text(
              d['body']!,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32)),
            child: Text(_expanded ? 'Show Less' : 'Read More'),
          ),
          Text('Source: ${d['source']}',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontStyle: FontStyle.italic,
                color: AppColors.textMuted,
              )),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('💡 Lesson: ${d['lesson']}',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: AppColors.primary900,
                  height: 1.5,
                )),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
          )),
    );
  }
}

// ── Statistics tab ─────────────────────────────────────────────────────────────

class _StatsTab extends StatelessWidget {
  const _StatsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 30),
      children: [
        const _HeaderCard(),
        const SizedBox(height: 8),

        ...NepalScamNewsData.scamStats.asMap().entries.map((e) {
          final s = e.value;
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AppColors.highRisk, Color(0xFFFF6D00)],
                  ).createShader(bounds),
                  child: Text(s['stat']!,
                      style: GoogleFonts.poppins(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      )),
                ),
                const SizedBox(height: 4),
                Text(s['label']!,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    )),
                const SizedBox(height: 3),
                Text('Source: ${s['source']}',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textMuted,
                    )),
              ],
            ),
          ).animate(delay: (e.key * 80).ms).fadeIn().slideY(begin: 0.05);
        }),

        // Trend chart
        Container(
          margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Fraud complaint growth (indexed)',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => const FlLine(
                        color: AppColors.borderLight,
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                      leftTitles: const AxisTitles(),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (v, _) => Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '${2020 + v.toInt()}',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: const [
                          FlSpot(0, 1),
                          FlSpot(1, 1.4),
                          FlSpot(2, 2.2),
                          FlSpot(3, 7.5),
                        ],
                        isCurved: true,
                        color: AppColors.highRisk,
                        barWidth: 3.5,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.highRisk
                              .withValues(alpha: 0.08),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Over 20,000 cybercrime complaints registered last fiscal year. '
                'SafeBuy Nepal launched in response.',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Your Rights tab ────────────────────────────────────────────────────────────

class _RightsTab extends StatelessWidget {
  const _RightsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 30),
      children: [
        const _HeaderCard(),
        const SizedBox(height: 8),

        ...NepalScamNewsData.legalFramework.map((l) => Container(
              margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l['law']!,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      )),
                  Text(l['section']!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      )),
                  const SizedBox(height: 6),
                  Text(l['description']!,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.55,
                      )),
                  if (l['penalty'] != 'N/A') ...[
                    const SizedBox(height: 6),
                    Text('Penalty: ${l['penalty']}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.highRisk,
                        )),
                  ],
                ],
              ),
            )),

        // How to file a complaint
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📝 How to File a Complaint',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary900,
                  )),
              const SizedBox(height: 8),
              _step('1',
                  'Collect evidence: payment proof and chat screenshots'),
              _step('2', 'Submit a report on SafeBuy Nepal'),
              _step(
                  '3',
                  'Visit Nepal Police Cybercrime Bureau, Kathmandu: '
                  'Naxal, Phone: 01-4412323'),
              _step('4',
                  'File a complaint under ETA 2063 Section 47/48'),
            ],
          ),
        ),

        // Rights summary
        Container(
          margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('⚖️ Your Rights as a Buyer',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(height: 8),
              _right(
                  'Right to compensation under the Consumer Protection Act'),
              _right('Right to truthful advertising'),
              _right('Right to file a complaint with DoCSCP'),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _step(String n, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(n,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                )),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: AppColors.textPrimary,
                  height: 1.5,
                )),
          ),
        ],
      ),
    );
  }

  static Widget _right(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded,
              size: 16, color: AppColors.trusted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: AppColors.textPrimary,
                  height: 1.5,
                )),
          ),
        ],
      ),
    );
  }
}
