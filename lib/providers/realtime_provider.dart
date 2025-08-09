import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/complaint_model.dart';
import '../services/realtime_service.dart';
import 'notification_provider.dart';

/// Provider for managing real-time updates throughout the app
class RealtimeProvider with ChangeNotifier {
  final RealtimeService _realtimeService = RealtimeService();
  NotificationProvider? _notificationProvider;
  
  // Subscription references
  StreamSubscription<ComplaintStatusUpdate>? _statusUpdatesSubscription;
  StreamSubscription<List<Complaint>>? _activeComplaintsSubscription;
  StreamSubscription<List<Complaint>>? _completedComplaintsSubscription;
  StreamSubscription<Map<String, dynamic>>? _notificationsSubscription;

  // Current state
  List<Complaint> _activeComplaints = [];
  List<Complaint> _completedComplaints = [];
  List<ComplaintStatusUpdate> _recentStatusUpdates = [];
  List<Map<String, dynamic>> _recentNotifications = [];
  bool _isConnected = false;
  String? _connectionError;

  // Getters
  List<Complaint> get activeComplaints => _activeComplaints;
  List<Complaint> get completedComplaints => _completedComplaints;
  List<ComplaintStatusUpdate> get recentStatusUpdates => _recentStatusUpdates;
  List<Map<String, dynamic>> get recentNotifications => _recentNotifications;
  bool get isConnected => _isConnected;
  String? get connectionError => _connectionError;

  /// Set notification provider for integration
  void setNotificationProvider(NotificationProvider notificationProvider) {
    _notificationProvider = notificationProvider;
    print('🔗 NotificationProvider linked to RealtimeProvider');
  }

  /// Initialize real-time connections
  Future<void> initialize() async {
    try {
      print('🔄 Initializing real-time provider...');
      
      // Initialize the real-time service
      await _realtimeService.initialize();
      
      // Subscribe to all streams
      _subscribeToStreams();
      
      _isConnected = true;
      _connectionError = null;
      notifyListeners();
      
      print('✅ Real-time provider initialized successfully');
    } catch (e) {
      _isConnected = false;
      _connectionError = e.toString();
      notifyListeners();
      print('❌ Failed to initialize real-time provider: $e');
    }
  }

  /// Subscribe to all real-time streams
  void _subscribeToStreams() {
    // Subscribe to status updates
    _statusUpdatesSubscription = _realtimeService.statusUpdates.listen(
      (statusUpdate) {
        _handleStatusUpdate(statusUpdate);
      },
      onError: (error) {
        print('Error in status updates stream: $error');
        _handleStreamError('Status Updates', error);
      },
    );

    // Subscribe to active complaints
    _activeComplaintsSubscription = _realtimeService.activeComplaints.listen(
      (complaints) {
        _handleActiveComplaintsUpdate(complaints);
      },
      onError: (error) {
        print('Error in active complaints stream: $error');
        _handleStreamError('Active Complaints', error);
      },
    );

    // Subscribe to completed complaints
    _completedComplaintsSubscription = _realtimeService.completedComplaints.listen(
      (complaints) {
        _handleCompletedComplaintsUpdate(complaints);
      },
      onError: (error) {
        print('Error in completed complaints stream: $error');
        _handleStreamError('Completed Complaints', error);
      },
    );

    // Subscribe to notifications
    _notificationsSubscription = _realtimeService.notifications.listen(
      (notification) {
        _handleNotificationUpdate(notification);
      },
      onError: (error) {
        print('Error in notifications stream: $error');
        _handleStreamError('Notifications', error);
      },
    );
  }

  /// Handle status update events
  void _handleStatusUpdate(ComplaintStatusUpdate statusUpdate) {
    print('📊 Received status update: ${statusUpdate.complaintId} → ${statusUpdate.newStatus}');
    
    // Add to recent updates (keep only last 20)
    _recentStatusUpdates.insert(0, statusUpdate);
    if (_recentStatusUpdates.length > 20) {
      _recentStatusUpdates = _recentStatusUpdates.take(20).toList();
    }
    
    // Update the complaint in our lists if it exists
    _updateComplaintStatus(statusUpdate);
    
    notifyListeners();
  }

  /// Handle active complaints update
  void _handleActiveComplaintsUpdate(List<Complaint> complaints) {
    print('📋 Received active complaints update: ${complaints.length} complaints');
    _activeComplaints = complaints;
    notifyListeners();
  }

  /// Handle completed complaints update
  void _handleCompletedComplaintsUpdate(List<Complaint> complaints) {
    print('✅ Received completed complaints update: ${complaints.length} complaints');
    _completedComplaints = complaints;
    notifyListeners();
  }

