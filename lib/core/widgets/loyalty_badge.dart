import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/seller_model.dart';

/// Clean-record loyalty medal: earned by account age with ZERO fraud
/// reports. Bronze at 6 months, silver at 1 year, gold at 2 years.
class LoyaltyBadge extends StatelessWidget {
  const LoyaltyBadge({super.key, required this.seller, this.compact = false});

  final SellerModel seller;

  /// Compact pills fit inside search result cards.
  final bool compact;

  /// (label, medal color, text color) of the highest earned tier,
  /// or null when nothing is earned yet.
  static (String, Color, Color)? tierFor(SellerModel seller) {
    if (seller.scamReportCount > 0) return null;
    final days =
        DateTime.now().difference(seller.accountCreatedAt).inDays;
    if (days >= 730) {
      return ('2 Year Elite Seller', Color(0xFFD4AF37), Color(0xFF6B5310));
    }
    if (days >= 365) {
      return ('1 Year Trusted', Color(0xFF97A3B4), Color(0xFF414B59));
    }
    if (days >= 182) {
      return ('6 Month Clean Record', Color(0xFFCD7F32), Color(0xFF6E4218));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final tier = tierFor(seller);
    if (tier == null) return const SizedBox.shrink();
    final (label, medal, text) = tier;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            medal.withValues(alpha: 0.28),
            medal.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: medal.withValues(alpha: 0.65)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.military_tech_rounded,
              size: compact ? 13 : 16, color: medal),
          SizedBox(width: compact ? 4 : 6),
          Text(label,
              style: GoogleFonts.inter(
                fontSize: compact ? 10 : 11.5,
                fontWeight: FontWeight.w700,
                color: text,
              )),
        ],
      ),
    );
  }
}
