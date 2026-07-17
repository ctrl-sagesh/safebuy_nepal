import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/popup_helper.dart';
import '../../../../models/kyc_submission_model.dart';
import '../../../../services/firestore_service.dart';
import '../../../../services/kyc_service.dart';
import '../../kyc_draft.dart';

/// KYC Step 5 — three business/home location photos with GPS capture,
/// then final submission.
class KycLocationScreen extends ConsumerStatefulWidget {
  const KycLocationScreen({super.key});

  @override
  ConsumerState<KycLocationScreen> createState() =>
      _KycLocationScreenState();
}

class _KycLocationScreenState
    extends ConsumerState<KycLocationScreen> {
  bool _submitting = false;

  static const _zoneLabels = [
    'Wide shot of room with products',
    'Close-up of your products',
    'Entrance or address indicator',
  ];

  Future<void> _captureZone(int index) async {
    final file =
        await pickKycImage(context, source: ImageSource.camera);
    if (file == null) return;
    setState(() => KycDraft.instance.locationFiles[index] = file);

    // Capture GPS alongside the photo.
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          PopupHelper.showWarning(
              context,
              'GPS not captured. Please enable location permission '
              'for better verification.');
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      KycDraft.instance
        ..locationLat = pos.latitude
        ..locationLng = pos.longitude;
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        PopupHelper.showWarning(
            context,
            'GPS not captured. Please enable location permission '
            'for better verification.');
      }
    }
  }

  Future<void> _submit() async {
    final draft = KycDraft.instance;
    if (draft.locationFiles.any((f) => f == null)) {
      PopupHelper.showWarning(
          context, 'Please upload all 3 location photos');
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      PopupHelper.showError(
          context, 'Session expired. Please sign in again.');
      return;
    }

    setState(() => _submitting = true);
    PopupHelper.showLoadingDialog(context, 'Submitting your documents...');

    try {
      final kyc = KycService();
      final fs = ref.read(firestoreServiceProvider);
      final me = await fs.getUserById(user.uid);
      final sellerId = me?.linkedSellerId ?? '';

      // Upload all documents.
      final selfieUrl = draft.selfieFile != null
          ? await kyc.uploadKycDocument(
              userId: user.uid, kind: 'selfie', file: draft.selfieFile!)
          : '';
      final panUrl = draft.panFile != null
          ? await kyc.uploadKycDocument(
              userId: user.uid, kind: 'pan', file: draft.panFile!)
          : '';
      final qrUrl = draft.qrFile != null
          ? await kyc.uploadQrCode(userId: user.uid, file: draft.qrFile!)
          : '';
      final locationUrls = <String>[];
      for (var i = 0; i < 3; i++) {
        locationUrls.add(await kyc.uploadKycDocument(
          userId: user.uid,
          kind: 'location${i + 1}',
          file: draft.locationFiles[i]!,
        ));
      }

      await kyc.submitKyc(KycSubmissionModel(
        submissionId: '',
        sellerId: sellerId,
        submittedBy: user.uid,
        submittedAt: DateTime.now(),
        selfieUrl: selfieUrl,
        citizenshipUrl: selfieUrl, // selfie includes citizenship card
        panCardUrl: panUrl,
        locationPhotoUrls: locationUrls,
        locationLat: draft.locationLat ?? 0,
        locationLng: draft.locationLng ?? 0,
        panNumberSubmitted: draft.panNumber,
        citizenshipNumberSubmitted: draft.citizenshipNumber,
        gmailAccountSubmitted: draft.gmail ?? '',
        qrCodeUrlSubmitted: qrUrl,
      ));

      if (!mounted) return;
      PopupHelper.hideLoadingDialog(context);
      Navigator.pushNamedAndRemoveUntil(
          context, '/kyc/submitted', (r) => r.isFirst);
    } catch (_) {
      if (!mounted) return;
      PopupHelper.hideLoadingDialog(context);
      PopupHelper.showError(
          context,
          'Submission failed. Your photos are saved. Please try '
          'submitting again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = KycDraft.instance;
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(title: const Text('KYC: Location Photos')),
      body: Column(
        children: [
          const KycStepHeader(step: 5),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.home_work_outlined,
                          color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Home-based businesses are accepted. Your photos '
                          'prove you have real products at a real location.',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: AppColors.primary900,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Room illustration
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: CustomPaint(
                    painter: _RoomGuidePainter(),
                    child: const SizedBox.expand(),
                  ),
                ),
                const SizedBox(height: 16),

                ...List.generate(3, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Photo ${i + 1}: ${_zoneLabels[i]}',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            )),
                        const SizedBox(height: 6),
                        KycUploadZone(
                          label: '📷 Tap to capture with camera',
                          icon: Icons.camera_alt_outlined,
                          file: draft.locationFiles[i],
                          onPick: () => _captureZone(i),
                          onRemove: () => setState(
                              () => draft.locationFiles[i] = null),
                          height: 110,
                        ),
                      ],
                    ),
                  );
                }),

                if (draft.locationLat != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.trustedBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '📍 GPS Captured: '
                      '${draft.locationLat!.toStringAsFixed(5)}, '
                      '${draft.locationLng!.toStringAsFixed(5)}',
                      style: GoogleFonts.robotoMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.trusted,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '🔒 Location photos and GPS are only visible to the '
                    'admin team. Buyers only ever see your district name.',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          KycBottomBar(
            enabled: !_submitting,
            label: 'Submit for Review',
            onNext: _submit,
            onDisabledTap: () {},
          ),
        ],
      ),
    );
  }
}

