/// Legacy color constants (int-based) for backward compatibility.
/// New code should use lib/core/theme/app_colors.dart (Color-based) instead.
class AppColors {
  static const primary = 0xFF1565C0;
  static const secondary = 0xFF1976D2;
  static const accent = 0xFFFF8F00;
  static const trusted = 0xFF00C853;
  static const unverified = 0xFFFF8F00;
  static const highRisk = 0xFFD32F2F;
  static const background = 0xFFF5F7FA;
  static const white = 0xFFFFFFFF;
  static const textDark = 0xFF0A1628;
  static const textGrey = 0xFF4A5568;
  static const cardBg = 0xFFFFFFFF;
  static const divider = 0xFFE2E8F0;
  static const gradStart = 0xFF0D47A1;
  static const gradEnd = 0xFF1976D2;
}

class AppConstants {
  static const appName = 'SafeBuy Nepal';
  static const tagline = 'Buy Smart. Stay Safe.';
  static const searchHint = 'Search by phone, eSewa ID, or username...';
  static const trusted = 'Trusted';
  static const unverified = 'Unverified';
  static const highRisk = 'High Risk';
}

class TrustThreshold {
  static const trusted = 80;
  static const unverified = 50;
}

class Platforms {
  static const list = [
    'TikTok',
    'Instagram',
    'Facebook',
    'WhatsApp',
    'Viber',
    'Other',
  ];
}

class BusinessTypes {
  static const list = [
    'Clothing & Fashion',
    'Electronics & Gadgets',
    'Cosmetics & Beauty',
    'Food & Beverages',
    'Handmade & Crafts',
    'Books & Stationery',
    'Health & Wellness',
    'Home & Decor',
    'Sports & Fitness',
    'Other',
  ];
}

class ReportTypes {
  static const list = [
    'no_delivery',
    'wrong_item',
    'fake_product',
    'payment_issue',
    'impersonation',
    'other',
  ];

  /// Human-readable label for an incident-type key.
  static String label(String key) {
    const map = {
      'no_delivery': 'Item Not Delivered',
      'wrong_item': 'Wrong Item Sent',
      'fake_product': 'Fake / Counterfeit Product',
      'payment_issue': 'Paid, No Response',
      'impersonation': 'Account Impersonation',
      'other': 'Other',
    };
    return map[key] ?? key;
  }
}
