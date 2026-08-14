import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/language_toggle.dart';
import '../../../../providers/language_provider.dart';

/// Alerts tab — scam news entry card + live community alerts +
/// trending scam types.
class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  List<Map<String, dynamic>>? _alerts;
  bool _failed = false;

  /// Current UI language ('en' | 'ne'); refreshed at the top of build().
  String _lang = 'en';
  String _t(String en, String ne) => _lang == 'ne' ? ne : en;

  /// (emoji, English title, Nepali title, share of reports, color).
  static const _trendingTypes = [
    ('📦', 'Non-Delivery', 'सामान नआउने', 35, AppColors.highRisk),
    ('🏷️', 'Fake Products', 'नक्कली सामान', 28, Color(0xFFFF6D00)),
    ('💳', 'Payment Fraud', 'भुक्तानी ठगी', 20, AppColors.unverified),
    ('🎭', 'Account Cloning', 'खाता नक्कल', 12, Color(0xFF7C5CFC)),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('community_alerts')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();
      if (mounted) {
        setState(() {
          _alerts = snap.docs.map((d) => d.data()).toList();
          _failed = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _alerts = [];
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _lang = ref.watch(languageProvider);
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
        title: Text(_t('Safety Alerts', 'सुरक्षा सतर्कता')),
        automaticallyImplyLeading: false,
        actions: [
          const LanguageToggle(),
          TextButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, '/nepal-stats');
            },
            icon: const Icon(Icons.bar_chart_rounded, size: 18),
            label: Text(_t('Nepal Fraud Data', 'नेपाल ठगी तथ्यांक'),
                style: const TextStyle(fontSize: 12.5)),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _t('Active fraud warnings from the SafeBuy Nepal community',
                    'SafeBuy Nepal समुदायबाट सक्रिय ठगी चेतावनी'),
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            // Scam news entry card
            InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.pushNamed(context, '/scam-news');
              },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: AppColors.riskGradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Text('📰', style: TextStyle(fontSize: 30)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_t('Scam Reports Nepal', 'ठगी रिपोर्ट नेपाल'),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                              )),
                          Text(
                            _t(
                                '10 documented fraud cases, official statistics, '
                                    'and your legal rights',
                                '१० प्रलेखित ठगी घटना, आधिकारिक तथ्यांक, '
                                    'र तपाईंका कानुनी अधिकार'),
                            style: GoogleFonts.inter(
                              color:
                                  Colors.white.withValues(alpha: 0.9),
                              fontSize: 11.5,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: Colors.white, size: 26),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05),
            const SizedBox(height: 18),

            // Trending scam types (consolidated from home)
            Text(_t('Trending Scam Types', 'बढ्दो ठगीका प्रकार'),
                style: GoogleFonts.poppins(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                )),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.1,
              children: _trendingTypes.asMap().entries.map((e) {
                final (emoji, titleEn, titleNe, pct, color) = e.value;
                final title = _t(titleEn, titleNe);
                final sub = _t('$pct% of reports', 'उजुरीको $pct%');
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                )),
                            Text(sub,
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: (e.key * 60).ms).fadeIn().slideY(
                      begin: 0.08,
                    );
              }).toList(),
            ),
            const SizedBox(height: 20),

            Text(_t('Community Alerts', 'सामुदायिक सतर्कता'),
                style: GoogleFonts.poppins(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                )),
            const SizedBox(height: 10),

            if (_alerts == null)
              ...List.generate(
                3,
                (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Shimmer.fromColors(
                    baseColor: AppColors.shimmerBase,
                    highlightColor: AppColors.shimmerHighlight,
                    child: Container(
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              )
            else if (_alerts!.isEmpty)
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: _failed ? Colors.white : AppColors.trustedBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: _failed
                          ? AppColors.borderLight
                          : AppColors.trusted.withValues(alpha: 0.35)),
                ),
                alignment: Alignment.center,
                child: Text(
                  _failed
                      ? _t(
                          'Could not load alerts. Check your connection '
                              'and pull down to retry.',
                          'सतर्कता लोड गर्न सकिएन। इन्टरनेट जाँची तल '
                              'तान्नुहोस्।')
                      : _t(
                          'No active alerts right now. Nepal\'s social '
                              'commerce community is safe today.',
                          'अहिले कुनै सक्रिय सतर्कता छैन। नेपालको सोशल '
                              'कमर्स समुदाय आज सुरक्षित छ।'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: _failed
                        ? AppColors.textSecondary
                        : AppColors.success,
                    fontWeight:
                        _failed ? FontWeight.w400 : FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              )
            else
              ..._alerts!.asMap().entries.map((entry) {
                final a = entry.value;
                final ts = a['createdAt'];
                final when = ts is Timestamp
                    ? DateFormat('dd MMM').format(ts.toDate())
                    : '';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
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
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    a['title'] as String? ??
                                        _t('Community alert',
                                            'सामुदायिक सतर्कता'),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Text(when,
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      color: AppColors.textMuted,
                                    )),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              (a['body'] ?? a['description'] ?? '')
                                  as String,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: (entry.key * 40).ms).fadeIn();
              }),
          ],
        ),
      ),
    );
  }
}
