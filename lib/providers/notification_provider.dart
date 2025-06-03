import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationProvider extends ChangeNotifier {
  bool _notificationsEnabled = true;
  static const String _notificationKey = 'notifications_enabled';

  bool get notificationsEnabled => _notificationsEnabled;

  NotificationProvider() {
    _loadNotificationSettings();
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
}
