import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/app_constants.dart';
import '../models/report_model.dart';
import '../models/review_model.dart';
import '../models/seller_model.dart';

/// SafeBuy Nepal — Seed Data Service
///
/// Creates 5 realistic seller profiles with associated reports and reviews
/// for thesis demonstration. Only run in debug mode from the Dashboard.
class SeedDataService {
  SeedDataService._();

  static final _db = FirebaseFirestore.instance;
  static const _uuid = Uuid();

  /// Wipes existing demo data and reseeds.
  /// Returns a status string for UI feedback.
  static Future<String> seedDatabase() async {
    try {
      await _seedTrustedSellers();
      await _seedUnverifiedSeller();
      await _seedHighRiskSellers();
      return 'Seeded 5 sellers, 12 reports, 50+ reviews';
    } catch (e) {
      return 'Seed failed: $e';
    }
  }

  /// Auto-seed on first launch if database is empty.
  /// Solves the cold-start problem — new users see real-looking data.
  static Future<void> ensureSeedOnFirstLaunch() async {
    try {
      // Check if sellers collection already has data
      final existing = await _db
          .collection(AppConstants.colSellers)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) return; // Already has data

      await seedDatabase();
    } catch (_) {
      // Silently fail — seed data is nice-to-have, not critical
    }
  }

  // ── Seller 1 & 2 — Trusted ────────────────────────────────────────────────────
  static Future<void> _seedTrustedSellers() async {
    final now = DateTime.now();

    final priya = SellerModel(
      sellerId: 'seed_priya_fashions',
      name: 'Priya Sharma',
      phone: '9841234567',
      esewaId: '9841234567',
      tiktokHandle: 'priyafashionsktm',
      instagramHandle: 'priyafashions.np',
      trustScore: 87.0,
      trustVerdict: 'trusted',
      isVerified: true,
      verifiedBadge: true,
      totalOrders: 234,
      reviewCount: 23,
      scamReportCount: 0,
      accountCreatedAt: now.subtract(const Duration(days: 400)),
      lastActiveAt: now.subtract(const Duration(hours: 2)),
      disputeResponseRate: 0.95,
      businessName: 'Priya Fashions',
      businessCategory: 'Clothing & Fashion',
      description:
          'Authentic Nepali kurthas and modern fashion delivered across Kathmandu Valley. 5+ years serving 1000+ happy customers.',
      averageRating: 4.7,
      trustScoreHistory: _scoreHistory(85, 87, 30),
    );

    final tech = SellerModel(
      sellerId: 'seed_technepal_store',
      name: 'Bibek Karki',
      phone: '9851234568',
      esewaId: '9851234568',
      instagramHandle: 'technepaltm',
      trustScore: 82.0,
      trustVerdict: 'trusted',
      isVerified: true,
      verifiedBadge: true,
      totalOrders: 89,
      reviewCount: 15,
      scamReportCount: 0,
      accountCreatedAt: now.subtract(const Duration(days: 280)),
      lastActiveAt: now.subtract(const Duration(hours: 5)),
      disputeResponseRate: 0.88,
      businessName: 'TechNepal Store',
      businessCategory: 'Electronics',
      description:
          'Genuine electronics, mobile accessories, and gadgets with 7-day return policy.',
      averageRating: 4.5,
      trustScoreHistory: _scoreHistory(80, 82, 30),
    );

    await _writeSeller(priya);
    await _writeSeller(tech);
    await _writeReviews(priya.sellerId, _genReviews(priya.sellerId, 23, 4.7));
    await _writeReviews(tech.sellerId, _genReviews(tech.sellerId, 15, 4.5));
  }

  // ── Seller 3 — Unverified ────────────────────────────────────────────────────
  static Future<void> _seedUnverifiedSeller() async {
    final now = DateTime.now();

    final sunset = SellerModel(
      sellerId: 'seed_sunset_cosmetics',
      name: 'Sunita Khadka',
      phone: '9861234569',
      tiktokHandle: 'sunsetcosmetics.np',
      trustScore: 64.0,
      trustVerdict: 'unverified',
      isVerified: true,
      verifiedBadge: false,
      totalOrders: 23,
      reviewCount: 8,
      scamReportCount: 1,
      accountCreatedAt: now.subtract(const Duration(days: 95)),
      lastActiveAt: now.subtract(const Duration(days: 1)),
      disputeResponseRate: 0.75,
      businessName: 'Sunset Cosmetics',
      businessCategory: 'Cosmetics & Beauty',
      description: 'Imported Korean skincare and makeup products.',
      averageRating: 3.9,
      trustScoreHistory: _scoreHistory(70, 64, 30),
    );

    await _writeSeller(sunset);
    await _writeReviews(
        sunset.sellerId, _genReviews(sunset.sellerId, 8, 3.9, withMixed: true));

    // 1 old resolved report
    await _writeReport(ReportModel(
      reportId: 'seed_rpt_sunset_1',
      reporterId: 'seed_buyer_1',
      sellerId: sunset.sellerId,
      sellerPhone: sunset.phone,
      sellerSocialHandle: sunset.tiktokHandle,
      platform: 'TikTok',
      incidentType: 'wrong_item',
      amountLost: 2500.0,
      description:
          'Ordered Innisfree Green Tea Foam Cleanser but received a different brand. Seller refunded after dispute.',
      incidentDate: now.subtract(const Duration(days: 60)),
      paymentScreenshotUrl: null,
      chatScreenshotUrl: null,
      submittedAt: now.subtract(const Duration(days: 58)),
      status: 'resolved',
      reporterDeclaration: true,
      sellerResponse:
          'Apologised for the mix-up. Refunded full amount via eSewa within 24 hours.',
      adminNotes: 'Verified refund. Marked resolved.',
      isAnonymizedForDeletion: false,
    ));
  }

  // ── Sellers 4 & 5 — High Risk ────────────────────────────────────────────────
  static Future<void> _seedHighRiskSellers() async {
    final now = DateTime.now();

    final quickbuy = SellerModel(
      sellerId: 'seed_quickbuy_electronics',
      name: 'Ram Bahadur',
      phone: '9871234570',
      facebookHandle: 'quickbuynepal',
      trustScore: 31.0,
      trustVerdict: 'high_risk',
      isVerified: false,
      verifiedBadge: false,
      totalOrders: 12,
      reviewCount: 2,
      scamReportCount: 4,
      accountCreatedAt: now.subtract(const Duration(days: 60)),
      lastActiveAt: now.subtract(const Duration(days: 3)),
      disputeResponseRate: 0.2,
      businessName: 'QuickBuy Electronics',
      businessCategory: 'Electronics',
      description: 'Mobile and gadgets at lowest prices.',
      averageRating: 2.1,
      trustScoreHistory: _scoreHistory(55, 31, 60),
    );

    final fastdeal = SellerModel(
      sellerId: 'seed_fastdeal_nepal',
      name: 'Unknown Seller',
      phone: '9881234571',
      tiktokHandle: 'fastdeal.nepal',
      trustScore: 18.0,
      trustVerdict: 'high_risk',
      isVerified: false,
      verifiedBadge: false,
      totalOrders: 0,
      reviewCount: 0,
      scamReportCount: 7,
      accountCreatedAt: now.subtract(const Duration(days: 15)),
      lastActiveAt: now.subtract(const Duration(days: 5)),
      disputeResponseRate: 0.0,
      businessName: 'FastDeal Nepal',
      businessCategory: 'Other',
      description: 'Cheapest deals online.',
      averageRating: 0.0,
      trustScoreHistory: _scoreHistory(80, 18, 15),
    );

    await _writeSeller(quickbuy);
    await _writeSeller(fastdeal);

    // QuickBuy: suspicious reviews (low authenticity)
    await _writeReview(ReviewModel(
      reviewId: _uuid.v4(),
      sellerId: quickbuy.sellerId,
      reviewerId: 'seed_suspicious_1',
      reviewerDisplayName: 'Anonymous Buyer',
      rating: 5,
      comment: 'good',
      createdAt: now.subtract(const Duration(days: 7, hours: 2)),
      isVerifiedPurchase: false,
      authenticityWeight: 0.2,
      helpfulCount: 0,
    ));
    await _writeReview(ReviewModel(
      reviewId: _uuid.v4(),
      sellerId: quickbuy.sellerId,
      reviewerId: 'seed_suspicious_2',
      reviewerDisplayName: 'Anonymous Buyer',
      rating: 5,
      comment: 'nice',
      createdAt: now.subtract(const Duration(days: 7, hours: 3)),
      isVerifiedPurchase: false,
      authenticityWeight: 0.2,
      helpfulCount: 0,
    ));

    // QuickBuy: 4 reports
    final qbReports = [
      _genReport(quickbuy, 'no_delivery', 15000, 25, 'pending',
          response:
              'These reports are fake. We have shipped all orders. Buyers should check delivery status.'),
      _genReport(quickbuy, 'no_delivery', 12000, 18, 'pending'),
      _genReport(quickbuy, 'no_delivery', 8000, 10, 'pending'),
      _genReport(quickbuy, 'fake_product', 10000, 35, 'verified'),
    ];
    for (final r in qbReports) {
      await _writeReport(r);
    }

    // FastDeal: 7 reports, all unresolved, varied amounts
    const fdAmounts = [8000.0, 12000.0, 15000.0, 9500.0, 7000.0, 18000.0, 14000.0];
    final types = ['no_delivery', 'no_delivery', 'no_delivery', 'no_delivery', 'no_delivery', 'payment_issue', 'payment_issue'];
    for (var i = 0; i < 7; i++) {
      await _writeReport(_genReport(
        fastdeal,
        types[i],
        fdAmounts[i],
        i + 2,
        'pending',
        response: i == 3
            ? 'I never received the order from supplier. Will refund soon.'
            : null,
      ));
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  static Future<void> _writeSeller(SellerModel seller) async {
    await _db
        .collection(AppConstants.colSellers)
        .doc(seller.sellerId)
        .set(seller.toMap());
  }

  static Future<void> _writeReport(ReportModel report) async {
    await _db
        .collection(AppConstants.colReports)
        .doc(report.reportId)
        .set(report.toMap());
  }

  static Future<void> _writeReview(ReviewModel review) async {
    await _db
        .collection(AppConstants.colReviews)
        .doc(review.reviewId)
        .set(review.toMap());
  }

  static Future<void> _writeReviews(String sellerId, List<ReviewModel> reviews) async {
    for (final r in reviews) {
      await _writeReview(r);
    }
  }

  static List<Map<String, dynamic>> _scoreHistory(
      double startScore, double endScore, int days) {
    final history = <Map<String, dynamic>>[];
    final step = (endScore - startScore) / days;
    final now = DateTime.now();
    for (var i = 0; i <= days; i += 2) {
      history.add({
        'score': (startScore + step * i).clamp(0.0, 100.0),
        'timestamp': Timestamp.fromDate(now.subtract(Duration(days: days - i))),
      });
    }
    return history;
  }

  static List<ReviewModel> _genReviews(
    String sellerId,
    int count,
    double avgRating, {
    bool withMixed = false,
  }) {
    final comments = [
      'Excellent service, fast delivery!',
      'Product matched the description. Highly recommended.',
      'Genuine seller, will buy again.',
      'Smooth transaction and good communication.',
      'Best price in Kathmandu, satisfied.',
      'Quality is great, packaging was nice.',
      'On-time delivery, no issues.',
      'Friendly seller, answered all my questions.',
    ];
    final mixedComments = [
      'Took longer than expected but product was okay.',
      'Product was slightly different from photo.',
      'Average service.',
    ];

    final reviews = <ReviewModel>[];
    final now = DateTime.now();
    for (var i = 0; i < count; i++) {
      final useMixed = withMixed && i % 3 == 0;
      final rating = useMixed ? 3 : (avgRating.round() + (i % 2 == 0 ? 0 : -1)).clamp(1, 5);
      reviews.add(ReviewModel(
        reviewId: _uuid.v4(),
        sellerId: sellerId,
        reviewerId: 'seed_buyer_${sellerId}_$i',
        reviewerDisplayName: _displayName(i),
        rating: rating,
        comment: useMixed
            ? mixedComments[i % mixedComments.length]
            : comments[i % comments.length],
        createdAt: now.subtract(Duration(days: i * 4 + 2)),
        isVerifiedPurchase: !useMixed,
        authenticityWeight: useMixed ? 0.7 : 0.95,
        helpfulCount: (count - i) ~/ 2,
      ));
    }
    return reviews;
  }

  static String _displayName(int idx) {
    const places = ['Kathmandu', 'Lalitpur', 'Bhaktapur', 'Pokhara', 'Biratnagar'];
    return 'Buyer from ${places[idx % places.length]}';
  }

  static ReportModel _genReport(
    SellerModel seller,
    String type,
    double amount,
    int daysAgo,
    String status, {
    String? response,
  }) {
    final now = DateTime.now();
    return ReportModel(
      reportId: _uuid.v4(),
      reporterId: 'seed_buyer_${_uuid.v4().substring(0, 8)}',
      sellerId: seller.sellerId,
      sellerPhone: seller.phone,
      sellerEsewaId: seller.esewaId,
      sellerSocialHandle: seller.tiktokHandle ??
          seller.instagramHandle ??
          seller.facebookHandle,
      platform: seller.tiktokHandle != null
          ? 'TikTok'
          : seller.instagramHandle != null
              ? 'Instagram'
              : 'Facebook',
      incidentType: type,
      amountLost: amount,
      description: _reportDescription(type, amount),
      incidentDate: now.subtract(Duration(days: daysAgo + 2)),
      paymentScreenshotUrl: null,
      chatScreenshotUrl: null,
      submittedAt: now.subtract(Duration(days: daysAgo)),
      status: status,
      reporterDeclaration: true,
      sellerResponse: response,
      adminNotes: null,
      isAnonymizedForDeletion: false,
    );
  }

  static String _reportDescription(String type, double amount) {
    switch (type) {
      case 'no_delivery':
        return 'Paid NPR ${amount.toStringAsFixed(0)} via eSewa for an order. Seller stopped responding after payment. No delivery received after 2 weeks of waiting.';
      case 'wrong_item':
        return 'Received a completely different item than what was advertised. Seller refused to refund or exchange.';
      case 'fake_product':
        return 'Product appears to be a counterfeit. Quality is far below the advertised brand-name item. Seller denies and refuses refund.';
      case 'payment_issue':
        return 'Made advance payment of NPR ${amount.toStringAsFixed(0)} as requested. Seller has been unresponsive since. Cannot reach them on any platform.';
      default:
        return 'Issue with order worth NPR ${amount.toStringAsFixed(0)}.';
    }
  }
}
