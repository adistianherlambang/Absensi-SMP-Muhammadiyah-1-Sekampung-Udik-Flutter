import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _initialized = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  bool get initialized => _initialized;

  AuthProvider() {
    _init();
  }

  // Monitor status login Firebase
  void _init() {
    _authService.authStateChanges.listen((User? firebaseUser) async {
      _isLoading = true;
      notifyListeners();

      if (firebaseUser != null) {
        try {
          _currentUser = await _authService.getUserProfile(firebaseUser.uid);
        } catch (e) {
          _currentUser = null;
        }
      } else {
        _currentUser = null;
      }

      _isLoading = false;
      _initialized = true;
      notifyListeners();
    });
  }

  // Panggil login
  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final userCredential = await _authService.signInWithEmailAndPassword(email, password);
      if (userCredential.user != null) {
        _currentUser = await _authService.getUserProfile(userCredential.user!.uid);
        if (_currentUser == null) {
          // Jika data user tidak ada di database, lempar error
          await _authService.signOut();
          throw Exception("Profil pengguna tidak ditemukan di database.");
        }
      }
    } catch (e) {
      _currentUser = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Panggil logout
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _currentUser = null;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh profil pengguna
  Future<void> refreshProfile() async {
    if (_currentUser == null) return;
    try {
      final updated = await _authService.getUserProfile(_currentUser!.uid);
      if (updated != null) {
        _currentUser = updated;
        notifyListeners();
      }
    } catch (e) {
      // Abaikan jika gagal
    }
  }
}
