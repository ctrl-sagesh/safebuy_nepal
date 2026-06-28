import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Shared shimmer base — wraps any widget in shimmer effect.
class ShimmerWrapper extends StatelessWidget {
  const ShimmerWrapper({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      period: const Duration(milliseconds: 1200),
      child: child,
    );
  }
}

/// Rectangular shimmer placeholder.
class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    required this.width,
    required this.height,
    this.radius = AppSpacing.radiusMd,
  });
  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.shimmerBase,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Seller card skeleton — matches SellerCard widget dimensions.
class SellerCardSkeleton extends StatelessWidget {
  const SellerCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            // Avatar
            const _ShimmerBox(width: 52, height: 52, radius: AppSpacing.radiusFull),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _ShimmerBox(width: 140, height: 14),
                  const SizedBox(height: 6),
                  const _ShimmerBox(width: 100, height: 11),
                  const SizedBox(height: 8),
                  Row(
                    children: const [
                      _ShimmerBox(width: 72, height: 22, radius: AppSpacing.radiusFull),
                      SizedBox(width: 8),
                      _ShimmerBox(width: 80, height: 22, radius: AppSpacing.radiusFull),
                    ],
                  ),
                ],
              ),
            ),
            const _ShimmerBox(width: 48, height: 48, radius: AppSpacing.radiusSm),
          ],
        ),
      ),
    );
  }
}

/// Profile screen header skeleton.
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: Column(
        children: [
          // Header gradient box
          Container(
            height: 200,
            color: AppColors.shimmerBase,
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            child: Column(
              children: [
                const _ShimmerBox(width: double.infinity, height: 14),
                const SizedBox(height: 8),
                const _ShimmerBox(width: 200, height: 12),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: const [
                    Expanded(child: _ShimmerBox(width: null, height: 60)),
                    SizedBox(width: 8),
                    Expanded(child: _ShimmerBox(width: null, height: 60)),
                    SizedBox(width: 8),
                    Expanded(child: _ShimmerBox(width: null, height: 60)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Review card skeleton.
class ReviewSkeleton extends StatelessWidget {
  const ReviewSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                _ShimmerBox(width: 36, height: 36, radius: AppSpacing.radiusFull),
                SizedBox(width: AppSpacing.sm),
                _ShimmerBox(width: 110, height: 12),
                Spacer(),
                _ShimmerBox(width: 70, height: 12),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const _ShimmerBox(width: 80, height: 10),
            const SizedBox(height: AppSpacing.sm),
            const _ShimmerBox(width: double.infinity, height: 11),
            const SizedBox(height: 4),
            const _ShimmerBox(width: 200, height: 11),
          ],
        ),
      ),
    );
  }
}

/// List of N skeleton items.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 4, required this.item});
  final int count;
  final Widget item;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (_) => item),
    );
  }
}
