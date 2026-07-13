import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/kyc_submission_model.dart';
import 'storage_service.dart';

/// Handles the full KYC verification pipeline:
/// document uploads (Firebase Storage) → submission (Firestore) →
/// admin review → card issuance.
class KycService {
  KycService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // ── Uploads (Firebase Storage) ───────────────────────────────────────────────

  /// Uploads a KYC document image. Returns the download URL.
  /// [kind] is one of: selfie, citizenship, pan, location1, location2, location3.
  Future<String> uploadKycDocument({
    required String userId,
    required String kind,
    required File file,
  }) {
    return StorageService.uploadKycDocument(
      file: file,
      userId: userId,
      docType: kind,
    );
  }

  /// Uploads the seller's eSewa QR code screenshot. Returns the download URL.
  Future<String> uploadQrCode({
    required String userId,
    required File file,
  }) {
    return StorageService.uploadQrCode(file: file, sellerId: userId);
  }

  // ── Submission ───────────────────────────────────────────────────────────────

  Future<String> submitKyc(KycSubmissionModel submission) async {
    final doc = await _db.collection('kyc_submissions').add(submission.toMap());

    // Mark the linked seller as KYC-pending.
    if (submission.sellerId.isNotEmpty) {
      await _db.collection('sellers').doc(submission.sellerId).set(
        {'kycStatus': 'pending'},
        SetOptions(merge: true),
      );
    }
    return doc.id;
  }

  Future<KycSubmissionModel?> getLatestSubmissionForUser(String userId) async {
    final snap = await _db
        .collection('kyc_submissions')
        .where('submittedBy', isEqualTo: userId)
        .orderBy('submittedAt', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return KycSubmissionModel.fromFirestore(snap.docs.first);
  }

  // ── Admin review ─────────────────────────────────────────────────────────────

  Stream<List<KycSubmissionModel>> watchSubmissions({String? status}) {
    Query<Map<String, dynamic>> q = _db.collection('kyc_submissions');
    if (status != null) q = q.where('status', isEqualTo: status);
    return q
        .orderBy('submittedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map(KycSubmissionModel.fromFirestore).toList());
  }

  /// Approves a KYC submission at the given [tier] and issues the
  /// SafeBuy verification card.
  Future<String> approveSubmission({
    required KycSubmissionModel submission,
    required String tier,
    required String adminId,
  }) async {
    final now = DateTime.now();
    final expiry = DateTime(now.year, now.month + 6, now.day);
    final cardId = _generateCardId();

    final batch = _db.batch();
    batch.update(
      _db.collection('kyc_submissions').doc(submission.submissionId),
      {
        'status': 'approved',
        'adminReviewedBy': adminId,
        'adminReviewedAt': Timestamp.fromDate(now),
      },
    );
    if (submission.sellerId.isNotEmpty) {
      batch.set(
        _db.collection('sellers').doc(submission.sellerId),
        {
          'kycStatus': 'verified',
          'verificationTier': tier,
          'isVerified': true,
          'verifiedBadge': tier == 'premium',
          'kycSelfieUrl': submission.selfieUrl,
          'kycCitizenshipUrl': submission.citizenshipUrl,
          'kycPanCardUrl': submission.panCardUrl,
          'panNumber': submission.panNumberSubmitted,
          'gmailAccount': submission.gmailAccountSubmitted,
          'qrCodeUrl': submission.qrCodeUrlSubmitted,
          'isQrLocked': true,
          'safebuyCardId': cardId,
          'verificationDate': Timestamp.fromDate(now),
          'verificationExpiry': Timestamp.fromDate(expiry),
          'kycLocationLat': submission.locationLat,
          'kycLocationLng': submission.locationLng,
        },
        SetOptions(merge: true),
      );
    }
    batch.set(
      _db.collection('verification_cards').doc(cardId),
      {
        'cardId': cardId,
        'sellerId': submission.sellerId,
        'tier': tier,
        'issuedAt': Timestamp.fromDate(now),
        'expiresAt': Timestamp.fromDate(expiry),
        'status': 'active',
      },
    );
    await batch.commit();
    return cardId;
  }

  Future<void> rejectSubmission({
    required KycSubmissionModel submission,
    required String reason,
    required String adminId,
  }) async {
    final batch = _db.batch();
    batch.update(
      _db.collection('kyc_submissions').doc(submission.submissionId),
      {
        'status': 'rejected',
        'rejectionReason': reason,
        'adminReviewedBy': adminId,
        'adminReviewedAt': Timestamp.fromDate(DateTime.now()),
      },
    );
    if (submission.sellerId.isNotEmpty) {
      batch.set(
        _db.collection('sellers').doc(submission.sellerId),
        {'kycStatus': 'rejected', 'kycRejectionReason': reason},
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  // ── QR change requests ───────────────────────────────────────────────────────

  Future<void> submitQrChangeRequest({
    required String sellerId,
    required String userId,
    required String reason,
    required String explanation,
    required String newQrUrl,
  }) async {
    await _db.collection('qr_change_requests').add({
      'sellerId': sellerId,
      'requestedBy': userId,
      'reason': reason,
      'explanation': explanation,
      'newQrUrl': newQrUrl,
      'status': 'pending',
      'requestedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  String _generateCardId() {
    final year = DateTime.now().year;
    final n = DateTime.now().millisecondsSinceEpoch % 100000;
    return 'SBV-$year-${n.toString().padLeft(5, '0')}';
  }
}
