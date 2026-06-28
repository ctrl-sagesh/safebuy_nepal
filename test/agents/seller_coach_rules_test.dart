import 'package:flutter_test/flutter_test.dart';
import 'package:safebuy_nepal/agents/seller_coach/coaching_rules.dart';
import 'package:safebuy_nepal/agents/seller_coach/milestone_tracker.dart';
import 'package:safebuy_nepal/models/seller_model.dart';

SellerModel _makeSeller({
  bool isVerified = true,
  String? tiktokHandle,
  String? instagramHandle,
  int scamReportCount = 0,
  double disputeResponseRate = 1.0,
  int reviewCount = 10,
  int accountAgeDays = 60,
  double trustScore = 50,
  List<Map<String, dynamic>> trustScoreHistory = const [],
}) {
  return SellerModel(
    sellerId: 'test_seller',
    name: 'Test Seller',
    phone: '9841234567',
    tiktokHandle: tiktokHandle,
    instagramHandle: instagramHandle,
    trustScore: trustScore,
    trustVerdict: trustScore >= 80
        ? 'trusted'
        : trustScore >= 50
            ? 'unverified'
            : 'high_risk',
    isVerified: isVerified,
    verifiedBadge: false,
    totalOrders: 10,
    reviewCount: reviewCount,
    scamReportCount: scamReportCount,
    accountCreatedAt: DateTime.now().subtract(Duration(days: accountAgeDays)),
    lastActiveAt: DateTime.now(),
    disputeResponseRate: disputeResponseRate,
    trustScoreHistory: trustScoreHistory,
    averageRating: 4.0,
  );
}

void main() {
  group('CoachingRules', () {
    test('phoneNotVerified triggers when not verified', () {
      final seller = _makeSeller(isVerified: false);
      expect(CoachingRules.phoneNotVerified.evaluate(seller), isTrue);
    });

    test('phoneNotVerified does not trigger when verified', () {
      final seller = _makeSeller(isVerified: true);
      expect(CoachingRules.phoneNotVerified.evaluate(seller), isFalse);
    });

    test('noSocialMedia triggers when verified but no socials', () {
      final seller = _makeSeller(isVerified: true);
      expect(CoachingRules.noSocialMedia.evaluate(seller), isTrue);
    });

    test('noSocialMedia does not trigger when TikTok linked', () {
      final seller = _makeSeller(tiktokHandle: 'myshop');
      expect(CoachingRules.noSocialMedia.evaluate(seller), isFalse);
    });

    test('unansweredReports triggers with reports and low response rate', () {
      final seller =
          _makeSeller(scamReportCount: 2, disputeResponseRate: 0.3);
      expect(CoachingRules.unansweredReports.evaluate(seller), isTrue);
    });

    test('unansweredReports does not trigger with good response rate', () {
      final seller =
          _makeSeller(scamReportCount: 2, disputeResponseRate: 0.8);
      expect(CoachingRules.unansweredReports.evaluate(seller), isFalse);
    });

    test('lowReviewCount triggers when < 5 reviews', () {
      final seller = _makeSeller(reviewCount: 3);
      expect(CoachingRules.lowReviewCount.evaluate(seller), isTrue);
    });

    test('lowReviewCount does not trigger when >= 5 reviews', () {
      final seller = _makeSeller(reviewCount: 5);
      expect(CoachingRules.lowReviewCount.evaluate(seller), isFalse);
    });

    test('newAccount triggers for < 30 day old account', () {
      final seller = _makeSeller(accountAgeDays: 15);
      expect(CoachingRules.newAccount.evaluate(seller), isTrue);
    });

    test('newAccount does not trigger for old account', () {
      final seller = _makeSeller(accountAgeDays: 60);
      expect(CoachingRules.newAccount.evaluate(seller), isFalse);
    });

    test('trustedMilestone triggers when score crosses 80', () {
      final seller = _makeSeller(
        trustScore: 82,
        trustScoreHistory: [
          {'score': 75, 'timestamp': DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch},
          {'score': 82, 'timestamp': DateTime.now().millisecondsSinceEpoch},
        ],
      );
      expect(CoachingRules.trustedMilestone.evaluate(seller), isTrue);
    });

    test('trustedMilestone does not trigger when already above 80', () {
      final seller = _makeSeller(
        trustScore: 85,
        trustScoreHistory: [
          {'score': 82, 'timestamp': DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch},
          {'score': 85, 'timestamp': DateTime.now().millisecondsSinceEpoch},
        ],
      );
      expect(CoachingRules.trustedMilestone.evaluate(seller), isFalse);
    });

    test('rules are sorted by priority in all list', () {
      // First rule should be priority 0 (milestone), then 1s, etc.
      expect(CoachingRules.all.first.priorityOrder, 0);
    });
  });

  group('MilestoneTracker', () {
    test('getNextMilestone returns correct milestone', () {
      final next = MilestoneTracker.getNextMilestone(45);
      expect(next, isNotNull);
      expect(next!.score, 50);
      expect(next.label, 'Verified Seller');
    });

    test('getNextMilestone returns null when all achieved', () {
      expect(MilestoneTracker.getNextMilestone(100), isNull);
    });

    test('progressToNextMilestone returns fraction', () {
      // Score 60, next milestone at 70, previous at 50
      final progress = MilestoneTracker.progressToNextMilestone(60);
      expect(progress, closeTo(0.5, 0.01));
    });

    test('progressToNextMilestone returns 1.0 at max', () {
      expect(MilestoneTracker.progressToNextMilestone(100), 1.0);
    });

    test('achievedMilestones returns correct list', () {
      final achieved = MilestoneTracker.achievedMilestones(75);
      expect(achieved.length, 2); // 50 and 70
    });

    test('getCurrentMilestone returns latest achieved', () {
      final current = MilestoneTracker.getCurrentMilestone(85);
      expect(current, isNotNull);
      expect(current!.score, 80);
    });
  });
}
