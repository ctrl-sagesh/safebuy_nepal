import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/utils/validators.dart';
import '../../../../models/user_model.dart';
import '../../../../providers/language_provider.dart';
import '../../../../services/firestore_service.dart';
import '../providers/auth_provider.dart';

class UserProfileSetupScreen extends ConsumerStatefulWidget {
  const UserProfileSetupScreen({super.key});

  @override
  ConsumerState<UserProfileSetupScreen> createState() =>
      _UserProfileSetupScreenState();
}

class _UserProfileSetupScreenState
    extends ConsumerState<UserProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _selectedRole = 'buyer';
  bool _isSubmitting = false;
  String? _idImagePath;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickIdDocument() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.bgPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded,
                  color: AppColors.primary),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: AppColors.primary),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      maxWidth: 1280,
      imageQuality: 80,
    );
    if (file != null && mounted) {
      setState(() => _idImagePath = file.path);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);

    try {
      final authUser = ref.read(authStateProvider).value;
      if (authUser == null) {
        setState(() => _isSubmitting = false);
        return;
      }

      final lang = ref.read(languageProvider);
      final hasId = _idImagePath != null;
      final user = UserModel(
        userId: authUser.uid,
        phone: authUser.phoneNumber?.replaceFirst('+977', '') ?? '',
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        role: _selectedRole,
        createdAt: DateTime.now(),
        isAccountActive: true,
        totalReportsSubmitted: 0,
        lastLoginAt: DateTime.now(),
        preferredLanguage: lang,
        // Local reference for the demo build (Storage upload happens server-side
        // once Firebase Storage is enabled). Presence marks the ID as submitted.
        nationalIdUrl: _idImagePath,
        verificationStatus: hasId ? 'pending' : 'none',
      );

      await ref.read(firestoreServiceProvider).createOrUpdateUser(user);

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(hasId
                  ? 'Profile created. Your ID is pending admin verification.'
                  : 'Profile created. Upload an ID later to report fraud.'),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    const Icon(Icons.person_outline,
                        color: Colors.white, size: 48),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      AppStrings.get('setup_title', lang),
                      style: AppTextStyles.titleLarge(lang: lang)
                          .copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppSpacing.radiusXxl),
                      topRight: Radius.circular(AppSpacing.radiusXxl),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSpacing.lg),
                          TextFormField(
                            controller: _nameCtrl,
                            textCapitalization: TextCapitalization.words,
                            validator: (v) => Validators.fullName(v, lang),
                            decoration: InputDecoration(
                              labelText: AppStrings.get('full_name', lang),
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          // Email
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => Validators.email(v, lang),
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              hintText: 'you@example.com',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Text('I am a...',
                              style: AppTextStyles.titleSmall(lang: lang)),
                          const SizedBox(height: AppSpacing.md),
                          _RoleCard(
                            title: AppStrings.get('i_am_buyer', lang),
                            subtitle: AppStrings.get('i_am_buyer_sub', lang),
                            icon: Icons.shopping_bag_outlined,
                            isSelected: _selectedRole == 'buyer',
                            onTap: () =>
                                setState(() => _selectedRole = 'buyer'),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _RoleCard(
                            title: AppStrings.get('i_am_seller', lang),
                            subtitle: AppStrings.get('i_am_seller_sub', lang),
                            icon: Icons.store_outlined,
                            isSelected: _selectedRole == 'seller',
                            onTap: () =>
                                setState(() => _selectedRole = 'seller'),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          // ── National ID verification ──────────────────────
                          Text('Identity Verification',
                              style: AppTextStyles.titleSmall(lang: lang)),
                          const SizedBox(height: 4),
                          Text(
                            'Upload a national ID (citizenship, license, or passport). Required to file fraud reports — an admin reviews it manually. Optional if you only want to browse.',
                            style: AppTextStyles.bodySmall(lang: lang),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _IdUploadZone(
                            imagePath: _idImagePath,
                            onTap: _pickIdDocument,
                            onRemove: () =>
                                setState(() => _idImagePath = null),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          CustomButton(
                            label: AppStrings.get('continue_btn', lang),
                            onPressed: _isSubmitting ? null : _submit,
                            isLoading: _isSubmitting,
                            lang: lang,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── ID upload zone ──────────────────────────────────────────────────────────

class _IdUploadZone extends StatelessWidget {
  const _IdUploadZone({
    required this.imagePath,
    required this.onTap,
    required this.onRemove,
  });
  final String? imagePath;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    if (imagePath != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(
              File(imagePath!),
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
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
                color: AppColors.unverified.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Pending verification',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.badge_outlined,
                color: AppColors.primary.withValues(alpha: 0.7), size: 32),
            const SizedBox(height: 8),
            Text('Tap to upload your ID',
                style: AppTextStyles.labelMedium()
                    .copyWith(color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.grey100,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.grey500,
                size: AppSpacing.iconLg,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: AppColors.primary, size: AppSpacing.iconMd),
          ],
        ),
      ),
    );
  }
}
