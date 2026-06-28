import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../providers/language_provider.dart';
import '../../../../services/firestore_service.dart';
import '../providers/auth_provider.dart';

class OtpVerifyScreen extends ConsumerStatefulWidget {
  const OtpVerifyScreen({super.key, required this.phone});
  final String phone;

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  int _countdown = AppConstants.otpTimeoutSeconds;
  Timer? _timer;
  bool _hasError = false;
  String _enteredOtp = '';

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _countdown = AppConstants.otpTimeoutSeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 0) {
        t.cancel();
      } else {
        if (mounted) setState(() => _countdown--);
      }
    });
  }

  Future<void> _resendOtp() async {
    if (_countdown > 0) return;
    HapticFeedback.lightImpact();
    await ref.read(authNotifierProvider.notifier).sendOtp(widget.phone);
    if (!mounted) return;
    final state = ref.read(authNotifierProvider);
    if (state.status == AuthStatus.otpSent) {
      _startTimer();
      setState(() => _hasError = false);
    }
  }

  Future<void> _verify(String otp) async {
    if (otp.length != 6) return;
    HapticFeedback.mediumImpact();
    _enteredOtp = otp;

    final success =
        await ref.read(authNotifierProvider.notifier).verifyOtp(otp);
    if (!mounted) return;

    if (success) {
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        try {
          final userDoc =
              await ref.read(firestoreServiceProvider).getUserById(user.uid);
          if (!mounted) return;
          if (userDoc != null) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/home',
              (route) => false,
            );
          } else {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/setup-profile',
              (route) => false,
            );
          }
        } catch (_) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/setup-profile',
            (route) => false,
          );
        }
      }
    } else {
      setState(() => _hasError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final authState = ref.watch(authNotifierProvider);
    final isVerifying = authState.status == AuthStatus.verifying;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          AppStrings.get('otp_title', lang),
          style: AppTextStyles.titleMedium(lang: lang)
              .copyWith(color: Colors.white),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.35],
          ),
        ),
        child: Column(
          children: [
            // Timer ring
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: _countdown / AppConstants.otpTimeoutSeconds,
                      strokeWidth: 5,
                      backgroundColor: Colors.white24,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '$_countdown',
                    style: AppTextStyles.titleLarge(lang: lang)
                        .copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),

            // Card
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppSpacing.radiusXxl),
                    topRight: Radius.circular(AppSpacing.radiusXxl),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        '${AppStrings.get('otp_subtitle', lang)} +977 ${widget.phone}',
                        style: AppTextStyles.bodyMedium(lang: lang)
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // OTP input
                      _hasError
                          ? OtpInputField(
                              onCompleted: _verify,
                              hasError: _hasError,
                            )
                              .animate(key: const ValueKey('otp_error'))
                              .shake(
                                  hz: 4,
                                  curve: Curves.easeInOut,
                                  duration: 500.ms)
                          : OtpInputField(
                              onCompleted: _verify,
                              hasError: _hasError,
                            ),

                      if (_hasError) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Invalid OTP. Please try again.',
                          style: AppTextStyles.bodySmall(lang: lang)
                              .copyWith(color: AppColors.error),
                        ),
                      ],

                      const SizedBox(height: AppSpacing.xl),
                      CustomButton(
                        label: AppStrings.get('verify', lang),
                        onPressed: isVerifying || _enteredOtp.length < 6
                            ? null
                            : () => _verify(_enteredOtp),
                        isLoading: isVerifying,
                        lang: lang,
                      ),

                      const SizedBox(height: AppSpacing.lg),
                      Center(
                        child: _countdown <= 0
                            ? TextButton(
                                onPressed: _resendOtp,
                                child: Text(
                                  AppStrings.get('otp_resend', lang),
                                  style: AppTextStyles.labelMedium(lang: lang)
                                      .copyWith(color: AppColors.primary),
                                ),
                              )
                            : Text(
                                '${AppStrings.get('otp_resend_in', lang)} ${_countdown}s',
                                style: AppTextStyles.bodySmall(lang: lang)
                                    .copyWith(color: AppColors.textSecondary),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
