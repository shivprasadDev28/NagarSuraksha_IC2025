import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _firebaseUser;
  AppUser? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;

  User? get firebaseUser => _firebaseUser;
  AppUser? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _firebaseUser != null;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    AuthService.authStateChanges.listen((User? user) {
      _firebaseUser = user;
      if (user != null) {
        _loadUserProfile();
      } else {
        _userProfile = null;
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserProfile() async {
    if (_firebaseUser != null) {
      try {
        _userProfile = await AuthService.getUserProfile();
        notifyListeners();
      } catch (e) {
        _errorMessage = e.toString();
        notifyListeners();
      }
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    String? location,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await AuthService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        location: location,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await AuthService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await AuthService.signOut();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await AuthService.resetPassword(email);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile(AppUser user) async {
    _setLoading(true);
    _clearError();

    try {
      await AuthService.updateUserProfile(user);
      _userProfile = user;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }
}
