import 'package:flutter_test/flutter_test.dart';
import 'package:safebuy_nepal/core/utils/validators.dart';
import 'package:safebuy_nepal/models/seller_model.dart';
import 'package:safebuy_nepal/models/report_model.dart';
import 'package:safebuy_nepal/services/cyber_bureau_service.dart';

SellerModel _seller({
  double trustScore = 40,
  int scamReportCount = 0,
}) {
  return SellerModel(
    sellerId: 'seller1',
    name: 'Quick Buy Store',
    phone: '9841234567',
    esewaId: '9841234567',
    tiktokHandle: 'quickbuy_np',
    trustScore: trustScore,
    trustVerdict: trustScore >= 80
        ? 'trusted'
        : trustScore >= 50
            ? 'unverified'
            : 'high_risk',
    isVerified: false,
    verifiedBadge: false,
    totalOrders: 10,
    reviewCount: 2,
    scamReportCount: scamReportCount,
    accountCreatedAt: DateTime(2025, 1, 1),
    lastActiveAt: DateTime(2026, 1, 1),
    disputeResponseRate: 0.2,
    trustScoreHistory: const [],
    averageRating: 2.0,
  );
}

ReportModel _report({
  required String id,
  double amountLost = 1000,
  String type = 'no_delivery',
  String status = 'verified',
}) {
  return ReportModel(
    reportId: id,
    reporterId: 'user_$id',
    sellerId: 'seller1',
    sellerPhone: '9841234567',
    platform: 'TikTok',
    incidentType: type,
    amountLost: amountLost,
    description: 'Paid in advance, never received the item.',
    incidentDate: DateTime(2026, 1, 10),
    submittedAt: DateTime(2026, 1, 11),
    status: status,
    reporterDeclaration: true,
  );
}

void main() {
  group('Validators.email', () {
    test('accepts a valid email', () {
      expect(Validators.email('sagesh@example.com'), isNull);
    });
    test('rejects empty', () {
      expect(Validators.email(''), isNotNull);
    });
    test('rejects malformed', () {
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('a@b'), isNotNull);
    });
    test('returns Nepali message when lang=ne', () {
      expect(Validators.email('', 'ne'), 'इमेल आवश्यक छ');
    });
  });

  group('CyberBureauService.shouldEscalate', () {
    test('escalates at 5+ verified reports', () {
      final reports =
          List.generate(5, (i) => _report(id: 'R$i', amountLost: 1000));
      expect(CyberBureauService.shouldEscalate(_seller(), reports), isTrue);
    });

    test('escalates when total loss >= 50,000', () {
      final reports = [
        _report(id: 'R1', amountLost: 30000),
        _report(id: 'R2', amountLost: 25000),
      ];
      expect(CyberBureauService.shouldEscalate(_seller(), reports), isTrue);
    });

    test('escalates on critical score with 3+ reports', () {
      final reports =
          List.generate(3, (i) => _report(id: 'R$i', amountLost: 500));
      expect(
        CyberBureauService.shouldEscalate(
            _seller(trustScore: 20), reports),
        isTrue,
      );
    });

    test('does NOT escalate below thresholds', () {
      final reports = [_report(id: 'R1', amountLost: 500)];
      expect(
        CyberBureauService.shouldEscalate(
            _seller(trustScore: 60), reports),
        isFalse,
      );
    });

    test('ignores false-flagged reports', () {
      final reports = List.generate(
          6, (i) => _report(id: 'R$i', status: 'flagged_false'));
      expect(CyberBureauService.shouldEscalate(_seller(), reports), isFalse);
    });
  });

  group('CyberBureauService.generateNivedan', () {
    final reports = List.generate(5, (i) => _report(id: 'RPT-$i'));
    final letter = CyberBureauService.generateNivedan(_seller(), reports);

    test('addresses the Cyber Bureau', () {
      expect(letter.contains('साइबर ब्यूरो'), isTrue);
      expect(letter.contains('नेपाल प्रहरी'), isTrue);
    });
    test('includes seller identifiers', () {
      expect(letter.contains('9841234567'), isTrue);
      expect(letter.contains('quickbuy_np'), isTrue);
    });
    test('includes report reference IDs', () {
      expect(letter.contains('RPT-0'), isTrue);
    });
    test('includes an English summary section', () {
      expect(letter.contains('ENGLISH SUMMARY'), isTrue);
    });
  });
}
