import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/seller_trust_badge.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../models/seller_model.dart';
import '../../../../services/firestore_service.dart';

final adminSellersProvider =
    FutureProvider.autoDispose<List<SellerModel>>((ref) async {
  return ref.read(firestoreServiceProvider).getAllSellers();
});

class AdminSellersScreen extends ConsumerWidget {
  const AdminSellersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellersAsync = ref.watch(adminSellersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Sellers'),
        backgroundColor: AppColors.primary700,
      ),
      body: sellersAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.screenH),
          child: SkeletonList(count: 4, item: SellerCardSkeleton()),
        ),
        error: (e, _) => ErrorStateWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(adminSellersProvider),
        ),
        data: (sellers) {
          if (sellers.isEmpty) {
            return const EmptyStateWidget(variant: EmptyVariant.noResults);
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminSellersProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.screenH),
              itemCount: sellers.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, i) => _AdminSellerCard(seller: sellers[i]),
            ),
          );
        },
      ),
    );
  }
}

class _AdminSellerCard extends ConsumerWidget {
  const _AdminSellerCard({required this.seller});
  final SellerModel seller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary50,
                child: Text(
                  seller.displayName.isNotEmpty
                      ? seller.displayName[0].toUpperCase()
                      : '?',
                  style: AppTextStyles.titleMedium().copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(seller.displayName,
                        style: AppTextStyles.titleSmall()),
                    Text(
                      seller.phone,
                      style: AppTextStyles.bodySmall().copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              SellerTrustBadge(
                score: seller.trustScore,
                animate: false,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _stat('Orders', seller.totalOrders.toString()),
              _stat('Reviews', seller.reviewCount.toString()),
              _stat('Reports', seller.scamReportCount.toString()),
              _stat('Score', seller.trustScore.toStringAsFixed(0)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.verified, size: 16),
                  label: const Text('Verify'),
                  onPressed: seller.verifiedBadge
                      ? null
                      : () => _grantBadge(context, ref),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.tune, size: 16),
                  label: const Text('Score'),
                  onPressed: () => _overrideScore(context, ref),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: AppTextStyles.titleSmall()
                  .copyWith(color: AppColors.primary)),
          Text(label,
              style: AppTextStyles.labelSmall()
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Future<void> _grantBadge(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(firestoreServiceProvider).updateSeller(seller.sellerId, {
        'verifiedBadge': true,
        'isVerified': true,
      });
      await ref.read(firestoreServiceProvider).logAdminAction(
            'admin',
            'badge_granted',
            seller.sellerId,
            'Admin granted verified badge',
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verified badge granted')),
        );
        ref.invalidate(adminSellersProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  Future<void> _overrideScore(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController(text: seller.trustScore.toStringAsFixed(1));
    final reasonCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Manual Score Override'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'New score (0-100)'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: reasonCtrl,
              decoration:
                  const InputDecoration(labelText: 'Reason for override'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final newScore = double.tryParse(ctrl.text);
    if (newScore == null || newScore < 0 || newScore > 100) return;

    try {
      final verdict = newScore >= 80
          ? 'trusted'
          : newScore >= 50
              ? 'unverified'
              : 'high_risk';
      await ref.read(firestoreServiceProvider).updateSeller(seller.sellerId, {
        'trustScore': newScore,
        'trustVerdict': verdict,
      });
      await ref.read(firestoreServiceProvider).logAdminAction(
            'admin',
            'score_override',
            seller.sellerId,
            'Score → $newScore. ${reasonCtrl.text}',
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Score updated to $newScore')),
        );
        ref.invalidate(adminSellersProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }
}
