import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/widgets/dhaka_pattern.dart';
import '../../core/widgets/nepal_logo.dart';

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
                    // SafeBuy Nepal brand logo, fading + scaling in.
                    Transform.scale(
                      scale: 0.9 + 0.1 * pulseT,
                      child: Opacity(
                        opacity: Curves.easeOut.transform(_seg(0.0, 0.9)),
                        child: const NepalLogo(size: 96),
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
