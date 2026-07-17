import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/popup_helper.dart';
import '../../../../core/utils/validators.dart';
import '../../../../models/review_model.dart';
import '../../../../models/seller_model.dart';
import '../../../../services/firestore_service.dart';
import '../../../../services/storage_service.dart';
import '../../../kyc/kyc_draft.dart' show KycUploadZone, pickKycImage;

/// Write a review for a seller — rating, product info, photo, experience.
class WriteReviewScreen extends ConsumerStatefulWidget {
  const WriteReviewScreen({super.key, required this.sellerId});

  final String sellerId;

  @override
  ConsumerState<WriteReviewScreen> createState() =>
      _WriteReviewScreenState();
}

class _WriteReviewScreenState
    extends ConsumerState<WriteReviewScreen> {
  SellerModel? _seller;
  double _rating = 0;
  final _productName = TextEditingController();
  final _comment = TextEditingController();
  File? _productImage;
  int? _experience; // 0 bad, 1 okay, 2 good
  bool _submitting = false;

  static const _experiences = [
    ('😞', 'Bad'),
    ('😐', 'Okay'),
    ('😍', 'Great'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await ref
          .read(firestoreServiceProvider)
          .getSellerById(widget.sellerId);
      if (mounted) setState(() => _seller = s);
    } catch (_) {}
  }

  @override
  void dispose() {
    _productName.dispose();
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    HapticFeedback.mediumImpact();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      PopupHelper.showAuthGateBottomSheet(context);
      return;
    }
    if (_productName.text.trim().isEmpty) {
      PopupHelper.showWarning(
          context, 'Please enter what you purchased');
      return;
    }
    if (_rating < 1) {
      PopupHelper.showWarning(context, 'Please select a star rating');
      return;
    }
    if (_comment.text.trim().length < 30) {
      PopupHelper.showWarning(
          context, 'Please write at least 30 characters');
      return;
    }
    if (_experience == null) {
      PopupHelper.showWarning(
          context, 'Please select your experience rating');
      return;
    }

    setState(() => _submitting = true);
    PopupHelper.showLoadingDialog(context, 'Submitting your review...');

    try {
      final fs = ref.read(firestoreServiceProvider);

      // One review per seller.
      final existing =
          await fs.getReviewsForSeller(widget.sellerId);
      if (existing.any((r) => r.reviewerId == user.uid)) {
        if (!mounted) return;
        PopupHelper.hideLoadingDialog(context);
        PopupHelper.showError(
            context,
            'You have already reviewed this seller. You can only '
            'submit one review per seller.');
        setState(() => _submitting = false);
        return;
      }

      String productUrl = '';
      if (_productImage != null) {
        try {
          productUrl = await StorageService.uploadReviewImage(
            file: _productImage!,
            reviewId: 'review-${const Uuid().v4()}',
          );
        } catch (_) {
          // Photo failed but review can proceed — inform honestly.
          if (mounted) {
            PopupHelper.showWarning(context,
                'Product photo upload failed. Submitting review without it.');
          }
        }
      }

      final me = await fs.getUserById(user.uid);
      await fs.submitReview(ReviewModel(
        reviewId: '',
        sellerId: widget.sellerId,
        reviewerId: user.uid,
        reviewerDisplayName: me?.fullName ?? 'SafeBuy user',
        rating: _rating.round(),
        comment: Validators.sanitize(_comment.text),
        createdAt: DateTime.now(),
        isVerifiedPurchase: productUrl.isNotEmpty,
        authenticityWeight: 1.0,
        helpfulCount: 0,
        productImageUrl: productUrl,
        productName: _productName.text.trim(),
        productRating: _rating,
      ));

      if (!mounted) return;
      PopupHelper.hideLoadingDialog(context);
      HapticFeedback.heavyImpact();
      PopupHelper.showSuccess(context, 'Review submitted! Thank you.');
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      PopupHelper.hideLoadingDialog(context);
      PopupHelper.showError(
          context, 'Review submission failed. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(title: const Text('Write a Review')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        children: [
          // Seller mini card
          if (_seller != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary50,
                    child: Text(
                      _seller!.displayName.isNotEmpty
                          ? _seller!.displayName[0]
                          : '?',
                      style: GoogleFonts.poppins(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_seller!.displayName,
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 250.ms),

          TextField(
            controller: _productName,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'What did you purchase? *',
              prefixIcon: Icon(Icons.shopping_bag_outlined),
            ),
          ),
          const SizedBox(height: 18),

          Center(
            child: Column(
              children: [
                Text('Your rating *',
                    style: GoogleFonts.poppins(
                        fontSize: 13.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                RatingBar.builder(
                  initialRating: _rating,
                  minRating: 1,
                  itemCount: 5,
                  itemSize: 42,
                  glow: false,
                  unratedColor: AppColors.borderMedium,
                  itemBuilder: (_, _) => const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFF5B400)),
                  onRatingUpdate: (v) {
                    HapticFeedback.lightImpact();
                    setState(() => _rating = v);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              Text('Product photo',
                  style: GoogleFonts.poppins(
                      fontSize: 13.5, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              if (_productImage != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.trustedBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Verified Purchase ✓',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.trusted,
                      )),
                ),
            ],
          ),
          const SizedBox(height: 8),
          KycUploadZone(
            label:
                'Add a photo of the product you received (recommended)',
            icon: Icons.add_a_photo_outlined,
            file: _productImage,
            onPick: () async {
              final f = await pickKycImage(context,
                  source: ImageSource.gallery);
              if (f != null) setState(() => _productImage = f);
            },
            onRemove: () => setState(() => _productImage = null),
            height: 120,
          ),
          const SizedBox(height: 18),

          TextField(
            controller: _comment,
            maxLines: 4,
            maxLength: 600,
            decoration: InputDecoration(
              labelText: 'Your review (min 30 characters) *',
              alignLabelWithHint: true,
              counterText: '${_comment.text.trim().length}/30 minimum',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),

          Text('Overall experience *',
              style: GoogleFonts.poppins(
                  fontSize: 13.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: List.generate(3, (i) {
              final (emoji, label) = _experiences[i];
              final selected = _experience == i;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 10 : 0),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _experience = i);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary50
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.borderLight,
                          width: selected ? 1.8 : 1.1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(emoji,
                              style: const TextStyle(fontSize: 24)),
                          const SizedBox(height: 4),
                          Text(label,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                child: const Text('Submit Review'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
