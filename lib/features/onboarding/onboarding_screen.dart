import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/popup_helper.dart';

/// 4-slide visual tutorial onboarding.
/// Slide 1: search flow demo  ·  Slide 2: verification card
/// Slide 3: report pipeline   ·  Slide 4: account vs guest
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  Future<void> _complete({required bool asGuest}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.prefOnboardingDone, true);
      if (asGuest) await prefs.setBool('is_guest', true);
    } catch (_) {
      if (mounted) {
        PopupHelper.showWarning(
            context, 'Could not save your preference. Continuing anyway.');
      }
    }
    if (!mounted) return;
    Navigator.of(context)
        .pushReplacementNamed(asGuest ? '/home' : '/auth');
  }

  void _next() {
    HapticFeedback.lightImpact();
    if (_page < 3) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip (hidden on slide 4)
            SizedBox(
              height: 48,
              child: Align(
                alignment: Alignment.centerRight,
                child: _page < 3
                    ? TextButton(
                        onPressed: () => _complete(asGuest: true),
                        child: Text(
                          'Skip',
                          style: GoogleFonts.inter(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : null,
              ),
            ),

            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: const [
                  _Slide1(),
                  _Slide2(),
                  _Slide3(),
                  _Slide4(),
                ],
              ),
            ),

            // Dots
            SmoothPageIndicator(
              controller: _controller,
              count: 4,
              effect: const ExpandingDotsEffect(
                dotHeight: 8,
                dotWidth: 8,
                expansionFactor: 3,
                activeDotColor: AppColors.primary,
                dotColor: AppColors.borderMedium,
              ),
            ),
            const SizedBox(height: 20),

            // Bottom actions
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: _page < 3
                  ? SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ElevatedButton(
                          onPressed: _next,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                          ),
                          child: const Text('Next'),
                        ),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ElevatedButton(
                              onPressed: () => _complete(asGuest: false),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                              ),
                              child: const Text('Create Free Account'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            onPressed: () => _complete(asGuest: true),
                            child: const Text('Browse as Guest'),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared slide scaffold ──────────────────────────────────────────────────────

class _SlideBody extends StatelessWidget {
  const _SlideBody({
    required this.illustration,
    required this.guideSteps,
    required this.title,
    required this.titleNe,
    required this.body,
  });

  final Widget illustration;
  final List<(String, String)> guideSteps; // (emoji, text)
  final String title;
  final String titleNe;
  final String body;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(height: 210, child: Center(child: illustration)),
          const SizedBox(height: 12),

          // Mini guide steps with staggered entrance
          ...List.generate(guideSteps.length, (i) {
            final (emoji, text) = guideSteps[i];
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 350 + i * 300),
              curve: Curves.easeOut,
              builder: (context, t, child) => Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(24 * (1 - t), 0),
                  child: child,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.primary50,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary100),
                      ),
                      alignment: Alignment.center,
                      child: Text('${i + 1}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          )),
                    ),
                    const SizedBox(width: 10),
                    Text(emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        text,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titleNe,
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansDevanagari(
              fontSize: 14,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── Slide 1: phone mockup with looping search demo ─────────────────────────────

class _Slide1 extends StatefulWidget {
  const _Slide1();

  @override
  State<_Slide1> createState() => _Slide1State();
}

class _Slide1State extends State<_Slide1> {
  int _step = 0;
  String _typed = '';
  Timer? _timer;
  static const _number = '98XXXXXXXX';

  @override
  void initState() {
    super.initState();
    _loop();
  }

  void _loop() {
    _timer?.cancel();
    setState(() {
      _step = 0;
      _typed = '';
    });
    // Step 1 → type number → show result → hold → restart
    _timer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() => _step = 1);
      var i = 0;
      _timer = Timer.periodic(const Duration(milliseconds: 110), (t) {
        if (!mounted) return t.cancel();
        if (i < _number.length) {
          setState(() => _typed = _number.substring(0, ++i));
        } else {
          t.cancel();
          setState(() => _step = 2);
          _timer = Timer(const Duration(milliseconds: 1800), () {
            if (mounted) _loop();
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SlideBody(
      illustration: _phoneMockup(),
      guideSteps: const [
        ('🔍', 'Open Search tab'),
        ('📱', 'Enter phone, eSewa ID, or @handle'),
        ('✅', 'See trust verdict instantly'),
      ],
      title: 'Verify Any Seller Instantly',
      titleNe: 'जुनसुकै विक्रेता तुरुन्त जाँच्नुस्',
      body: 'Search any TikTok, Instagram, or Facebook seller by their '
          'phone number, eSewa ID, or social media handle. See their '
          'trust score before you pay.',
    );
  }

  Widget _phoneMockup() {
    return Container(
      width: 160,
      height: 210,
      decoration: BoxDecoration(
        color: const Color(0xFF10203A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF29405F), width: 3),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('SafeBuy Nepal',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 10),
          // Search bar
          Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 12, color: Colors.white70),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _typed.isEmpty ? '' : _typed,
                    style: GoogleFonts.robotoMono(
                        color: Colors.white, fontSize: 10),
                  ),
                ),
                // Blinking cursor
                _BlinkingCursor(visible: _step <= 1),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Result card slides up
          AnimatedSlide(
            offset: _step == 2 ? Offset.zero : const Offset(0, 1.2),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: _step == 2 ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.trustedBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('TRUSTED',
                              style: GoogleFonts.poppins(
                                color: AppColors.trusted,
                                fontSize: 7,
                                fontWeight: FontWeight.w800,
                              )),
                        ),
                        const Spacer(),
                        Text('87',
                            style: GoogleFonts.poppins(
                              color: AppColors.trusted,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            )),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Priya Fashions',
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor({required this.visible});
  final bool visible;

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();
    return FadeTransition(
      opacity: _c,
      child: Container(width: 1.5, height: 12, color: Colors.white),
    );
  }
}

// ── Slide 2: verification card ─────────────────────────────────────────────────

class _Slide2 extends StatefulWidget {
  const _Slide2();

  @override
  State<_Slide2> createState() => _Slide2State();
}

class _Slide2State extends State<_Slide2>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SlideBody(
      illustration: AnimatedBuilder(
        animation: _glow,
        builder: (context, _) => Container(
          width: 280,
          height: 160,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Color.lerp(const Color(0xFFD4AF37),
                  const Color(0xFFFFE082), _glow.value)!,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37)
                    .withValues(alpha: 0.25 + 0.2 * _glow.value),
                blurRadius: 18 + 8 * _glow.value,
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.shield_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text('SafeBuy Nepal',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      )),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('VERIFIED',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        )),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your Business Name',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          )),
                      Text('Clothing & Fashion · Kathmandu',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 9,
                          )),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.qr_code_2,
                        size: 26, color: Color(0xFF0A1628)),
                  ),
                  const SizedBox(width: 8),
                  Text('SBV-2026-XXXXX',
                      style: GoogleFonts.robotoMono(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
            ],
          ),
        ),
      ),
      guideSteps: const [
        ('📋', 'Register your business details'),
        ('🪪', 'Upload KYC documents'),
        ('🏆', 'Get your SafeBuy Verified card'),
      ],
      title: 'Get Your Business Verified',
      titleNe: 'आफ्नो व्यवसाय प्रमाणित गर्नुस्',
      body: 'Complete KYC verification and receive your SafeBuy '
          'Verification Card. Buyers trust verified sellers with a '
          'locked payment QR.',
    );
  }
}

