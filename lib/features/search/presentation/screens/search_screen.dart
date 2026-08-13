import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/popup_helper.dart';
import '../../../../core/widgets/language_toggle.dart';
import '../../../../core/widgets/loyalty_badge.dart';
import '../../../../core/widgets/pulse_glow.dart';
import '../../../../core/widgets/verification_card.dart';
import '../../../../models/seller_model.dart';
import '../../../../providers/language_provider.dart';
import '../../../../services/firestore_service.dart';
import 'qr_scan_screen.dart';

/// Inline EN/NE picker used across this file's widgets.
String _tr(String lang, String en, String ne) => lang == 'ne' ? ne : en;

/// Search tab — find sellers by phone, eSewa ID, or social handle and
/// see their SafeBuy verification card.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.autofocus = false, this.searchRequest});

  final bool autofocus;

  /// When the Home tab requests a search (example chips), the query
  /// arrives here and runs immediately.
  final ValueNotifier<String?>? searchRequest;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  bool _searching = false;
  bool _searched = false;
  List<SellerModel> _results = const [];

  bool get _isGuest => FirebaseAuth.instance.currentUser == null;

  String get _hint {
    final q = _controller.text.trim();
    if (q.isEmpty) return '';
    final lang = ref.read(languageProvider);
    if (q.startsWith('97') || q.startsWith('98')) {
      return _tr(lang, 'Searching by phone number',
          'फोन नम्बरबाट खोज्दै');
    }
    if (q.startsWith('@')) {
      return _tr(lang, 'Searching by social handle',
          'सोशल ह्यान्डलबाट खोज्दै');
    }
    if (RegExp(r'^[A-Za-z]').hasMatch(q)) {
      return _tr(lang, 'Searching by business name',
          'व्यवसायको नामबाट खोज्दै');
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    widget.searchRequest?.addListener(_onExternalSearch);
  }

  void _onExternalSearch() {
    final q = widget.searchRequest?.value;
    if (q == null || q.isEmpty || !mounted) return;
    widget.searchRequest?.value = null;
    _controller.text = q;
    setState(() {});
    _search();
  }

  @override
  void dispose() {
    widget.searchRequest?.removeListener(_onExternalSearch);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Opens the QR scanner; a scanned phone number pre-fills the field
  /// and triggers the search immediately.
  Future<void> _scanQr() async {
    HapticFeedback.lightImpact();
    final phone = await Navigator.push<String>(
      context,
      MaterialPageRoute(
          builder: (_) => const QrScanScreen(), fullscreenDialog: true),
    );
    if (phone == null || phone.isEmpty || !mounted) return;
    _controller.text = phone;
    setState(() {});
    _search();
  }

  Future<void> _search() async {
    HapticFeedback.mediumImpact();
    final q = _controller.text.trim();
    if (q.isEmpty) {
      PopupHelper.showWarning(
          context,
          _tr(ref.read(languageProvider),
              'Please enter a phone number, eSewa ID, or handle',
              'कृपया फोन नम्बर, eSewa आईडी, वा ह्यान्डल हाल्नुहोस्'));
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _searching = true;
      _searched = false;
    });
    try {
      final results =
          await ref.read(firestoreServiceProvider).searchSellers(q);
      if (!mounted) return;
      setState(() {
        _results = results;
        _searching = false;
        _searched = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = const [];
        _searching = false;
        _searched = true;
      });
      PopupHelper.showError(
          context,
          _tr(ref.read(languageProvider),
              'Search failed. Please check your connection.',
              'खोज असफल भयो। कृपया इन्टरनेट जाँच्नुहोस्।'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    String t(String en, String ne) => _tr(lang, en, ne);
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(t('Verify a Seller', 'विक्रेता जाँच्नुहोस्')),
        automaticallyImplyLeading: false,
        actions: const [LanguageToggle()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            padding: const EdgeInsets.fromLTRB(16, 4, 6, 4),
            child: Row(
              children: [
                const Icon(Icons.search_rounded,
                    color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    autofocus: widget.autofocus,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: t('Phone, eSewa ID, or @handle…',
                          'फोन, eSewa आईडी, वा @ह्यान्डल…'),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                  ),
                ),
                SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: _searching ? null : _search,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 42),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 18),
                    ),
                    child: _searching
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(t('Search', 'खोज्नुहोस्')),
                  ),
                ),
                IconButton(
                  onPressed: _scanQr,
                  tooltip: t('Scan seller QR', 'विक्रेता QR स्क्यान गर्नुहोस्'),
                  icon: const Icon(Icons.qr_code_scanner_rounded,
                      color: AppColors.primary),
                ),
              ],
            ),
          ),

          // Live hint about what kind of search is running
          if (_hint.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Text(_hint,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  )),
            ),
          const SizedBox(height: 16),

          // Demo quick-search (debug builds only — for thesis demonstration)
          if (AppConfig.showDemoFeatures) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quick Search',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary900,
                      )),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _demoChip('✅ Trusted', AppConfig.demoTrustedSeller,
                          AppColors.trusted),
                      _demoChip('⚠ Unverified',
                          AppConfig.demoUnverifiedSeller,
                          AppColors.unverified),
                      _demoChip('🔴 High Risk',
                          AppConfig.demoHighRiskSeller, AppColors.highRisk),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (_searching)
            ...List.generate(
              2,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Shimmer.fromColors(
                  baseColor: AppColors.shimmerBase,
                  highlightColor: AppColors.shimmerHighlight,
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            )
          else if (_searched && _results.isEmpty)
            _NotFoundCard(query: _controller.text.trim(), lang: lang)
          else if (_results.isNotEmpty)
            ..._results.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      children: [
                        _SellerResultCard(
                          seller: e.value,
                          isGuest: _isGuest,
                          lang: lang,
                        ),
                        if (e.value.trustVerdict == 'unverified')
                          _BeforeYouPayChecklist(
                              sellerId: e.value.sellerId, lang: lang),
                      ],
                    )
                        .animate(delay: (e.key * 100).ms)
                        .fadeIn(duration: 350.ms)
                        .moveY(
                          begin: 40,
                          end: 0,
                          duration: 600.ms,
                          curve: Curves.easeOutBack,
                        ),
                  ),
                )
          else
            _IdleHelp(lang: lang),
        ],
      ),
    );
  }

  Widget _demoChip(String label, String phone, Color color) {
    return InkWell(
      onTap: () {
        HapticFeedback.mediumImpact();
        _controller.text = phone;
        setState(() {});
        _search();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: color,
            )),
      ),
    );
  }

}

