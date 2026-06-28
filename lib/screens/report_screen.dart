import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/report_model.dart';
import '../models/seller_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../core/widgets/loading_overlay.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../agents/core/agent_registry.dart';
import '../agents/evidence_reviewer/evidence_reviewer_agent.dart';
import '../agents/evidence_reviewer/extraction_rules.dart';

class ReportScreen extends ConsumerStatefulWidget {
  final SellerModel? prefilledSeller;

  const ReportScreen({super.key, this.prefilledSeller});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Step 1
  final _phoneCtrl = TextEditingController();
  final _esewaCtrl = TextEditingController();
  final _handleCtrl = TextEditingController();
  String _platform = Platforms.list.first;

  // Step 2
  double _amountLost = 0; // dragged via slider (NPR)
  String _incidentType = ReportTypes.list.first;
  final _descCtrl = TextEditingController();
  DateTime _incidentDate = DateTime.now();
  bool _declaration = false;

  // Step 3
  File? _paymentScreenshot;
  File? _chatScreenshot;
  bool _isSubmitting = false;
  String _loadingMessage = 'Submitting report...';

  // Evidence Review Agent
  EvidenceReviewResult? _evidenceReview;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    final s = widget.prefilledSeller;
    if (s != null) {
      _phoneCtrl.text = s.phone;
      _esewaCtrl.text = s.esewaId ?? '';
      _handleCtrl.text = s.tiktokHandle ?? s.instagramHandle ?? '';
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _esewaCtrl.dispose();
    _handleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isPayment) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (isPayment) {
          _paymentScreenshot = File(picked.path);
        } else {
          _chatScreenshot = File(picked.path);
        }
      });
      _runEvidenceReview();
    }
  }

  Future<void> _runEvidenceReview() async {
    if (_paymentScreenshot == null && _chatScreenshot == null) return;
    setState(() => _isAnalyzing = true);
    try {
      final reviewer = AgentRegistry().evidenceReviewer;
      final result = await reviewer.reviewEvidence(
        paymentScreenshot: _paymentScreenshot,
        chatScreenshot: _chatScreenshot,
      );
      if (mounted) setState(() => _evidenceReview = result);
    } catch (_) {
      // Silently fail — evidence review is non-blocking
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      if (_phoneCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter seller phone number'),
            backgroundColor: Color(AppColors.highRisk),
          ),
        );
        return false;
      }
    } else if (_currentStep == 1) {
      if (_amountLost <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please drag the slider to set the amount lost (must be > 0)'),
            backgroundColor: Color(AppColors.highRisk),
          ),
        );
        return false;
      }
      if (_descCtrl.text.trim().length < 50) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Description must be at least 50 characters'),
            backgroundColor: Color(AppColors.highRisk),
          ),
        );
        return false;
      }
      if (!_declaration) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please accept the declaration'),
            backgroundColor: Color(AppColors.highRisk),
          ),
        );
        return false;
      }
    }
    return true;
  }

  void _showVerificationDialog({
    required String title,
    required String message,
    required String actionLabel,
    VoidCallback? onAction,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.verified_user_outlined,
            color: Color(0xFF1565C0), size: 36),
        title: Text(title, textAlign: TextAlign.center),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onAction?.call();
            },
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final reporterId = currentUser?.uid ?? 'anonymous';
    final sellerId =
        widget.prefilledSeller?.sellerId ?? const Uuid().v4();

    // ── Identity verification gate ──────────────────────────────────────────
    // Only reporters whose national ID has been approved by an admin may file.
    if (currentUser == null) {
      _showVerificationDialog(
        title: 'Sign in required',
        message:
            'You must sign in and verify your identity before reporting a seller.',
        actionLabel: 'Sign In',
        onAction: () => Navigator.of(context).pushNamed('/auth'),
      );
      return;
    }
    final reporter =
        await ref.read(firestoreServiceProvider).getUserById(reporterId);
    if (!mounted) return;
    if (reporter == null || reporter.verificationStatus != 'approved') {
      final status = reporter?.verificationStatus ?? 'none';
      _showVerificationDialog(
        title: status == 'pending'
            ? 'Verification pending'
            : 'Identity verification required',
        message: status == 'pending'
            ? 'Your national ID is still being reviewed by our team. You can file reports once it is approved (usually within 24–48 hours).'
            : status == 'rejected'
                ? 'Your previous ID submission was not accepted. Please re-upload a valid national ID from your profile to report.'
                : 'To prevent fake reports, you must upload a national ID for one-time verification before filing a fraud report.',
        actionLabel: status == 'pending' ? 'OK' : 'Upload ID',
        onAction: status == 'pending'
            ? null
            : () => Navigator.of(context).pushNamed('/setup-profile'),
      );
      return;
    }

    // Rate limit check (reporter is guaranteed signed-in & verified by here)
    final allowed = await ref
        .read(firestoreServiceProvider)
        .checkReportRateLimit(reporterId, sellerId);
    if (!allowed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'You have already submitted 3 reports against this seller in the last 7 days.'),
          backgroundColor: Color(AppColors.highRisk),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _loadingMessage = 'Uploading evidence...';
    });

    String? paymentUrl;
    String? chatUrl;
    final reportId = 'RPT-${DateTime.now().year}-${const Uuid().v4().substring(0, 6).toUpperCase()}';

    try {
      // Upload images (gracefully skip if Storage is not enabled)
      if (_paymentScreenshot != null) {
        try {
          paymentUrl = await ref.read(storageServiceProvider).uploadEvidence(
                file: _paymentScreenshot!,
                reportId: reportId,
                evidenceType: 'payment',
                userId: reporterId,
              );
        } catch (_) {
          // Storage not enabled — skip upload, report still submits
          paymentUrl = null;
        }
      }
      if (_chatScreenshot != null) {
        try {
          chatUrl = await ref.read(storageServiceProvider).uploadEvidence(
                file: _chatScreenshot!,
                reportId: reportId,
                evidenceType: 'chat',
                userId: reporterId,
              );
        } catch (_) {
          chatUrl = null;
        }
      }

      if (mounted) {
        setState(() => _loadingMessage = 'Submitting report...');
      }

      // Create seller if not in DB
      if (widget.prefilledSeller == null) {
        final existing = await ref
            .read(firestoreServiceProvider)
            .searchSeller(_phoneCtrl.text.trim());
        if (existing == null) {
          final newSeller = SellerModel(
            sellerId: sellerId,
            name: 'Unknown Seller',
            phone: _phoneCtrl.text.trim(),
            esewaId: _esewaCtrl.text.trim().isEmpty
                ? null
                : _esewaCtrl.text.trim(),
            tiktokHandle: _platform == 'TikTok' &&
                    _handleCtrl.text.trim().isNotEmpty
                ? _handleCtrl.text.trim()
                : null,
            instagramHandle: _platform == 'Instagram' &&
                    _handleCtrl.text.trim().isNotEmpty
                ? _handleCtrl.text.trim()
                : null,
            trustScore: 50.0,
            trustVerdict: 'unverified',
            isVerified: false,
            verifiedBadge: false,
            totalOrders: 0,
            reviewCount: 0,
            scamReportCount: 0,
            accountCreatedAt: DateTime.now(),
            lastActiveAt: DateTime.now(),
            disputeResponseRate: 0.0,
            trustScoreHistory: const [],
            averageRating: 0.0,
          );
          await ref.read(firestoreServiceProvider).registerSeller(newSeller);
        }
      }

      final report = ReportModel(
        reportId: reportId,
        reporterId: reporterId,
        sellerId: sellerId,
        sellerPhone: _phoneCtrl.text.trim(),
        sellerEsewaId: _esewaCtrl.text.trim().isEmpty
            ? null
            : _esewaCtrl.text.trim(),
        sellerSocialHandle: _handleCtrl.text.trim().isEmpty
            ? null
            : _handleCtrl.text.trim(),
        platform: _platform,
        incidentType: _incidentType,
        amountLost: _amountLost,
        description: _descCtrl.text.trim(),
        incidentDate: _incidentDate,
        paymentScreenshotUrl: paymentUrl,
        chatScreenshotUrl: chatUrl,
        submittedAt: DateTime.now(),
        status: 'pending',
        reporterDeclaration: _declaration,
      );

      await ref.read(firestoreServiceProvider).submitReport(report);

      // Trigger Fraud Detector Agent in background (non-blocking)
      Future.microtask(() {
        AgentRegistry().fraudDetector.analyzeNewReport(
          sellerId: sellerId,
          amountLost: _amountLost,
          platform: _platform,
          incidentType: _incidentType,
        );
      });

      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSuccess(reportId);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'),
              backgroundColor: const Color(AppColors.highRisk)),
        );
      }
    }
  }

  void _showSuccess(String reportId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(AppColors.trusted).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: Color(AppColors.trusted), size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'Report Submitted!',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your report has been received. Our team will review it within 2-3 working days. Thank you for protecting the community.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: Color(AppColors.textGrey), fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(AppColors.primary).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  const Text('Your Report ID',
                      style: TextStyle(
                          fontSize: 11, color: Color(AppColors.textGrey))),
                  const SizedBox(height: 4),
                  Text(reportId,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Color(AppColors.primary))),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Fraud'),
        backgroundColor: const Color(AppColors.highRisk),
        foregroundColor: Colors.white,
      ),
      body: LoadingOverlay(
        isLoading: _isSubmitting,
        message: _loadingMessage,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildStepIndicator(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: [
                    _buildStep1(),
                    _buildStep2(),
                    _buildStep3(),
                  ][_currentStep],
                ),
              ),
              _buildBottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final labels = ['Seller Details', 'Incident Info', 'Evidence'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      color: const Color(AppColors.highRisk).withValues(alpha: 0.05),
      child: Row(
        children: List.generate(3, (i) {
          final isActive = i == _currentStep;
          final isDone = i < _currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDone
                              ? const Color(AppColors.trusted)
                              : isActive
                                  ? const Color(AppColors.highRisk)
                                  : Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isDone ? Icons.check : Icons.circle,
                          color: Colors.white,
                          size: isDone ? 18 : 10,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        labels[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.normal,
                          color: isActive
                              ? const Color(AppColors.highRisk)
                              : const Color(AppColors.textGrey),
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < 2)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 20),
                      color: isDone
                          ? const Color(AppColors.trusted)
                          : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Who scammed you?',
            'Enter any identifier you know about the seller'),
        const SizedBox(height: 20),
        _field(
          controller: _phoneCtrl,
          label: 'Phone Number *',
          hint: '98XXXXXXXX',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 14),
        _field(
          controller: _esewaCtrl,
          label: 'eSewa / Khalti ID',
          hint: 'Payment account ID',
          icon: Icons.account_balance_wallet,
        ),
        const SizedBox(height: 14),
        _field(
          controller: _handleCtrl,
          label: 'Social Media Handle',
          hint: '@username or profile link',
          icon: Icons.alternate_email,
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _platform,
          decoration: InputDecoration(
            labelText: 'Platform',
            prefixIcon: const Icon(Icons.apps),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: Platforms.list
              .map((p) => DropdownMenuItem(value: p, child: Text(p)))
              .toList(),
          onChanged: (v) => setState(() => _platform = v!),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('What happened?', 'Tell us about the incident'),
        const SizedBox(height: 20),
        // ── Amount lost — drag slider (0 → highest) ──
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          decoration: BoxDecoration(
            color: const Color(0xFFD32F2F).withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: const Color(0xFFD32F2F).withValues(alpha: 0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.currency_rupee,
                      size: 18, color: Color(0xFFD32F2F)),
                  const SizedBox(width: 6),
                  const Text('Amount Lost',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text(
                    _amountLost >= 100000
                        ? 'NPR 100,000+'
                        : 'NPR ${_amountLost.toInt()}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFD32F2F),
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFFD32F2F),
                  thumbColor: const Color(0xFFD32F2F),
                  overlayColor: const Color(0xFFD32F2F).withValues(alpha: 0.15),
                  inactiveTrackColor:
                      const Color(0xFFD32F2F).withValues(alpha: 0.15),
                ),
                child: Slider(
                  value: _amountLost,
                  min: 0,
                  max: 100000,
                  divisions: 200,
                  label: 'NPR ${_amountLost.toInt()}',
                  onChanged: (v) => setState(() => _amountLost = v),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('NPR 0',
                        style: TextStyle(
                            fontSize: 11, color: Color(0xFF6B7280))),
                    Text('Drag right to increase →',
                        style: TextStyle(
                            fontSize: 11, color: Color(0xFF6B7280))),
                    Text('100,000+',
                        style: TextStyle(
                            fontSize: 11, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _incidentType,
          decoration: InputDecoration(
            labelText: 'Incident Type *',
            prefixIcon: const Icon(Icons.category),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: ReportTypes.list
              .map((t) =>
                  DropdownMenuItem(value: t, child: Text(ReportTypes.label(t))))
              .toList(),
          onChanged: (v) => setState(() => _incidentType = v!),
        ),
        const SizedBox(height: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              maxLength: 1000,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Description *',
                hintText: 'Describe what happened in detail (min 50 chars)...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            Text(
              '${_descCtrl.text.length}/1000 chars (min 50)',
              style: TextStyle(
                fontSize: 11,
                color: _descCtrl.text.length >= 50
                    ? const Color(AppColors.trusted)
                    : const Color(AppColors.textGrey),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ListTile(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          tileColor: Colors.white,
          leading: const Icon(Icons.calendar_today,
              color: Color(AppColors.primary)),
          title: const Text('Date of Incident'),
          subtitle:
              Text(DateFormat('dd MMMM yyyy').format(_incidentDate)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _incidentDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) setState(() => _incidentDate = picked);
          },
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _declaration,
              onChanged: (v) => setState(() => _declaration = v ?? false),
              activeColor: const Color(AppColors.primary),
            ),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'I confirm this report is truthful and based on my genuine personal experience.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Evidence Upload',
            'Screenshots help verify your report faster'),
        const SizedBox(height: 20),
        _evidenceUploader(
          label: 'Payment Screenshot',
          file: _paymentScreenshot,
          onTap: () => _pickImage(true),
          onRemove: () => setState(() => _paymentScreenshot = null),
        ),
        const SizedBox(height: 14),
        _evidenceUploader(
          label: 'Chat Screenshot',
          file: _chatScreenshot,
          onTap: () => _pickImage(false),
          onRemove: () => setState(() => _chatScreenshot = null),
        ),
        if (_paymentScreenshot == null && _chatScreenshot == null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Adding screenshots significantly speeds up report verification.',
                    style:
                        TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
        ],

        // ── Evidence Reviewer Agent Feedback ─────────────────────
        if (_isAnalyzing) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(AppColors.primary).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(AppColors.primary).withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI Evidence Reviewer analyzing screenshots...',
                    style: TextStyle(
                        fontSize: 12, color: Color(AppColors.primary)),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_evidenceReview != null && !_isAnalyzing) ...[
          const SizedBox(height: 16),
          _buildEvidenceReviewCard(),
        ],

        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your report will be reviewed within 24-48 hours. Evidence is stored securely.',
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _evidenceUploader({
    required String label,
    required File? file,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    if (file != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(file,
                width: double.infinity, height: 160, fit: BoxFit.cover),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(AppColors.highRisk),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11)),
            ),
          ),
        ],
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
              color: const Color(AppColors.primary),
              width: 1.5,
              style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(14),
          color: const Color(AppColors.primary).withValues(alpha: 0.03),
        ),
        child: Column(
          children: [
            const Icon(Icons.add_photo_alternate,
                size: 36, color: Color(AppColors.primary)),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                  color: Color(AppColors.primary),
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tap to add screenshot',
              style: TextStyle(
                  fontSize: 12, color: Color(AppColors.textGrey)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvidenceReviewCard() {
    final review = _evidenceReview!;
    final qualityColor = switch (review.quality) {
      EvidenceQuality.strong => const Color(AppColors.trusted),
      EvidenceQuality.moderate => Colors.orange,
      EvidenceQuality.weak => const Color(AppColors.highRisk),
    };
    final qualityLabel = switch (review.quality) {
      EvidenceQuality.strong => 'Strong Evidence',
      EvidenceQuality.moderate => 'Moderate Evidence',
      EvidenceQuality.weak => 'Weak Evidence',
    };
    final qualityIcon = switch (review.quality) {
      EvidenceQuality.strong => Icons.verified,
      EvidenceQuality.moderate => Icons.info,
      EvidenceQuality.weak => Icons.warning_amber,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: qualityColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: qualityColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.smart_toy, color: qualityColor, size: 18),
              const SizedBox(width: 8),
              const Text(
                'AI Evidence Review',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: qualityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(qualityIcon, color: qualityColor, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      qualityLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: qualityColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.paymentFeedback.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.payment, size: 14, color: Color(AppColors.textGrey)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    review.paymentFeedback,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
          if (review.chatFeedback.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.chat, size: 14, color: Color(AppColors.textGrey)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    review.chatFeedback,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
          if (review.smartPrompts.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'Suggested details to include:',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(AppColors.textGrey)),
            ),
            const SizedBox(height: 6),
            ...review.smartPrompts.take(3).map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_right,
                          size: 14, color: Color(AppColors.primary)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          p.question,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(AppColors.primary)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back',
                    style: TextStyle(color: Color(AppColors.primary))),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _currentStep < 2
                ? ElevatedButton(
                    onPressed: () {
                      if (_validateCurrentStep()) {
                        setState(() => _currentStep++);
                      }
                    },
                    child: const Text('Continue'),
                  )
                : ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(AppColors.highRisk),
                      foregroundColor: Colors.white,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Submit Report'),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style:
                const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: const TextStyle(
                color: Color(AppColors.textGrey), fontSize: 13)),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
