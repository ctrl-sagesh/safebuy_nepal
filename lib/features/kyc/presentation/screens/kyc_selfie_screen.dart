import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/popup_helper.dart';
import '../../kyc_draft.dart';

/// KYC Step 3 — selfie holding the citizenship card, with an illustrated
/// do/don't guide drawn entirely in CustomPainter.
class KycSelfieScreen extends StatefulWidget {
  const KycSelfieScreen({super.key});

  @override
  State<KycSelfieScreen> createState() => _KycSelfieScreenState();
}

class _KycSelfieScreenState extends State<KycSelfieScreen> {
  final List<bool> _checks = List.filled(5, false);

  static const _checkLabels = [
    'My face is clearly visible',
    'Citizenship card is held next to my face',
    'Text on card is readable',
    'Photo is well lit and not blurry',
    'I am not wearing sunglasses or face covering',
  ];

  bool get _ready =>
      KycDraft.instance.selfieFile != null &&
      _checks.every((c) => c);

  Future<void> _capture(ImageSource source) async {
    final file = await pickKycImage(
      context,
      source: source,
      camera: CameraDevice.front,
    );
    if (file == null) return;
    setState(() => KycDraft.instance.selfieFile = file);
  }

  @override
  Widget build(BuildContext context) {
    final draft = KycDraft.instance;
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(title: const Text('KYC: Identity Selfie')),
      body: Column(
        children: [
          const KycStepHeader(step: 3),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              children: [
                // Guide illustration
                Container(
                  height: 190,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: CustomPaint(
                    painter: _SelfieGuidePainter(),
                    child: const SizedBox.expand(),
                  ),
                ),
                const SizedBox(height: 16),

                // Photo or capture buttons
                if (draft.selfieFile != null)
                  KycUploadZone(
                    label: '',
                    file: draft.selfieFile,
                    onPick: () {},
                    onRemove: () => setState(() {
                      draft.selfieFile = null;
                      for (var i = 0; i < _checks.length; i++) {
                        _checks[i] = false;
                      }
                    }),
                    height: 200,
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _capture(ImageSource.camera),
                            style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 50)),
                            icon: const Icon(Icons.camera_alt_rounded,
                                size: 18),
                            label: const Text('Take Selfie'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _capture(ImageSource.gallery),
                            style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 50)),
                            icon: const Icon(Icons.photo_library_outlined,
                                size: 18),
                            label: const Text('Upload Photo'),
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),

                // Confirm checklist
                Text('Confirm each requirement:',
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    )),
                const SizedBox(height: 8),
                ...List.generate(_checkLabels.length, (i) {
                  final checked = _checks[i];
                  return InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _checks[i] = !checked);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 11),
                      decoration: BoxDecoration(
                        color: checked
                            ? AppColors.trustedBg
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: checked
                              ? AppColors.trusted
                              : AppColors.borderLight,
                        ),
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 200),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: checked
                                  ? AppColors.trusted
                                  : Colors.white,
                              border: Border.all(
                                color: checked
                                    ? AppColors.trusted
                                    : AppColors.borderMedium,
                                width: 1.6,
                              ),
                            ),
                            child: checked
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 14)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(_checkLabels[i],
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                )),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '🔒 Your selfie is never shown publicly. It is only '
                    'used for identity verification by our admin team.',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: AppColors.primary900,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          KycBottomBar(
            enabled: _ready,
            label: 'Next',
            onNext: () => Navigator.pushNamed(context, '/kyc/pan'),
            onDisabledTap: () => PopupHelper.showWarning(
                context,
                'Please take a selfie and confirm all checklist items '
                'before continuing'),
          ),
        ],
      ),
    );
  }
}

