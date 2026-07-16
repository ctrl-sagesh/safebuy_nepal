import 'package:flutter/material.dart';

/// Repeating diamond/rhombus motif inspired by Nepali Dhaka fabric.
/// Painted as a subtle overlay on hero surfaces; [shift] slides the
/// pattern slowly for a gentle "woven" motion.
class DhakaPatternPainter extends CustomPainter {
  DhakaPatternPainter({
    required this.color,
    this.opacity = 0.06,
    this.shift = 0,
    this.cell = 26,
  });

  final Color color;
  final double opacity;

  /// 0..1 — one full cell of horizontal drift.
  final double shift;
  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final fill = Paint()
      ..color = color.withValues(alpha: opacity * 0.55)
      ..style = PaintingStyle.fill;

    final dx = shift * cell * 2;
    final half = cell / 2;

    for (double y = -cell; y < size.height + cell; y += cell) {
      final rowOffset = ((y / cell).round().isEven ? 0.0 : cell) + dx;
      for (double x = -cell * 2 + rowOffset;
          x < size.width + cell;
          x += cell * 2) {
        final path = Path()
          ..moveTo(x, y - half)
          ..lineTo(x + half, y)
          ..lineTo(x, y + half)
          ..lineTo(x - half, y)
          ..close();
        canvas.drawPath(path, paint);
        // Small solid diamond nested in every other cell.
        final inner = Path()
          ..moveTo(x, y - half * 0.35)
          ..lineTo(x + half * 0.35, y)
          ..lineTo(x, y + half * 0.35)
          ..lineTo(x - half * 0.35, y)
          ..close();
        canvas.drawPath(inner, fill);
      }
    }
  }

  @override
  bool shouldRepaint(DhakaPatternPainter old) =>
      old.shift != shift ||
      old.opacity != opacity ||
      old.color != color ||
      old.cell != cell;
}

/// Self-animating Dhaka overlay: position it inside a [Stack] with
/// `Positioned.fill`. Drifts one pattern cell every [period].
class AnimatedDhakaPattern extends StatefulWidget {
  const AnimatedDhakaPattern({
    super.key,
    this.color = Colors.white,
    this.opacity = 0.06,
    this.period = const Duration(seconds: 10),
  });

  final Color color;
  final double opacity;
  final Duration period;

  @override
  State<AnimatedDhakaPattern> createState() => _AnimatedDhakaPatternState();
}

class _AnimatedDhakaPatternState extends State<AnimatedDhakaPattern>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift =
      AnimationController(vsync: this, duration: widget.period)..repeat();

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _drift,
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: DhakaPatternPainter(
              color: widget.color,
              opacity: widget.opacity,
              shift: _drift.value,
            ),
          ),
        ),
      ),
    );
  }
}
