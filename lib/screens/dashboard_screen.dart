import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/services.dart';
import '../utils/constants.dart';
import '../widgets/trust_badge_widget.dart';
import '../models/seller_model.dart';
import '../services/seed_data_service.dart';
import '../agents/core/agent_registry.dart';
import '../agents/seller_coach/coaching_rules.dart';
import '../agents/seller_coach/milestone_tracker.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // Demo data - replace with real Firestore data in production
  SellerModel get _demoSeller => SellerModel(
        sellerId: 'demo',
        name: 'Your Business',
        phone: '9841234567',
        trustScore: 82,
        trustVerdict: 'trusted',
        isVerified: true,
        verifiedBadge: true,
        totalOrders: 148,
        reviewCount: 43,
        scamReportCount: 1,
        accountCreatedAt: DateTime(2024, 1, 15),
        lastActiveAt: DateTime.now(),
        disputeResponseRate: 0.9,
        averageRating: 4.7,
        trustScoreHistory: const [],
      );

  @override
  Widget build(BuildContext context) {
    final seller = _demoSeller;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(seller),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildTrustCard(seller),
                const SizedBox(height: 16),
                _buildMilestoneProgress(seller),
                const SizedBox(height: 16),
                _buildCoachingCards(seller),
                const SizedBox(height: 16),
                _buildVerificationCard(seller),
                const SizedBox(height: 16),
                _buildShareCard(context, seller),
                const SizedBox(height: 16),
                _buildActivityFeed(),
                if (kDebugMode) ...[
                  const SizedBox(height: 16),
                  _buildSeedButton(context),
                ],
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(SellerModel seller) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: const Color(AppColors.secondary),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(AppColors.primary), Color(AppColors.secondary)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.store, color: Colors.white70, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Business Dashboard',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Welcome back,\n${seller.name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrustCard(SellerModel seller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Trust Score',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TrustScoreCircle(score: seller.trustScore, size: 100),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TrustBadge(trustVerdict: seller.trustVerdict, large: true),
                      const SizedBox(height: 12),
                      _scoreFactor(
                          'Verified Account', seller.isVerified, '+25 pts'),
                      _scoreFactor('4.7 Average Rating', true, '+23 pts'),
                      _scoreFactor(
                          '${seller.scamReportCount} Scam Report',
                          seller.scamReportCount == 0,
                          seller.scamReportCount > 0 ? '-7 pts' : '0 pts'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreFactor(String label, bool positive, String pts) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            positive ? Icons.check_circle : Icons.cancel,
            size: 14,
            color: positive
                ? const Color(AppColors.trusted)
                : const Color(AppColors.highRisk),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis),
          ),
          Text(
            pts,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: positive
                  ? const Color(AppColors.trusted)
                  : const Color(AppColors.highRisk),
            ),
          ),
        ],
      ),
    );
  }

  // ── Milestone Progress (Step 12a) ──────────────────────────────
  Widget _buildMilestoneProgress(SellerModel seller) {
    final coach = AgentRegistry().sellerCoach;
    final progress = coach.getMilestoneProgress(seller.trustScore);
    final current = MilestoneTracker.getCurrentMilestone(seller.trustScore);
    final next = progress.next;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events,
                    color: Color(0xFFF9A825), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Milestone Progress',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (current != null)
              Row(
                children: [
                  Text(current.icon, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    current.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(AppColors.trusted),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            if (next != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Next: ${next.icon} ${next.label}',
                    style: const TextStyle(
                        fontSize: 12, color: Color(AppColors.textGrey)),
                  ),
                  Text(
                    '${(progress.progress * 100).toInt()}%',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(AppColors.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress.progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(AppColors.primary)),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Score ${seller.trustScore.toInt()} → need ${next.score.toInt()}',
                style: const TextStyle(
                    fontSize: 11, color: Color(AppColors.textGrey)),
              ),
            ] else
              const Text(
                '🎉 All milestones achieved! You are a SafeBuy Champion!',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(AppColors.trusted),
                ),
              ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              children: progress.achieved.map((m) {
                return Chip(
                  avatar: Text(m.icon, style: const TextStyle(fontSize: 12)),
                  label: Text(m.label,
                      style: const TextStyle(fontSize: 10)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  backgroundColor:
                      const Color(AppColors.trusted).withValues(alpha: 0.1),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Coaching Cards (Step 12b) ─────────────────────────────────
  Widget _buildCoachingCards(SellerModel seller) {
    final coach = AgentRegistry().sellerCoach;
    final cards = coach.getCoachingCards(seller, maxCards: 3);

    if (cards.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.lightbulb, color: Color(0xFFF9A825), size: 20),
            SizedBox(width: 8),
            Text(
              'AI Coach Recommendations',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Personalized tips to improve your trust score',
          style: TextStyle(fontSize: 12, color: Color(AppColors.textGrey)),
        ),
        const SizedBox(height: 12),
        ...cards.map((card) => _coachingCardTile(card)),
      ],
    );
  }

  Widget _coachingCardTile(CoachingCard card) {
    final color = _hexToColor(card.cardColor);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(card.icon, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  card.description,
                  style: const TextStyle(
                      fontSize: 11, color: Color(AppColors.textGrey)),
                ),
                if (card.potentialScoreIncrease > 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(AppColors.trusted)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '+${card.potentialScoreIncrease.toInt()} pts possible',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(AppColors.trusted),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  Widget _buildVerificationCard(SellerModel seller) {
    final steps = [
      ('Phone number verified', true),
      ('Profile photo added', true),
      ('Business description added', false),
      ('First 10 orders completed', true),
      ('No scam reports in 90 days', seller.scamReportCount == 0),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Verification Steps',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const Spacer(),
                if (seller.isVerified)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(AppColors.trusted).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Verified',
                        style: TextStyle(
                            color: Color(AppColors.trusted),
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            ...steps.map((s) => _verificationStep(s.$1, s.$2)),
          ],
        ),
      ),
    );
  }

  Widget _verificationStep(String label, bool done) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: done
                ? const Color(AppColors.trusted)
                : Colors.grey.shade400,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: done
                  ? const Color(AppColors.textDark)
                  : const Color(AppColors.textGrey),
              decoration: done ? TextDecoration.none : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareCard(BuildContext context, SellerModel seller) {
    final profileLink = 'safebuy.np/seller/${seller.sellerId}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Share Your Profile',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Share your SafeBuy profile with buyers so they can verify your trust score before ordering.',
              style:
                  TextStyle(fontSize: 13, color: Color(AppColors.textGrey)),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(AppColors.background),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(AppColors.divider)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link,
                      size: 16, color: Color(AppColors.primary)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      profileLink,
                      style: const TextStyle(
                          fontSize: 13, color: Color(AppColors.primary)),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: profileLink));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profile link copied!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: const Icon(Icons.copy,
                        size: 18, color: Color(AppColors.primary)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityFeed() {
    final activities = [
      (Icons.star, 'New 5-star review received', '2 hours ago', Colors.amber),
      (Icons.person_add, 'New buyer searched your profile', '5 hours ago',
          const Color(AppColors.secondary)),
      (Icons.verified, 'Account verification renewed', '2 days ago',
          const Color(AppColors.trusted)),
      (Icons.report, '1 dispute report submitted', '5 days ago',
          const Color(AppColors.highRisk)),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 14),
            ...activities.map((a) => _activityItem(
                  icon: a.$1,
                  label: a.$2,
                  time: a.$3,
                  color: a.$4,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSeedButton(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.science, color: Color(AppColors.accent), size: 18),
                SizedBox(width: 8),
                Text(
                  'Developer Tools',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Seed demo data for thesis presentation.',
              style: TextStyle(fontSize: 12, color: Color(AppColors.textGrey)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.upload, size: 16),
                label: const Text('Seed Demo Data'),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.showSnackBar(const SnackBar(
                      content: Text('Seeding... please wait')));
                  final result = await SeedDataService.seedDatabase();
                  messenger.showSnackBar(SnackBar(content: Text(result)));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activityItem({
    required IconData icon,
    required String label,
    required String time,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                Text(time,
                    style: const TextStyle(
                        fontSize: 11, color: Color(AppColors.textGrey))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
