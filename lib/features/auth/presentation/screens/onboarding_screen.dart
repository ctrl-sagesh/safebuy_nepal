import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.lang = 'en'});
  final String lang;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageCtrl = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefOnboardingDone, true);
  }

  Future<void> _goToAuth() async {
    HapticFeedback.mediumImpact();
    await _markDone();
    if (mounted) Navigator.of(context).pushReplacementNamed('/auth');
  }

  Future<void> _goAsGuest() async {
    HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefOnboardingDone, true);
    await prefs.setBool('is_guest', true);
    if (mounted) Navigator.of(context).pushReplacementNamed('/home');
  }

  void _next() {
    if (_page < 3) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _back() {
    if (_page > 0) {
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final isLast = _page == 3;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(
                  right: AppSpacing.lg, top: AppSpacing.sm,
                ),
                child: isLast
                    ? const SizedBox(height: 40)
                    : TextButton(
                        onPressed: () => _pageCtrl.animateToPage(
                          3,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        ),
                        child: Text(
                          AppStrings.get('skip', lang),
                          style: AppTextStyles.labelMedium(lang: lang),
                        ),
                      ),
              ),
            ),

            // Page view (illustration + text)
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _Slide1(lang: lang),
                  _Slide2(lang: lang),
                  _Slide3(lang: lang),
                  _Slide4(lang: lang),
                ],
              ),
            ),

            // Progress dots
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) => _Dot(active: i == _page)),
              ),
            ),

            // Bottom buttons
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl, 0, AppSpacing.xl, bottomPad + AppSpacing.lg,
              ),
              child: isLast
                  ? Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _goToAuth,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              AppStrings.get('i_am_buyer', lang) == 'I\'m a Buyer'
                                  ? 'Create Account'
                                  : 'खाता बनाउनुहोस्',
                              style: AppTextStyles.button(lang: lang)
                                  .copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton(
                            onPressed: _goAsGuest,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: AppColors.borderMedium, width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              lang == 'en'
                                  ? 'Browse as Guest'
                                  : 'अतिथिको रूपमा हेर्नुहोस्',
                              style: AppTextStyles.button(lang: lang)
                                  .copyWith(color: AppColors.textBlue),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        if (_page > 0)
                          TextButton(
                            onPressed: _back,
                            child: Text(
                              AppStrings.get('back', lang),
                              style: AppTextStyles.button(lang: lang)
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                        const Spacer(),
                        SizedBox(
                          width: 140,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _next,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              minimumSize: Size.zero,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  AppStrings.get('next', lang),
                                  style: AppTextStyles.button(lang: lang)
                                      .copyWith(color: Colors.white),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.arrow_forward, size: 16),
                              ],
                            ),
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

// ═══════════════════════════════════════════════════════════════════════════════
// SLIDE 1 — Verify Before You Pay
// ═══════════════════════════════════════════════════════════════════════════════

class _Slide1 extends StatelessWidget {
  const _Slide1({required this.lang});
  final String lang;

  @override
  Widget build(BuildContext context) {
    return _SlideLayout(
      illustration: _ShieldIllustration(),
      title: AppStrings.get('onboard1_title', lang),
      nepaliTitle: lang == 'en' ? 'तिर्नु अघि जाँच्नुस्' : null,
      body: AppStrings.get('onboard1_body', lang),
      lang: lang,
    );
  }
}

class _ShieldIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Blue gradient circle background
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.12),
                  AppColors.primary.withValues(alpha: 0.03),
                ],
              ),
            ),
          ),
          // Shield icon
          Icon(Icons.shield_rounded, size: 80, color: AppColors.primary)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1.0, end: 1.08, duration: 2000.ms),
          // Floating trust pills
          Positioned(
            top: 20, right: 10,
            child: _TrustPill(
              label: 'TRUSTED 87',
              color: AppColors.trusted,
              bg: AppColors.trustedBg,
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 400.ms)
                .slideX(begin: 0.3, end: 0, delay: 300.ms),
          ),
          Positioned(
            right: 0, top: 100,
            child: _TrustPill(
              label: 'UNVERIFIED 64',
              color: AppColors.unverified,
              bg: AppColors.unverifiedBg,
            )
                .animate()
                .fadeIn(delay: 600.ms, duration: 400.ms)
                .slideX(begin: 0.3, end: 0, delay: 600.ms),
          ),
          Positioned(
            bottom: 20, right: 20,
            child: _TrustPill(
              label: 'HIGH RISK 31',
              color: AppColors.highRisk,
              bg: AppColors.highRiskBg,
            )
                .animate()
                .fadeIn(delay: 900.ms, duration: 400.ms)
                .slideX(begin: 0.3, end: 0, delay: 900.ms),
          ),
        ],
      ),
    );
  }
}

class _TrustPill extends StatelessWidget {
  const _TrustPill({
    required this.label, required this.color, required this.bg,
  });
  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 8),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w700, color: color,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SLIDE 2 — Community-Powered Safety
// ═══════════════════════════════════════════════════════════════════════════════

class _Slide2 extends StatelessWidget {
  const _Slide2({required this.lang});
  final String lang;

  @override
  Widget build(BuildContext context) {
    return _SlideLayout(
      illustration: _CommunityIllustration(),
      title: AppStrings.get('onboard2_title', lang),
      nepaliTitle: lang == 'en' ? 'समुदायद्वारा सुरक्षित' : null,
      body: AppStrings.get('onboard2_body', lang),
      lang: lang,
    );
  }
}

