import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/popup_helper.dart';

/// In-memory draft of the KYC submission, shared across the step screens.
class KycDraft {
  static final KycDraft instance = KycDraft._();
  KycDraft._();

  String? gmail;
  File? qrFile;
  File? selfieFile;
  File? panFile;
  final List<File?> locationFiles = [null, null, null];
  double? locationLat;
  double? locationLng;
  String panNumber = '';
  String panName = '';
  String citizenshipNumber = '';

  void reset() {
    gmail = null;
    qrFile = null;
    selfieFile = null;
    panFile = null;
    locationFiles.setAll(0, [null, null, null]);
    locationLat = null;
    locationLng = null;
    panNumber = '';
    panName = '';
    citizenshipNumber = '';
  }
}

/// Step progress header used across the 5 KYC steps.
class KycStepHeader extends StatelessWidget {
  const KycStepHeader({super.key, required this.step});

  final int step; // 1-5

  static const _labels = ['Gmail', 'QR', 'Selfie', 'PAN', 'Location'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        children: List.generate(5, (i) {
          final done = i < step - 1;
          final active = i == step - 1;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done
                              ? AppColors.trusted
                              : active
                                  ? AppColors.primary
                                  : AppColors.grey200,
                        ),
                        alignment: Alignment.center,
                        child: done
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 15)
                            : Text('${i + 1}',
                                style: GoogleFonts.poppins(
                                  color: active
                                      ? Colors.white
                                      : AppColors.grey500,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                )),
                      ),
                      const SizedBox(height: 3),
                      Text(_labels[i],
                          style: GoogleFonts.inter(
                            fontSize: 8.5,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: active
                                ? AppColors.primary
                                : AppColors.textMuted,
                          )),
                    ],
                  ),
                ),
                if (i < 4)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 14),
                      color: done
                          ? AppColors.trusted
                          : AppColors.grey200,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

/// Dashed upload zone with preview + remove.
class KycUploadZone extends StatelessWidget {
  const KycUploadZone({
    super.key,
    required this.label,
    required this.file,
    required this.onPick,
    this.onRemove,
    this.height = 150,
    this.icon = Icons.add_photo_alternate_outlined,
  });

  final String label;
  final File? file;
  final VoidCallback onPick;
  final VoidCallback? onRemove;
  final double height;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (file != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(file!,
                height: height,
                width: double.infinity,
                fit: BoxFit.cover),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onRemove?.call();
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      );
    }
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onPick();
      },
      borderRadius: BorderRadius.circular(14),
      child: DottedBorder(
        options: RoundedRectDottedBorderOptions(
          radius: const Radius.circular(14),
          color: AppColors.primary,
          strokeWidth: 1.6,
          dashPattern: const [7, 5],
        ),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 34, color: AppColors.primary),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared image-picking helper with error popups.
Future<File?> pickKycImage(BuildContext context,
    {ImageSource source = ImageSource.gallery,
    CameraDevice camera = CameraDevice.rear}) async {
  try {
    final picked = await ImagePicker().pickImage(
      source: source,
      preferredCameraDevice: camera,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (picked == null) return null;
    return File(picked.path);
  } catch (_) {
    if (context.mounted) {
      PopupHelper.showError(context,
          'Could not open the ${source == ImageSource.camera ? 'camera' : 'gallery'}. Please check app permissions.');
    }
    return null;
  }
}

/// Bottom next/submit bar used by every KYC step.
class KycBottomBar extends StatelessWidget {
  const KycBottomBar({
    super.key,
    required this.enabled,
    required this.label,
    required this.onNext,
    required this.onDisabledTap,
  });

  final bool enabled;
  final String label;
  final VoidCallback onNext;
  final VoidCallback onDisabledTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.paddingOf(context).bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: GestureDetector(
        onTap: enabled ? null : onDisabledTap,
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: enabled ? AppColors.primaryGradient : null,
              color: enabled ? null : AppColors.grey200,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ElevatedButton(
              onPressed: enabled
                  ? () {
                      HapticFeedback.mediumImpact();
                      onNext();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
              child: Text(label,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color:
                        enabled ? Colors.white : AppColors.grey400,
                  )),
            ),
          ),
        ),
      ),
    );
  }
}
