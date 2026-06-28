import 'package:flutter/foundation.dart';

/// SafeBuy Nepal — Analytics wrapper.
///
/// In production this would forward to Firebase Analytics. Since we have
/// not added `firebase_analytics` to pubspec yet, all events are logged
/// to debugPrint in debug mode and silently no-op in release.
///
/// IMPORTANT: Never log personally identifying information (PII) such as
/// phone numbers, eSewa IDs, or seller handles. Only log categorical data.
abstract final class AnalyticsService {
  static void _log(String event, [Map<String, Object?>? params]) {
    if (!kDebugMode) return;
    final paramStr = params == null || params.isEmpty
        ? ''
        : ' ${params.entries.map((e) => '${e.key}=${e.value}').join(' ')}';
    debugPrint('📊 Analytics: $event$paramStr');
  }

  /// User searched for a seller. searchType is one of: phone, esewa, tiktok,
  /// instagram. The actual identifier is NEVER logged.
  static void logSellerSearched(String searchType) =>
      _log('seller_searched', {'search_type': searchType});

  /// User viewed a seller profile. trustVerdict: trusted/unverified/high_risk.
  static void logSellerProfileViewed(String trustVerdict) =>
      _log('seller_profile_viewed', {'trust_verdict': trustVerdict});

  /// User submitted a fraud report.
  static void logReportSubmitted(String incidentType, String platform) =>
      _log('report_submitted', {
        'incident_type': incidentType,
        'platform': platform,
      });

  /// User registered a business.
  static void logBusinessRegistered(String category) =>
      _log('business_registered', {'category': category});

  /// Chatbot opened.
  static void logChatbotUsed() => _log('chatbot_used');

  /// Onboarding finished.
  static void logOnboardingCompleted() => _log('onboarding_completed');

  /// Language selected on first launch.
  static void logLanguageSelected(String language) =>
      _log('language_selected', {'language': language});

  /// OTP verification succeeded.
  static void logAuthSuccess() => _log('auth_success');

  /// Evidence file uploaded for a report.
  static void logEvidenceUploaded(int evidenceCount) =>
      _log('report_evidence_uploaded', {'count': evidenceCount});

  /// Admin took moderation action.
  static void logAdminAction(String action) =>
      _log('admin_action', {'action': action});
}
