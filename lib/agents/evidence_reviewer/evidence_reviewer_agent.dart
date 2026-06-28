import 'dart:io';

import '../core/agent_base.dart';
import '../core/agent_message.dart';
import '../core/agent_response.dart';
import 'extraction_rules.dart';
import 'image_analyzer.dart';

/// Result of reviewing uploaded evidence.
class EvidenceReviewResult {
  ImageAnalysisResult? paymentAnalysis;
  ImageAnalysisResult? chatAnalysis;
  String paymentFeedback = '';
  String paymentFeedbackNe = '';
  String chatFeedback = '';
  String chatFeedbackNe = '';
  List<SmartPrompt> smartPrompts = [];
  EvidenceQuality quality = EvidenceQuality.weak;
}

/// Agent 4: Evidence Review Agent.
///
/// Analyzes uploaded screenshots during report filing, provides
/// feedback on quality, and generates smart prompts to help
/// pre-fill form fields.
class EvidenceReviewerAgent extends AgentBase {
  EvidenceReviewerAgent()
      : super(
          agentId: 'evidence_reviewer',
          agentName: 'Evidence Reviewer',
          agentDescription:
              'Analyzes your fraud evidence screenshots and helps complete your report',
        );

  final _analyzer = ImageAnalyzer();

  @override
  Future<void> initialize() async {
    isActive = true;
  }

  /// Not a conversational agent; process() returns a status summary.
  @override
  Future<AgentResponse> process(AgentMessage message) async {
    return AgentResponse(
      text: 'Use reviewEvidence() to analyze uploaded screenshots.',
      agentId: agentId,
    );
  }

  /// Review uploaded evidence files and return analysis + smart prompts.
  Future<EvidenceReviewResult> reviewEvidence({
    File? paymentScreenshot,
    File? chatScreenshot,
  }) async {
    final result = EvidenceReviewResult();

    if (paymentScreenshot != null) {
      try {
        result.paymentAnalysis =
            await _analyzer.analyzeImage(paymentScreenshot);
        final fb = _generateFeedback(result.paymentAnalysis!, 'payment');
        result.paymentFeedback = fb.en;
        result.paymentFeedbackNe = fb.ne;
      } catch (_) {
        result.paymentFeedback = 'Could not analyze the payment screenshot.';
        result.paymentFeedbackNe =
            'Payment screenshot विश्लेषण गर्न सकिएन।';
      }
    }

    if (chatScreenshot != null) {
      try {
        result.chatAnalysis =
            await _analyzer.analyzeImage(chatScreenshot);
        final fb = _generateFeedback(result.chatAnalysis!, 'chat');
        result.chatFeedback = fb.en;
        result.chatFeedbackNe = fb.ne;
      } catch (_) {
        result.chatFeedback = 'Could not analyze the chat screenshot.';
        result.chatFeedbackNe = 'Chat screenshot विश्लेषण गर्न सकिएन।';
      }
    }

    // Generate smart prompts
    result.smartPrompts = ExtractionRules.generatePrompts(
      hasPaymentScreenshot: paymentScreenshot != null,
      hasChatScreenshot: chatScreenshot != null,
    );

    // Evaluate quality
    result.quality = ExtractionRules.evaluateQuality(
      hasPaymentScreenshot: paymentScreenshot != null,
      hasChatScreenshot: chatScreenshot != null,
      paymentLooksValid:
          result.paymentAnalysis?.looksLikeScreenshot ?? false,
      chatLooksValid:
          result.chatAnalysis?.looksLikeScreenshot ?? false,
    );

    return result;
  }

  ({String en, String ne}) _generateFeedback(
    ImageAnalysisResult analysis,
    String type,
  ) {
    if (analysis.flags.contains(ImageFlag.tooLarge)) {
      return (
        en: 'This file is large but we will compress it automatically.',
        ne: 'यो file ठूलो छ तर हामी स्वचालित रूपमा compress गर्छौं।',
      );
    }
    if (analysis.flags.contains(ImageFlag.mayNotBeScreenshot)) {
      if (type == 'payment') {
        return (
          en: 'This does not look like a typical payment screenshot. '
              'Make sure you are uploading your eSewa/Khalti receipt.',
          ne: 'यो सामान्य payment screenshot जस्तो देखिँदैन। '
              'कृपया eSewa/Khalti receipt upload गर्नुस्।',
        );
      }
      return (
        en: 'This may not be a chat screenshot. '
            'Please upload a screenshot of your conversation with the seller.',
        ne: 'यो chat screenshot नहुन सक्छ। '
            'कृपया seller सँगको कुराकानीको screenshot upload गर्नुस्।',
      );
    }
    if (analysis.flags.contains(ImageFlag.unusuallySmallForDimensions)) {
      return (
        en: 'This image may have been compressed or edited. '
            'Try to upload the original screenshot from your phone.',
        ne: 'यो image compress वा edit भएको हुन सक्छ। '
            'कृपया फोनबाट original screenshot upload गर्नुस्।',
      );
    }
    if (analysis.looksLikeScreenshot) {
      return (
        en: 'Screenshot looks good. Evidence accepted.',
        ne: 'Screenshot ठीक देखिन्छ। प्रमाण स्वीकृत।',
      );
    }
    return (
      en: 'Evidence uploaded. Our team will review this.',
      ne: 'प्रमाण upload भयो। हाम्रो team ले review गर्नेछ।',
    );
  }
}
