import '../../models/seller_model.dart';

/// A single coaching card shown to the seller.
class CoachingCard {
  const CoachingCard({
    required this.id,
    required this.title,
    required this.titleNe,
    required this.description,
    required this.descriptionNe,
    required this.actionLabel,
    required this.actionLabelNe,
    this.actionRoute,
    required this.potentialScoreIncrease,
    required this.icon,
    required this.cardColor,
  });

  final String id;
  final String title;
  final String titleNe;
  final String description;
  final String descriptionNe;
  final String actionLabel;
  final String actionLabelNe;
  final String? actionRoute;
  final double potentialScoreIncrease;
  final String icon;
  final String cardColor; // hex color for accent
}

/// A coaching rule with an evaluation condition.
class CoachingRule {
  const CoachingRule({
    required this.id,
    required this.priorityOrder,
    required this.card,
    required this.evaluate,
  });

  final String id;
  final int priorityOrder;
  final CoachingCard card;

  /// Returns true if this rule applies to the given seller.
  final bool Function(SellerModel seller) evaluate;
}

/// All coaching rules for seller improvement.
class CoachingRules {
  CoachingRules._();

  /// All rules sorted by priority (evaluated at runtime).
  static final List<CoachingRule> all = [
    // Rule 7: Trusted milestone (priority 0 - celebration)
    trustedMilestone,
    // Rule 1: Phone not verified (priority 1)
    phoneNotVerified,
    // Rule 3: Unanswered reports (priority 1 when applicable)
    unansweredReports,
    // Rule 6: Score dropped (priority 1 when detected)
    scoreDropped,
    // Rule 2: No social media linked (priority 2)
    noSocialMedia,
    // Rule 4: Low review count (priority 3)
    lowReviewCount,
    // Rule 5: New account (priority 4)
    newAccount,
  ];

  // ── Rule 1: Phone Not Verified ───────────────────────────────────

  static final phoneNotVerified = CoachingRule(
    id: 'phone_not_verified',
    priorityOrder: 1,
    card: const CoachingCard(
      id: 'phone_not_verified',
      title: 'Verify Your Phone Number',
      titleNe: 'आफ्नो फोन नम्बर verify गर्नुस्',
      description: 'Verifying your phone adds up to +15 points to your '
          'trust score and shows buyers you are a real, accountable seller.',
      descriptionNe: 'फोन verify गर्दा +15 points सम्म बढ्छ र '
          'खरिदकर्ताहरूलाई तपाईं वास्तविक seller हुनुहुन्छ भनी देखाउँछ।',
      actionLabel: 'Verify Phone',
      actionLabelNe: 'फोन verify गर्नुस्',
      actionRoute: '/verify-phone',
      potentialScoreIncrease: 15,
      icon: '📱',
      cardColor: '#1565C0',
    ),
    evaluate: (seller) => !seller.isVerified,
  );

  // ── Rule 2: No Social Media Linked ───────────────────────────────

  static final noSocialMedia = CoachingRule(
    id: 'no_social_media',
    priorityOrder: 2,
    card: const CoachingCard(
      id: 'no_social_media',
      title: 'Link Your Social Media',
      titleNe: 'Social Media जोड्नुस्',
      description: 'Linking your TikTok or Instagram adds +10 points '
          'and proves your online presence is real and consistent.',
      descriptionNe: 'TikTok वा Instagram जोड्दा +10 points बढ्छ '
          'र तपाईंको online presence वास्तविक छ भनी प्रमाणित हुन्छ।',
      actionLabel: 'Link Accounts',
      actionLabelNe: 'Account जोड्नुस्',
      actionRoute: '/edit-business',
      potentialScoreIncrease: 10,
      icon: '📲',
      cardColor: '#7B1FA2',
    ),
    evaluate: (seller) =>
        seller.isVerified &&
        (seller.tiktokHandle?.isEmpty ?? true) &&
        (seller.instagramHandle?.isEmpty ?? true),
  );

  // ── Rule 3: Unanswered Reports ───────────────────────────────────

  static final unansweredReports = CoachingRule(
    id: 'unanswered_reports',
    priorityOrder: 1,
    card: const CoachingCard(
      id: 'unanswered_reports',
      title: 'Respond to Reports Against You',
      titleNe: 'तपाईंविरुद्धका रिपोर्टको जवाफ दिनुस्',
      description: 'You have unanswered report(s). Responding '
          'within 48 hours can add up to +10 points and shows buyers '
          'you take concerns seriously.',
      descriptionNe: 'तपाईंका अनुत्तरित रिपोर्ट छन्। ४८ घण्टामा '
          'जवाफ दिँदा +10 points सम्म बढ्न सक्छ।',
      actionLabel: 'View Disputes',
      actionLabelNe: 'Disputes हेर्नुस्',
      actionRoute: '/dashboard/disputes',
      potentialScoreIncrease: 10,
      icon: '💬',
      cardColor: '#C62828',
    ),
    evaluate: (seller) =>
        seller.scamReportCount > 0 && seller.disputeResponseRate < 0.5,
  );

  // ── Rule 4: Low Review Count ─────────────────────────────────────

