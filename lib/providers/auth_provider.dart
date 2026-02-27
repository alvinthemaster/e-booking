import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Lazy getter – avoids web timing issues where Firestore plugin isn't
  // registered yet if accessed as a field initializer.
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  User? _currentUser;
  bool _emailVerificationSent = false;
  bool _hasSignedIn = false; // Track if user has successfully signed in

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  User? get currentUser => _currentUser;
  bool get emailVerificationSent => _emailVerificationSent;
  bool get requiresEmailVerification => _currentUser != null && !_currentUser!.emailVerified;

  AuthProvider() {
    // Listen to auth state changes
    _firebaseAuth.authStateChanges().listen((User? user) {
      _currentUser = user;
      
      if (user == null) {
        // User is signed out
        _isAuthenticated = false;
        _hasSignedIn = false;
      } else {
        // Only mark authenticated if email has been verified
        _isAuthenticated = user.emailVerified;
        if (user.emailVerified && !_hasSignedIn) {
          _hasSignedIn = true;
        }
      }
      
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

  void _setEmailVerificationSent(bool sent) {
    _emailVerificationSent = sent;
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
    return await signUpWithEmailAndPassword(email, password, name, phone);
  }

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      final UserCredential result = await _firebaseAuth
          .signInWithEmailAndPassword(email: email.trim(), password: password);

      final user = result.user;
      if (user != null && !user.emailVerified) {
        // Sign out immediately — unverified users must verify first
        await _firebaseAuth.signOut();
        _setError('Please verify your email before signing in. Check your inbox for the verification link.');
        return false;
      }

      _currentUser = user;
      _isAuthenticated = user != null;
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
    String phone,
  ) async {
    _setLoading(true);
    _setError(null);

    try {
      final UserCredential result = await _firebaseAuth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );

      final user = result.user;
      if (user == null) throw Exception('Account creation failed.');

      // Update display name
      await user.updateDisplayName(name.trim());

      // Save user profile to Firestore users collection.
      // Wrapped in its own try/catch so a Firestore failure never
      // crashes the signup – the user can still verify their email.
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name.trim(),
          'email': email.trim(),
          'phone': phone.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'emailVerified': false,
        });
      } catch (firestoreError) {
        debugPrint('⚠️ Firestore user save failed: $firestoreError');
      }

      // Send email verification
      debugPrint('📧 Attempting to send verification email to: ${email.trim()}');
      try {
        await user.sendEmailVerification();
        debugPrint('✅ Email verification sent successfully');
        _setEmailVerificationSent(true);
      } catch (emailError) {
        debugPrint('❌ Failed to send verification email: $emailError');
        _setError('Account created but failed to send verification email. Please try resending from the verification screen.');
      }

      // Keep the Firebase Auth user signed in so the verification screen
      // can poll checkEmailVerification(), but do NOT mark as authenticated
      // until the email is actually verified.
      _currentUser = user;
      _isAuthenticated = false; // not verified yet
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

  Future<bool> sendEmailVerification() async {
    _setLoading(true);
    _setError(null);

    try {
      if (_currentUser != null && !_currentUser!.emailVerified) {
        await _currentUser!.sendEmailVerification();
        _setEmailVerificationSent(true);
        return true;
      }
      return false;
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

  Future<bool> checkEmailVerification() async {
    try {
      await _currentUser?.reload();
      _currentUser = _firebaseAuth.currentUser;
      final verified = _currentUser?.emailVerified ?? false;
      if (verified) {
        // Update Firestore to reflect verified status
        try {
          await _firestore.collection('users').doc(_currentUser!.uid).update({
            'emailVerified': true,
          });
        } catch (_) {}
        _isAuthenticated = true;
        _hasSignedIn = true;
      }
      notifyListeners();
      return verified;
    } catch (e) {
      _setError(e.toString());
      return false;
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
      case 'email-not-verified':
        return 'Please verify your email before signing in.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
