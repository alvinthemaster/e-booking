import 'package:flutter/foundation.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider with ChangeNotifier {
  // final FirebaseAuth _auth = FirebaseAuth.instance;
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // User? _user;
  final bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;

  // User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;

  AuthProvider() {
    // TODO: Set up Firebase authentication
    // Listen to auth state changes
    // _auth.authStateChanges().listen((User? user) {
    //   _user = user;
    //   notifyListeners();
    // });
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
    try {
      _setLoading(true);
      _setError(null);

      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      _user = result.user;
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      switch (e.code) {
        case 'user-not-found':
          _setError('No user found with this email.');
          break;
        case 'wrong-password':
          _setError('Incorrect password.');
          break;
        case 'invalid-email':
          _setError('Invalid email format.');
          break;
        case 'user-disabled':
          _setError('This account has been disabled.');
          break;
        case 'too-many-requests':
          _setError('Too many failed login attempts. Please try again later.');
          break;
        default:
          _setError('Login failed. Please try again.');
      }
      return false;
    } catch (e) {
      _setLoading(false);
      _setError('An unexpected error occurred. Please try again.');
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String name, String phone) async {
    try {
      _setLoading(true);
      _setError(null);

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      _user = result.user;

      // Save additional user data to Firestore
      if (_user != null) {
        await _firestore.collection('users').doc(_user!.uid).set({
          'uid': _user!.uid,
          'email': email.trim(),
          'name': name.trim(),
          'phone': phone.trim(),
          'role': 'user', // Default role
          'createdAt': DateTime.now(),
          'isActive': true,
        });

        // Update display name
        await _user!.updateDisplayName(name.trim());
      }

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      switch (e.code) {
        case 'weak-password':
          _setError('Password is too weak. Please use at least 6 characters.');
          break;
        case 'email-already-in-use':
          _setError('An account already exists with this email.');
          break;
        case 'invalid-email':
          _setError('Invalid email format.');
          break;
        case 'operation-not-allowed':
          _setError('Email registration is not enabled.');
          break;
        default:
          _setError('Registration failed. Please try again.');
      }
      return false;
    } catch (e) {
      _setLoading(false);
      _setError('An unexpected error occurred. Please try again.');
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _setError(null);

      await _auth.sendPasswordResetEmail(email: email.trim());
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      switch (e.code) {
        case 'user-not-found':
          _setError('No user found with this email.');
          break;
        case 'invalid-email':
          _setError('Invalid email format.');
          break;
        default:
          _setError('Failed to send reset email. Please try again.');
      }
      return false;
    } catch (e) {
      _setLoading(false);
      _setError('An unexpected error occurred. Please try again.');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      _errorMessage = null;
    } catch (e) {
      _setError('Failed to sign out. Please try again.');
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    if (_user == null) return null;
    
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(_user!.uid).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}