import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../models/seller_model.dart';
import '../../../../models/report_model.dart';
import '../../../../services/firestore_service.dart';
import '../../../../services/cyber_bureau_service.dart';

final _candidatesProvider =
    FutureProvider.autoDispose<List<SellerModel>>((ref) async {
  return ref.read(firestoreServiceProvider).getEscalationCandidates();
});

class CyberBureauScreen extends ConsumerWidget {
  const CyberBureauScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final candidates = ref.watch(_candidatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cyber Bureau Escalation'),
        backgroundColor: AppColors.primary700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(_candidatesProvider),
          ),
        ],
      ),
      body: candidates.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(_candidatesProvider),
        ),
        data: (sellers) {
          if (sellers.isEmpty) {
            return _empty();
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screenH),
            children: [
              _banner(),
              const SizedBox(height: AppSpacing.lg),
              ...sellers.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _CandidateCard(seller: s),
                  )),
            ],
          );
        },
      ),
    );
  }

  Widget _banner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.highRisk, Color(0xFFF44336)],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          const Icon(Icons.gavel_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Auto-Escalation Queue',
                    style: AppTextStyles.titleMedium()
                        .copyWith(color: Colors.white)),
                Text(
                  'Sellers crossing the fraud threshold. Generate the official निवेदन for the Cyber Bureau.',
                  style: AppTextStyles.bodySmall()
                      .copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, size: 64, color: AppColors.borderMedium),
          const SizedBox(height: 16),
          Text('No sellers need escalation',
              style: AppTextStyles.headlineSmall()
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('Flagged sellers will appear here automatically.',
              style: AppTextStyles.bodyMedium()),
        ],
      ),
    );
  }
}

class _CandidateCard extends ConsumerWidget {
  const _CandidateCard({required this.seller});
  final SellerModel seller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.highRisk.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.store_rounded,
                    color: AppColors.highRisk, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(seller.name, style: AppTextStyles.titleSmall()),
                    Text(
                      '+977 ${seller.phone}',
                      style: AppTextStyles.bodySmall(),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${seller.scamReportCount}',
                      style: AppTextStyles.titleLarge()
                          .copyWith(color: AppColors.highRisk)),
                  Text('reports', style: AppTextStyles.labelSmall()),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _prepare(context, ref),
              icon: const Icon(Icons.description_outlined, size: 18),
              label: const Text('Generate निवेदन Letter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 46),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _prepare(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final service = ref.read(firestoreServiceProvider);
    final reports = await service.getReportsForSeller(seller.sellerId);

    if (!CyberBureauService.shouldEscalate(seller, reports)) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
              '${seller.name} does not yet meet the escalation threshold '
              '(${CyberBureauService.escalationReason(seller, reports)}).'),
        ),
      );
      return;
    }

    final letter = CyberBureauService.generateNivedan(seller, reports);
    final valid = reports.where((r) => r.status != 'flagged_false').toList();
    final totalLoss =
        valid.fold<double>(0, (s, ReportModel r) => s + r.amountLost);

    await service.saveCyberBureauEscalation(
      sellerId: seller.sellerId,
      sellerName: seller.name,
      letter: letter,
      reportCount: valid.length,
      totalLoss: totalLoss,
    );

    navigator.push(MaterialPageRoute(
      builder: (_) => _LetterPreviewScreen(
        seller: seller,
        letter: letter,
        reason: CyberBureauService.escalationReason(seller, reports),
        evidence: CyberBureauService.collectEvidence(reports),
      ),
    ));
  }
}

// ── Letter preview + admin approval workflow ─────────────────────────────────

class _LetterPreviewScreen extends ConsumerStatefulWidget {
  const _LetterPreviewScreen({
    required this.seller,
    required this.letter,
    required this.reason,
    required this.evidence,
  });
  final SellerModel seller;
  final String letter;
  final String reason;
  final List<EvidenceItem> evidence;

  @override
  ConsumerState<_LetterPreviewScreen> createState() =>
      _LetterPreviewScreenState();
}

