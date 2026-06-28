import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../models/report_model.dart';
import '../../../../services/firestore_service.dart';
import 'admin_dashboard_screen.dart' show adminStatsProvider;

// ── Providers ────────────────────────────────────────────────────────────────

final adminReportFilterProvider = StateProvider<String>((_) => 'pending');

final adminReportsProvider = FutureProvider.autoDispose
    .family<List<ReportModel>, String>((ref, filter) async {
  final svc = ref.read(firestoreServiceProvider);
  return svc.getAllReports(status: filter);
});

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(adminReportFilterProvider);
    final reportsAsync = ref.watch(adminReportsProvider(filter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Reports'),
        backgroundColor: AppColors.primary700,
      ),
      body: Column(
        children: [
          _FilterChips(),
          Expanded(
            child: reportsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.screenH),
                child: SkeletonList(count: 4, item: ReviewSkeleton()),
              ),
              error: (e, _) => ErrorStateWidget(
                message: e.toString(),
                onRetry: () => ref.invalidate(adminReportsProvider(filter)),
              ),
              data: (reports) {
                if (reports.isEmpty) {
                  return const EmptyStateWidget(
                    variant: EmptyVariant.noReports,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.screenH),
                  itemCount: reports.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, i) => _ReportCard(report: reports[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter chips ──────────────────────────────────────────────────────────────

class _FilterChips extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(adminReportFilterProvider);
    const filters = [
      ('all', 'All'),
      ('pending', 'Pending'),
      ('verified', 'Verified'),
      ('flagged_false', 'False'),
      ('resolved', 'Resolved'),
    ];

    return Container(
      height: 56,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (_, i) {
          final isSelected = filter == filters[i].$1;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ChoiceChip(
              label: Text(filters[i].$2),
              selected: isSelected,
              onSelected: (_) => ref
                  .read(adminReportFilterProvider.notifier)
                  .state = filters[i].$1,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Report card ───────────────────────────────────────────────────────────────

class _ReportCard extends ConsumerWidget {
  const _ReportCard({required this.report});
  final ReportModel report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      onTap: () => _showDetail(context, ref),
      child: Container(
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
                Expanded(
                  child: Text(
                    report.sellerPhone,
                    style: AppTextStyles.titleSmall(),
                  ),
                ),
                _StatusBadge(status: report.status),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              report.incidentType.replaceAll('_', ' ').toUpperCase(),
              style: AppTextStyles.labelSmall().copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.attach_money,
                    size: 14, color: AppColors.highRisk),
                Text(
                  report.amountLost.npr,
                  style: AppTextStyles.labelMedium().copyWith(
                    color: AppColors.highRisk,
                  ),
                ),
                const Spacer(),
                Icon(Icons.calendar_today,
                    size: 12, color: AppColors.grey500),
                const SizedBox(width: 4),
                Text(
                  report.incidentDate.timeAgo,
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ReportDetailSheet(report: report),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  Color get _color {
    switch (status) {
      case 'verified':
        return AppColors.trusted;
      case 'pending':
        return AppColors.warning;
      case 'flagged_false':
        return AppColors.grey500;
      case 'resolved':
        return AppColors.info;
      default:
        return AppColors.grey500;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTextStyles.labelSmall().copyWith(
          color: _color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Detail sheet ──────────────────────────────────────────────────────────────

class _ReportDetailSheet extends ConsumerStatefulWidget {
  const _ReportDetailSheet({required this.report});
  final ReportModel report;

  @override
  ConsumerState<_ReportDetailSheet> createState() =>
      _ReportDetailSheetState();
}

class _ReportDetailSheetState extends ConsumerState<_ReportDetailSheet> {
  bool _working = false;

  Future<void> _act(String newStatus) async {
    setState(() => _working = true);
    try {
      await ref.read(firestoreServiceProvider).updateReportStatus(
            widget.report.reportId,
            newStatus,
            'Reviewed by admin',
          );
      await ref.read(firestoreServiceProvider).logAdminAction(
            'admin',
            'report_$newStatus',
            widget.report.reportId,
            'Admin reviewed report',
          );
      if (mounted) {
        Navigator.pop(context);
        context.showSnackBar('Report marked as $newStatus');
        ref.invalidate(adminReportsProvider);
        ref.invalidate(adminStatsProvider);
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Action failed: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.report;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Report Details', style: AppTextStyles.titleLarge()),
            const SizedBox(height: AppSpacing.lg),
            _row('Seller phone', r.sellerPhone),
            _row('Platform', r.platform),
            _row('Incident type', r.incidentType.replaceAll('_', ' ')),
            _row('Amount lost', r.amountLost.npr),
            _row('Incident date', r.incidentDate.formatted),
            _row('Status', r.status),
            const SizedBox(height: AppSpacing.lg),
            Text('Description', style: AppTextStyles.titleSmall()),
            const SizedBox(height: AppSpacing.xs),
            Text(
              r.description,
              style: AppTextStyles.bodyMedium(),
            ),
            if (r.sellerResponse != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Text('Seller response', style: AppTextStyles.titleSmall()),
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.infoSurface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Text(r.sellerResponse!,
                    style: AppTextStyles.bodySmall()),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            if (r.status == 'pending') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.close),
                      label: const Text('Mark False'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.highRisk,
                        side: const BorderSide(color: AppColors.highRisk),
                      ),
                      onPressed: _working ? null : () => _act('flagged_false'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Verify'),
                      onPressed: _working ? null : () => _act('verified'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.bodySmall()
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.labelMedium(),
            ),
          ),
        ],
      ),
    );
  }
}

