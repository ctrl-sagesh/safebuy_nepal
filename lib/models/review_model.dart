import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ReviewModel extends Equatable {
  final String reviewId;
  final String sellerId;
  final String reviewerId;
  final String reviewerDisplayName;
  final int rating; // 1-5
  final String comment;
  final DateTime createdAt;
  final bool isVerifiedPurchase;
  final double authenticityWeight; // 0.0 - 1.0
  final int helpfulCount;
  final String? evidenceUrl; // required proof backing the review
  final String productImageUrl; // photo of the product received
  final String productName; // what product was purchased
  final double productRating; // rating specifically for the product
  final bool isTopReview; // admin marked as featured

  const ReviewModel({
    required this.reviewId,
    required this.sellerId,
    required this.reviewerId,
    required this.reviewerDisplayName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.isVerifiedPurchase,
    required this.authenticityWeight,
    required this.helpfulCount,
    this.evidenceUrl,
    this.productImageUrl = '',
    this.productName = '',
    this.productRating = 0,
    this.isTopReview = false,
  });

  factory ReviewModel.fromMap(String id, Map<String, dynamic> data) {
    return ReviewModel(
      reviewId: id,
      sellerId: data['sellerId'] as String? ?? '',
      reviewerId: data['reviewerId'] as String? ?? '',
      reviewerDisplayName: data['reviewerDisplayName'] as String? ??
          data['reviewerName'] as String? ??
          'Anonymous',
      rating: (data['rating'] as num?)?.toInt() ?? 0,
      comment: data['comment'] as String? ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isVerifiedPurchase: data['isVerifiedPurchase'] as bool? ?? false,
      authenticityWeight:
          (data['authenticityWeight'] as num?)?.toDouble() ?? 1.0,
      helpfulCount: (data['helpfulCount'] as num?)?.toInt() ?? 0,
      evidenceUrl: data['evidenceUrl'] as String?,
      productImageUrl: data['productImageUrl'] as String? ?? '',
      productName: data['productName'] as String? ?? '',
      productRating: (data['productRating'] as num?)?.toDouble() ?? 0,
      isTopReview: data['isTopReview'] as bool? ?? false,
    );
  }

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    return ReviewModel.fromMap(
        doc.id, doc.data() as Map<String, dynamic>? ?? {});
  }

  Map<String, dynamic> toMap() => {
        'sellerId': sellerId,
        'reviewerId': reviewerId,
        'reviewerDisplayName': reviewerDisplayName,
        'reviewerName': reviewerDisplayName, // backward compat
        'rating': rating,
        'comment': comment,
        'createdAt': Timestamp.fromDate(createdAt),
        'isVerifiedPurchase': isVerifiedPurchase,
        'authenticityWeight': authenticityWeight,
        'helpfulCount': helpfulCount,
        'evidenceUrl': evidenceUrl,
        'productImageUrl': productImageUrl,
        'productName': productName,
        'productRating': productRating,
        'isTopReview': isTopReview,
      };

  ReviewModel copyWith({
    String? reviewId,
    String? sellerId,
    String? reviewerId,
    String? reviewerDisplayName,
    int? rating,
    String? comment,
    DateTime? createdAt,
    bool? isVerifiedPurchase,
    double? authenticityWeight,
    int? helpfulCount,
    String? evidenceUrl,
    String? productImageUrl,
    String? productName,
    double? productRating,
    bool? isTopReview,
  }) {
    return ReviewModel(
      reviewId: reviewId ?? this.reviewId,
      sellerId: sellerId ?? this.sellerId,
      reviewerId: reviewerId ?? this.reviewerId,
      reviewerDisplayName: reviewerDisplayName ?? this.reviewerDisplayName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      isVerifiedPurchase: isVerifiedPurchase ?? this.isVerifiedPurchase,
      authenticityWeight: authenticityWeight ?? this.authenticityWeight,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      evidenceUrl: evidenceUrl ?? this.evidenceUrl,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      productName: productName ?? this.productName,
      productRating: productRating ?? this.productRating,
      isTopReview: isTopReview ?? this.isTopReview,
    );
  }

  @override
  List<Object?> get props => [
        reviewId,
        sellerId,
        reviewerId,
        reviewerDisplayName,
        rating,
        comment,
        createdAt,
        isVerifiedPurchase,
        authenticityWeight,
        helpfulCount,
        evidenceUrl,
        productImageUrl,
        productName,
        productRating,
        isTopReview,
      ];
}
