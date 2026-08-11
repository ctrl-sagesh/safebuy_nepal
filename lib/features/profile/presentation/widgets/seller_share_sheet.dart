import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/popup_helper.dart';
import '../../../../models/seller_model.dart';

/// "Share My SafeBuy Profile" — lets a verified seller hand buyers a link,
/// a ready-made message, or a QR that opens their public verification page
/// (`/verify`) in any mobile browser, no app install needed.
Future<void> showSellerShareSheet(BuildContext context, SellerModel seller) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => _SellerShareSheet(seller: seller),
  );
}

class _SellerShareSheet extends StatelessWidget {
  const _SellerShareSheet({required this.seller});

  final SellerModel seller;

  static const _site = 'https://safebuy-nepal.vercel.app';

  String get _verifyUrl {
    if (seller.phone.isNotEmpty) return '$_site/verify?phone=${seller.phone}';
    if ((seller.tiktokHandle ?? '').isNotEmpty) {
      return '$_site/verify?handle=${seller.tiktokHandle}';
    }
    return '$_site/verify?phone=${seller.phone}';
  }

  String get _verdictLabel {
    switch (seller.trustVerdict) {
      case 'trusted':
        return 'TRUSTED';
      case 'high_risk':
        return 'HIGH RISK';
      default:
        return 'UNVERIFIED';
    }
  }

  String get _message =>
      'I am a verified seller on SafeBuy Nepal.\n'
      'Check my trust rating before ordering:\n'
      '$_verifyUrl\n\n'
      'SafeBuy Rating: ${seller.trustScore.round()}/100 ($_verdictLabel)';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderMedium,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Share Your Verification',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                )),
            const SizedBox(height: 2),
            Text('Let buyers verify you instantly',
                style: GoogleFonts.inter(
                    fontSize: 13, color: const Color(0xFF666666))),
            const SizedBox(height: 18),

            _card1(context),
            const SizedBox(height: 12),
            _card2(context),
            const SizedBox(height: 12),
            _card3(context),
          ],
        ),
      ),
    );
  }

  // ── Card 1: Share Link ───────────────────────────────────────────────────────

  Widget _card1(BuildContext context) {
    return _cardShell(
      icon: Icons.link_rounded,
      title: 'Share Link',
      subtitle: 'Share in your TikTok bio or WhatsApp',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Text(_verifyUrl,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.robotoMono(
                    fontSize: 12, color: const Color(0xFF1A1A1A))),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _smallBtn(Icons.copy_rounded, 'Copy', () async {
                  await Clipboard.setData(ClipboardData(text: _verifyUrl));
                  if (context.mounted) {
                    PopupHelper.showSuccess(context, 'Link copied to clipboard');
                  }
                }),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _smallBtn(Icons.share_rounded, 'Share', () {
                  SharePlus.instance.share(ShareParams(
                    text: _verifyUrl,
                    subject: 'Verify me on SafeBuy Nepal',
                  ));
                }, filled: true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Card 2: Share as Message ─────────────────────────────────────────────────

  Widget _card2(BuildContext context) {
    return _cardShell(
      icon: Icons.chat_bubble_outline_rounded,
      title: 'Share as Message',
      subtitle: 'A ready-to-send message with your rating',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Text(_message,
                style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: const Color(0xFF1A1A1A),
                    height: 1.5)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _smallBtn(Icons.copy_rounded, 'Copy', () async {
                  await Clipboard.setData(ClipboardData(text: _message));
                  if (context.mounted) {
                    PopupHelper.showSuccess(context, 'Message copied');
                  }
                }),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _smallBtn(Icons.send_rounded, 'WhatsApp', () async {
                  final uri = Uri.parse(
                      'whatsapp://send?text=${Uri.encodeComponent(_message)}');
                  try {
                    final ok = await launchUrl(uri);
                    if (!ok) throw Exception();
                  } catch (_) {
                    SharePlus.instance.share(ShareParams(text: _message));
                  }
                }, filled: true, fillColor: const Color(0xFF25D366)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Card 3: QR Code ──────────────────────────────────────────────────────────

  Widget _card3(BuildContext context) {
    return _cardShell(
      icon: Icons.qr_code_2_rounded,
      title: 'QR Code',
      subtitle: 'Add this QR to your product posts or packaging',
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: QrImageView(
              data: _verifyUrl,
              version: QrVersions.auto,
              size: 160,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF0D2137),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF0D2137),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _smallBtn(Icons.download_rounded, 'Download QR',
                () => _downloadQr(context),
                filled: true),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadQr(BuildContext context) async {
    try {
      const size = 640.0;
      final painter = QrPainter(
        data: _verifyUrl,
        version: QrVersions.auto,
        gapless: true,
        eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.square, color: Color(0xFF0D2137)),
        dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square, color: Color(0xFF0D2137)),
      );

      // Paint onto a white background so the QR scans on any surface.
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, size, size),
        Paint()..color = Colors.white,
      );
      painter.paint(canvas, const Size(size, size));
      final image =
          await recorder.endRecording().toImage(size.toInt(), size.toInt());
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw Exception('encode failed');

      final dir = await getApplicationDocumentsDirectory();
      final file = File(
          '${dir.path}/safebuy_verify_${seller.phone.isNotEmpty ? seller.phone : seller.sellerId}.png');
      await file.writeAsBytes(bytes.buffer.asUint8List());

      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        text: 'Scan to verify me on SafeBuy Nepal: $_verifyUrl',
      ));
    } catch (_) {
      if (context.mounted) {
        PopupHelper.showError(context, 'Could not create the QR image.');
      }
    }
  }

  // ── Shared card + button builders ────────────────────────────────────────────

  Widget _cardShell({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A1A),
                        )),
                    Text(subtitle,
                        style: GoogleFonts.inter(
                            fontSize: 11.5, color: const Color(0xFF666666))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _smallBtn(IconData icon, String label, VoidCallback onTap,
      {bool filled = false, Color fillColor = AppColors.primary}) {
    if (filled) {
      return SizedBox(
        height: 42,
        child: ElevatedButton.icon(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: fillColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 42),
          ),
          icon: Icon(icon, size: 16),
          label: Text(label,
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      );
    }
    return SizedBox(
      height: 42,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          minimumSize: const Size(0, 42),
        ),
        icon: Icon(icon, size: 16),
        label: Text(label,
            style:
                GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
