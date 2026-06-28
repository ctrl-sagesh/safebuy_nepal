import 'package:cloud_firestore/cloud_firestore.dart';

import 'fraud_pattern_rules.dart';

/// Publishes fraud detection results to Firestore.
class FraudAlertPublisher {
  FraudAlertPublisher._();

  static final _firestore = FirebaseFirestore.instance;

  /// Log a detection result to the fraud_detector_log collection.
  static Future<void> logDetection(DetectionResult result) async {
    await _firestore.collection('fraud_detector_log').add({
      'sellerId': result.sellerId,
      'rule': result.rule.name,
      'severity': result.severity.name,
      'alertMessage': result.alertMessage,
      'data': result.data,
      'timestamp': FieldValue.serverTimestamp(),
      'agentId': 'fraud_detector',
    });
  }

  /// Post a community alert visible to all users.
  static Future<void> postCommunityAlert(DetectionResult result) async {
    await _firestore.collection('community_alerts').add({
      'title': 'Fraud Pattern Detected',
      'description': result.alertMessage,
      'severity': result.severity.name,
      'timestamp': FieldValue.serverTimestamp(),
      'source': 'fraud_detector_agent',
      'relatedSellerId': result.sellerId,
      'data': result.data,
    });
  }

  /// Notify admin of critical findings.
  static Future<void> notifyAdmin(DetectionResult result) async {
    await _firestore.collection('admin_notifications').add({
      'type': result.rule.name,
      'sellerId': result.sellerId,
      'alertMessage': result.alertMessage,
      'data': result.data,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  /// Cap a seller's trust score at [maxScore].
  static Future<void> capTrustScore(
    String sellerId,
    double currentScore,
    double maxScore,
  ) async {
    if (currentScore > maxScore) {
      await _firestore.collection('sellers').doc(sellerId).update({
        'trustScore': maxScore,
      });
    }
  }

  /// Set seller status to 'under_review'.
  static Future<void> flagForReview(String sellerId) async {
    await _firestore.collection('sellers').doc(sellerId).update({
      'status': 'under_review',
    });
  }

  /// Add a warning flag to the seller document.
  static Future<void> addWarningFlag(String sellerId, String flag) async {
    await _firestore.collection('sellers').doc(sellerId).update({
      'warningFlags': FieldValue.arrayUnion([flag]),
    });
  }
}
