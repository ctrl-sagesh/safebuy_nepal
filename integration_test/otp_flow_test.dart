// Live OTP integration test — runs on a real device/emulator against the
// REAL Firebase project, using the Console-configured TEST phone number:
//   +977 9876543210 · verification code 123456
//
// Run with:
//   flutter test integration_test/otp_flow_test.dart -d <device-id>
//
// This proves end-to-end:
//   1. Phone number formatting is correct (+977 added exactly once)
//   2. App verification bypass works in debug (no Play Integrity needed)
//   3. codeSent fires and the OTP 123456 signs the user in
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:safebuy_nepal/firebase_options.dart';
import 'package:safebuy_nepal/services/auth_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Firebase test-number OTP flow signs in successfully',
      (tester) async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    // Same setting the debug app uses in main().
    await FirebaseAuth.instance
        .setSettings(appVerificationDisabledForTesting: true);
    await FirebaseAuth.instance.signOut();

    final service = AuthService();
    final codeSentCompleter = Completer<String>();
    String? failure;

    await service.verifyPhoneNumber(
      phone: '9876543210', // bare number — service adds +977
      onCodeSent: (verificationId, _) {
        if (!codeSentCompleter.isCompleted) {
          codeSentCompleter.complete(verificationId);
        }
      },
      onFailed: (error) {
        failure = error;
        if (!codeSentCompleter.isCompleted) {
          codeSentCompleter.completeError(error);
        }
      },
      onAutoVerified: (_) {},
    );

    final verificationId = await codeSentCompleter.future
        .timeout(const Duration(seconds: 45));
    expect(failure, isNull,
        reason: 'verifyPhoneNumber reported: $failure');
    expect(verificationId, isNotEmpty);

    final credential = await service.confirmOTP(
      verificationId: verificationId,
      otp: '123456',
    );

    expect(credential.user, isNotNull);
    expect(credential.user!.phoneNumber, '+9779876543210');

    // Leave no session behind.
    await FirebaseAuth.instance.signOut();
  });
}
