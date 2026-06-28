import 'package:flutter/material.dart';
import '../core/widgets/nepal_logo.dart';

/// Full-screen "Namaste" welcome shown on first launch.
/// Renders immediately (no delayed gate) with a single fade-in so it can
/// never get stuck invisible on slow devices.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  double _opacity = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _opacity = 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A1628), Color(0xFF1A3A5C), Color(0xFF0D47A1)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: AnimatedOpacity(
            opacity: _opacity,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            child: Column(
              children: [
                const Spacer(flex: 2),
                // Logo
                Container(
                  width: 116,
                  height: 116,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFDC143C).withValues(alpha: 0.45),
                        blurRadius: 35,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: const Color(0xFF003893).withValues(alpha: 0.3),
                        blurRadius: 25,
                      ),
                    ],
                  ),
                  child: const Center(child: NepalLogo(size: 108)),
                ),
                const SizedBox(height: 32),
                const Text(
                  'नमस्ते 🙏',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 46,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Welcome to',
                  style: TextStyle(color: Color(0xFF90CAF9), fontSize: 16),
                ),
                const SizedBox(height: 4),
                const Text(
                  'SafeBuy Nepal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    'Nepal\'s trusted seller verification\n& fraud protection platform\n\nनेपालको विश्वसनीय विक्रेता प्रमाणीकरण\nर ठगी संरक्षण प्लेटफर्म',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Color(0xFF90CAF9), fontSize: 14, height: 1.7),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_rounded,
                          color: Color(0xFF81C784), size: 16),
                      SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          '5,432+ buyers protected across Nepal',
                          style: TextStyle(
                            color: Color(0xFF81C784),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
                // Continue
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pushReplacementNamed(
                              context, '/language'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC143C),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 8,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Get Started  •  सुरु गर्नुहोस्',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Powered by community trust',
                        style: TextStyle(color: Color(0xFF64B5F6), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
