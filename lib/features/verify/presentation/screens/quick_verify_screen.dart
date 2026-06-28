import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../utils/constants.dart' show AppColors;
import '../../../../services/firestore_service.dart';
import '../../../../models/seller_model.dart';
import '../../../../widgets/trust_badge_widget.dart';
import '../../../../screens/seller_profile_screen.dart';
import '../../../../screens/report_screen.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

const _kDarkBg = Color(0xFF0A1628);
const _kCardBg = Color(0xFF112240);
const _kCardBorder = Color(0xFF1E3A5F);
const _kGreenAccent = Color(0xFF00E676);
const _kCyanAccent = Color(0xFF00BCD4);
const _kAmberGlow = Color(0xFFFFAB00);

// ── Search Tab Enum ───────────────────────────────────────────────────────────

enum _SearchTab { phone, esewa, social }

extension _SearchTabX on _SearchTab {
  String get label {
    switch (this) {
      case _SearchTab.phone:
        return 'Phone';
      case _SearchTab.esewa:
        return 'eSewa ID';
      case _SearchTab.social:
        return 'Social Handle';
    }
  }

  IconData get icon {
    switch (this) {
      case _SearchTab.phone:
        return Icons.phone_android_rounded;
      case _SearchTab.esewa:
        return Icons.account_balance_wallet_rounded;
      case _SearchTab.social:
        return Icons.alternate_email_rounded;
    }
  }

  String get hint {
    switch (this) {
      case _SearchTab.phone:
        return '98XXXXXXXX';
      case _SearchTab.esewa:
        return 'eSewa ID or phone';
      case _SearchTab.social:
        return '@username';
    }
  }

  TextInputType get keyboardType {
    switch (this) {
      case _SearchTab.phone:
        return TextInputType.phone;
      case _SearchTab.esewa:
        return TextInputType.text;
      case _SearchTab.social:
        return TextInputType.text;
    }
  }
}

// ── Scan State ────────────────────────────────────────────────────────────────

enum _ScanPhase { idle, scanning, done }

// ── Recent Verification Model ─────────────────────────────────────────────────

class _RecentVerification {
  final String query;
  final String type;
  final String result;
  final Color resultColor;
  final String time;

  const _RecentVerification({
    required this.query,
    required this.type,
    required this.result,
    required this.resultColor,
    required this.time,
  });
}

final _recentVerifications = [
  _RecentVerification(
    query: '9841XXXXXX',
    type: 'Phone',
    result: 'Trusted',
    resultColor: const Color(AppColors.trusted),
    time: '2 min ago',
  ),
  _RecentVerification(
    query: '@fashion_np',
    type: 'Social',
    result: 'High Risk',
    resultColor: const Color(AppColors.highRisk),
    time: '15 min ago',
  ),
  _RecentVerification(
    query: '9812XXXXXX',
    type: 'eSewa',
    result: 'Unverified',
    resultColor: const Color(0xFFB5860D),
    time: '1 hr ago',
  ),
  _RecentVerification(
    query: '@gadgets_ktm',
    type: 'Social',
    result: 'Trusted',
    resultColor: const Color(AppColors.trusted),
    time: '3 hrs ago',
  ),
  _RecentVerification(
    query: '9867XXXXXX',
    type: 'Phone',
    result: 'No Record',
    resultColor: const Color(0xFF607D8B),
    time: '5 hrs ago',
  ),
];

// ── Main Screen ───────────────────────────────────────────────────────────────

class QuickVerifyScreen extends ConsumerStatefulWidget {
  const QuickVerifyScreen({super.key});

  @override
  ConsumerState<QuickVerifyScreen> createState() => _QuickVerifyScreenState();
}

