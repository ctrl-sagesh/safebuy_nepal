import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/popup_helper.dart';
import '../../../../core/utils/validators.dart';
import '../../../../services/firestore_service.dart';
import '../../../../services/google_auth_service.dart';
import '../../../../models/user_model.dart';
import '../providers/auth_provider.dart';

/// Combined Sign In / Register screen.
/// Top 40%: blue gradient hero with curved bottom edge.
/// Bottom 60%: white card with tabbed forms.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs =
      TabController(length: 2, vsync: this);

  final _signInPhone = TextEditingController();
  final _regPhone = TextEditingController();
  final _regName = TextEditingController();
  String _regRole = 'buyer';
  bool _sending = false;

  String? _signInPhoneError;
  String? _regPhoneError;
  String? _regNameError;

  @override
  void dispose() {
    _tabs.dispose();
    _signInPhone.dispose();
    _regPhone.dispose();
    _regName.dispose();
    super.dispose();
  }

  // ── Google sign in ───────────────────────────────────────────────────────────

  Future<void> _googleSignIn() async {
    HapticFeedback.mediumImpact();
    try {
      final service = GoogleAuthService();
      final cred = await service.signInWithGoogle();
      if (cred == null) return; // user cancelled
      final user = cred.user;
      if (user == null) {
        if (mounted) {
          PopupHelper.showError(
              context, 'Google sign-in failed. Please try again.');
        }
        return;
      }
      // Ensure a Firestore user document exists.
      final fs = ref.read(firestoreServiceProvider);
      final existing = await fs.getUserById(user.uid);
      if (existing == null) {
        await fs.createOrUpdateUser(UserModel(
          userId: user.uid,
          phone: user.phoneNumber ?? '',
          fullName: user.displayName ?? '',
          role: 'buyer',
          createdAt: DateTime.now(),
          isAccountActive: true,
          totalReportsSubmitted: 0,
          lastLoginAt: DateTime.now(),
          preferredLanguage: 'en',
          email: user.email,
        ));
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_guest', false);
      if (!mounted) return;
      PopupHelper.showSuccess(context, 'Welcome back!');
      if (existing == null || existing.fullName.isEmpty) {
        Navigator.of(context).pushReplacementNamed('/auth/profile-setup');
      } else {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home', (r) => false);
      }
    } catch (e) {
      if (!mounted) return;
      PopupHelper.showError(
          context,
          'Could not sign in with Google. Please try again '
          'or use your phone number.');
    }
  }

  // ── Phone OTP ────────────────────────────────────────────────────────────────

  Future<void> _sendOtp({required bool isRegister}) async {
    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();

    if (isRegister) {
      final nameErr = Validators.fullName(_regName.text);
      final phoneErr = Validators.nepaliPhone(_regPhone.text);
      setState(() {
        _regNameError = nameErr;
        _regPhoneError = phoneErr == null
            ? null
            : 'Enter a valid Nepal phone number (97XXXXXXXX or 98XXXXXXXX)';
      });
      if (nameErr != null || phoneErr != null) {
        PopupHelper.showError(
            context, 'Please fix the highlighted fields to continue.');
        return;
      }
    } else {
      final phoneErr = Validators.nepaliPhone(_signInPhone.text);
      setState(() {
        _signInPhoneError = phoneErr == null
            ? null
            : 'Enter a valid Nepal phone number (97XXXXXXXX or 98XXXXXXXX)';
      });
      if (phoneErr != null) {
        PopupHelper.showError(context, 'Please enter a valid phone number.');
        return;
      }
    }

    final phone =
        (isRegister ? _regPhone.text : _signInPhone.text).trim();

    // Stash pending registration info for profile setup.
    try {
      final prefs = await SharedPreferences.getInstance();
      if (isRegister) {
        await prefs.setString('pending_name', _regName.text.trim());
        await prefs.setString('pending_role', _regRole);
      } else {
        await prefs.remove('pending_name');
        await prefs.remove('pending_role');
      }
    } catch (_) {}

    setState(() => _sending = true);
    await ref.read(authNotifierProvider.notifier).sendOtp('+977$phone');

    if (!mounted) return;
    setState(() => _sending = false);

    final state = ref.read(authNotifierProvider);
    if (state.status == AuthStatus.otpSent ||
        state.status == AuthStatus.sendingOtp) {
      PopupHelper.showSuccess(context, 'OTP sent to your number');
      Navigator.of(context)
          .pushNamed('/auth/otp', arguments: {'phone': phone});
    } else if (state.status == AuthStatus.verified) {
      Navigator.of(context).pushReplacementNamed('/auth/profile-setup');
    } else {
      PopupHelper.showError(
          context,
          'Failed to send OTP. Please check your number and try again.');
    }
  }

  // ── UI ───────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Hero — blue gradient with curved bottom
          ClipPath(
            clipper: _CurveClipper(),
            child: Container(
              height: size.height * 0.34,
              width: double.infinity,
              decoration:
                  const BoxDecoration(gradient: AppColors.heroGradient),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_rounded,
                          color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 14),
                    Text('SafeBuy Nepal',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        )),
                    Text('Verify before you pay · तिर्नु अघि जाँच्नुस्',
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12.5,
                        )),
                  ],
                ),
              ),
            ),
          ),

          // Tabs card
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -22),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(26)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x141565C0),
                      blurRadius: 20,
                      offset: Offset(0, -6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    TabBar(
                      controller: _tabs,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textMuted,
                      indicatorColor: AppColors.primary,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.5,
                      ),
                      tabs: const [
                        Tab(text: 'Sign In'),
                        Tab(text: 'Register'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabs,
                        children: [
                          _buildSignIn(),
                          _buildRegister(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignIn() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Google button
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _googleSignIn,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.borderMedium),
                foregroundColor: AppColors.textPrimary,
              ),
              icon: const _GoogleG(),
              label: Text('Continue with Google',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                  )),
            ),
          ),
          const SizedBox(height: 18),
          Row(children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or',
                  style: GoogleFonts.inter(
                      color: AppColors.textMuted, fontSize: 12.5)),
            ),
            const Expanded(child: Divider()),
          ]),
          const SizedBox(height: 18),

          _PhoneField(
            controller: _signInPhone,
            errorText: _signInPhoneError,
            onChanged: (_) {
              if (_signInPhoneError != null) {
                setState(() => _signInPhoneError = null);
              }
            },
          ),
          const SizedBox(height: 18),

          SizedBox(
            height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton(
                onPressed:
                    _sending ? null : () => _sendOtp(isRegister: false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                child: _sending
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Send OTP'),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'By continuing you agree to our Terms of Service and '
            'Privacy Policy.',
            textAlign: TextAlign.center,
            style:
                GoogleFonts.inter(fontSize: 11.5, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildRegister() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _regName,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Full Name',
              prefixIcon: const Icon(Icons.person_outline_rounded),
              errorText: _regNameError,
            ),
            onChanged: (v) {
              if (_regNameError != null) {
                setState(() => _regNameError =
                    v.trim().length >= 2 ? null : _regNameError);
              }
            },
          ),
          const SizedBox(height: 16),

          // Role cards
          Row(
            children: [
              Expanded(
                child: _RoleCard(
                  emoji: '🛒',
                  title: 'Buyer',
                  subtitle: 'Verify & stay safe',
                  selected: _regRole == 'buyer',
                  onTap: () => setState(() => _regRole = 'buyer'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RoleCard(
                  emoji: '🏪',
                  title: 'Seller',
                  subtitle: 'Build my trust',
                  selected: _regRole == 'seller',
                  onTap: () => setState(() => _regRole = 'seller'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _PhoneField(
            controller: _regPhone,
            errorText: _regPhoneError,
            onChanged: (_) {
              if (_regPhoneError != null) {
                setState(() => _regPhoneError = null);
              }
            },
          ),
          const SizedBox(height: 18),

          SizedBox(
            height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton(
                onPressed:
                    _sending ? null : () => _sendOtp(isRegister: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                child: _sending
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Send OTP'),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Your number is only used for identity verification. '
            'We never share it.',
            textAlign: TextAlign.center,
            style:
                GoogleFonts.inter(fontSize: 11.5, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ── Widgets ────────────────────────────────────────────────────────────────────

class _PhoneField extends StatelessWidget {
  const _PhoneField({
    required this.controller,
    this.errorText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.phone,
      maxLength: 10,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: 'Phone Number',
        counterText: '',
        errorText: errorText,
        errorMaxLines: 2,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 8, top: 14),
          child: Text('+977',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AppColors.textPrimary,
              )),
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary50 : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderLight,
            width: selected ? 2 : 1.2,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textPrimary,
                )),
            Text(subtitle,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  color: AppColors.textMuted,
                )),
          ],
        ),
      ),
    );
  }
}

class _GoogleG extends StatelessWidget {
  const _GoogleG();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final stroke = size.width * 0.18;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final r = (size.width - stroke) / 2;
    final c = rect.center;

    // Four coloured arcs approximating the Google G.
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), 3.4, 1.6, false, paint);
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), 2.2, 1.2, false, paint);
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), 0.9, 1.3, false, paint);
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -0.4, 1.3, false, paint);
    // The G crossbar
    paint.color = const Color(0xFF4285F4);
    canvas.drawLine(
      Offset(c.dx + r * 0.1, c.dy),
      Offset(c.dx + r, c.dy),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, size.height - 36)
      ..quadraticBezierTo(
          size.width / 2, size.height, size.width, size.height - 36)
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
