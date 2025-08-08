import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/complaint_model.dart';
import '../utils/philippine_time.dart';
import 'database_service.dart';

/// Specialized service for advanced complaint operations
/// Built on top of DatabaseService for enhanced functionality
class ComplaintService {
  final DatabaseService _databaseService = DatabaseService();
  final SupabaseClient _supabase = Supabase.instance.client;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // =============================================
  // ADVANCED COMPLAINT OPERATIONS
  // =============================================

  /// Submit a new complaint with enhanced validation and processing
  Future<String?> submitComplaint(Complaint complaint) async {
    try {
      // Pre-submission validation
      if (!_validateComplaint(complaint)) {
        throw 'Complaint validation failed';
      }

      // Check for duplicate complaints
      final isDuplicate = await _checkForDuplicateComplaint(complaint);
      if (isDuplicate) {
        throw 'A similar complaint has already been submitted recently';
      }

      // Submit using the database service
      final complaintId = await _databaseService.submitComplaint(complaint);
      
      if (complaintId != null) {
        // Post-submission processing
        await _postSubmissionProcessing(complaintId, complaint);
      }

      return complaintId;
    } catch (e) {
      print('ComplaintService Error: $e');
      rethrow;
    }
  }

  /// Get complaints with enhanced filtering and sorting
  Future<List<Complaint>> getComplaints({
    ComplaintStatus? status,
    String? priority,
    CrimeType? crimeType,
    DateTime? fromDate,
    DateTime? toDate,
    String sortBy = 'created_at',
    bool ascending = false,
    int limit = 50,
  }) async {
    try {
      List<Map<String, dynamic>> rawData;
      
      if (status != null && (status == ComplaintStatus.resolved || status == ComplaintStatus.dismissed)) {
        rawData = await _databaseService.getUserCompletedComplaints();
      } else {
        rawData = await _databaseService.getUserActiveComplaints();
      }

      // Convert to Complaint objects
      var complaints = rawData.map((data) => _complaintFromDatabaseMap(data)).toList();

      // Apply additional filters
      complaints = _applyFilters(complaints, 
        status: status,
        priority: priority,
        crimeType: crimeType,
        fromDate: fromDate,
        toDate: toDate,
      );

      // Apply sorting
      complaints = _applySorting(complaints, sortBy: sortBy, ascending: ascending);

      // Apply limit
      if (complaints.length > limit) {
        complaints = complaints.take(limit).toList();
      }

      return complaints;
    } catch (e) {
      print('Error getting filtered complaints: $e');
      return [];
    }
  }

  /// Get complaint with detailed information including status history
  Future<Complaint?> getComplaintWithDetails(String complaintId) async {
    try {
      final complaintData = await _databaseService.getComplaint(complaintId);
      if (complaintData == null) return null;

      final complaint = _complaintFromDatabaseMap(complaintData);

      // Load status history
      final statusHistory = await _databaseService.getComplaintStatusHistory(complaintId);
      final statusUpdates = statusHistory.map((data) => StatusUpdate(
        status: ComplaintStatus.values.firstWhere(
          (e) => e.displayName == data['status'],
          orElse: () => ComplaintStatus.pending,
        ),
        timestamp: DateTime.parse(data['timestamp']),
        updatedBy: data['updated_by'],
        remarks: data['remarks'],
      )).toList();

      // Return complaint with complete status history
      return complaint.copyWith(statusHistory: statusUpdates);
    } catch (e) {
      print('Error getting complaint details: $e');
      return null;
    }
  }

  /// Get complaint statistics and analytics
  Future<Map<String, dynamic>> getComplaintAnalytics() async {
    try {
      final stats = await _databaseService.getUserComplaintStats();
      
      // Enhanced analytics
      final analytics = Map<String, dynamic>.from(stats);
      
      // Calculate additional metrics
      final total = analytics['total'] ?? 0;
      final resolved = analytics['resolved'] ?? 0;
      final dismissed = analytics['dismissed'] ?? 0;
      final active = (analytics['pending'] ?? 0) + 
                    (analytics['under_investigation'] ?? 0) + 
                    (analytics['requires_more_info'] ?? 0);

      analytics['active_cases'] = active;
      analytics['completed_cases'] = resolved + dismissed;
      analytics['success_rate'] = total > 0 ? ((resolved / total) * 100).round() : 0;
      analytics['resolution_rate'] = total > 0 ? (((resolved + dismissed) / total) * 100).round() : 0;

      return analytics;
    } catch (e) {
      print('Error getting complaint analytics: $e');
      return {};
    }
  }

