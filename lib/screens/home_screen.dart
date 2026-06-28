import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/seller_model.dart';
import '../services/firestore_service.dart';
import '../utils/app_strings.dart';
import '../providers/language_provider.dart';
import '../widgets/seller_card_widget.dart';
import '../core/widgets/skeleton_loader.dart';
import '../core/widgets/empty_state_widget.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/auth_gate_sheet.dart';
import 'report_screen.dart';
import 'seller_profile_screen.dart';
import 'language_screen.dart';
import 'register_business_screen.dart';
import '../widgets/must_know_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  List<SellerModel> _searchResults = [];
  bool _isSearching = false;
  bool _searched = false;
  bool _isFocused = false;
  bool _isGuest = false;
  List<String> _searchHistory = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _searchFocusNode.addListener(() {
      setState(() => _isFocused = _searchFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(AppConstants.prefSearchHistory) ?? [];
    final guest = prefs.getBool('is_guest') ?? false;
    if (mounted) {
      setState(() {
        _searchHistory = history;
        _isGuest = guest;
      });
    }
  }

  Future<void> _saveToHistory(String query) async {
    if (query.isEmpty) return;
    final updated = [
      query,
      ..._searchHistory.where((s) => s != query),
    ].take(AppConstants.maxSearchHistory).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(AppConstants.prefSearchHistory, updated);
    if (mounted) setState(() => _searchHistory = updated);
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _searched = false;
        _searchResults = [];
      });
      return;
    }
    setState(() {}); // refresh hint
    _debounceTimer = Timer(
      const Duration(milliseconds: AppConstants.searchDebounceMs),
      () => _search(value.trim()),
    );
  }

  Future<void> _search([String? query]) async {
    final q = (query ?? _searchController.text).trim();
    if (q.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searched = false;
    });

    try {
      final results =
          await ref.read(firestoreServiceProvider).searchSellers(q);
      await _saveToHistory(q);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
          _searched = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searched = true;
        });
      }
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searched = false;
      _searchResults = [];
    });
  }

  /// Navigate, but gate guests into the sign-in sheet first.
  void _guardedNavigate(Widget screen, String feature) {
    if (_isGuest) {
      AuthGateSheet.show(context, feature: feature);
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    }
  }

  String _greeting(String lang) {
    final h = DateTime.now().hour;
    if (lang == 'ne') {
      if (h < 12) return 'शुभ प्रभात';
      if (h < 17) return 'शुभ दिन';
      return 'शुभ साँझ';
    }
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildTopBar(lang)),
            SliverToBoxAdapter(child: _buildHeroCard(lang)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isFocused && !_searched && _searchHistory.isNotEmpty)
                      _buildHistoryChips(),
                    if (_isFocused &&
                        _searchController.text.isNotEmpty &&
                        !_searched)
                      _buildSearchHint(),
                    if (_isSearching) ...[
                      const SizedBox(height: 8),
                      const SkeletonList(
                          count: 3, item: SellerCardSkeleton()),
                    ],
                    if (!_isSearching && _searched && _searchResults.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          children: [
                            _buildAINoResultsBanner(),
                            const SizedBox(height: 12),
                            EmptyStateWidget(
                              variant: EmptyVariant.noResults,
                              lang: lang,
                              actionLabel:
                                  AppStrings.get('report_this_seller', lang),
                              onAction: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const ReportScreen()),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (!_isSearching &&
                        _searched &&
                        _searchResults.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildAIResultBanner(_searchResults.first),
                      const SizedBox(height: 8),
                      ..._searchResults.map((seller) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: SellerCard(
                              seller: seller,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      SellerProfileScreen(seller: seller),
                                ),
                              ),
                            ),
                          )),
                    ],
                    if (!_searched) ...[
                      const SizedBox(height: 8),
                      _buildLiveAlertTicker()
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 12),
                      _buildMustKnowButton(lang)
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 50.ms)
                          .slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 12),
                      _buildAgentsHubButton(lang)
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 75.ms)
                          .slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 24),
                      _buildQuickActions(lang)
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 100.ms)
                          .slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 24),
                      _buildTrustMeter()
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 200.ms)
                          .slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 24),
                      _buildCommunityImpact(lang)
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 300.ms)
                          .slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 24),
                      _buildRecentScamTypes()
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 400.ms)
                          .slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 24),
                      _buildSafetyTips()
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 500.ms)
                          .slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 24),
                      _buildHowItWorks(lang)
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 600.ms)
                          .slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 40),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Top Bar (white)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTopBar(String lang) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          // Logo
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.shield_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Text(
            'SafeBuy Nepal',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          // Notification bell
          _circleButton(
            icon: Icons.notifications_outlined,
            onTap: () => Navigator.pushNamed(context, '/notifications'),
            badge: true,
          ),
          const SizedBox(width: 8),
          // Language toggle
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LanguageScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.bgPrimary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(lang == 'en' ? '🇬🇧' : '🇳🇵',
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    lang == 'en' ? 'EN' : 'ने',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    bool badge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.bgPrimary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: AppColors.textPrimary, size: 20),
            if (badge)
              Positioned(
                top: 9,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.highRisk,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.bgPrimary, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Hero Card (gradient) — greeting + stats + search
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeroCard(String lang) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.heroGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_greeting(lang)}! 👋',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_isGuest ? Icons.lock_outline : Icons.shield_rounded,
                          color: Colors.white, size: 13),
                      const SizedBox(width: 5),
                      Text(
                        _isGuest ? 'Guest Mode' : 'Protected',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Stat chips
            Row(
              children: [
                _statChip('1,247', 'Verified'),
                const SizedBox(width: 8),
                _statChip('389', 'Reports'),
                const SizedBox(width: 8),
                _statChip('₨2.1M', 'Saved'),
              ],
            ),
            const SizedBox(height: 16),
            // Embedded search bar
            _buildHeroSearch(lang),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSearch(String lang) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onSubmitted: (_) => _search(),
        onChanged: _onSearchChanged,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: AppStrings.get('search_hint', lang),
          hintStyle:
              const TextStyle(color: AppColors.textMuted, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.primary, size: 22),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  color: AppColors.textMuted,
                  onPressed: _clearSearch,
                )
              : Container(
                  margin: const EdgeInsets.all(7),
                  width: 36,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 18),
                ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildHistoryChips() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _searchHistory.map((term) {
          return ActionChip(
            avatar: const Icon(Icons.history, size: 14),
            label: Text(term, style: const TextStyle(fontSize: 12)),
            backgroundColor: AppColors.bgPrimary,
            side: const BorderSide(color: AppColors.borderLight),
            onPressed: () {
              _searchController.text = term;
              _search(term);
              _searchFocusNode.unfocus();
            },
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AI Search Helper — contextual hints
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSearchHint() {
    final query = _searchController.text.trim();
    String hint;
    String subHint;
    IconData icon;

    if (RegExp(r'^(97|98)\d*$').hasMatch(query)) {
      hint = '🔍 Searching by phone number';
      subHint = 'This will match eSewa and payment records';
      icon = Icons.phone_android_rounded;
    } else if (query.startsWith('@')) {
      hint = '🔍 Searching by social media handle';
      subHint = 'Checking TikTok, Instagram, and Facebook';
      icon = Icons.alternate_email_rounded;
    } else if (RegExp(r'^\d{10}$').hasMatch(query)) {
      hint = '🔍 Searching by eSewa/Khalti ID';
      subHint = 'Matching against payment identifiers';
      icon = Icons.account_balance_wallet_rounded;
    } else {
      hint = '🔍 Searching by business name';
      subHint = 'Try adding their phone number for better results';
      icon = Icons.store_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hint,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                  Text(subHint,
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary.withValues(alpha: 0.7))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAINoResultsBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.smart_toy_rounded,
                    color: AppColors.primary, size: 16),
              ),
              const SizedBox(width: 8),
              const Text('SafeGuard AI',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'I couldn\'t find this seller in our database. This could mean they\'re new and haven\'t been reported yet.',
            style: TextStyle(
                fontSize: 13, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 10),
          const Text('Safety tips before you pay:',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          _safetyBullet('Ask for a video call to verify their products'),
          _safetyBullet('Check their social media reviews and follower count'),
          _safetyBullet('Use Cash on Delivery whenever possible'),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _safetyBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ',
              style: TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w700)),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildAIResultBanner(SellerModel seller) {
    if (seller.trustVerdict == 'high_risk') {
      return _aiBanner(
        icon: Icons.warning_rounded,
        color: AppColors.highRisk,
        title: '⚠ SafeGuard Warning',
        body:
            'This seller has a high risk score with ${seller.scamReportCount} fraud reports. We strongly recommend not making payment.',
      );
    } else if (seller.trustVerdict == 'trusted') {
      return _aiBanner(
        icon: Icons.verified_rounded,
        color: AppColors.trusted,
        title: '✅ SafeGuard Verified',
        body:
            'This seller has a strong trust score based on ${seller.reviewCount} community reviews.',
      );
    }
    return const SizedBox.shrink();
  }

  Widget _aiBanner({
    required IconData icon,
    required Color color,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: color)),
                const SizedBox(height: 2),
                Text(body,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Live alert ticker
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLiveAlertTicker() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.unverified.withValues(alpha: 0.1),
            AppColors.unverified.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.unverified.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.unverified.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.notifications_active_rounded,
                color: AppColors.unverified, size: 20),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1, end: 1.12, duration: 800.ms),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.highRisk,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('LIVE',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1)),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('3 active scam alerts in your area',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.textPrimary)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'New fraud reports in Kathmandu Valley today. Always verify before sending advance payment.',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Must-Know & Agents buttons
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMustKnowButton(String lang) {
    final isNe = lang == 'ne';
    return _infoTile(
      onTap: () => MustKnowSheet.show(context, lang: lang),
      icon: Icons.info_outline_rounded,
      color: const Color(0xFF7C4DFF),
      title: isNe ? 'जान्नैपर्ने कुराहरू' : 'Must Know Information',
      subtitle: isNe
          ? 'एन्टी-बोट सुरक्षा, विश्वास स्कोर र प्लेटफर्म रणनीति'
          : 'Anti-bot protection, trust scoring and platform strategy',
    );
  }

  Widget _buildAgentsHubButton(String lang) {
    return _infoTile(
      onTap: () => Navigator.pushNamed(context, '/agents'),
      icon: Icons.smart_toy_outlined,
      color: AppColors.primary,
      title: 'AI Agent System',
      subtitle: lang == 'ne'
          ? '4 बुद्धिमान agent हरूले तपाईंलाई सुरक्षित राख्छन्'
          : '4 intelligent agents protecting your purchases',
    );
  }

  Widget _infoTile({
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgPrimary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.textMuted, size: 14),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Quick Actions
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildQuickActions(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(AppStrings.get('quick_actions', lang)),
        const SizedBox(height: 14),
        Row(
          children: [
            _actionCard(
              icon: Icons.verified_user_rounded,
              label: AppStrings.get('search_seller', lang),
              gradient: const [Color(0xFF1565C0), Color(0xFF42A5F5)],
              onTap: () =>
                  FocusScope.of(context).requestFocus(_searchFocusNode),
            ),
            const SizedBox(width: 12),
            _actionCard(
              icon: Icons.report_problem_rounded,
              label: AppStrings.get('report_fraud', lang),
              gradient: const [Color(0xFFD32F2F), Color(0xFFF44336)],
              onTap: () => _guardedNavigate(
                  const ReportScreen(), 'report a fraudulent seller'),
            ),
            const SizedBox(width: 12),
            _actionCard(
              icon: Icons.storefront_rounded,
              label: AppStrings.get('register_business', lang),
              gradient: const [Color(0xFF00C853), Color(0xFF00E676)],
              onTap: () => _guardedNavigate(
                  const RegisterBusinessScreen(), 'register your business'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradient[0].withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Nepal Trust Index (white card)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTrustMeter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _whiteCard(),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.insights_rounded,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('Nepal Trust Index',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.textPrimary)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.trusted.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('LIVE',
                    style: TextStyle(
                        color: AppColors.trusted,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _trustMeterItem('58%', 'Trusted', AppColors.trusted),
              _trustMeterDivider(),
              _trustMeterItem('29%', 'Unverified', AppColors.unverified),
              _trustMeterDivider(),
              _trustMeterItem('13%', 'High Risk', AppColors.highRisk),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                Expanded(
                    flex: 58,
                    child: Container(height: 8, color: AppColors.trusted)),
                Expanded(
                    flex: 29,
                    child: Container(height: 8, color: AppColors.unverified)),
                Expanded(
                    flex: 13,
                    child: Container(height: 8, color: AppColors.highRisk)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text('Based on 1,247 verified sellers across Nepal',
              style:
                  TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _trustMeterItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontFamily: 'Poppins',
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }

  Widget _trustMeterDivider() {
    return Container(width: 1, height: 40, color: AppColors.borderLight);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Community Impact
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCommunityImpact(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Community Impact'),
        const SizedBox(height: 14),
        Row(
          children: [
            _impactCard('1,247', 'Sellers\nVerified',
                Icons.verified_user_rounded, AppColors.primary),
            const SizedBox(width: 10),
            _impactCard('389', 'Scam\nReports',
                Icons.report_problem_rounded, AppColors.highRisk),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _impactCard('₨2.1M', 'Scams\nPrevented', Icons.savings_rounded,
                AppColors.trusted),
            const SizedBox(width: 10),
            _impactCard('5,432', 'Active\nUsers', Icons.people_rounded,
                const Color(0xFF7B1FA2)),
          ],
        ),
      ],
    );
  }

  Widget _impactCard(
      String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _whiteCard(),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: color)),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          height: 1.3)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Trending Scam Types
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRecentScamTypes() {
    final scamTypes = [
      ('No Delivery', 0.35, AppColors.highRisk),
      ('Fake Products', 0.28, const Color(0xFFFF6D00)),
      ('Payment Fraud', 0.20, AppColors.unverified),
      ('Impersonation', 0.12, const Color(0xFF7B1FA2)),
      ('Other', 0.05, AppColors.textMuted),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _whiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.highRisk.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.pie_chart_rounded,
                    color: AppColors.highRisk, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('Trending Scam Types',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 18),
          ...scamTypes.map((t) => _scamTypeBar(t.$1, t.$2, t.$3)),
        ],
      ),
    );
  }

  Widget _scamTypeBar(String label, double percent, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ),
              Text('${(percent * 100).toInt()}%',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: color)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Safety Tips carousel
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSafetyTips() {
    final tips = [
      (
        'Verify Before You Pay',
        'Always check the seller\'s trust score on SafeBuy before sending money',
        Icons.verified_user_rounded,
        const [Color(0xFF1565C0), Color(0xFF42A5F5)],
      ),
      (
        'Never Share OTP',
        'No legitimate seller will ever ask for your OTP or banking PIN',
        Icons.lock_rounded,
        const [Color(0xFFD32F2F), Color(0xFFF44336)],
      ),
      (
        'Use COD When Possible',
        'Cash on Delivery protects you from advance payment scams',
        Icons.local_shipping_rounded,
        const [Color(0xFF00C853), Color(0xFF00E676)],
      ),
      (
        'Report Suspicious Activity',
        'Your report helps protect thousands of other buyers',
        Icons.flag_rounded,
        const [Color(0xFFFF8F00), Color(0xFFFFB300)],
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Stay Safe'),
        const SizedBox(height: 14),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tips.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final tip = tips[i];
              return Container(
                width: 260,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: tip.$4,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: tip.$4[0].withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(tip.$3, color: Colors.white, size: 22),
                    ),
                    const SizedBox(height: 12),
                    Text(tip.$1,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(tip.$2,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                            height: 1.4),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // How It Works
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHowItWorks(String lang) {
    final steps = [
      (
        'Search Seller',
        'Enter phone, eSewa ID, or social handle',
        Icons.search_rounded,
        AppColors.primary,
      ),
      (
        'Check Trust Score',
        'See verified ratings and scam reports',
        Icons.shield_rounded,
        AppColors.trusted,
      ),
      (
        'Buy with Confidence',
        'Make informed decisions, stay safe',
        Icons.thumb_up_alt_rounded,
        const Color(0xFF7B1FA2),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _whiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How It Works',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 18),
          ...steps.asMap().entries.map((e) {
            final isLast = e.key == steps.length - 1;
            final step = e.value;
            return Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          step.$4,
                          step.$4.withValues(alpha: 0.7),
                        ]),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text('${e.key + 1}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18)),
                    ),
                    const SizedBox(width: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: step.$4.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(step.$3, color: step.$4, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(step.$1,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 2),
                          Text(step.$2,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!isLast)
                  Padding(
                    padding: const EdgeInsets.only(left: 21),
                    child: Container(
                      width: 2,
                      height: 24,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.borderLight,
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Shared helpers
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: AppColors.textPrimary,
      ),
    );
  }

  BoxDecoration _whiteCard() {
    return BoxDecoration(
      color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.borderLight),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadowColor,
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
