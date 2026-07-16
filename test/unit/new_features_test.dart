import 'package:flutter_test/flutter_test.dart';
import 'package:safebuy_nepal/core/services/festival_alert_service.dart';
import 'package:safebuy_nepal/core/widgets/loyalty_badge.dart';
import 'package:safebuy_nepal/models/seller_model.dart';

SellerModel _seller({
  required int accountAgeDays,
  int scamReportCount = 0,
}) {
  return SellerModel(
    sellerId: 'seller1',
    name: 'Loyal Store',
    phone: '9841234567',
    trustScore: 70,
    trustVerdict: 'unverified',
    isVerified: true,
    verifiedBadge: false,
    totalOrders: 10,
    reviewCount: 3,
    scamReportCount: scamReportCount,
    accountCreatedAt:
        DateTime.now().subtract(Duration(days: accountAgeDays)),
    lastActiveAt: DateTime.now(),
    disputeResponseRate: 0.5,
    trustScoreHistory: const [],
    averageRating: 4.0,
  );
}

void main() {
  group('FestivalAlertService.activeFestival', () {
    test('Dashain window covers early October', () {
      expect(FestivalAlertService.activeFestival(DateTime(2026, 10, 5)),
          'Dashain');
    });

    test('Tihar covers early November', () {
      expect(FestivalAlertService.activeFestival(DateTime(2026, 11, 8)),
          'Tihar');
    });

    test('Holi covers March', () {
      expect(FestivalAlertService.activeFestival(DateTime(2026, 3, 15)),
          'Holi');
    });

    test('Nepali New Year covers mid April', () {
      expect(FestivalAlertService.activeFestival(DateTime(2026, 4, 14)),
          'Nepali New Year');
    });

    test('Teej covers early September', () {
      expect(FestivalAlertService.activeFestival(DateTime(2026, 9, 5)),
          'Teej');
    });

    test('no festival in mid July', () {
      expect(FestivalAlertService.activeFestival(DateTime(2026, 7, 17)),
          isNull);
    });

    test('no festival in December', () {
      expect(FestivalAlertService.activeFestival(DateTime(2026, 12, 25)),
          isNull);
    });

    test('window boundaries are inclusive', () {
      expect(FestivalAlertService.activeFestival(DateTime(2026, 10, 1)),
          'Dashain');
      expect(FestivalAlertService.activeFestival(DateTime(2026, 10, 20)),
          isNotNull);
    });
  });

  group('LoyaltyBadge.tierFor', () {
    test('no badge under 6 months', () {
      expect(LoyaltyBadge.tierFor(_seller(accountAgeDays: 100)), isNull);
    });

    test('bronze at 6 months clean', () {
      final tier = LoyaltyBadge.tierFor(_seller(accountAgeDays: 200));
      expect(tier?.$1, '6 Month Clean Record');
    });

    test('silver at 1 year clean', () {
      final tier = LoyaltyBadge.tierFor(_seller(accountAgeDays: 400));
      expect(tier?.$1, '1 Year Trusted');
    });

    test('gold at 2 years clean', () {
      final tier = LoyaltyBadge.tierFor(_seller(accountAgeDays: 800));
      expect(tier?.$1, '2 Year Elite Seller');
    });

    test('no badge with any fraud report, regardless of age', () {
      expect(
          LoyaltyBadge.tierFor(
              _seller(accountAgeDays: 800, scamReportCount: 1)),
          isNull);
    });
  });
}
