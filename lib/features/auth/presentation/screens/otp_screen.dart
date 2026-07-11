import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/popup_helper.dart';
import '../providers/auth_provider.dart';

/// OTP verification — 6 pinput boxes, auto-submit, shake on error,
/// 60s circular countdown with resend.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.phone});

  final String phone;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen>
    with TickerProviderStateMixin {
  final _pinController = TextEditingController();
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final AnimationController _successScale = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  Timer? _countdown;
  int _secondsLeft = 60;
  bool _verifying = false;
  bool _verified = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdown?.cancel();
    setState(() => _secondsLeft = 60);
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (_secondsLeft <= 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _countdown?.cancel();
    _pinController.dispose();
    _shake.dispose();
    _successScale.dispose();
    super.dispose();
  }

  Future<void> _verify(String otp) async {
    if (_verifying || _verified) return;
    setState(() => _verifying = true);

    final ok =
        await ref.read(authNotifierProvider.notifier).verifyOtp(otp);
    if (!mounted) return;
    setState(() => _verifying = false);

    if (ok) {
      HapticFeedback.heavyImpact();
      setState(() => _verified = true);
      _successScale.forward();
      PopupHelper.showSuccess(context, 'Number verified successfully!');
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_guest', false);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
          '/auth/profile-setup', (r) => r.isFirst);
    } else {
      final state = ref.read(authNotifierProvider);
      final msg = state.errorMessage ?? '';
      _shake.forward(from: 0);
      _pinController.clear();
      if (msg.toLowerCase().contains('expired')) {
        PopupHelper.showWarning(
            context, 'OTP has expired. Please request a new one.');
      } else {
        PopupHelper.showError(
            context, 'Invalid OTP. Please check and try again.');
      }
    }
  }

  Future<void> _resend() async {
    HapticFeedback.mediumImpact();
    _startCountdown();
    await ref
        .read(authNotifierProvider.notifier)
        .sendOtp('+977${widget.phone}');
    if (!mounted) return;
    final state = ref.read(authNotifierProvider);
    if (state.status == AuthStatus.error) {
      PopupHelper.showError(
          context, 'Failed to resend OTP. Please try again.');
    } else {
      PopupHelper.showInfo(context, 'New OTP sent to your number');
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPin = PinTheme(
      width: 50,
      height: 56,
      textStyle: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: const BackButton(),
        title: const Text('Verify Your Number'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Success check or phone icon
            _verified
                ? ScaleTransition(
                    scale: CurvedAnimation(
                        parent: _successScale, curve: Curves.elasticOut),
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: const BoxDecoration(
                        color: AppColors.trustedBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: AppColors.trusted, size: 48),
                    ),
                  )
                : Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: AppColors.primary50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.sms_outlined,
                        color: AppColors.primary, size: 40),
                  ),
            const SizedBox(height: 22),

            Text('Enter the 6-digit code',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                )),
            const SizedBox(height: 6),
            Text('Code sent to +977${widget.phone}',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                )),
            const SizedBox(height: 30),

            // OTP boxes with shake on error
            AnimatedBuilder(
              animation: _shake,
              builder: (context, child) {
                final t = _shake.value;
                final dx = math.sin(t * math.pi * 6) * 10 * (1 - t);
                return Transform.translate(
                    offset: Offset(dx, 0), child: child);
              },
              child: Pinput(
                controller: _pinController,
                length: 6,
                autofocus: true,
                enabled: !_verifying && !_verified,
                defaultPinTheme: defaultPin,
                focusedPinTheme: defaultPin.copyWith(
                  decoration: defaultPin.decoration!.copyWith(
                    border:
                        Border.all(color: AppColors.primary, width: 2),
                  ),
                ),
                submittedPinTheme: defaultPin.copyWith(
                  decoration: defaultPin.decoration!.copyWith(
                    color: AppColors.primary50,
                    border: Border.all(color: AppColors.primary100),
                  ),
                ),
                onCompleted: _verify,
              ),
            ),
            const SizedBox(height: 30),

            if (_verifying)
              const CircularProgressIndicator(color: AppColors.primary)
            else if (_secondsLeft > 0)
              // Circular countdown
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: CircularProgressIndicator(
                        value: _secondsLeft / 60,
                        strokeWidth: 4,
                        color: AppColors.primary,
                        backgroundColor: AppColors.borderLight,
                      ),
                    ),
                    Text('$_secondsLeft',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        )),
                  ],
                ),
              )
            else
              TextButton.icon(
                onPressed: _resend,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Resend OTP'),
              ),

            const SizedBox(height: 20),
            Text(
              'Didn\'t get the code? Check your SMS inbox or wait for '
              'the timer to finish, then tap Resend.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textMuted, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
