import 'dart:async';

import 'package:flutter/material.dart';

import 'auth_provider.dart';
import 'notification_provider.dart';
import '../utils/philippine_time.dart';

/// Global refresh provider for coordinating refreshes across all tabs
/// WITHOUT FCM integration to avoid notification conflicts
class GlobalRefreshProvider extends ChangeNotifier {
  
  // Linked providers for coordinated refresh
  NotificationProvider? _notificationProvider;
  AuthProvider? _authProvider;
  
  // Refresh state
  bool _isRefreshing = false;
  String? _refreshError;
  DateTime? _lastRefresh;
  final Map<String, bool> _tabRefreshStatus = {};
  
  // Progress tracking
  int _totalRefreshSteps = 0;
  int _completedRefreshSteps = 0;
  
  // Getters
  bool get isRefreshing => _isRefreshing;
  String? get refreshError => _refreshError;
  DateTime? get lastRefresh => _lastRefresh;
  double get refreshProgress => _totalRefreshSteps > 0 
      ? _completedRefreshSteps / _totalRefreshSteps 
      : 0.0;
  
  String get refreshProgressText {
    if (!_isRefreshing) return '';
    return 'Refreshing... ($_completedRefreshSteps/$_totalRefreshSteps)';
  }
  
  Map<String, bool> get tabRefreshStatus => Map.from(_tabRefreshStatus);
  
  /// Link providers for coordinated refresh
  void linkProviders({
    NotificationProvider? notificationProvider,
    AuthProvider? authProvider,
  }) {
    _notificationProvider = notificationProvider;
    _authProvider = authProvider;
    print('🔗 GlobalRefreshProvider linked with providers');
  }
  
  /// Trigger global refresh across all tabs
  Future<void> refreshAll({
    bool refreshReports = true,
    bool refreshNotifications = true,
    bool refreshProfile = true,
    bool refreshHistory = true,
  }) async {
    if (_isRefreshing) {
      print('⚠️ Global refresh already in progress, skipping');
      return;
    }
    
    try {
      print('🔄 Starting global refresh...');
      _setRefreshing(true);
      _refreshError = null;
      _tabRefreshStatus.clear();
      
      // Calculate total steps
      _totalRefreshSteps = 0;
      _completedRefreshSteps = 0;
      
      if (refreshReports) _totalRefreshSteps += 1;
      if (refreshHistory) _totalRefreshSteps += 1; 
      if (refreshNotifications) _totalRefreshSteps += 1;
      if (refreshProfile) _totalRefreshSteps += 1;
      
      notifyListeners();
      
      // Refresh each component
      if (refreshReports) {
        await _refreshReports();
      }
      
      if (refreshHistory) {
        await _refreshHistory();
      }
      
      if (refreshNotifications && _notificationProvider != null) {
        await _refreshNotifications();
      }
      
      if (refreshProfile && _authProvider != null) {
        await _refreshUserProfile();
      }
      
      _lastRefresh = PhilippineTime.now();
      print('✅ Global refresh completed successfully');
      
    } catch (e) {
      _refreshError = 'Refresh failed: ${e.toString()}';
      print('❌ Global refresh failed: $e');
    } finally {
      _setRefreshing(false);
    }
  }
  
  /// Refresh reports data
  Future<void> _refreshReports() async {
    try {
      _tabRefreshStatus['reports'] = true;
      notifyListeners();
      
      print('📋 Refreshing reports data...');
      
      // Simulate reports refresh - in real implementation this would call complaint service
      await Future.delayed(const Duration(milliseconds: 800));
      
      _completedRefreshSteps++;
      _tabRefreshStatus['reports'] = false;
      print('✅ Reports data refreshed');
      
    } catch (e) {
      _tabRefreshStatus['reports'] = false;
      print('❌ Error refreshing reports: $e');
      rethrow;
    }
    
    notifyListeners();
  }
  
  /// Refresh history data
  Future<void> _refreshHistory() async {
    try {
      _tabRefreshStatus['history'] = true;
      notifyListeners();
      
      print('📚 Refreshing history data...');
      
      // Simulate history refresh
      await Future.delayed(const Duration(milliseconds: 600));
      
      _completedRefreshSteps++;
      _tabRefreshStatus['history'] = false;
      print('✅ History data refreshed');
      
    } catch (e) {
      _tabRefreshStatus['history'] = false;
      print('❌ Error refreshing history: $e');
      rethrow;
    }
    
    notifyListeners();
  }
  
