import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/fcm_service.dart';
import '../utils/philippine_time.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _userProfile;
  bool _isInitialized = false;

  // Notification state management
  List<Map<String, dynamic>> _notifications = [];
  Map<String, dynamic> _notificationStats = {};
  bool _notificationsLoading = false;
  DateTime? _lastNotificationCheck;

  // Basic getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isInitialized => _isInitialized;
  Map<String, dynamic>? get userProfile => _userProfile;

  // User type and status getters
  String get userType => _userProfile?['user_type'] ?? 'CLIENT';
  String get userStatus => _userProfile?['user_status'] ?? 'active';
  bool get isAdmin => userType == 'ADMIN';
  bool get isClient => userType == 'CLIENT';
  bool get isAccountActive => userStatus == 'active';
  String? get currentUserId => _user?.uid;

  // Notification getters
  List<Map<String, dynamic>> get notifications => _notifications;
  Map<String, dynamic> get notificationStats => _notificationStats;
  bool get notificationsLoading => _notificationsLoading;
  int get unreadNotificationCount => _notificationStats['unread_notifications'] ?? 0;
  int get urgentNotificationCount => _notificationStats['urgent_notifications'] ?? 0;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() async {
    try {
      print('🚀 Initializing AuthProvider...');
      _user = _authService.currentUser;
      if (_user != null) {
        print('✅ Found existing user: ${_user!.uid}');
        await _loadUserProfile();
        await _loadNotifications();
        await _updateLastActive();
      } else {
        print('❌ No existing user found');
        _userProfile = null;
        _clearNotifications();
      }

      _isInitialized = true;
      notifyListeners();
      print('✅ AuthProvider initialization complete');

      _authService.authStateChanges.listen((User? user) {
        _handleAuthStateChange(user);
      });
    } catch (e) {
      print('❌ Error during AuthProvider initialization: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _handleAuthStateChange(User? user) async {
    if (user?.uid == _user?.uid) return;

    _user = user;
    _errorMessage = null;

    if (user != null) {
      print('✅ User signed in: ${user.uid}');
      await _loadUserProfile();
      await _loadNotifications();
      await _updateLastActive();
    } else {
      print('❌ User signed out');
      _userProfile = null;
      _clearNotifications();
    }

    if (!_isInitialized) {
      _isInitialized = true;
    }
    notifyListeners();
  }

  Future<void> _loadUserProfile() async {
    try {
      _userProfile = await _databaseService.getUserProfile();
      if (_userProfile != null) {
        print('✅ User profile loaded: ${_userProfile!['full_name']}');
      } else {
        print('⚠️ No user profile found in database');
      }
    } catch (e) {
      print('❌ Error loading user profile: $e');
      _errorMessage = 'Failed to load user profile';
    }
  }

  Future<void> _updateLastActive() async {
    try {
      await _databaseService.updateUserLastActive();
    } catch (e) {
      print('⚠️ Failed to update last active: $e');
    }
  }

  Future<void> waitForInitialization() async {
    if (_isInitialized) return;

    int attempts = 0;
    const maxAttempts = 50;
    while (!_isInitialized && attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    if (!_isInitialized) {
      print('⚠️ AuthProvider initialization timeout');
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Enhanced profile update method with better state management
  void updateUserProfileFromRealtime(Map<String, dynamic> newProfile) {
    print('🔄 Updating profile from real-time: $newProfile');
    _userProfile = newProfile;
    notifyListeners();
  }

  // Enhanced refresh method
  Future<void> refreshUserProfile() async {
    print('🔄 Refreshing user profile from database...');
    await _loadUserProfile();
    notifyListeners();
    print('✅ User profile refreshed');
  }

  // Enhanced profile update with immediate state refresh
  Future<bool> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? profilePictureUrl,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      print('📝 Updating user profile');

      // Update Firebase Auth display name if provided
      if (fullName != null) {
        await _authService.updateUserDisplayName(fullName);
      }

      // Update Supabase profile
      await _databaseService.updateUserProfile(
        fullName: fullName,
        phoneNumber: phoneNumber,
        profilePictureUrl: profilePictureUrl,
      );

      // Send profile update notification
      try {
        await _databaseService.saveNotification(
          title: 'Profile Updated',
          message: 'Your profile has been successfully updated.',
          type: 'success',
        );
      } catch (e) {
        print('⚠️ Failed to send profile update notification: $e');
      }

      // CRITICAL: Immediately refresh profile data from database
      await _loadUserProfile();
      await _loadNotifications();

      // Force UI update
      notifyListeners();

      print('✅ Profile updated successfully');
      return true;
    } catch (e) {
      print('❌ Profile update error: $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Authentication methods
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      print('🔐 Starting sign in process for: $email');
      final user = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      if (user != null) {
        _user = user;
        await _loadUserProfile();

        if (!isAccountActive) {
          await signOut();
          _setError('Your account has been suspended. Please contact support.');
          return false;
        }
        if (userType != 'CLIENT') {
          await signOut();
          _setError('Only CLIENT users can sign in through this app.');
          return false;
        }

        await _loadNotifications();
        await _updateLastActive();

        try {
          await _databaseService.saveNotification(
            title: 'Welcome Back!',
            message: 'You have successfully signed in to LawBot.',
            type: 'success',
          );
          print('✅ Signin notification sent to user');
        } catch (e) {
          print('⚠️ Failed to send signin notification: $e');
        }

        print('✅ Sign in successful');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Sign in error: $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUp(
      String email,
      String password,
      String fullName,
      String phoneNumber) async {
    _setLoading(true);
    _clearError();
    try {
      print('🚀 Starting signup process for: $email');
      // Step 1: Create Firebase user
      final user = await _authService.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
      );
      if (user != null) {
        _user = user;
        print('✅ Firebase user created: ${user.uid}');
        // Step 2: Create user profile in database
        await _databaseService.createUserProfile(
          firebaseUid: user.uid,
          email: email,
          fullName: fullName,
          phoneNumber: phoneNumber,
          userType: 'CLIENT',
        );
        print('✅ User profile created with notifications');
        // Step 3: Load user profile and notifications
        await _loadUserProfile();
        await _loadNotifications();
        // Step 4: Send additional analytics
        try {
          await _databaseService.saveUserAnalytics(
            metricName: 'user_signup_completed',
            metricValue: {
              'signup_method': 'email',
              'timestamp': PhilippineTime.toUtc(PhilippineTime.now()).toIso8601String(),
            },
          );
        } catch (e) {
          print('⚠️ Failed to save signup analytics: $e');
        }
        print('🎉 Signup completed successfully');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Signup error: $e');
      _setError(e.toString());
      // Clean up if database creation failed but Firebase user was created
      if (_authService.currentUser != null) {
        try {
          await _authService.currentUser!.delete();
          print('🧹 Cleaned up Firebase user after database error');
        } catch (cleanupError) {
          print('⚠️ Failed to cleanup Firebase user: $cleanupError');
        }
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    _clearError();
    try {
      print('👋 Signing out user');
      
      // Clear FCM token before signing out
      await _clearFCMToken();
      
      await _authService.signOut();
      _user = null;
      _userProfile = null;
      _clearNotifications();
      print('✅ Sign out successful');
    } catch (e) {
      print('❌ Sign out error: $e');
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();
    try {
      print('📧 Sending password reset email to: $email');
      await _authService.resetPassword(email);
      print('✅ Password reset email sent');
      return true;
    } catch (e) {
      print('❌ Password reset error: $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Re-authenticate user before sensitive operations
  Future<bool> reauthenticate(String password) async {
    _setLoading(true);
    _clearError();
    try {
      print('🔐 Re-authenticating user');
      await _authService.reauthenticateWithPassword(password);
      print('✅ Re-authentication successful');
      return true;
    } catch (e) {
      print('❌ Re-authentication error: $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Account deletion with notifications
  Future<bool> deleteAccount(String password) async {
    _setLoading(true);
    _clearError();
    try {
      if (_user == null) {
        throw 'No user is currently signed in';
      }
      print('🗑️ Starting account deletion process');
      // Step 1: Re-authenticate the user first
      await _authService.reauthenticateWithPassword(password);
      print('✅ Re-authentication successful');
      // Step 2: Notify admins about account deletion
      try {
        final userName = _userProfile?['full_name'] ?? 'Unknown User';
        final userEmail = _userProfile?['email'] ?? 'Unknown Email';
        await _databaseService.saveUserAnalytics(
          metricName: 'user_account_deleted',
          metricValue: {
            'user_name': userName,
            'user_email': userEmail,
            'deletion_timestamp': PhilippineTime.toUtc(PhilippineTime.now()).toIso8601String(),
          },
        );
      } catch (e) {
        print('⚠️ Failed to log account deletion: $e');
      }
      // Step 3: Delete user data from Supabase
      await _databaseService.deleteUserAccount();
      print('✅ Database cleanup completed');
      // Step 4: Delete the Firebase user account
      await _authService.deleteUserAccount();
      print('✅ Firebase user deleted');
      // Step 5: Clear local state
      _user = null;
      _userProfile = null;
      _clearNotifications();
      notifyListeners();
      print('🎉 Account deletion completed successfully');
      return true;
    } catch (e) {
      print('❌ Account deletion error: $e');
      _setError('Failed to delete account: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Check account status
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

  // Load notifications for current user
  Future<void> _loadNotifications() async {
    if (_user == null) return;
    try {
      _notificationsLoading = true;
      notifyListeners();

      _notifications = await _databaseService.getNotifications(
        unreadOnly: false,
        limit: 50,
      );

      _notificationStats = await _databaseService.getNotificationStats();
      _lastNotificationCheck = PhilippineTime.now();

      print('✅ Loaded ${_notifications.length} notifications');
    } catch (e) {
      print('❌ Error loading notifications: $e');
    } finally {
      _notificationsLoading = false;
      notifyListeners();
    }
  }

  // Refresh notifications (for pull-to-refresh)
  Future<void> refreshNotifications() async {
    await _loadNotifications();
  }

  // Get unread notifications only
  Future<List<Map<String, dynamic>>> getUnreadNotifications() async {
    try {
      return await _databaseService.getNotifications(unreadOnly: true);
    } catch (e) {
      print('Error getting unread notifications: $e');
      return [];
    }
  }

  // Get urgent notifications
  Future<List<Map<String, dynamic>>> getUrgentNotifications() async {
    try {
      return await _databaseService.getUrgentNotifications();
    } catch (e) {
      print('Error getting urgent notifications: $e');
      return [];
    }
  }

  // Mark notification as read
  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      final success = await _databaseService.markNotificationAsRead(notificationId);
      if (success) {
        // Update local state
        final index = _notifications.indexWhere((n) => n['id'] == notificationId);
        if (index != -1) {
          _notifications[index]['is_read'] = true;
          _notifications[index]['read_at'] = PhilippineTime.toUtc(PhilippineTime.now()).toIso8601String();
        }
        // Update stats
        final currentUnread = _notificationStats['unread_notifications'] ?? 0;
        if (currentUnread > 0) {
          _notificationStats['unread_notifications'] = currentUnread - 1;
        }
        notifyListeners();
      }
      return success;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  // Mark all notifications as read
  Future<bool> markAllNotificationsAsRead() async {
    try {
      final success = await _databaseService.markAllNotificationsAsRead();
      if (success) {
        // Update local state
        for (var notification in _notifications) {
          notification['is_read'] = true;
          notification['read_at'] = PhilippineTime.toUtc(PhilippineTime.now()).toIso8601String();
        }
        // Update stats
        _notificationStats['unread_notifications'] = 0;
        notifyListeners();
      }
      return success;
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }

  // Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final success = await _databaseService.deleteNotification(notificationId);
      if (success) {
        // Update local state
        _notifications.removeWhere((n) => n['id'] == notificationId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      print('Error deleting notification: $e');
      return false;
    }
  }

  // Clear notifications from local state
  void _clearNotifications() {
    _notifications.clear();
    _notificationStats.clear();
    _lastNotificationCheck = null;
    _notificationsLoading = false;
  }

  // Utility methods
  DateTime? getLastActiveTime() {
    final lastActiveStr = _userProfile?['last_active'];
    if (lastActiveStr != null) {
      final utcTime = DateTime.tryParse(lastActiveStr);
      if (utcTime != null) {
        return PhilippineTime.fromUtc(utcTime);
      }
    }
    return null;
  }

  DateTime? getAccountCreatedTime() {
    final createdAtStr = _userProfile?['created_at'];
    if (createdAtStr != null) {
      final utcTime = DateTime.tryParse(createdAtStr);
      if (utcTime != null) {
        return PhilippineTime.fromUtc(utcTime);
      }
    }
    return null;
  }

  // Get formatted last active time string in Philippine time
  String getLastActiveTimeString() {
    final lastActiveTime = getLastActiveTime();
    if (lastActiveTime != null) {
      return PhilippineTime.getRelativeTimeString(lastActiveTime);
    }
    return 'Unknown';
  }

  // Get formatted account created time string in Philippine time
  String getAccountCreatedTimeString() {
    final createdTime = getAccountCreatedTime();
    if (createdTime != null) {
      return PhilippineTime.formatDateTime(createdTime);
    }
    return 'Unknown';
  }

  // Check if notifications need refreshing (every 5 minutes)
  bool get shouldRefreshNotifications {
    if (_lastNotificationCheck == null) return true;
    return PhilippineTime.now().difference(_lastNotificationCheck!).inMinutes >= 5;
  }

  // Auto-refresh notifications if needed
  Future<void> autoRefreshNotifications() async {
    if (shouldRefreshNotifications && _user != null) {
      await _loadNotifications();
    }
  }

  // Private helper methods
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

  // Notification convenience methods
  bool get hasUnreadNotifications => unreadNotificationCount > 0;
  bool get hasUrgentNotifications => urgentNotificationCount > 0;

  String get notificationBadgeText {
    final count = unreadNotificationCount;
    if (count == 0) return '';
    if (count > 99) return '99+';
    return count.toString();
  }

  Map<String, dynamic>? getNotificationById(String notificationId) {
    try {
      return _notifications.firstWhere((n) => n['id'] == notificationId);
    } catch (e) {
      return null;
    }
  }

  List<Map<String, dynamic>> getNotificationsByType(String type) {
    return _notifications.where((n) => n['type'] == type).toList();
  }

  List<Map<String, dynamic>> getNotificationsByCategory(String category) {
    return _notifications.where((n) => n['notification_category'] == category).toList();
  }

  List<Map<String, dynamic>> get unreadNotifications {
    return _notifications.where((n) => n['is_read'] == false).toList();
  }

  List<Map<String, dynamic>> get urgentNotifications {
    return _notifications.where((n) => n['priority'] == 'urgent' && n['is_read'] == false).toList();
  }

  // =============================================
  // FCM INTEGRATION METHODS
  // =============================================

  /// Initialize FCM for the current user (called after successful login)
  Future<void> _initializeFCM() async {
    if (_user?.uid == null) {
      print('⚠️ Cannot initialize FCM: No user authenticated');
      return;
    }

    try {
      print('🔔 Initializing FCM for user: ${_user!.uid}');
      
      // Get NotificationProvider from the widget context
      // This will be handled differently - we'll pass it from the UI layer
      
      print('✅ FCM initialization completed');
    } catch (e) {
      print('❌ Error initializing FCM: $e');
    }
  }

  /// Initialize FCM with notification provider (called from UI after login)
  Future<void> initializeFCMWithProvider(dynamic notificationProvider) async {
    if (_user?.uid == null) {
      print('⚠️ Cannot initialize FCM: No user authenticated');
      return;
    }

    try {
      print('🔔 Initializing FCM with notification provider for user: ${_user!.uid}');
      
      await FCMService.initialize(
        notificationProvider: notificationProvider,
        userId: _user!.uid,
      );
      
      print('✅ FCM initialization with provider completed');
    } catch (e) {
      print('❌ Error initializing FCM with provider: $e');
    }
  }

  /// Clear FCM token on logout
  Future<void> _clearFCMToken() async {
    try {
      print('🧹 Clearing FCM token on logout...');
      await FCMService.clearToken();
      print('✅ FCM token cleared');
    } catch (e) {
      print('❌ Error clearing FCM token: $e');
    }
  }
}
