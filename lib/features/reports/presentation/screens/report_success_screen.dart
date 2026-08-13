import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/language_provider.dart';

/// Report submitted — confetti + report id.
class ReportSuccessScreen extends ConsumerStatefulWidget {
  const ReportSuccessScreen({
    super.key,
    required this.reportId,
    this.sellerId,
  });

  final String reportId;
  final String? sellerId;

  @override
  ConsumerState<ReportSuccessScreen> createState() =>
      _ReportSuccessScreenState();
}

class _ReportSuccessScreenState extends ConsumerState<ReportSuccessScreen> {
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 4));

  /// Current UI language ('en' | 'ne'); refreshed at the top of build().
  String _lang = 'en';
  String _t(String en, String ne) => _lang == 'ne' ? ne : en;

  /// Every third particle is a small shield; the rest are rectangles.
  static int _particleCount = 0;

  static Path _confettiParticle(Size size) {
    _particleCount++;
    if (_particleCount % 3 == 0) {
      // Simple shield silhouette.
      final w = size.width;
      final h = size.height;
      return Path()
        ..moveTo(w / 2, 0)
        ..lineTo(w, h * 0.22)
        ..lineTo(w * 0.86, h * 0.62)
        ..quadraticBezierTo(w * 0.72, h * 0.9, w / 2, h)
        ..quadraticBezierTo(w * 0.28, h * 0.9, w * 0.14, h * 0.62)
        ..lineTo(0, h * 0.22)
        ..close();
    }
    return Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.6));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _confetti.play());
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  String get _shortId {
    final year = DateTime.now().year;
    final tail = widget.reportId.length >= 5
        ? widget.reportId.substring(0, 5).toUpperCase()
        : widget.reportId.toUpperCase();
    return 'RPT-$year-$tail';
  }

  @override
  Widget build(BuildContext context) {
    _lang = ref.watch(languageProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),
                  Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      color: AppColors.trustedBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: AppColors.trusted, size: 54),
                  ).animate().scaleXY(
                      begin: 0.4,
                      end: 1,
                      duration: 550.ms,
                      curve: Curves.elasticOut),
                  const SizedBox(height: 22),
                  Text(_t('Report Submitted!', 'उजुरी पेस भयो!'),
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      )).animate().fadeIn(delay: 250.ms),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.bgSecondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_shortId,
                        style: GoogleFonts.robotoMono(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        )),
                  ).animate().fadeIn(delay: 350.ms),
                  const SizedBox(height: 14),
                  Text(
                    _t('Thank you for protecting Nepal\'s buyer community.',
                        'नेपालको ग्राहक समुदाय जोगाएकोमा धन्यवाद।'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ).animate().fadeIn(delay: 450.ms),
                  const SizedBox(height: 18),

                  // What happens next
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bgSecondary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_t('What happens next:', 'अब के हुन्छ:'),
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            )),
                        const SizedBox(height: 8),
                        ...[
                          _t(
                              'The seller\'s trust rating updates within minutes',
                              'विक्रेताको ट्रस्ट रेटिङ केही मिनेटमै अपडेट हुन्छ'),
                          _t(
                              'Future buyers will see a warning before paying this seller',
                              'भावी ग्राहकले यो विक्रेतालाई तिर्नुअघि चेतावनी देख्नेछन्'),
                          _t(
                              'If 3 or more reports are filed, a community alert is posted',
                              '३ वा बढी उजुरी परे, सामुदायिक सतर्कता जारी हुन्छ'),
                        ].asMap().entries.map((e) => Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 3),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary50,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text('${e.key + 1}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        )),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(e.value,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color:
                                              AppColors.textSecondary,
                                          height: 1.5,
                                        )),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ).animate().fadeIn(delay: 550.ms),
                  const Spacer(),
                  if (widget.sellerId?.isNotEmpty == true)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pushReplacementNamed(
                            context, '/seller',
                            arguments: {'sellerId': widget.sellerId}),
                        child: Text(_t('View Seller Profile',
                            'विक्रेता प्रोफाइल हेर्नुहोस्')),
                      ),
                    ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context)
                            .pushNamedAndRemoveUntil(
                                '/home', (r) => false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        child: Text(_t('Back to Home', 'गृहमा फर्कनुहोस्')),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Nepal-flag confetti: crimson, blue, and white pieces.
          ConfettiWidget(
            confettiController: _confetti,
            blastDirection: math.pi / 2,
            emissionFrequency: 0.08,
            numberOfParticles: 30,
            maxBlastForce: 24,
            minBlastForce: 8,
            createParticlePath: _confettiParticle,
            colors: const [
              Color(0xFFDC143C),
              Color(0xFF003893),
              Colors.white,
            ],
          ),
        ],
      ),
    );
  }
}