class _QuickVerifyScreenState extends ConsumerState<QuickVerifyScreen>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  _SearchTab _activeTab = _SearchTab.phone;
  _ScanPhase _phase = _ScanPhase.idle;
  List<SellerModel> _results = [];
  String _scanStatus = '';
  String? _errorMessage;

  late AnimationController _pulseController;
  late AnimationController _scanRotationController;
  late AnimationController _gradientController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scanRotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _pulseController.dispose();
    _scanRotationController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  // ── Verify Logic ──────────────────────────────────────────────────────────

  Future<void> _onVerify() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    _focusNode.unfocus();
    setState(() {
      _phase = _ScanPhase.scanning;
      _results = [];
      _errorMessage = null;
      _scanStatus = 'Initializing secure connection...';
    });

    // Dramatic scanning sequence
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _scanStatus = 'Scanning databases...');

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _scanStatus = 'Cross-referencing reports...');

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final results = await firestoreService.searchSellers(query);

      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() => _scanStatus = 'Analyzing trust patterns...');

      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() {
        _results = results;
        _phase = _ScanPhase.done;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _ScanPhase.done;
        _errorMessage = 'Scan failed. Please try again.';
      });
    }
  }

  void _resetScan() {
    setState(() {
      _phase = _ScanPhase.idle;
      _results = [];
      _errorMessage = null;
      _controller.clear();
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kDarkBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(child: _buildHeader()),
            // Search area
            SliverToBoxAdapter(child: _buildSearchSection()),
            // Content based on phase
            if (_phase == _ScanPhase.scanning)
              SliverToBoxAdapter(child: _buildScanningAnimation()),
            if (_phase == _ScanPhase.done)
              SliverToBoxAdapter(child: _buildResults()),
            // Recent verifications
            if (_phase == _ScanPhase.idle)
              SliverToBoxAdapter(child: _buildRecentVerifications()),
            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _kCardBorder.withValues(alpha: 0.5),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white70,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _kGreenAccent.withValues(alpha: 0.2),
                  _kCyanAccent.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _kGreenAccent.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: _kGreenAccent,
              size: 24,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .shimmer(
                duration: 2000.ms,
                color: _kGreenAccent.withValues(alpha: 0.3),
              ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Verify',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Instant seller safety check',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          // Animated status dot
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, _) {
              return Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kGreenAccent
                      .withValues(alpha: 0.5 + _pulseController.value * 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: _kGreenAccent
                          .withValues(alpha: _pulseController.value * 0.6),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 4),
          Text(
            'LIVE',
            style: TextStyle(
              color: _kGreenAccent.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0);
  }

  // ── Search Section ────────────────────────────────────────────────────────

  Widget _buildSearchSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kCardBorder),
        boxShadow: [
          BoxShadow(
            color: _kGreenAccent.withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab switches
          _buildTabBar(),
          const SizedBox(height: 16),
          // Search input
          _buildSearchInput(),
          const SizedBox(height: 16),
          // Verify button
          _buildVerifyButton(),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 200.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _kDarkBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: _SearchTab.values.map((tab) {
          final isActive = tab == _activeTab;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _activeTab = tab;
                if (_phase == _ScanPhase.done) _resetScan();
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                decoration: BoxDecoration(
                  color: isActive ? _kCardBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  border: isActive
                      ? Border.all(
                          color: _kGreenAccent.withValues(alpha: 0.4))
                      : null,
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: _kGreenAccent.withValues(alpha: 0.15),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tab.icon,
                      size: 15,
                      color: isActive
                          ? _kGreenAccent
                          : Colors.white.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      tab.label,
                      style: TextStyle(
                        color: isActive
                            ? _kGreenAccent
                            : Colors.white.withValues(alpha: 0.4),
                        fontSize: 12,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                        letterSpacing: isActive ? 0.3 : 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchInput() {
    return Container(
      decoration: BoxDecoration(
        color: _kDarkBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _focusNode.hasFocus
              ? _kGreenAccent.withValues(alpha: 0.5)
              : _kCardBorder,
        ),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        keyboardType: _activeTab.keyboardType,
        style: const TextStyle(
          color: _kGreenAccent,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.0,
        ),
        cursorColor: _kGreenAccent,
        decoration: InputDecoration(
          hintText: _activeTab.hint,
          hintStyle: TextStyle(
            color: _kGreenAccent.withValues(alpha: 0.3),
            fontSize: 16,
            fontWeight: FontWeight.w400,
            letterSpacing: 1.0,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Icon(
              Icons.terminal_rounded,
              color: _kGreenAccent.withValues(alpha: 0.5),
              size: 20,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: Colors.white.withValues(alpha: 0.3),
                    size: 18,
                  ),
                  onPressed: () {
                    _controller.clear();
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _onVerify(),
      ),
    );
  }

  Widget _buildVerifyButton() {
    final isEnabled =
        _controller.text.trim().isNotEmpty && _phase != _ScanPhase.scanning;

    return AnimatedBuilder(
      animation: _gradientController,
      builder: (_, _) {
        final shimmerOffset = _gradientController.value;
        return GestureDetector(
          onTap: isEnabled ? _onVerify : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: isEnabled
                  ? LinearGradient(
                      begin: Alignment(-1.0 + shimmerOffset * 2, 0),
                      end: Alignment(1.0 + shimmerOffset * 2, 0),
                      colors: const [
                        Color(AppColors.gradStart),
                        _kGreenAccent,
                        Color(AppColors.gradEnd),
                        _kCyanAccent,
                      ],
                      stops: const [0.0, 0.3, 0.6, 1.0],
                    )
                  : null,
              color: isEnabled ? null : _kCardBorder.withValues(alpha: 0.5),
              boxShadow: isEnabled
                  ? [
                      BoxShadow(
                        color: _kGreenAccent.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified_user_rounded,
                  color: isEnabled
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.3),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'VERIFY NOW',
                  style: TextStyle(
                    color: isEnabled
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.3),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Scanning Animation ────────────────────────────────────────────────────

  Widget _buildScanningAnimation() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          // Rotating scanner ring
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer pulse ring
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, _) {
                    return Container(
                      width: 120 + (_pulseController.value * 20),
                      height: 120 + (_pulseController.value * 20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _kGreenAccent.withValues(
                              alpha: 0.2 - _pulseController.value * 0.15),
                          width: 1.5,
                        ),
                      ),
                    );
                  },
                ),
                // Rotating arc
                AnimatedBuilder(
                  animation: _scanRotationController,
                  builder: (_, _) {
                    return Transform.rotate(
                      angle: _scanRotationController.value * 2 * pi,
                      child: CustomPaint(
                        size: const Size(100, 100),
                        painter: _ScanArcPainter(
                          color: _kGreenAccent,
                          progress: _scanRotationController.value,
                        ),
                      ),
                    );
                  },
                ),
                // Center shield icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kCardBg,
                    border: Border.all(
                      color: _kGreenAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    color: _kGreenAccent,
                    size: 28,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.1, 1.1),
                      duration: 800.ms,
                    ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          // Scan status text
          Text(
            _scanStatus,
            style: TextStyle(
              color: _kGreenAccent.withValues(alpha: 0.9),
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fadeIn(duration: 600.ms)
              .then()
              .fadeOut(duration: 600.ms),
          const SizedBox(height: 12),
          // Animated dots
          _buildAnimatedDots(),
          const SizedBox(height: 20),
          // Progress bar
          Container(
            width: 200,
            height: 3,
            decoration: BoxDecoration(
              color: _kCardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
            child: AnimatedBuilder(
              animation: _scanRotationController,
              builder: (_, _) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _scanRotationController.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_kGreenAccent, _kCyanAccent],
                      ),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: _kGreenAccent.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildAnimatedDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _kGreenAccent.withValues(alpha: 0.7),
          ),
        )
            .animate(
              onPlay: (c) => c.repeat(reverse: true),
              delay: Duration(milliseconds: index * 200),
            )
            .scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1.2, 1.2),
              duration: 600.ms,
            )
            .fadeIn(duration: 400.ms);
      }),
    );
  }

  // ── Results ───────────────────────────────────────────────────────────────

  Widget _buildResults() {
    if (_errorMessage != null) {
      return _buildErrorCard();
    }
    if (_results.isEmpty) {
      return _buildNotFoundCard();
    }
    return Column(
      children: [
        for (final seller in _results) _buildSellerResultCard(seller),
        const SizedBox(height: 8),
        _buildScanAgainButton(),
      ],
    );
  }

  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(AppColors.highRisk).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: const Color(AppColors.highRisk).withValues(alpha: 0.8),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _buildScanAgainButton(),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildNotFoundCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kCardBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kDarkBg,
              border: Border.all(
                color: _kAmberGlow.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.search_off_rounded,
              color: _kAmberGlow.withValues(alpha: 0.8),
              size: 36,
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0.0, 0.0),
                end: const Offset(1.0, 1.0),
                duration: 500.ms,
                curve: Curves.elasticOut,
              ),
          const SizedBox(height: 20),
          const Text(
            'No Records Found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This seller is not in our database yet.\nBe the first to report or help others stay safe.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.flag_rounded,
                  label: 'Report Seller',
                  color: const Color(AppColors.highRisk),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ReportScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.replay_rounded,
                  label: 'Scan Again',
                  color: _kCyanAccent,
                  onTap: _resetScan,
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 100.ms)
        .slideY(begin: 0.15, end: 0);
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellerResultCard(SellerModel seller) {
    final trustColor = seller.trustScore >= 80
        ? const Color(AppColors.trusted)
        : seller.trustScore >= 50
            ? const Color(0xFFB5860D)
            : const Color(AppColors.highRisk);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: trustColor.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: trustColor.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Trust score circle + info
          Row(
            children: [
              // Animated trust score circle
              _buildTrustScoreCircle(seller.trustScore, trustColor),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      seller.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    TrustBadge(
                      trustVerdict: seller.trustVerdict,
                      large: true,
                    ),
                    const SizedBox(height: 10),
                    _buildInfoChip(
                      Icons.report_rounded,
                      '${seller.scamReportCount} reports',
                    ),
                    const SizedBox(height: 4),
                    _buildInfoChip(
                      Icons.star_rounded,
                      '${seller.reviewCount} reviews  |  ${seller.averageRating.toStringAsFixed(1)} avg',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Divider
          Container(
            height: 1,
            color: _kCardBorder.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            SellerProfileScreen(seller: seller),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          trustColor.withValues(alpha: 0.2),
                          trustColor.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: trustColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_rounded, color: trustColor, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'View Full Profile',
                          style: TextStyle(
                            color: trustColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ReportScreen(prefilledSeller: seller),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(AppColors.highRisk)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(AppColors.highRisk)
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.flag_rounded,
                    color: Color(AppColors.highRisk),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 200.ms)
        .slideY(begin: 0.2, end: 0)
        .scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildTrustScoreCircle(double score, Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: score),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (_, value, _) {
        return SizedBox(
          width: 90,
          height: 90,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background ring
              SizedBox(
                width: 90,
                height: 90,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 6,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(
                    _kCardBorder.withValues(alpha: 0.3),
                  ),
                ),
              ),
              // Score ring
              SizedBox(
                width: 90,
                height: 90,
                child: CircularProgressIndicator(
                  value: value / 100,
                  strokeWidth: 6,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(color),
                  strokeCap: StrokeCap.round,
                ),
              ),
              // Score text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value.toStringAsFixed(0),
                    style: TextStyle(
                      color: color,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '/100',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.4)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildScanAgainButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: _resetScan,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kCardBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.replay_rounded,
                color: _kCyanAccent.withValues(alpha: 0.8),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Scan Another',
                style: TextStyle(
                  color: _kCyanAccent.withValues(alpha: 0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 400.ms);
  }

  // ── Recent Verifications ──────────────────────────────────────────────────

  Widget _buildRecentVerifications() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history_rounded,
                color: Colors.white.withValues(alpha: 0.5),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Recent Verifications',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(_recentVerifications.length, (index) {
            final item = _recentVerifications[index];
            return _buildRecentItem(item, index);
          }),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 400.ms);
  }

  Widget _buildRecentItem(_RecentVerification item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _kCardBg.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kCardBorder.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.resultColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getTypeIcon(item.type),
              color: item.resultColor.withValues(alpha: 0.8),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.query,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.type}  ·  ${item.time}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: item.resultColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.result,
              style: TextStyle(
                color: item.resultColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 80))
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.1, end: 0);
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Phone':
        return Icons.phone_android_rounded;
      case 'eSewa':
        return Icons.account_balance_wallet_rounded;
      case 'Social':
        return Icons.alternate_email_rounded;
      default:
        return Icons.search_rounded;
    }
  }
}

// ── Custom Painter for Scan Arc ─────────────────────────────────────────────

class _ScanArcPainter extends CustomPainter {
  final Color color;
  final double progress;

  _ScanArcPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: pi * 2,
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.8),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);

    canvas.drawArc(rect, 0, pi * 1.5, false, paint);
  }

  @override
  bool shouldRepaint(_ScanArcPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