  /// Handle notification update
  void _handleNotificationUpdate(Map<String, dynamic> notification) {
    print('🔔 Received notification update: ${notification['title']}');
    
    // Add to recent notifications (keep only last 50)
    _recentNotifications.insert(0, notification);
    if (_recentNotifications.length > 50) {
      _recentNotifications = _recentNotifications.take(50).toList();
    }
    
    // Forward to NotificationProvider if available
    if (_notificationProvider != null) {
      print('🔄 Forwarding notification to NotificationProvider');
      _notificationProvider!.handleRealtimeNotificationUpdate(notification);
    } else {
      print('⚠️ NotificationProvider not set, notification not forwarded');
    }
    
    notifyListeners();
  }

  /// Update complaint status in local lists
  void _updateComplaintStatus(ComplaintStatusUpdate statusUpdate) {
    // Check active complaints
    final activeIndex = _activeComplaints.indexWhere((c) => c.id == statusUpdate.complaintId);
    if (activeIndex != -1) {
      final complaint = _activeComplaints[activeIndex];
      final updatedComplaint = complaint.copyWith(
        status: ComplaintStatus.values.firstWhere(
          (s) => s.displayName == statusUpdate.newStatus,
          orElse: () => complaint.status,
        ),
        updatedAt: statusUpdate.timestamp,
        remarks: statusUpdate.remarks,
      );
      
      // If status is now completed, move to completed list
      if (statusUpdate.newStatus == 'Resolved' || statusUpdate.newStatus == 'Dismissed') {
        _activeComplaints.removeAt(activeIndex);
        _completedComplaints.insert(0, updatedComplaint);
      } else {
        _activeComplaints[activeIndex] = updatedComplaint;
      }
    }
    
    // Check completed complaints
    final completedIndex = _completedComplaints.indexWhere((c) => c.id == statusUpdate.complaintId);
    if (completedIndex != -1) {
      final complaint = _completedComplaints[completedIndex];
      final updatedComplaint = complaint.copyWith(
        status: ComplaintStatus.values.firstWhere(
          (s) => s.displayName == statusUpdate.newStatus,
          orElse: () => complaint.status,
        ),
        updatedAt: statusUpdate.timestamp,
        remarks: statusUpdate.remarks,
      );
      
      // If status is no longer completed, move to active list
      if (statusUpdate.newStatus != 'Resolved' && statusUpdate.newStatus != 'Dismissed') {
        _completedComplaints.removeAt(completedIndex);
        _activeComplaints.insert(0, updatedComplaint);
      } else {
        _completedComplaints[completedIndex] = updatedComplaint;
      }
    }
  }

  /// Handle stream errors
  void _handleStreamError(String streamName, dynamic error) {
    _connectionError = '$streamName stream error: $error';
    _isConnected = false;
    notifyListeners();
    
    // Attempt to reconnect after a delay
    Timer(const Duration(seconds: 5), () {
      _attemptReconnect();
    });
  }

  /// Attempt to reconnect to real-time services
  Future<void> _attemptReconnect() async {
    try {
      print('🔄 Attempting to reconnect real-time services...');
      await initialize();
    } catch (e) {
      print('❌ Reconnection failed: $e');
    }
  }

  /// Get complaint by ID
  Complaint? getComplaintById(String complaintId) {
    // Check active complaints first
    try {
      return _activeComplaints.firstWhere((c) => c.id == complaintId);
    } catch (e) {
      // Not found in active, check completed
      try {
        return _completedComplaints.firstWhere((c) => c.id == complaintId);
      } catch (e) {
        return null;
      }
    }
  }

  /// Get status updates for a specific complaint
  List<ComplaintStatusUpdate> getStatusUpdatesForComplaint(String complaintId) {
    return _recentStatusUpdates
        .where((update) => update.complaintId == complaintId)
        .toList();
  }

  /// Clear recent status updates
  void clearRecentStatusUpdates() {
    _recentStatusUpdates.clear();
    notifyListeners();
  }

  /// Clear recent notifications
  void clearRecentNotifications() {
    _recentNotifications.clear();
    notifyListeners();
  }

  /// Manual refresh of complaint data
  Future<void> refreshComplaints() async {
    try {
      // This will trigger the real-time service to refresh data
      _realtimeService.dispose();
      await _realtimeService.initialize();
      _subscribeToStreams();
      
      _isConnected = true;
      _connectionError = null;
      notifyListeners();
    } catch (e) {
      print('Error refreshing complaints: $e');
      _connectionError = 'Failed to refresh: $e';
      _isConnected = false;
      notifyListeners();
    }
  }

  /// Dispose of all subscriptions
  @override
  void dispose() {
    _statusUpdatesSubscription?.cancel();
    _activeComplaintsSubscription?.cancel();
    _completedComplaintsSubscription?.cancel();
    _notificationsSubscription?.cancel();
    
    _realtimeService.dispose();
    
    super.dispose();
    print('✅ Real-time provider disposed');
  }

  /// Get connection status info
  Map<String, dynamic> getConnectionInfo() {
    return {
      'isConnected': _isConnected,
      'error': _connectionError,
      'activeComplaints': _activeComplaints.length,
      'completedComplaints': _completedComplaints.length,
      'recentUpdates': _recentStatusUpdates.length,
      'recentNotifications': _recentNotifications.length,
    };
  }
}