class _CommunityIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 180,
            height: 260,
            decoration: BoxDecoration(
              color: AppColors.bgDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 20, offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Report cards
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4,
                    ),
                    child: _MiniReportCard(index: i)
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: 300 + i * 400))
                        .slideY(
                          begin: 0.4, end: 0,
                          delay: Duration(milliseconds: 300 + i * 400),
                          duration: 400.ms,
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniReportCard extends StatelessWidget {
  const _MiniReportCard({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    final data = [
      ('TikTok', 'NPR 5,000', AppColors.highRisk),
      ('Instagram', 'NPR 2,500', AppColors.unverified),
      ('Facebook', 'NPR 8,000', AppColors.highRisk),
    ];
    final (platform, amount, color) = data[index];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.warning_rounded, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  platform,
                  style: const TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w600, color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SLIDE 3 — Report Fraud in Minutes
// ═══════════════════════════════════════════════════════════════════════════════

class _Slide3 extends StatelessWidget {
  const _Slide3({required this.lang});
  final String lang;

  @override
  Widget build(BuildContext context) {
    return _SlideLayout(
      illustration: _StepsIllustration(),
      title: AppStrings.get('onboard3_title', lang) == 'Build Your Business Trust'
          ? 'Report Fraud in Minutes'
          : 'मिनेटमा ठगी रिपोर्ट गर्नुस्',
      nepaliTitle: lang == 'en' ? 'मिनेटमा ठगी रिपोर्ट गर्नुस्' : null,
      body: lang == 'en'
          ? 'Submit a structured report with evidence. Your report immediately affects the seller\'s trust score and protects future buyers.'
          : 'प्रमाणसहित संरचित रिपोर्ट पेश गर्नुहोस्। तपाईंको रिपोर्टले विक्रेताको ट्रस्ट स्कोरलाई तुरुन्तै असर गर्छ।',
      lang: lang,
    );
  }
}

class _StepsIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final steps = [
      (Icons.person_search_rounded, 'Find Seller', AppColors.primary),
      (Icons.report_problem_rounded, 'Report Fraud', AppColors.highRisk),
      (Icons.check_circle_rounded, 'Score Updated', AppColors.trusted),
    ];

    return SizedBox(
      height: 220,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            _StepCard(
              icon: steps[i].$1,
              label: steps[i].$2,
              color: steps[i].$3,
            )
                .animate()
                .fadeIn(delay: Duration(milliseconds: 200 + i * 300))
                .slideX(
                  begin: -0.2, end: 0,
                  delay: Duration(milliseconds: 200 + i * 300),
                  duration: 400.ms,
                ),
            if (i < 2)
              Container(
                width: 2, height: 20,
                margin: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.borderMedium,
                  borderRadius: BorderRadius.circular(1),
                ),
              )
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: 400 + i * 300)),
          ],
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.icon, required this.label, required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SLIDE 4 — Your Safety, Your Choice
// ═══════════════════════════════════════════════════════════════════════════════

class _Slide4 extends StatelessWidget {
  const _Slide4({required this.lang});
  final String lang;

  @override
  Widget build(BuildContext context) {
    return _SlideLayout(
      illustration: _ChoiceIllustration(),
      title: lang == 'en'
          ? 'Your Safety, Your Choice'
          : 'तपाईंको सुरक्षा, तपाईंको छनौट',
      nepaliTitle: lang == 'en' ? 'तपाईंको सुरक्षा, तपाईंको छनौट' : null,
      body: lang == 'en'
          ? 'Browse seller trust scores as a guest, or create an account to report fraud and protect the community.'
          : 'अतिथिको रूपमा विक्रेता ट्रस्ट स्कोर हेर्नुहोस्, वा खाता बनाएर समुदायलाई सुरक्षित राख्नुहोस्।',
      lang: lang,
    );
  }
}

class _ChoiceIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ChoiceCard(
          icon: Icons.lock_open_rounded,
          title: 'Guest',
          subtitle: 'Browse freely',
          color: AppColors.textSecondary,
        )
            .animate()
            .fadeIn(delay: 300.ms, duration: 400.ms)
            .slideX(begin: -0.2, end: 0, delay: 300.ms),
        const SizedBox(width: 16),
        _ChoiceCard(
          icon: Icons.verified_user_rounded,
          title: 'Account',
          subtitle: 'Full access',
          color: AppColors.primary,
          highlighted: true,
        )
            .animate()
            .fadeIn(delay: 500.ms, duration: 400.ms)
            .slideX(begin: 0.2, end: 0, delay: 500.ms),
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.highlighted = false,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.primary.withValues(alpha: 0.05)
            : AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlighted
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.borderLight,
          width: highlighted ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    )
        .animate(onPlay: highlighted ? (c) => c.repeat(reverse: true) : null)
        .scaleXY(
          begin: 1.0,
          end: highlighted ? 1.03 : 1.0,
          duration: 2000.ms,
        );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED LAYOUT
// ═══════════════════════════════════════════════════════════════════════════════

class _SlideLayout extends StatelessWidget {
  const _SlideLayout({
    required this.illustration,
    required this.title,
    this.nepaliTitle,
    required this.body,
    required this.lang,
  });
  final Widget illustration;
  final String title;
  final String? nepaliTitle;
  final String body;
  final String lang;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          // Illustration (60% area)
          Expanded(
            flex: 6,
            child: Center(child: illustration),
          ),
          // Text (40% area)
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Text(
                  title,
                  style: AppTextStyles.displaySmall(lang: lang).copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (nepaliTitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    nepaliTitle!,
                    style: AppTextStyles.titleMedium(lang: 'ne').copyWith(
                      color: AppColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: Text(
                    body,
                    style: AppTextStyles.bodyLarge(lang: lang),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page indicator dot ────────────────────────────────────────────────────────

class _Dot extends StatelessWidget {
  const _Dot({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 6),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.borderMedium,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
    );
  }
}
