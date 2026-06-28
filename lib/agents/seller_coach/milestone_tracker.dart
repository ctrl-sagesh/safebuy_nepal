/// A milestone a seller can achieve.
class Milestone {
  const Milestone({
    required this.score,
    required this.label,
    required this.labelNe,
    required this.icon,
  });

  final double score;
  final String label;
  final String labelNe;
  final String icon;
}

/// Tracks and displays seller milestones.
class MilestoneTracker {
  MilestoneTracker._();

  static const milestones = [
    Milestone(score: 50, label: 'Verified Seller', labelNe: 'प्रमाणित Seller', icon: '✅'),
    Milestone(score: 70, label: 'Community Trusted', labelNe: 'समुदायमा भरोसायोग्य', icon: '🌟'),
    Milestone(score: 80, label: 'Trusted Status', labelNe: 'Trusted Status', icon: '🏆'),
    Milestone(score: 90, label: 'Elite Seller', labelNe: 'Elite Seller', icon: '💎'),
    Milestone(score: 100, label: 'SafeBuy Champion', labelNe: 'SafeBuy Champion', icon: '🥇'),
  ];

  /// Get the next milestone the seller has not yet reached.
  static Milestone? getNextMilestone(double currentScore) {
    for (final m in milestones) {
      if (m.score > currentScore) return m;
    }
    return null;
  }

  /// Get the latest milestone the seller has achieved.
  static Milestone? getCurrentMilestone(double currentScore) {
    Milestone? latest;
    for (final m in milestones) {
      if (currentScore >= m.score) latest = m;
    }
    return latest;
  }

  /// Progress fraction (0.0 to 1.0) toward the next milestone.
  static double progressToNextMilestone(double currentScore) {
    final next = getNextMilestone(currentScore);
    if (next == null) return 1.0; // All milestones achieved!

    // Find the previous milestone boundary
    double prevScore = 0;
    for (final m in milestones) {
      if (m.score <= currentScore) {
        prevScore = m.score;
      }
    }

    final range = next.score - prevScore;
    if (range <= 0) return 1.0;
    return ((currentScore - prevScore) / range).clamp(0.0, 1.0);
  }

  /// All milestones the seller has already achieved.
  static List<Milestone> achievedMilestones(double currentScore) {
    return milestones.where((m) => currentScore >= m.score).toList();
  }
}
