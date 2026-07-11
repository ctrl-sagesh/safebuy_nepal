import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/popup_helper.dart';
import '../../../../models/seller_model.dart';
import '../../../../models/user_model.dart';
import '../../../../services/firestore_service.dart';

/// Post-auth profile setup: name, role, language, optional business info.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

class _ProfileSetupScreenState
    extends ConsumerState<ProfileSetupScreen> {
  final _name = TextEditingController();
  final _businessName = TextEditingController();
  String _role = 'buyer';
  String _lang = 'en';
  String? _category;
  bool _saving = false;

  String? _nameError;
  String? _businessNameError;

  static const _categories = [
    'Clothing & Fashion',
    'Electronics & Gadgets',
    'Cosmetics & Beauty',
    'Food & Beverages',
    'Handmade & Crafts',
    'Books & Stationery',
    'Health & Wellness',
    'Home & Decor',
    'Sports & Fitness',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  Future<void> _prefill() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingName = prefs.getString('pending_name');
      final pendingRole = prefs.getString('pending_role');
      final googleName =
          FirebaseAuth.instance.currentUser?.displayName;
      if (!mounted) return;
      setState(() {
        _name.text = pendingName?.isNotEmpty == true
            ? pendingName!
            : (googleName ?? '');
        if (pendingRole != null) _role = pendingRole;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _name.dispose();
    _businessName.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();

    final nameErr = _name.text.trim().length < 2
        ? 'Name must be at least 2 characters'
        : null;
    final bizErr = _role == 'seller' &&
            _businessName.text.trim().length < 3
        ? 'Business name must be at least 3 characters'
        : null;
    setState(() {
      _nameError = nameErr;
      _businessNameError = bizErr;
    });
    if (nameErr != null || bizErr != null) {
      PopupHelper.showError(
          context, 'Please fill in all required fields');
      return;
    }
    if (_role == 'seller' && _category == null) {
      PopupHelper.showError(
          context, 'Please select your business category');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      PopupHelper.showError(
          context, 'Session expired. Please sign in again.');
      Navigator.of(context).pushReplacementNamed('/auth');
      return;
    }

    setState(() => _saving = true);
    PopupHelper.showLoadingDialog(context, 'Setting up your account...');

    try {
      final fs = ref.read(firestoreServiceProvider);
      String? linkedSellerId;

      if (_role == 'seller') {
        final seller = SellerModel(
          sellerId: '',
          name: _name.text.trim(),
          phone: user.phoneNumber?.replaceAll('+977', '') ?? '',
          trustScore: 50,
          trustVerdict: 'unverified',
          isVerified: false,
          verifiedBadge: false,
          totalOrders: 0,
          reviewCount: 0,
          scamReportCount: 0,
          accountCreatedAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
          disputeResponseRate: 0,
          businessName: _businessName.text.trim(),
          businessCategory: _category,
          trustScoreHistory: const [],
          averageRating: 0,
          linkedUserId: user.uid,
        );
        linkedSellerId = await fs.registerSeller(seller);
      }

      await fs.createOrUpdateUser(UserModel(
        userId: user.uid,
        phone: user.phoneNumber?.replaceAll('+977', '') ?? '',
        fullName: _name.text.trim(),
        role: _role,
        createdAt: DateTime.now(),
        linkedSellerId: linkedSellerId,
        isAccountActive: true,
        totalReportsSubmitted: 0,
        lastLoginAt: DateTime.now(),
        preferredLanguage: _lang,
        email: user.email,
      ));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefLanguage, _lang);
      await prefs.setBool('is_guest', false);
      await prefs.remove('pending_name');
      await prefs.remove('pending_role');

      if (!mounted) return;
      PopupHelper.hideLoadingDialog(context);
      PopupHelper.showSuccess(context, 'Welcome to SafeBuy Nepal!');
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/home', (r) => false);
    } catch (e) {
      if (!mounted) return;
      PopupHelper.hideLoadingDialog(context);
      PopupHelper.showError(context,
          'Could not set up your account. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Set Up Your Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Full Name *',
                prefixIcon: const Icon(Icons.person_outline_rounded),
                errorText: _nameError,
              ),
              onChanged: (v) {
                if (_nameError != null && v.trim().length >= 2) {
                  setState(() => _nameError = null);
                }
              },
            ),
            const SizedBox(height: 18),

            Text('I am a...',
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                )),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _roleCard('🛒', 'Buyer',
                      'Verify sellers & stay safe', 'buyer'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _roleCard('🏪', 'Seller',
                      'Build my trust rating', 'seller'),
                ),
              ],
            ),
            const SizedBox(height: 18),

            Text('Language / भाषा',
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                )),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _langChip('🇬🇧  English', 'en')),
                const SizedBox(width: 12),
                Expanded(child: _langChip('🇳🇵  नेपाली', 'ne')),
              ],
            ),

            if (_role == 'seller') ...[
              const SizedBox(height: 18),
              TextField(
                controller: _businessName,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Business Name *',
                  prefixIcon: const Icon(Icons.storefront_outlined),
                  errorText: _businessNameError,
                ),
                onChanged: (v) {
                  if (_businessNameError != null &&
                      v.trim().length >= 3) {
                    setState(() => _businessNameError = null);
                  }
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Business Category *',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _categories
                    .map((c) =>
                        DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v),
              ),
            ],

            const SizedBox(height: 28),
            SizedBox(
              height: 54,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  child: const Text('Complete Setup'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleCard(
      String emoji, String title, String subtitle, String value) {
    final selected = _role == value;
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _role = value);
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary50 : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                selected ? AppColors.primary : AppColors.borderLight,
            width: selected ? 2 : 1.2,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textPrimary,
                )),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.textMuted,
                )),
          ],
        ),
      ),
    );
  }

  Widget _langChip(String label, String value) {
    final selected = _lang == value;
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _lang = value);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderLight,
            width: selected ? 2 : 1.2,
          ),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: selected
                  ? AppColors.primary
                  : AppColors.textSecondary,
            )),
      ),
    );
  }
}
