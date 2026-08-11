import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'firebase_options.dart';

// Core
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/phone_extractor.dart';
import 'core/utils/popup_helper.dart';

// Screens
import 'features/splash/splash_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/auth/presentation/screens/auth_screen.dart';
import 'features/auth/presentation/screens/otp_screen.dart';
import 'features/auth/presentation/screens/profile_setup_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/search/presentation/screens/search_screen.dart';
import 'features/alerts/presentation/screens/alerts_screen.dart';
import 'features/alerts/presentation/screens/scam_news_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/sellers/presentation/screens/seller_profile_screen.dart';
import 'features/kyc/presentation/screens/kyc_intro_screen.dart';
import 'features/kyc/presentation/screens/kyc_gmail_screen.dart';
import 'features/kyc/presentation/screens/kyc_qr_screen.dart';
import 'features/kyc/presentation/screens/kyc_selfie_screen.dart';
import 'features/kyc/presentation/screens/kyc_pan_screen.dart';
import 'features/kyc/presentation/screens/kyc_location_screen.dart';
import 'features/kyc/presentation/screens/kyc_submitted_screen.dart';
import 'features/kyc/presentation/screens/verification_card_screen.dart';
import 'features/kyc/presentation/screens/qr_change_screen.dart';
import 'features/reports/presentation/screens/incident_report_screen.dart';
import 'features/reports/presentation/screens/report_success_screen.dart';
import 'features/reviews/presentation/screens/write_review_screen.dart';
import 'features/leaderboard/presentation/screens/leaderboard_screen.dart';
import 'features/guide/presentation/screens/how_it_works_screen.dart';
import 'features/legal/privacy_policy_screen.dart';
import 'features/legal/terms_screen.dart';
import 'features/legal/presentation/screens/cybercrime_report_screen.dart';
import 'features/profile/presentation/screens/about_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/stats/presentation/screens/nepal_fraud_stats_screen.dart';
import 'features/search/presentation/screens/share_result_screen.dart';
import 'features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'features/admin/presentation/screens/admin_kyc_screen.dart';
import 'screens/register_business_screen.dart';

// Services & agents
import 'services/notification_service.dart';
import 'agents/core/agent_registry.dart';
import 'agents/safeguard/safeguard_chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform);

  // Debug builds only: skip Play Integrity / reCAPTCHA app verification so
  // the Firebase TEST phone numbers (Console → Auth → Phone → test numbers)
  // work instantly on emulators and devices. Release builds are unaffected
  // and use full verification for real SMS.
  if (kDebugMode) {
    await FirebaseAuth.instance
        .setSettings(appVerificationDisabledForTesting: true);
  }

  // Quick Verify: if the app was cold-launched from another app's share
  // sheet (selected phone/handle), open straight into the result screen.
  bool sharedLaunch = false;
  String? initialShareQuery;
  try {
    final shared =
        await ReceiveSharingIntent.instance.getInitialMedia();
    for (final f in shared) {
      if (f.type == SharedMediaType.text || f.type == SharedMediaType.url) {
        sharedLaunch = true;
        initialShareQuery = PhoneExtractor.extract(f.path);
        break;
      }
    }
    if (sharedLaunch) {
      await ReceiveSharingIntent.instance.reset();
    }
  } catch (_) {
    sharedLaunch = false;
  }

  runApp(ProviderScope(
    child: SafeBuyApp(
      sharedLaunch: sharedLaunch,
      initialShareQuery: initialShareQuery,
    ),
  ));

  // Defer non-critical startup work so it never competes with the first
  // frames / splash navigation. Agents run in the background (no hub tab).
  Future.delayed(const Duration(milliseconds: 900), () {
    unawaited(AgentRegistry().initializeAll());
  });
  Future.delayed(const Duration(milliseconds: 3500), () {
    unawaited(NotificationService.initialize());
  });
}

class SafeBuyApp extends StatefulWidget {
  const SafeBuyApp({
    super.key,
    this.sharedLaunch = false,
    this.initialShareQuery,
  });

  /// True when the process was started by an incoming SEND (share) intent.
  final bool sharedLaunch;

  /// The extracted identifier from that share, if any.
  final String? initialShareQuery;

