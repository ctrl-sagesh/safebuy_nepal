/// Represents a message sent to any agent for processing.
class AgentMessage {
  AgentMessage({
    required this.content,
    required this.userId,
    this.language = 'en',
    this.context = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// User input text.
  final String content;

  /// Who sent this message.
  final String userId;

  /// Active language: 'en' or 'ne'.
  final String language;

  /// Extra data the agent might need.
  ///
  /// Common keys:
  /// - `sellerId`      : specific seller being asked about
  /// - `reportId`      : specific report being asked about
  /// - `sellerData`    : SellerModel as map if already fetched
  /// - `currentScreen` : which screen the user is on
  /// - `userRole`      : 'buyer' or 'seller'
  final Map<String, dynamic> context;

  /// When the message was created.
  final DateTime timestamp;
}