// ── Seller result: the SafeBuy verification-card style result ─────────────────

class _SellerResultCard extends StatelessWidget {
  const _SellerResultCard(
      {required this.seller, required this.isGuest, required this.lang});

  final SellerModel seller;
  final bool isGuest;
  final String lang;

  String t(String en, String ne) => _tr(lang, en, ne);

  int get _monthsActive {
    final days =
        DateTime.now().difference(seller.accountCreatedAt).inDays;
    return (days / 30).floor().clamp(0, 999);
  }

  (IconData, String, String, Color, Color) get _verdictContent {
    switch (seller.trustVerdict) {
      case 'trusted':
        return (
          Icons.check_circle_rounded,
          t('TRUSTED SELLER', 'भरपर्दो विक्रेता'),
          t(
            'This seller has a strong track record. '
                '${seller.reviewCount} community reviews, '
                '$_monthsActive months active, '
                '${seller.scamReportCount == 0 ? 'zero complaints' : 'only ${seller.scamReportCount} complaint(s)'}.',
            'यो विक्रेताको राम्रो रेकर्ड छ। '
                '${seller.reviewCount} समुदाय समीक्षा, '
                '$_monthsActive महिना सक्रिय, '
                '${seller.scamReportCount == 0 ? 'कुनै उजुरी छैन' : 'जम्मा ${seller.scamReportCount} उजुरी'}।',
          ),
          AppColors.trusted,
          AppColors.trustedBg,
        );
      case 'high_risk':
        return (
          Icons.cancel_rounded,
          t('HIGH RISK: DO NOT PAY', 'उच्च जोखिम: भुक्तानी नगर्नुहोस्'),
          t(
            'WARNING: ${seller.scamReportCount} fraud '
                'complaint${seller.scamReportCount == 1 ? ' has' : 's have'} '
                'been filed against this seller. We strongly recommend '
                'not paying this seller.',
            'चेतावनी: यो विक्रेताविरुद्ध ${seller.scamReportCount} ठगी '
                'उजुरी दर्ता भएका छन्। यो विक्रेतालाई भुक्तानी नगर्न '
                'हामी दृढतापूर्वक सिफारिस गर्छौं।',
          ),
          AppColors.highRisk,
          AppColors.highRiskBg,
        );
      default:
        return (
          Icons.help_rounded,
          t('UNVERIFIED SELLER', 'अप्रमाणित विक्रेता'),
          t(
            'This seller has not been fully verified. Proceed with '
                'caution. Ask for video call proof before paying.',
            'यो विक्रेता पूर्ण रूपमा प्रमाणित छैन। सावधानीका साथ '
                'अगाडि बढ्नुहोस्। भुक्तानी अघि भिडियो कल प्रमाण माग्नुहोस्।',
          ),
          AppColors.unverified,
          AppColors.unverifiedBg,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = AppColors.trustScoreColor(seller.trustScore);
    final tier = seller.verificationTier;
    final tierColor = TierStyle.color(tier);
    final overdue = seller.isReverificationOverdue;
    final (vIcon, vTitle, vExplain, vColor, vBg) = _verdictContent;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // TOP — blue gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: tierColor, width: 2.5),
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                  child: seller.profileImageUrl?.isNotEmpty == true
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: seller.profileImageUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => const Icon(
                                Icons.person,
                                color: Colors.white),
                          ),
                        )
                      : const Icon(Icons.person,
                          color: Colors.white, size: 30),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(seller.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          )),
                      if (seller.businessCategory != null)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(seller.businessCategory!,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 10.5,
                              )),
                        ),
                    ],
                  ),
                ),
                // Trust score circle
                Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: scoreColor, width: 3),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        seller.trustScore.round().toString(),
                        style: GoogleFonts.poppins(
                          color: scoreColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      seller.trustVerdict == 'trusted'
                          ? t('TRUSTED', 'भरपर्दो')
                          : seller.trustVerdict == 'high_risk'
                              ? t('HIGH RISK', 'उच्च जोखिम')
                              : t('UNVERIFIED', 'अप्रमाणित'),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // VERDICT BANNER — the first thing eyes land on
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: vBg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    seller.trustVerdict == 'high_risk'
                        ? PulseGlow.danger(
                            color: vColor,
                            child: Icon(vIcon, color: vColor, size: 24),
                          )
                        : PulseGlow(
                            color: vColor,
                            child: Icon(vIcon, color: vColor, size: 24),
                          ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(vTitle,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: vColor,
                            letterSpacing: 0.3,
                          )),
                    ),
                    Text('${seller.trustScore.round()}/100',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: vColor,
                        )),
                  ],
                ),
                const SizedBox(height: 6),
                Text(vExplain,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    )),
              ],
            ),
          ),

          // MIDDLE — white
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('📅 ', style: TextStyle(fontSize: 13)),
                    Text(
                      '${t('Member since', 'सदस्य भएदेखि')}: ${DateFormat('MMMM yyyy').format(seller.accountCreatedAt)}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(overdue ? '⚠ ' : '🔄 ',
                        style: const TextStyle(fontSize: 13)),
                    Expanded(
                      child: Text(
                        seller.verificationExpiry == null
                            ? t('Not yet verified', 'अझै प्रमाणित छैन')
                            : overdue
                                ? t('Re-verification Overdue',
                                    'पुन:प्रमाणीकरण बाँकी')
                                : '${t('Verified until', 'सम्म प्रमाणित')}: ${DateFormat('dd MMM yyyy').format(seller.verificationExpiry!)}',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight:
                              overdue ? FontWeight.w700 : FontWeight.w500,
                          color: overdue
                              ? AppColors.warning
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Tier banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: tierColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: tierColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(TierStyle.icon(tier),
                          size: 16, color: tierColor),
                      const SizedBox(width: 8),
                      Text(
                        tier == 'none'
                            ? t('Verification Pending', 'प्रमाणीकरण बाँकी')
                            : '${TierStyle.label(tier)} ${t('Seller', 'विक्रेता')}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: tierColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (LoyaltyBadge.tierFor(seller) != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(children: [
                      LoyaltyBadge(seller: seller, compact: true),
                    ]),
                  ),
                const SizedBox(height: 10),

                // Socials + stats
                Row(
                  children: [
                    if (seller.tiktokHandle?.isNotEmpty == true)
                      _social('🎵 TikTok'),
                    if (seller.instagramHandle?.isNotEmpty == true)
                      _social('📸 Instagram'),
                    if (seller.facebookHandle?.isNotEmpty == true)
                      _social('👥 Facebook'),
                    const Spacer(),
                    Text('⭐ ${seller.reviewCount} ${t('Reviews', 'समीक्षा')}',
                        style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: AppColors.textSecondary)),
                    const SizedBox(width: 10),
                    Text(
                      '📋 ${seller.scamReportCount} ${t('Complaints', 'उजुरी')}',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: seller.scamReportCount > 0
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: seller.scamReportCount > 0
                            ? AppColors.highRisk
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // BOTTOM — light grey
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Column(
              children: [
                if (seller.qrCodeUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: seller.qrCodeUrl,
                      width: 92,
                      height: 92,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => const Icon(
                          Icons.qr_code_2_rounded,
                          size: 72),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                      t('🔒 This QR is locked by SafeBuy Nepal, safe to use',
                          '🔒 यो QR SafeBuy Nepal द्वारा लक गरिएको, प्रयोग गर्न सुरक्षित'),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      )),
                  const SizedBox(height: 4),
                ],
                if (seller.safebuyCardId.isNotEmpty)
                  Text(seller.safebuyCardId,
                      style: GoogleFonts.robotoMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      )),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pushNamed(context, '/seller',
                              arguments: {'sellerId': seller.sellerId});
                        },
                        style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 46)),
                        child: Text(
                            t('View Full Profile', 'पूरा प्रोफाइल हेर्नुहोस्')),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          if (isGuest) {
                            PopupHelper.showAuthGateBottomSheet(context);
                          } else {
                            Navigator.pushNamed(context, '/report',
                                arguments: {
                                  'sellerId': seller.sellerId,
                                  'phone': seller.phone,
                                });
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 46),
                          foregroundColor: AppColors.highRisk,
                          side: const BorderSide(
                              color: AppColors.highRisk, width: 1.5),
                        ),
                        child: Text(isGuest
                            ? t('Sign in to Report', 'उजुरीका लागि साइन इन')
                            : t('Report This Seller',
                                'यो विक्रेता उजुरी गर्नुहोस्')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _social(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 11, color: AppColors.textSecondary)),
    );
  }
}

