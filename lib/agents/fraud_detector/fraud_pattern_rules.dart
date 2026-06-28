import '../../models/seller_model.dart';

/// Fraud detection rule identifiers.
enum FraudRule {
  rapidNewAccount,
  largeAmount,
  coordinatedAttack,
  phoneRecycling,
  platformConcentration,
  zeroReviewWithReports,
}

/// Severity levels for detected patterns.
enum RuleSeverity { low, medium, high, critical }

/// Result of a single rule evaluation.
class DetectionResult {
  const DetectionResult({
    required this.rule,
    required this.severity,
    required this.sellerId,
    required this.alertMessage,
    this.data = const {},
  });

  final FraudRule rule;
  final RuleSeverity severity;
  final String sellerId;
  final String alertMessage;
  final Map<String, dynamic> data;
}

/// Static rule definitions evaluated against seller and report data.
class FraudPatternRules {
  FraudPatternRules._();

  // ── Rule 1: Rapid New Account ────────────────────────────────────

  /// Seller account < 30 days AND >= 2 scam reports.
  static DetectionResult? checkRapidNewAccount(SellerModel seller) {
    final accountAge = DateTime.now().difference(seller.accountCreatedAt).inDays;
    if (accountAge <= 30 && seller.scamReportCount >= 2) {
      return DetectionResult(
        rule: FraudRule.rapidNewAccount,
        severity: RuleSeverity.high,
        sellerId: seller.sellerId,
        alertMessage:
            'New seller with multiple reports. Possible hit-and-run scam.',
        data: {'accountAgeDays': accountAge, 'reportCount': seller.scamReportCount},
      );
    }
    return null;
  }

  // ── Rule 2: Large Amount Pattern ─────────────────────────────────

  /// Any single report with amountLost > 20,000 NPR.
  static DetectionResult? checkLargeAmount(
    String sellerId,
    double amountLost,
  ) {
    if (amountLost > 20000) {
      return DetectionResult(
        rule: FraudRule.largeAmount,
        severity: RuleSeverity.critical,
        sellerId: sellerId,
        alertMessage:
            'High-value fraud alert. NPR ${amountLost.toStringAsFixed(0)} reported lost.',
        data: {'amount': amountLost},
      );
    }
    return null;
  }

  // ── Rule 3: Coordinated Attack ───────────────────────────────────

  /// 3+ reports against same seller within 48 hours.
  static DetectionResult? checkCoordinatedAttack(
    String sellerId,
    List<DateTime> recentReportDates,
  ) {
    final cutoff = DateTime.now().subtract(const Duration(hours: 48));
    final recentCount =
        recentReportDates.where((d) => d.isAfter(cutoff)).length;
    if (recentCount >= 3) {
      return DetectionResult(
        rule: FraudRule.coordinatedAttack,
        severity: RuleSeverity.medium,
        sellerId: sellerId,
        alertMessage:
            'Surge in reports against this seller. Possible active scam campaign.',
        data: {'reportsIn48h': recentCount},
      );
    }
    return null;
  }

  // ── Rule 4: Phone Number Recycling ───────────────────────────────

  /// Same phone in multiple seller profiles.
  static DetectionResult? checkPhoneRecycling(
    String sellerId,
    String phone,
    int sellerCountWithSamePhone,
  ) {
    if (sellerCountWithSamePhone > 1) {
      return DetectionResult(
        rule: FraudRule.phoneRecycling,
        severity: RuleSeverity.high,
        sellerId: sellerId,
        alertMessage:
            'Phone number linked to multiple seller profiles. Possible identity fraud.',
        data: {
          'phone': phone,
          'profileCount': sellerCountWithSamePhone,
        },
      );
    }
    return null;
  }

  // ── Rule 5: Platform Concentration ───────────────────────────────

  /// 5+ reports in 7 days from same platform with same incident type.
  static DetectionResult? checkPlatformConcentration(
    String platform,
    String incidentType,
    int reportCount,
  ) {
    if (reportCount >= 5) {
      return DetectionResult(
        rule: FraudRule.platformConcentration,
        severity: RuleSeverity.low,
        sellerId: '', // platform-wide, not seller-specific
        alertMessage:
            'Trending scam type detected on $platform: $incidentType',
        data: {'platform': platform, 'incidentType': incidentType, 'count': reportCount},
      );
    }
    return null;
  }

  // ── Rule 6: Zero Review with Reports ─────────────────────────────

  /// Seller has 0 reviews but >= 1 scam report.
  static DetectionResult? checkZeroReviewWithReports(SellerModel seller) {
    if (seller.reviewCount == 0 && seller.scamReportCount >= 1) {
      return DetectionResult(
        rule: FraudRule.zeroReviewWithReports,
        severity: RuleSeverity.medium,
        sellerId: seller.sellerId,
        alertMessage:
            'Unreviewed seller with fraud reports. No positive history.',
        data: {'reportCount': seller.scamReportCount},
      );
    }
    return null;
  }
}
