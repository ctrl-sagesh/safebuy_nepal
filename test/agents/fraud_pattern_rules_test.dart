import 'package:flutter_test/flutter_test.dart';
import 'package:safebuy_nepal/agents/fraud_detector/fraud_pattern_rules.dart';
import 'package:safebuy_nepal/models/seller_model.dart';

SellerModel _makeSeller({
  int accountAgeDays = 60,
  int scamReportCount = 0,
  int reviewCount = 5,
  double disputeResponseRate = 1.0,
  double trustScore = 50,
  String phone = '9841234567',
}) {
  return SellerModel(
    sellerId: 'test_seller',
    name: 'Test Seller',
    phone: phone,
    trustScore: trustScore,
    trustVerdict: trustScore >= 80
        ? 'trusted'
        : trustScore >= 50
            ? 'unverified'
            : 'high_risk',
    isVerified: true,
    verifiedBadge: false,
    totalOrders: 10,
    reviewCount: reviewCount,
    scamReportCount: scamReportCount,
    accountCreatedAt: DateTime.now().subtract(Duration(days: accountAgeDays)),
    lastActiveAt: DateTime.now(),
    disputeResponseRate: disputeResponseRate,
    trustScoreHistory: [],
    averageRating: 4.0,
  );
}

void main() {
  group('FraudPatternRules', () {
    // ── Rule 1: Rapid New Account ──────────────────────────────────
    group('checkRapidNewAccount', () {
      test('triggers for new account with 2+ reports', () {
        final seller = _makeSeller(accountAgeDays: 15, scamReportCount: 2);
        final result = FraudPatternRules.checkRapidNewAccount(seller);
        expect(result, isNotNull);
        expect(result!.rule, FraudRule.rapidNewAccount);
        expect(result.severity, RuleSeverity.high);
      });

      test('does not trigger for old account', () {
        final seller = _makeSeller(accountAgeDays: 60, scamReportCount: 3);
        expect(FraudPatternRules.checkRapidNewAccount(seller), isNull);
      });

      test('does not trigger for new account with 1 report', () {
        final seller = _makeSeller(accountAgeDays: 10, scamReportCount: 1);
        expect(FraudPatternRules.checkRapidNewAccount(seller), isNull);
      });

      test('boundary: exactly 30 days and 2 reports triggers', () {
        final seller = _makeSeller(accountAgeDays: 30, scamReportCount: 2);
        expect(FraudPatternRules.checkRapidNewAccount(seller), isNotNull);
      });
    });

    // ── Rule 2: Large Amount ───────────────────────────────────────
    group('checkLargeAmount', () {
      test('triggers for amount > 20000 NPR', () {
        final result = FraudPatternRules.checkLargeAmount('s1', 25000);
        expect(result, isNotNull);
        expect(result!.rule, FraudRule.largeAmount);
        expect(result.severity, RuleSeverity.critical);
      });

      test('does not trigger for amount <= 20000', () {
        expect(
            FraudPatternRules.checkLargeAmount('s1', 20000), isNull);
      });

      test('does not trigger for small amount', () {
        expect(
            FraudPatternRules.checkLargeAmount('s1', 500), isNull);
      });
    });

    // ── Rule 3: Coordinated Attack ─────────────────────────────────
    group('checkCoordinatedAttack', () {
      test('triggers for 3+ reports within 48h', () {
        final now = DateTime.now();
        final dates = [
          now.subtract(const Duration(hours: 1)),
          now.subtract(const Duration(hours: 10)),
          now.subtract(const Duration(hours: 24)),
        ];
        final result = FraudPatternRules.checkCoordinatedAttack('s1', dates);
        expect(result, isNotNull);
        expect(result!.rule, FraudRule.coordinatedAttack);
      });

      test('does not trigger for 2 reports', () {
        final now = DateTime.now();
        final dates = [
          now.subtract(const Duration(hours: 1)),
          now.subtract(const Duration(hours: 10)),
        ];
        expect(
            FraudPatternRules.checkCoordinatedAttack('s1', dates), isNull);
      });

      test('does not trigger for old reports', () {
        final now = DateTime.now();
        final dates = [
          now.subtract(const Duration(hours: 72)),
          now.subtract(const Duration(hours: 96)),
          now.subtract(const Duration(hours: 100)),
        ];
        expect(
            FraudPatternRules.checkCoordinatedAttack('s1', dates), isNull);
      });
    });

    // ── Rule 4: Phone Recycling ────────────────────────────────────
    group('checkPhoneRecycling', () {
      test('triggers when phone appears in 2+ profiles', () {
        final result = FraudPatternRules.checkPhoneRecycling(
            's1', '9841234567', 2);
        expect(result, isNotNull);
        expect(result!.rule, FraudRule.phoneRecycling);
      });

      test('does not trigger for unique phone', () {
        expect(FraudPatternRules.checkPhoneRecycling(
            's1', '9841234567', 1), isNull);
      });
    });

    // ── Rule 5: Platform Concentration ─────────────────────────────
    group('checkPlatformConcentration', () {
      test('triggers for 5+ reports on same platform and type', () {
        final result = FraudPatternRules.checkPlatformConcentration(
            'tiktok', 'non_delivery', 5);
        expect(result, isNotNull);
        expect(result!.rule, FraudRule.platformConcentration);
      });

      test('does not trigger for 4 reports', () {
        expect(FraudPatternRules.checkPlatformConcentration(
            'tiktok', 'non_delivery', 4), isNull);
      });
    });

    // ── Rule 6: Zero Review with Reports ───────────────────────────
    group('checkZeroReviewWithReports', () {
      test('triggers for seller with 0 reviews and 1+ reports', () {
        final seller = _makeSeller(reviewCount: 0, scamReportCount: 1);
        final result = FraudPatternRules.checkZeroReviewWithReports(seller);
        expect(result, isNotNull);
        expect(result!.rule, FraudRule.zeroReviewWithReports);
      });

      test('does not trigger for seller with reviews', () {
        final seller = _makeSeller(reviewCount: 3, scamReportCount: 1);
        expect(
            FraudPatternRules.checkZeroReviewWithReports(seller), isNull);
      });

      test('does not trigger for seller with 0 reports', () {
        final seller = _makeSeller(reviewCount: 0, scamReportCount: 0);
        expect(
            FraudPatternRules.checkZeroReviewWithReports(seller), isNull);
      });
    });
  });
}
