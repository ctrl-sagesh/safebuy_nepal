import '../constants/app_constants.dart';

/// SafeBuy Nepal — Input Validators
/// All validator methods return null on success, or an error string on failure.
abstract final class Validators {
  // ── Phone ─────────────────────────────────────────────────────────────────────
  /// Nepal mobile number: exactly 10 digits, starts with 97 or 98.
  static String? nepaliPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final digits = value.trim().replaceAll(RegExp(r'\D'), '');
    if (digits.length != AppConstants.phoneLength) {
      return 'Enter a valid 10-digit Nepal phone number';
    }
    if (!digits.startsWith('97') && !digits.startsWith('98')) {
      return 'Phone must start with 97 or 98';
    }
    return null;
  }

  static String? nepaliPhoneNe(String? value) {
    if (value == null || value.trim().isEmpty) return 'फोन नम्बर आवश्यक छ';
    final digits = value.trim().replaceAll(RegExp(r'\D'), '');
    if (digits.length != AppConstants.phoneLength) return 'वैध १०-अंकको नेपाल फोन नम्बर लेख्नुहोस्';
    if (!digits.startsWith('97') && !digits.startsWith('98')) return 'फोन ९७ वा ९८ बाट सुरु हुनुपर्छ';
    return null;
  }

  // ── Required ──────────────────────────────────────────────────────────────────
  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // ── Min length ────────────────────────────────────────────────────────────────
  static String? minLength(String? value, int min, [String? label]) {
    if (value == null || value.trim().length < min) {
      return '${label ?? 'This field'} must be at least $min characters';
    }
    return null;
  }

  // ── Max length ────────────────────────────────────────────────────────────────
  static String? maxLength(String? value, int max, [String? label]) {
    if (value != null && value.trim().length > max) {
      return '${label ?? 'This field'} must be at most $max characters';
    }
    return null;
  }

  // ── Description (min 50) ──────────────────────────────────────────────────────
  static String? reportDescription(String? value, [String lang = 'en']) {
    if (value == null || value.trim().isEmpty) {
      return lang == 'ne' ? 'विवरण आवश्यक छ' : 'Description is required';
    }
    if (value.trim().length < AppConstants.minDescriptionChars) {
      return lang == 'ne'
          ? 'कम्तीमा ${AppConstants.minDescriptionChars} अक्षर लेख्नुहोस्'
          : 'Minimum ${AppConstants.minDescriptionChars} characters required';
    }
    return null;
  }

  // ── Amount (positive number) ──────────────────────────────────────────────────
  static String? positiveAmount(String? value, [String lang = 'en']) {
    if (value == null || value.trim().isEmpty) {
      return lang == 'ne' ? 'रकम लेख्नुहोस्' : 'Amount is required';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed < 1) {
      return lang == 'ne'
          ? 'वैध रकम लेख्नुहोस् (कम्तीमा १ रु)'
          : 'Enter a valid amount (minimum NPR 1)';
    }
    return null;
  }

  // ── Business name ─────────────────────────────────────────────────────────────
  static String? businessName(String? value, [String lang = 'en']) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return lang == 'ne' ? 'व्यवसायको नाम आवश्यक छ' : 'Business name is required';
    }
    if (v.length < AppConstants.minBusinessNameChars) {
      return lang == 'ne'
          ? 'कम्तीमा ${AppConstants.minBusinessNameChars} अक्षर'
          : 'Minimum ${AppConstants.minBusinessNameChars} characters';
    }
    if (v.length > AppConstants.maxBusinessNameChars) {
      return lang == 'ne'
          ? 'बढीमा ${AppConstants.maxBusinessNameChars} अक्षर'
          : 'Maximum ${AppConstants.maxBusinessNameChars} characters';
    }
    return null;
  }

  // ── Social handle (strip @ if present) ───────────────────────────────────────
  static String stripAtPrefix(String handle) =>
      handle.startsWith('@') ? handle.substring(1) : handle;

  // ── eSewa / Khalti ID ─────────────────────────────────────────────────────────
  /// eSewa IDs in Nepal are typically 10-digit numbers (same as phone).
  static String? esewaId(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final digits = value.trim().replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) {
      return 'Enter a valid eSewa / Khalti ID (10 digits)';
    }
    return null;
  }

  // ── Email ─────────────────────────────────────────────────────────────────────
  static String? email(String? value, [String lang = 'en']) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return lang == 'ne' ? 'इमेल आवश्यक छ' : 'Email is required';
    }
    final ok = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(v);
    if (!ok) {
      return lang == 'ne' ? 'वैध इमेल लेख्नुहोस्' : 'Enter a valid email address';
    }
    return null;
  }

  // ── Full name ─────────────────────────────────────────────────────────────────
  static String? fullName(String? value, [String lang = 'en']) {
    if (value == null || value.trim().length < 2) {
      return lang == 'ne' ? 'पूरा नाम लेख्नुहोस्' : 'Enter your full name';
    }
    return null;
  }

  // ── PAN number (Nepal: exactly 9 digits) ─────────────────────────────────────
  static String? panNumber(String? value, [String lang = 'en']) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return lang == 'ne' ? 'PAN नम्बर आवश्यक छ' : 'PAN number is required';
    }
    if (!RegExp(r'^\d{9}$').hasMatch(v)) {
      return lang == 'ne'
          ? 'PAN नम्बर ठीक ९ अंकको हुनुपर्छ'
          : 'PAN number must be exactly 9 digits';
    }
    return null;
  }

  // ── Gmail address ─────────────────────────────────────────────────────────────
  static String? gmail(String? value, [String lang = 'en']) {
    final v = value?.trim().toLowerCase() ?? '';
    if (v.isEmpty) {
      return lang == 'ne' ? 'Gmail आवश्यक छ' : 'Gmail address is required';
    }
    if (!RegExp(r'^[\w.+-]+@gmail\.com$').hasMatch(v)) {
      return lang == 'ne'
          ? 'वैध Gmail ठेगाना लेख्नुहोस्'
          : 'Please enter a valid Gmail address';
    }
    return null;
  }

  // ── OTP (6 digits) ────────────────────────────────────────────────────────────
  static String? otp(String? value, [String lang = 'en']) {
    final v = value?.trim() ?? '';
    if (v.length != 6 || !RegExp(r'^\d{6}$').hasMatch(v)) {
      return lang == 'ne'
          ? 'कृपया सबै ६ अंक लेख्नुहोस्'
          : 'Please enter all 6 digits';
    }
    return null;
  }

  // ── Social handle (no spaces) ─────────────────────────────────────────────────
  static String? socialHandle(String? value, [String lang = 'en']) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null; // optional
    if (v.contains(' ')) {
      return lang == 'ne'
          ? 'ह्यान्डलमा स्पेस राख्न मिल्दैन (@ स्वतः थपिन्छ)'
          : 'Enter handle without spaces (@ will be added automatically)';
    }
    return null;
  }

  // ── HTML sanitize (strips tags before Firestore writes) ───────────────────────
  static String sanitize(String input) =>
      input.replaceAll(RegExp(r'<[^>]*>'), '').trim();

  // ── Combine validators ────────────────────────────────────────────────────────
  static String? Function(String?) combine(
    List<String? Function(String?)> validators,
  ) {
    return (value) {
      for (final v in validators) {
        final result = v(value);
        if (result != null) return result;
      }
      return null;
    };
  }
}
