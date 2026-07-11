import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/leaderboard_model.dart';

/// Monthly seller leaderboard.
/// Reads the pre-computed /leaderboard/{month}/entries collection when
/// available; otherwise falls back to ranking the sellers collection live
/// (weighted: trust score 50%, avg rating 30%, review count 20%).
class LeaderboardService {
  LeaderboardService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static String monthKey([DateTime? date]) {
    final d = date ?? DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}';
  }

  Future<List<LeaderboardEntryModel>> getLeaderboard({
    String? month,
    int limit = 20,
  }) async {
    final key = month ?? monthKey();

    // 1) Pre-computed leaderboard written by admin / Cloud Functions.
    try {
      final snap = await _db
          .collection('leaderboard')
          .doc(key)
          .collection('entries')
          .orderBy('rank')
          .limit(limit)
          .get();
      if (snap.docs.isNotEmpty) {
        return snap.docs
            .map((d) => LeaderboardEntryModel.fromMap(d.data()))
            .toList();
      }
    } catch (_) {
      // fall through to live computation
    }

    // 2) Live fallback from sellers collection.
    final sellers = await _db
        .collection('sellers')
        .orderBy('trustScore', descending: true)
        .limit(60)
        .get();

    final entries = sellers.docs.map((d) {
      final data = d.data();
      final trust = (data['trustScore'] as num?)?.toDouble() ?? 0;
      final rating = (data['averageRating'] as num?)?.toDouble() ?? 0;
      final reviews = (data['reviewCount'] as num?)?.toInt() ?? 0;
      final score = trust * 0.5 + (rating / 5 * 100) * 0.3 +
          (reviews.clamp(0, 50) / 50 * 100) * 0.2;
      return (
        score,
        LeaderboardEntryModel(
          sellerId: d.id,
          sellerName: data['name'] as String? ?? '',
          businessName: data['businessName'] as String? ?? '',
          profileImageUrl: data['profileImageUrl'] as String? ?? '',
          averageRating: rating,
          reviewCount: reviews,
          totalOrders: (data['totalOrders'] as num?)?.toInt() ?? 0,
          trustScore: trust,
          verificationTier: data['verificationTier'] as String? ?? 'none',
          safebuyCardId: data['safebuyCardId'] as String? ?? '',
          month: key,
          calculatedAt: DateTime.now(),
        ),
      );
    }).toList()
      ..sort((a, b) => b.$1.compareTo(a.$1));

    return [
      for (var i = 0; i < entries.length && i < limit; i++)
        LeaderboardEntryModel(
          sellerId: entries[i].$2.sellerId,
          sellerName: entries[i].$2.sellerName,
          businessName: entries[i].$2.businessName,
          profileImageUrl: entries[i].$2.profileImageUrl,
          averageRating: entries[i].$2.averageRating,
          reviewCount: entries[i].$2.reviewCount,
          totalOrders: entries[i].$2.totalOrders,
          trustScore: entries[i].$2.trustScore,
          verificationTier: entries[i].$2.verificationTier,
          safebuyCardId: entries[i].$2.safebuyCardId,
          rank: i + 1,
          month: key,
          calculatedAt: DateTime.now(),
        ),
    ];
  }
}
