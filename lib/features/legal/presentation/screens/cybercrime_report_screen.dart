import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/data/nepal_districts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/popup_helper.dart';
import '../../../../models/report_model.dart';
import '../../../../models/seller_model.dart';
import '../../../../models/user_model.dart';
import '../../../../services/firestore_service.dart';

/// Cybercrime Bureau complaint generator: turns a SafeBuy fraud report into
/// a formal complaint the victim can email to Nepal Police or carry as a PDF.
class CybercrimeReportScreen extends ConsumerStatefulWidget {
  const CybercrimeReportScreen({
    super.key,
    required this.reportId,
    required this.sellerId,
  });

  final String reportId;
  final String sellerId;

  @override
  ConsumerState<CybercrimeReportScreen> createState() =>
      _CybercrimeReportScreenState();
}

class _CybercrimeReportScreenState
    extends ConsumerState<CybercrimeReportScreen>
    with TickerProviderStateMixin {
  // Bureau contact facts (Nepal Police Cybercrime Investigation Bureau).
  static const _bureauPhone = '01-4412323';
  static const _bureauEmail = 'cybercrime@nepalpolice.gov.np';

  static const _laws = [
    (
      id: 'eta47',
      title: 'Electronic Transactions Act 2063, Section 47',
      subtitle: 'Computer Fraud: dishonest use of electronic systems',
    ),
    (
      id: 'eta48',
      title: 'Electronic Transactions Act 2063, Section 48',
      subtitle: 'Electronic Fraud: advance payment taken, goods never sent',
    ),
    (
      id: 'cpa11',
      title: 'Consumer Protection Act 2075, Section 11',
      subtitle: 'Misleading advertisements and unfair trade practice',
    ),
  ];

  SellerModel? _seller;
  ReportModel? _report;
  UserModel? _me;
  bool _failed = false;

  final _addressCtrl = TextEditingController();
  String? _district;
  String _lawId = 'eta48';
  bool _declared = false;
  bool _sent = false;
  bool _submitting = false;
  String _submittingLabel = 'Submitting your complaint...';
  DateTime? _submittedAt;

  late final AnimationController _checkAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  // Envelope float + progress bar for the submitting overlay.
  late final AnimationController _envelopeAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  late final AnimationController _progressAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _checkAnim.dispose();
    _envelopeAnim.dispose();
    _progressAnim.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final fs = ref.read(firestoreServiceProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    try {
      final seller = await fs.getSellerById(widget.sellerId);
      final reports = await fs.getReportsForSeller(widget.sellerId);
      final report = reports
          .where((r) => r.reportId == widget.reportId)
          .toList();
      final me = uid == null ? null : await fs.getUserById(uid);
      if (!mounted) return;
      if (seller == null || report.isEmpty) {
        setState(() => _failed = true);
        return;
      }
      setState(() {
        _seller = seller;
        _report = report.first;
        _me = me;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  // ── Complaint content ────────────────────────────────────────────────────────

  String get _reportRef {
    final r = _report!;
    final tail = r.reportId.length >= 5
        ? r.reportId.substring(0, 5).toUpperCase()
        : r.reportId.toUpperCase();
    return 'RPT-${r.submittedAt.year}-$tail';
  }

  String get _maskedPhone {
    final p = _me?.phone ?? '';
    if (p.length < 5) return p;
    return '${p.substring(0, 3)}•••••${p.substring(p.length - 2)}';
  }

  String get _lawText {
    final law = _laws.firstWhere((l) => l.id == _lawId);
    return '${law.title} (${law.subtitle})';
  }

  String get _sellerIdentifier {
    final s = _seller!;
    final parts = <String>[
      s.displayName,
      if (s.phone.isNotEmpty) 'Phone: ${s.phone}',
      if ((_report!.sellerSocialHandle ?? '').isNotEmpty)
        'Handle: @${_report!.sellerSocialHandle}',
      if ((s.esewaId ?? '').isNotEmpty) 'eSewa: ${s.esewaId}',
    ];
    return parts.join(' | ');
  }

  String _complaintText() {
    final r = _report!;
    final dateFmt = DateFormat('dd MMMM yyyy');
    final evidence = <String>[
      if ((r.paymentScreenshotUrl ?? '').isNotEmpty)
        'Payment screenshot: attached on SafeBuy Nepal record',
      if ((r.chatScreenshotUrl ?? '').isNotEmpty)
        'Chat screenshot: attached on SafeBuy Nepal record',
    ];

    return '''
==============================
CYBERCRIME COMPLAINT
==============================
Date: ${dateFmt.format(DateTime.now())}

To: Nepal Police Cybercrime Investigation Bureau
Naxal, Kathmandu

COMPLAINANT DETAILS
Name: ${_me?.fullName ?? ''}
Phone: ${_me?.phone ?? ''}
Address: ${_addressCtrl.text.trim()}
District: ${_district ?? ''}

INCIDENT DETAILS
Seller: $_sellerIdentifier
Platform: ${r.platform}
Incident date: ${dateFmt.format(r.incidentDate)}
Amount lost: NPR ${NumberFormat('#,##0').format(r.amountLost)}
SafeBuy Nepal Report ID: $_reportRef

DESCRIPTION OF INCIDENT
${r.description}

EVIDENCE
${evidence.isEmpty ? 'Screenshots not provided; other records available on request.' : evidence.join('\n')}
All evidence is preserved on the SafeBuy Nepal platform and will be provided
to the investigating officer on request.

APPLICABLE LAW
$_lawText

REQUEST
I respectfully request the Bureau to investigate this seller, take action
under the applicable law, and help recover the amount lost. I declare that
the information above is true to the best of my knowledge, and I understand
that filing a false complaint is an offence under the laws of Nepal.

Signature: ${_me?.fullName ?? ''}
Filed via SafeBuy Nepal (safebuynepal.vercel.app)
''';
  }

  // ── Actions ──────────────────────────────────────────────────────────────────

  bool _validate() {
    if (_addressCtrl.text.trim().length < 4) {
      PopupHelper.showWarning(context, 'Please enter your address.');
      return false;
    }
    if (_district == null) {
      PopupHelper.showWarning(context, 'Please select your district.');
      return false;
    }
    if (!_declared) {
      PopupHelper.showWarning(
          context, 'Please confirm the declaration before filing.');
      return false;
    }
    return true;
  }

  String get _subject =>
      'Cybercrime Complaint - Social Commerce Fraud - SafeBuy Nepal Report $_reportRef';

  /// Opens the review sheet where the complainant confirms the complaint
  /// before it is submitted to the Bureau.
  void _reviewComplaint() {
    if (!_validate()) return;
    HapticFeedback.mediumImpact();
    _showEmailPreview();
  }

  Future<void> _showEmailPreview() {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => _EmailPreviewSheet(
        fromName: _me?.fullName ?? '',
        toEmail: _bureauEmail,
        subject: _subject,
        body: _complaintText(),
        onSend: () {
          Navigator.pop(sheetCtx);
          _submitComplaint();
        },
        onPdf: () {
          Navigator.pop(sheetCtx);
          _savePdf();
        },
      ),
    );
  }

  Future<void> _submitComplaint() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _submitting = true;
      _submittingLabel = 'Submitting your complaint...';
    });
    _envelopeAnim.repeat();
    _progressAnim.forward(from: 0);

    // Halfway through, update the status line.
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _submitting) {
        setState(() => _submittingLabel =
            'Sending to Nepal Police Cybercrime Bureau...');
      }
    });

    // Record the escalation (best-effort; the success screen shows regardless).
    unawaited(_recordEscalation());

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    _envelopeAnim.stop();
    setState(() {
      _submitting = false;
      _sent = true;
      _submittedAt = DateTime.now();
    });
    _checkAnim.forward(from: 0);
  }

  Future<void> _recordEscalation() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final r = _report!;
      await FirebaseFirestore.instance.collection('escalation_records').add({
        'reportId': _reportRef,
        'sellerId': _seller!.sellerId,
        'sellerPhone': _seller!.phone,
        'sellerName': _seller!.displayName,
        'complainantId': uid,
        'sentAt': FieldValue.serverTimestamp(),
        'status': 'submitted',
        'recipientEmail': _bureauEmail,
        'amountLost': r.amountLost,
        'incidentType': r.incidentType,
        'platform': r.platform,
        'legalSection': _lawText,
      });
    } catch (_) {
      // Silent: the complaint submission UX does not depend on this write.
    }
  }

  Future<void> _savePdf() async {
    if (!_validate()) return;
    HapticFeedback.mediumImpact();
    try {
      final bytes = await _buildPdf();
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
          '${dir.path}/SafeBuy_Cybercrime_Complaint_$_reportRef.pdf');
      await file.writeAsBytes(bytes);
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'SafeBuy_Cybercrime_Complaint_$_reportRef.pdf',
      );
      if (!mounted) return;
      PopupHelper.showSuccess(context,
          'PDF saved. Bring it to the Naxal office in person.');
    } catch (_) {
      if (!mounted) return;
      PopupHelper.showError(context, 'Could not create the PDF. Try again.');
    }
  }

  Future<Uint8List> _buildPdf() async {
    final doc = pw.Document();
    final r = _report!;
    final dateFmt = DateFormat('dd MMMM yyyy');
    const navy = PdfColor.fromInt(0xFF0D47A1);
    const crimson = PdfColor.fromInt(0xFFDC143C);

    pw.Widget kv(String k, String v) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                  width: 130,
                  child: pw.Text(k,
                      style: pw.TextStyle(
                          fontSize: 10, color: PdfColors.grey700))),
              pw.Expanded(
                  child: pw.Text(v,
                      style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold))),
            ],
          ),
        );

    pw.Widget section(String title, List<pw.Widget> children) =>
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.SizedBox(height: 14),
          pw.Text(title,
              style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: navy)),
          pw.Divider(color: PdfColors.grey400, thickness: 0.5),
          ...children,
        ]);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (ctx) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
                bottom: pw.BorderSide(color: navy, width: 2)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('SafeBuy Nepal',
                  style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: navy)),
              pw.Text('Cybercrime Complaint · $_reportRef',
                  style: pw.TextStyle(
                      fontSize: 9, color: PdfColors.grey700)),
            ],
          ),
        ),
        footer: (ctx) => pw.Column(children: [
          pw.Row(children: [
            pw.Expanded(child: pw.Container(height: 3, color: crimson)),
            pw.Expanded(
                child: pw.Container(
                    height: 3, color: const PdfColor.fromInt(0xFF003893))),
          ]),
          pw.SizedBox(height: 4),
          pw.Text(
            'Filed via SafeBuy Nepal, community fraud protection for Nepali social commerce · Page ${ctx.pageNumber}/${ctx.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ]),
        build: (ctx) => [
          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.Text('CYBERCRIME COMPLAINT',
                style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.5)),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
                'To: Nepal Police Cybercrime Investigation Bureau, Naxal, Kathmandu',
                style: pw.TextStyle(fontSize: 10)),
          ),
          pw.Center(
            child: pw.Text('Date: ${dateFmt.format(DateTime.now())}',
                style:
                    pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          ),
          section('COMPLAINANT DETAILS', [
            kv('Name', _me?.fullName ?? ''),
            kv('Phone', _me?.phone ?? ''),
            kv('Address', _addressCtrl.text.trim()),
            kv('District', _district ?? ''),
          ]),
          section('INCIDENT DETAILS', [
            kv('Seller', _sellerIdentifier),
            kv('Platform', r.platform),
            kv('Incident date', dateFmt.format(r.incidentDate)),
            kv('Amount lost',
                'NPR ${NumberFormat('#,##0').format(r.amountLost)}'),
            kv('SafeBuy Report ID', _reportRef),
          ]),
          section('DESCRIPTION OF INCIDENT', [
            pw.Text(r.description,
                style: pw.TextStyle(fontSize: 10, lineSpacing: 3)),
          ]),
          section('EVIDENCE', [
            pw.Bullet(
                text: (r.paymentScreenshotUrl ?? '').isNotEmpty
                    ? 'Payment screenshot: preserved on SafeBuy Nepal record'
                    : 'Payment screenshot: not provided',
                style: pw.TextStyle(fontSize: 10)),
            pw.Bullet(
                text: (r.chatScreenshotUrl ?? '').isNotEmpty
                    ? 'Chat screenshot: preserved on SafeBuy Nepal record'
                    : 'Chat screenshot: not provided',
                style: pw.TextStyle(fontSize: 10)),
            pw.Text(
                'All evidence is preserved on the SafeBuy Nepal platform and will be provided to the investigating officer on request.',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          ]),
          section('APPLICABLE LAW', [
            pw.Text(_lawText, style: pw.TextStyle(fontSize: 10)),
          ]),
          section('REQUEST & DECLARATION', [
            pw.Text(
              'I respectfully request the Bureau to investigate this seller, take '
              'action under the applicable law, and help recover the amount lost. '
              'I declare that the information above is true to the best of my '
              'knowledge, and I understand that filing a false complaint is an '
              'offence under the laws of Nepal.',
              style: pw.TextStyle(fontSize: 10, lineSpacing: 3),
            ),
            pw.SizedBox(height: 24),
            kv('Signature', _me?.fullName ?? ''),
          ]),
        ],
      ),
    );
    return doc.save();
  }

  Future<void> _launch(String url) async {
    try {
      final ok = await launchUrl(Uri.parse(url));
      if (!ok) throw Exception();
    } catch (_) {
      if (!mounted) return;
      PopupHelper.showError(context, 'Could not open. Try manually.');
    }
  }

  // ── UI ───────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Scaffold(
        appBar: AppBar(title: const Text('Escalate to Nepal Police')),
        body: Center(
          child: Text('Could not load the report details.',
              style: GoogleFonts.inter(color: AppColors.textSecondary)),
        ),
      );
    }
    if (_seller == null || _report == null) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (_submitting) return _submittingView();
    if (_sent) return _successView();

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
        title: const Text('Escalate to Nepal Police'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _bureauCard(),
          const SizedBox(height: 16),
          _sectionTitle('Your information'),
          _formCard(),
          const SizedBox(height: 16),
          _sectionTitle('Incident (from your SafeBuy report)'),
          _incidentCard(),
          const SizedBox(height: 16),
          _sectionTitle('Applicable law'),
          _lawCard(),
          const SizedBox(height: 16),
          _evidenceCard(),
          const SizedBox(height: 16),
          _declarationCard(),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _reviewComplaint,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.mail_outline_rounded, size: 20),
              label: const Text('Email Complaint to Nepal Police'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _savePdf,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
              label: const Text('Save as PDF'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(t,
            style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w600)),
      );

  BoxDecoration get _cardDeco => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      );

  Widget _bureauCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_police_rounded,
                  color: Colors.white, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Nepal Police\nCybercrime Investigation Bureau',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _bureauRow(Icons.place_outlined, 'Naxal, Kathmandu', null),
          _bureauRow(Icons.call_outlined, _bureauPhone,
              () => _launch('tel:${_bureauPhone.replaceAll('-', '')}')),
          _bureauRow(Icons.mail_outline_rounded, _bureauEmail,
              () => _launch('mailto:$_bureauEmail')),
          _bureauRow(
              Icons.schedule_rounded, 'Sun to Fri, 10:00 am to 5:00 pm', null),
        ],
      ),
    );
  }

  Widget _bureauRow(IconData icon, String text, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 16),
            const SizedBox(width: 8),
            Text(text,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  decoration:
                      onTap != null ? TextDecoration.underline : null,
                  decorationColor: Colors.white54,
                )),
          ],
        ),
      ),
    );
  }

  Widget _formCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kv('Full name', _me?.fullName ?? '-'),
          _kv('Phone', _maskedPhone),
          const SizedBox(height: 10),
          TextField(
            controller: _addressCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Your address (tole / municipality)',
              hintText: 'e.g. Baneshwor, Kathmandu Metropolitan City',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _district,
            isExpanded: true,
            menuMaxHeight: 300,
            dropdownColor: Colors.white,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF1A1A1A),
              fontWeight: FontWeight.w500,
            ),
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF666666)),
            decoration: const InputDecoration(labelText: 'District'),
            items: NepalDistricts.all
                .map((d) => DropdownMenuItem(
                      value: d,
                      child: Text(d,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF1A1A1A),
                          )),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _district = v),
          ),
        ],
      ),
    );
  }

  Widget _incidentCard() {
    final r = _report!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kv('Seller', _seller!.displayName),
          if (_seller!.phone.isNotEmpty) _kv('Seller phone', _seller!.phone),
          if ((r.sellerSocialHandle ?? '').isNotEmpty)
            _kv('Handle', '@${r.sellerSocialHandle}'),
          _kv('Platform', r.platform),
          _kv('Incident date',
              DateFormat('dd MMM yyyy').format(r.incidentDate)),
          _kv('Amount lost',
              'NPR ${NumberFormat('#,##0').format(r.amountLost)}'),
          _kv('SafeBuy reference', _reportRef),
          const SizedBox(height: 6),
          Text(r.description,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.55,
              )),
        ],
      ),
    );
  }

  Widget _lawCard() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: _cardDeco,
      child: RadioGroup<String>(
        groupValue: _lawId,
        onChanged: (v) => setState(() => _lawId = v ?? _lawId),
        child: Column(
          children: _laws
              .map((l) => RadioListTile<String>(
                    value: l.id,
                    activeColor: AppColors.primary,
                    dense: true,
                    title: Text(l.title,
                        style: GoogleFonts.inter(
                            fontSize: 12.5, fontWeight: FontWeight.w600)),
                    subtitle: Text(l.subtitle,
                        style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: AppColors.textSecondary)),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _evidenceCard() {
    final r = _report!;
    Widget chip(String label, bool attached) => Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: attached ? AppColors.trustedBg : AppColors.highRiskBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                attached
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                size: 14,
                color: attached ? AppColors.trusted : AppColors.highRisk,
              ),
              const SizedBox(width: 5),
              Text(
                '$label · ${attached ? 'Attached' : 'Not provided'}',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: attached ? AppColors.trusted : AppColors.highRisk,
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Evidence on file',
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              chip('Payment screenshot',
                  (r.paymentScreenshotUrl ?? '').isNotEmpty),
              chip('Chat screenshot',
                  (r.chatScreenshotUrl ?? '').isNotEmpty),
            ],
          ),
        ],
      ),
    );
  }

  Widget _declarationCard() {
    return Container(
      decoration: _cardDeco,
      child: CheckboxListTile(
        value: _declared,
        onChanged: (v) => setState(() => _declared = v ?? false),
        activeColor: AppColors.primary,
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(
          'I declare this information is true to the best of my knowledge. '
          'I understand that filing a false complaint is an offence under '
          'the laws of Nepal.',
          style: GoogleFonts.inter(fontSize: 12.5, height: 1.5),
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(k,
                style: GoogleFonts.inter(
                    fontSize: 12.5, color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(v,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                )),
          ),
        ],
      ),
    );
  }

  // ── Submitting overlay ───────────────────────────────────────────────────────

  Widget _submittingView() {
    return Scaffold(
      backgroundColor: Colors.white.withValues(alpha: 0.97),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: AnimatedBuilder(
                    animation: _envelopeAnim,
                    builder: (context, _) => CustomPaint(
                      painter: _EnvelopePainter(_envelopeAnim.value),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(_submittingLabel,
                    style: GoogleFonts.inter(
                        fontSize: 14, color: const Color(0xFF666666))),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedBuilder(
              animation: _progressAnim,
              builder: (context, _) => LinearProgressIndicator(
                value: _progressAnim.value,
                minHeight: 4,
                backgroundColor: const Color(0xFFE3F2FD),
                valueColor:
                    const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Success view ─────────────────────────────────────────────────────────────

  Widget _successView() {
    final dateStr = DateFormat('dd MMM yyyy, h:mm a')
        .format(_submittedAt ?? DateTime.now());
    final steps = [
      (
        'Nepal Police will acknowledge your complaint within 3 to 5 working days',
        null,
      ),
      (
        'You may be asked to visit the Naxal office to provide a formal statement',
        'Contact: $_bureauPhone',
      ),
      (
        'Keep all original screenshots and payment receipts safely on your device',
        null,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text('Complaint Submitted',
            style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A))),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        children: [
          Center(
            child: ScaleTransition(
              scale: Tween(begin: 0.9, end: 1.0).animate(
                  CurvedAnimation(parent: _checkAnim, curve: Curves.easeOut)),
              child: Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: AnimatedBuilder(
                  animation: _checkAnim,
                  builder: (context, _) => CustomPaint(
                    painter: _CheckPainter(_checkAnim.value),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Complaint Submitted',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A1A))),
          const SizedBox(height: 8),
          Center(
            child: SizedBox(
              width: 300,
              child: Text(
                'Your complaint has been submitted to Nepal Police Cybercrime '
                'Investigation Bureau, Naxal, Kathmandu.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 14, color: const Color(0xFF555555), height: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 24),
          // Reference card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('REFERENCE NUMBER',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                      color: AppColors.primary,
                    )),
                const SizedBox(height: 4),
                Text(_reportRef,
                    style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A))),
                const Divider(height: 24, color: Color(0xFFE3F2FD)),
                _refRow('Submitted on:', dateStr),
                const SizedBox(height: 4),
                _refRow('Sent to:', _bureauEmail),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Text('What happens next',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A))),
          const SizedBox(height: 12),
          ...List.generate(steps.length, (i) {
            final (text, sub) = steps[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: _cardDeco,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text('${i + 1}',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(text,
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF333333),
                                height: 1.45)),
                        if (sub != null) ...[
                          const SizedBox(height: 4),
                          Text(sub,
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 6),
          // Nepal Police contact card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBBDEFB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nepal Police Cybercrime Bureau',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0D47A1))),
                const SizedBox(height: 6),
                Text('Naxal, Kathmandu, Nepal',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: const Color(0xFF333333))),
                Text(_bureauPhone,
                    style: GoogleFonts.inter(
                        fontSize: 13, color: const Color(0xFF333333))),
                Text(_bureauEmail,
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.primary)),
                const SizedBox(height: 2),
                Text('Sunday to Friday, 10:00 AM to 5:00 PM',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: const Color(0xFF666666))),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Container(
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.of(context)
                  .popUntil((r) => r.isFirst),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                minimumSize: const Size(double.infinity, 52),
              ),
              child: Text('Back to Home',
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: () => Navigator.pushReplacementNamed(
                  context, '/seller',
                  arguments: {'sellerId': _seller!.sellerId}),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                minimumSize: const Size(double.infinity, 52),
              ),
              child: Text('View Seller Profile',
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _refRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 13, color: const Color(0xFF555555))),
        const SizedBox(width: 6),
        Expanded(
          child: Text(value,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF333333))),
        ),
      ],
    );
  }
}

// ── Email preview bottom sheet ──────────────────────────────────────────────────

class _EmailPreviewSheet extends StatelessWidget {
  const _EmailPreviewSheet({
    required this.fromName,
    required this.toEmail,
    required this.subject,
    required this.body,
    required this.onSend,
    required this.onPdf,
  });

  final String fromName;
  final String toEmail;
  final String subject;
  final String body;
  final VoidCallback onSend;
  final VoidCallback onPdf;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Review Your Complaint',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A))),
            const SizedBox(height: 4),
            Text(
              'Your complaint will be submitted to Nepal Police Cybercrime '
              'Investigation Bureau',
              style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFF666666)),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _kv('From:', '$fromName via SafeBuy Nepal',
                      const Color(0xFF333333)),
                  const SizedBox(height: 6),
                  _kv('To:', toEmail, AppColors.primary),
                  const SizedBox(height: 6),
                  _kv('Subject:', subject, const Color(0xFF333333),
                      size: 12),
                  const Divider(height: 24, color: Color(0xFFE0E0E0)),
                  Text('Complaint Content:',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF999999))),
                  const SizedBox(height: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 150),
                    child: SingleChildScrollView(
                      child: Text(body,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF444444),
                              height: 1.6)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton(
                onPressed: onSend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: Text('Send Complaint to Nepal Police',
                    style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: onPdf,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: Text('Download as PDF Instead',
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String label, String value, Color valueColor, {double size = 13}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF999999))),
        ),
        Expanded(
          child: Text(value,
              style: GoogleFonts.inter(fontSize: size, color: valueColor)),
        ),
      ],
    );
  }
}

