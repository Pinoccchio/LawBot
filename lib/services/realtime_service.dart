import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/complaint_model.dart';
import '../utils/philippine_time.dart';
import 'database_service.dart';

/// Service for handling real-time updates from Supabase
class RealtimeService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _databaseService = DatabaseService();

  String? get currentUserId => _auth.currentUser?.uid;

  // Stream controllers for different types of real-time updates
  final StreamController<ComplaintStatusUpdate> _statusUpdatesController = 
      StreamController<ComplaintStatusUpdate>.broadcast();
  final StreamController<List<Complaint>> _activeComplaintsController = 
      StreamController<List<Complaint>>.broadcast();
  final StreamController<List<Complaint>> _completedComplaintsController = 
      StreamController<List<Complaint>>.broadcast();
  final StreamController<Map<String, dynamic>> _notificationsController = 
      StreamController<Map<String, dynamic>>.broadcast();

  // Subscription references
  RealtimeChannel? _complaintsChannel;
  RealtimeChannel? _statusHistoryChannel;
  RealtimeChannel? _notificationsChannel;

  // Getters for streams
  Stream<ComplaintStatusUpdate> get statusUpdates => _statusUpdatesController.stream;
  Stream<List<Complaint>> get activeComplaints => _activeComplaintsController.stream;
  Stream<List<Complaint>> get completedComplaints => _completedComplaintsController.stream;
  Stream<Map<String, dynamic>> get notifications => _notificationsController.stream;

  /// Initialize real-time subscriptions
  Future<void> initialize() async {
    if (currentUserId == null) {
      print('Cannot initialize realtime service: User not authenticated');
      return;
    }

    try {
      await _subscribeToComplaints();
      await _subscribeToStatusHistory();
      await _subscribeToNotifications();
      print('✅ Realtime subscriptions initialized');
    } catch (e) {
      print('❌ Error initializing realtime subscriptions: $e');
    }
  }

  /// Dispose of all subscriptions and controllers
  void dispose() {
    _complaintsChannel?.unsubscribe();
    _statusHistoryChannel?.unsubscribe();
    _notificationsChannel?.unsubscribe();
    
    _statusUpdatesController.close();
    _activeComplaintsController.close();
    _completedComplaintsController.close();
    _notificationsController.close();
    
    print('✅ Realtime service disposed');
  }

  /// Subscribe to complaint changes
  Future<void> _subscribeToComplaints() async {
    if (currentUserId == null) return;

    _complaintsChannel = _supabase.channel('complaints_$currentUserId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'complaints',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: currentUserId!,
        ),
        callback: _handleComplaintChange,
      )
      .subscribe();
  }

  /// Subscribe to status history changes
  Future<void> _subscribeToStatusHistory() async {
    if (currentUserId == null) return;

    _statusHistoryChannel = _supabase.channel('status_history_$currentUserId')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'complaint_status_history',
        callback: _handleStatusHistoryChange,
      )
      .subscribe();
  }

  /// Subscribe to notification changes
  Future<void> _subscribeToNotifications() async {
    if (currentUserId == null) return;

    _notificationsChannel = _supabase.channel('notifications_$currentUserId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: currentUserId!,
        ),
        callback: _handleNotificationChange,
      )
      .subscribe();
  }

  /// Handle complaint table changes
  void _handleComplaintChange(PostgresChangePayload payload) {
    try {
      print('📱 Complaint change detected: ${payload.eventType}');
      
      switch (payload.eventType) {
        case PostgresChangeEvent.insert:
          _handleComplaintInsert(payload.newRecord);
          break;
        case PostgresChangeEvent.update:
          _handleComplaintUpdate(payload.oldRecord, payload.newRecord);
          break;
        case PostgresChangeEvent.delete:
          _handleComplaintDelete(payload.oldRecord);
          break;
        case PostgresChangeEvent.all:
          // This shouldn't happen in practice since we handle specific events
          break;
      }

      // Refresh complaint lists
      _refreshComplaintLists();
    } catch (e) {
      print('Error handling complaint change: $e');
    }
  }

  /// Handle status history changes
  void _handleStatusHistoryChange(PostgresChangePayload payload) {
    try {
      print('📊 Status history change detected');
      
      final record = payload.newRecord;
      if (record != null) {
        final statusUpdate = ComplaintStatusUpdate(
          complaintId: record['complaint_id'],
          oldStatus: null, // Would need to track this separately
          newStatus: record['status'],
          updatedBy: record['updated_by'],
          remarks: record['remarks'],
          timestamp: DateTime.parse(record['created_at']),
        );

        _statusUpdatesController.add(statusUpdate);

        // Create notification for status change
        _createStatusChangeNotification(statusUpdate);
      }
    } catch (e) {
      print('Error handling status history change: $e');
    }
  }

  /// Handle notification changes
  void _handleNotificationChange(PostgresChangePayload payload) {
    try {
      print('🔔 Notification change detected: ${payload.eventType}');
      
      if (payload.newRecord != null) {
        _notificationsController.add(payload.newRecord!);
      }
    } catch (e) {
      print('Error handling notification change: $e');
    }
  }

  /// Handle complaint insert
  void _handleComplaintInsert(Map<String, dynamic>? record) {
    if (record == null) return;
    print('➕ New complaint inserted: ${record['complaint_number']}');
  }

  /// Handle complaint update
  void _handleComplaintUpdate(Map<String, dynamic>? oldRecord, Map<String, dynamic>? newRecord) {
    if (oldRecord == null || newRecord == null) return;
    
    final oldStatus = oldRecord['status'];
    final newStatus = newRecord['status'];
    
    if (oldStatus != newStatus) {
      print('🔄 Complaint status changed: $oldStatus → $newStatus');
      
      // Create status update notification
      final statusUpdate = ComplaintStatusUpdate(
        complaintId: newRecord['id'],
        oldStatus: oldStatus,
        newStatus: newStatus,
        updatedBy: 'System', // This would come from the actual updater
        remarks: newRecord['remarks'],
        timestamp: DateTime.now(),
      );
      
      _statusUpdatesController.add(statusUpdate);
    }
  }

  /// Handle complaint delete
  void _handleComplaintDelete(Map<String, dynamic>? record) {
    if (record == null) return;
    print('🗑️ Complaint deleted: ${record['complaint_number']}');
  }

  /// Refresh complaint lists
  Future<void> _refreshComplaintLists() async {
    try {
      // Get updated active complaints
      final activeData = await _databaseService.getUserActiveComplaints();
      final activeComplaints = activeData.map((data) => _complaintFromDatabaseMap(data)).toList();
      _activeComplaintsController.add(activeComplaints);

      // Get updated completed complaints
      final completedData = await _databaseService.getUserCompletedComplaints();
      final completedComplaints = completedData.map((data) => _complaintFromDatabaseMap(data)).toList();
      _completedComplaintsController.add(completedComplaints);
    } catch (e) {
      print('Error refreshing complaint lists: $e');
    }
  }

  /// Create notification for status change
  Future<void> _createStatusChangeNotification(ComplaintStatusUpdate statusUpdate) async {
    try {
      final statusMessages = {
        'Pending': 'Your complaint is being reviewed by our team.',
        'Under Investigation': 'Your complaint is now under active investigation.',
        'Requires More Information': 'Additional information is needed for your complaint.',
        'Resolved': 'Your complaint has been successfully resolved.',
        'Dismissed': 'Your complaint has been reviewed and dismissed.',
      };

      final message = statusMessages[statusUpdate.newStatus] ?? 
                     'Your complaint status has been updated to ${statusUpdate.newStatus}.';

      await _databaseService.saveNotification(
        title: 'Complaint Status Updated',
        message: message,
        type: 'info',
        priority: statusUpdate.newStatus == 'Resolved' ? 'high' : 'normal',
        category: 'complaint_status',
      );
    } catch (e) {
      print('Error creating status change notification: $e');
    }
  }

  /// Convert database map to Complaint object
  Complaint _complaintFromDatabaseMap(Map<String, dynamic> data) {
    try {
      // Parse evidence files
      final evidenceFiles = <EvidenceFile>[];
      if (data['evidence_files'] != null) {
        for (final evidenceData in data['evidence_files'] as List) {
          evidenceFiles.add(EvidenceFile(
            id: evidenceData['id'],
            fileName: evidenceData['file_name'],
            filePath: evidenceData['file_path'] ?? '',
            fileType: evidenceData['file_type'],
            fileSize: evidenceData['file_size'],
            uploadedAt: DateTime.parse(evidenceData['created_at']),
            downloadUrl: evidenceData['download_url'],
          ));
        }
      }

      // Parse assigned officer info
      String? assignedOfficer;
      if (data['case_assignments'] != null && 
          (data['case_assignments'] as List).isNotEmpty) {
        final assignment = (data['case_assignments'] as List).first;
        if (assignment['pnp_officer_profiles'] != null) {
          final officer = assignment['pnp_officer_profiles'];
          assignedOfficer = '${officer['rank']} ${officer['full_name']} (${officer['badge_number']})';
        }
      }

      return Complaint(
        id: data['id'],
        userId: data['user_id'],
        crimeType: CrimeType.values.firstWhere(
          (e) => e.name == data['crime_type'],
          orElse: () => CrimeType.phishing,
        ),
        title: data['title'],
        description: data['description'],
        evidenceFiles: evidenceFiles,
        fullName: data['full_name'],
        email: data['email'],
        phoneNumber: data['phone_number'],
        incidentDateTime: DateTime.parse(data['incident_date_time']),
        incidentLocation: data['incident_location'],
        estimatedFinancialLoss: data['estimated_loss']?.toDouble(),
        status: ComplaintStatus.values.firstWhere(
          (e) => e.displayName == data['status'],
          orElse: () => ComplaintStatus.pending,
        ),
        priority: data['priority'] ?? 'low',
        riskScore: data['risk_score'] ?? 30,
        assignedUnit: data['assigned_unit'],
        createdAt: DateTime.parse(data['created_at']),
        updatedAt: DateTime.parse(data['updated_at']),
        complaintNumber: data['complaint_number'],
        assignedOfficer: assignedOfficer,
        remarks: data['remarks'],
        statusHistory: [],
      );
    } catch (e) {
      print('Error converting database data to Complaint: $e');
      // Return a basic complaint object as fallback
      return Complaint(
        id: data['id'] ?? 'unknown',
        userId: data['user_id'] ?? '',
        crimeType: CrimeType.phishing,
        description: data['description'] ?? 'Unable to load description',
        fullName: data['full_name'] ?? 'Unknown',
        email: data['email'] ?? '',
        phoneNumber: data['phone_number'] ?? '',
        incidentDateTime: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  /// Get complaint by ID for real-time updates
  Future<Complaint?> getComplaint(String complaintId) async {
    try {
      final data = await _databaseService.getComplaint(complaintId);
      if (data == null) return null;
      
      return _complaintFromDatabaseMap(data);
    } catch (e) {
      print('Error getting complaint for real-time update: $e');
      return null;
    }
  }
}

/// Data class for complaint status updates
class ComplaintStatusUpdate {
  final String complaintId;
  final String? oldStatus;
  final String newStatus;
  final String updatedBy;
  final String? remarks;
  final DateTime timestamp;

  ComplaintStatusUpdate({
    required this.complaintId,
    this.oldStatus,
    required this.newStatus,
    required this.updatedBy,
    this.remarks,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'ComplaintStatusUpdate(complaintId: $complaintId, oldStatus: $oldStatus, newStatus: $newStatus, updatedBy: $updatedBy, timestamp: $timestamp)';
  }
}