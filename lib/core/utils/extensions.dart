import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// SafeBuy Nepal — Dart/Flutter Extension Methods

// ── String ────────────────────────────────────────────────────────────────────
extension StringX on String {
  /// Strip leading @
  String get withoutAt => startsWith('@') ? substring(1) : this;

  /// Capitalise first letter only
  String get capitalised =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Truncate with ellipsis
  String truncate(int maxLength) =>
      length > maxLength ? '${substring(0, maxLength)}…' : this;

  /// Returns true if this looks like a Nepal phone number
  bool get isNepaliPhone {
    final d = replaceAll(RegExp(r'\D'), '');
    return d.length == 10 && (d.startsWith('97') || d.startsWith('98'));
  }
}

// ── Nullable String ───────────────────────────────────────────────────────────
extension NullableStringX on String? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
  String get orEmpty => this ?? '';
}

// ── DateTime ──────────────────────────────────────────────────────────────────
extension DateTimeX on DateTime {
  /// "14 May 2026"
  String get formatted => DateFormat('dd MMM yyyy').format(this);

  /// "14 May 2026, 10:30 AM"
  String get formattedWithTime => DateFormat('dd MMM yyyy, hh:mm a').format(this);

  /// "2 days ago" / "3 months ago"
  String get timeAgo {
    final diff = DateTime.now().difference(this);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  /// Is in the past?
  bool get isPast => isBefore(DateTime.now());
}

// ── Double (NPR formatting) ────────────────────────────────────────────────────
extension DoubleX on double {
  /// "NPR 1,500"
  String get npr {
    final f = NumberFormat('#,##0', 'en_IN');
    return 'NPR ${f.format(this)}';
  }

  /// "₹1,500" (rupee symbol variant)
  String get inrFormat {
    final f = NumberFormat('#,##0', 'en_IN');
    return '₹${f.format(this)}';
  }

  /// Clamp between 0 and 100 and format as "XX.X"
  String get trustScoreDisplay =>
      clamp(0, 100).toStringAsFixed(1);
}

// ── Int ───────────────────────────────────────────────────────────────────────
extension IntX on int {
  /// "1,234"
  String get formatted => NumberFormat('#,##0').format(this);
}

// ── BuildContext ──────────────────────────────────────────────────────────────
extension BuildContextX on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  bool get isSmallScreen => screenWidth < 360;
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
