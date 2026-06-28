import 'dart:math' as math;
import 'package:flutter/material.dart';

/// SafeBuy Nepal logo — a trust shield carrying the Nepal flag's
/// white crescent moon and 12-ray sun, with a verification check.
/// Crimson → blue gradient (Nepal flag colours). Drawn with CustomPainter
/// so it scales crisply and matches the website logo exactly.
class NepalLogo extends StatelessWidget {
  const NepalLogo({super.key, this.size = 80});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _NepalLogoPainter(),
        size: Size(size, size),
      ),
    );
  }
}

class _NepalLogoPainter extends CustomPainter {
  // Logo is authored on a 120 x 132 canvas (matches the website SVG).
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height / 132.0;
    final logoW = 120.0 * scale;
    final dx = (size.width - logoW) / 2;

    double x(double v) => dx + v * scale;
    double y(double v) => v * scale;
    double s(double v) => v * scale;

    // ── Shield (double-pennon top, pointed base) ───────────────────
    final shield = Path()
      ..moveTo(x(60), y(11))
      ..cubicTo(x(52), y(5), x(40), y(5), x(31), y(8))
      ..cubicTo(x(23), y(10), x(13), y(10), x(13), y(21))
      ..lineTo(x(13), y(66))
      ..cubicTo(x(13), y(96), x(37), y(116), x(60), y(127))
      ..cubicTo(x(83), y(116), x(107), y(96), x(107), y(66))
      ..lineTo(x(107), y(21))
      ..cubicTo(x(107), y(10), x(97), y(10), x(89), y(8))
      ..cubicTo(x(80), y(5), x(68), y(5), x(60), y(11))
      ..close();

    final bounds = shield.getBounds();
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE4163C), Color(0xFFC1121F), Color(0xFF013A8F)],
        stops: [0.0, 0.52, 1.0],
      ).createShader(bounds);
    canvas.drawPath(shield, bodyPaint);

    // Shield edge
    canvas.drawPath(
      shield,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s(3.0)
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white.withValues(alpha: 0.55),
    );

    // ── Crescent moon (Nepal flag) ─────────────────────────────────
    final big = Path()
      ..addOval(Rect.fromCircle(center: Offset(x(57), y(34)), radius: s(12.5)));
    final small = Path()
      ..addOval(Rect.fromCircle(center: Offset(x(62.5), y(30)), radius: s(10.5)));
    final moon = Path.combine(PathOperation.difference, big, small);
    canvas.drawPath(moon, Paint()..color = Colors.white.withValues(alpha: 0.96));

    // ── Sun: 12 rays + disc (Nepal flag) ───────────────────────────
    _drawSun(canvas, x(60), y(76), s(21), s(13), 12,
        Colors.white.withValues(alpha: 0.96));
    canvas.drawCircle(Offset(x(60), y(76)), s(10),
        Paint()..color = Colors.white.withValues(alpha: 0.96));

    // ── Verification check inside the sun ──────────────────────────
    final check = Path()
      ..moveTo(x(54.5), y(76))
      ..lineTo(x(59), y(81))
      ..lineTo(x(67.5), y(71));
    canvas.drawPath(
      check,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s(3.6)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFFC1121F),
    );
  }

  void _drawSun(Canvas canvas, double cx, double cy, double outerR,
      double innerR, int rays, Color color) {
    final path = Path();
    for (int i = 0; i < rays * 2; i++) {
      final radius = i.isEven ? outerR : innerR;
      final angle = (math.pi * i / rays) - math.pi / 2;
      final px = cx + radius * math.cos(angle);
      final py = cy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
