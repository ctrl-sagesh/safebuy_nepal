import 'package:flutter_test/flutter_test.dart';
import 'package:safebuy_nepal/agents/safeguard/safeguard_intent_classifier.dart';

void main() {
  group('SafeguardIntentClassifier', () {
    // ── Greet ──────────────────────────────────────────────────────
    test('classifies "hello" as greet', () {
      final r = SafeguardIntentClassifier.classify('hello', 'en');
      expect(r.intent, SafeguardIntent.greet);
    });

    test('classifies "namaste" as greet', () {
      final r = SafeguardIntentClassifier.classify('namaste', 'ne');
      expect(r.intent, SafeguardIntent.greet);
    });

    test('classifies "नमस्ते" as greet', () {
      final r = SafeguardIntentClassifier.classify('नमस्ते', 'ne');
      expect(r.intent, SafeguardIntent.greet);
    });

    test('classifies "hi" as greet', () {
      final r = SafeguardIntentClassifier.classify('hi', 'en');
      expect(r.intent, SafeguardIntent.greet);
    });

    // ── Seller queries ─────────────────────────────────────────────
    test('classifies phone number as askAboutSeller', () {
      final r = SafeguardIntentClassifier.classify(
          'is 9841234567 safe?', 'en');
      expect(r.intent, SafeguardIntent.askAboutSeller);
      expect(r.extractedPhone, '9841234567');
    });

    test('classifies @handle as askAboutSeller', () {
      final r = SafeguardIntentClassifier.classify(
          'check @tiktokseller', 'en');
      expect(r.intent, SafeguardIntent.askAboutSeller);
      expect(r.extractedHandle, 'tiktokseller');
    });

    test('classifies "this seller" as askAboutSeller', () {
      final r = SafeguardIntentClassifier.classify(
          'is this seller legit', 'en');
      expect(r.intent, SafeguardIntent.askAboutSeller);
    });

    // ── Trust score ────────────────────────────────────────────────
    test('classifies trust score question', () {
      final r = SafeguardIntentClassifier.classify(
          'how is trust score calculated', 'en');
      expect(r.intent, SafeguardIntent.askTrustScore);
    });

    test('classifies Nepali trust score question', () {
      final r = SafeguardIntentClassifier.classify(
          'विश्वास स्कोर कसरी गणना हुन्छ', 'ne');
      expect(r.intent, SafeguardIntent.askTrustScore);
    });

    // ── How to report ──────────────────────────────────────────────
    test('classifies report question', () {
      final r = SafeguardIntentClassifier.classify(
          'how do I report a scam', 'en');
      expect(r.intent, SafeguardIntent.askHowToReport);
    });

    test('classifies "my report" as reportHelp', () {
      final r = SafeguardIntentClassifier.classify(
          'where is my report', 'en');
      expect(r.intent, SafeguardIntent.reportHelp);
    });

    // ── Scam types ─────────────────────────────────────────────────
    test('classifies scam types question', () {
      final r = SafeguardIntentClassifier.classify(
          'what are common scam types', 'en');
      expect(r.intent, SafeguardIntent.askAboutScamTypes);
    });

    // ── ETA / legal ────────────────────────────────────────────────
    test('classifies legal question', () {
      final r = SafeguardIntentClassifier.classify(
          'tell me about the electronic transactions act', 'en');
      expect(r.intent, SafeguardIntent.askAboutETA);
    });

    // ── eSewa ──────────────────────────────────────────────────────
    test('classifies eSewa question', () {
      final r = SafeguardIntentClassifier.classify(
          'is esewa payment safe', 'en');
      expect(r.intent, SafeguardIntent.askAbouteSewa);
    });

    // ── TikTok ─────────────────────────────────────────────────────
    test('classifies TikTok question', () {
      final r = SafeguardIntentClassifier.classify(
          'how to buy safely from tiktok', 'en');
      expect(r.intent, SafeguardIntent.askAboutTikTok);
    });

    // ── Refund ─────────────────────────────────────────────────────
    test('classifies refund question', () {
      final r = SafeguardIntentClassifier.classify(
          'how to get my money back', 'en');
      expect(r.intent, SafeguardIntent.askAboutRefund);
    });

    // ── Seller defense ─────────────────────────────────────────────
    test('classifies seller defense', () {
      final r = SafeguardIntentClassifier.classify(
          'this is a false report against me', 'en');
      expect(r.intent, SafeguardIntent.sellerDefense);
    });

    // ── Platform ───────────────────────────────────────────────────
    test('classifies platform question', () {
      final r = SafeguardIntentClassifier.classify(
          'what is safebuy nepal', 'en');
      expect(r.intent, SafeguardIntent.askAboutPlatform);
    });

    // ── Verify ─────────────────────────────────────────────────────
    test('classifies verify question', () {
      final r = SafeguardIntentClassifier.classify(
          'how to verify before buying', 'en');
      expect(r.intent, SafeguardIntent.askHowToVerify);
    });

    // ── Register ───────────────────────────────────────────────────
    test('classifies register question', () {
      final r = SafeguardIntentClassifier.classify(
          'how to register my business', 'en');
      expect(r.intent, SafeguardIntent.askHowToRegister);
    });

    // ── Unknown ────────────────────────────────────────────────────
    test('classifies gibberish as unknown', () {
      final r = SafeguardIntentClassifier.classify(
          'asdfghjkl qwerty', 'en');
      expect(r.intent, SafeguardIntent.unknown);
    });

    // ── Phone extraction ───────────────────────────────────────────
    test('extracts Nepal phone number from text', () {
      final r = SafeguardIntentClassifier.classify(
          'check seller 9876543210', 'en');
      expect(r.extractedPhone, '9876543210');
    });

    test('does not extract non-Nepal phone', () {
      final r = SafeguardIntentClassifier.classify(
          'call 1234567890', 'en');
      expect(r.extractedPhone, isNull);
    });

    // ── Handle extraction ──────────────────────────────────────────
    test('extracts handle from @mention', () {
      final r = SafeguardIntentClassifier.classify(
          'is @shopnepal safe', 'en');
      expect(r.extractedHandle, 'shopnepal');
    });

    test('no handle if no @', () {
      final r = SafeguardIntentClassifier.classify(
          'is this shop safe', 'en');
      expect(r.extractedHandle, isNull);
    });
  });
}
