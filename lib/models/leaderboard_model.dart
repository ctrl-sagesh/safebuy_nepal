import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// A single seller entry on the monthly trust leaderboard.
class LeaderboardEntryModel extends Equatable {
  final String sellerId;
  final String sellerName;
  final String businessName;
  final String profileImageUrl;
  final double averageRating;
  final int reviewCount;
  final int totalOrders;
  final double trustScore;
  final String verificationTier;
  final String safebuyCardId;
  final int rank;

  /// '2026-07' format.
  final String month;
  final DateTime calculatedAt;

  const LeaderboardEntryModel({
    required this.sellerId,
    required this.sellerName,
    this.businessName = '',
    this.profileImageUrl = '',
    this.averageRating = 0,
    this.reviewCount = 0,
    this.totalOrders = 0,
    this.trustScore = 0,
    this.verificationTier = 'none',
    this.safebuyCardId = '',
    this.rank = 0,
    this.month = '',
    required this.calculatedAt,
  });

  String get displayName =>
      businessName.isNotEmpty ? businessName : sellerName;

  factory LeaderboardEntryModel.fromMap(Map<String, dynamic> data) {
    return LeaderboardEntryModel(
      sellerId: data['sellerId'] as String? ?? '',
      sellerName: data['sellerName'] as String? ?? '',
      businessName: data['businessName'] as String? ?? '',
      profileImageUrl: data['profileImageUrl'] as String? ?? '',
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0,
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
      totalOrders: (data['totalOrders'] as num?)?.toInt() ?? 0,
      trustScore: (data['trustScore'] as num?)?.toDouble() ?? 0,
      verificationTier: data['verificationTier'] as String? ?? 'none',
      safebuyCardId: data['safebuyCardId'] as String? ?? '',
      rank: (data['rank'] as num?)?.toInt() ?? 0,
      month: data['month'] as String? ?? '',
      calculatedAt: data['calculatedAt'] is Timestamp
          ? (data['calculatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'sellerId': sellerId,
        'sellerName': sellerName,
        'businessName': businessName,
        'profileImageUrl': profileImageUrl,
        'averageRating': averageRating,
        'reviewCount': reviewCount,
        'totalOrders': totalOrders,
        'trustScore': trustScore,
        'verificationTier': verificationTier,
        'safebuyCardId': safebuyCardId,
        'rank': rank,
        'month': month,
        'calculatedAt': Timestamp.fromDate(calculatedAt),
      };

  @override
  List<Object?> get props => [
        sellerId,
        sellerName,
        businessName,
        profileImageUrl,
        averageRating,
        reviewCount,
        totalOrders,
        trustScore,
        verificationTier,
        safebuyCardId,
        rank,
        month,
        calculatedAt,
      ];
}
