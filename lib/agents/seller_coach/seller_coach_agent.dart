import '../../models/seller_model.dart';
import '../core/agent_base.dart';
import '../core/agent_message.dart';
import '../core/agent_response.dart';
import 'coaching_rules.dart';
import 'milestone_tracker.dart';

/// Agent 3: Seller Coaching Agent.
///
/// Provides personalized guidance for sellers to improve trust score
/// with specific actionable steps and milestone celebrations.
class SellerCoachAgent extends AgentBase {
  SellerCoachAgent()
      : super(
          agentId: 'seller_coach',
          agentName: 'Seller Coach',
          agentDescription:
              'Personalized guidance to improve your trust score and grow your reputation',
        );

  @override
  Future<void> initialize() async {
    isActive = true;
  }

  /// Not a conversational agent; process() returns a summary.
  @override
  Future<AgentResponse> process(AgentMessage message) async {
    return AgentResponse(
      text: 'Use getCoachingCards() to get personalized coaching for a seller.',
      agentId: agentId,
    );
  }

  /// Get applicable coaching cards for a seller, sorted by priority.
  /// Returns at most [maxCards] cards.
  List<CoachingCard> getCoachingCards(
    SellerModel seller, {
    int maxCards = 4,
  }) {
    final applicable = <CoachingRule>[];

    for (final rule in CoachingRules.all) {
      if (rule.evaluate(seller)) {
        applicable.add(rule);
      }
    }

    // Already sorted by priority in CoachingRules.all
    return applicable
        .take(maxCards)
        .map((r) => r.card)
        .toList();
  }

  /// Check if the seller just achieved the Trusted milestone.
  CoachingCard? getMilestoneCard(SellerModel seller) {
    if (CoachingRules.trustedMilestone.evaluate(seller)) {
      return CoachingRules.trustedMilestone.card;
    }
    return null;
  }

  /// Get the next milestone info for progress bar display.
  ({Milestone? next, double progress, List<Milestone> achieved})
      getMilestoneProgress(double currentScore) {
    return (
      next: MilestoneTracker.getNextMilestone(currentScore),
      progress: MilestoneTracker.progressToNextMilestone(currentScore),
      achieved: MilestoneTracker.achievedMilestones(currentScore),
    );
  }
}