  @override
  State<SafeBuyApp> createState() => _SafeBuyAppState();
}

class _SafeBuyAppState extends State<SafeBuyApp> {
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
  StreamSubscription<List<SharedMediaFile>>? _shareSub;

  @override
  void initState() {
    super.initState();
    // Handle shares that arrive while the app is already running: push a
    // Quick Verify screen on top of whatever the user was looking at.
    _shareSub =
        ReceiveSharingIntent.instance.getMediaStream().listen((files) {
      for (final f in files) {
        if (f.type == SharedMediaType.text || f.type == SharedMediaType.url) {
          final query = PhoneExtractor.extract(f.path);
          _navKey.currentState?.push(MaterialPageRoute(
            builder: (_) => ShareResultScreen(initialQuery: query),
          ));
          break;
        }
      }
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _shareSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeBuy Nepal',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      navigatorKey: _navKey,
      home: widget.sharedLaunch
          ? ShareResultScreen(initialQuery: widget.initialShareQuery)
          : null,
      initialRoute: widget.sharedLaunch ? null : '/splash',
      onGenerateRoute: _onGenerateRoute,
    );
  }

  /// Slide-right page transition (250ms push, reversed on pop).
  static Route<dynamic> _route(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 250),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) {
        final offset = Tween<Offset>(
          begin: const Offset(0.06, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: animation.drive(offset),
            child: child,
          ),
        );
      },
    );
  }

  /// Routes that require a signed-in user.
  static const _protected = {
    '/report',
    '/cybercrime-report',
    '/register-business',
    '/kyc',
    '/kyc/gmail',
    '/kyc/qr',
    '/kyc/selfie',
    '/kyc/pan',
    '/kyc/location',
    '/kyc/change-qr',
  };

  static Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? '/';
    final args = settings.arguments as Map<String, dynamic>? ?? {};

    // Auth guard.
    if (_protected.contains(name) &&
        FirebaseAuth.instance.currentUser == null) {
      return _route(const _AuthGateRedirect(), settings);
    }

    switch (name) {
      case '/splash':
        return _route(const SplashScreen(), settings);
      case '/onboarding':
        return _route(const OnboardingScreen(), settings);
      case '/auth':
        return _route(const AuthScreen(), settings);
      case '/auth/otp':
        return _route(
            OtpScreen(phone: args['phone'] as String? ?? ''), settings);
      case '/auth/profile-setup':
        return _route(const ProfileSetupScreen(), settings);
      case '/home':
        return _route(const MainAppScreen(), settings);
      case '/search':
        return _route(const SearchScreen(autofocus: true), settings);
      case '/alerts':
        return _route(const AlertsScreen(), settings);
      case '/profile':
        return _route(const ProfileScreen(), settings);
      case '/seller':
        return _route(
            SellerProfileScreen(
                sellerId: args['sellerId'] as String? ?? ''),
            settings);
      case '/seller/card':
      case '/kyc/card':
        return _route(
            VerificationCardScreen(
                sellerId: args['sellerId'] as String? ?? ''),
            settings);
      case '/seller/review':
        return _route(
            WriteReviewScreen(
                sellerId: args['sellerId'] as String? ?? ''),
            settings);
      case '/report':
        return _route(
            IncidentReportScreen(
              sellerId: args['sellerId'] as String?,
              prefillPhone:
                  args['phone'] as String? ?? args['prefill'] as String?,
            ),
            settings);
      case '/cybercrime-report':
        return _route(
            CybercrimeReportScreen(
              reportId: args['reportId'] as String? ?? '',
              sellerId: args['sellerId'] as String? ?? '',
            ),
            settings);
      case '/report/success':
        return _route(
            ReportSuccessScreen(
              reportId: args['reportId'] as String? ?? '',
              sellerId: args['sellerId'] as String?,
            ),
            settings);
      case '/register-business':
        return _route(const RegisterBusinessScreen(), settings);
      case '/kyc':
        return _route(const KycIntroScreen(), settings);
      case '/kyc/gmail':
        return _route(const KycGmailScreen(), settings);
      case '/kyc/qr':
        return _route(const KycQrScreen(), settings);
      case '/kyc/selfie':
        return _route(const KycSelfieScreen(), settings);
      case '/kyc/pan':
        return _route(const KycPanScreen(), settings);
      case '/kyc/location':
        return _route(const KycLocationScreen(), settings);
      case '/kyc/submitted':
        return _route(const KycSubmittedScreen(), settings);
      case '/kyc/change-qr':
        return _route(
            QrChangeScreen(sellerId: args['sellerId'] as String? ?? ''),
            settings);
      case '/leaderboard':
        return _route(const LeaderboardScreen(), settings);
      case '/guide':
        return _route(const HowItWorksScreen(), settings);
      case '/nepal-stats':
        return _route(const NepalFraudStatsScreen(), settings);
      case '/scam-news':
        return _route(const ScamNewsScreen(), settings);
      case '/notifications':
        return _route(const NotificationsScreen(), settings);
      case '/privacy':
        return _route(const PrivacyPolicyScreen(), settings);
      case '/terms':
        return _route(const TermsScreen(), settings);
      case '/about':
        return _route(const AboutScreen(), settings);
      case '/admin':
      case '/admin/dashboard':
        return _route(const AdminDashboardScreen(), settings);
      case '/admin/kyc':
        return _route(const AdminKycScreen(), settings);
      case '/safeguard':
        return _route(const SafeguardChatScreen(), settings);
      default:
        return _route(const SplashScreen(), settings);
    }
  }
}

