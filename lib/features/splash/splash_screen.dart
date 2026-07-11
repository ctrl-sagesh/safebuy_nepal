import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';

/// SafeBuy Nepal splash — 3-second staged animation sequence driven by a
/// single AnimationController (kept deliberately light so first-frame jank
/// can never delay navigation).
///
/// t 0.00-0.17  shield outline draws itself
/// t 0.17-0.30  shield fills (glass) + "SB" appears
/// t 0.30-0.43  "SafeBuy Nepal" slides up
/// t 0.43-0.57  Nepali + English taglines fade in
/// t 0.57-0.77  three loading dots pulse
/// t 0.77-1.00  fade to white, then navigate
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _go();
      })
      ..forward();
    // Safety fallback: never strand the user on splash.
    Future.delayed(const Duration(milliseconds: 4500), _go);
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

  double _seg(double start, double end) =>
      ((_c.value - start) / (end - start)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final drawT = _seg(0.00, 0.17);
          final fillT = _seg(0.17, 0.30);
          final nameT = Curves.easeOutCubic.transform(_seg(0.30, 0.43));
          final tagT = _seg(0.43, 0.57);
          final dotsT = _seg(0.57, 0.77);
          final fadeT = _seg(0.77, 1.00);

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

              // Floating particles (20 circles drifting upward)
              CustomPaint(painter: _ParticlePainter(_c.value)),

              // Center column
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Shield draws then fills, "SB" appears
                    SizedBox(
                      width: 96,
                      height: 104,
                      child: CustomPaint(
                        painter: _ShieldPainter(
                          drawProgress: drawT,
                          fillOpacity: 0.15 * fillT,
                        ),
                        child: Center(
                          child: Opacity(
                            opacity: fillT,
                            child: Text(
                              'SB',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // App name slides up
                    ClipRect(
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - nameT)),
                        child: Opacity(
                          opacity: nameT,
                          child: Text(
                            'SafeBuy Nepal',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Taglines fade in
                    Opacity(
                      opacity: tagT,
                      child: Column(
                        children: [
                          Text(
                            'सुरक्षित किनमेल',
                            style: GoogleFonts.notoSansDevanagari(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Secure Shopping',
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 44),

                    // Three staggered loading dots
                    SizedBox(
                      height: 18,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (i) {
                          final phase =
                              ((dotsT * 3.0) - i * 0.33).clamp(0.0, 1.0);
                          final scale = 1.0 + 0.5 * math.sin(phase * math.pi);
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 5),
                            child: Transform.scale(
                              scale: dotsT == 0 ? 0 : scale,
                              child: Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  shape: BoxShape.circle,
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

// ── Shield outline + glass fill ────────────────────────────────────────────────

class _ShieldPainter extends CustomPainter {
  _ShieldPainter({required this.drawProgress, required this.fillOpacity});

  final double drawProgress;
  final double fillOpacity;

  Path _shieldPath(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.5, h * 0.03)
      ..cubicTo(w * 0.38, h * 0.10, w * 0.16, h * 0.13, w * 0.08, h * 0.14)
      ..lineTo(w * 0.08, h * 0.52)
      ..cubicTo(w * 0.08, h * 0.75, w * 0.30, h * 0.90, w * 0.5, h * 0.97)
      ..cubicTo(w * 0.70, h * 0.90, w * 0.92, h * 0.75, w * 0.92, h * 0.52)
      ..lineTo(w * 0.92, h * 0.14)
      ..cubicTo(w * 0.84, h * 0.13, w * 0.62, h * 0.10, w * 0.5, h * 0.03)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _shieldPath(size);

    if (fillOpacity > 0) {
      canvas.drawPath(
        path,
        Paint()..color = Colors.white.withValues(alpha: fillOpacity),
      );
    }

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
  }

  @override
  bool shouldRepaint(_ShieldPainter old) =>
      old.drawProgress != drawProgress || old.fillOpacity != fillOpacity;
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
