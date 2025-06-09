import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _userProfile;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  Map<String, dynamic>? get userProfile => _userProfile;

  // NEW: Get user type and status
  String get userType => _userProfile?['user_type'] ?? 'CLIENT';
  String get userStatus => _userProfile?['user_status'] ?? 'active';
  bool get isAdmin => userType == 'ADMIN';
  bool get isAccountActive => userStatus == 'active';

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    _user = _authService.currentUser;

    // Load user profile if authenticated
    if (_user != null) {
      _loadUserProfile();
    }

    // Listen to auth state changes
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      if (user != null) {
        _loadUserProfile();
      } else {
        _userProfile = null;
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserProfile() async {
    try {
      _userProfile = await _databaseService.getUserProfile();

      // Update last active when profile is loaded
      if (_userProfile != null) {
        _databaseService.updateUserLastActive();
      }

      notifyListeners();
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      if (user != null) {
        _user = user;
        await _loadUserProfile();

        // Check if account is active
        if (!isAccountActive) {
          await signOut();
          _setError('Your account has been suspended. Please contact support.');
          return false;
        }

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // UPDATED: Enhanced signup with all required fields
  Future<bool> signUp(
      String email,
      String password,
      String fullName, {
        String preferredLanguage = 'en',
        Map<String, dynamic>? notificationPreferences,
      }) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
      );

      if (user != null) {
        _user = user;

        // Create user profile in Supabase with all new fields
        await _databaseService.createUserProfile(
          firebaseUid: user.uid,
          email: email,
          fullName: fullName,
          userType: 'CLIENT', // Default to CLIENT
          preferredLanguage: preferredLanguage,
          notificationPreferences: notificationPreferences ?? {
            'email': true,
            'push': true,
          },
        );

        await _loadUserProfile();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.signOut();
      _user = null;
      _userProfile = null;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.resetPassword(email);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // UPDATED: Enhanced profile update with new fields
  Future<void> updateProfile({
    required String fullName,
    String? phoneNumber,
    String? avatarUrl,
    String? preferredLanguage,
    Map<String, dynamic>? notificationPreferences,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Update Firebase Auth display name
      await _authService.updateUserDisplayName(fullName);

      // Update Supabase profile with all new fields
      await _databaseService.updateUserProfile(
        fullName: fullName,
        phoneNumber: phoneNumber,
        avatarUrl: avatarUrl,
        preferredLanguage: preferredLanguage,
        notificationPreferences: notificationPreferences,
      );

      // Reload profile
      await _loadUserProfile();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // NEW: Update notification preferences
  Future<void> updateNotificationPreferences(Map<String, dynamic> preferences) async {
    _setLoading(true);
    _clearError();

    try {
      await _databaseService.updateUserProfile(
        notificationPreferences: preferences,
      );

      // Reload profile
      await _loadUserProfile();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // NEW: Update preferred language
  Future<void> updatePreferredLanguage(String language) async {
    _setLoading(true);
    _clearError();

    try {
      await _databaseService.updateUserProfile(
        preferredLanguage: language,
      );

      // Reload profile
      await _loadUserProfile();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Re-authenticate user before sensitive operations
  Future<bool> reauthenticate(String password) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.reauthenticateWithPassword(password);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // FIXED: Account deletion with re-authentication
  Future<bool> deleteAccount(String password) async {
    _setLoading(true);
    _clearError();

    try {
      if (_user == null) {
        throw 'No user is currently signed in';
      }

      // Step 1: Re-authenticate the user first
      await _authService.reauthenticateWithPassword(password);

      // Step 2: Delete user data from Supabase
      await _databaseService.deleteUserAccount();

      // Step 3: Delete the Firebase user account (now that we're re-authenticated)
      await _authService.deleteUserAccount();

      // Step 4: Clear local state
      _user = null;
      _userProfile = null;
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Failed to delete account: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // NEW: Check account status
  Future<bool> checkAccountStatus() async {
    try {
      final statusInfo = await _databaseService.getUserStatusAndType();
      if (statusInfo != null) {
        final status = statusInfo['user_status'];
        if (status != 'active') {
          await signOut();
          _setError('Your account has been ${status}. Please contact support.');
          return false;
        }
      }
      return true;
    } catch (e) {
      print('Error checking account status: $e');
      return true; // Don't block user if check fails
    }
  }

  // NEW: Get user preferences safely
  Map<String, dynamic> getNotificationPreferences() {
    return _userProfile?['notification_preferences'] ?? {
      'email': true,
      'push': true,
    };
  }

  String getPreferredLanguage() {
    return _userProfile?['preferred_language'] ?? 'en';
  }

  DateTime? getLastActiveTime() {
    final lastActiveStr = _userProfile?['last_active'];
    if (lastActiveStr != null) {
      return DateTime.tryParse(lastActiveStr);
    }
    return null;
  }

  DateTime? getAccountCreatedTime() {
    final createdAtStr = _userProfile?['created_at'];
    if (createdAtStr != null) {
      return DateTime.tryParse(createdAtStr);
    }
    return null;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
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