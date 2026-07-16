import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/popup_helper.dart';

/// 4-slide onboarding that makes a stranger FEEL the problem before
/// showing the solution.
/// Slide 1: the ghosted-buyer story   · Slide 2: check before you pay
/// Slide 3: report once, protect all  · Slide 4: account vs guest choice
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
                children: [
                  const _ProblemSlide(),
                  const _SolutionSlide(),
                  const _CommunitySlide(),
                  _ChoiceSlide(
                    onCreateAccount: () => _complete(asGuest: false),
                    onBrowse: () => _complete(asGuest: true),
                  ),
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
            const SizedBox(height: 16),

            // Next button on slides 1-3; slide 4 uses its own card buttons.
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
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
                  : const SizedBox(height: 4),
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
    required this.headline,
    required this.body,
    this.footnote,
  });

  final Widget illustration;
  final String headline;
  final String body;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(height: 260, child: Center(child: illustration)),
          const SizedBox(height: 24),
          Text(
            headline,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 23,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              height: 1.65,
              color: AppColors.textSecondary,
            ),
          ),
          if (footnote != null) ...[
            const SizedBox(height: 14),
            Text(
              footnote!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
                color: AppColors.textMuted,
              ),
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── Slide 1: THE PROBLEM — a conversation that goes silent ─────────────────────

class _ProblemSlide extends StatelessWidget {
  const _ProblemSlide();

  Widget _bubble(String text,
      {required bool isBuyer, double maxWidth = 200}) {
    return Align(
      alignment: isBuyer ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isBuyer ? AppColors.primary : const Color(0xFF2A3648),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isBuyer ? 14 : 4),
            bottomRight: Radius.circular(isBuyer ? 4 : 14),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SlideBody(
      illustration: Container(
        width: 290,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF10203A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF29405F), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _bubble('Payment garnu hos NPR 3,500', isBuyer: false),
            _bubble('Delivery 3 din ma', isBuyer: false),
            _bubble('eSewa garchhu', isBuyer: true),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Seen',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 10.5,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.schedule_rounded,
                    color: Color(0xFFFF6B6B), size: 15),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '7 days later... no product, no reply',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: const Color(0xFFFF6B6B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      headline: 'Sound familiar?',
      body: 'Every month, thousands of Nepali buyers lose money to '
          'TikTok and Instagram sellers who disappear after payment. '
          'There was no way to know who to trust.',
      footnote: 'NPR 40 crore lost in 2023 alone — Nepal Police Report',
    );
  }
}

// ── Slide 2: THE SOLUTION — search before you pay ──────────────────────────────

class _SolutionSlide extends StatelessWidget {
  const _SolutionSlide();

  @override
  Widget build(BuildContext context) {
    return _SlideBody(
      illustration: Container(
        width: 250,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF10203A),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF29405F), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search bar with the number typed in
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search,
                      size: 15, color: Colors.white70),
                  const SizedBox(width: 6),
                  Text('9841234567',
                      style: GoogleFonts.robotoMono(
                          color: Colors.white, fontSize: 12.5)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Seller result card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.trustedBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('TRUSTED',
                            style: GoogleFonts.poppins(
                              color: AppColors.trusted,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            )),
                      ),
                      const Spacer(),
                      Text('87/100',
                          style: GoogleFonts.poppins(
                            color: AppColors.trusted,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          )),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Priya Fashions',
                      style: GoogleFonts.poppins(
                        color: AppColors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 3),
                  Text('23 reviews · 0 complaints · Verified',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
      headline: 'Check before you pay',
      body: 'Search any seller by their phone number, eSewa ID, or '
          'TikTok handle. See their trust rating, reviews, and fraud '
          'complaints — before sending a single rupee.',
    );
  }
}

// ── Slide 3: THE COMMUNITY — report once, protect thousands ────────────────────

class _CommunitySlide extends StatelessWidget {
  const _CommunitySlide();

  Widget _stepBox(IconData icon, String label, Color color) {
    return Container(
      width: 88,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.35,
              )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SlideBody(
      illustration: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _stepBox(Icons.person_rounded, 'You report\nfraud',
                  AppColors.primary),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.arrow_forward_rounded,
                    color: AppColors.textMuted, size: 20),
              ),
              _stepBox(Icons.warning_rounded, 'Score drops\ninstantly',
                  AppColors.unverified),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.arrow_forward_rounded,
                    color: AppColors.textMuted, size: 20),
              ),
              _stepBox(Icons.groups_rounded, 'Next buyer\nsees warning',
                  AppColors.trusted),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Your report protects the next buyer',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      headline: 'Report once, protect thousands',
      body: 'When you file a fraud report, the seller\'s trust rating '
          'drops immediately. Every future buyer who searches that '
          'seller will see your warning.',
    );
  }
}

// ── Slide 4: THE CHOICE — account vs guest ─────────────────────────────────────

class _ChoiceSlide extends StatelessWidget {
  const _ChoiceSlide({
    required this.onCreateAccount,
    required this.onBrowse,
  });

  final VoidCallback onCreateAccount;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Create account card
              Expanded(
                child: _OptionCard(
                  icon: Icons.person_add_alt_1_rounded,
                  iconColor: AppColors.primary,
                  borderColor: AppColors.primary,
                  title: 'Create Account',
                  points: const [
                    'Report fraud',
                    'Leave reviews',
                    'Track your history',
                    'Get notified',
                  ],
                  button: SizedBox(
                    height: 44,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          onCreateAccount();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text('Get Started',
                            style: TextStyle(fontSize: 13.5)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Guest card
              Expanded(
                child: _OptionCard(
                  icon: Icons.visibility_outlined,
                  iconColor: AppColors.grey500,
                  borderColor: AppColors.borderMedium,
                  title: 'Browse as Guest',
                  points: const [
                    'Search sellers',
                    'View trust ratings',
                    'Read community alerts',
                    'No signup needed',
                  ],
                  button: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        onBrowse();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(
                            color: AppColors.borderMedium),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text('Browse',
                          style: TextStyle(fontSize: 13.5)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Text(
            'How do you want to join?',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Both options are free. Create an account to help the '
            'community by reporting fraud and leaving reviews.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
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

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.iconColor,
    required this.borderColor,
    required this.title,
    required this.points,
    required this.button,
  });

  final IconData icon;
  final Color iconColor;
  final Color borderColor;
  final String title;
  final List<String> points;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 10),
          Text(title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 8),
          ...points.map((p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(Icons.check_rounded, size: 13, color: iconColor),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(p,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          )),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: button),
        ],
      ),
    );
  }
}