  /// Search complaints by text query
  Future<List<Complaint>> searchComplaints(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      // Get all user complaints
      final activeData = await _databaseService.getUserActiveComplaints();
      final completedData = await _databaseService.getUserCompletedComplaints();
      
      final allData = [...activeData, ...completedData];
      final allComplaints = allData.map((data) => _complaintFromDatabaseMap(data)).toList();

      // Filter by query
      final lowercaseQuery = query.toLowerCase();
      final filteredComplaints = allComplaints.where((complaint) {
        return complaint.description.toLowerCase().contains(lowercaseQuery) ||
               complaint.crimeType.displayName.toLowerCase().contains(lowercaseQuery) ||
               (complaint.complaintNumber?.toLowerCase().contains(lowercaseQuery) ?? false) ||
               (complaint.assignedUnit?.toLowerCase().contains(lowercaseQuery) ?? false);
      }).toList();

      // Sort by relevance (exact matches first, then partial matches)
      filteredComplaints.sort((a, b) {
        final aExact = a.description.toLowerCase() == lowercaseQuery ? 1 : 0;
        final bExact = b.description.toLowerCase() == lowercaseQuery ? 1 : 0;
        return bExact.compareTo(aExact);
      });

      return filteredComplaints;
    } catch (e) {
      print('Error searching complaints: $e');
      return [];
    }
  }

  /// Load status history for a specific complaint with caching
  Future<List<StatusUpdate>> loadComplaintStatusHistory(String complaintId) async {
    try {
      print('🔄 [ComplaintService] Loading status history for complaint: $complaintId');
      
      // Validate complaint ID
      if (complaintId.isEmpty) {
        print('❌ [ComplaintService] Empty complaint ID provided');
        return [];
      }
      
      // Get status history from database
      final statusHistory = await _databaseService.getComplaintStatusHistory(complaintId);
      
      print('📊 [ComplaintService] Raw status history data: ${statusHistory.length} records');
      
      if (statusHistory.isEmpty) {
        print('⚠️ [ComplaintService] No status history found for complaint: $complaintId');
        return [];
      }
      
      // Debug: Print raw data structure
      print('📊 [ComplaintService] First raw entry: ${statusHistory[0]}');
      
      // Convert to StatusUpdate objects
      final statusUpdates = <StatusUpdate>[];
      
      for (int i = 0; i < statusHistory.length; i++) {
        final data = statusHistory[i];
        try {
          // Debug each conversion
          print('🔄 [ComplaintService] Converting entry $i: ${data['status']} by ${data['updated_by']}');
          
          final statusUpdate = StatusUpdate(
            status: ComplaintStatus.values.firstWhere(
              (e) => e.displayName == data['status'],
              orElse: () {
                print('⚠️ [ComplaintService] Unknown status: ${data['status']}, defaulting to pending');
                return ComplaintStatus.pending;
              },
            ),
            timestamp: DateTime.parse(data['timestamp']),
            updatedBy: data['updated_by'],
            remarks: data['remarks'],
          );
          
          statusUpdates.add(statusUpdate);
          print('✅ [ComplaintService] Successfully converted entry $i');
        } catch (convertError) {
          print('❌ [ComplaintService] Error converting entry $i: $convertError');
          print('❌ [ComplaintService] Raw data: $data');
        }
      }
      
      print('✅ [ComplaintService] Loaded ${statusUpdates.length} status updates for complaint: $complaintId');
      return statusUpdates;
    } catch (e) {
      print('❌ [ComplaintService] Error loading status history for complaint $complaintId: $e');
      print('❌ [ComplaintService] Error type: ${e.runtimeType}');
      return [];
    }
  }

  /// Update complaint object with loaded status history
  Complaint updateComplaintWithStatusHistory(Complaint complaint, List<StatusUpdate> statusHistory) {
    return complaint.copyWith(statusHistory: statusHistory);
  }

  // =============================================
  // PRIVATE HELPER METHODS
  // =============================================

  /// Validate complaint before submission
  bool _validateComplaint(Complaint complaint) {
    // Basic required fields validation
    if (complaint.userId.isEmpty ||
        complaint.description.trim().isEmpty ||
        complaint.fullName.trim().isEmpty ||
        complaint.email.trim().isEmpty ||
        complaint.phoneNumber.trim().isEmpty) {
      return false;
    }

    // Email validation
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(complaint.email)) {
      return false;
    }

    // Phone number validation (Philippine format)
    final phoneRegex = RegExp(r'^(\+63|63|0)?[0-9]{10}$');
    if (!phoneRegex.hasMatch(complaint.phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), ''))) {
      return false;
    }

    // Evidence file validation
    if (complaint.evidenceFiles.length > 5) {
      return false;
    }

    final totalSize = complaint.evidenceFiles.fold<int>(0, (sum, file) => sum + file.fileSize);
    if (totalSize > 25 * 1024 * 1024) { // 25MB limit
      return false;
    }

    return true;
  }

  /// Check for duplicate complaints
  Future<bool> _checkForDuplicateComplaint(Complaint complaint) async {
    try {
      if (currentUserId == null) return false;

      // Get recent complaints (last 24 hours)
      final oneDayAgo = DateTime.now().subtract(const Duration(days: 1));
      final recentComplaints = await _supabase
          .from('complaints')
          .select('description, crime_type, created_at')
          .eq('user_id', currentUserId!)
          .gte('created_at', oneDayAgo.toUtc().toIso8601String());

      // Check for similar complaints
      for (final existingComplaint in recentComplaints) {
        if (existingComplaint['crime_type'] == complaint.crimeType.name &&
            _calculateSimilarity(existingComplaint['description'], complaint.description) > 0.8) {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error checking for duplicates: $e');
      return false;
    }
  }

  /// Calculate text similarity between two strings
  double _calculateSimilarity(String text1, String text2) {
    if (text1 == text2) return 1.0;
    
    final words1 = text1.toLowerCase().split(' ').toSet();
    final words2 = text2.toLowerCase().split(' ').toSet();
    
    final intersection = words1.intersection(words2);
    final union = words1.union(words2);
    
    return union.isEmpty ? 0.0 : intersection.length / union.length;
  }

  /// Post-submission processing
  Future<void> _postSubmissionProcessing(String complaintId, Complaint complaint) async {
    try {
      // Create notification for user
      await _databaseService.saveNotification(
        title: 'Complaint Submitted Successfully',
        message: 'Your complaint ${complaint.complaintNumber ?? complaintId} has been submitted and is being reviewed.',
        type: 'success',
        priority: 'normal',
        category: 'complaint_status',
      );

      // Log analytics event
      await _databaseService.saveUserAnalytics(
        metricName: 'complaint_submitted',
        metricValue: {
          'complaint_id': complaintId,
          'crime_type': complaint.crimeType.name,
          'priority': complaint.priority,
          'risk_score': complaint.riskScore,
          'evidence_count': complaint.evidenceFiles.length,
        },
      );
    } catch (e) {
      print('Error in post-submission processing: $e');
      // Don't throw error as submission was successful
    }
  }

  /// Convert database map to Complaint object
  Complaint _complaintFromDatabaseMap(Map<String, dynamic> data) {
    try {
      // Debug: Print complaint ID information
      print('📊 [ComplaintService] Mapping complaint data:');
      print('   - ID (UUID): ${data['id']}');
      print('   - Complaint Number: ${data['complaint_number']}');
      print('   - Status: ${data['status']}');
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
      String? assignedOfficerId;
      if (data['case_assignments'] != null && 
          (data['case_assignments'] as List).isNotEmpty) {
        final assignment = (data['case_assignments'] as List).first;
        if (assignment['pnp_officer_profiles'] != null) {
          final officer = assignment['pnp_officer_profiles'];
          assignedOfficer = '${officer['rank']} ${officer['full_name']} (${officer['badge_number']})';
          assignedOfficerId = officer['id'];
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
        assignedOfficerId: assignedOfficerId,
        remarks: data['remarks'],
        statusHistory: [], // Status history loaded separately when needed
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

  /// Apply filters to complaint list
  List<Complaint> _applyFilters(
    List<Complaint> complaints, {
    ComplaintStatus? status,
    String? priority,
    CrimeType? crimeType,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    var filtered = complaints;

    if (status != null) {
      filtered = filtered.where((c) => c.status == status).toList();
    }

    if (priority != null) {
      filtered = filtered.where((c) => c.priority == priority).toList();
    }

    if (crimeType != null) {
      filtered = filtered.where((c) => c.crimeType == crimeType).toList();
    }

    if (fromDate != null) {
      filtered = filtered.where((c) => c.createdAt.isAfter(fromDate)).toList();
    }

    if (toDate != null) {
      filtered = filtered.where((c) => c.createdAt.isBefore(toDate)).toList();
    }

    return filtered;
  }

  /// Apply sorting to complaint list
  List<Complaint> _applySorting(
    List<Complaint> complaints, {
    required String sortBy,
    required bool ascending,
  }) {
    complaints.sort((a, b) {
      int comparison = 0;
      
      switch (sortBy) {
        case 'created_at':
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case 'updated_at':
          comparison = a.updatedAt.compareTo(b.updatedAt);
          break;
        case 'priority':
          final priorityOrder = {'high': 3, 'medium': 2, 'low': 1};
          comparison = (priorityOrder[a.priority] ?? 1).compareTo(priorityOrder[b.priority] ?? 1);
          break;
        case 'risk_score':
          comparison = a.riskScore.compareTo(b.riskScore);
          break;
        case 'crime_type':
          comparison = a.crimeType.displayName.compareTo(b.crimeType.displayName);
          break;
        case 'status':
          comparison = a.status.displayName.compareTo(b.status.displayName);
          break;
        default:
          comparison = a.createdAt.compareTo(b.createdAt);
      }

      return ascending ? comparison : -comparison;
    });

    return complaints;
  }
}