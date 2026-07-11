import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/popup_helper.dart';
import '../../../../core/widgets/verification_card.dart';
import '../../../../models/leaderboard_model.dart';
import '../../../../services/leaderboard_service.dart';

/// Monthly top-seller leaderboard with podium.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<LeaderboardEntryModel>? _entries;
  int _filter = 0; // 0 this month, 1 last month, 2 all time
  bool _infoExpanded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _entries = null);
    try {
      String? month;
      if (_filter == 1) {
        final now = DateTime.now();
        month =
            LeaderboardService.monthKey(DateTime(now.year, now.month - 1));
      } else if (_filter == 2) {
        month = 'all-time';
      }
      final list =
          await LeaderboardService().getLeaderboard(month: month);
      if (mounted) setState(() => _entries = list);
    } catch (_) {
      if (mounted) {
        setState(() => _entries = const []);
        PopupHelper.showError(context, 'Could not load leaderboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries;
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(title: const Text('Monthly Leaderboard')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          // Gradient header
          Container(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text('🏆 Top Verified Sellers',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    )),
                Text(
                  'Ranked by trust score, ratings, and reviews',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Filter tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(3, (i) {
                final labels = ['This Month', 'Last Month', 'All Time'];
                final selected = _filter == i;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _filter = i);
                        _load();
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding:
                            const EdgeInsets.symmetric(vertical: 9),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.borderLight,
                          ),
                        ),
                        child: Text(labels[i],
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            )),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),

          if (entries == null)
            const Padding(
              padding: EdgeInsets.all(50),
              child: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary)),
            )
          else if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  const Icon(Icons.emoji_events_outlined,
                      size: 56, color: AppColors.grey400),
                  const SizedBox(height: 10),
                  Text('No rankings available yet for this period',
                      style: GoogleFonts.inter(
                          fontSize: 13.5,
                          color: AppColors.textSecondary)),
                ],
              ),
            )
          else ...[
            // Podium (top 3)
            if (entries.isNotEmpty)
              SizedBox(
                height: 205,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (entries.length > 1)
                      _podium(entries[1], 2, 120, const Color(0xFFB0BEC5),
                          delayMs: 250),
                    if (entries.isNotEmpty)
                      _podium(entries[0], 1, 150, const Color(0xFFD4AF37),
                          delayMs: 0, crown: true),
                    if (entries.length > 2)
                      _podium(entries[2], 3, 100, const Color(0xFFCD7F32),
                          delayMs: 450),
                  ],
                ),
              ),
            const SizedBox(height: 10),

            // Positions 4+
            ...entries.skip(3).toList().asMap().entries.map((e) {
              final entry = e.value;
              final even = e.key % 2 == 0;
              return InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pushNamed(context, '/seller',
                      arguments: {'sellerId': entry.sellerId});
                },
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: even ? Colors.white : AppColors.grey50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 30,
                        child: Text('#${entry.rank}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                            )),
                      ),
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: AppColors.primary50,
                        child: Text(
                          entry.displayName.isNotEmpty
                              ? entry.displayName[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.poppins(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(entry.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                )),
                            Text(
                              '${TierStyle.label(entry.verificationTier)} · ⭐ ${entry.averageRating.toStringAsFixed(1)} · ${entry.reviewCount} reviews',
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(entry.trustScore.round().toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.trustScoreColor(
                                entry.trustScore),
                          )),
                    ],
                  ),
                ),
              ).animate(delay: (e.key * 40).ms).fadeIn().slideX(
                    begin: 0.05,
                  );
            }),
          ],

          // Ranking info
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: InkWell(
              onTap: () =>
                  setState(() => _infoExpanded = !_infoExpanded),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('How rankings are calculated',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary900,
                              )),
                        ),
                        Icon(
                          _infoExpanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                    if (_infoExpanded) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Rank = trust score (50%) + average rating (30%) '
                        '+ review volume (20%). Only sellers with no '
                        'pending fraud reports are eligible. Rankings '
                        'refresh monthly.',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: AppColors.textPrimary,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _podium(LeaderboardEntryModel e, int place, double height,
      Color color,
      {required int delayMs, bool crown = false}) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/seller',
          arguments: {'sellerId': e.sellerId}),
      child: Container(
        width: 105,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (crown)
              const Text('👑', style: TextStyle(fontSize: 22))
                  .animate(
                      onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 0.92, end: 1.08, duration: 900.ms),
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withValues(alpha: 0.2),
              child: Text(
                e.displayName.isNotEmpty
                    ? e.displayName[0].toUpperCase()
                    : '?',
                style: GoogleFonts.poppins(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(e.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                )),
            Text('⭐ ${e.averageRating.toStringAsFixed(1)}',
                style: GoogleFonts.inter(
                    fontSize: 10, color: AppColors.textMuted)),
            const SizedBox(height: 5),
            Container(
              height: height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.6)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12)),
              ),
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                place == 1
                    ? '🥇'
                    : place == 2
                        ? '🥈'
                        : '🥉',
                style: const TextStyle(fontSize: 26),
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: delayMs.ms)
        .fadeIn(duration: 350.ms)
        .slideY(begin: -0.2, curve: Curves.easeOutCubic);
  }
}
