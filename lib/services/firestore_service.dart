import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/seller_model.dart';
import '../models/report_model.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';
import '../core/constants/app_constants.dart';
import 'trust_score_service.dart';

final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService(ref));

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Ref _ref;

  FirestoreService(this._ref);

  // ── Sellers ────────────────────────────────────────────────────────────────

  /// Search sellers by phone, esewaId, tiktokHandle, instagramHandle in parallel.
  Future<List<SellerModel>> searchSellers(String query) async {
    try {
      final q = query.trim();
      if (q.isEmpty) return [];

      final futures = await Future.wait([
        _db
            .collection(AppConstants.colSellers)
            .where('phone', isEqualTo: q)
            .limit(5)
            .get(),
        _db
            .collection(AppConstants.colSellers)
            .where('phoneNumber', isEqualTo: q)
            .limit(5)
            .get(),
        _db
            .collection(AppConstants.colSellers)
            .where('esewaId', isEqualTo: q)
            .limit(5)
            .get(),
        _db
            .collection(AppConstants.colSellers)
            .where('tiktokHandle', isEqualTo: q)
            .limit(5)
            .get(),
        _db
            .collection(AppConstants.colSellers)
            .where('instagramHandle', isEqualTo: q)
            .limit(5)
            .get(),
      ]);

      final seen = <String>{};
      final results = <SellerModel>[];
      for (final snap in futures) {
        for (final doc in snap.docs) {
          if (!seen.contains(doc.id)) {
            seen.add(doc.id);
            results.add(SellerModel.fromFirestore(doc));
          }
        }
      }
      return results.take(AppConstants.searchPageSize).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Legacy single-result search for backward compat
  Future<SellerModel?> searchSeller(String query) async {
    final results = await searchSellers(query);
    return results.isEmpty ? null : results.first;
  }

  Future<SellerModel?> getSellerById(String id) async {
    try {
      final doc =
          await _db.collection(AppConstants.colSellers).doc(id).get();
      if (!doc.exists) return null;
      return SellerModel.fromFirestore(doc);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> registerSeller(SellerModel seller) async {
    try {
      final ref = seller.sellerId.isEmpty
          ? _db.collection(AppConstants.colSellers).doc()
          : _db.collection(AppConstants.colSellers).doc(seller.sellerId);
      await ref.set(seller.toMap(), SetOptions(merge: true));
      return ref.id;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateSeller(
      String sellerId, Map<String, dynamic> data) async {
    try {
      await _db
          .collection(AppConstants.colSellers)
          .doc(sellerId)
          .update(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> createOrUpdateSeller(SellerModel seller) async {
    return registerSeller(seller);
  }

  // ── Reports ────────────────────────────────────────────────────────────────

  Future<List<ReportModel>> getReportsForSeller(String sellerId) async {
    try {
      final snap = await _db
          .collection(AppConstants.colReports)
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('submittedAt', descending: true)
          .get();
      return snap.docs
          .map((d) => ReportModel.fromFirestore(d))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Reports filed by a specific user (buyer's "My Reports" list).
  /// Sorted client-side so no composite index is required.
  Future<List<ReportModel>> getReportsByReporter(String reporterId) async {
    try {
      final snap = await _db
          .collection(AppConstants.colReports)
          .where('reporterId', isEqualTo: reporterId)
          .get();
      final reports =
          snap.docs.map((d) => ReportModel.fromFirestore(d)).toList()
            ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      return reports;
    } catch (e) {
      return [];
    }
  }

  /// Stream version for real-time (backward compat with SellerProfileScreen)
  Stream<List<ReportModel>> getReportsForSellerStream(String sellerId) {
    return _db
        .collection(AppConstants.colReports)
        .where('sellerId', isEqualTo: sellerId)
        .where('status', whereIn: ['verified', 'pending'])
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => ReportModel.fromFirestore(d)).toList());
  }

  Future<String> submitReport(ReportModel report) async {
    try {
      final docRef = _db.collection(AppConstants.colReports).doc();
      await docRef.set(report.toMap());

      // Try to recalculate trust score
      try {
        await _recalculateTrustScore(report.sellerId);
      } catch (_) {}

      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addSellerResponse(
      String reportId, String response) async {
    try {
      await _db
          .collection(AppConstants.colReports)
          .doc(reportId)
          .update({'sellerResponse': response});
    } catch (e) {
      rethrow;
    }
  }

  // ── Reviews ────────────────────────────────────────────────────────────────

  Future<List<ReviewModel>> getReviewsForSeller(String sellerId) async {
    try {
      final snap = await _db
          .collection(AppConstants.colReviews)
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs
          .map((d) => ReviewModel.fromFirestore(d))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Stream version for real-time (backward compat)
  Stream<List<ReviewModel>> getReviewsForSellerStream(String sellerId) {
    return _db
        .collection(AppConstants.colReviews)
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => ReviewModel.fromFirestore(d)).toList());
  }

  /// Submit a review with full anti-bot protection.
  /// Throws [Exception] with user-friendly message if review is rejected.
  Future<void> submitReview(ReviewModel review) async {
    // ── Anti-bot check 1: Minimum review text length ──
    if (review.comment.trim().length < AppConstants.minReviewChars) {
      throw Exception(
          'Review must be at least ${AppConstants.minReviewChars} characters. '
          'Please write a detailed review to help the community.');
    }

    // ── Anti-bot check 2: Account age ──
    try {
      final userDoc = await _db
          .collection(AppConstants.colUsers)
          .doc(review.reviewerId)
          .get();
      if (userDoc.exists) {
        final createdAt = userDoc.data()?['createdAt'] as Timestamp?;
        if (createdAt != null) {
          final accountAge =
              DateTime.now().difference(createdAt.toDate()).inDays;
          if (accountAge < AppConstants.minAccountAgeDays) {
            throw Exception(
                'Your account must be at least ${AppConstants.minAccountAgeDays} '
                'days old to submit reviews. This prevents fake review bots.');
          }
        }
      }
    } catch (e) {
      if (e.toString().contains('days old')) rethrow;
    }

    // ── Anti-bot check 3: Duplicate review per seller ──
    try {
      final dupSnap = await _db
          .collection(AppConstants.colReviews)
          .where('reviewerId', isEqualTo: review.reviewerId)
          .where('sellerId', isEqualTo: review.sellerId)
          .limit(1)
          .get();
      if (dupSnap.docs.isNotEmpty) {
        throw Exception(
            'You have already reviewed this seller. '
            'Each user can submit only one review per seller.');
      }
    } catch (e) {
      if (e.toString().contains('already reviewed')) rethrow;
    }

    // ── Anti-bot check 4: Daily review rate limit ──
    try {
      final dayAgo = DateTime.now().subtract(const Duration(hours: 24));
      final rateSnap = await _db
          .collection(AppConstants.colReviews)
          .where('reviewerId', isEqualTo: review.reviewerId)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(dayAgo))
          .get();
      if (rateSnap.docs.length >= AppConstants.maxReviewsPerDay) {
        throw Exception(
            'You can submit a maximum of ${AppConstants.maxReviewsPerDay} '
            'reviews per day. Please try again tomorrow.');
      }
    } catch (e) {
      if (e.toString().contains('maximum of')) rethrow;
    }

    // ── Anti-bot check 5: Review cooldown (1 hour gap) ──
    try {
      final cooldown = DateTime.now()
          .subtract(Duration(hours: AppConstants.reviewCooldownHours));
      final coolSnap = await _db
          .collection(AppConstants.colReviews)
          .where('reviewerId', isEqualTo: review.reviewerId)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(cooldown))
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      if (coolSnap.docs.isNotEmpty) {
        throw Exception(
            'Please wait at least ${AppConstants.reviewCooldownHours} hour(s) '
            'between reviews. This prevents automated spam.');
      }
    } catch (e) {
      if (e.toString().contains('wait at least')) rethrow;
    }

    // ── Anti-bot check 6: Text similarity with recent reviews ──
    try {
      final recentReviews = await _db
          .collection(AppConstants.colReviews)
          .where('reviewerId', isEqualTo: review.reviewerId)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();
      for (final doc in recentReviews.docs) {
        final oldComment =
            (doc.data()['comment'] as String?)?.toLowerCase() ?? '';
        final newComment = review.comment.toLowerCase();
        final similarity = _jaccardSimilarity(oldComment, newComment);
        if (similarity > AppConstants.textSimilarityThreshold) {
          throw Exception(
              'Your review is too similar to a previous review you submitted. '
              'Please write a unique, honest review.');
        }
      }
    } catch (e) {
      if (e.toString().contains('too similar')) rethrow;
    }

    // ── Calculate authenticity weight ──
    double weight = 1.0;
    if (review.comment.trim().length < 50) {
      weight -= AppConstants.authPenaltyShortReview;
    }
    if (!review.isVerifiedPurchase) {
      weight -= 0.15;
    }

    // ── All checks passed — submit review ──
    try {
      final reviewWithWeight = review.copyWith(
        authenticityWeight: weight.clamp(0.1, 1.0),
      );
      await _db
          .collection(AppConstants.colReviews)
          .doc()
          .set(reviewWithWeight.toMap());
      await _recalculateRating(review.sellerId);
    } catch (e) {
      rethrow;
    }
  }

  /// Jaccard similarity between two strings (word-level).
  /// Returns 0.0 (completely different) to 1.0 (identical).
  double _jaccardSimilarity(String a, String b) {
    if (a.isEmpty && b.isEmpty) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    final setA = a.split(RegExp(r'\s+')).toSet();
    final setB = b.split(RegExp(r'\s+')).toSet();
    final intersection = setA.intersection(setB).length;
    final union = setA.union(setB).length;
    if (union == 0) return 0.0;
    return intersection / union;
  }

  // ── Users ──────────────────────────────────────────────────────────────────

  Future<void> createOrUpdateUser(UserModel user) async {
    try {
      await _db
          .collection(AppConstants.colUsers)
          .doc(user.userId)
          .set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _db
          .collection(AppConstants.colUsers)
          .doc(userId)
          .get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  // ── Identity verification (admin) ────────────────────────────────────────────

  /// Live stream of users awaiting national-ID verification.
  Stream<List<UserModel>> watchPendingVerifications() {
    return _db
        .collection(AppConstants.colUsers)
        .where('verificationStatus', isEqualTo: 'pending')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => UserModel.fromFirestore(d)).toList());
  }

  /// One-time fetch of pending verifications (for non-stream callers).
  Future<List<UserModel>> getPendingVerifications() async {
    final snap = await _db
        .collection(AppConstants.colUsers)
        .where('verificationStatus', isEqualTo: 'pending')
        .get();
    return snap.docs.map((d) => UserModel.fromFirestore(d)).toList();
  }

  /// Admin approves or rejects a user's identity. [status] = approved | rejected.
  Future<void> setVerificationStatus(String userId, String status) async {
    await _db.collection(AppConstants.colUsers).doc(userId).set(
      {
        'verificationStatus': status,
        'verifiedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // ── Cyber Bureau escalation ──────────────────────────────────────────────────

  /// Sellers with enough reports to potentially warrant Cyber Bureau escalation.
  Future<List<SellerModel>> getEscalationCandidates() async {
    final snap = await _db
        .collection(AppConstants.colSellers)
        .where('scamReportCount', isGreaterThanOrEqualTo: 3)
        .get();
    final list = snap.docs.map((d) => SellerModel.fromFirestore(d)).toList();
    list.sort((a, b) => b.scamReportCount.compareTo(a.scamReportCount));
    return list;
  }

  /// Live stream of escalation records already prepared/submitted.
  Stream<List<Map<String, dynamic>>> watchEscalations() {
    return _db
        .collection('cyber_bureau_escalations')
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  /// Persist a prepared Nivedan letter for a flagged seller.
  Future<void> saveCyberBureauEscalation({
    required String sellerId,
    required String sellerName,
    required String letter,
    required int reportCount,
    required double totalLoss,
  }) async {
    await _db.collection('cyber_bureau_escalations').doc(sellerId).set(
      {
        'sellerId': sellerId,
        'sellerName': sellerName,
        'letter': letter,
        'reportCount': reportCount,
        'totalLoss': totalLoss,
        'status': 'prepared', // prepared | submitted
        'generatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Admin approves a prepared letter, allowing it to be shared/submitted.
  Future<void> approveEscalation(String sellerId) async {
    await _db.collection('cyber_bureau_escalations').doc(sellerId).set(
      {
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Read a single escalation record (to know its current status).
  Future<Map<String, dynamic>?> getEscalation(String sellerId) async {
    final doc =
        await _db.collection('cyber_bureau_escalations').doc(sellerId).get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...?doc.data()};
  }

  /// Mark a prepared escalation as officially submitted to the Cyber Bureau.
  Future<void> markEscalationSubmitted(String sellerId) async {
    await _db.collection('cyber_bureau_escalations').doc(sellerId).set(
      {
        'status': 'submitted',
        'submittedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // ── Rate Limiting ──────────────────────────────────────────────────────────

  /// Returns true if reporter can still submit (under limit)
  Future<bool> checkReportRateLimit(
      String reporterId, String sellerId) async {
    try {
      final cutoff = DateTime.now().subtract(
          const Duration(days: AppConstants.reportRateLimitDays));
      final snap = await _db
          .collection(AppConstants.colReports)
          .where('reporterId', isEqualTo: reporterId)
          .where('sellerId', isEqualTo: sellerId)
          .where('submittedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
          .get();
      return snap.size < AppConstants.maxReportsPerSellerPerDays;
    } catch (_) {
      return true; // Allow on error
    }
  }

  // ── Admin ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final now = DateTime.now();
      final monthStart =
          DateTime(now.year, now.month, 1);

      final results = await Future.wait([
        _db
            .collection(AppConstants.colSellers)
            .count()
            .get(),
        _db
            .collection(AppConstants.colReports)
            .where('submittedAt',
                isGreaterThanOrEqualTo:
                    Timestamp.fromDate(monthStart))
            .count()
            .get(),
        _db
            .collection(AppConstants.colSellers)
            .where('trustVerdict', isEqualTo: 'high_risk')
            .count()
            .get(),
        _db
            .collection(AppConstants.colReports)
            .where('status', isEqualTo: 'pending')
            .count()
            .get(),
      ]);

      // Sum total NPR lost from verified reports
      double totalNprLost = 0;
      try {
        final lostSnap = await _db
            .collection(AppConstants.colReports)
            .where('status', isEqualTo: 'verified')
            .get();
        for (final doc in lostSnap.docs) {
          totalNprLost +=
              (doc.data()['amountLost'] as num?)?.toDouble() ?? 0;
        }
      } catch (_) {}

      return {
        'totalSellers': results[0].count ?? 0,
        'reportsThisMonth': results[1].count ?? 0,
        'totalNprLost': totalNprLost,
        'highRiskCount': results[2].count ?? 0,
        'pendingReports': results[3].count ?? 0,
      };
    } catch (e) {
      return {
        'totalSellers': 0,
        'reportsThisMonth': 0,
        'totalNprLost': 0.0,
        'highRiskCount': 0,
        'pendingReports': 0,
      };
    }
  }

  Future<List<ReportModel>> getAllReports({String? status}) async {
    try {
      Query query = _db
          .collection(AppConstants.colReports)
          .orderBy('submittedAt', descending: true);
      if (status != null && status != 'all') {
        query = query.where('status', isEqualTo: status);
      }
      final snap = await query.get();
      return snap.docs
          .map((d) => ReportModel.fromFirestore(d as DocumentSnapshot))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<SellerModel>> getAllSellers() async {
    try {
      final snap = await _db
          .collection(AppConstants.colSellers)
          .orderBy('trustScore')
          .get();
      return snap.docs
          .map((d) => SellerModel.fromFirestore(d))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> updateReportStatus(
    String reportId,
    String status,
    String adminNotes,
  ) async {
    try {
      await _db
          .collection(AppConstants.colReports)
          .doc(reportId)
          .update({
        'status': status,
        'adminNotes': adminNotes,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logAdminAction(
    String adminId,
    String action,
    String targetId,
    String reason,
  ) async {
    try {
      await _db.collection(AppConstants.colAdminActions).add({
        'adminId': adminId,
        'action': action,
        'targetId': targetId,
        'reason': reason,
        'timestamp': Timestamp.now(),
      });
    } catch (_) {}
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  Future<void> _recalculateTrustScore(String sellerId) async {
    try {
      final seller = await getSellerById(sellerId);
      if (seller == null) return;

      final reports = await getReportsForSeller(sellerId);
      final reviews = await getReviewsForSeller(sellerId);

      final service = _ref.read(trustScoreServiceProvider);
      final newScore =
          service.calculateTrustScore(seller, reports, reviews);
      final verdict = service.getTrustVerdict(newScore);

      await _db
          .collection(AppConstants.colSellers)
          .doc(sellerId)
          .update({
        'trustScore': newScore,
        'trustVerdict': verdict,
        'scamReportCount': reports
            .where((r) => r.status != 'flagged_false')
            .length,
        'lastActiveAt': Timestamp.now(),
        'trustScoreHistory': FieldValue.arrayUnion([
          {
            'score': newScore,
            'date': Timestamp.now().millisecondsSinceEpoch,
          }
        ]),
      });
    } catch (_) {}
  }

  Future<void> _recalculateRating(String sellerId) async {
    try {
      final reviews = await getReviewsForSeller(sellerId);
      if (reviews.isEmpty) return;

      final avg = reviews.map((r) => r.rating).reduce((a, b) => a + b) /
          reviews.length;

      await _db
          .collection(AppConstants.colSellers)
          .doc(sellerId)
          .update({
        'averageRating': avg,
        'reviewCount': reviews.length,
        'lastActiveAt': Timestamp.now(),
      });
    } catch (_) {}
  }
}
