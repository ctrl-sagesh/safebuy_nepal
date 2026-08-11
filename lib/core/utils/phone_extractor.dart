/// Pulls a seller identifier (Nepali phone / eSewa ID / social handle) out
/// of arbitrary shared text — a WhatsApp message, a TikTok bio, an SMS, etc.
/// Used by the Android share-intent Quick Verify flow.
class PhoneExtractor {
  // +977 followed by a 10-digit 97/98 number (optional space or dash).
  static final _withCountryCode = RegExp(r'\+977[\s-]?(97|98)\d{8}');

  // Bare Nepali mobile: 97xxxxxxxx or 98xxxxxxxx.
  static final _nepalPhone = RegExp(r'(97|98)\d{8}');

  // Social handle: @username.
  static final _handle = RegExp(r'@[\w.]+');

  /// Returns the first usable identifier found, or null. Phone numbers are
  /// normalised to the bare 10-digit form (no +977, spaces, or dashes).
  static String? extract(String text) {
    var match = _withCountryCode.firstMatch(text);
    if (match != null) {
      return match
          .group(0)!
          .replaceAll('+977', '')
          .replaceAll(' ', '')
          .replaceAll('-', '')
          .trim();
    }

    match = _nepalPhone.firstMatch(text);
    if (match != null) return match.group(0);

    match = _handle.firstMatch(text);
    if (match != null) return match.group(0);

    return null;
  }

  /// True when [text] is a valid seller identifier: a @handle (len > 2) or a
  /// 10-digit number starting 97/98.
  static bool isValid(String? text) {
    if (text == null) return false;
    if (text.startsWith('@')) return text.length > 2;
    final digits = text.replaceAll(RegExp(r'\D'), '');
    return digits.length == 10 &&
        (digits.startsWith('97') || digits.startsWith('98'));
  }
}
