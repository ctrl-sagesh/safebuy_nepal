import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/user_model.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/firestore_service.dart';

// ── Auth state machine ────────────────────────────────────────────────────────

enum AuthStatus {
  idle,
  sendingOtp,
  otpSent,
  verifying,
  verified,
  error,
}

class AuthState {
  const AuthState({
    this.status = AuthStatus.idle,
    this.verificationId,
    this.phone,
    this.errorMessage,
    this.credential,
  });

  final AuthStatus status;
  final String? verificationId;
  final String? phone;
  final String? errorMessage;
  final UserCredential? credential;

  AuthState copyWith({
    AuthStatus? status,
    String? verificationId,
    String? phone,
    String? errorMessage,
    UserCredential? credential,
  }) {
    return AuthState(
      status: status ?? this.status,
      verificationId: verificationId ?? this.verificationId,
      phone: phone ?? this.phone,
      errorMessage: errorMessage ?? this.errorMessage,
      credential: credential ?? this.credential,
    );
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

/// Stream of Firebase Auth user
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Current UserModel from Firestore
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authAsync = ref.watch(authStateProvider);
  return authAsync.when(
    data: (user) async {
      if (user == null) return null;
      try {
        return await ref
            .read(firestoreServiceProvider)
            .getUserById(user.uid);
      } catch (_) {
        return null;
      }
    },
    loading: () => null,
    error: (_, _) => null,
  );
});

/// Phone auth notifier
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(const AuthState());

  final Ref _ref;

  Future<void> sendOtp(String phone) async {
    state = state.copyWith(status: AuthStatus.sendingOtp, phone: phone);
    try {
      await _ref.read(authServiceProvider).verifyPhoneNumber(
            phone: phone,
            onCodeSent: (verificationId, _) {
              state = state.copyWith(
                status: AuthStatus.otpSent,
                verificationId: verificationId,
              );
            },
            onFailed: (error) {
              state = state.copyWith(
                status: AuthStatus.error,
                errorMessage: error,
              );
            },
            onAutoVerified: (credential) {
              state = state.copyWith(
                status: AuthStatus.verified,
                credential: credential,
              );
            },
          );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> verifyOtp(String otp) async {
    if (state.verificationId == null) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Verification ID missing. Please resend OTP.',
      );
      return false;
    }
    state = state.copyWith(status: AuthStatus.verifying);
    try {
      final uc = await _ref.read(authServiceProvider).confirmOTP(
            verificationId: state.verificationId!,
            otp: otp,
          );
      state = state.copyWith(
        status: AuthStatus.verified,
        credential: uc,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message ?? 'Invalid OTP. Please try again.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  void reset() {
    state = const AuthState();
  }
}
