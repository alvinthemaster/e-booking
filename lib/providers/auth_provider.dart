import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  User? _currentUser;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  User? get currentUser => _currentUser;

  AuthProvider() {
    // Listen to auth state changes
    _firebaseAuth.authStateChanges().listen((User? user) {
      _currentUser = user;
      _isAuthenticated = user != null;
      notifyListeners();
    });
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    return await signInWithEmailAndPassword(email, password);
  }

  Future<bool> signUp(
    String email,
    String password,
    String name,
    String phone,
  ) async {
    return await signUpWithEmailAndPassword(email, password, name);
  }

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      final UserCredential result = await _firebaseAuth
          .signInWithEmailAndPassword(email: email.trim(), password: password);

      _currentUser = result.user;
      _isAuthenticated = result.user != null;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getReadableError(e.code));
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUpWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    _setLoading(true);
    _setError(null);

    try {
      final UserCredential result = await _firebaseAuth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );

      // Update display name
      await result.user?.updateDisplayName(name.trim());

      _currentUser = result.user;
      _isAuthenticated = result.user != null;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getReadableError(e.code));
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      _isAuthenticated = false;
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _setError(null);

    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getReadableError(e.code));
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  String _getReadableError(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'operation-not-allowed':
        return 'Signing in with email and password is not enabled.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
