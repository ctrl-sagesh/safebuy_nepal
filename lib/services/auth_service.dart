import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? getCurrentUser() => _auth.currentUser;

  /// Send OTP to a Nepal phone number (formatted as +977XXXXXXXXXX)
  Future<void> verifyPhoneNumber({
    required String phone,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String error) onFailed,
    required void Function(UserCredential credential) onAutoVerified,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: '+977$phone',
        timeout: const Duration(seconds: AppConstants.otpTimeoutSeconds),
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            final uc = await _auth.signInWithCredential(credential);
            onAutoVerified(uc);
          } catch (e) {
            onFailed(e.toString());
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          onFailed(e.message ?? e.code);
        },
        codeSent: onCodeSent,
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      onFailed(e.toString());
    }
  }

  /// Confirm OTP and sign in
  Future<UserCredential> confirmOTP({
    required String verificationId,
    required String otp,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );
    return await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {}
  }

  /// Anonymize Firestore data and delete Auth account.
  Future<void> deleteAccount(String userId) async {
    try {
      // Anonymize user document
      await _db.collection(AppConstants.colUsers).doc(userId).set({
        'isAnonymizedForDeletion': true,
        'phone': 'deleted',
        'fullName': 'Deleted User',
        'fcmToken': null,
      }, SetOptions(merge: true));

      // Delete Firebase Auth account
      await _auth.currentUser?.delete();
    } catch (e) {
      rethrow;
    }
  }
}
