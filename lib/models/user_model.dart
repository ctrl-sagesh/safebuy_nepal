import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String userId;
  final String phone;
  final String fullName;
  final String role; // buyer / seller / admin
  final DateTime createdAt;
  final String? linkedSellerId;
  final bool isAccountActive;
  final int totalReportsSubmitted;
  final DateTime lastLoginAt;
  final String preferredLanguage;
  final String? fcmToken;
  // ── Identity & verification ──────────────────────────────────────────────
  final String? email;
  final String? nationalIdUrl;
  /// none | pending | approved | rejected
  final String verificationStatus;

  const UserModel({
    required this.userId,
    required this.phone,
    required this.fullName,
    required this.role,
    required this.createdAt,
    this.linkedSellerId,
    required this.isAccountActive,
    required this.totalReportsSubmitted,
    required this.lastLoginAt,
    required this.preferredLanguage,
    this.fcmToken,
    this.email,
    this.nationalIdUrl,
    this.verificationStatus = 'none',
  });

  bool get isVerifiedReporter => verificationStatus == 'approved';

  factory UserModel.fromMap(String id, Map<String, dynamic> data) {
    return UserModel(
      userId: id,
      phone: data['phone'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      role: data['role'] as String? ?? 'buyer',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      linkedSellerId: data['linkedSellerId'] as String?,
      isAccountActive: data['isAccountActive'] as bool? ?? true,
      totalReportsSubmitted:
          (data['totalReportsSubmitted'] as num?)?.toInt() ?? 0,
      lastLoginAt: data['lastLoginAt'] != null
          ? (data['lastLoginAt'] as Timestamp).toDate()
          : DateTime.now(),
      preferredLanguage: data['preferredLanguage'] as String? ?? 'en',
      fcmToken: data['fcmToken'] as String?,
      email: data['email'] as String?,
      nationalIdUrl: data['nationalIdUrl'] as String?,
      verificationStatus: data['verificationStatus'] as String? ?? 'none',
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    return UserModel.fromMap(
        doc.id, doc.data() as Map<String, dynamic>? ?? {});
  }

  Map<String, dynamic> toMap() => {
        'phone': phone,
        'fullName': fullName,
        'role': role,
        'createdAt': Timestamp.fromDate(createdAt),
        'linkedSellerId': linkedSellerId,
        'isAccountActive': isAccountActive,
        'totalReportsSubmitted': totalReportsSubmitted,
        'lastLoginAt': Timestamp.fromDate(lastLoginAt),
        'preferredLanguage': preferredLanguage,
        'fcmToken': fcmToken,
        'email': email,
        'nationalIdUrl': nationalIdUrl,
        'verificationStatus': verificationStatus,
      };

  UserModel copyWith({
    String? userId,
    String? phone,
    String? fullName,
    String? role,
    DateTime? createdAt,
    String? linkedSellerId,
    bool? isAccountActive,
    int? totalReportsSubmitted,
    DateTime? lastLoginAt,
    String? preferredLanguage,
    String? fcmToken,
    String? email,
    String? nationalIdUrl,
    String? verificationStatus,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      linkedSellerId: linkedSellerId ?? this.linkedSellerId,
      isAccountActive: isAccountActive ?? this.isAccountActive,
      totalReportsSubmitted:
          totalReportsSubmitted ?? this.totalReportsSubmitted,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      fcmToken: fcmToken ?? this.fcmToken,
      email: email ?? this.email,
      nationalIdUrl: nationalIdUrl ?? this.nationalIdUrl,
      verificationStatus: verificationStatus ?? this.verificationStatus,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        phone,
        fullName,
        role,
        createdAt,
        linkedSellerId,
        isAccountActive,
        totalReportsSubmitted,
        lastLoginAt,
        preferredLanguage,
        fcmToken,
        email,
        nationalIdUrl,
        verificationStatus,
      ];
}