/// Line-art selfie guide: correct pose on the left, common mistakes right.
class _SelfieGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = AppColors.textSecondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final good = Paint()
      ..color = AppColors.trusted
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    void text(String s, Offset pos, Color color,
        {double fs = 9, bool bold = false, bool center = false}) {
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
      tp.paint(canvas, center ? pos - Offset(tp.width / 2, 0) : pos);
    }

    // Divider
    canvas.drawLine(
      Offset(size.width / 2, 12),
      Offset(size.width / 2, size.height - 12),
      Paint()
        ..color = AppColors.borderLight
        ..strokeWidth = 1,
    );

    // ── Left: correct pose ────────────────────────────────────────────
    final lc = Offset(size.width * 0.20, size.height * 0.42);
    // Head
    canvas.drawCircle(lc, 17, good);
    // Body trapezoid
    final body = Path()
      ..moveTo(lc.dx - 14, lc.dy + 22)
      ..lineTo(lc.dx + 14, lc.dy + 22)
      ..lineTo(lc.dx + 22, lc.dy + 58)
      ..lineTo(lc.dx - 22, lc.dy + 58)
      ..close();
    canvas.drawPath(body, good);
    // Card held at face level
    final card = Rect.fromLTWH(lc.dx + 24, lc.dy - 12, 34, 22);
    canvas.drawRRect(
        RRect.fromRectAndRadius(card, const Radius.circular(3)), good);
    canvas.drawLine(Offset(card.left + 4, card.top + 7),
        Offset(card.right - 4, card.top + 7), good..strokeWidth = 1.2);
    canvas.drawLine(Offset(card.left + 4, card.top + 13),
        Offset(card.right - 10, card.top + 13), good);
    good.strokeWidth = 2;

    text('Your Face', Offset(lc.dx - 46, lc.dy - 34), AppColors.trusted,
        bold: true);
    text('Citizenship Card', Offset(card.left - 8, card.bottom + 6),
        AppColors.trusted,
        bold: true);
    text('✓ Both visible', Offset(size.width * 0.06, size.height * 0.82),
        AppColors.trusted,
        fs: 10, bold: true);
    text('✓ Good lighting',
        Offset(size.width * 0.26, size.height * 0.82), AppColors.trusted,
        fs: 10, bold: true);

    // ── Right: mistakes grid ──────────────────────────────────────────
    final rx = size.width * 0.55;
    void mistake(Offset origin, String label, void Function(Offset) draw) {
      draw(origin);
      text('❌ $label', origin + const Offset(-6, 34), AppColors.highRisk,
          fs: 8.5, bold: true);
    }

    mistake(Offset(rx + 22, 30), 'Too far', (o) {
      canvas.drawCircle(o, 7, line);
      canvas.drawRect(Rect.fromLTWH(o.dx + 22, o.dy + 6, 10, 7), line);
    });
    mistake(Offset(rx + 105, 30), 'Sunglasses', (o) {
      canvas.drawCircle(o, 11, line);
      canvas.drawRect(
          Rect.fromLTWH(o.dx - 9, o.dy - 4, 7, 5),
          Paint()..color = AppColors.textSecondary);
      canvas.drawRect(
          Rect.fromLTWH(o.dx + 2, o.dy - 4, 7, 5),
          Paint()..color = AppColors.textSecondary);
    });
    mistake(Offset(rx + 22, 105), 'Poor lighting', (o) {
      canvas.drawCircle(
          o, 11, Paint()..color = AppColors.grey400.withValues(alpha: 0.6));
    });
    mistake(Offset(rx + 105, 105), 'Card missing', (o) {
      canvas.drawCircle(o, 11, line);
      // No card — cross where it should be
      canvas.drawLine(Offset(o.dx + 18, o.dy - 6),
          Offset(o.dx + 30, o.dy + 6), line);
      canvas.drawLine(Offset(o.dx + 30, o.dy - 6),
          Offset(o.dx + 18, o.dy + 6), line);
    });

    text('CORRECT', Offset(size.width * 0.25, 6), AppColors.trusted,
        fs: 10, bold: true, center: true);
    text('AVOID', Offset(size.width * 0.75, 6), AppColors.highRisk,
        fs: 10, bold: true, center: true);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
