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

  // ── KYC verification ──────────────────────────────────────────────────────
  /// not_submitted | pending | verified | rejected | expired
  final String kycStatus;

  /// none | basic | verified | premium
  final String verificationTier;
  final String kycSelfieUrl;
  final String kycCitizenshipUrl;
  final String kycPanCardUrl;
  final String kycLocationPhoto1Url;
  final String kycLocationPhoto2Url;
  final String kycLocationPhoto3Url;
  final double kycLocationLat;
  final double kycLocationLng;
  final String kycLocationDistrict;

  /// Masked in UI as XXXXX789 — never shown in full publicly.
  final String panNumber;
  final String panName;

  /// Never shown publicly.
  final String citizenshipNumber;
  final String gmailAccount;
  final String qrCodeUrl;

  /// SBV-2026-XXXXX unique verification card id.
  final String safebuyCardId;
  final DateTime? verificationDate;
  final DateTime? verificationExpiry;
  final DateTime? lastReverificationDate;
  final String kycRejectionReason;
  final bool isQrLocked;

  /// Public-facing district only (never the full address).
  final String verificationDistrict;

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
    this.kycStatus = 'not_submitted',
    this.verificationTier = 'none',
    this.kycSelfieUrl = '',
    this.kycCitizenshipUrl = '',
    this.kycPanCardUrl = '',
    this.kycLocationPhoto1Url = '',
    this.kycLocationPhoto2Url = '',
    this.kycLocationPhoto3Url = '',
    this.kycLocationLat = 0,
    this.kycLocationLng = 0,
    this.kycLocationDistrict = '',
    this.panNumber = '',
    this.panName = '',
    this.citizenshipNumber = '',
    this.gmailAccount = '',
    this.qrCodeUrl = '',
    this.safebuyCardId = '',
    this.verificationDate,
    this.verificationExpiry,
    this.lastReverificationDate,
    this.kycRejectionReason = '',
    this.isQrLocked = false,
    this.verificationDistrict = '',
  });

  // ── Getters ───────────────────────────────────────────────────────────────

  String get displayName => businessName ?? name;

  bool get isHighRisk => trustVerdict == 'high_risk';

  bool get isTrusted => trustVerdict == 'trusted';

  bool get isKycVerified => kycStatus == 'verified';

  bool get isKycPending => kycStatus == 'pending';

  bool get isReverificationOverdue =>
      verificationExpiry != null &&
      DateTime.now().isAfter(verificationExpiry!);

  /// Masked PAN for UI display: XXXXX789
  String get maskedPan {
    if (panNumber.length < 4) return panNumber.isEmpty ? '' : 'XXXXX';
    return 'XXXXX${panNumber.substring(panNumber.length - 3)}';
  }

  String get tierLabel {
    switch (verificationTier) {
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

  // ── Factory ───────────────────────────────────────────────────────────────

  factory SellerModel.fromMap(String id, Map<String, dynamic> data) {
    DateTime? ts(dynamic v) => v is Timestamp ? v.toDate() : null;
    return SellerModel(
      sellerId: id,
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? data['phoneNumber'] as String? ?? '',
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
      accountCreatedAt:
          ts(data['accountCreatedAt']) ?? ts(data['createdAt']) ?? DateTime(2024),
      lastActiveAt:
          ts(data['lastActiveAt']) ?? ts(data['updatedAt']) ?? DateTime.now(),
      disputeResponseRate:
          (data['disputeResponseRate'] as num?)?.toDouble() ?? 0.0,
      businessName: data['businessName'] as String?,
      businessCategory: data['businessCategory'] as String?,
      profileImageUrl:
          data['profileImageUrl'] as String? ?? data['photoUrl'] as String?,
      description: data['description'] as String?,
      trustScoreHistory:
          List<Map<String, dynamic>>.from(data['trustScoreHistory'] ?? []),
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      linkedUserId: data['linkedUserId'] as String?,
      kycStatus: data['kycStatus'] as String? ?? 'not_submitted',
      verificationTier: data['verificationTier'] as String? ?? 'none',
      kycSelfieUrl: data['kycSelfieUrl'] as String? ?? '',
      kycCitizenshipUrl: data['kycCitizenshipUrl'] as String? ?? '',
      kycPanCardUrl: data['kycPanCardUrl'] as String? ?? '',
      kycLocationPhoto1Url: data['kycLocationPhoto1Url'] as String? ?? '',
      kycLocationPhoto2Url: data['kycLocationPhoto2Url'] as String? ?? '',
      kycLocationPhoto3Url: data['kycLocationPhoto3Url'] as String? ?? '',
      kycLocationLat: (data['kycLocationLat'] as num?)?.toDouble() ?? 0,
      kycLocationLng: (data['kycLocationLng'] as num?)?.toDouble() ?? 0,
      kycLocationDistrict: data['kycLocationDistrict'] as String? ?? '',
      panNumber: data['panNumber'] as String? ?? '',
      panName: data['panName'] as String? ?? '',
      citizenshipNumber: data['citizenshipNumber'] as String? ?? '',
      gmailAccount: data['gmailAccount'] as String? ?? '',
      qrCodeUrl: data['qrCodeUrl'] as String? ?? '',
      safebuyCardId: data['safebuyCardId'] as String? ?? '',
      verificationDate: ts(data['verificationDate']),
      verificationExpiry: ts(data['verificationExpiry']),
      lastReverificationDate: ts(data['lastReverificationDate']),
      kycRejectionReason: data['kycRejectionReason'] as String? ?? '',
      isQrLocked: data['isQrLocked'] as bool? ?? false,
      verificationDistrict: data['verificationDistrict'] as String? ?? '',
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
        'kycStatus': kycStatus,
        'verificationTier': verificationTier,
        'kycSelfieUrl': kycSelfieUrl,
        'kycCitizenshipUrl': kycCitizenshipUrl,
        'kycPanCardUrl': kycPanCardUrl,
        'kycLocationPhoto1Url': kycLocationPhoto1Url,
        'kycLocationPhoto2Url': kycLocationPhoto2Url,
        'kycLocationPhoto3Url': kycLocationPhoto3Url,
        'kycLocationLat': kycLocationLat,
        'kycLocationLng': kycLocationLng,
        'kycLocationDistrict': kycLocationDistrict,
        'panNumber': panNumber,
        'panName': panName,
        'citizenshipNumber': citizenshipNumber,
        'gmailAccount': gmailAccount,
        'qrCodeUrl': qrCodeUrl,
        'safebuyCardId': safebuyCardId,
        'verificationDate': verificationDate != null
            ? Timestamp.fromDate(verificationDate!)
            : null,
        'verificationExpiry': verificationExpiry != null
            ? Timestamp.fromDate(verificationExpiry!)
            : null,
        'lastReverificationDate': lastReverificationDate != null
            ? Timestamp.fromDate(lastReverificationDate!)
            : null,
        'kycRejectionReason': kycRejectionReason,
        'isQrLocked': isQrLocked,
        'verificationDistrict': verificationDistrict,
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
    String? kycStatus,
    String? verificationTier,
    String? kycSelfieUrl,
    String? kycCitizenshipUrl,
    String? kycPanCardUrl,
    String? kycLocationPhoto1Url,
    String? kycLocationPhoto2Url,
    String? kycLocationPhoto3Url,
    double? kycLocationLat,
    double? kycLocationLng,
    String? kycLocationDistrict,
    String? panNumber,
    String? panName,
    String? citizenshipNumber,
    String? gmailAccount,
    String? qrCodeUrl,
    String? safebuyCardId,
    DateTime? verificationDate,
    DateTime? verificationExpiry,
    DateTime? lastReverificationDate,
    String? kycRejectionReason,
    bool? isQrLocked,
    String? verificationDistrict,
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
      kycStatus: kycStatus ?? this.kycStatus,
      verificationTier: verificationTier ?? this.verificationTier,
      kycSelfieUrl: kycSelfieUrl ?? this.kycSelfieUrl,
      kycCitizenshipUrl: kycCitizenshipUrl ?? this.kycCitizenshipUrl,
      kycPanCardUrl: kycPanCardUrl ?? this.kycPanCardUrl,
      kycLocationPhoto1Url: kycLocationPhoto1Url ?? this.kycLocationPhoto1Url,
      kycLocationPhoto2Url: kycLocationPhoto2Url ?? this.kycLocationPhoto2Url,
      kycLocationPhoto3Url: kycLocationPhoto3Url ?? this.kycLocationPhoto3Url,
      kycLocationLat: kycLocationLat ?? this.kycLocationLat,
      kycLocationLng: kycLocationLng ?? this.kycLocationLng,
      kycLocationDistrict: kycLocationDistrict ?? this.kycLocationDistrict,
      panNumber: panNumber ?? this.panNumber,
      panName: panName ?? this.panName,
      citizenshipNumber: citizenshipNumber ?? this.citizenshipNumber,
      gmailAccount: gmailAccount ?? this.gmailAccount,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      safebuyCardId: safebuyCardId ?? this.safebuyCardId,
      verificationDate: verificationDate ?? this.verificationDate,
      verificationExpiry: verificationExpiry ?? this.verificationExpiry,
      lastReverificationDate:
          lastReverificationDate ?? this.lastReverificationDate,
      kycRejectionReason: kycRejectionReason ?? this.kycRejectionReason,
      isQrLocked: isQrLocked ?? this.isQrLocked,
      verificationDistrict: verificationDistrict ?? this.verificationDistrict,
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
        kycStatus,
        verificationTier,
        kycSelfieUrl,
        kycCitizenshipUrl,
        kycPanCardUrl,
        kycLocationPhoto1Url,
        kycLocationPhoto2Url,
        kycLocationPhoto3Url,
        kycLocationLat,
        kycLocationLng,
        kycLocationDistrict,
        panNumber,
        panName,
        citizenshipNumber,
        gmailAccount,
        qrCodeUrl,
        safebuyCardId,
        verificationDate,
        verificationExpiry,
        lastReverificationDate,
        kycRejectionReason,
        isQrLocked,
        verificationDistrict,
      ];
}
