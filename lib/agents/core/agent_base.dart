import 'agent_message.dart';
import 'agent_response.dart';

/// Abstract base class every SafeBuy agent must extend.
abstract class AgentBase {
  AgentBase({
    required this.agentId,
    required this.agentName,
    required this.agentDescription,
  });

  /// Unique identifier (e.g. 'safeguard', 'fraud_detector').
  final String agentId;

  /// Human-readable name (e.g. 'SafeGuard AI').
  final String agentName;

  /// Short description of what the agent does.
  final String agentDescription;

  bool isActive = false;

  /// One-time setup (load knowledge base, warm caches, etc.).
  Future<void> initialize();

  /// Process an incoming message and return a response.
  Future<AgentResponse> process(AgentMessage message);

  /// Release resources.
  void dispose() {
    isActive = false;
  }
}
