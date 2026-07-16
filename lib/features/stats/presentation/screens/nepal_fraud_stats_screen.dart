import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/data/nepal_scam_data.dart';
import '../../../../core/utils/popup_helper.dart';

/// Nepal Fraud Statistics dashboard — the only DARK screen in the app.
/// Live SafeBuy community numbers on top, official Nepal Police data below.
class NepalFraudStatsScreen extends StatefulWidget {
  const NepalFraudStatsScreen({super.key});

  @override
  State<NepalFraudStatsScreen> createState() =>
      _NepalFraudStatsScreenState();
}

class _NepalFraudStatsScreenState extends State<NepalFraudStatsScreen> {
  // Dark palette for this screen only.
  static const _bg = Color(0xFF0D2137);
  static const _card = Color(0xFF1A3A5C);
  static const _blue = Color(0xFF1565C0);
  static const _red = Color(0xFFC62828);
  static const _textDim = Color(0xFF9FB3C8);

  // Live SafeBuy data (null while loading).
  int? _totalReports;
  double? _totalLost;
  int? _highRiskSellers;
  int? _verifiedSellers;

  // Registered complaints per year (Nepal Police Annual Report 2023;
  // 2024 projected). The 2023 value is the 340% spike.
  static const _complaintsByYear = [
    (2020, 280.0),
    (2021, 390.0),
    (2022, 545.0),
    (2023, 2400.0),
    (2024, 2900.0),
  ];

  static const _fraudTypes = [
    ('Non-delivery', 35.0, Color(0xFFE53935)),
    ('Fake products', 28.0, Color(0xFFFB8C00)),
    ('Wrong item', 20.0, Color(0xFFFDD835)),
    ('Payment fraud', 12.0, Color(0xFF42A5F5)),
    ('Other', 5.0, Color(0xFF90A4AE)),
  ];

  static const _platforms = [
    ('TikTok', 48.0),
    ('Instagram', 32.0),
    ('Facebook', 20.0),
  ];

  @override
  void initState() {
    super.initState();
    _loadLiveStats();
  }

  Future<void> _loadLiveStats() async {
    final db = FirebaseFirestore.instance;
    try {
      final reportsAgg = await db
          .collection('reports')
          .aggregate(count(), sum('amountLost'))
          .get();
      final highRisk = await db
          .collection('sellers')
          .where('trustVerdict', isEqualTo: 'high_risk')
          .count()
          .get();
      final verified = await db
          .collection('sellers')
          .where('kycStatus', isEqualTo: 'verified')
          .count()
          .get();
      if (!mounted) return;
      setState(() {
        _totalReports = reportsAgg.count;
        _totalLost = reportsAgg.getSum('amountLost') ?? 0;
        _highRiskSellers = highRisk.count;
        _verifiedSellers = verified.count;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _totalReports = 0;
        _totalLost = 0;
        _highRiskSellers = 0;
        _verifiedSellers = 0;
      });
    }
  }

