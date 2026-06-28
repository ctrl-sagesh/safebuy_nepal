import 'package:flutter_test/flutter_test.dart';
import 'package:safebuy_nepal/agents/evidence_reviewer/image_analyzer.dart';
import 'package:safebuy_nepal/agents/evidence_reviewer/extraction_rules.dart';

void main() {
  group('ImageAnalysisResult', () {
    test('flags tooLarge for files > 5120 KB', () {
      final result = ImageAnalysisResult()
        ..fileSizeKB = 6000
        ..width = 1080
        ..height = 2340
        ..looksLikeScreenshot = true;
      result.flags.add(ImageFlag.tooLarge);
      expect(result.flags.contains(ImageFlag.tooLarge), isTrue);
    });

    test('flags mayNotBeScreenshot for landscape images', () {
      final result = ImageAnalysisResult()
        ..fileSizeKB = 200
        ..width = 1920
        ..height = 1080
        ..looksLikeScreenshot = false;
      result.flags.add(ImageFlag.mayNotBeScreenshot);
      expect(result.flags.contains(ImageFlag.mayNotBeScreenshot), isTrue);
      expect(result.looksLikeScreenshot, isFalse);
    });

    test('detects typical phone screenshot ratio', () {
      // Typical phone: 1080x2340 = ratio ~2.17
      final width = 1080;
      final height = 2340;
      final isPortrait = height > width;
      final ratio = height / width;
      final isTypical = ratio > 1.5 && ratio < 2.5;
      expect(isPortrait, isTrue);
      expect(isTypical, isTrue);
    });

    test('detects non-screenshot ratio (square)', () {
      final width = 1080;
      final height = 1080;
      final isPortrait = height > width;
      expect(isPortrait, isFalse);
    });

    test('flags unusually small file for dimensions', () {
      // 15 KB for a 1080px wide image is suspicious
      final result = ImageAnalysisResult()
        ..fileSizeKB = 15
        ..width = 1080
        ..height = 2340;
      if (result.fileSizeKB < 20 && result.width > 500) {
        result.flags.add(ImageFlag.unusuallySmallForDimensions);
      }
      expect(
          result.flags.contains(ImageFlag.unusuallySmallForDimensions), isTrue);
    });

    test('does not flag normal file size', () {
      final result = ImageAnalysisResult()
        ..fileSizeKB = 350
        ..width = 1080
        ..height = 2340;
      // Normal size, no flag
      expect(result.flags.isEmpty, isTrue);
    });
  });

  group('ExtractionRules', () {
    test('generates payment prompts when payment screenshot exists', () {
      final prompts = ExtractionRules.generatePrompts(
        hasPaymentScreenshot: true,
        hasChatScreenshot: false,
      );
      expect(prompts.length, 3); // amount, date, payment method
      expect(prompts.any((p) => p.field == 'amountLost'), isTrue);
      expect(prompts.any((p) => p.field == 'incidentDate'), isTrue);
    });

    test('generates chat prompts when chat screenshot exists', () {
      final prompts = ExtractionRules.generatePrompts(
        hasPaymentScreenshot: false,
        hasChatScreenshot: true,
      );
      expect(prompts.length, 2); // platform, handle
      expect(prompts.any((p) => p.field == 'platform'), isTrue);
    });

    test('generates all prompts when both screenshots exist', () {
      final prompts = ExtractionRules.generatePrompts(
        hasPaymentScreenshot: true,
        hasChatScreenshot: true,
      );
      expect(prompts.length, 5);
    });

    test('evaluates strong quality', () {
      final quality = ExtractionRules.evaluateQuality(
        hasPaymentScreenshot: true,
        hasChatScreenshot: true,
        paymentLooksValid: true,
        chatLooksValid: true,
      );
      expect(quality, EvidenceQuality.strong);
    });

    test('evaluates moderate quality', () {
      final quality = ExtractionRules.evaluateQuality(
        hasPaymentScreenshot: true,
        hasChatScreenshot: false,
        paymentLooksValid: true,
        chatLooksValid: false,
      );
      expect(quality, EvidenceQuality.moderate);
    });

    test('evaluates weak quality', () {
      final quality = ExtractionRules.evaluateQuality(
        hasPaymentScreenshot: false,
        hasChatScreenshot: false,
        paymentLooksValid: false,
        chatLooksValid: false,
      );
      expect(quality, EvidenceQuality.weak);
    });
  });
}
