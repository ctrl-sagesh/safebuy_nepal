/// A smart prompt to help user fill in report form fields.
class SmartPrompt {
  const SmartPrompt({
    required this.question,
    required this.questionNe,
    required this.field,
    required this.inputType,
    this.options = const [],
  });

  /// English question text.
  final String question;

  /// Nepali question text.
  final String questionNe;

  /// Which form field this fills (e.g. 'amountLost', 'incidentDate').
  final String field;

  /// Input type: 'number', 'date', 'text', 'select'.
  final String inputType;

  /// Options for 'select' type.
  final List<String> options;
}

/// Evidence quality level.
enum EvidenceQuality {
  strong,   // Both screenshots uploaded and valid
  moderate, // One screenshot or one has flags
  weak,     // No screenshots or suspicious
}

/// Rules for generating smart prompts and evaluating evidence quality.
class ExtractionRules {
  ExtractionRules._();

  /// Generate smart prompts based on uploaded evidence.
  static List<SmartPrompt> generatePrompts({
    required bool hasPaymentScreenshot,
    required bool hasChatScreenshot,
  }) {
    final prompts = <SmartPrompt>[];

    if (hasPaymentScreenshot) {
      prompts.add(const SmartPrompt(
        question: 'What is the exact amount shown in your payment receipt?',
        questionNe: 'तपाईंको payment receipt मा कति रकम देखिन्छ?',
        field: 'amountLost',
        inputType: 'number',
      ));
      prompts.add(const SmartPrompt(
        question: 'What was the date of your payment?',
        questionNe: 'तपाईंले कहिले payment गर्नुभयो?',
        field: 'incidentDate',
        inputType: 'date',
      ));
      prompts.add(const SmartPrompt(
        question: 'Which payment method did you use?',
        questionNe: 'कुन payment method प्रयोग गर्नुभयो?',
        field: 'paymentMethod',
        inputType: 'select',
        options: ['eSewa', 'Khalti', 'Bank Transfer', 'IME Pay', 'Other'],
      ));
    }

    if (hasChatScreenshot) {
      prompts.add(const SmartPrompt(
        question: 'What platform did you communicate on?',
        questionNe: 'कुन platform मा कुरा गर्नुभयो?',
        field: 'platform',
        inputType: 'select',
        options: ['TikTok', 'Instagram', 'Facebook', 'WhatsApp', 'Viber', 'Other'],
      ));
      prompts.add(const SmartPrompt(
        question: 'What is the seller\'s username or handle on that platform?',
        questionNe: 'त्यो platform मा seller को username के हो?',
        field: 'sellerHandle',
        inputType: 'text',
      ));
    }

    return prompts;
  }

  /// Evaluate overall evidence quality.
  static EvidenceQuality evaluateQuality({
    required bool hasPaymentScreenshot,
    required bool hasChatScreenshot,
    required bool paymentLooksValid,
    required bool chatLooksValid,
  }) {
    if (hasPaymentScreenshot &&
        hasChatScreenshot &&
        paymentLooksValid &&
        chatLooksValid) {
      return EvidenceQuality.strong;
    }

    if ((hasPaymentScreenshot && paymentLooksValid) ||
        (hasChatScreenshot && chatLooksValid)) {
      return EvidenceQuality.moderate;
    }

    return EvidenceQuality.weak;
  }
}
