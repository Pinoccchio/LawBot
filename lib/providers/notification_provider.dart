import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';

class NotificationProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  
  bool _notificationsEnabled = true;
  static const String _notificationKey = 'notifications_enabled';
  
  List<Map<String, dynamic>> _notifications = [];
  Map<String, dynamic> _notificationStats = {};
  bool _notificationsLoading = false;

  bool get notificationsEnabled => _notificationsEnabled;
  List<Map<String, dynamic>> get notifications => _notifications;
  Map<String, dynamic> get notificationStats => _notificationStats;
  bool get notificationsLoading => _notificationsLoading;
  int get unreadNotificationCount => _notificationStats['unread_notifications'] ?? 0;
  int get urgentNotificationCount => _notificationStats['urgent_notifications'] ?? 0;
  bool get hasUnreadNotifications => unreadNotificationCount > 0;
  
  String get notificationBadgeText {
    final count = unreadNotificationCount;
    return count > 99 ? '99+' : count.toString();
  }

  NotificationProvider() {
    _loadNotificationSettings();
    _loadNotifications();
  }

  // Load notification settings from SharedPreferences
  Future<void> _loadNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _notificationsEnabled = prefs.getBool(_notificationKey) ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
      _notificationsEnabled = true;
    }
  }

  // Save notification settings to SharedPreferences
  Future<void> _saveNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationKey, _notificationsEnabled);
    } catch (e) {
      debugPrint('Error saving notification settings: $e');
    }
  }

  // Toggle notifications
  Future<void> toggleNotifications() async {
    _notificationsEnabled = !_notificationsEnabled;
    await _saveNotificationSettings();
    notifyListeners();
  }

  // Set notification state
  Future<void> setNotifications(bool enabled) async {
    if (_notificationsEnabled != enabled) {
      _notificationsEnabled = enabled;
      await _saveNotificationSettings();
      notifyListeners();
    }
  }

  // Load notifications from database
  Future<void> _loadNotifications() async {
    try {
      _notificationsLoading = true;
      notifyListeners();

      print('📱 Loading notifications from database...');
      
      // Get notifications from database (using existing method signature)
      _notifications = await _databaseService.getNotifications(limit: 100);
      
      // Get notification statistics
      _notificationStats = await _databaseService.getNotificationStats();
      
      print('✅ Loaded ${_notifications.length} notifications from database');
      
      _notificationsLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ Error loading notifications: $e');
      _notificationsLoading = false;
      
      // Load sample data as fallback for development
      _loadSampleNotifications();
      notifyListeners();
    }
  }

  // Load sample notifications for frontend (fallback)
  void _loadSampleNotifications() {
    final now = DateTime.now();
    _notifications = [
      // PENDING Status Notifications
      {
        'id': '1',
        'title': 'Report Successfully Submitted',
        'message': 'Your cybercrime report #CYB-2024-005 has been received and is pending initial review by our team.',
        'type': 'success',
        'priority': 'normal',
        'notification_category': 'case_update',
        'sender_name': 'PNP Cybercrime Unit',
        'is_read': false,
        'created_at': now.subtract(const Duration(minutes: 30)).toIso8601String(),
        'action_url': '/complaint/617a89da-3475-4165-8ea0-1bd850891bf9',
      },
      {
        'id': '2',
        'title': 'Report Queued for Review',
        'message': 'Your online harassment report #CYB-2024-004 is pending assignment to a specialized officer.',
        'type': 'case_update',
        'priority': 'normal',
        'notification_category': 'case_update',
        'sender_name': 'Case Management System',
        'is_read': false,
        'created_at': now.subtract(const Duration(hours: 1)).toIso8601String(),
        'action_url': '/complaint/728b91cd-4576-5276-9fb1-2ce959892c0a',
      },

      // UNDER INVESTIGATION Status Notifications
      {
        'id': '3',
        'title': 'Investigation Started',
        'message': 'Your cybercrime report #CYB-2024-001 has been updated to "Under Investigation" and assigned to Officer Santos.',
        'type': 'case_update',
        'priority': 'high',
        'notification_category': 'case_update',
        'sender_name': 'Officer Santos - Economic Offenses Wing',
        'is_read': false,
        'created_at': now.subtract(const Duration(hours: 2)).toIso8601String(),
        'action_url': '/case/839c02de-5687-6387-afg2-3df060893d1b',
      },
      {
        'id': '4',
        'title': 'Evidence Under Analysis',
        'message': 'Digital forensics team is analyzing evidence for report #CYB-2024-002. Investigation is actively progressing.',
        'type': 'case_update',
        'priority': 'normal',
        'notification_category': 'case_update',
        'sender_name': 'Digital Forensics Team',
        'is_read': false,
        'created_at': now.subtract(const Duration(hours: 4)).toIso8601String(),
        'action_url': '/complaint/617a89da-3475-4165-8ea0-1bd850891bf9',
      },
      {
        'id': '5',
        'title': 'Witness Interview Scheduled',
        'message': 'Investigation update for #CYB-2024-003: Witness interviews have been scheduled as part of the ongoing investigation.',
        'type': 'case_update',
        'priority': 'normal',
        'notification_category': 'case_update',
        'sender_name': 'Officer Cruz - Cyber Crime Investigation Cell',
        'is_read': true,
        'created_at': now.subtract(const Duration(hours: 8)).toIso8601String(),
        'action_url': '/complaint/617a89da-3475-4165-8ea0-1bd850891bf9',
      },

      // REQUIRES MORE INFO Status Notifications
      {
        'id': '6',
        'title': 'Additional Information Required',
        'message': 'Your report #CYB-2024-006 requires more information. Please provide additional transaction details and screenshots.',
        'type': 'warning',
        'priority': 'high',
        'notification_category': 'case_update',
        'sender_name': 'Officer Reyes - Economic Offenses Wing',
        'is_read': false,
        'created_at': now.subtract(const Duration(hours: 3)).toIso8601String(),
        'action_url': '/complaint/617a89da-3475-4165-8ea0-1bd850891bf9',
      },
      {
        'id': '7',
        'title': 'Evidence Clarification Needed',
        'message': 'Report #CYB-2024-007 requires clarification on the timeline of events. Please contact our office within 7 days.',
        'type': 'warning',
        'priority': 'high',
        'notification_category': 'case_update',
        'sender_name': 'Officer Luna - Cyber Crime Against Women and Children',
        'is_read': true,
        'created_at': now.subtract(const Duration(days: 1)).toIso8601String(),
        'action_url': '/complaint/617a89da-3475-4165-8ea0-1bd850891bf9',
      },

      // RESOLVED Status Notifications
      {
        'id': '8',
        'title': 'Case Successfully Resolved',
        'message': 'Great news! Your cybercrime report #CYB-2023-078 has been resolved. Suspect identified and charges filed successfully.',
        'type': 'success',
        'priority': 'normal',
        'notification_category': 'case_update',
        'sender_name': 'Officer Martinez - Cyber Crime Against Women and Children',
        'is_read': true,
        'created_at': now.subtract(const Duration(days: 2)).toIso8601String(),
        'action_url': '/complaint/617a89da-3475-4165-8ea0-1bd850891bf9',
      },
      {
        'id': '9',
        'title': 'Recovery Successful',
        'message': 'Case #CYB-2023-052 resolved: Full refund of ₱15,000 has been processed through platform mediation.',
        'type': 'success',
        'priority': 'normal',
        'notification_category': 'case_update',
        'sender_name': 'Officer Santos - Economic Offenses Wing',
        'is_read': true,
        'created_at': now.subtract(const Duration(days: 3)).toIso8601String(),
        'action_url': '/complaint/617a89da-3475-4165-8ea0-1bd850891bf9',
      },
      {
        'id': '10',
        'title': 'Identity Theft Case Closed',
        'message': 'Report #CYB-2023-001 resolved: Fraudulent accounts closed, credit restored, and suspect arrested.',
        'type': 'success',
        'priority': 'normal',
        'notification_category': 'case_update',
        'sender_name': 'Officer Reyes - Cyber Security Division',
        'is_read': true,
        'created_at': now.subtract(const Duration(days: 4)).toIso8601String(),
        'action_url': '/complaint/617a89da-3475-4165-8ea0-1bd850891bf9',
      },

      // DISMISSED Status Notifications
      {
        'id': '11',
        'title': 'Case Dismissed - Insufficient Evidence',
        'message': 'Report #CYB-2022-089 has been dismissed due to insufficient evidence to pursue criminal charges. Civil remedies recommended.',
        'type': 'warning',
        'priority': 'normal',
        'notification_category': 'case_update',
        'sender_name': 'Officer Luna - Cyber Crime Against Women and Children',
        'is_read': true,
        'created_at': now.subtract(const Duration(days: 5)).toIso8601String(),
        'action_url': '/complaint/617a89da-3475-4165-8ea0-1bd850891bf9',
      },
      {
        'id': '12',
        'title': 'Case Classification Updated',
        'message': 'Report #CYB-2023-033 dismissed: General phishing attempt with no specific target identified and no financial loss incurred.',
        'type': 'warning',
        'priority': 'normal',
        'notification_category': 'case_update',
        'sender_name': 'Officer Cruz - Cyber Crime Investigation Cell',
        'is_read': true,
        'created_at': now.subtract(const Duration(days: 6)).toIso8601String(),
        'action_url': '/complaint/617a89da-3475-4165-8ea0-1bd850891bf9',
      },

      // SECURITY & SYSTEM NOTIFICATIONS
      {
        'id': '13',
        'title': 'Security Alert - Phishing Campaign',
        'message': 'Increased phishing activity targeting banking customers detected. Please review your submitted reports for similarities.',
        'type': 'security_alert',
        'priority': 'urgent',
        'notification_category': 'security',
        'sender_name': 'Cybersecurity Division',
        'is_read': true,
        'created_at': now.subtract(const Duration(days: 1, hours: 6)).toIso8601String(),
        'action_url': '/complaint/617a89da-3475-4165-8ea0-1bd850891bf9',
      },
      {
        'id': '14',
        'title': 'System Maintenance Notice',
        'message': 'Scheduled maintenance tonight from 12:00 AM to 2:00 AM. Report submission may be temporarily unavailable.',
        'type': 'announcement',
        'priority': 'normal',
        'notification_category': 'system',
        'sender_name': 'System Administrator',
        'is_read': true,
        'created_at': now.subtract(const Duration(days: 7)).toIso8601String(),
        'action_url': '/complaint/617a89da-3475-4165-8ea0-1bd850891bf9',
      },

      // LEGAL UPDATE NOTIFICATIONS
      {
        'id': '15',
        'title': 'New Cybercrime Guidelines',
        'message': 'Updated guidelines for reporting cryptocurrency fraud have been released. Enhanced protection measures now available.',
        'type': 'legal_update',
        'priority': 'normal',
        'notification_category': 'legal_update',
        'sender_name': 'Legal Affairs Division',
        'is_read': true,
        'created_at': now.subtract(const Duration(days: 10)).toIso8601String(),
        'action_url': '/complaint/617a89da-3475-4165-8ea0-1bd850891bf9',
      },
    ];

    _updateNotificationStats();
    notifyListeners();
  }

  void _updateNotificationStats() {
    final unreadCount = _notifications.where((n) => n['is_read'] == false).length;
    final urgentCount = _notifications.where((n) => n['priority'] == 'urgent' && n['is_read'] == false).length;
    final todayCount = _notifications.where((n) {
      try {
        final createdAt = DateTime.parse(n['created_at']);
        final today = DateTime.now();
        return createdAt.year == today.year && 
               createdAt.month == today.month && 
               createdAt.day == today.day;
      } catch (e) {
        return false;
      }
    }).length;

    _notificationStats = {
      'total_notifications': _notifications.length,
      'unread_notifications': unreadCount,
      'urgent_notifications': urgentCount,
      'notifications_today': todayCount,
    };
  }

  Future<void> refreshNotifications() async {
    await _loadNotifications();
  }

  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      // Update in database
      final success = await _databaseService.markNotificationAsRead(notificationId);
      
      if (success) {
        // Update local data
        final index = _notifications.indexWhere((n) => n['id'] == notificationId);
        if (index != -1 && _notifications[index]['is_read'] == false) {
          _notifications[index]['is_read'] = true;
          _notifications[index]['read_at'] = DateTime.now().toIso8601String();
          _updateNotificationStats();
          notifyListeners();
        }
      }
      
      return success;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  Future<bool> markAllNotificationsAsRead() async {
    try {
      // Update in database
      final success = await _databaseService.markAllNotificationsAsRead();
      
      if (success) {
        // Update local data
        for (var notification in _notifications) {
          if (notification['is_read'] == false) {
            notification['is_read'] = true;
            notification['read_at'] = DateTime.now().toIso8601String();
          }
        }
        _updateNotificationStats();
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      return false;
    }
  }

  Future<bool> deleteNotification(String notificationId) async {
    try {
      // Delete from database
      final success = await _databaseService.deleteNotification(notificationId);
      
      if (success) {
        // Update local data
        _notifications.removeWhere((n) => n['id'] == notificationId);
        _updateNotificationStats();
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      return false;
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

  // Get unread notifications
  List<Map<String, dynamic>> getUnreadNotifications() {
    return _notifications.where((n) => n['is_read'] == false).toList();
  }

  // Get urgent notifications
  List<Map<String, dynamic>> getUrgentNotifications() {
    return _notifications.where((n) => n['priority'] == 'urgent' && n['is_read'] == false).toList();
  }

  /// Handle real-time notification update from RealtimeProvider
  void handleRealtimeNotificationUpdate(Map<String, dynamic> notification) {
    try {
      print('🔔 Received real-time notification: ${notification['title']}');
      
      // Check if notification already exists (update) or is new (insert)
      final existingIndex = _notifications.indexWhere((n) => n['id'] == notification['id']);
      
      if (existingIndex != -1) {
        // Update existing notification
        _notifications[existingIndex] = notification;
        print('📝 Updated existing notification');
      } else {
        // Add new notification at the beginning
        _notifications.insert(0, notification);
        print('➕ Added new notification');
      }
      
      // Update statistics
      _updateNotificationStats();
      notifyListeners();
      
      print('✅ Real-time notification processed successfully');
    } catch (e) {
      print('❌ Error handling real-time notification update: $e');
    }
  }

  /// Handle real-time notification deletion
  void handleRealtimeNotificationDelete(String notificationId) {
    try {
      print('🗑️ Processing real-time notification deletion: $notificationId');
      
      _notifications.removeWhere((n) => n['id'] == notificationId);
      _updateNotificationStats();
      notifyListeners();
      
      print('✅ Real-time notification deletion processed');
    } catch (e) {
      print('❌ Error handling real-time notification deletion: $e');
    }
  }

  /// Force refresh notifications from database (for error recovery)
  Future<void> forceRefreshNotifications() async {
    try {
      print('🔄 Force refreshing notifications from database...');
      await _loadNotifications();
      print('✅ Force refresh completed');
    } catch (e) {
      print('❌ Error in force refresh: $e');
    }
  }
}
