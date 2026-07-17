import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/popup_helper.dart';
import '../../../../services/google_auth_service.dart';
import '../../kyc_draft.dart';

/// KYC Step 1 — link the Gmail account used on social platforms.
class KycGmailScreen extends StatefulWidget {
  const KycGmailScreen({super.key});

  @override
  State<KycGmailScreen> createState() => _KycGmailScreenState();
}

class _KycGmailScreenState extends State<KycGmailScreen> {
  String? get _gmail => KycDraft.instance.gmail;
  bool _linking = false;

  Future<void> _link() async {
    if (_gmail != null) {
      PopupHelper.showInfo(context, 'Gmail already linked: $_gmail');
      return;
    }
    setState(() => _linking = true);
    try {
      final email = await GoogleAuthService().linkGmailAccount();
      if (!mounted) return;
      if (email == null) {
        // user cancelled — no popup needed
      } else {
        setState(() => KycDraft.instance.gmail = email);
        PopupHelper.showSuccess(
            context, 'Gmail account linked successfully!');
      }
    } catch (_) {
      if (mounted) {
        PopupHelper.showError(
            context,
            'Could not link Gmail. Please try again or use a '
            'different account.');
      }
    } finally {
      if (mounted) setState(() => _linking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(title: const Text('KYC: Link Gmail')),
      body: Column(
        children: [
          const KycStepHeader(step: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              children: [
                // Illustration: gmail hub with platform arrows
                SizedBox(
                  height: 150,
                  child: CustomPaint(
                    painter: _GmailHubPainter(),
                    child: const SizedBox.expand(),
                  ),
                ),
                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Why do we need this?',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary900,
                          )),
                      const SizedBox(height: 6),
                      Text(
                        'TikTok, Instagram, and Facebook accounts are '
                        'registered with a Gmail address. Linking the same '
                        'Gmail proves you actually own the social accounts '
                        'you sell from. A clone account cannot do this.',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: AppColors.textPrimary,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                if (_gmail != null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.trustedBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color:
                              AppColors.trusted.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.trusted),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(_gmail!,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              )),
                        ),
                        TextButton(
                          onPressed: () => setState(
                              () => KycDraft.instance.gmail = null),
                          child: const Text('Change'),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _linking ? null : _link,
                      icon: _linking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2))
                          : const Icon(Icons.mail_outline_rounded),
                      label: const Text('Link Gmail Account'),
                    ),
                  ),
              ],
            ),
          ),
          KycBottomBar(
            enabled: _gmail != null,
            label: 'Next',
            onNext: () => Navigator.pushNamed(context, '/kyc/qr'),
            onDisabledTap: () => PopupHelper.showWarning(
                context, 'Please link your Gmail account to continue'),
          ),
        ],
      ),
    );
  }
}

/// Gmail hub illustration: platforms pointing at a Gmail envelope.
class _GmailHubPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);

    void platformDot(Offset pos, Color color, String label) {
      canvas.drawCircle(pos, 20, Paint()..color = color);
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
      // Arrow toward center
      final dir = (c - pos);
      final n = dir / dir.distance;
      final start = pos + n * 26;
      final end = c - n * 42;
      final arrow = Paint()
        ..color = AppColors.borderMedium
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(start, end, arrow);
      // Arrowhead
      final perp = Offset(-n.dy, n.dx);
      final head = Path()
        ..moveTo(end.dx, end.dy)
        ..lineTo(end.dx - n.dx * 7 + perp.dx * 4,
            end.dy - n.dy * 7 + perp.dy * 4)
        ..lineTo(end.dx - n.dx * 7 - perp.dx * 4,
            end.dy - n.dy * 7 - perp.dy * 4)
        ..close();
      canvas.drawPath(head, Paint()..color = AppColors.borderMedium);
    }

    platformDot(Offset(size.width * 0.14, size.height * 0.25),
        const Color(0xFF111111), 'TT');
    platformDot(Offset(size.width * 0.5, size.height * 0.12),
        const Color(0xFFC13584), 'IG');
    platformDot(Offset(size.width * 0.86, size.height * 0.25),
        const Color(0xFF1877F2), 'FB');

    // Gmail envelope
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c + const Offset(0, 18), width: 76, height: 54),
      const Radius.circular(8),
    );
    canvas.drawRRect(rect, Paint()..color = Colors.white);
    canvas.drawRRect(
      rect,
      Paint()
        ..color = const Color(0xFFEA4335)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    final flap = Path()
      ..moveTo(rect.left + 4, rect.top + 6)
      ..lineTo(c.dx, c.dy + 26)
      ..lineTo(rect.right - 4, rect.top + 6);
    canvas.drawPath(
      flap,
      Paint()
        ..color = const Color(0xFFEA4335)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