/// Room perspective illustration for location photos.
class _RoomGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = AppColors.textSecondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    void text(String s, Offset pos, Color color,
        {double fs = 8.5, bool bold = true}) {
      final tp = TextPainter(
        text: TextSpan(
            text: s,
            style: TextStyle(
                color: color,
                fontSize: fs,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos);
    }

    // Back wall + floor
    final wall = Rect.fromLTWH(size.width * 0.12, 20, size.width * 0.76, 60);
    canvas.drawRect(wall, line);
    final floor = Path()
      ..moveTo(wall.left, wall.bottom)
      ..lineTo(wall.left - 22, size.height - 18)
      ..lineTo(wall.right + 22, size.height - 18)
      ..lineTo(wall.right, wall.bottom)
      ..close();
    canvas.drawPath(floor, line);

    // Product boxes in corner
    final boxPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawRect(
        Rect.fromLTWH(wall.left + 8, wall.bottom - 22, 22, 22), boxPaint);
    canvas.drawRect(
        Rect.fromLTWH(wall.left + 32, wall.bottom - 16, 16, 16), boxPaint);
    canvas.drawRect(
        Rect.fromLTWH(wall.left + 14, wall.bottom - 40, 18, 18), boxPaint);
    text('Your products', Offset(wall.left, wall.bottom + 8),
        AppColors.primary);

    // Person with phone
    final px = size.width * 0.68;
    final py = size.height * 0.55;
    canvas.drawCircle(Offset(px, py), 8, line); // head
    canvas.drawLine(Offset(px, py + 8), Offset(px, py + 30), line); // body
    canvas.drawLine(
        Offset(px, py + 14), Offset(px + 14, py + 6), line); // arm w/ phone
    canvas.drawRect(
        Rect.fromLTWH(px + 13, py + 1, 7, 11),
        Paint()..color = AppColors.textSecondary);

    // GPS pin above head
    final pin = Offset(px, py - 24);
    canvas.drawCircle(pin, 6,
        Paint()..color = AppColors.highRisk);
    final tail = Path()
      ..moveTo(pin.dx - 4, pin.dy + 4)
      ..lineTo(pin.dx, pin.dy + 13)
      ..lineTo(pin.dx + 4, pin.dy + 4)
      ..close();
    canvas.drawPath(tail, Paint()..color = AppColors.highRisk);
    text('GPS captured', Offset(px + 12, py - 30), AppColors.highRisk);

    // Photo zone circles
    void zone(Offset pos, String n) {
      canvas.drawCircle(
          pos,
          10,
          Paint()
            ..color = AppColors.primary
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6);
      text(n, pos - const Offset(3, 6), AppColors.primary, fs: 10);
    }

    zone(Offset(size.width * 0.3, size.height * 0.42), '1');
    zone(Offset(size.width * 0.46, size.height * 0.68), '2');
    zone(Offset(size.width * 0.85, size.height * 0.72), '3');
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
