import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class SellerModel extends Equatable {
  final String sellerId;
  final String name;
  final String phone;
  final String? esewaId;
  final String? tiktokHandle;
  final String? instagramHandle;
  final String? facebookHandle;
  final double trustScore;
  final String trustVerdict; // trusted / unverified / high_risk
  final bool isVerified;
  final bool verifiedBadge;
  final int totalOrders;
  final int reviewCount;
  final int scamReportCount;
  final DateTime accountCreatedAt;
  final DateTime lastActiveAt;
  final double disputeResponseRate;
  final String? businessName;
  final String? businessCategory;
  final String? profileImageUrl;
  final String? description;
  final List<Map<String, dynamic>> trustScoreHistory;
  final double averageRating;
  final String? linkedUserId;

  const SellerModel({
    required this.sellerId,
    required this.name,
    required this.phone,
    this.esewaId,
    this.tiktokHandle,
    this.instagramHandle,
    this.facebookHandle,
    required this.trustScore,
    required this.trustVerdict,
    required this.isVerified,
    required this.verifiedBadge,
    required this.totalOrders,
    required this.reviewCount,
    required this.scamReportCount,
    required this.accountCreatedAt,
    required this.lastActiveAt,
    required this.disputeResponseRate,
    this.businessName,
    this.businessCategory,
    this.profileImageUrl,
    this.description,
    required this.trustScoreHistory,
    required this.averageRating,
    this.linkedUserId,
  });

  // ── Getters ───────────────────────────────────────────────────────────────────

  String get displayName => businessName ?? name;

  bool get isHighRisk => trustVerdict == 'high_risk';

  bool get isTrusted => trustVerdict == 'trusted';

  // Legacy enum-style getter for widgets that use TrustVerdict enum
  String get verdictLabel {
    switch (trustVerdict) {
      case 'trusted':
        return 'trusted';
      case 'high_risk':
        return 'high_risk';
      default:
        return 'unverified';
    }
  }

  // ── Factory ───────────────────────────────────────────────────────────────────

  factory SellerModel.fromMap(String id, Map<String, dynamic> data) {
    return SellerModel(
      sellerId: id,
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ??
          data['phoneNumber'] as String? ??
          '',
      esewaId: data['esewaId'] as String?,
      tiktokHandle: data['tiktokHandle'] as String?,
      instagramHandle: data['instagramHandle'] as String?,
      facebookHandle: data['facebookHandle'] as String?,
      trustScore: (data['trustScore'] as num?)?.toDouble() ?? 50.0,
      trustVerdict: data['trustVerdict'] as String? ?? 'unverified',
      isVerified: data['isVerified'] as bool? ?? false,
      verifiedBadge: data['verifiedBadge'] as bool? ?? false,
      totalOrders: (data['totalOrders'] as num?)?.toInt() ?? 0,
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
      scamReportCount: (data['scamReportCount'] as num?)?.toInt() ??
          (data['reportCount'] as num?)?.toInt() ??
          0,
      accountCreatedAt: data['accountCreatedAt'] != null
          ? (data['accountCreatedAt'] as Timestamp).toDate()
          : data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime(2024),
      lastActiveAt: data['lastActiveAt'] != null
          ? (data['lastActiveAt'] as Timestamp).toDate()
          : data['updatedAt'] != null
              ? (data['updatedAt'] as Timestamp).toDate()
              : DateTime.now(),
      disputeResponseRate:
          (data['disputeResponseRate'] as num?)?.toDouble() ?? 0.0,
      businessName: data['businessName'] as String?,
      businessCategory: data['businessCategory'] as String?,
      profileImageUrl: data['profileImageUrl'] as String? ??
          data['photoUrl'] as String?,
      description: data['description'] as String?,
      trustScoreHistory:
          List<Map<String, dynamic>>.from(data['trustScoreHistory'] ?? []),
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      linkedUserId: data['linkedUserId'] as String?,
    );
  }

  factory SellerModel.fromFirestore(DocumentSnapshot doc) {
    return SellerModel.fromMap(
        doc.id, doc.data() as Map<String, dynamic>? ?? {});
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'phoneNumber': phone, // backward compat
        'esewaId': esewaId,
        'tiktokHandle': tiktokHandle,
        'instagramHandle': instagramHandle,
        'facebookHandle': facebookHandle,
        'trustScore': trustScore,
        'trustVerdict': trustVerdict,
        'isVerified': isVerified,
        'verifiedBadge': verifiedBadge,
        'totalOrders': totalOrders,
        'reviewCount': reviewCount,
        'scamReportCount': scamReportCount,
        'reportCount': scamReportCount, // backward compat
        'accountCreatedAt': Timestamp.fromDate(accountCreatedAt),
        'createdAt': Timestamp.fromDate(accountCreatedAt),
        'lastActiveAt': Timestamp.fromDate(lastActiveAt),
        'updatedAt': Timestamp.fromDate(lastActiveAt),
        'disputeResponseRate': disputeResponseRate,
        'businessName': businessName,
        'businessCategory': businessCategory,
        'profileImageUrl': profileImageUrl,
        'description': description,
        'trustScoreHistory': trustScoreHistory,
        'averageRating': averageRating,
        'linkedUserId': linkedUserId,
      };

  SellerModel copyWith({
    String? sellerId,
    String? name,
    String? phone,
    String? esewaId,
    String? tiktokHandle,
    String? instagramHandle,
    String? facebookHandle,
    double? trustScore,
    String? trustVerdict,
    bool? isVerified,
    bool? verifiedBadge,
    int? totalOrders,
    int? reviewCount,
    int? scamReportCount,
    DateTime? accountCreatedAt,
    DateTime? lastActiveAt,
    double? disputeResponseRate,
    String? businessName,
    String? businessCategory,
    String? profileImageUrl,
    String? description,
    List<Map<String, dynamic>>? trustScoreHistory,
    double? averageRating,
    String? linkedUserId,
  }) {
    return SellerModel(
      sellerId: sellerId ?? this.sellerId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      esewaId: esewaId ?? this.esewaId,
      tiktokHandle: tiktokHandle ?? this.tiktokHandle,
      instagramHandle: instagramHandle ?? this.instagramHandle,
      facebookHandle: facebookHandle ?? this.facebookHandle,
      trustScore: trustScore ?? this.trustScore,
      trustVerdict: trustVerdict ?? this.trustVerdict,
      isVerified: isVerified ?? this.isVerified,
      verifiedBadge: verifiedBadge ?? this.verifiedBadge,
      totalOrders: totalOrders ?? this.totalOrders,
      reviewCount: reviewCount ?? this.reviewCount,
      scamReportCount: scamReportCount ?? this.scamReportCount,
      accountCreatedAt: accountCreatedAt ?? this.accountCreatedAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      disputeResponseRate: disputeResponseRate ?? this.disputeResponseRate,
      businessName: businessName ?? this.businessName,
      businessCategory: businessCategory ?? this.businessCategory,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      description: description ?? this.description,
      trustScoreHistory: trustScoreHistory ?? this.trustScoreHistory,
      averageRating: averageRating ?? this.averageRating,
      linkedUserId: linkedUserId ?? this.linkedUserId,
    );
  }

  @override
  List<Object?> get props => [
        sellerId,
        name,
        phone,
        esewaId,
        tiktokHandle,
        instagramHandle,
        facebookHandle,
        trustScore,
        trustVerdict,
        isVerified,
        verifiedBadge,
        totalOrders,
        reviewCount,
        scamReportCount,
        accountCreatedAt,
        lastActiveAt,
        disputeResponseRate,
        businessName,
        businessCategory,
        profileImageUrl,
        description,
        trustScoreHistory,
        averageRating,
        linkedUserId,
      ];
}
