import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Very small Firebase email/password auth wrapper.
class AuthService extends ChangeNotifier {
  // Private named constructor
  AuthService._internal() {
    // Whenever Firebase auth state changes, notify listeners
    _auth.authStateChanges().listen((_) => notifyListeners());
  }

  /// Singleton instance used everywhere (router, UI, etc.).
  static final AuthService instance = AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Currently signed-in Firebase user (or null).
  User? get currentUser => _auth.currentUser;

  /// Returns `null` on success, or an error message string on failure.
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Sign in failed';
    } catch (_) {
      return 'Sign in failed';
    }
  }

  /// Returns `null` on success, or an error message string on failure.
  Future<String?> signUp({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Sign up failed';
    } catch (_) {
      return 'Sign up failed';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
