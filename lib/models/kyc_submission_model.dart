import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// A seller's KYC document submission awaiting admin review.
class KycSubmissionModel extends Equatable {
  final String submissionId;
  final String sellerId;
  final String submittedBy; // userId
  final DateTime submittedAt;

  /// pending | approved | rejected
  final String status;
  final String selfieUrl;
  final String citizenshipUrl;
  final String panCardUrl;
  final List<String> locationPhotoUrls;
  final double locationLat;
  final double locationLng;
  final String panNumberSubmitted;
  final String citizenshipNumberSubmitted;
  final String gmailAccountSubmitted;
  final String qrCodeUrlSubmitted;
  final String adminReviewedBy;
  final DateTime? adminReviewedAt;
  final String adminNotes;
  final String rejectionReason;

  const KycSubmissionModel({
    required this.submissionId,
    required this.sellerId,
    required this.submittedBy,
    required this.submittedAt,
    this.status = 'pending',
    this.selfieUrl = '',
    this.citizenshipUrl = '',
    this.panCardUrl = '',
    this.locationPhotoUrls = const [],
    this.locationLat = 0,
    this.locationLng = 0,
    this.panNumberSubmitted = '',
    this.citizenshipNumberSubmitted = '',
    this.gmailAccountSubmitted = '',
    this.qrCodeUrlSubmitted = '',
    this.adminReviewedBy = '',
    this.adminReviewedAt,
    this.adminNotes = '',
    this.rejectionReason = '',
  });

  bool get isPending => status == 'pending';

  factory KycSubmissionModel.fromMap(String id, Map<String, dynamic> data) {
    DateTime? ts(dynamic v) => v is Timestamp ? v.toDate() : null;
    return KycSubmissionModel(
      submissionId: id,
      sellerId: data['sellerId'] as String? ?? '',
      submittedBy: data['submittedBy'] as String? ?? '',
      submittedAt: ts(data['submittedAt']) ?? DateTime.now(),
      status: data['status'] as String? ?? 'pending',
      selfieUrl: data['selfieUrl'] as String? ?? '',
      citizenshipUrl: data['citizenshipUrl'] as String? ?? '',
      panCardUrl: data['panCardUrl'] as String? ?? '',
      locationPhotoUrls:
          List<String>.from(data['locationPhotoUrls'] ?? const []),
      locationLat: (data['locationLat'] as num?)?.toDouble() ?? 0,
      locationLng: (data['locationLng'] as num?)?.toDouble() ?? 0,
      panNumberSubmitted: data['panNumberSubmitted'] as String? ?? '',
      citizenshipNumberSubmitted:
          data['citizenshipNumberSubmitted'] as String? ?? '',
      gmailAccountSubmitted: data['gmailAccountSubmitted'] as String? ?? '',
      qrCodeUrlSubmitted: data['qrCodeUrlSubmitted'] as String? ?? '',
      adminReviewedBy: data['adminReviewedBy'] as String? ?? '',
      adminReviewedAt: ts(data['adminReviewedAt']),
      adminNotes: data['adminNotes'] as String? ?? '',
      rejectionReason: data['rejectionReason'] as String? ?? '',
    );
  }

  factory KycSubmissionModel.fromFirestore(DocumentSnapshot doc) =>
      KycSubmissionModel.fromMap(
          doc.id, doc.data() as Map<String, dynamic>? ?? {});

  Map<String, dynamic> toMap() => {
        'sellerId': sellerId,
        'submittedBy': submittedBy,
        'submittedAt': Timestamp.fromDate(submittedAt),
        'status': status,
        'selfieUrl': selfieUrl,
        'citizenshipUrl': citizenshipUrl,
        'panCardUrl': panCardUrl,
        'locationPhotoUrls': locationPhotoUrls,
        'locationLat': locationLat,
        'locationLng': locationLng,
        'panNumberSubmitted': panNumberSubmitted,
        'citizenshipNumberSubmitted': citizenshipNumberSubmitted,
        'gmailAccountSubmitted': gmailAccountSubmitted,
        'qrCodeUrlSubmitted': qrCodeUrlSubmitted,
        'adminReviewedBy': adminReviewedBy,
        'adminReviewedAt': adminReviewedAt != null
            ? Timestamp.fromDate(adminReviewedAt!)
            : null,
        'adminNotes': adminNotes,
        'rejectionReason': rejectionReason,
      };

  KycSubmissionModel copyWith({
    String? status,
    String? adminReviewedBy,
    DateTime? adminReviewedAt,
    String? adminNotes,
    String? rejectionReason,
  }) {
    return KycSubmissionModel(
      submissionId: submissionId,
      sellerId: sellerId,
      submittedBy: submittedBy,
      submittedAt: submittedAt,
      status: status ?? this.status,
      selfieUrl: selfieUrl,
      citizenshipUrl: citizenshipUrl,
      panCardUrl: panCardUrl,
      locationPhotoUrls: locationPhotoUrls,
      locationLat: locationLat,
      locationLng: locationLng,
      panNumberSubmitted: panNumberSubmitted,
      citizenshipNumberSubmitted: citizenshipNumberSubmitted,
      gmailAccountSubmitted: gmailAccountSubmitted,
      qrCodeUrlSubmitted: qrCodeUrlSubmitted,
      adminReviewedBy: adminReviewedBy ?? this.adminReviewedBy,
      adminReviewedAt: adminReviewedAt ?? this.adminReviewedAt,
      adminNotes: adminNotes ?? this.adminNotes,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  @override
  List<Object?> get props => [
        submissionId,
        sellerId,
        submittedBy,
        submittedAt,
        status,
        selfieUrl,
        citizenshipUrl,
        panCardUrl,
        locationPhotoUrls,
        locationLat,
        locationLng,
        panNumberSubmitted,
        citizenshipNumberSubmitted,
        gmailAccountSubmitted,
        qrCodeUrlSubmitted,
        adminReviewedBy,
        adminReviewedAt,
        adminNotes,
        rejectionReason,
      ];
}
