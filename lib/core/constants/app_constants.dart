/// SafeBuy Nepal — Global Application Constants
abstract final class AppConstants {
  // ── App meta ──────────────────────────────────────────────────────────────────
  static const String appName    = 'SafeBuy Nepal';
  static const String appVersion = '1.0.0';

  // ── Trust score thresholds ────────────────────────────────────────────────────
  static const double trustTrusted    = 80.0;
  static const double trustUnverified = 50.0;

  // ── Firestore collection names ────────────────────────────────────────────────
  static const String colSellers      = 'sellers';
  static const String colReports      = 'reports';
  static const String colReviews      = 'reviews';
  static const String colUsers        = 'users';
  static const String colAdminAudit   = 'admin_audit_log';
  static const String colAdminActions = 'admin_actions';

  // ── SharedPreferences keys ─────────────────────────────────────────────────────
  static const String prefLanguage        = 'language';
  static const String prefOnboardingDone  = 'onboarding_done';
  static const String prefSearchHistory   = 'search_history';
  static const String prefCachedSellers   = 'cached_sellers';

  // ── Validation limits ─────────────────────────────────────────────────────────
  static const int phoneLength          = 10;
  static const int minDescriptionChars  = 50;
  static const int maxDescriptionChars  = 500;
  static const int maxBusinessNameChars = 60;
  static const int minBusinessNameChars = 3;
  static const int maxResponseChars     = 500;
  static const int maxSearchHistory     = 10;
  static const int maxCachedSellers     = 20;

  // ── Report rate limiting ──────────────────────────────────────────────────────
  static const int maxReportsPerSellerPerDays = 3;
  static const int reportRateLimitDays        = 7;

  // ── Pagination ────────────────────────────────────────────────────────────────
  static const int searchPageSize  = 10;
  static const int reviewPageSize  = 10;
  static const int reportPageSize  = 10;
  static const int activityPageSize = 20;

  // ── Upload limits ─────────────────────────────────────────────────────────────
  static const int maxFileSizeMb    = 5;
  static const int maxFileSizeBytes = maxFileSizeMb * 1024 * 1024;
  static const int imageMaxWidth    = 800;
  static const int imageQuality     = 75;

  // ── Timings ───────────────────────────────────────────────────────────────────
  static const int searchDebounceMs    = 500;
  static const int otpTimeoutSeconds   = 60;
  static const int splashDurationMs    = 2000;
  static const int snackbarDurationMs  = 3000;

  // ── Default starting trust score for new sellers ──────────────────────────────
  static const double newSellerScore = 50.0;

  // ── Review authenticity penalties ─────────────────────────────────────────────
  static const double authPenaltyNewAccount   = 0.3; // account < 7 days
  static const double authPenaltyReviewSpam   = 0.2; // 3+ reviews in 24h
  static const double authPenaltyShortReview  = 0.2; // text < 20 chars

  // ── Anti-bot review protection ───────────────────────────────────────────────
  static const int maxReviewsPerDay           = 3;   // max reviews a user can post in 24h
  static const int maxReviewsPerSellerPerUser = 1;   // one review per seller per user
  static const int minAccountAgeDays          = 7;   // account must be ≥7 days old
  static const int minReviewChars             = 20;  // minimum review text length
  static const double textSimilarityThreshold = 0.85; // Jaccard sim above this = suspected bot
  static const int reviewCooldownHours        = 1;   // min gap between reviews

  // ── Platform identifiers ──────────────────────────────────────────────────────
  static const List<String> platforms = [
    'TikTok',
    'Instagram',
    'Facebook',
    'WhatsApp',
    'Viber',
    'Other'
  ];

  // ── Incident types ────────────────────────────────────────────────────────────
  static const List<String> incidentTypes = [
    'no_delivery',
    'wrong_item',
    'fake_product',
    'payment_issue',
    'impersonation',
    'other',
  ];

  // ── Business categories ───────────────────────────────────────────────────────
  static const List<String> businessCategories = [
    'Clothing & Fashion',
    'Electronics',
    'Cosmetics & Beauty',
    'Food & Beverages',
    'Handmade Crafts',
    'Books & Stationery',
    'Home & Living',
    'Sports & Fitness',
    'Health & Wellness',
    'Other',
  ];
}
