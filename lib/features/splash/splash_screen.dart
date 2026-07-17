import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/widgets/dhaka_pattern.dart';

/// SafeBuy Nepal splash — a 4-second branded sequence that tells a
/// stranger what the app is before the first screen loads. Driven by a
/// single AnimationController (kept light so first-frame jank can never
/// delay navigation).
///
/// Timeline (seconds):
///   0.0-0.6  shield outline draws itself stroke by stroke
///   0.6-1.0  shield fills, Nepal flag accent + pennant appear, pulse in
///   1.0-1.5  "SafeBuy Nepal" slides up from below
///   1.5-2.0  tagline fades in
///   2.0-2.6  three feature pills stagger in from the bottom
///   2.6-3.2  statistics row fades in
///   3.2-3.8  Nepal flag floats in the top-right corner
///   3.8-4.0  fade to white, then navigate
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _navigated = false;

  static const _pills = ['Verify Sellers', 'Report Fraud', 'Stay Safe'];

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _go();
      })
      ..forward();
    // Safety fallback: never strand the user on splash.
    Future.delayed(const Duration(milliseconds: 5500), _go);
  }

  Future<void> _go() async {
    if (_navigated || !mounted) return;
    _navigated = true;
    String route = '/onboarding';
    try {
      final prefs = await SharedPreferences.getInstance();
      final onboardingDone =
          prefs.getBool(AppConstants.prefOnboardingDone) ?? false;
      final isGuest = prefs.getBool('is_guest') ?? false;
      final signedIn = FirebaseAuth.instance.currentUser != null;
      if (!onboardingDone) {
        route = '/onboarding';
      } else if (signedIn || isGuest) {
        route = '/home';
      } else {
        route = '/auth';
      }
    } catch (_) {
      route = '/onboarding';
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Progress 0..1 within the [start]..[end] window of the 4s timeline
  /// (both in seconds).
  double _seg(double start, double end) =>
      ((_c.value * 4 - start) / (end - start)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final drawT = _seg(0.0, 0.6);
          final fillT = Curves.easeOut.transform(_seg(0.6, 1.0));
          final pulseT = Curves.easeOutBack.transform(_seg(0.6, 1.0));
          final nameT = Curves.easeOutCubic.transform(_seg(1.0, 1.5));
          final tagT = Curves.easeOut.transform(_seg(1.5, 2.0));
          final statsT = Curves.easeOut.transform(_seg(2.6, 3.2));
          final flagT = Curves.easeOut.transform(_seg(3.2, 3.8));
          final fadeT = _seg(3.8, 4.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              // Deep blue gradient background
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
                  ),
                ),
              ),

              // Dhaka fabric motif, barely visible over the gradient
              const AnimatedDhakaPattern(opacity: 0.08),

              // Floating particles (20 circles drifting upward)
              CustomPaint(painter: _ParticlePainter(_c.value)),

              // Nepal flag floats gently in the corner (3.2s onward)
              Positioned(
                right: 20,
                top: MediaQuery.paddingOf(context).top +
                    14 +
                    math.sin(_c.value * math.pi * 6) * 3,
                child: Opacity(
                  opacity: 0.9 * flagT,
                  child: const Text('🇳🇵', style: TextStyle(fontSize: 20)),
                ),
              ),

              // Center column
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // SafeBuy shield: outline draws, then fills with the
                    // Nepal accent and its pennant, pulsing 0.9 -> 1.0.
                    Transform.scale(
                      scale: 0.9 + 0.1 * pulseT,
                      child: SizedBox(
                        width: 90,
                        height: 90,
                        child: CustomPaint(
                          painter: _ShieldLogoPainter(
                            drawProgress: drawT,
                            fillProgress: fillT,
                          ),
                          child: Center(
                            child: Opacity(
                              opacity: fillT,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'SB',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),

                    // App name slides up from below (20px)
                    ClipRect(
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - nameT)),
                        child: Opacity(
                          opacity: nameT,
                          child: Text(
                            'SafeBuy Nepal',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Tagline
                    Opacity(
                      opacity: tagT,
                      child: Text(
                        "Nepal's Seller Verification Platform",
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Three feature pills, staggered 200ms apart,
                    // each sliding in from the bottom.
                    SizedBox(
                      height: 34,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(_pills.length, (i) {
                          final t = Curves.easeOutCubic.transform(
                              _seg(2.0 + i * 0.2, 2.4 + i * 0.2));
                          return Opacity(
                            opacity: t,
                            child: Transform.translate(
                              offset: Offset(0, 16 * (1 - t)),
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 5),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _pills[i],
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),

              // Statistics row near the bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: MediaQuery.paddingOf(context).bottom + 42,
                child: Opacity(
                  opacity: 0.7 * statsT,
                  child: Text(
                    '1,247 Sellers Verified  •  389 Reports  •  NPR 2.1M Saved',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),

              // Fade to white before navigation
              if (fadeT > 0)
                IgnorePointer(
                  child: Container(
                    color: Colors.white.withValues(alpha: fadeT),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── SafeBuy shield logo ────────────────────────────────────────────────────────
//
// White shield outline that draws itself, then fills with a glass white.
// Inside: a crimson-and-blue Nepal accent band. On the top right of the
// shield, a small Nepal double-pennant flag on a pole.

class _ShieldLogoPainter extends CustomPainter {
  _ShieldLogoPainter({
    required this.drawProgress,
    required this.fillProgress,
  });

  final double drawProgress;
  final double fillProgress;

  static const _crimson = Color(0xFFDC143C);
  static const _flagBlue = Color(0xFF003893);

  Path _shieldPath(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.5, h * 0.05)
      ..cubicTo(w * 0.38, h * 0.12, w * 0.16, h * 0.15, w * 0.08, h * 0.16)
      ..lineTo(w * 0.08, h * 0.52)
      ..cubicTo(w * 0.08, h * 0.74, w * 0.30, h * 0.89, w * 0.5, h * 0.96)
      ..cubicTo(w * 0.70, h * 0.89, w * 0.92, h * 0.74, w * 0.92, h * 0.52)
      ..lineTo(w * 0.92, h * 0.16)
      ..cubicTo(w * 0.84, h * 0.15, w * 0.62, h * 0.12, w * 0.5, h * 0.05)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = _shieldPath(size);

    // Glass fill once the outline has drawn.
    if (fillProgress > 0) {
      canvas.drawPath(
        path,
        Paint()..color = Colors.white.withValues(alpha: 0.16 * fillProgress),
      );

      // Nepal accent: crimson band with a thin flag-blue edge, clipped
      // to the shield, sitting under the "SB" monogram.
      canvas.save();
      canvas.clipPath(path);
      final bandTop = h * 0.68;
      canvas.drawRect(
        Rect.fromLTRB(0, bandTop, w, bandTop + h * 0.09),
        Paint()..color = _crimson.withValues(alpha: 0.9 * fillProgress),
      );
      canvas.drawRect(
        Rect.fromLTRB(0, bandTop - h * 0.025, w, bandTop),
        Paint()..color = _flagBlue.withValues(alpha: 0.9 * fillProgress),
      );
      canvas.restore();
    }

    // Outline draws itself stroke by stroke.
    if (drawProgress > 0) {
      final stroke = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      if (drawProgress >= 1) {
        canvas.drawPath(path, stroke);
      } else {
        for (final metric in path.computeMetrics()) {
          canvas.drawPath(
            metric.extractPath(0, metric.length * drawProgress),
            stroke,
          );
        }
      }
    }

    // Small Nepal double-pennant on a pole at the shield's top right.
    if (fillProgress > 0) {
      final alpha = fillProgress;
      final poleX = w * 0.94;
      final poleTop = h * 0.02;
      final poleBottom = h * 0.20;
      canvas.drawLine(
        Offset(poleX, poleTop),
        Offset(poleX, poleBottom),
        Paint()
          ..color = Colors.white.withValues(alpha: alpha)
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round,
      );
      final pennant = Path()
        ..moveTo(poleX, poleTop)
        ..lineTo(poleX + w * 0.14, h * 0.055)
        ..lineTo(poleX, h * 0.085)
        ..lineTo(poleX + w * 0.14, h * 0.125)
        ..lineTo(poleX, h * 0.16)
        ..close();
      canvas.drawPath(
        pennant,
        Paint()..color = _crimson.withValues(alpha: alpha),
      );
      canvas.drawPath(
        pennant,
        Paint()
          ..color = _flagBlue.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1,
      );
    }
  }

  @override
  bool shouldRepaint(_ShieldLogoPainter old) =>
      old.drawProgress != drawProgress || old.fillProgress != fillProgress;
}

// ── Floating particles ─────────────────────────────────────────────────────────

class _ParticlePainter extends CustomPainter {
  _ParticlePainter(this.t);

  final double t;
  static final _rng = math.Random(7);
  static final List<_Particle> _particles = List.generate(20, (_) {
    return _Particle(
      x: _rng.nextDouble(),
      y: _rng.nextDouble(),
      r: 1.5 + _rng.nextDouble() * 2.5,
      speed: 0.04 + _rng.nextDouble() * 0.08,
      alpha: 0.10 + _rng.nextDouble() * 0.10,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in _particles) {
      final y = ((p.y - t * p.speed * 6) % 1.0 + 1.0) % 1.0;
      paint.color = Colors.white.withValues(alpha: p.alpha);
      canvas.drawCircle(
        Offset(p.x * size.width, y * size.height),
        p.r,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.t != t;
}

class _Particle {
  const _Particle({
    required this.x,
    required this.y,
    required this.r,
    required this.speed,
    required this.alpha,
  });
  final double x, y, r, speed, alpha;
}
