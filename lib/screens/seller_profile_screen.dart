import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/seller_model.dart';
import '../models/report_model.dart';
import '../models/review_model.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';
import '../widgets/trust_badge_widget.dart';
import '../core/widgets/skeleton_loader.dart';
import '../core/widgets/empty_state_widget.dart';
import 'report_screen.dart';

// ── FutureProviders ────────────────────────────────────────────────────────────

final _sellerReviewsProvider =
    FutureProvider.family<List<ReviewModel>, String>((ref, sellerId) async {
  return ref.read(firestoreServiceProvider).getReviewsForSeller(sellerId);
});

final _sellerReportsProvider =
    FutureProvider.family<List<ReportModel>, String>((ref, sellerId) async {
  return ref.read(firestoreServiceProvider).getReportsForSeller(sellerId);
});

class SellerProfileScreen extends ConsumerWidget {
  final SellerModel seller;

  const SellerProfileScreen({super.key, required this.seller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (_, _) => [
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: const Color(AppColors.primary),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: () {
                    final link = 'safebuy.np/seller/${seller.sellerId}';
                    Clipboard.setData(ClipboardData(text: link));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Profile link copied to clipboard')),
                    );
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeader(context),
              ),
              bottom: const TabBar(
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                tabs: [
                  Tab(text: 'Reviews'),
                  Tab(text: 'Reports'),
                ],
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _ReviewsTab(sellerId: seller.sellerId),
              _ReportsTab(sellerId: seller.sellerId),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReportScreen(prefilledSeller: seller),
            ),
          ),
          backgroundColor: const Color(AppColors.highRisk),
          icon: const Icon(Icons.report_problem),
          label: const Text('Report this Seller'),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(AppColors.primary), Color(AppColors.secondary)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    backgroundImage: seller.profileImageUrl != null
                        ? NetworkImage(seller.profileImageUrl!)
                        : null,
                    child: seller.profileImageUrl == null
                        ? Text(
                            seller.displayName.isNotEmpty
                                ? seller.displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                seller.displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (seller.isVerified) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.verified,
                                  color: Colors.white, size: 20),
                            ],
                          ],
                        ),
                        if (seller.businessName != null &&
                            seller.businessName != seller.name) ...[
                          const SizedBox(height: 2),
                          Text(
                            seller.name,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ],
                        const SizedBox(height: 6),
                        TrustBadge(
                            trustVerdict: seller.trustVerdict, large: true),
                      ],
                    ),
                  ),
                  TrustScoreCircle(score: seller.trustScore, size: 80),
                ],
              ),
              const SizedBox(height: 16),
              _buildStatsRow(),
              const SizedBox(height: 12),
              _buildHandles(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _statItem('${seller.totalOrders}', 'Orders'),
        _divider(),
        _statItem('${seller.reviewCount}', 'Reviews'),
        _divider(),
        _statItem('${seller.scamReportCount}', 'Reports',
            highlight: seller.scamReportCount > 0),
        _divider(),
        _statItem(seller.averageRating.toStringAsFixed(1), 'Rating'),
      ],
    );
  }

  Widget _statItem(String value, String label, {bool highlight = false}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: highlight ? const Color(AppColors.accent) : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 30,
        color: Colors.white.withValues(alpha: 0.3),
      );

  Widget _buildHandles() {
    final handles = <Widget>[];
    if (seller.phone.isNotEmpty) {
      handles.add(_handleChip(Icons.phone, seller.phone));
    }
    if (seller.esewaId != null) {
      handles.add(
          _handleChip(Icons.account_balance_wallet, seller.esewaId!));
    }
    if (seller.tiktokHandle != null) {
      handles.add(
          _handleChip(Icons.video_library, '@${seller.tiktokHandle}'));
    }
    if (seller.instagramHandle != null) {
      handles.add(
          _handleChip(Icons.photo_camera, '@${seller.instagramHandle}'));
    }
    if (handles.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 8, runSpacing: 6, children: handles);
  }

  Widget _handleChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 13),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Reviews Tab ────────────────────────────────────────────────────────────────

