/// How the response should be rendered in the UI.
enum ResponseType {
  /// Plain text reply.
  text,

  /// Show a seller profile card.
  sellerCard,

  /// Show tappable action buttons.
  actionButton,

  /// Show a warning banner.
  alert,

  /// Pre-fill a form.
  form,

  /// Celebration animation + message.
  milestone,

  /// Numbered step list.
  steps,
}

/// A single tappable action attached to a response.
class AgentAction {
  const AgentAction({
    required this.label,
    required this.labelNe,
    required this.actionType,
    this.payload = const {},
  });

  /// English button label.
  final String label;

  /// Nepali button label.
  final String labelNe;

  /// One of: 'navigate', 'search', 'call_agent'.
  final String actionType;

  /// Extra data (e.g. route path, prefill values).
  final Map<String, dynamic> payload;
}

/// Structured response from any agent.
class AgentResponse {
  const AgentResponse({
    required this.text,
    this.textNepali = '',
    this.type = ResponseType.text,
    this.actions = const [],
    this.data = const {},
    required this.agentId,
    this.requiresFollowUp = false,
    this.followUpQuestion = '',
  });

  /// Main response text (in active language).
  final String text;

  /// Nepali translation of the response.
  final String textNepali;

  /// How the response should be rendered.
  final ResponseType type;

  /// Optional tappable actions.
  final List<AgentAction> actions;

  /// Structured payload for cards, alerts, or suggestions.
  final Map<String, dynamic> data;

  /// Which agent produced this response.
  final String agentId;

  /// Whether the agent should ask a follow-up question.
  final bool requiresFollowUp;

  /// The follow-up question text (in active language).
  final String followUpQuestion;
}
