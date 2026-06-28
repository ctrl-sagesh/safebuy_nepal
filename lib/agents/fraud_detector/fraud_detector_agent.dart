import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/seller_model.dart';
import '../core/agent_base.dart';
import '../core/agent_message.dart';
import '../core/agent_response.dart';
import 'fraud_alert_publisher.dart';
import 'fraud_pattern_rules.dart';

/// Agent 2: Fraud Pattern Detector (background agent).
///
/// Runs automatically when reports are submitted. Detects patterns
/// across sellers and reports, then posts community alerts.
class FraudDetectorAgent extends AgentBase {
  FraudDetectorAgent()
      : super(
          agentId: 'fraud_detector',
          agentName: 'Fraud Detector',
          agentDescription:
              'Automatically analyzes reports for suspicious patterns and alerts the community',
        );

  @override
  Future<void> initialize() async {
    isActive = true;
  }

  /// Not a conversational agent, so process() returns a status summary.
  @override
  Future<AgentResponse> process(AgentMessage message) async {
    return AgentResponse(
      text: 'Fraud Detector is a background agent. '
          'It runs automatically when reports are submitted.',
      agentId: agentId,
    );
  }

  // ── Main entry point: call after a report is submitted ──────────

  /// Analyze a newly submitted report for fraud patterns.
  ///
  /// Call this via `Future.microtask()` so it never blocks the UI.
  Future<List<DetectionResult>> analyzeNewReport({
    required String sellerId,
    required double amountLost,
    required String platform,
    required String incidentType,
  }) async {
    final detectedPatterns = <DetectionResult>[];

    try {
      final seller = await _fetchSeller(sellerId);
      if (seller == null) return detectedPatterns;

      // Rule 1: Rapid New Account
      final r1 = FraudPatternRules.checkRapidNewAccount(seller);
      if (r1 != null) detectedPatterns.add(r1);

      // Rule 2: Large Amount
      final r2 = FraudPatternRules.checkLargeAmount(sellerId, amountLost);
      if (r2 != null) detectedPatterns.add(r2);

      // Rule 3: Coordinated Attack
      final recentDates = await _fetchRecentReportDates(sellerId);
      final r3 = FraudPatternRules.checkCoordinatedAttack(
        sellerId,
        recentDates,
      );
      if (r3 != null) detectedPatterns.add(r3);

      // Rule 4: Phone Recycling
      final phoneCount = await _countSellersWithPhone(seller.phone);
      final r4 = FraudPatternRules.checkPhoneRecycling(
        sellerId,
        seller.phone,
        phoneCount,
      );
      if (r4 != null) detectedPatterns.add(r4);

      // Rule 6: Zero Review with Reports
      final r6 = FraudPatternRules.checkZeroReviewWithReports(seller);
      if (r6 != null) detectedPatterns.add(r6);

      // Execute actions for all triggered rules
      for (final result in detectedPatterns) {
        await _executeRuleAction(result, seller);
        await FraudAlertPublisher.logDetection(result);
      }

      // Rule 5: Platform Concentration (platform-wide)
      await _checkPlatformConcentration(platform, incidentType);
    } catch (_) {
      // Agent errors must never crash the app
    }

    return detectedPatterns;
  }

  // ── Firestore queries ────────────────────────────────────────────

  Future<SellerModel?> _fetchSeller(String sellerId) async {
    final doc = await FirebaseFirestore.instance
        .collection('sellers')
        .doc(sellerId)
        .get()
        .timeout(const Duration(seconds: 5));
    if (!doc.exists) return null;
    return SellerModel.fromFirestore(doc);
  }

  Future<List<DateTime>> _fetchRecentReportDates(String sellerId) async {
    final cutoff = DateTime.now().subtract(const Duration(hours: 48));
    final snap = await FirebaseFirestore.instance
        .collection('reports')
        .where('sellerId', isEqualTo: sellerId)
        .where('createdAt', isGreaterThan: Timestamp.fromDate(cutoff))
        .get()
        .timeout(const Duration(seconds: 5));
    return snap.docs.map((d) {
      final ts = d.data()['createdAt'] as Timestamp?;
      return ts?.toDate() ?? DateTime.now();
    }).toList();
  }

  Future<int> _countSellersWithPhone(String phone) async {
    if (phone.isEmpty) return 0;
    final snap = await FirebaseFirestore.instance
        .collection('sellers')
        .where('phone', isEqualTo: phone)
        .get()
        .timeout(const Duration(seconds: 5));
    return snap.docs.length;
  }

  Future<void> _checkPlatformConcentration(
    String platform,
    String incidentType,
  ) async {
    if (platform.isEmpty || incidentType.isEmpty) return;
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final snap = await FirebaseFirestore.instance
        .collection('reports')
        .where('platform', isEqualTo: platform)
        .where('incidentType', isEqualTo: incidentType)
        .where('createdAt', isGreaterThan: Timestamp.fromDate(cutoff))
        .get()
        .timeout(const Duration(seconds: 5));

    final r5 = FraudPatternRules.checkPlatformConcentration(
      platform,
      incidentType,
      snap.docs.length,
    );
    if (r5 != null) {
      await FraudAlertPublisher.postCommunityAlert(r5);
      await FraudAlertPublisher.logDetection(r5);
    }
  }

  // ── Rule action execution ────────────────────────────────────────

  Future<void> _executeRuleAction(
    DetectionResult result,
    SellerModel seller,
  ) async {
    switch (result.rule) {
      case FraudRule.rapidNewAccount:
        await FraudAlertPublisher.capTrustScore(
          seller.sellerId,
          seller.trustScore,
          40.0,
        );
        await FraudAlertPublisher.postCommunityAlert(result);
        break;

      case FraudRule.largeAmount:
        await FraudAlertPublisher.notifyAdmin(result);
        await FraudAlertPublisher.postCommunityAlert(result);
        break;

      case FraudRule.coordinatedAttack:
        await FraudAlertPublisher.flagForReview(seller.sellerId);
        await FraudAlertPublisher.postCommunityAlert(result);
        break;

      case FraudRule.phoneRecycling:
        await FraudAlertPublisher.notifyAdmin(result);
        await FraudAlertPublisher.addWarningFlag(
          seller.sellerId,
          'phone_recycling',
        );
        break;

      case FraudRule.platformConcentration:
        // Handled separately in _checkPlatformConcentration
        break;

      case FraudRule.zeroReviewWithReports:
        await FraudAlertPublisher.addWarningFlag(
          seller.sellerId,
          'zero_review_with_reports',
        );
        break;
    }
  }
}