class _ReviewsTab extends ConsumerWidget {
  final String sellerId;
  const _ReviewsTab({required this.sellerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(_sellerReviewsProvider(sellerId));
    return Column(
      children: [
        // Write a review (positive OR negative)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openWriteReview(context, ref, sellerId),
              icon: const Icon(Icons.rate_review_outlined, size: 18),
              label: const Text('Write a Review'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(AppColors.primary),
                side: const BorderSide(color: Color(AppColors.primary)),
                minimumSize: const Size(0, 46),
              ),
            ),
          ),
        ),
        Expanded(
          child: reviewsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: SkeletonList(count: 3, item: ReviewSkeleton()),
            ),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (reviews) {
              if (reviews.isEmpty) {
                return const EmptyStateWidget(variant: EmptyVariant.noReviews);
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: reviews.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _ReviewCard(review: reviews[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openWriteReview(
      BuildContext context, WidgetRef ref, String sellerId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to write a review.'),
          backgroundColor: Color(AppColors.primary),
        ),
      );
      Navigator.of(context).pushNamed('/auth');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _WriteReviewSheet(sellerId: sellerId, ref: ref),
    );
  }
}

// ── Write Review bottom sheet ────────────────────────────────────────────────

class _WriteReviewSheet extends StatefulWidget {
  const _WriteReviewSheet({required this.sellerId, required this.ref});
  final String sellerId;
  final WidgetRef ref;

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  int _rating = 0;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;
  String? _evidencePath;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickEvidence() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded,
                  color: Color(AppColors.primary)),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: Color(AppColors.primary)),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final file = await ImagePicker()
        .pickImage(source: source, maxWidth: 1280, imageQuality: 80);
    if (file != null && mounted) setState(() => _evidencePath = file.path);
  }

  String get _sentiment {
    if (_rating == 0) return '';
    if (_rating >= 4) return 'Positive 👍';
    if (_rating == 3) return 'Neutral 😐';
    return 'Negative 👎';
  }

  Color get _sentimentColor {
    if (_rating >= 4) return const Color(AppColors.trusted);
    if (_rating == 3) return const Color(0xFFB5860D);
    return const Color(AppColors.highRisk);
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating.')),
      );
      return;
    }
    if (_evidencePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please attach evidence (a screenshot). Proof is required so reviews stay fair.'),
        ),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _submitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final profile =
          await widget.ref.read(firestoreServiceProvider).getUserById(user.uid);
      // Anonymise: show only the reviewer's first name.
      final firstName = (profile?.fullName ?? 'Buyer').split(' ').first;
      final review = ReviewModel(
        reviewId: '',
        sellerId: widget.sellerId,
        reviewerId: user.uid,
        reviewerDisplayName: firstName,
        rating: _rating,
        comment: _commentCtrl.text.trim(),
        createdAt: DateTime.now(),
        isVerifiedPurchase: profile?.isVerifiedReporter ?? false,
        authenticityWeight: 1.0,
        helpfulCount: 0,
        evidenceUrl: _evidencePath,
      );
      await widget.ref.read(firestoreServiceProvider).submitReview(review);
      if (!mounted) return;
      widget.ref.invalidate(_sellerReviewsProvider(widget.sellerId));
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you! Your review has been posted.'),
          backgroundColor: Color(AppColors.trusted),
        ),
      );
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: const Color(AppColors.highRisk),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(AppColors.divider),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text('Write a Review',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text(
            'Share your honest experience — positive or negative. Both help the community.',
            style: TextStyle(fontSize: 13, color: Color(AppColors.textGrey)),
          ),
          const SizedBox(height: 16),
          // Star selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 1; i <= 5; i++)
                GestureDetector(
                  onTap: () => setState(() => _rating = i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      i <= _rating ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 40,
                      color: i <= _rating
                          ? const Color(AppColors.accent)
                          : const Color(AppColors.divider),
                    ),
                  ),
                ),
            ],
          ),
          if (_sentiment.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(_sentiment,
                    style: TextStyle(
                        color: _sentimentColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText:
                  'Describe your experience (min 20 characters)...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // ── Required evidence ──
          const Text('Evidence (required)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          const Text(
            'Reviews are anonymous, so proof is required to keep them fair and protect sellers from mistaken or false reviews.',
            style: TextStyle(fontSize: 11, color: Color(AppColors.textGrey)),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickEvidence,
            child: _evidencePath == null
                ? Container(
                    height: 88,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(AppColors.primary)
                          .withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(AppColors.primary)
                              .withValues(alpha: 0.3)),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined,
                            color: Color(AppColors.primary), size: 24),
                        SizedBox(height: 4),
                        Text('Tap to add a screenshot',
                            style: TextStyle(
                                fontSize: 12, color: Color(AppColors.primary))),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(File(_evidencePath!),
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: () => setState(() => _evidencePath = null),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(AppColors.primary),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Post Review',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor:
                      const Color(AppColors.primary).withValues(alpha: 0.1),
                  child: Text(
                    review.reviewerDisplayName.isNotEmpty
                        ? review.reviewerDisplayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Color(AppColors.primary),
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(review.reviewerDisplayName,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        DateFormat('dd MMM yyyy').format(review.createdAt),
                        style: const TextStyle(
                            fontSize: 11, color: Color(AppColors.textGrey)),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < review.rating ? Icons.star : Icons.star_border,
                      color: const Color(AppColors.accent),
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            if (review.isVerifiedPurchase) ...[
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(AppColors.trusted).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Verified Purchase',
                  style: TextStyle(
                      fontSize: 10, color: Color(AppColors.trusted)),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(review.comment,
                style: const TextStyle(
                    fontSize: 13, color: Color(AppColors.textDark))),
            if (review.authenticityWeight < 0.7) ...[
              const SizedBox(height: 4),
              const Text(
                'Low authenticity weight',
                style: TextStyle(fontSize: 10, color: Color(AppColors.textGrey)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Reports Tab ────────────────────────────────────────────────────────────────

class _ReportsTab extends ConsumerWidget {
  final String sellerId;
  const _ReportsTab({required this.sellerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(_sellerReportsProvider(sellerId));
    return reportsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: SkeletonList(count: 3, item: ReviewSkeleton()),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (reports) {
        if (reports.isEmpty) {
          return const EmptyStateWidget(variant: EmptyVariant.noReports);
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _ReportCard(report: reports[i]),
        );
      },
    );
  }
}

class _ReportCard extends StatefulWidget {
  final ReportModel report;
  const _ReportCard({required this.report});

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> {
  bool _expanded = false;

  Color _statusColor(String status) {
    switch (status) {
      case 'verified':
        return const Color(AppColors.highRisk);
      case 'resolved':
        return const Color(AppColors.trusted);
      case 'flagged_false':
        return const Color(AppColors.textGrey);
      default:
        return const Color(0xFFB5860D);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(AppColors.highRisk).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.warning_amber_rounded,
                      color: Color(AppColors.highRisk), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ReportTypes.label(report.incidentType),
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(
                        DateFormat('dd MMM yyyy')
                            .format(report.incidentDate),
                        style: const TextStyle(
                            fontSize: 11, color: Color(AppColors.textGrey)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        _statusColor(report.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    report.status.toUpperCase(),
                    style: TextStyle(
                      color: _statusColor(report.status),
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.currency_rupee,
                    size: 13, color: Color(AppColors.highRisk)),
                Text(
                  'NPR ${report.amountLost.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(AppColors.highRisk),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.apps, size: 13, color: Color(AppColors.textGrey)),
                const SizedBox(width: 4),
                Text(report.platform,
                    style: const TextStyle(
                        fontSize: 12, color: Color(AppColors.textGrey))),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded
                    ? report.description
                    : report.description.length > 80
                        ? '${report.description.substring(0, 80)}... (tap to expand)'
                        : report.description,
                style: const TextStyle(
                    fontSize: 13, color: Color(AppColors.textDark)),
              ),
            ),
            const SizedBox(height: 10),
            // Anonymity line — name/tag visible, personal details protected
            Row(
              children: [
                const Icon(Icons.verified_user_rounded,
                    size: 13, color: Color(AppColors.primary)),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    '${report.anonymizedReporter}  •  identity protected',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(AppColors.textGrey),
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            if (_expanded && report.sellerResponse != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(AppColors.primary).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(AppColors.primary)
                          .withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Seller Response:',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(report.sellerResponse!,
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
