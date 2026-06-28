import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/seller_model.dart';
import '../utils/constants.dart';
import 'trust_badge_widget.dart';

class SellerCard extends StatelessWidget {
  final SellerModel seller;
  final VoidCallback onTap;

  const SellerCard({super.key, required this.seller, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final verdictColor = _verdictColor(seller.trustVerdict);
    return Hero(
      tag: 'seller-${seller.sellerId}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: verdictColor.withValues(alpha: 0.1),
          highlightColor: verdictColor.withValues(alpha: 0.05),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: verdictColor.withValues(alpha: 0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: verdictColor.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  _avatar(verdictColor),
                  const SizedBox(width: 14),
                  Expanded(child: _info(verdictColor)),
                  _scoreColumn(verdictColor),
                ],
              ),
            ),
            // Bottom stats bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: verdictColor.withValues(alpha: 0.04),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  _miniStat(Icons.shopping_bag_outlined,
                      '${seller.totalOrders} orders', const Color(0xFF6B7280)),
                  const SizedBox(width: 16),
                  _miniStat(Icons.star_rounded,
                      seller.averageRating.toStringAsFixed(1), Colors.amber),
                  const SizedBox(width: 16),
                  _miniStat(
                    Icons.warning_amber_rounded,
                    '${seller.scamReportCount} reports',
                    seller.scamReportCount > 0
                        ? const Color(0xFFC62828)
                        : const Color(0xFF6B7280),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded,
                      color: verdictColor, size: 20),
                ],
              ),
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }

  Widget _miniStat(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _verdictColor(String verdict) {
    switch (verdict) {
      case 'trusted':
        return const Color(AppColors.trusted);
      case 'high_risk':
        return const Color(AppColors.highRisk);
      default:
        return const Color(0xFFE65100);
    }
  }

  Widget _avatar(Color accent) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.15), accent.withValues(alpha: 0.05)],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.3), width: 2),
      ),
      child: CircleAvatar(
        radius: 28,
        backgroundColor: Colors.transparent,
        backgroundImage: seller.profileImageUrl != null
            ? NetworkImage(seller.profileImageUrl!)
            : null,
        child: seller.profileImageUrl == null
            ? Text(
                seller.displayName.isNotEmpty
                    ? seller.displayName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: accent,
                ),
              )
            : null,
      ),
    );
  }

  Widget _info(Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                seller.displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFF1A1A2E),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (seller.verifiedBadge) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Color(0xFF1565C0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 12, color: Colors.white),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        if (seller.phone.isNotEmpty)
          Row(
            children: [
              const Icon(Icons.phone_outlined,
                  size: 13, color: Color(0xFF6B7280)),
              const SizedBox(width: 4),
              Text(
                seller.phone,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        const SizedBox(height: 6),
        _VerdictBadge(trustVerdict: seller.trustVerdict),
      ],
    );
  }

  Widget _scoreColumn(Color accent) {
    return Column(
      children: [
        TrustScoreCircle(score: seller.trustScore, size: 60),
      ],
    );
  }
}

class _VerdictBadge extends StatelessWidget {
  final String trustVerdict;
  const _VerdictBadge({required this.trustVerdict});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    final String label;
    switch (trustVerdict) {
      case 'trusted':
        color = const Color(0xFF2E7D32);
        icon = Icons.verified_rounded;
        label = 'TRUSTED';
        break;
      case 'high_risk':
        color = const Color(0xFFC62828);
        icon = Icons.gpp_bad_rounded;
        label = 'HIGH RISK';
        break;
      default:
        color = const Color(0xFFE65100);
        icon = Icons.help_outline_rounded;
        label = 'UNVERIFIED';
    }

    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );

    // Pulse animation for high risk
    if (trustVerdict == 'high_risk') {
      badge = badge
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 1.0, end: 1.05, duration: 600.ms);
    }

    return badge;
  }
}
