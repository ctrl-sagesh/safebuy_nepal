import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/popup_helper.dart';
import '../../../../core/utils/validators.dart';
import '../../kyc_draft.dart';

/// KYC Step 4 — PAN card photo + number + name.
class KycPanScreen extends StatefulWidget {
  const KycPanScreen({super.key});

  @override
  State<KycPanScreen> createState() => _KycPanScreenState();
}

class _KycPanScreenState extends State<KycPanScreen> {
  final _pan = TextEditingController(text: KycDraft.instance.panNumber);
  final _name = TextEditingController(text: KycDraft.instance.panName);
  bool _whyExpanded = false;
  String? _panError;
  String? _nameError;

  @override
  void dispose() {
    _pan.dispose();
    _name.dispose();
    super.dispose();
  }

  void _next() {
    final draft = KycDraft.instance;
    final missing = <String>[];
    if (draft.panFile == null) missing.add('PAN card photo');
    final panErr = Validators.panNumber(_pan.text);
    final nameErr = _name.text.trim().length < 2
        ? 'Name must be at least 2 characters'
        : null;
    setState(() {
      _panError = panErr;
      _nameError = nameErr;
    });
    if (panErr != null) missing.add('9-digit PAN number');
    if (nameErr != null) missing.add('name on PAN');
    if (missing.isNotEmpty) {
      PopupHelper.showWarning(
          context, 'Missing: ${missing.join(', ')}');
      return;
    }
    draft.panNumber = _pan.text.trim();
    draft.panName = _name.text.trim();
    Navigator.pushNamed(context, '/kyc/location');
  }

  @override
  Widget build(BuildContext context) {
    final draft = KycDraft.instance;
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(title: const Text('KYC: PAN Card')),
      body: Column(
        children: [
          const KycStepHeader(step: 4),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              children: [
                // PAN card illustration
                Container(
                  height: 170,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: CustomPaint(
                    painter: _PanGuidePainter(),
                    child: const SizedBox.expand(),
                  ),
                ),
                const SizedBox(height: 14),

                // Why we need PAN
                InkWell(
                  onTap: () =>
                      setState(() => _whyExpanded = !_whyExpanded),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary50,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('Why we need your PAN',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary900,
                                  )),
                            ),
                            Icon(
                              _whyExpanded
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                        if (_whyExpanded) ...[
                          const SizedBox(height: 8),
                          Text(
                            'A PAN (Permanent Account Number) is issued by '
                            'Nepal\'s Inland Revenue Department and ties your '
                            'business to a real registered taxpayer. It is the '
                            'strongest legitimacy signal a seller can provide. '
                            'Your PAN number is masked publicly (XXXXX789) and '
                            'the card photo is never shown to buyers.',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: AppColors.textPrimary,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                KycUploadZone(
                  label: 'Tap to upload a clear photo of your PAN card',
                  icon: Icons.badge_outlined,
                  file: draft.panFile,
                  onPick: () async {
                    final f = await pickKycImage(context,
                        source: ImageSource.gallery);
                    if (f != null) {
                      setState(() => draft.panFile = f);
                    }
                  },
                  onRemove: () => setState(() => draft.panFile = null),
                  height: 150,
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _pan,
                  keyboardType: TextInputType.number,
                  maxLength: 9,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  decoration: InputDecoration(
                    labelText: 'PAN Number (9 digits) *',
                    counterText: '',
                    helperText:
                        'Enter the 9-digit PAN number from your card',
                    prefixIcon: const Icon(Icons.numbers_rounded),
                    errorText: _panError,
                  ),
                  onChanged: (v) {
                    if (_panError != null &&
                        Validators.panNumber(v) == null) {
                      setState(() => _panError = null);
                    }
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Name on PAN *',
                    helperText: 'Must match name on citizenship card',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    errorText: _nameError,
                  ),
                  onChanged: (v) {
                    if (_nameError != null && v.trim().length >= 2) {
                      setState(() => _nameError = null);
                    }
                  },
                ),
              ],
            ),
          ),
          KycBottomBar(
            enabled: true,
            label: 'Next',
            onNext: _next,
            onDisabledTap: () {},
          ),
        ],
      ),
    );
  }
}

/// PAN card line-art guide.
class _PanGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    void text(String s, Offset pos, Color color,
        {double fs = 9, bool bold = false}) {
      final tp = TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(
            color: color,
            fontSize: fs,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos);
    }

    // Card
    final card = Rect.fromLTWH(
        size.width * 0.14, 18, size.width * 0.5, 82);
    canvas.drawRRect(
      RRect.fromRectAndRadius(card, const Radius.circular(8)),
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // Gov building icon (triangle roof + pillars)
    final gx = card.left + 12;
    final gy = card.top + 10;
    final roof = Path()
      ..moveTo(gx, gy + 8)
      ..lineTo(gx + 9, gy)
      ..lineTo(gx + 18, gy + 8)
      ..close();
    canvas.drawPath(roof, Paint()..color = AppColors.primary);
    for (var i = 0; i < 3; i++) {
      canvas.drawRect(
        Rect.fromLTWH(gx + 2 + i * 6, gy + 10, 3, 9),
        Paint()..color = AppColors.primary,
      );
    }
    text('Inland Revenue Department', Offset(gx + 24, gy + 2),
        AppColors.textSecondary, fs: 8, bold: true);

    // PAN line
    text('PAN: XXXXXXXXX', Offset(card.left + 12, card.top + 34),
        AppColors.textPrimary, fs: 11, bold: true);
    // Name line
    text('Name: YOUR NAME', Offset(card.left + 12, card.top + 52),
        AppColors.textSecondary, fs: 9.5);
    // IRD logo circle
    canvas.drawCircle(
      Offset(card.right - 18, card.bottom - 18),
      10,
      Paint()
        ..color = AppColors.borderMedium
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Arrows + labels
    final arrow = Paint()
      ..color = AppColors.highRisk
      ..strokeWidth = 1.6;
    canvas.drawLine(Offset(card.right + 8, card.top + 38),
        Offset(card.right + 42, card.top + 30), arrow);
    text('PAN Number', Offset(card.right + 10, card.top + 16),
        AppColors.highRisk, fs: 9.5, bold: true);
    canvas.drawLine(Offset(card.right + 8, card.top + 56),
        Offset(card.right + 42, card.top + 62), arrow);
    text('Your Name', Offset(card.right + 14, card.top + 64),
        AppColors.highRisk, fs: 9.5, bold: true);

    // Mistakes row
    final y = size.height - 40;
    text('❌ Blurry', Offset(size.width * 0.08, y), AppColors.highRisk,
        fs: 9.5, bold: true);
    text('❌ Partially visible', Offset(size.width * 0.28, y),
        AppColors.highRisk, fs: 9.5, bold: true);
    text('❌ Photo of screen', Offset(size.width * 0.58, y),
        AppColors.highRisk, fs: 9.5, bold: true);
    text('✓ Flat & clear', Offset(size.width * 0.08, y + 16),
        AppColors.trusted, fs: 9.5, bold: true);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
