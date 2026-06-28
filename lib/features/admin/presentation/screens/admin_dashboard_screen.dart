import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../services/firestore_service.dart';
import 'admin_reports_screen.dart';
import 'admin_sellers_screen.dart';
import 'admin_verifications_screen.dart';
import 'cyber_bureau_screen.dart';

// ── Provider ─────────────────────────────────────────────────────────────────
final adminStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) async => ref.read(firestoreServiceProvider).getAdminStats(),
);

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppColors.primary700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminStatsProvider),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.screenH),
          child: ShimmerWrapper(
            child: Column(
              children: [
                SizedBox(height: 100),
              ],
            ),
          ),
        ),
        error: (e, _) => ErrorStateWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(adminStatsProvider),
        ),
        data: (stats) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminStatsProvider),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenH),
            children: [
              _Greeting().animate().fadeIn(),
              const SizedBox(height: AppSpacing.lg),
              _StatGrid(stats: stats).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Moderation',
                style: AppTextStyles.titleMedium(),
              ),
              const SizedBox(height: AppSpacing.md),
              _NavTile(
                icon: Icons.report_problem_outlined,
                title: 'Manage Reports',
                subtitle: '${stats['pendingReports']} pending review',
                color: AppColors.warning,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AdminReportsScreen()),
                ),
              ).animate().fadeIn(delay: 150.ms).slideX(begin: 0.1, end: 0),
              const SizedBox(height: AppSpacing.sm),
              _NavTile(
                icon: Icons.storefront_outlined,
                title: 'Manage Sellers',
                subtitle: '${stats['totalSellers']} registered, '
                    '${stats['highRiskCount']} high-risk',
                color: AppColors.primary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AdminSellersScreen()),
                ),
              ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1, end: 0),
              const SizedBox(height: AppSpacing.sm),
              _NavTile(
                icon: Icons.badge_outlined,
                title: 'ID Verifications',
                subtitle: 'Review reporters\' national IDs',
                color: AppColors.trusted,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AdminVerificationsScreen()),
                ),
              ).animate().fadeIn(delay: 250.ms).slideX(begin: 0.1, end: 0),
              const SizedBox(height: AppSpacing.sm),
              _NavTile(
                icon: Icons.gavel_rounded,
                title: 'Cyber Bureau Escalation',
                subtitle: 'Auto-prepare निवेदन for flagged sellers',
                color: AppColors.highRisk,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CyberBureauScreen()),
                ),
              ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Greeting ──────────────────────────────────────────────────────────────────

class _Greeting extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white24,
            child: Icon(Icons.admin_panel_settings, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, Admin',
                  style: AppTextStyles.titleMedium().copyWith(
                    color: AppColors.textOnDark,
                  ),
                ),
                Text(
                  'Manage reports and seller verifications',
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColors.textOnDark70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat grid ─────────────────────────────────────────────────────────────────

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats});
  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Total Sellers', stats['totalSellers'].toString(), Icons.store,
          AppColors.primary),
      ('Reports This Month', stats['reportsThisMonth'].toString(),
          Icons.assignment_late, AppColors.warning),
      ('High Risk Sellers', stats['highRiskCount'].toString(),
          Icons.gpp_bad, AppColors.highRisk),
      ('Pending Reports', stats['pendingReports'].toString(),
          Icons.pending_actions, AppColors.info),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (_, i) => _StatCard(
        label: items[i].$1,
        value: items[i].$2,
        icon: items[i].$3,
        color: items[i].$4,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTextStyles.displayMedium().copyWith(color: color),
              ),
              Text(
                label,
                style: AppTextStyles.bodySmall().copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Nav tile ──────────────────────────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(icon, color: color, size: AppSpacing.iconMd),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.titleSmall()),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall().copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.grey400),
            ],
          ),
        ),
      ),
    );
  }
}
