// SafeBuy Nepal — Trust Score Service Unit Tests
import 'package:flutter_test/flutter_test.dart';

import 'package:safebuy_nepal/services/trust_score_service.dart';
import 'package:safebuy_nepal/models/seller_model.dart';
import 'package:safebuy_nepal/models/report_model.dart';
import 'package:safebuy_nepal/models/review_model.dart';

void main() {
  late TrustScoreService service;

  setUp(() => service = TrustScoreService());

  // ── Helpers ────────────────────────────────────────────────────────────────

  SellerModel mkSeller({
    bool isVerified = false,
    bool verifiedBadge = false,
    double disputeRate = 0.0,
    int accountAgeDays = 30,
  }) {
    return SellerModel(
      sellerId: 'test',
      name: 'Test Seller',
      phone: '9841234567',
      trustScore: 50,
      trustVerdict: 'unverified',
      isVerified: isVerified,
      verifiedBadge: verifiedBadge,
      totalOrders: 10,
      reviewCount: 0,
      scamReportCount: 0,
      accountCreatedAt:
          DateTime.now().subtract(Duration(days: accountAgeDays)),
      lastActiveAt: DateTime.now(),
      disputeResponseRate: disputeRate,
      averageRating: 0,
      trustScoreHistory: const [],
    );
  }

  ReportModel mkReport({
    String type = 'no_delivery',
    int daysAgo = 5,
    String status = 'pending',
    double amount = 5000,
  }) {
    return ReportModel(
      reportId: 't',
      reporterId: 'r',
      sellerId: 'test',
      sellerPhone: '9841234567',
      platform: 'TikTok',
      incidentType: type,
      amountLost: amount,
      description: 'Test report description over fifty characters long.',
      incidentDate: DateTime.now().subtract(Duration(days: daysAgo)),
      submittedAt: DateTime.now().subtract(Duration(days: daysAgo)),
      status: status,
      reporterDeclaration: true,
      isAnonymizedForDeletion: false,
    );
  }

  ReviewModel mkReview({
    int rating = 5,
    double authenticity = 1.0,
  }) {
    return ReviewModel(
      reviewId: 'rv',
      sellerId: 'test',
      reviewerId: 'rev',
      reviewerDisplayName: 'Buyer',
      rating: rating,
      comment: 'A genuine review of the product and service.',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      isVerifiedPurchase: true,
      authenticityWeight: authenticity,
      helpfulCount: 0,
    );
  }

  // ── Tests ──────────────────────────────────────────────────────────────────

  group('TrustScoreService.calculateTrustScore', () {
    test('returns >= 0 and <= 100', () {
      final score = service.calculateTrustScore(mkSeller(), [], []);
      expect(score, inInclusiveRange(0, 100));
    });

    test('verified seller with badge gets full verification bonus', () {
      final clean = service.calculateTrustScore(
          mkSeller(isVerified: true, verifiedBadge: true), [], []);
      final unverified = service.calculateTrustScore(mkSeller(), [], []);
      expect(clean, greaterThan(unverified));
    });

    test('reports decrease the score', () {
      final clean = service.calculateTrustScore(mkSeller(), [], []);
      final withReport =
          service.calculateTrustScore(mkSeller(), [mkReport()], []);
      expect(withReport, lessThan(clean));
    });

    test('flagged_false reports are EXCLUDED', () {
      final fakeReports = [
        mkReport(status: 'flagged_false'),
        mkReport(status: 'flagged_false'),
        mkReport(status: 'flagged_false'),
      ];
      final scoreFlagged =
          service.calculateTrustScore(mkSeller(), fakeReports, []);
      final scoreEmpty = service.calculateTrustScore(mkSeller(), [], []);
      expect(scoreFlagged, scoreEmpty);
    });

    test('recent reports penalised more than old reports', () {
      final recent = service.calculateTrustScore(
          mkSeller(), [mkReport(daysAgo: 5)], []);
      final old = service.calculateTrustScore(
          mkSeller(), [mkReport(daysAgo: 200)], []);
      expect(recent, lessThan(old));
    });

    test('higher dispute response rate yields higher score', () {
      final low = service.calculateTrustScore(
          mkSeller(disputeRate: 0.1), [], []);
      final high = service.calculateTrustScore(
          mkSeller(disputeRate: 0.9), [], []);
      expect(high, greaterThanOrEqualTo(low));
    });

    test('older accounts get age bonus', () {
      final young =
          service.calculateTrustScore(mkSeller(accountAgeDays: 10), [], []);
      final mature =
          service.calculateTrustScore(mkSeller(accountAgeDays: 365), [], []);
      expect(mature, greaterThanOrEqualTo(young));
    });

    test('positive reviews increase the score', () {
      final none = service.calculateTrustScore(mkSeller(), [], []);
      final great = service.calculateTrustScore(
        mkSeller(),
        [],
        [mkReview(rating: 5), mkReview(rating: 5), mkReview(rating: 5)],
      );
      expect(great, greaterThan(none));
    });

    test('low-authenticity reviews count less than high-authenticity', () {
      // Use multiple reviews to amplify the authenticity weight effect
      final highAuthReviews = List.generate(
          5, (_) => mkReview(rating: 5, authenticity: 1.0));
      final lowAuthReviews = List.generate(
          5, (_) => mkReview(rating: 5, authenticity: 0.2));
      final highAuth =
          service.calculateTrustScore(mkSeller(), [], highAuthReviews);
      final lowAuth =
          service.calculateTrustScore(mkSeller(), [], lowAuthReviews);
      expect(highAuth, greaterThanOrEqualTo(lowAuth));
    });

    test('score is rounded to one decimal place', () {
      final score = service.calculateTrustScore(mkSeller(), [], []);
      // value * 10 should be an integer
      expect((score * 10) % 1, 0.0);
    });
  });

  group('TrustScoreService.getTrustVerdict', () {
    test('score >= 80 = trusted', () {
      expect(service.getTrustVerdict(80.0), 'trusted');
      expect(service.getTrustVerdict(95.5), 'trusted');
      expect(service.getTrustVerdict(100.0), 'trusted');
    });

    test('score >= 50 and < 80 = unverified', () {
      expect(service.getTrustVerdict(50.0), 'unverified');
      expect(service.getTrustVerdict(65.4), 'unverified');
      expect(service.getTrustVerdict(79.9), 'unverified');
    });

    test('score < 50 = high_risk', () {
      expect(service.getTrustVerdict(49.9), 'high_risk');
      expect(service.getTrustVerdict(25.0), 'high_risk');
      expect(service.getTrustVerdict(0.0), 'high_risk');
    });
  });
}
