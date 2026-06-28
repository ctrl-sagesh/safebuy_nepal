import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

// Core
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';

// Legacy screens
import 'screens/home_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/language_screen.dart';
import 'screens/welcome_screen.dart';

// Feature screens
import 'features/auth/presentation/screens/onboarding_screen.dart';
import 'features/auth/presentation/screens/phone_auth_screen.dart';
import 'features/auth/presentation/screens/otp_verify_screen.dart';
import 'features/auth/presentation/screens/user_profile_setup_screen.dart';
import 'features/auth/presentation/screens/privacy_policy_screen.dart';
import 'features/auth/presentation/screens/terms_screen.dart';
import 'features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'features/news/presentation/screens/news_feed_screen.dart';
import 'features/verify/presentation/screens/quick_verify_screen.dart';
import 'features/splash/splash_screen.dart';
import 'features/notifications/notifications_screen.dart';

// Services
import 'services/notification_service.dart';

// Agents
import 'agents/core/agent_registry.dart';
import 'agents/safeguard/safeguard_chat_screen.dart';
import 'agents/agents_hub_screen.dart';

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

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final prefs = await SharedPreferences.getInstance();
  final isFirstLaunch = prefs.getString(AppConstants.prefLanguage) == null;
  final onboardingDone =
      prefs.getBool(AppConstants.prefOnboardingDone) ?? false;

  runApp(
    ProviderScope(
      child: SafeBuyApp(
        isFirstLaunch: isFirstLaunch,
        onboardingDone: onboardingDone,
      ),
    ),
  );

  // Defer non-critical startup work so it never competes with the first
  // frames / splash navigation.
  // NOTE: auto-seed is intentionally NOT called on launch — under the
  // locked-down production Firestore rules an unauthenticated client cannot
  // create seller docs, so it only produced endless rejected-write retries.
  // Demo data is seeded via the admin/debug dashboard or Firebase console.
  Future.delayed(const Duration(milliseconds: 900), () {
    unawaited(AgentRegistry().initializeAll());
  });
  Future.delayed(const Duration(milliseconds: 3500), () {
    unawaited(NotificationService.initialize());
  });
}

class SafeBuyApp extends StatelessWidget {
  const SafeBuyApp({
    super.key,
    required this.isFirstLaunch,
    required this.onboardingDone,
  });

  final bool isFirstLaunch;
  final bool onboardingDone;

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, _) => MaterialApp(
        title: 'SafeBuy Nepal',
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        initialRoute: _initialRoute,
        routes: {
          '/splash': (_) => const SplashScreen(),
          '/welcome': (_) => const WelcomeScreen(),
          '/language': (_) => const LanguageScreen(),
          '/onboarding': (_) => const OnboardingScreen(),
          '/auth': (_) => const PhoneAuthScreen(),
          '/home': (_) => const MainNavigation(),
          '/admin': (_) => const AdminDashboardScreen(),
          '/privacy': (_) => const PrivacyPolicyScreen(),
          '/terms': (_) => const TermsScreen(),
          '/agents': (_) => const AgentsHubScreen(),
          '/notifications': (_) => const NotificationsScreen(),
          '/setup-profile': (_) => const UserProfileSetupScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/verify-otp') {
            final args = settings.arguments as Map<String, dynamic>?;
            final phone = args?['phone'] as String? ?? '';
            return MaterialPageRoute(
              builder: (_) => OtpVerifyScreen(phone: phone),
            );
          }
          return null;
        },
      ),
    );
  }

  String get _initialRoute => '/splash';
}

// ── Bottom navigation shell ────────────────────────────────────────────────────

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _selectedIndex = 0;

  static const _screens = [
    HomeScreen(),
    QuickVerifyScreen(),
    NewsFeedScreen(),
    DashboardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        heroTag: 'safeguard_ai',
        backgroundColor: const Color(0xFF1565C0),
        tooltip: 'Ask SafeGuard AI',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SafeguardChatScreen()),
        ),
        child: const Icon(Icons.shield_rounded, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          backgroundColor: Colors.white,
          elevation: 0,
          height: 68,
          indicatorColor: const Color(0xFF1565C0).withValues(alpha: 0.1),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, size: 24),
              selectedIcon:
                  Icon(Icons.home_rounded, color: Color(0xFF1565C0), size: 24),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.verified_user_outlined, size: 24),
              selectedIcon: Icon(Icons.verified_user_rounded,
                  color: Color(0xFF1565C0), size: 24),
              label: 'Verify',
            ),
            NavigationDestination(
              icon: Icon(Icons.newspaper_outlined, size: 24),
              selectedIcon: Icon(Icons.newspaper_rounded,
                  color: Color(0xFF1565C0), size: 24),
              label: 'Alerts',
            ),
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, size: 24),
              selectedIcon: Icon(Icons.dashboard_rounded,
                  color: Color(0xFF1565C0), size: 24),
              label: 'Dashboard',
            ),
          ],
        ),
      ),
    );
  }
}
