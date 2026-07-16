import 'package:flutter/material.dart';

/// Soft pulsing glow behind trust badges: green breathes slowly,
/// red pulses faster and more intensely (danger), amber gets a gentle
/// shimmer-like pulse.
class PulseGlow extends StatefulWidget {
  const PulseGlow({
    super.key,
    required this.color,
    required this.child,
    this.duration = const Duration(milliseconds: 2000),
    this.minOpacity = 0.3,
    this.maxOpacity = 0.6,
    this.maxScale = 1.03,
  });

  /// Danger preset: faster, stronger pulse.
  const PulseGlow.danger({
    super.key,
    required this.color,
    required this.child,
  })  : duration = const Duration(milliseconds: 1200),
        minOpacity = 0.35,
        maxOpacity = 0.75,
        maxScale = 1.04;

  final Color color;
  final Widget child;
  final Duration duration;
  final double minOpacity;
  final double maxOpacity;
  final double maxScale;

  @override
  State<PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<PulseGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: widget.duration)
        ..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_pulse.value);
        final opacity = widget.minOpacity +
            (widget.maxOpacity - widget.minOpacity) * t;
        final scale = 1 + (widget.maxScale - 1) * t;
        return Transform.scale(
          scale: scale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: opacity),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
