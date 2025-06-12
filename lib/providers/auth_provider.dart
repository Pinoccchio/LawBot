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
  bool _isInitialized = false; // ADDED: Initialization state

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
  bool get isInitialized => _isInitialized; // ADDED: Initialization getter
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

  // FIXED: Proper initialization that checks current user immediately
  void _initializeAuth() async {
    try {
      print('🚀 Initializing AuthProvider...');

      // CRITICAL: Check current user immediately (synchronously)
      _user = _authService.currentUser;

      if (_user != null) {
        print('✅ Found existing user: ${_user!.uid}');
        // Load user profile and notifications for existing user
        await _loadUserProfile();
        await _loadNotifications();
        await _updateLastActive();
      } else {
        print('❌ No existing user found');
        _userProfile = null;
        _clearNotifications();
      }

      // Mark as initialized after checking current state
      _isInitialized = true;
      notifyListeners();

      print('✅ AuthProvider initialization complete');

      // Listen to auth state changes for future changes
      _authService.authStateChanges.listen((User? user) {
        _handleAuthStateChange(user);
      });

    } catch (e) {
      print('❌ Error during AuthProvider initialization: $e');
      // Still mark as initialized even if there's an error
      _isInitialized = true;
      notifyListeners();
    }
  }

  // UPDATED: Handle auth state changes (for future auth events)
  Future<void> _handleAuthStateChange(User? user) async {
    // Don't process if this is the same user (avoid duplicate processing)
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

    // Ensure initialized is true
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
      // Don't show error to user for this
    }
  }

  // ADDED: Wait for initialization to complete (for splash screen)
  Future<void> waitForInitialization() async {
    if (_isInitialized) return;

    // Wait for initialization with timeout
    int attempts = 0;
    const maxAttempts = 50; // 5 seconds max wait

    while (!_isInitialized && attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    if (!_isInitialized) {
      print('⚠️ AuthProvider initialization timeout');
      _isInitialized = true; // Force initialization to prevent infinite wait
      notifyListeners();
    }
  }

  /// Updates user profile based on real-time changes.
  void updateUserProfileFromRealtime(Map<String, dynamic> newProfile) {
    _userProfile = newProfile;
    notifyListeners();
  }

  /// Reloads the user profile from the database.
  Future<void> refreshUserProfile() async {
    await _loadUserProfile();
    notifyListeners();
  }

  // =============================================
  // AUTHENTICATION METHODS (ENHANCED)
  // =============================================

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

        // Check if account is active and user_type is CLIENT
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

        // Load notifications after successful sign in
        await _loadNotifications();
        await _updateLastActive();

        // Send signin notification to user
        try {
          await _databaseService.saveNotification(
            title: 'Welcome Back!',
            message: 'You have successfully signed in to LawBot.',
            type: 'success',
          );
          print('✅ Signin notification sent to user');
        } catch (e) {
          print('⚠️ Failed to send signin notification: $e');
          // Don't fail signin if notification fails
        }

        // Send signin analytics
        try {
          await _databaseService.saveUserAnalytics(
            metricName: 'user_signin',
            metricValue: {
              'signin_method': 'email',
              'timestamp': DateTime.now().toUtc().toIso8601String(),
              'user_agent': 'flutter_app',
            },
          );
        } catch (e) {
          print('⚠️ Failed to save signin analytics: $e');
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

  // Enhanced signup with notification integration
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
        // This will automatically trigger:
        // - Admin notifications via database trigger
        // - Welcome notification to user
        // - Default notification preferences creation
        await _databaseService.createUserProfile(
          firebaseUid: user.uid,
          email: email,
          fullName: fullName,
          userType: 'CLIENT',
          preferredLanguage: preferredLanguage,
          notificationPreferences: notificationPreferences ?? {
            'email': true,
            'push': true,
            'legal_updates': true,
            'marketing': false,
            'security_alerts': true,
          },
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
              'preferred_language': preferredLanguage,
              'notification_preferences_set': notificationPreferences != null,
              'timestamp': DateTime.now().toUtc().toIso8601String(),
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

  // =============================================
  // PROFILE MANAGEMENT (ENHANCED)
  // =============================================

  // Enhanced profile update with notifications
  Future<bool> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? avatarUrl,
    String? preferredLanguage,
    Map<String, dynamic>? notificationPreferences,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      print('📝 Updating user profile');

      // Update Firebase Auth display name if provided
      if (fullName != null) {
        await _authService.updateUserDisplayName(fullName);
      }

      // Update Supabase profile with all new fields
      await _databaseService.updateUserProfile(
        fullName: fullName,
        phoneNumber: phoneNumber,
        avatarUrl: avatarUrl,
        preferredLanguage: preferredLanguage,
        notificationPreferences: notificationPreferences,
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

      // Reload profile and notifications
      await _loadUserProfile();
      await _loadNotifications();

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

  // Update notification preferences
  Future<bool> updateNotificationPreferences(Map<String, dynamic> preferences) async {
    _setLoading(true);
    _clearError();

    try {
      print('🔔 Updating notification preferences');

      await _databaseService.updateUserProfile(
        notificationPreferences: preferences,
      );

      // Reload profile
      await _loadUserProfile();

      print('✅ Notification preferences updated');
      return true;
    } catch (e) {
      print('❌ Notification preferences update error: $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update preferred language
  Future<bool> updatePreferredLanguage(String language) async {
    _setLoading(true);
    _clearError();

    try {
      print('🌐 Updating preferred language to: $language');

      await _databaseService.updateUserProfile(
        preferredLanguage: language,
      );

      // Reload profile
      await _loadUserProfile();

      print('✅ Preferred language updated');
      return true;
    } catch (e) {
      print('❌ Language update error: $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // =============================================
  // NOTIFICATION MANAGEMENT
  // =============================================

  // Load notifications for current user
  Future<void> _loadNotifications() async {
    if (_user == null) return;

    try {
      _notificationsLoading = true;
      notifyListeners();

      // Get notifications
      _notifications = await _databaseService.getNotifications(
        unreadOnly: false,
        limit: 50,
      );

      // Get notification statistics
      _notificationStats = await _databaseService.getNotificationStats();

      _lastNotificationCheck = DateTime.now();

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
          _notifications[index]['read_at'] = DateTime.now().toUtc().toIso8601String();
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
          notification['read_at'] = DateTime.now().toUtc().toIso8601String();
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

  // =============================================
  // ADMIN NOTIFICATION FEATURES
  // =============================================

  // Send notification to specific user (admin only)
  Future<Map<String, dynamic>?> sendNotificationToUser({
    required String userId,
    required String title,
    required String message,
    String type = 'admin_message',
    String category = 'announcement',
    String priority = 'normal',
    String? actionUrl,
    DateTime? expiresAt,
  }) async {
    if (!isAdmin) {
      throw 'Only admins can send notifications to users';
    }

    try {
      _setLoading(true);

      print('📤 Admin sending notification to user: $userId');

      final result = await _databaseService.sendAdminNotification(
        title: title,
        message: message,
        recipientUserId: userId,
        type: type,
        category: category,
        priority: priority,
        actionUrl: actionUrl,
        expiresAt: expiresAt,
      );

      print('✅ Notification sent successfully');
      return result;
    } catch (e) {
      print('❌ Error sending notification: $e');
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Broadcast notification to all users (admin only)
  Future<Map<String, dynamic>?> broadcastNotification({
    required String title,
    required String message,
    String type = 'announcement',
    String category = 'system',
    String priority = 'normal',
    String? actionUrl,
    DateTime? expiresAt,
  }) async {
    if (!isAdmin) {
      throw 'Only admins can broadcast notifications';
    }

    try {
      _setLoading(true);

      print('📢 Admin broadcasting notification to all users');

      final result = await _databaseService.sendAdminNotification(
        title: title,
        message: message,
        recipientUserId: null, // null = all users
        type: type,
        category: category,
        priority: priority,
        actionUrl: actionUrl,
        expiresAt: expiresAt,
      );

      print('✅ Broadcast notification sent successfully');
      return result;
    } catch (e) {
      print('❌ Error broadcasting notification: $e');
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Get admin signup notifications (admin only)
  Future<List<Map<String, dynamic>>> getAdminSignupNotifications() async {
    if (!isAdmin) return [];

    try {
      return await _databaseService.getAdminSignupNotifications();
    } catch (e) {
      print('Error getting admin signup notifications: $e');
      return [];
    }
  }

  // =============================================
  // ACCOUNT MANAGEMENT
  // =============================================

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
            'deletion_timestamp': DateTime.now().toUtc().toIso8601String(),
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

  // =============================================
  // UTILITY METHODS
  // =============================================

  // Get user preferences safely
  Map<String, dynamic> getNotificationPreferences() {
    return _userProfile?['notification_preferences'] ?? {
      'email': true,
      'push': true,
      'legal_updates': true,
      'marketing': false,
      'security_alerts': true,
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

  // Check if notifications need refreshing (every 5 minutes)
  bool get shouldRefreshNotifications {
    if (_lastNotificationCheck == null) return true;
    return DateTime.now().difference(_lastNotificationCheck!).inMinutes >= 5;
  }

  // Auto-refresh notifications if needed
  Future<void> autoRefreshNotifications() async {
    if (shouldRefreshNotifications && _user != null) {
      await _loadNotifications();
    }
  }

  // =============================================
  // PRIVATE HELPER METHODS
  // =============================================

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

  // =============================================
  // NOTIFICATION CONVENIENCE METHODS
  // =============================================

  // Check if user has unread notifications
  bool get hasUnreadNotifications => unreadNotificationCount > 0;

  // Check if user has urgent notifications
  bool get hasUrgentNotifications => urgentNotificationCount > 0;

  // Get notification badge text
  String get notificationBadgeText {
    final count = unreadNotificationCount;
    if (count == 0) return '';
    if (count > 99) return '99+';
    return count.toString();
  }

  // Get notification by ID
  Map<String, dynamic>? getNotificationById(String notificationId) {
    try {
      return _notifications.firstWhere((n) => n['id'] == notificationId);
    } catch (e) {
      return null;
    }
  }

  // Filter notifications by type
  List<Map<String, dynamic>> getNotificationsByType(String type) {
    return _notifications.where((n) => n['type'] == type).toList();
  }

  // Filter notifications by category
  List<Map<String, dynamic>> getNotificationsByCategory(String category) {
    return _notifications.where((n) => n['notification_category'] == category).toList();
  }

  // Get unread notifications from local state
  List<Map<String, dynamic>> get unreadNotifications {
    return _notifications.where((n) => n['is_read'] == false).toList();
  }

  // Get urgent notifications from local state
  List<Map<String, dynamic>> get urgentNotifications {
    return _notifications.where((n) => n['priority'] == 'urgent' && n['is_read'] == false).toList();
  }
}