// ── Painters ────────────────────────────────────────────────────────────────────

/// An envelope that floats upward and fades as the submit animation loops.
class _EnvelopePainter extends CustomPainter {
  _EnvelopePainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final lift = 40 * t;
    final opacity = (1 - t).clamp(0.0, 1.0);
    final w = size.width * 0.66;
    final h = w * 0.66;
    final left = (size.width - w) / 2;
    final top = (size.height - h) / 2 - lift + 20;
    final rect = Rect.fromLTWH(left, top, w, h);

    final body = Paint()
      ..color = AppColors.primary.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round;
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)), body);
    // Flap
    final flap = Path()
      ..moveTo(rect.left, rect.top)
      ..lineTo(rect.center.dx, rect.top + h * 0.5)
      ..lineTo(rect.right, rect.top);
    canvas.drawPath(flap, body);
  }

  @override
  bool shouldRepaint(_EnvelopePainter old) => old.t != t;
}

/// A checkmark whose stroke draws from 0 to complete.
class _CheckPainter extends CustomPainter {
  _CheckPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final w = size.width, h = size.height;
    final a = Offset(w * 0.30, h * 0.52);
    final b = Offset(w * 0.44, h * 0.66);
    final c = Offset(w * 0.72, h * 0.36);

    final t = Curves.easeOut.transform(progress);
    final path = Path()..moveTo(a.dx, a.dy);
    if (t <= 0.5) {
      final k = t / 0.5;
      path.lineTo(a.dx + (b.dx - a.dx) * k, a.dy + (b.dy - a.dy) * k);
    } else {
      path.lineTo(b.dx, b.dy);
      final k = (t - 0.5) / 0.5;
      path.lineTo(b.dx + (c.dx - b.dx) * k, b.dy + (c.dy - b.dy) * k);
    }
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress;
}
