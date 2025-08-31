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
  final StreamController<Map<String, dynamic>> _officerAssignmentController = 
      StreamController<Map<String, dynamic>>.broadcast();

  // Subscription references
  RealtimeChannel? _complaintsChannel;
  RealtimeChannel? _statusHistoryChannel;
  RealtimeChannel? _notificationsChannel;
  RealtimeChannel? _caseAssignmentsChannel;

  // Getters for streams
  Stream<ComplaintStatusUpdate> get statusUpdates => _statusUpdatesController.stream;
  Stream<List<Complaint>> get activeComplaints => _activeComplaintsController.stream;
  Stream<List<Complaint>> get completedComplaints => _completedComplaintsController.stream;
  Stream<Map<String, dynamic>> get notifications => _notificationsController.stream;
  Stream<Map<String, dynamic>> get officerAssignments => _officerAssignmentController.stream;

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
      await _subscribeToCaseAssignments();
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
    _caseAssignmentsChannel?.unsubscribe();
    
    _statusUpdatesController.close();
    _activeComplaintsController.close();
    _completedComplaintsController.close();
    _notificationsController.close();
    _officerAssignmentController.close();
    
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
        table: 'status_history',
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
          orElse: () => ComplaintStatus.toBeAssigned,
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
        // Citizen update fields for complaint editing
        lastCitizenUpdate: data['last_citizen_update'] != null 
            ? DateTime.parse(data['last_citizen_update']) 
            : null,
        updateRequestMessage: data['update_request_message'],
        totalUpdates: data['total_updates'] ?? 0,
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

  /// Subscribe to case assignment changes (for officers)
  Future<void> _subscribeToCaseAssignments() async {
    if (currentUserId == null) return;

    _caseAssignmentsChannel = _supabase.channel('case_assignments_$currentUserId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'case_assignments',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'officer_id',
          value: currentUserId!,
        ),
        callback: _handleCaseAssignmentChange,
      )
      .subscribe();
  }

  /// Handle case assignment changes (for officer notifications)
  void _handleCaseAssignmentChange(PostgresChangePayload payload) {
    try {
      print('👮 Case assignment change detected: ${payload.eventType}');
      
      switch (payload.eventType) {
        case PostgresChangeEvent.insert:
          _handleNewCaseAssignment(payload.newRecord);
          break;
        case PostgresChangeEvent.update:
          _handleCaseAssignmentUpdate(payload.oldRecord, payload.newRecord);
          break;
        case PostgresChangeEvent.delete:
          _handleCaseAssignmentRemoval(payload.oldRecord);
          break;
        default:
          break;
      }
    } catch (e) {
      print('Error handling case assignment change: $e');
    }
  }

  /// Handle new case assignment
  void _handleNewCaseAssignment(Map<String, dynamic>? record) {
    if (record == null) return;
    
    print('🚨 New case assigned: ${record['complaint_id']}');
    
    // Notify the officer assignment stream
    _officerAssignmentController.add({
      'type': 'new_assignment',
      'complaint_id': record['complaint_id'],
      'officer_id': record['officer_id'],
      'assigned_at': record['assigned_at'],
      'status': record['status'],
    });

    // Create notification for the officer
    _createOfficerAssignmentNotification(record);
  }

  /// Handle case assignment updates
  void _handleCaseAssignmentUpdate(Map<String, dynamic>? oldRecord, Map<String, dynamic>? newRecord) {
    if (oldRecord == null || newRecord == null) return;
    
    print('🔄 Case assignment updated: ${newRecord['complaint_id']}');
    
    _officerAssignmentController.add({
      'type': 'assignment_update',
      'complaint_id': newRecord['complaint_id'],
      'old_status': oldRecord['status'],
      'new_status': newRecord['status'],
      'updated_at': PhilippineTime.toUtc(PhilippineTime.now()).toIso8601String(),
    });
  }

  /// Handle case assignment removal
  void _handleCaseAssignmentRemoval(Map<String, dynamic>? record) {
    if (record == null) return;
    
    print('🗑️ Case assignment removed: ${record['complaint_id']}');
    
    _officerAssignmentController.add({
      'type': 'assignment_removed',
      'complaint_id': record['complaint_id'],
      'officer_id': record['officer_id'],
      'removed_at': PhilippineTime.toUtc(PhilippineTime.now()).toIso8601String(),
    });
  }

  /// Create notification for officer assignment
  Future<void> _createOfficerAssignmentNotification(Map<String, dynamic> assignmentRecord) async {
    try {
      // Get complaint details
      final complaintData = await _supabase
          .from('complaints')
          .select('complaint_number, crime_type, title, priority')
          .eq('id', assignmentRecord['complaint_id'])
          .single();

      await _databaseService.saveNotification(
        title: '🚨 New Case Assignment',
        message: 'You have been assigned to case ${complaintData['complaint_number']}: ${complaintData['title']}',
        type: 'case_assignment',
        priority: complaintData['priority'] ?? 'medium',
        category: 'officer_assignment',
        actionUrl: '/case/${assignmentRecord['complaint_id']}',
      );

      print('✅ Officer assignment notification created');
    } catch (e) {
      print('❌ Error creating officer assignment notification: $e');
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