import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// SafeBuy Nepal — centralised popup / feedback system.
/// Every user action that can fail or succeed must surface through one of
/// these helpers. No silent failures anywhere in the app.
abstract final class PopupHelper {
  // ── SnackBars ────────────────────────────────────────────────────────────────

  static void showSuccess(BuildContext context, String message) {
    HapticFeedback.heavyImpact();
    _showSnack(
      context,
      message: message,
      background: AppColors.trusted,
      foreground: Colors.white,
      icon: Icons.check_circle_rounded,
      duration: const Duration(seconds: 3),
    );
  }

  static void showError(BuildContext context, String message) {
    HapticFeedback.vibrate();
    _showSnack(
      context,
      message: message,
      background: AppColors.error,
      foreground: Colors.white,
      icon: Icons.error_rounded,
      duration: const Duration(seconds: 4),
      shake: true,
    );
  }

  static void showWarning(BuildContext context, String message) {
    HapticFeedback.mediumImpact();
    _showSnack(
      context,
      message: message,
      background: const Color(0xFFFFC107),
      foreground: const Color(0xFF3A2E00),
      icon: Icons.warning_amber_rounded,
      duration: const Duration(seconds: 3),
    );
  }

  static void showInfo(BuildContext context, String message) {
    _showSnack(
      context,
      message: message,
      background: AppColors.primary,
      foreground: Colors.white,
      icon: Icons.info_rounded,
      duration: const Duration(seconds: 3),
    );
  }

  static void _showSnack(
    BuildContext context, {
    required String message,
    required Color background,
    required Color foreground,
    required IconData icon,
    required Duration duration,
    bool shake = false,
  }) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: background,
        duration: duration,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: _SnackContent(
          icon: icon,
          message: message,
          foreground: foreground,
          shake: shake,
        ),
      ),
    );
  }

  // ── Confirm dialog ───────────────────────────────────────────────────────────

  static Future<void> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required VoidCallback onConfirm,
    String cancelLabel = 'Cancel',
    bool isDangerous = false,
  }) {
    HapticFeedback.mediumImpact();
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.55,
            color: AppColors.textSecondary,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 44),
              foregroundColor: AppColors.grey500,
              side: const BorderSide(color: AppColors.borderMedium),
              padding: const EdgeInsets.symmetric(horizontal: 18),
            ),
            child: Text(cancelLabel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 44),
              backgroundColor:
                  isDangerous ? AppColors.error : AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 18),
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  // ── Loading dialog ───────────────────────────────────────────────────────────

  static void showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 3.5,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void hideLoadingDialog(BuildContext context) {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  // ── Bottom sheets ────────────────────────────────────────────────────────────

  static Future<T?> showBottomSheet<T>(BuildContext context, Widget child) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderMedium,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }

  /// Special auth-gate sheet shown when a guest taps a restricted feature.
  static Future<void> showAuthGateBottomSheet(BuildContext context) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
            24, 12, 24, MediaQuery.paddingOf(ctx).bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderMedium,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 18),
            Text(
              'Sign in to Continue',
              style: GoogleFonts.poppins(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'With a free SafeBuy account you can report fraud, '
              'review sellers, register your business, and track '
              'your community impact.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                height: 1.6,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(ctx, '/auth');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  child: const Text('Create Account'),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(ctx, '/auth');
                },
                child: const Text('Sign In'),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Maybe Later',
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Snack content with optional shake animation for errors.
class _SnackContent extends StatefulWidget {
  const _SnackContent({
    required this.icon,
    required this.message,
    required this.foreground,
    required this.shake,
  });

  final IconData icon;
  final String message;
  final Color foreground;
  final bool shake;

  @override
  State<_SnackContent> createState() => _SnackContentState();
}

class _SnackContentState extends State<_SnackContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  @override
  void initState() {
    super.initState();
    if (widget.shake) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        Icon(widget.icon, color: widget.foreground, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            widget.message,
            style: GoogleFonts.inter(
              color: widget.foreground,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
    if (!widget.shake) return row;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        // Damped sine wave: shakes hard then settles.
        final dx = (1 - t) * 8 * math.sin(t * 40);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: row,
    );
  }
}