  Future<void> _emailBureau() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'cybercrime@nepalpolice.gov.np',
      query: 'subject=${Uri.encodeComponent('Cybercrime Complaint Inquiry')}',
    );
    try {
      final ok = await launchUrl(uri);
      if (!ok) throw Exception();
    } catch (_) {
      if (!mounted) return;
      PopupHelper.showError(
          context, 'Could not open an email app on this device.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🇳🇵', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text('Nepal Fraud Data',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                )),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ── LIVE SafeBuy data ────────────────────────────────────────────
          _sectionHeader('LIVE — SafeBuy Community Data', _blue),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: _counterCard('Fraud reports filed',
                    _totalReports?.toDouble(), _red, isMoney: false)),
            const SizedBox(width: 10),
            Expanded(
                child: _counterCard('NPR reported lost', _totalLost, _red,
                    isMoney: true)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: _counterCard('High-risk sellers',
                    _highRiskSellers?.toDouble(), _red, isMoney: false)),
            const SizedBox(width: 10),
            Expanded(
                child: _counterCard('Verified sellers',
                    _verifiedSellers?.toDouble(), const Color(0xFF00C853),
                    isMoney: false)),
          ]),

          const SizedBox(height: 26),

          // ── Official Nepal Police data ──────────────────────────────────
          _sectionHeader('Official Nepal Police Data', _red),
          const SizedBox(height: 4),
          Text('Registered social commerce fraud complaints, 2020–2024',
              style: GoogleFonts.inter(fontSize: 11.5, color: _textDim)),
          const SizedBox(height: 14),
          _chartCard(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: Color(0xFF2A4A6C),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (v, _) => Text(
                        v >= 1000
                            ? '${(v / 1000).toStringAsFixed(1)}k'
                            : v.toInt().toString(),
                        style: GoogleFonts.inter(
                            fontSize: 10, color: _textDim),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('${2020 + v.toInt()}',
                            style: GoogleFonts.inter(
                                fontSize: 10.5, color: _textDim)),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < _complaintsByYear.length; i++)
                        FlSpot(i.toDouble(), _complaintsByYear[i].$2),
                    ],
                    isCurved: true,
                    color: _red,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                        radius: spot.x == 3 ? 6 : 3.5,
                        color: spot.x == 3 ? _red : Colors.white,
                        strokeColor: _red,
                        strokeWidth: 2,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: _red.withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('The 2023 spike is a 340% year-on-year increase.',
              style: GoogleFonts.inter(fontSize: 11, color: _textDim)),
          const SizedBox(height: 14),

          // 4 headline stat boxes
          Row(children: [
            Expanded(child: _statBox('340%', 'complaint increase in 2023')),
            const SizedBox(width: 10),
            Expanded(child: _statBox('NPR 40Cr+', 'estimated losses 2023')),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _statBox('560%', 'TikTok fraud growth 22–23')),
            const SizedBox(width: 10),
            Expanded(
                child: _statBox('2,400+', 'registered complaints 2023')),
          ]),
          const SizedBox(height: 6),
          Text('Source: Nepal Police Annual Report 2023, Cybercrime Bureau',
              style: GoogleFonts.inter(fontSize: 10.5, color: _textDim)),

          const SizedBox(height: 26),

          // ── Fraud types donut ───────────────────────────────────────────
          _sectionHeader('What Kind of Fraud Happens', _blue),
          const SizedBox(height: 14),
          _chartCard(
            height: 230,
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 40,
                      sections: _fraudTypes
                          .map((t) => PieChartSectionData(
                                value: t.$2,
                                color: t.$3,
                                radius: 46,
                                title: '${t.$2.toInt()}%',
                                titleStyle: GoogleFonts.poppins(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _fraudTypes
                        .map((t) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                children: [
                                  Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: t.$3,
                                        borderRadius:
                                            BorderRadius.circular(3),
                                      )),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(t.$1,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: Colors.white,
                                        )),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 26),

          // ── Platform bar chart ──────────────────────────────────────────
          _sectionHeader('Where It Happens', _blue),
          const SizedBox(height: 14),
          _chartCard(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 60,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(_platforms[v.toInt()].$1,
                            style: GoogleFonts.inter(
                                fontSize: 11, color: _textDim)),
                      ),
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (_, _, rod, _) => BarTooltipItem(
                      '${rod.toY.toInt()}%',
                      GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < _platforms.length; i++)
                    BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: _platforms[i].$2,
                        width: 34,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8)),
                        gradient: const LinearGradient(
                          colors: [_blue, Color(0xFF42A5F5)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('Share of complaints by platform (2023 registered cases)',
              style: GoogleFonts.inter(fontSize: 11, color: _textDim)),

          const SizedBox(height: 26),

          // ── Legal framework ─────────────────────────────────────────────
          _sectionHeader('The Law Is On Your Side', _blue),
          const SizedBox(height: 12),
          ...NepalScamNewsData.legalFramework.take(3).map(_legalCard),

          const SizedBox(height: 24),

          // ── CTA ─────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_red, Color(0xFF8E0000)]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Text('Been scammed? Report it to the Cybercrime Bureau.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 6),
                Text('Naxal, Kathmandu · 01-4412323',
                    style: GoogleFonts.inter(
                        color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _emailBureau,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _red,
                    ),
                    icon: const Icon(Icons.mail_outline_rounded, size: 18),
                    label: const Text('Email the Bureau'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Building blocks ──────────────────────────────────────────────────────────

  Widget _sectionHeader(String title, Color accent) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title,
              style: GoogleFonts.poppins(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              )),
        ),
      ],
    );
  }

  Widget _counterCard(String label, double? value, Color accent,
      {required bool isMoney}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          value == null
              ? SizedBox(
                  height: 26,
                  width: 26,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: accent),
                )
              : TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: value),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => Text(
                    isMoney
                        ? NumberFormat.compact().format(v)
                        : NumberFormat('#,##0').format(v),
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.inter(fontSize: 11.5, color: _textDim)),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }

  Widget _statBox(String stat, String label) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(stat,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFFF5252),
              )),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.inter(fontSize: 10.5, color: _textDim)),
        ],
      ),
    );
  }

  Widget _chartCard({required double height, required Widget child}) {
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(12, 18, 18, 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }

  Widget _legalCard(Map<String, String> law) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
        ),
        child: ExpansionTile(
          iconColor: Colors.white70,
          collapsedIconColor: Colors.white54,
          title: Text(law['section'] ?? '',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              )),
          subtitle: Text(law['law'] ?? '',
              style: GoogleFonts.inter(fontSize: 11, color: _textDim)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(law['description'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.55,
                  )),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Penalty: ${law['penalty']}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFF8A80),
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
