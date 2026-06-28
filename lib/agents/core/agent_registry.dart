import '../safeguard/safeguard_agent.dart';
import '../fraud_detector/fraud_detector_agent.dart';
import '../seller_coach/seller_coach_agent.dart';
import '../evidence_reviewer/evidence_reviewer_agent.dart';

/// Singleton registry that holds all agent instances.
class AgentRegistry {
  AgentRegistry._internal();
  static final AgentRegistry _instance = AgentRegistry._internal();
  factory AgentRegistry() => _instance;

  late final SafeguardAgent safeguard;
  late final FraudDetectorAgent fraudDetector;
  late final SellerCoachAgent sellerCoach;
  late final EvidenceReviewerAgent evidenceReviewer;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Initialise every agent. Safe to call multiple times.
  Future<void> initializeAll() async {
    if (_initialized) return;

    safeguard = SafeguardAgent();
    fraudDetector = FraudDetectorAgent();
    sellerCoach = SellerCoachAgent();
    evidenceReviewer = EvidenceReviewerAgent();

    await Future.wait([
      safeguard.initialize(),
      fraudDetector.initialize(),
      sellerCoach.initialize(),
      evidenceReviewer.initialize(),
    ]);

    _initialized = true;
  }

  /// Dispose all agents and reset state.
  void disposeAll() {
    if (!_initialized) return;
    safeguard.dispose();
    fraudDetector.dispose();
    sellerCoach.dispose();
    evidenceReviewer.dispose();
    _initialized = false;
  }
}
