// Smoke tests for the rebuilt screens that don't require Firebase.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:safebuy_nepal/core/data/nepal_scam_data.dart';
import 'package:safebuy_nepal/core/utils/validators.dart';
import 'package:safebuy_nepal/features/alerts/presentation/screens/scam_news_screen.dart';
import 'package:safebuy_nepal/features/guide/presentation/screens/how_it_works_screen.dart';
import 'package:safebuy_nepal/features/legal/privacy_policy_screen.dart';
import 'package:safebuy_nepal/features/legal/terms_screen.dart';
import 'package:safebuy_nepal/features/onboarding/onboarding_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Screen smoke tests', () {
    testWidgets('Onboarding renders slide 1 with guide steps',
        (tester) async {
      await tester
          .pumpWidget(const MaterialApp(home: OnboardingScreen()));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Verify Any Seller Instantly'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('How It Works shows three tabs', (tester) async {
      await tester
          .pumpWidget(const MaterialApp(home: HowItWorksScreen()));
      await tester.pumpAndSettle();
      expect(find.text('For Buyers'), findsOneWidget);
      expect(find.text('For Sellers'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('Scam news shows the three tabs', (tester) async {
      await tester
          .pumpWidget(const MaterialApp(home: ScamNewsScreen()));
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('Cases'), findsOneWidget);
      expect(find.text('Statistics'), findsWidgets);
      expect(find.text('Your Rights'), findsOneWidget);
      expect(find.text('Scam Reports Nepal'), findsOneWidget);
    });

    testWidgets('Privacy policy renders opening sections',
        (tester) async {
      await tester
          .pumpWidget(const MaterialApp(home: PrivacyPolicyScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('1. Who We Are'), findsOneWidget);
    });

    testWidgets('Terms of service renders opening sections',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: TermsScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.text('1. Acceptance of Terms'), findsOneWidget);
    });
  });

  group('Scam data integrity', () {
    test('has 10 documented cases with required fields', () {
      expect(NepalScamNewsData.scamCases.length, 10);
      for (final c in NepalScamNewsData.scamCases) {
        expect(c['headline'], isNotEmpty);
        expect(c['body'], isNotEmpty);
        expect(c['source'], isNotEmpty);
        expect(c['lesson'], isNotEmpty);
      }
    });

    test('has 6 statistics and 5 legal entries', () {
      expect(NepalScamNewsData.scamStats.length, 6);
      expect(NepalScamNewsData.legalFramework.length, 5);
    });
  });

  group('New validators', () {
    test('PAN number requires exactly 9 digits', () {
      expect(Validators.panNumber('123456789'), isNull);
      expect(Validators.panNumber('12345678'), isNotNull);
      expect(Validators.panNumber('1234567890'), isNotNull);
      expect(Validators.panNumber('12345678a'), isNotNull);
      expect(Validators.panNumber(''), isNotNull);
    });

    test('Gmail validator accepts only gmail.com', () {
      expect(Validators.gmail('shop@gmail.com'), isNull);
      expect(Validators.gmail('shop@yahoo.com'), isNotNull);
      expect(Validators.gmail(''), isNotNull);
    });

    test('OTP requires all 6 digits', () {
      expect(Validators.otp('123456'), isNull);
      expect(Validators.otp('12345'), isNotNull);
      expect(Validators.otp('12345a'), isNotNull);
    });

    test('Social handle rejects spaces', () {
      expect(Validators.socialHandle('seller_np'), isNull);
      expect(Validators.socialHandle('seller np'), isNotNull);
      expect(Validators.socialHandle(''), isNull); // optional
    });
  });
}
