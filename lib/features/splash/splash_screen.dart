import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/nepal_logo.dart';

/// Lightweight, reliable splash. Shows the SafeBuy Nepal logo + name, then
/// routes to welcome / onboarding / home. Kept deliberately simple (no heavy
/// per-frame painters) so it never stalls on low-end devices/emulators.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;
  double _opacity = 0;

  @override
  void initState() {
    super.initState();
    // Fade content in after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _opacity = 1);
    });
    // Navigate after a short, fixed delay.
    Timer(const Duration(milliseconds: 1900), _go);
  }

  Future<void> _go() async {
    if (_navigated || !mounted) return;
    _navigated = true;

    String route = '/welcome';
    try {
      final prefs = await SharedPreferences.getInstance();
      final onboardingDone =
          prefs.getBool(AppConstants.prefOnboardingDone) ?? false;
      final langSet = prefs.getString(AppConstants.prefLanguage) != null;
      if (!langSet) {
        route = '/welcome';
      } else if (!onboardingDone) {
        route = '/onboarding';
      } else {
        route = '/home';
      }
    } catch (_) {
      route = '/welcome';
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1976D2)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: AnimatedOpacity(
                  opacity: _opacity,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 116,
                        height: 116,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFDC143C)
                                  .withValues(alpha: 0.35),
                              blurRadius: 40,
                            ),
                            BoxShadow(
                              color: const Color(0xFF013A8F)
                                  .withValues(alpha: 0.3),
                              blurRadius: 28,
                            ),
                          ],
                        ),
                        child: const Center(child: NepalLogo(size: 108)),
                      ),
                      const SizedBox(height: 26),
                      Text(
                        'SafeBuy Nepal',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'सुरक्षित किनमेल',
                        style: GoogleFonts.notoSansDevanagari(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Secure Shopping',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Loading indicator
              Positioned(
                bottom: 56,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation(
                        Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ),
              ),
              // Academic credit
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Text(
                  'Sagesh Adhikari • Softwarica College',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.25),
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