// ── Not-found card ─────────────────────────────────────────────────────────────

class _NotFoundCard extends StatelessWidget {
  const _NotFoundCard({required this.query, required this.lang});

  final String query;
  final String lang;

  String t(String en, String ne) => _tr(lang, en, ne);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.unverifiedBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded,
                color: AppColors.unverified, size: 32),
          ),
          const SizedBox(height: 14),
          Text(
              t('Seller not found on SafeBuy Nepal',
                  'SafeBuy Nepal मा विक्रेता भेटिएन'),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 14),

          // Box 1 — what "not found" means
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.unverifiedBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.unverified.withValues(alpha: 0.35)),
            ),
            child: Text(
              t(
                  'This does not mean they are fraudulent. They may '
                      'simply not be registered yet.',
                  'यसको मतलब उनीहरू ठग हुन् भन्ने होइन। सायद उनीहरू '
                      'अझै दर्ता भएका छैनन्।'),
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: AppColors.textPrimary,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Box 2 — safety tips
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    t('Safety tips when buying from unverified sellers:',
                        'अप्रमाणित विक्रेतासँग किन्दा सुरक्षा सुझाव:'),
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    )),
                const SizedBox(height: 8),
                ...[
                  t('Ask for a video call showing the real product',
                      'साँचो सामान देखाउने भिडियो कल माग्नुहोस्'),
                  t('Start with a small test order under NPR 500',
                      'NPR ५०० भन्दा कमको सानो अर्डरबाट सुरु गर्नुहोस्'),
                  t('Never pay the full amount before seeing proof of dispatch',
                      'पठाएको प्रमाण नदेखी पूरा रकम कहिल्यै नतिर्नुहोस्'),
                  t('Screenshot everything before and after payment',
                      'भुक्तानी अघि र पछि सबै कुराको स्क्रिनसट लिनुहोस्'),
                ].map((tip) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_rounded,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(tip,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textPrimary,
                                  height: 1.5,
                                )),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    final guest =
                        FirebaseAuth.instance.currentUser == null;
                    if (guest) {
                      PopupHelper.showAuthGateBottomSheet(context);
                    } else {
                      Navigator.pushNamed(context, '/report',
                          arguments: {'prefill': query});
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 46),
                    foregroundColor: AppColors.highRisk,
                    side: const BorderSide(color: AppColors.highRisk),
                  ),
                  child: Text(
                      t('Report if you were scammed',
                          'ठगिनुभएको भए उजुरी गर्नुहोस्'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12.5)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    final guest =
                        FirebaseAuth.instance.currentUser == null;
                    if (guest) {
                      PopupHelper.showAuthGateBottomSheet(context);
                    } else {
                      Navigator.pushNamed(context, '/register-business');
                    }
                  },
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 46)),
                  child: Text(
                      t('This is my business? Register',
                          'यो मेरो व्यवसाय हो? दर्ता गर्नुहोस्'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12.5)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Idle helper ────────────────────────────────────────────────────────────────

class _IdleHelp extends StatelessWidget {
  const _IdleHelp({required this.lang});

  final String lang;

  @override
  Widget build(BuildContext context) {
    String t(String en, String ne) => _tr(lang, en, ne);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          const Icon(Icons.travel_explore_rounded,
              size: 56, color: AppColors.primary200),
          const SizedBox(height: 14),
          Text(
              t('Verify any seller before you pay',
                  'भुक्तानी अघि जुनसुकै विक्रेता जाँच्नुहोस्'),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 6),
          Text(
            t(
                'Enter a phone number (98XXXXXXXX), eSewa ID, or a '
                    'social media handle like @seller_np to see their '
                    'trust score and verification card.',
                'फोन नम्बर (98XXXXXXXX), eSewa आईडी, वा @seller_np '
                    'जस्तो सोशल मिडिया ह्यान्डल हालेर उनीहरूको ट्रस्ट '
                    'स्कोर र प्रमाणीकरण कार्ड हेर्नुहोस्।'),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── "Before You Pay" safety checklist (unverified sellers) ────────────────────

/// Interactive 5-step safety checklist shown under unverified search
/// results. Check state and dismissal live for the app session only.
class _BeforeYouPayChecklist extends StatefulWidget {
  const _BeforeYouPayChecklist({required this.sellerId, required this.lang});

  final String sellerId;
  final String lang;

  /// Session-scoped state, keyed by sellerId.
  static final Set<String> _dismissed = {};
  static final Map<String, Set<int>> _checked = {};

  @override
  State<_BeforeYouPayChecklist> createState() =>
      _BeforeYouPayChecklistState();
}

class _BeforeYouPayChecklistState extends State<_BeforeYouPayChecklist> {
  String t(String en, String ne) => _tr(widget.lang, en, ne);

  List<String> get _steps => [
        t('Ask for a video call showing the actual product',
            'साँचो सामान देखाउने भिडियो कल माग्नुहोस्'),
        t('Check their Instagram/TikTok comments for complaints',
            'उनीहरूको Instagram/TikTok कमेन्टमा उजुरी जाँच्नुहोस्'),
        t('Start with a small test order under NPR 500',
            'NPR ५०० भन्दा कमको सानो अर्डरबाट सुरु गर्नुहोस्'),
        t('Screenshot their profile and QR before paying',
            'भुक्तानी अघि उनीहरूको प्रोफाइल र QR स्क्रिनसट लिनुहोस्'),
        t('Never pay the full amount before dispatch',
            'पठाउनु अघि पूरा रकम कहिल्यै नतिर्नुहोस्'),
      ];

  Set<int> get _done =>
      _BeforeYouPayChecklist._checked.putIfAbsent(widget.sellerId, () => {});

  @override
  Widget build(BuildContext context) {
    if (_BeforeYouPayChecklist._dismissed.contains(widget.sellerId)) {
      return const SizedBox.shrink();
    }
    final allDone = _done.length == _steps.length;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: allDone ? AppColors.trustedBg : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: allDone
              ? AppColors.trusted.withValues(alpha: 0.5)
              : AppColors.unverified.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                allDone
                    ? Icons.verified_user_rounded
                    : Icons.checklist_rounded,
                size: 18,
                color: allDone ? AppColors.trusted : AppColors.unverified,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  allDone
                      ? t('You have completed all safety steps',
                          'तपाईंले सबै सुरक्षा चरण पूरा गर्नुभयो')
                      : t('Unverified Seller: Check These Before Paying',
                          'अप्रमाणित विक्रेता: भुक्तानी अघि यी जाँच्नुहोस्'),
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: allDone
                        ? AppColors.trusted
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              Text('${_done.length} ${t('of', '/')} ${_steps.length}',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: allDone
                        ? AppColors.trusted
                        : AppColors.unverified,
                  )),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _done.length / _steps.length,
              minHeight: 5,
              backgroundColor: AppColors.borderLight,
              color: allDone ? AppColors.trusted : AppColors.unverified,
            ),
          ),
          const SizedBox(height: 6),
          if (allDone)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                  t('You are better protected now.',
                      'अब तपाईं बढी सुरक्षित हुनुहुन्छ।'),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  )),
            )
          else
            ...List.generate(_steps.length, (i) {
              final checked = _done.contains(i);
              return InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    checked ? _done.remove(i) : _done.add(i);
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        checked
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 18,
                        color: checked
                            ? AppColors.trusted
                            : AppColors.grey400,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _steps[i],
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            height: 1.4,
                            color: checked
                                ? AppColors.textMuted
                                : AppColors.textPrimary,
                            decoration: checked
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                setState(() => _BeforeYouPayChecklist._dismissed
                    .add(widget.sellerId));
              },
              child: Text(
                  t('I understand the risks', 'मैले जोखिम बुझें'),
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  )),
            ),
          ),
        ],
      ),
    );
  }
}
