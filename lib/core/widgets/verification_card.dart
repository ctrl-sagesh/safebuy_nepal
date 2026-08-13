import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/seller_model.dart';
import '../theme/app_colors.dart';

/// Tier visual helpers shared across the app.
abstract final class TierStyle {
  static Color color(String tier) {
    switch (tier) {
      case 'premium':
        return const Color(0xFFD4AF37); // gold
      case 'verified':
        return AppColors.trusted;
      case 'basic':
        return AppColors.primary;
      default:
        return AppColors.grey400;
    }
  }

  static IconData icon(String tier) {
    switch (tier) {
      case 'premium':
        return Icons.emoji_events_rounded;
      case 'verified':
        return Icons.verified_user_rounded;
      case 'basic':
        return Icons.how_to_reg_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  static String label(String tier) {
    switch (tier) {
      case 'premium':
        return 'PREMIUM';
      case 'verified':
        return 'VERIFIED';
      case 'basic':
        return 'BASIC';
      default:
        return 'UNVERIFIED';
    }
  }

  static LinearGradient cardGradient(String tier) {
    switch (tier) {
      case 'premium':
        return const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF8B6914)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'verified':
        return const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF00695C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  static Color borderColor(String tier) {
    switch (tier) {
      case 'premium':
        return const Color(0xFFD4AF37);
      case 'verified':
        return const Color(0xFFB0BEC5); // silver
      default:
        return AppColors.primaryLight;
    }
  }
}

/// The physical-looking SafeBuy Verification Card (340x200 aspect).
/// Used on the card screen, seller profile preview, and onboarding.
/// A white shine sweeps across the face every 5 seconds.
class SafebuyVerificationCard extends StatefulWidget {
  const SafebuyVerificationCard({
    super.key,
    required this.seller,
    this.width = 340,
  });

  final SellerModel seller;
  final double width;

  @override
  State<SafebuyVerificationCard> createState() =>
      _SafebuyVerificationCardState();
}

class _SafebuyVerificationCardState extends State<SafebuyVerificationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shine = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..repeat();

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seller = widget.seller;
    final width = widget.width;
    final tier = seller.verificationTier;
    final height = width * 200 / 340;
    final scale = width / 340;
    final expiry = seller.verificationExpiry;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: TierStyle.cardGradient(tier),
        borderRadius: BorderRadius.circular(18 * scale),
        border: Border.all(color: TierStyle.borderColor(tier), width: 2),
        boxShadow: [
          BoxShadow(
            color: TierStyle.borderColor(tier).withValues(alpha: 0.35),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16 * scale),
        child: Stack(
          children: [
            // Shine: sweeps within the first fifth of each 5s cycle.
            // RepaintBoundary isolates the per-frame sweep from the rest
            // of the (static) card face.
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                animation: _shine,
                builder: (context, _) {
                  final t = (_shine.value / 0.2).clamp(0.0, 1.0);
                  return IgnorePointer(
                    child: Transform.translate(
                      offset: Offset((t * 2 - 1) * width * 1.4, 0),
                      child: Transform.rotate(
                        angle: 0.35,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0),
                                Colors.white.withValues(alpha: 0.18),
                                Colors.white.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(14 * scale),
              child: _cardBody(seller, tier, scale, expiry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardBody(
      SellerModel seller, String tier, double scale, DateTime? expiry) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar
          Row(
            children: [
              Icon(Icons.shield_rounded,
                  color: Colors.white, size: 18 * scale),
              SizedBox(width: 6 * scale),
              Text('SafeBuy Nepal',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 11 * scale,
                    fontWeight: FontWeight.w700,
                  )),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 8 * scale, vertical: 3 * scale),
                decoration: BoxDecoration(
                  color: TierStyle.color(tier),
                  borderRadius: BorderRadius.circular(8 * scale),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(TierStyle.icon(tier),
                        color: Colors.white, size: 10 * scale),
                    SizedBox(width: 3 * scale),
                    Text(TierStyle.label(tier),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 8 * scale,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        )),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),

          // Middle: photo + info
          Row(
            children: [
              Container(
                width: 52 * scale,
                height: 52 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: TierStyle.color(tier), width: 2.5),
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                child: seller.profileImageUrl != null &&
                        seller.profileImageUrl!.isNotEmpty
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: seller.profileImageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => Icon(Icons.person,
                              color: Colors.white, size: 28 * scale),
                        ),
                      )
                    : Icon(Icons.person,
                        color: Colors.white, size: 28 * scale),
              ),
              SizedBox(width: 10 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(seller.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 13 * scale,
                          fontWeight: FontWeight.w600,
                        )),
                    Text(
                      [
                        if (seller.businessCategory != null)
                          seller.businessCategory!,
                        if (seller.verificationDistrict.isNotEmpty)
                          seller.verificationDistrict,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 9 * scale,
                      ),
                    ),
                    Text(
                      'Member since ${DateFormat('MMM yyyy').format(seller.accountCreatedAt)}',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 9 * scale,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),

          // Bottom bar: card id + QR
          Row(
            children: [
              Container(
                width: 34 * scale,
                height: 34 * scale,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5 * scale),
                ),
                child: seller.qrCodeUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(5 * scale),
                        child: CachedNetworkImage(
                          imageUrl: seller.qrCodeUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => Icon(
                              Icons.qr_code_2_rounded,
                              size: 28 * scale,
                              color: AppColors.bgDark),
                        ),
                      )
                    : Icon(Icons.qr_code_2_rounded,
                        size: 28 * scale, color: AppColors.bgDark),
              ),
              SizedBox(width: 8 * scale),
              Text(
                seller.safebuyCardId.isNotEmpty
                    ? seller.safebuyCardId
                    : 'SBV-PENDING',
                style: GoogleFonts.robotoMono(
                  color: Colors.white,
                  fontSize: 10.5 * scale,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Verified by SafeBuy Nepal',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 7.5 * scale,
                      )),
                  if (expiry != null)
                    Text(
                      'Valid until ${DateFormat('dd MMM yyyy').format(expiry)}',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 8 * scale,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ),
      ],
    );
  }
}
