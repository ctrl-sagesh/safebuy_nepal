import 'dart:io';

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
    with SingleTickerProviderStateMixin {
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

  late final AnimationController _checkAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
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
Filed via SafeBuy Nepal (safebuy-nepal.vercel.app)
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

  Future<void> _emailComplaint() async {
    if (!_validate()) return;
    HapticFeedback.mediumImpact();
    final uri = Uri(
      scheme: 'mailto',
      path: _bureauEmail,
      query: _encodeQuery({
        'subject':
            'Cybercrime Complaint - Social Commerce Fraud - SafeBuy Nepal Report $_reportRef',
        'body': _complaintText(),
      }),
    );
    try {
      final ok = await launchUrl(uri);
      if (!ok) throw Exception('no email app');
      if (!mounted) return;
      setState(() => _sent = true);
      _checkAnim.forward();
    } catch (_) {
      if (!mounted) return;
      PopupHelper.showError(context,
          'Could not open an email app. Use "Save as PDF" instead and email it manually.');
    }
  }

  static String _encodeQuery(Map<String, String> params) => params.entries
      .map((e) =>
          '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
      .join('&');

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
              onPressed: _emailComplaint,
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

  // ── Success view ─────────────────────────────────────────────────────────────

  Widget _successView() {
    final steps = [
      (
        '1',
        'Wait for acknowledgement',
        'The Bureau usually acknowledges complaints within 3 to 5 working days.'
      ),
      (
        '2',
        'You may be called to Naxal',
        'An officer may phone you or ask you to visit the Naxal office. '
            'Bureau phone: $_bureauPhone.'
      ),
      (
        '3',
        'Keep your originals safe',
        'Keep the original payment and chat screenshots on your phone. '
            'Investigators will ask for them.'
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              ScaleTransition(
                scale: CurvedAnimation(
                    parent: _checkAnim, curve: Curves.elasticOut),
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.trustGradient,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 56),
                ),
              ),
              const SizedBox(height: 20),
              Text('Complaint Sent to Nepal Police',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 19, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('Reference: $_reportRef',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  )),
              const SizedBox(height: 24),
              ...steps.map((s) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: _cardDeco,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 13,
                          backgroundColor: AppColors.primary50,
                          child: Text(s.$1,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              )),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.$2,
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 3),
                              Text(s.$3,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
