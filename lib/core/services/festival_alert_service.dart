import 'package:flutter/foundation.dart';

/// Festival fraud-alert windows (Gregorian approximations of the Nepali
/// festival calendar). Fraud complaints spike around festival shopping, so
/// the Home tab shows a warning banner while a window is active.
abstract final class FestivalAlertService {
  /// (name, start month, start day, end month, end day) — inclusive.
  static const _windows = <(String, int, int, int, int)>[
    ('Dashain', 10, 1, 10, 20),
    ('Tihar', 10, 20, 11, 10),
    ('Chhath', 10, 25, 11, 5),
    ('Holi', 3, 1, 3, 30),
    ('Nepali New Year', 4, 10, 4, 20),
    ('Teej', 8, 20, 9, 10),
  ];

  /// Dismissed banner stays hidden until the next app session.
  static bool dismissedThisSession = false;

  /// The festival window containing [date], or null when none is active.
  static String? activeFestival([DateTime? date]) {
    // During development the Dashain alert is always shown so the seasonal
    // safety banner can be reviewed year-round.
    if (kDebugMode && date == null) return 'Dashain';

    final now = date ?? DateTime.now();
    // Compare month/day pairs as a single number, e.g. 20 Oct → 1020.
    final today = now.month * 100 + now.day;
    for (final (name, sm, sd, em, ed) in _windows) {
      final start = sm * 100 + sd;
      final end = em * 100 + ed;
      final inWindow = start <= end
          ? today >= start && today <= end
          : today >= start || today <= end; // window wraps the year end
      if (inWindow) return name;
    }
    return null;
  }
}