class _LetterPreviewScreenState extends ConsumerState<_LetterPreviewScreen> {
  // prepared → approved → submitted
  String _status = 'prepared';
  bool _busy = false;

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.letter));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Letter copied to clipboard')),
    );
  }

  Future<void> _approve() async {
    setState(() => _busy = true);
    await ref
        .read(firestoreServiceProvider)
        .approveEscalation(widget.seller.sellerId);
    if (!mounted) return;
    setState(() {
      _status = 'approved';
      _busy = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Letter approved. You can now share it.'),
        backgroundColor: AppColors.trusted,
      ),
    );
  }

  Future<void> _share() async {
    setState(() => _busy = true);
    Clipboard.setData(ClipboardData(text: widget.letter));
    await ref
        .read(firestoreServiceProvider)
        .markEscalationSubmitted(widget.seller.sellerId);
    if (!mounted) return;
    setState(() {
      _status = 'submitted';
      _busy = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Letter copied & marked submitted to the Cyber Bureau.'),
        backgroundColor: AppColors.trusted,
      ),
    );
  }

  Color get _statusColor => switch (_status) {
        'approved' => AppColors.primary,
        'submitted' => AppColors.trusted,
        _ => AppColors.unverified,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('निवेदन: Cyber Bureau'),
        backgroundColor: AppColors.primary700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Copy letter',
            icon: const Icon(Icons.copy_rounded),
            onPressed: _copy,
          ),
        ],
      ),
      body: Column(
        children: [
          // Status + reason banner
          Container(
            width: double.infinity,
            color: _statusColor.withValues(alpha: 0.1),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  _status == 'submitted'
                      ? Icons.check_circle
                      : _status == 'approved'
                          ? Icons.verified
                          : Icons.info_outline,
                  size: 16,
                  color: _statusColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Status: ${_status.toUpperCase()}  •  ${widget.reason}',
                    style: AppTextStyles.bodySmall()
                        .copyWith(color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                // Evidence gallery
                Row(
                  children: [
                    const Icon(Icons.attachment_rounded,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text('Attached evidence (${widget.evidence.length})',
                        style: AppTextStyles.titleSmall()),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (widget.evidence.isEmpty)
                  Text(
                    'No screenshots were attached to these reports.',
                    style: AppTextStyles.bodySmall(),
                  )
                else
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.evidence.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => _EvidenceThumb(item: widget.evidence[i]),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                // Letter
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: SelectableText(
                    widget.letter,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      height: 1.55,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildActionBar(),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: switch (_status) {
          // Step 1 — admin must approve before sharing
          'prepared' => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Admin approval is required before this letter can be shared.',
                  style: AppTextStyles.bodySmall(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : _approve,
                    icon: const Icon(Icons.verified_rounded, size: 18),
                    label: const Text('Approve for Submission'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          // Step 2 — approved, can share/submit
          'approved' => Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copy,
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copy'),
                    style:
                        OutlinedButton.styleFrom(minimumSize: const Size(0, 50)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : _share,
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Share / Submit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.trusted,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 50),
                    ),
                  ),
                ),
              ],
            ),
          // Submitted — done
          _ => Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.trusted.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: AppColors.trusted),
                  const SizedBox(width: 8),
                  Text('Submitted to Cyber Bureau',
                      style: AppTextStyles.titleSmall()
                          .copyWith(color: AppColors.trusted)),
                ],
              ),
            ),
        },
      ),
    );
  }
}

class _EvidenceThumb extends StatelessWidget {
  const _EvidenceThumb({required this.item});
  final EvidenceItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 84,
            height: 84,
            child: item.isLocalFile
                ? Image.file(File(item.url), fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _ph())
                : Image.network(item.url, fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _ph()),
          ),
        ),
        const SizedBox(height: 4),
        Text(item.label,
            style: AppTextStyles.labelSmall()),
      ],
    );
  }

  Widget _ph() => Container(
        width: 84,
        height: 84,
        color: AppColors.bgSurface,
        child: const Icon(Icons.image_not_supported_outlined,
            color: AppColors.textMuted),
      );
}
