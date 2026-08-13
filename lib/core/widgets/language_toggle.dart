import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/language_provider.dart';
import '../theme/app_colors.dart';

/// Compact EN / ने switch for app bars. Reads and updates [languageProvider]
/// so the whole app re-renders in the chosen language. Place it in an
/// AppBar's `actions`.
class LanguageToggle extends ConsumerWidget {
  const LanguageToggle({super.key, this.onDark = false});

  /// Use lighter colours when placed on a dark/coloured app bar.
  final bool onDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);

    Widget segment(String code, String label) {
      final active = lang == code;
      final activeBg = onDark ? Colors.white : AppColors.primary;
      final activeFg = onDark ? AppColors.primary : Colors.white;
      final idleFg =
          onDark ? Colors.white.withValues(alpha: 0.85) : AppColors.textMuted;
      return GestureDetector(
        onTap: () {
          if (active) return;
          HapticFeedback.selectionClick();
          ref.read(languageProvider.notifier).setLanguage(code);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: active ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: active ? activeFg : idleFg,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: onDark
            ? Colors.white.withValues(alpha: 0.15)
            : AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: onDark
              ? Colors.white.withValues(alpha: 0.25)
              : AppColors.borderLight,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [segment('en', 'EN'), segment('ne', 'ने')],
      ),
    );
  }
}
