import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/popup_helper.dart';
import '../../../../core/widgets/verification_card.dart';
import '../widgets/seller_share_sheet.dart';
import '../../../../models/report_model.dart';
import '../../../../models/seller_model.dart';
import '../../../../models/user_model.dart';
import '../../../../services/firestore_service.dart';
import '../../../../services/google_auth_service.dart';
import '../../../../services/seed_data_service.dart';

/// Profile tab — guest prompt, buyer dashboard, or seller dashboard.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  UserModel? _me;
  SellerModel? _mySeller;
  List<ReportModel> _myReports = const [];
  List<ReportModel> _myFiledReports = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final fs = ref.read(firestoreServiceProvider);
      final me = await fs.getUserById(user.uid);
      SellerModel? seller;
      if (me?.linkedSellerId != null) {
        seller = await fs.getSellerById(me!.linkedSellerId!);
      }
      List<ReportModel> reports = const [];
      if (seller != null) {
        reports = await fs.getReportsForSeller(seller.sellerId);
      }
      final filed = await fs.getReportsByReporter(user.uid);
      if (mounted) {
        setState(() {
          _me = me;
          _mySeller = seller;
          _myReports = reports;
          _myFiledReports = filed;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        PopupHelper.showWarning(
            context, 'Could not load your profile data');
      }
    }
  }

  String _maskedPhone(String phone) {
    if (phone.length < 4) return phone;
    return '98XXXX${phone.substring(phone.length - 4)}';
  }

  Future<void> _signOut() async {
    await PopupHelper.showConfirmDialog(
      context,
      title: 'Sign Out',
      message: 'You can sign back in any time with your phone number.',
      confirmLabel: 'Sign Out',
      onConfirm: () async {
        try {
          await GoogleAuthService().signOut();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_guest', true);
          if (!mounted) return;
          PopupHelper.showSuccess(context, 'Signed out successfully');
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/home', (r) => false);
        } catch (_) {
          if (mounted) {
            PopupHelper.showError(
                context, 'Sign out failed. Please try again.');
          }
        }
      },
    );
  }

  Future<void> _deleteAccount() async {
    await PopupHelper.showConfirmDialog(
      context,
      title: 'Delete Your Account',
      message: 'Your reports will be anonymized but retained for '
          'fraud prevention. This cannot be undone.',
      confirmLabel: 'Delete Forever',
      isDangerous: true,
      onConfirm: () async {
        PopupHelper.showLoadingDialog(context, 'Deleting account...');
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await ref
                .read(firestoreServiceProvider)
                .createOrUpdateUser(_me!.copyWith(
                  isAccountActive: false,
                  fullName: 'Deleted user',
                ));
            await user.delete();
          }
          if (!mounted) return;
          PopupHelper.hideLoadingDialog(context);
          PopupHelper.showSuccess(context, 'Account deleted');
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/onboarding', (r) => false);
        } catch (_) {
          if (!mounted) return;
          PopupHelper.hideLoadingDialog(context);
          PopupHelper.showError(
              context,
              'Could not delete account. You may need to sign in '
              'again first for security.');
        }
      },
    );
  }

  Future<void> _seedDemoData() async {
    if (!kDebugMode) return;
    PopupHelper.showLoadingDialog(context, 'Loading seller records...');
    try {
      final existing = await FirebaseFirestore.instance
          .collection('sellers')
          .doc('seed_priya_fashions')
          .get();
      if (existing.exists) {
        if (!mounted) return;
        PopupHelper.hideLoadingDialog(context);
        PopupHelper.showInfo(context, 'Seller records already exist');
        return;
      }
      await SeedDataService.seedDatabase();
      if (!mounted) return;
      PopupHelper.hideLoadingDialog(context);
      PopupHelper.showSuccess(context, 'Seller records loaded successfully');
    } catch (_) {
      if (!mounted) return;
      PopupHelper.hideLoadingDialog(context);
      PopupHelper.showError(
          context, 'Could not load seller records. Check your connection.');
    }
  }

  void _respondToReport(ReportModel report) {
    final controller = TextEditingController();
    PopupHelper.showBottomSheet(
      context,
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Respond to Report',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(report.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Explain your side of this incident...',
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (controller.text.trim().isEmpty) {
                    PopupHelper.showWarning(
                        context, 'Please write your response');
                    return;
                  }
                  try {
                    await ref
                        .read(firestoreServiceProvider)
                        .addSellerResponse(
                            report.reportId, controller.text.trim());
                    if (!mounted) return;
                    Navigator.pop(context);
                    PopupHelper.showSuccess(
                        context, 'Response submitted');
                    _load();
                  } catch (_) {
                    if (mounted) {
                      PopupHelper.showError(context,
                          'Could not submit response. Try again.');
                    }
                  }
                },
                child: const Text('Submit Response'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _guestView();
    if (_loading) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    return _mySeller != null ? _sellerView() : _buyerView();
  }

  // ── Guest ────────────────────────────────────────────────────────────────────

  Widget _guestView() {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
          title: const Text('Profile'),
          automaticallyImplyLeading: false),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline_rounded,
                    size: 46, color: AppColors.primary),
              ),
              const SizedBox(height: 18),
              Text('You are browsing as a guest',
                  style: GoogleFonts.poppins(
                      fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                'Create a free account to:',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              ...[
                (
                  Icons.flag_outlined,
                  'Report fraudulent sellers and protect others'
                ),
                (
                  Icons.star_outline_rounded,
                  'Leave reviews for sellers you have used'
                ),
                (
                  Icons.notifications_none_rounded,
                  'Get notified when a seller you searched gets reported'
                ),
                (
                  Icons.storefront_outlined,
                  'Build your seller profile if you run a business'
                ),
              ].map((row) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: AppColors.primary50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(row.$1,
                              size: 18, color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(row.$2,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: AppColors.textPrimary,
                                height: 1.4,
                              )),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/auth'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    child: const Text('Create Free Account'),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/auth'),
                  child: const Text('Sign In'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Buyer ────────────────────────────────────────────────────────────────────

  Widget _buyerView() {
    final me = _me;
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
          title: const Text('My Profile'),
          automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primary50,
                  child: Text(
                    (me?.fullName.isNotEmpty == true
                            ? me!.fullName[0]
                            : 'U')
                        .toUpperCase(),
                    style: GoogleFonts.poppins(
                      color: AppColors.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(me?.fullName ?? 'SafeBuy user',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          )),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Buyer',
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                )),
                          ),
                          const SizedBox(width: 8),
                          Text(_maskedPhone(me?.phone ?? ''),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              )),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Impact stats
          Text('Your contribution to SafeBuy Nepal',
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              _statCard('📋', '${_myFiledReports.length}',
                  'Reports filed'),
              const SizedBox(width: 10),
              _statCard(
                  '🗓️',
                  me != null
                      ? DateFormat('MMM yyyy').format(me.createdAt)
                      : '-',
                  'Member since'),
            ],
          ),
          const SizedBox(height: 18),

          // My reports
          Text('My Reports',
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (_myFiledReports.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderLight),
              ),
              alignment: Alignment.center,
              child: Text(
                'You have not filed any reports yet. If you have '
                'been scammed, help the community by reporting it.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.5),
              ),
            )
          else
            ..._myFiledReports.take(5).map((r) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 3),
                            Text(
                              'NPR ${r.amountLost.toStringAsFixed(0)} · '
                              '${DateFormat('dd MMM yyyy').format(r.submittedAt)}',
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: r.status == 'verified'
                              ? AppColors.trustedBg
                              : AppColors.unverifiedBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          r.status == 'verified'
                              ? 'Verified'
                              : r.status == 'pending'
                                  ? 'Under review'
                                  : r.status,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: r.status == 'verified'
                                ? AppColors.trusted
                                : AppColors.unverified,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          const SizedBox(height: 18),

          _settingsSection(),
        ],
      ),
    );
  }

  // ── Seller ───────────────────────────────────────────────────────────────────

  Widget _sellerView() {
    final s = _mySeller!;
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
          title: const Text('My Business'),
          automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
        children: [
          // Trust + tier header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          AppColors.trustScoreColor(s.trustScore),
                      width: 3,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(s.trustScore.round().toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color:
                            AppColors.trustScoreColor(s.trustScore),
                      )),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.displayName,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          )),
                      Row(
                        children: [
                          Icon(TierStyle.icon(s.verificationTier),
                              size: 14,
                              color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            '${TierStyle.label(s.verificationTier)} TIER',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // KYC status / card
          if (s.isKycVerified)
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/seller/card',
                  arguments: {'sellerId': s.sellerId}),
              child: Hero(
                tag: 'safebuy_card_${s.sellerId}',
                child: SafebuyVerificationCard(
                    seller: s,
                    width: MediaQuery.sizeOf(context).width - 32),
              ),
            )
          else
            _actionTile(
              icon: Icons.verified_user_outlined,
              color: AppColors.trusted,
              title: s.isKycPending
                  ? 'KYC under review (24-48 hrs)'
                  : 'Get SafeBuy Verified',
              subtitle: s.isKycPending
                  ? 'We will notify you once approved'
                  : 'Complete KYC to earn your verification card',
              onTap: () => Navigator.pushNamed(context, '/kyc'),
            ),
          const SizedBox(height: 12),

          // Share my SafeBuy profile so buyers can verify me instantly
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                showSellerShareSheet(context, s);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              icon: const Icon(Icons.ios_share_rounded, size: 18),
              label: Text('Share My SafeBuy Profile',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  )),
            ),
          ),
          const SizedBox(height: 12),

          // Reports against me
          Text('Reports Against You (${_myReports.length})',
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (_myReports.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderLight),
              ),
              alignment: Alignment.center,
              child: Text('✅ No reports on record. Keep it up!',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.textSecondary)),
            )
          else
            ..._myReports.take(5).map((r) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontSize: 12.5, height: 1.5)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            'NPR ${r.amountLost.toStringAsFixed(0)} · ${r.status}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.highRisk,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          if (r.sellerResponse == null)
                            TextButton(
                              onPressed: () => _respondToReport(r),
                              style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  minimumSize: const Size(0, 32)),
                              child: const Text('Respond'),
                            )
                          else
                            Text('✓ Responded',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.trusted,
                                  fontWeight: FontWeight.w600,
                                )),
                        ],
                      ),
                    ],
                  ),
                )),
          const SizedBox(height: 14),

          _actionTile(
            icon: Icons.emoji_events_outlined,
            color: const Color(0xFFD4AF37),
            title: 'Monthly Leaderboard',
            subtitle: 'See where your business ranks',
            onTap: () => Navigator.pushNamed(context, '/leaderboard'),
          ),
          const SizedBox(height: 18),

          _settingsSection(),
        ],
      ),
    );
  }

  // ── Shared pieces ────────────────────────────────────────────────────────────

  Widget _statCard(String emoji, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 10.5, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600)),
                    Text(subtitle,
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textMuted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Settings',
            style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: [
              _settingRow(Icons.notifications_none_rounded,
                  'Notifications', () {
                Navigator.pushNamed(context, '/notifications');
              }),
              _divider(),
              _settingRow(Icons.menu_book_outlined, 'How It Works', () {
                Navigator.pushNamed(context, '/guide');
              }),
              _divider(),
              _settingRow(Icons.privacy_tip_outlined, 'Privacy Policy',
                  () {
                Navigator.pushNamed(context, '/privacy');
              }),
              _divider(),
              _settingRow(
                  Icons.description_outlined, 'Terms of Service', () {
                Navigator.pushNamed(context, '/terms');
              }),
              _divider(),
              _settingRow(
                  Icons.info_outline_rounded, 'About SafeBuy Nepal', () {
                Navigator.pushNamed(context, '/about');
              }),
              if (_me?.role == 'admin') ...[
                _divider(),
                _settingRow(
                    Icons.admin_panel_settings_outlined, 'Admin: KYC Review',
                    () {
                  Navigator.pushNamed(context, '/admin/kyc');
                }),
                _divider(),
                _settingRow(Icons.dashboard_customize_outlined,
                    'Admin: Dashboard', () {
                  Navigator.pushNamed(context, '/admin');
                }),
              ],
              _divider(),
              _settingRow(Icons.logout_rounded, 'Sign Out', _signOut),
              _divider(),
              _settingRow(Icons.delete_outline_rounded, 'Delete Account',
                  _deleteAccount,
                  danger: true),
            ],
          ),
        ),

        // Developer Options — debug builds only.
        if (AppConfig.showDemoFeatures) ...[
          const SizedBox(height: 18),
          Text('Developer Options',
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: _settingRow(
                Icons.dataset_outlined, 'Load Seller Records', _seedDemoData),
          ),
        ],
      ],
    );
  }

  Widget _divider() =>
      const Divider(height: 1, color: AppColors.borderLight);

  Widget _settingRow(IconData icon, String label, VoidCallback onTap,
      {bool danger = false}) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color:
                    danger ? AppColors.error : AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: danger
                        ? AppColors.error
                        : AppColors.textPrimary,
                  )),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
