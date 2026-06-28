import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../models/user_model.dart';
import '../../../../services/firestore_service.dart';

/// Live stream of users awaiting national-ID verification.
final pendingVerificationsProvider =
    StreamProvider.autoDispose<List<UserModel>>((ref) {
  return ref.read(firestoreServiceProvider).watchPendingVerifications();
});

class AdminVerificationsScreen extends ConsumerWidget {
  const AdminVerificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingVerificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ID Verifications'),
        backgroundColor: AppColors.primary700,
        foregroundColor: Colors.white,
      ),
      body: pending.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(pendingVerificationsProvider),
        ),
        data: (users) {
          if (users.isEmpty) {
            return _buildEmpty();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.screenH),
            itemCount: users.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, i) => _VerificationCard(user: users[i], ref: ref),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_outlined,
              size: 64, color: AppColors.borderMedium),
          const SizedBox(height: 16),
          Text('No pending verifications',
              style: AppTextStyles.headlineSmall()
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('All submitted IDs have been reviewed.',
              style: AppTextStyles.bodyMedium()),
        ],
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({required this.user, required this.ref});
  final UserModel user;
  final WidgetRef ref;

  Future<void> _decide(BuildContext context, String status) async {
    HapticFeedback.mediumImpact();
    await ref
        .read(firestoreServiceProvider)
        .setVerificationStatus(user.userId, status);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == 'approved'
              ? '${user.fullName} approved as a verified reporter'
              : '${user.fullName}\'s verification rejected'),
          backgroundColor:
              status == 'approved' ? AppColors.trusted : AppColors.highRisk,
        ),
      );
    }
  }

  bool get _isLocalFile =>
      user.nationalIdUrl != null && !user.nationalIdUrl!.startsWith('http');

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ID document preview
          if (user.nationalIdUrl != null)
            SizedBox(
              height: 180,
              width: double.infinity,
              child: _isLocalFile
                  ? Image.file(File(user.nationalIdUrl!), fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _idPlaceholder())
                  : Image.network(user.nationalIdUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _idPlaceholder()),
            )
          else
            _idPlaceholder(),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        user.fullName.isNotEmpty
                            ? user.fullName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.fullName,
                              style: AppTextStyles.titleSmall()),
                          Text('${user.role} • ID submitted',
                              style: AppTextStyles.bodySmall()),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _infoRow(Icons.phone_outlined, '+977 ${user.phone}'),
                if (user.email != null && user.email!.isNotEmpty)
                  _infoRow(Icons.email_outlined, user.email!),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _decide(context, 'rejected'),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.highRisk,
                          side: const BorderSide(color: AppColors.highRisk),
                          minimumSize: const Size(0, 46),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _decide(context, 'approved'),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.trusted,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 46),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Text(text, style: AppTextStyles.bodyMedium()),
        ],
      ),
    );
  }

  Widget _idPlaceholder() {
    return Container(
      height: 180,
      width: double.infinity,
      color: AppColors.bgSurface,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.badge_outlined, size: 36, color: AppColors.textMuted),
            SizedBox(height: 6),
            Text('ID document', style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
