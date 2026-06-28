import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Trust badge that accepts a trustVerdict string (trusted/unverified/high_risk)
class TrustBadge extends StatelessWidget {
  final String trustVerdict;
  final bool large;

  const TrustBadge({super.key, required this.trustVerdict, this.large = false});

  @override
  Widget build(BuildContext context) {
    final config = _config(trustVerdict);
    final fontSize = large ? 13.0 : 11.0;
    final padding = large
        ? const EdgeInsets.symmetric(horizontal: 14, vertical: 6)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 4);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: config['color'] as Color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config['icon'] as IconData,
              color: Colors.white, size: large ? 16 : 13),
          const SizedBox(width: 4),
          Text(
            config['label'] as String,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _config(String verdict) {
    switch (verdict) {
      case 'trusted':
        return {
          'color': const Color(AppColors.trusted),
          'icon': Icons.verified,
          'label': 'TRUSTED',
        };
      case 'high_risk':
        return {
          'color': const Color(AppColors.highRisk),
          'icon': Icons.warning_amber_rounded,
          'label': 'HIGH RISK',
        };
      default:
        return {
          'color': const Color(0xFFB5860D),
          'icon': Icons.help_outline,
          'label': 'UNVERIFIED',
        };
    }
  }
}

class TrustScoreCircle extends StatelessWidget {
  final double score;
  final double size;

  const TrustScoreCircle({super.key, required this.score, this.size = 120});

  Color get _color {
    if (score >= 80) return const Color(AppColors.trusted);
    if (score >= 50) return const Color(0xFFB5860D);
    return const Color(AppColors.highRisk);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: score / 100,
            strokeWidth: 10,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(_color),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                score.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: size * 0.27,
                  fontWeight: FontWeight.w800,
                  color: _color,
                ),
              ),
              Text(
                '/100',
                style: TextStyle(
                  fontSize: size * 0.11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