  static final lowReviewCount = CoachingRule(
    id: 'low_review_count',
    priorityOrder: 3,
    card: const CoachingCard(
      id: 'low_review_count',
      title: 'Get Your First Reviews',
      titleNe: 'पहिलो Review पाउनुस्',
      description: 'Sellers with 5+ verified reviews score significantly '
          'higher. Share your SafeBuy profile link with happy customers '
          'and ask them to leave a review.',
      descriptionNe: '5+ verified review भएका seller को score धेरै बढी हुन्छ। '
          'सन्तुष्ट customer लाई review दिन भन्नुस्।',
      actionLabel: 'Share Profile',
      actionLabelNe: 'Profile share गर्नुस्',
      actionRoute: '/share-profile',
      potentialScoreIncrease: 8,
      icon: '⭐',
      cardColor: '#F57F17',
    ),
    evaluate: (seller) => seller.reviewCount < 5,
  );

  // ── Rule 5: New Account ──────────────────────────────────────────

  static final newAccount = CoachingRule(
    id: 'new_account',
    priorityOrder: 4,
    card: const CoachingCard(
      id: 'new_account',
      title: 'Build Account History',
      titleNe: 'Account को इतिहास बनाउनुस्',
      description: 'Your account is new. Trust is built over time. '
          'Keep trading honestly and your account age bonus '
          'will increase automatically over the next 3-6 months.',
      descriptionNe: 'तपाईंको account नयाँ छ। समयसँगै भरोसा बन्छ। '
          'इमान्दार व्यापार गर्दै जानुस्, account age bonus '
          '3-6 महिनामा स्वचालित रूपमा बढ्छ।',
      actionLabel: 'Learn More',
      actionLabelNe: 'थप जान्नुस्',
      potentialScoreIncrease: 5,
      icon: '📅',
      cardColor: '#388E3C',
    ),
    evaluate: (seller) {
      final days = DateTime.now().difference(seller.accountCreatedAt).inDays;
      return days < 30;
    },
  );

  // ── Rule 6: Score Dropped ────────────────────────────────────────

  static final scoreDropped = CoachingRule(
    id: 'score_dropped',
    priorityOrder: 1,
    card: const CoachingCard(
      id: 'score_dropped',
      title: 'Your Trust Score Dropped Recently',
      titleNe: 'तपाईंको Trust Score हालै घट्यो',
      description: 'Your score dropped in the last 7 days, likely '
          'due to a new report. Respond to any disputes quickly to '
          'recover your score.',
      descriptionNe: 'तपाईंको score गत ७ दिनमा घट्यो, सम्भवतः '
          'नयाँ रिपोर्टको कारण। छिटो जवाफ दिएर score बढाउनुस्।',
      actionLabel: 'View Disputes',
      actionLabelNe: 'Disputes हेर्नुस्',
      actionRoute: '/dashboard/disputes',
      potentialScoreIncrease: 0,
      icon: '📉',
      cardColor: '#E53935',
    ),
    evaluate: (seller) {
      if (seller.trustScoreHistory.length < 2) return false;
      final history = seller.trustScoreHistory;
      final latest = (history.last['score'] as num?)?.toDouble() ?? 0;
      // Check if any entry in last 7 days was > 10 points higher
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      for (final entry in history) {
        final ts = entry['timestamp'];
        if (ts == null) continue;
        DateTime? date;
        if (ts is DateTime) {
          date = ts;
        } else if (ts is int) {
          date = DateTime.fromMillisecondsSinceEpoch(ts);
        }
        if (date != null && date.isAfter(sevenDaysAgo)) {
          final score = (entry['score'] as num?)?.toDouble() ?? 0;
          if (score - latest > 10) return true;
        }
      }
      return false;
    },
  );

  // ── Rule 7: Trusted Milestone ────────────────────────────────────

  static final trustedMilestone = CoachingRule(
    id: 'trusted_milestone',
    priorityOrder: 0,
    card: const CoachingCard(
      id: 'trusted_milestone',
      title: 'You Reached Trusted Status!',
      titleNe: 'तपाईंले Trusted Status पाउनुभयो!',
      description: 'Congratulations! Your trust score crossed 80. '
          'Buyers now see your profile with a green TRUSTED badge. '
          'Share this milestone with your customers!',
      descriptionNe: 'बधाई छ! तपाईंको trust score 80 पुग्यो। '
          'अब खरिदकर्ताहरूले हरियो TRUSTED badge देख्छन्। '
          'यो उपलब्धि customer हरूसँग share गर्नुस्!',
      actionLabel: 'Share Achievement',
      actionLabelNe: 'उपलब्धि share गर्नुस्',
      actionRoute: '/share-profile',
      potentialScoreIncrease: 0,
      icon: '🏆',
      cardColor: '#2E7D32',
    ),
    evaluate: (seller) {
      if (seller.trustScore < 80) return false;
      if (seller.trustScoreHistory.length < 2) return false;
      final reversed = seller.trustScoreHistory.reversed.toList();
      if (reversed.length < 2) return false;
      final previous = (reversed[1]['score'] as num?)?.toDouble() ?? 0;
      return previous < 80;
    },
  );
}
