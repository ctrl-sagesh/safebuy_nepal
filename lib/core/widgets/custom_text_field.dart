import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// SafeBuy Nepal — Design System Text Field
/// Wraps TextFormField with consistent styling and special variants.
class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.onChanged,
    this.enabled = true,
    this.obscureText = false,
    this.textCapitalization = TextCapitalization.none,
    this.autofocus = false,
    this.showCounter = false,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool obscureText;
  final TextCapitalization textCapitalization;
  final bool autofocus;
  final bool showCounter;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: showCounter ? maxLength : null,
      inputFormatters: [
        if (maxLength != null && !showCounter)
          LengthLimitingTextInputFormatter(maxLength),
        ...?inputFormatters,
      ],
      validator: validator,
      enabled: enabled,
      obscureText: obscureText,
      textCapitalization: textCapitalization,
      autofocus: autofocus,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon,
        counterText: showCounter ? null : '',
      ),
    );
  }
}

/// Nepal phone number field with +977 prefix.
class NepalPhoneField extends StatelessWidget {
  const NepalPhoneField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      maxLength: 10,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: '98XXXXXXXX',
        counterText: '',
        prefixIcon: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          margin: const EdgeInsets.only(right: AppSpacing.sm),
          decoration: const BoxDecoration(
            border: Border(right: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🇳🇵', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                '+977',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 6-box OTP input field.
class OtpInputField extends StatefulWidget {
  const OtpInputField({
    super.key,
    required this.onCompleted,
    this.hasError = false,
  });

  final ValueChanged<String> onCompleted;
  final bool hasError;

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length == 6) {
      widget.onCompleted(otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (i) => _OtpBox(
        controller: _controllers[i],
        focusNode: _focusNodes[i],
        hasError: widget.hasError,
        onChanged: (v) => _onChanged(i, v),
      )),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 56,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        maxLength: 1,
        textAlign: TextAlign.center,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: onChanged,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide(
              color: hasError ? AppColors.error : AppColors.divider,
              width: hasError ? 2 : 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide(
              color: hasError ? AppColors.error : AppColors.primary,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}
