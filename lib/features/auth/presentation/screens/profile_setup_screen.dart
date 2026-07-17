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

  // Contrast tokens (match app_theme.dart's form styling).
  static const _ink = Color(0xFF1A1A1A);
  static const _inkLabel = Color(0xFF555555);
  static const _inkSub = Color(0xFF666666);
  static const _borderIdle = Color(0xFFE0E0E0);
  static const _sellerGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const SizedBox.shrink(),
        toolbarHeight: 24,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text('Complete Your Profile',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                )),
            const SizedBox(height: 4),
            Text('Tell us a bit about yourself',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: _inkSub,
                )),
            const SizedBox(height: 22),

            // Full name
            _fieldLabel('Full Name'),
            const SizedBox(height: 6),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              style: GoogleFonts.inter(
                fontSize: 14.5,
                color: _ink,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Your full name',
                prefixIcon: const Icon(Icons.person_outline_rounded,
                    color: Color(0xFF9E9E9E)),
                errorText: _nameError,
              ),
              onChanged: (v) {
                if (_nameError != null && v.trim().length >= 2) {
                  setState(() => _nameError = null);
                }
              },
            ),
            const SizedBox(height: 22),

            // Role selection
            Text('I am a...',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                )),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _roleCard(
                    icon: Icons.shopping_cart_outlined,
                    title: 'Buyer',
                    subtitle: 'Shop safely with trust ratings',
                    value: 'buyer',
                    accent: AppColors.primary,
                    selectedBg: const Color(0xFFEFF6FF),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _roleCard(
                    icon: Icons.storefront_outlined,
                    title: 'Seller',
                    subtitle: 'Build my trust rating',
                    value: 'seller',
                    accent: _sellerGreen,
                    selectedBg: const Color(0xFFF0FDF4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Language preference
            Text('Language / भाषा',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                )),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _langCard('🇬🇧', 'English', 'en')),
                const SizedBox(width: 12),
                Expanded(child: _langCard('🇳🇵', 'नेपाली', 'ne')),
              ],
            ),

            if (_role == 'seller') ...[
              const SizedBox(height: 22),
              _fieldLabel('Business Name'),
              const SizedBox(height: 6),
              TextField(
                controller: _businessName,
                textCapitalization: TextCapitalization.words,
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  color: _ink,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. Ramesh Clothing',
                  prefixIcon: const Icon(Icons.storefront_outlined,
                      color: Color(0xFF9E9E9E)),
                  errorText: _businessNameError,
                ),
                onChanged: (v) {
                  if (_businessNameError != null &&
                      v.trim().length >= 3) {
                    setState(() => _businessNameError = null);
                  }
                },
              ),
              const SizedBox(height: 16),
              _fieldLabel('Business Category'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _category,
                isExpanded: true,
                menuMaxHeight: 300,
                dropdownColor: Colors.white,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF666666)),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: _ink,
                  fontWeight: FontWeight.w500,
                ),
                decoration: const InputDecoration(
                  hintText: 'Select your category',
                  prefixIcon: Icon(Icons.category_outlined,
                      color: Color(0xFF9E9E9E)),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(
                            c,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: _ink,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ))
                    .toList(),
                selectedItemBuilder: (context) => _categories
                    .map((c) => Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            c,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: _ink,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _category = v),
              ),
            ],

            const SizedBox(height: 28),

            // Complete setup button
            Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: Text('Complete Setup',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: _inkLabel,
        ));
  }

  Widget _roleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required Color accent,
    required Color selectedBg,
  }) {
    final selected = _role == value;
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _role = value);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
        decoration: BoxDecoration(
          color: selected ? selectedBg : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? accent : _borderIdle,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Icon(icon,
                    size: 32,
                    color: selected ? accent : _inkSub),
                const SizedBox(height: 8),
                Text(title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: selected ? accent : _ink,
                    )),
                const SizedBox(height: 2),
                Text(subtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: _inkSub,
                      height: 1.35,
                    )),
              ],
            ),
            if (selected)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 13, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _langCard(String flag, String label, String value) {
    final selected = _lang == value;
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _lang = value);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : _borderIdle,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: selected ? AppColors.primary : _ink,
                )),
          ],
        ),
      ),
    );
  }
}