  /// Refresh notifications WITHOUT interfering with FCM
  Future<void> _refreshNotifications() async {
    try {
      _tabRefreshStatus['notifications'] = true;
      notifyListeners();
      
      print('🔔 Refreshing notifications...');
      
      if (_notificationProvider != null) {
        // Use the existing notification refresh method
        await _notificationProvider!.forceImmediateRefresh();
      }
      
      _completedRefreshSteps++;
      _tabRefreshStatus['notifications'] = false;
      print('✅ Notifications refreshed');
      
    } catch (e) {
      _tabRefreshStatus['notifications'] = false;
      print('❌ Error refreshing notifications: $e');
      rethrow;
    }
    
    notifyListeners();
  }
  
  /// Refresh user profile
  Future<void> _refreshUserProfile() async {
    try {
      _tabRefreshStatus['profile'] = true;
      notifyListeners();
      
      print('👤 Refreshing user profile...');
      
      if (_authProvider != null) {
        await _authProvider!.refreshUserProfile();
      }
      
      _completedRefreshSteps++;
      _tabRefreshStatus['profile'] = false;
      print('✅ User profile refreshed');
      
    } catch (e) {
      _tabRefreshStatus['profile'] = false;
      print('❌ Error refreshing profile: $e');
      rethrow;
    }
    
    notifyListeners();
  }
  
  /// Quick refresh for pull-to-refresh gestures
  Future<void> quickRefresh() async {
    await refreshAll(
      refreshReports: true,
      refreshNotifications: true,
      refreshProfile: false, // Skip profile for quick refresh
      refreshHistory: true,
    );
  }
  
  /// Check if refresh is needed (every 5 minutes)
  bool get shouldAutoRefresh {
    if (_lastRefresh == null) return true;
    return PhilippineTime.now().difference(_lastRefresh!).inMinutes >= 5;
  }
  
  /// Auto-refresh if needed
  Future<void> autoRefreshIfNeeded() async {
    if (shouldAutoRefresh && !_isRefreshing) {
      print('⏰ Auto-refresh triggered');
      await refreshAll();
    }
  }
  
  /// Refresh specific tab
  Future<void> refreshTab(String tabName) async {
    print('🔄 Refreshing tab: $tabName');
    
    switch (tabName.toLowerCase()) {
      case 'reports':
        await _refreshReports();
        break;
      case 'notifications':
        await _refreshNotifications();
        break;
      case 'profile':
        await _refreshUserProfile();
        break;
      case 'history':
        await _refreshHistory();
        break;
      default:
        print('⚠️ Unknown tab: $tabName');
    }
  }
  
  /// Get refresh status for specific tab
  bool isTabRefreshing(String tabName) {
    return _tabRefreshStatus[tabName.toLowerCase()] ?? false;
  }
  
  /// Clear refresh error
  void clearRefreshError() {
    _refreshError = null;
    notifyListeners();
  }
  
  /// Private helper methods
  void _setRefreshing(bool refreshing) {
    _isRefreshing = refreshing;
    if (!refreshing) {
      _completedRefreshSteps = 0;
      _totalRefreshSteps = 0;
      _tabRefreshStatus.clear();
    }
    notifyListeners();
  }
  
  /// Get formatted last refresh time
  String get lastRefreshText {
    if (_lastRefresh == null) return 'Never';
    return PhilippineTime.formatSpecificTime(_lastRefresh!.toIso8601String());
  }
  
  /// Get refresh status summary
  Map<String, dynamic> getRefreshStatus() {
    return {
      'isRefreshing': _isRefreshing,
      'progress': refreshProgress,
      'progressText': refreshProgressText,
      'lastRefresh': lastRefreshText,
      'error': _refreshError,
      'tabStatus': Map.from(_tabRefreshStatus),
    };
  }
  
  @override
  void dispose() {
    _notificationProvider = null;
    _authProvider = null;
    super.dispose();
    print('🗑️ GlobalRefreshProvider disposed');
  }
}