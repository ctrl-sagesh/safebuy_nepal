import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/seller_model.dart';
import '../models/report_model.dart';
import '../models/review_model.dart';
import '../core/constants/app_constants.dart';

final trustScoreServiceProvider =
    Provider<TrustScoreService>((ref) => TrustScoreService());

/// SafeBuy Nepal Trust Score Algorithm
///
/// Factor breakdown (total 100 points):
///   1. Report Severity      — 40 pts (deducted for reports)
///   2. Verification Status  — 25 pts
///   3. Review Authenticity  — 20 pts
///   4. Dispute Resolution   — 10 pts
///   5. Account Age          —  5 pts
///
/// Recency multiplier applied to each report's deduction:
///   < 30 days  → 1.0 (full weight)
///   < 90 days  → 0.7
///   else       → 0.4
class TrustScoreService {
  /// Calculate trust score (0-100, one decimal)
  double calculateTrustScore(
    SellerModel seller,
    List<ReportModel> reports,
    List<ReviewModel> reviews,
  ) {
    double score = 0.0;

    // ── Factor 1: Report Severity (max 40 pts, deducted) ──────────────────────
    // Start at 40, subtract for each verified/pending report
    double reportFactor = 40.0;
    final validReports = reports
        .where((r) => r.status != 'flagged_false')
        .toList();

    for (final report in validReports) {
      final severity = _reportSeverityDeduction(report.incidentType);
      final recency = _recencyMultiplier(report.submittedAt);
      reportFactor -= severity * recency;
    }
    score += reportFactor.clamp(0.0, 40.0);

    // ── Factor 2: Verification Status (25 pts) ────────────────────────────────
    if (seller.isVerified && seller.verifiedBadge) {
      score += 25.0;
    } else if (seller.isVerified) {
      score += 18.0;
    } else if (seller.phone.isNotEmpty) {
      score += 10.0; // phone registered
    } else {
      score += 5.0;
    }

    // ── Factor 3: Review Authenticity (20 pts) ────────────────────────────────
    if (reviews.isNotEmpty) {
      double weightedSum = 0.0;
      double weightTotal = 0.0;
      for (final review in reviews) {
        final weight = review.authenticityWeight.clamp(0.0, 1.0);
        weightedSum += review.rating * weight;
        weightTotal += weight;
      }
      if (weightTotal > 0) {
        final weightedAvg = weightedSum / weightTotal;
        score += (weightedAvg / 5.0) * 20.0;
      }
    }

    // ── Factor 4: Dispute Response Rate (10 pts) ──────────────────────────────
    score += (seller.disputeResponseRate.clamp(0.0, 1.0) * 10.0);

    // ── Factor 5: Account Age (5 pts) ─────────────────────────────────────────
    final ageInDays =
        DateTime.now().difference(seller.accountCreatedAt).inDays;
    if (ageInDays >= 365) {
      score += 5.0;
    } else if (ageInDays >= 90) {
      score += 3.0;
    } else if (ageInDays >= 30) {
      score += 2.0;
    } else {
      score += 1.0;
    }

    // Clamp to 0-100, one decimal
    final result = score.clamp(0.0, 100.0);
    return double.parse(result.toStringAsFixed(1));
  }

  /// Return trust verdict string based on score
  String getTrustVerdict(double score) {
    if (score >= AppConstants.trustTrusted) return 'trusted';
    if (score >= AppConstants.trustUnverified) return 'unverified';
    return 'high_risk';
  }

  // ── Internal helpers ──────────────────────────────────────────────────────────

  double _reportSeverityDeduction(String incidentType) {
    switch (incidentType) {
      case 'payment_issue':
        return 12.0;
      case 'impersonation':
        return 10.0;
      case 'fake_product':
        return 9.0;
      case 'no_delivery':
        return 8.0;
      case 'wrong_item':
        return 5.0;
      default:
        return 4.0;
    }
  }

  double _recencyMultiplier(DateTime reportDate) {
    final daysAgo = DateTime.now().difference(reportDate).inDays;
    if (daysAgo < 30) return 1.0;
    if (daysAgo < 90) return 0.7;
    return 0.4;
  }

  /// Legacy compatibility method
  double calculate(SellerModel seller, List<ReportModel> reports) {
    return calculateTrustScore(seller, reports, []);
  }
}
