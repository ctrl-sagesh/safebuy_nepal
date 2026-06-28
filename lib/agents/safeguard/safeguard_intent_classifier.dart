/// All intents the SafeGuard AI agent can classify.
enum SafeguardIntent {
  greet,
  askAboutSeller,
  askTrustScore,
  askHowToReport,
  askHowToVerify,
  askHowToRegister,
  askAboutScamTypes,
  askAboutPlatform,
  askAboutEvidence,
  askAboutETA,
  askAbouteSewa,
  askAboutTikTok,
  askAboutRefund,
  reportHelp,
  sellerDefense,
  unknown,
}

/// Rule-based intent classifier using keyword matching.
///
/// No external APIs. Fully offline. Academically explainable:
/// checks intent rules in priority order and returns the first match.
class SafeguardIntentClassifier {
  /// Classify [input] and return the best matching intent.
  /// Also extracts phone number or handle if found.
  static ({SafeguardIntent intent, String? extractedPhone, String? extractedHandle})
      classify(String input, String language) {
    final lower = input.toLowerCase().trim();
    final words = lower
        .replaceAll(RegExp(r'[^\w\s@]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toSet();

    // Extract phone and handle for potential seller queries
    final phoneMatch = RegExp(r'9[78]\d{8}').firstMatch(lower);
    final handleMatch = RegExp(r'@(\w+)').firstMatch(lower);
    final extractedPhone = phoneMatch?.group(0);
    final extractedHandle = handleMatch?.group(1);

    // 1. Greet detection
    const greetKeywords = {
      'hello', 'hi', 'namaste', 'hey', 'good morning',
      'good evening', 'sup', 'yo',
    };
    const greetNe = {'नमस्ते', 'नमस्कार', 'हेलो', 'हाय', 'सुप्रभात'};
    if (_hasAny(words, greetKeywords) || _containsAny(lower, greetNe)) {
      // Only if it's mostly a greeting (short input)
      if (words.length <= 4) {
        return (intent: SafeguardIntent.greet, extractedPhone: extractedPhone, extractedHandle: extractedHandle);
      }
    }

    // 2. Seller-specific detection (phone number, handle, or seller keywords)
    if (extractedPhone != null || extractedHandle != null) {
      return (intent: SafeguardIntent.askAboutSeller, extractedPhone: extractedPhone, extractedHandle: extractedHandle);
    }
    const sellerKeywords = {
      'seller', 'this seller', 'seller ko', 'safebuy search',
    };
    const sellerNe = {'यो seller', 'विक्रेता', 'यो विक्रेता'};
    if (_containsAny(lower, sellerKeywords) || _containsAny(lower, sellerNe)) {
      return (intent: SafeguardIntent.askAboutSeller, extractedPhone: extractedPhone, extractedHandle: extractedHandle);
    }

    // 3. Trust score questions
    const trustKeywords = {
      'trust score', 'trust', 'score', 'calculate', 'how score',
      'score kaise',
    };
    const trustNe = {'कसरी', 'score कति', 'भरोसा', 'विश्वास स्कोर'};
    if (_containsAny(lower, trustKeywords) || _containsAny(lower, trustNe)) {
      if (lower.contains('trust') || lower.contains('score') ||
          _containsAny(lower, trustNe)) {
        return (intent: SafeguardIntent.askTrustScore, extractedPhone: null, extractedHandle: null);
      }
    }

    // 4. Seller defense (check before report to avoid conflict)
    const defenseKeywords = {
      'dispute', 'false report', 'wrong report', 'not true',
      'defend', 'my side',
    };
    const defenseNe = {'गलत रिपोर्ट', 'झुटो', 'मेरो पक्ष'};
    if (_containsAny(lower, defenseKeywords) || _containsAny(lower, defenseNe)) {
      return (intent: SafeguardIntent.sellerDefense, extractedPhone: null, extractedHandle: null);
    }

    // 5. How to report
    const reportKeywords = {
      'report', 'complain', 'complaint', 'scam report', 'file',
      'kaise report',
    };
    const reportNe = {'रिपोर्ट', 'उजुरी', 'कसरी report'};
    if (_containsAny(lower, reportKeywords) || _containsAny(lower, reportNe)) {
      // Exclude "my report" / "my complaint" (those are report help)
      if (lower.contains('my report') || lower.contains('my complaint') ||
          lower.contains('मेरो रिपोर्ट')) {
        return (intent: SafeguardIntent.reportHelp, extractedPhone: null, extractedHandle: null);
      }
      return (intent: SafeguardIntent.askHowToReport, extractedPhone: null, extractedHandle: null);
    }

    // 6. How to verify
    const verifyKeywords = {
      'verify', 'check', 'search', 'find seller', 'kaise check',
      'before buying',
    };
    const verifyNe = {'कसरी खोज्ने', 'seller check', 'जाँच'};
    if (_containsAny(lower, verifyKeywords) || _containsAny(lower, verifyNe)) {
      return (intent: SafeguardIntent.askHowToVerify, extractedPhone: null, extractedHandle: null);
    }

    // 7. How to register
    const registerKeywords = {
      'register', 'registration', 'my business', 'add my shop',
      'seller ban',
    };
    const registerNe = {'दर्ता', 'व्यवसाय', 'दर्ता गर्ने'};
    if (_containsAny(lower, registerKeywords) || _containsAny(lower, registerNe)) {
      return (intent: SafeguardIntent.askHowToRegister, extractedPhone: null, extractedHandle: null);
    }

    // 8. Scam types
    const scamKeywords = {
      'scam type', 'fraud type', 'common scam', 'what scam',
      'kaise fraud',
    };
    const scamNe = {'ठगी', 'ठगीका प्रकार', 'किन fraud'};
    if (_containsAny(lower, scamKeywords) || _containsAny(lower, scamNe)) {
      return (intent: SafeguardIntent.askAboutScamTypes, extractedPhone: null, extractedHandle: null);
    }

    // 9. Platform questions
    const platformKeywords = {
      'what is safebuy', 'about safebuy', 'safebuy kya',
      'what does', 'how does safebuy',
    };
    const platformNe = {'safebuy Nepal ke ho', 'safebuy के हो'};
    if (_containsAny(lower, platformKeywords) || _containsAny(lower, platformNe)) {
      return (intent: SafeguardIntent.askAboutPlatform, extractedPhone: null, extractedHandle: null);
    }

    // 10. Evidence questions
    const evidenceKeywords = {
      'evidence', 'proof', 'screenshot', 'keep', 'save',
      'what to keep',
    };
    const evidenceNe = {'प्रमाण', 'screenshot राख्ने', 'प्रमाण के'};
    if (_containsAny(lower, evidenceKeywords) || _containsAny(lower, evidenceNe)) {
      return (intent: SafeguardIntent.askAboutEvidence, extractedPhone: null, extractedHandle: null);
    }

    // 11. ETA / legal
    const etaKeywords = {
      'law', 'legal', 'police', 'eta', 'electronic transactions',
      'act', 'cybercrime',
    };
    const etaNe = {'कानून', 'प्रहरी', 'साइबर'};
    if (_containsAny(lower, etaKeywords) || _containsAny(lower, etaNe)) {
      return (intent: SafeguardIntent.askAboutETA, extractedPhone: null, extractedHandle: null);
    }

    // 12. eSewa questions
    const esewaKeywords = {
      'esewa', 'khalti', 'payment', 'wallet', 'digital payment',
      'esewa safe',
    };
    const esewaNe = {'पैसा', 'payment kaise', 'इसेवा'};
    if (_containsAny(lower, esewaKeywords) || _containsAny(lower, esewaNe)) {
      return (intent: SafeguardIntent.askAbouteSewa, extractedPhone: null, extractedHandle: null);
    }

    // 13. TikTok scam questions
    const tiktokKeywords = {
      'tiktok', 'tik tok', 'tiktok scam', 'tiktok seller',
      'tiktok shop',
    };
    if (_containsAny(lower, tiktokKeywords)) {
      return (intent: SafeguardIntent.askAboutTikTok, extractedPhone: null, extractedHandle: null);
    }

    // 14. Refund questions
    const refundKeywords = {
      'refund', 'money back', 'paise wapas', 'return money',
      'kaise wapas',
    };
    const refundNe = {'पैसा फिर्ता', 'रिफन्ड', 'पैसा कसरी फिर्ता'};
    if (_containsAny(lower, refundKeywords) || _containsAny(lower, refundNe)) {
      return (intent: SafeguardIntent.askAboutRefund, extractedPhone: null, extractedHandle: null);
    }

    // 15. Report help (confused user)
    const helpKeywords = {'help', 'confused', 'stuck', 'how to', 'guide'};
    const helpNe = {'मद्दत', 'कसरी', 'बुझिन'};
    if (_containsAny(lower, helpKeywords) || _containsAny(lower, helpNe)) {
      return (intent: SafeguardIntent.reportHelp, extractedPhone: null, extractedHandle: null);
    }

    // 16. Unknown
    return (intent: SafeguardIntent.unknown, extractedPhone: null, extractedHandle: null);
  }

  /// Check if any of [keywords] exist in [words] set.
  static bool _hasAny(Set<String> words, Set<String> keywords) {
    return words.any((w) => keywords.contains(w));
  }

  /// Check if [text] contains any of the [phrases].
  static bool _containsAny(String text, Set<String> phrases) {
    return phrases.any((p) => text.contains(p));
  }
}
