import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Google sign-in — used both for "Continue with Google" auth and for
/// linking a Gmail account during seller KYC. Uses the google_sign_in v7 API.
class GoogleAuthService {
  GoogleAuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  static bool _initialized = false;

  Future<GoogleSignIn> _signIn() async {
    final instance = GoogleSignIn.instance;
    if (!_initialized) {
      await instance.initialize();
      _initialized = true;
    }
    return instance;
  }

  /// Full Firebase sign-in with Google. Returns null if the user cancelled.
  Future<UserCredential?> signInWithGoogle() async {
    final google = await _signIn();
    GoogleSignInAccount account;
    try {
      account = await google.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw Exception('Google sign-in returned no ID token');
    }
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    return _auth.signInWithCredential(credential);
  }

  /// Lightweight Gmail link for KYC — returns the Gmail address only,
  /// without switching the Firebase auth session. Null if cancelled.
  Future<String?> linkGmailAccount() async {
    final google = await _signIn();
    try {
      // Sign out of the Google session first so the account picker shows.
      await google.signOut();
    } catch (_) {}
    try {
      final account = await google.authenticate();
      return account.email;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      final google = await _signIn();
      await google.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}
