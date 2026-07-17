import 'package:flutter/foundation.dart';

/// Central app configuration + demo helpers.
///
/// `showDemoFeatures` is true only in debug builds — release APKs never
/// show the seed-data button or demo quick-search chips.
class AppConfig {
  AppConfig._();

  /// True unless the app is launched with --dart-define=FLUTTER_ENV=production.
  static const bool isProduction = bool.fromEnvironment(
        'FLUTTER_ENV',
        defaultValue: false,
      ) ==
      false;

  /// Demo-only affordances (seed data, quick-search chips) — debug builds only.
  static const bool showDemoFeatures = kDebugMode;

  static const String appVersion = '1.1.0';
  static const String buildNumber = '2';

  // Demo seller phone numbers for the thesis quick-search demo.
  static const String demoTrustedSeller = '9841234567'; // Priya Fashions (87)
  static const String demoUnverifiedSeller =
      '9861234569'; // Sunset Cosmetics (64)
  static const String demoHighRiskSeller =
      '9881234571'; // FastDeal Nepal (18)
}
