import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/theme/app_colors.dart';

/// Full-screen QR scanner: reads a seller's eSewa/Khalti QR, extracts the
/// phone number from the payload, and pops it back to the Search screen.
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen>
    with TickerProviderStateMixin {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    formats: const [BarcodeFormat.qrCode],
  );

  /// Nepali mobile inside a QR payload, with or without +977/977 prefix.
  static final _phoneRe = RegExp(r'(?:\+?977[-\s]?)?(9[78]\d{8})');

  bool _handled = false;
  bool _showFail = false;

  late final AnimationController _scanLine = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  @override
  void dispose() {
    _scanLine.dispose();
    _shake.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final raw = capture.barcodes
        .map((b) => b.rawValue ?? '')
        .firstWhere((v) => v.isNotEmpty, orElse: () => '');
    if (raw.isEmpty) return;

    final match = _phoneRe.firstMatch(raw);
    if (match != null) {
      _handled = true;
      HapticFeedback.mediumImpact();
      Navigator.pop(context, match.group(1));
      return;
    }

    // QR decoded but no Nepali phone number inside it.
    _handled = true;
    HapticFeedback.vibrate();
    _shake.forward(from: 0);
    setState(() => _showFail = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _showFail = false);
      _handled = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const frameSize = 260.0;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),

          // Dim everything except the scan window.
          CustomPaint(
            painter: _ScrimPainter(frameSize: frameSize),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),
                Text('Scan Seller QR',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 6),
                Text("Scan seller's eSewa or Khalti QR code",
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    )),
                const Spacer(),

                // Scan frame + moving line (shakes on failure)
                AnimatedBuilder(
                  animation: _shake,
                  builder: (context, child) {
                    final dx = math.sin(_shake.value * math.pi * 5) *
                        (1 - _shake.value) *
                        12;
                    return Transform.translate(
                        offset: Offset(dx, 0), child: child);
                  },
                  child: SizedBox(
                    width: frameSize,
                    height: frameSize,
                    child: Stack(
                      children: [
                        CustomPaint(
                          size: const Size(frameSize, frameSize),
                          painter: _CornersPainter(
                            color: _showFail
                                ? AppColors.highRisk
                                : Colors.white,
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _scanLine,
                          builder: (context, _) => Positioned(
                            top: 12 +
                                _scanLine.value * (frameSize - 26),
                            left: 14,
                            right: 14,
                            child: Container(
                              height: 2.5,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                gradient: LinearGradient(colors: [
                                  Colors.transparent,
                                  _showFail
                                      ? AppColors.highRisk
                                      : AppColors.accentCyan,
                                  Colors.transparent,
                                ]),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 22),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _showFail ? 1 : 0,
                  child: Column(
                    children: [
                      Text('Could not read QR code',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          )),
                      Text('Try typing the phone number manually.',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12,
                          )),
                    ],
                  ),
                ),
                const Spacer(),

                Padding(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      minimumSize: const Size(150, 46),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                    ),
                    child: const Text('Cancel'),
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

/// Dims the camera preview everywhere except the central scan window.
class _ScrimPainter extends CustomPainter {
  _ScrimPainter({required this.frameSize});

  final double frameSize;

  @override
  void paint(Canvas canvas, Size size) {
    final window = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: frameSize,
      height: frameSize,
    );
    final path = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()
        ..addRRect(
            RRect.fromRectAndRadius(window, const Radius.circular(22))),
    );
    canvas.drawPath(
        path, Paint()..color = Colors.black.withValues(alpha: 0.55));
  }

  @override
  bool shouldRepaint(_ScrimPainter old) => old.frameSize != frameSize;
}

/// White rounded corner brackets of the scan frame.
class _CornersPainter extends CustomPainter {
  _CornersPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const len = 34.0;
    const r = 22.0;
    final w = size.width;
    final h = size.height;

    // Top-left
    canvas.drawPath(
        Path()
          ..moveTo(0, len)
          ..lineTo(0, r)
          ..quadraticBezierTo(0, 0, r, 0)
          ..lineTo(len, 0),
        paint);
    // Top-right
    canvas.drawPath(
        Path()
          ..moveTo(w - len, 0)
          ..lineTo(w - r, 0)
          ..quadraticBezierTo(w, 0, w, r)
          ..lineTo(w, len),
        paint);
    // Bottom-right
    canvas.drawPath(
        Path()
          ..moveTo(w, h - len)
          ..lineTo(w, h - r)
          ..quadraticBezierTo(w, h, w - r, h)
          ..lineTo(w - len, h),
        paint);
    // Bottom-left
    canvas.drawPath(
        Path()
          ..moveTo(len, h)
          ..lineTo(r, h)
          ..quadraticBezierTo(0, h, 0, h - r)
          ..lineTo(0, h - len),
        paint);
  }

  @override
  bool shouldRepaint(_CornersPainter old) => old.color != color;
}
