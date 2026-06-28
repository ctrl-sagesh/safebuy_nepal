import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

enum ButtonVariant { primary, secondary, destructive, text }

/// SafeBuy Nepal — Design System Button
/// Supports primary, secondary, destructive, and text variants.
/// All variants enforce minimum 48px tap target height.
class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.lang = 'en',
  });

  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final String lang;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: AppSpacing.minTapTarget,
      child: _buildButton(),
    );
  }

  Widget _buildButton() {
    switch (variant) {
      case ButtonVariant.primary:
        return ElevatedButton(
          onPressed: (isLoading || onPressed == null) ? null : _handleTap,
          child: _buildChild(AppColors.textOnDark),
        );
      case ButtonVariant.secondary:
        return OutlinedButton(
          onPressed: (isLoading || onPressed == null) ? null : _handleTap,
          child: _buildChild(AppColors.primary),
        );
      case ButtonVariant.destructive:
        return ElevatedButton(
          onPressed: (isLoading || onPressed == null) ? null : _handleTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.highRisk,
            foregroundColor: AppColors.textOnDark,
            disabledBackgroundColor: AppColors.grey200,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
          child: _buildChild(AppColors.textOnDark),
        );
      case ButtonVariant.text:
        return TextButton(
          onPressed: (isLoading || onPressed == null) ? null : _handleTap,
          child: _buildChild(AppColors.primary),
        );
    }
  }

  Widget _buildChild(Color color) {
    if (isLoading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: color,
        ),
      );
    }
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: AppTextStyles.button(lang: lang).copyWith(color: color)),
        ],
      );
    }
    return Text(
      label,
      style: AppTextStyles.button(lang: lang).copyWith(color: color),
    );
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    onPressed?.call();
  }
}