// ── Slide 3: report pipeline ───────────────────────────────────────────────────

class _Slide3 extends StatefulWidget {
  const _Slide3();

  @override
  State<_Slide3> createState() => _Slide3State();
}

class _Slide3State extends State<_Slide3>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _card(String emoji, String label, Color color, double appearAt) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = ((_c.value - appearAt) / 0.18).clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.scale(
            scale: 0.7 + 0.3 * Curves.easeOutBack.transform(t),
            child: Container(
              width: 86,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.35)),
              ),
              child: Column(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 6),
                  Text(label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      )),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _arrow(double appearAt) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = ((_c.value - appearAt) / 0.12).clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: const Icon(Icons.arrow_forward_rounded,
              color: AppColors.primary, size: 20),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SlideBody(
      illustration: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _card('📸', 'Collect\nEvidence', AppColors.grey500, 0.05),
          _arrow(0.25),
          _card('📋', 'Submit\nReport', AppColors.primary, 0.38),
          _arrow(0.58),
          _card('🛡️', 'Score\nUpdated', AppColors.trusted, 0.70),
        ],
      ),
      guideSteps: const [
        ('📸', 'Screenshot payment and chat proof'),
        ('📋', 'Fill in seller details and incident info'),
        ('⚡', 'Trust score updates within minutes'),
      ],
      title: 'Report Fraud, Protect Others',
      titleNe: 'ठगी रिपोर्ट गर्नुस्, अरूलाई बचाउनुस्',
      body: 'Your evidence-backed report warns thousands of other '
          'buyers and permanently lowers the scammer\'s trust score.',
    );
  }
}

// ── Slide 4: account vs guest ──────────────────────────────────────────────────

class _Slide4 extends StatefulWidget {
  const _Slide4();

  @override
  State<_Slide4> createState() => _Slide4State();
}

class _Slide4State extends State<_Slide4> {
  bool _leftSelected = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() => _leftSelected = !_leftSelected);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _choiceCard({
    required bool selected,
    required String title,
    required List<String> items,
    required Color accent,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOut,
      width: 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected ? accent.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? accent : AppColors.borderLight,
          width: selected ? 2 : 1.2,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                )
              ]
            : null,
      ),
      child: Column(
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 10),
          ...items.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, size: 13, color: accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(e,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          )),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SlideBody(
      illustration: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _choiceCard(
            selected: _leftSelected,
            title: 'Full Account',
            items: const ['Report fraud', 'Write reviews', 'Track impact'],
            accent: AppColors.primary,
          ),
          const SizedBox(width: 16),
          _choiceCard(
            selected: !_leftSelected,
            title: 'Browse Only',
            items: const ['Search sellers', 'View scores', 'Read reviews'],
            accent: AppColors.grey500,
          ),
        ],
      ),
      guideSteps: const [
        ('🔐', 'Create a free account for full access'),
        ('👀', 'Or browse instantly as a guest'),
        ('🔄', 'Upgrade to an account any time'),
      ],
      title: 'Your Safety, Your Choice',
      titleNe: 'तपाईंको सुरक्षा, तपाईंको छनौट',
      body: 'Reporting and reviews need a verified account. '
          'Searching and browsing are always free — no sign-in needed.',
    );
  }
}