/// Shown when a guest hits a protected route: presents the auth-gate
/// sheet over a neutral background, then returns the user back.
class _AuthGateRedirect extends StatefulWidget {
  const _AuthGateRedirect();

  @override
  State<_AuthGateRedirect> createState() => _AuthGateRedirectState();
}

class _AuthGateRedirectState extends State<_AuthGateRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await PopupHelper.showAuthGateBottomSheet(context);
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: SizedBox.expand(),
    );
  }
}

// ── Bottom navigation shell: Home · Search · Alerts · Profile ─────────────────

class MainAppScreen extends ConsumerStatefulWidget {
  const MainAppScreen({super.key});

  @override
  ConsumerState<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends ConsumerState<MainAppScreen> {
  int _selectedIndex = 0;

  /// Set by the Home tab's example chips: switches to the Search tab
  /// with the query pre-filled and the search already running.
  final _searchRequest = ValueNotifier<String?>(null);

  @override
  void dispose() {
    _searchRequest.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onSearchTap: ([String? query]) {
          setState(() => _selectedIndex = 1);
          if (query != null && query.isNotEmpty) {
            _searchRequest.value = query;
          }
        },
      ),
      SearchScreen(searchRequest: _searchRequest),
      const AlertsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) {
            HapticFeedback.lightImpact();
            setState(() => _selectedIndex = i);
          },
          backgroundColor: Colors.white,
          elevation: 0,
          height: 64,
          indicatorColor: AppColors.primary.withValues(alpha: 0.12),
          labelBehavior:
              NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, size: 24),
              selectedIcon: _BounceIn(
                  child: Icon(Icons.home_rounded,
                      color: AppColors.primary, size: 24)),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.verified_user_outlined, size: 24),
              selectedIcon: _BounceIn(
                  child: Icon(Icons.verified_user_rounded,
                      color: AppColors.primary, size: 24)),
              label: 'Verify',
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_none_rounded, size: 24),
              selectedIcon: _BounceIn(
                  child: Icon(Icons.notifications_rounded,
                      color: AppColors.primary, size: 24)),
              label: 'Alerts',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded, size: 24),
              selectedIcon: _BounceIn(
                  child: Icon(Icons.person_rounded,
                      color: AppColors.primary, size: 24)),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

/// Springs the active nav icon up 4px when its tab is selected.
/// NavigationBar mounts the selectedIcon fresh on each selection, so the
/// bounce plays exactly once per tab switch.
class _BounceIn extends StatefulWidget {
  const _BounceIn({required this.child});

  final Widget child;

  @override
  State<_BounceIn> createState() => _BounceInState();
}

class _BounceInState extends State<_BounceIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = Curves.elasticOut.transform(_c.value);
        return Transform.translate(
          offset: Offset(0, -4 * (1 - t)),
          child: Transform.scale(scale: 0.85 + 0.15 * t, child: child),
        );
      },
      child: widget.child,
    );
  }
}
