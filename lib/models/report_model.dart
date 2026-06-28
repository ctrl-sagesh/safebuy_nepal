import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ReportModel extends Equatable {
  final String reportId;
  final String reporterId;
  final String sellerId;
  final String sellerPhone;
  final String? sellerEsewaId;
  final String? sellerSocialHandle;
  final String platform;
  final String incidentType;
  final double amountLost;
  final String description;
  final DateTime incidentDate;
  final String? paymentScreenshotUrl;
  final String? chatScreenshotUrl;
  final DateTime submittedAt;
  final String status; // pending / verified / disputed / resolved / flagged_false
  final bool reporterDeclaration;
  final String? sellerResponse;
  final String? adminNotes;
  final bool isAnonymizedForDeletion;

  const ReportModel({
    required this.reportId,
    required this.reporterId,
    required this.sellerId,
    required this.sellerPhone,
    this.sellerEsewaId,
    this.sellerSocialHandle,
    required this.platform,
    required this.incidentType,
    required this.amountLost,
    required this.description,
    required this.incidentDate,
    this.paymentScreenshotUrl,
    this.chatScreenshotUrl,
    required this.submittedAt,
    required this.status,
    required this.reporterDeclaration,
    this.sellerResponse,
    this.adminNotes,
    this.isAnonymizedForDeletion = false,
  });

  /// Public, privacy-safe label for the reporter. The reporter's name may be
  /// shown but phone/email/personal details are never exposed publicly —
  /// only an admin can access full reporter details.
  String get anonymizedReporter {
    if (reporterId.isEmpty || reporterId == 'anonymous') {
      return 'Anonymous reporter';
    }
    final tag = reporterId.length >= 4
        ? reporterId.substring(0, 4).toUpperCase()
        : reporterId.toUpperCase();
    return 'Verified buyer #$tag';
  }

  factory ReportModel.fromMap(String id, Map<String, dynamic> data) {
    return ReportModel(
      reportId: id,
      reporterId: data['reporterId'] as String? ?? '',
      sellerId: data['sellerId'] as String? ?? '',
      sellerPhone: data['sellerPhone'] as String? ?? '',
      sellerEsewaId: data['sellerEsewaId'] as String?,
      sellerSocialHandle: data['sellerSocialHandle'] as String?,
      platform: data['platform'] as String? ?? '',
      incidentType: data['incidentType'] as String? ?? '',
      amountLost: (data['amountLost'] as num?)?.toDouble() ?? 0.0,
      description: data['description'] as String? ?? '',
      incidentDate: data['incidentDate'] != null
          ? (data['incidentDate'] as Timestamp).toDate()
          : DateTime.now(),
      paymentScreenshotUrl: data['paymentScreenshotUrl'] as String?,
      chatScreenshotUrl: data['chatScreenshotUrl'] as String?,
      submittedAt: data['submittedAt'] != null
          ? (data['submittedAt'] as Timestamp).toDate()
          : data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
      status: data['status'] as String? ?? 'pending',
      reporterDeclaration: data['reporterDeclaration'] as bool? ?? false,
      sellerResponse: data['sellerResponse'] as String?,
      adminNotes: data['adminNotes'] as String?,
      isAnonymizedForDeletion:
          data['isAnonymizedForDeletion'] as bool? ?? false,
    );
  }

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    return ReportModel.fromMap(
        doc.id, doc.data() as Map<String, dynamic>? ?? {});
  }

  Map<String, dynamic> toMap() => {
        'reporterId': reporterId,
        'sellerId': sellerId,
        'sellerPhone': sellerPhone,
        'sellerEsewaId': sellerEsewaId,
        'sellerSocialHandle': sellerSocialHandle,
        'platform': platform,
        'incidentType': incidentType,
        'amountLost': amountLost,
        'description': description,
        'incidentDate': Timestamp.fromDate(incidentDate),
        'paymentScreenshotUrl': paymentScreenshotUrl,
        'chatScreenshotUrl': chatScreenshotUrl,
        'submittedAt': Timestamp.fromDate(submittedAt),
        'createdAt': Timestamp.fromDate(submittedAt),
        'status': status,
        'reporterDeclaration': reporterDeclaration,
        'sellerResponse': sellerResponse,
        'adminNotes': adminNotes,
        'isAnonymizedForDeletion': isAnonymizedForDeletion,
      };

  ReportModel copyWith({
    String? reportId,
    String? reporterId,
    String? sellerId,
    String? sellerPhone,
    String? sellerEsewaId,
    String? sellerSocialHandle,
    String? platform,
    String? incidentType,
    double? amountLost,
    String? description,
    DateTime? incidentDate,
    String? paymentScreenshotUrl,
    String? chatScreenshotUrl,
    DateTime? submittedAt,
    String? status,
    bool? reporterDeclaration,
    String? sellerResponse,
    String? adminNotes,
    bool? isAnonymizedForDeletion,
  }) {
    return ReportModel(
      reportId: reportId ?? this.reportId,
      reporterId: reporterId ?? this.reporterId,
      sellerId: sellerId ?? this.sellerId,
      sellerPhone: sellerPhone ?? this.sellerPhone,
      sellerEsewaId: sellerEsewaId ?? this.sellerEsewaId,
      sellerSocialHandle: sellerSocialHandle ?? this.sellerSocialHandle,
      platform: platform ?? this.platform,
      incidentType: incidentType ?? this.incidentType,
      amountLost: amountLost ?? this.amountLost,
      description: description ?? this.description,
      incidentDate: incidentDate ?? this.incidentDate,
      paymentScreenshotUrl: paymentScreenshotUrl ?? this.paymentScreenshotUrl,
      chatScreenshotUrl: chatScreenshotUrl ?? this.chatScreenshotUrl,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
      reporterDeclaration: reporterDeclaration ?? this.reporterDeclaration,
      sellerResponse: sellerResponse ?? this.sellerResponse,
      adminNotes: adminNotes ?? this.adminNotes,
      isAnonymizedForDeletion:
          isAnonymizedForDeletion ?? this.isAnonymizedForDeletion,
    );
  }

  @override
  List<Object?> get props => [
        reportId,
        reporterId,
        sellerId,
        sellerPhone,
        sellerEsewaId,
        sellerSocialHandle,
        platform,
        incidentType,
        amountLost,
        description,
        incidentDate,
        paymentScreenshotUrl,
        chatScreenshotUrl,
        submittedAt,
        status,
        reporterDeclaration,
        sellerResponse,
        adminNotes,
        isAnonymizedForDeletion,
      ];
}
