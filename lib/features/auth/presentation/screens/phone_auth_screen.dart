import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/utils/validators.dart';
import '../../../../providers/language_provider.dart';
import '../providers/auth_provider.dart';

class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    final phone = _phoneCtrl.text.trim();
    await ref.read(authNotifierProvider.notifier).sendOtp(phone);

    if (!mounted) return;
    final state = ref.read(authNotifierProvider);
    if (state.status == AuthStatus.otpSent) {
      Navigator.of(context).pushNamed(
        '/verify-otp',
        arguments: {'phone': phone},
      );
    } else if (state.status == AuthStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage ?? 'Failed to send OTP'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final authState = ref.watch(authNotifierProvider);
    final isSending = authState.status == AuthStatus.sendingOtp;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xxl,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: Colors.white,
                        size: AppSpacing.iconXxl,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      AppStrings.get('app_name', lang),
                      style: AppTextStyles.displayMedium(lang: lang)
                          .copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      AppStrings.get('tagline', lang),
                      style: AppTextStyles.bodyMedium(lang: lang)
                          .copyWith(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Form card
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            AppStrings.get('phone_auth_title', lang),
                            style: AppTextStyles.titleLarge(lang: lang),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            AppStrings.get('phone_auth_subtitle', lang),
                            style: AppTextStyles.bodyMedium(lang: lang)
                                .copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          NepalPhoneField(
                            controller: _phoneCtrl,
                            label: AppStrings.get('phone_hint', lang),
                            validator: (v) => lang == 'ne'
                                ? Validators.nepaliPhoneNe(v)
                                : Validators.nepaliPhone(v),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          CustomButton(
                            label: AppStrings.get('send_otp', lang),
                            onPressed: isSending ? null : _sendOtp,
                            isLoading: isSending,
                            lang: lang,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.lock_outline,
                                  size: AppSpacing.iconXs,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Flexible(
                                  child: Text(
                                    AppStrings.get('privacy_note', lang),
                                    style:
                                        AppTextStyles.bodySmall(lang: lang)
                                            .copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
