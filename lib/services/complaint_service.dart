import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../models/complaint_model.dart';
import '../utils/philippine_time.dart';
import 'database_service.dart';
import 'ai_risk_assessment_service.dart';

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
        relatedComplaintId: complaintId,
      );

      // Create notification for assigned officer if exists
      if (complaint.assignedOfficerId != null && complaint.assignedOfficerId!.isNotEmpty) {
        try {
          // Determine priority based on risk score
          final notificationPriority = _getNotificationPriority(complaint.riskScore ?? 50);
          
          await _databaseService.saveNotificationForUser(
            userId: complaint.assignedOfficerId!,
            title: 'New Case Assignment',
            message: 'You have been assigned to case ${complaint.complaintNumber ?? complaintId} - ${complaint.crimeType.displayName}',
            type: 'case_assignment',
            priority: notificationPriority,
            category: 'officer_assignment',
                relatedComplaintId: complaintId,
            senderName: 'Case Management System',
            additionalData: {
              'crime_type': complaint.crimeType.name,
              'risk_score': complaint.riskScore,
              'priority': complaint.priority,
              'complainant_name': complaint.fullName,
            },
          );
          print('✅ Officer notification sent to: ${complaint.assignedOfficer}');
        } catch (e) {
          print('⚠️ Failed to send officer notification: $e');
          // Don't fail the processing if officer notification fails
        }
      }

      // Log analytics event
      await _databaseService.saveUserAnalytics(
        metricName: 'complaint_submitted',
        metricValue: {
          'complaint_id': complaintId,
          'crime_type': complaint.crimeType.name,
          'priority': complaint.priority,
          'risk_score': complaint.riskScore,
          'evidence_count': complaint.evidenceFiles.length,
          'has_assigned_officer': complaint.assignedOfficerId != null,
        },
      );
    } catch (e) {
      print('Error in post-submission processing: $e');
      // Don't throw error as submission was successful
    }
  }

  /// Get notification priority based on risk score
  String _getNotificationPriority(int riskScore) {
    if (riskScore >= 80) return 'urgent';
    if (riskScore >= 60) return 'high';
    if (riskScore >= 40) return 'normal';
    return 'low';
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
        assignedOfficer: assignedOfficer ?? data['assigned_officer'],
        assignedOfficerId: assignedOfficerId ?? data['assigned_officer_id'],
        remarks: data['remarks'],
        statusHistory: [], // Status history loaded separately when needed
        // AI Assessment Fields
        aiPriority: data['ai_priority'],
        aiRiskScore: data['ai_risk_score']?.toInt(),
        aiConfidenceScore: data['ai_confidence_score']?.toInt(),
        riskFactors: data['risk_factors'] != null 
            ? List<String>.from(data['risk_factors']) 
            : [],
        urgencyIndicators: data['urgency_indicators'] != null 
            ? List<String>.from(data['urgency_indicators']) 
            : [],
        lastAiAssessment: data['last_ai_assessment'] != null 
            ? DateTime.parse(data['last_ai_assessment']) 
            : null,
        aiReasoning: data['ai_reasoning'],
        // Dynamic fields mapping from snake_case to camelCase
        platformWebsite: data['platform_website'],
        accountReference: data['account_reference'],
        suspectName: data['suspect_name'],
        suspectRelationship: data['suspect_relationship'],
        suspectContact: data['suspect_contact'],
        suspectDetails: data['suspect_details'],
        systemDetails: data['system_details'],
        technicalInfo: data['technical_info'],
        vulnerabilityDetails: data['vulnerability_details'],
        attackVector: data['attack_vector'],
        securityLevel: data['security_level'],
        targetInfo: data['target_info'],
        impactAssessment: data['impact_assessment'],
        contentDescription: data['content_description'],
        // Complaint Editing Fields - mapping from snake_case to camelCase
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

  // =============================================
  // COMPLAINT UPDATE OPERATIONS
  // =============================================

  /// Update complaint when status is "Requires More Information"
  Future<Map<String, dynamic>> updateComplaint({
    required String complaintId,
    required Map<String, dynamic> updates,
    List<XFile>? newEvidenceFiles,
    String? updateReason,
    Map<String, dynamic>? deviceInfo,
  }) async {
    try {
      // Validate user can update this complaint
      final complaint = await getComplaintWithDetails(complaintId);
      if (complaint == null) {
        throw 'Complaint not found';
      }

      if (complaint.userId != currentUserId) {
        throw 'Unauthorized: You can only update your own complaints';
      }

      if (complaint.status != ComplaintStatus.requiresMoreInfo) {
        throw 'Complaint can only be updated when status is "Requires More Information"';
      }

      // Use the database function to apply updates
      final result = await _supabase.rpc('apply_complaint_update', params: {
        'p_complaint_id': complaintId,
        'p_firebase_uid': currentUserId,  // Pass Firebase UID
        'p_updates': updates,
        'p_update_reason': updateReason,
        'p_update_notes': 'Updated via mobile app',
        'p_device_info': deviceInfo,
      });

      if (result == null || result['success'] != true) {
        throw result?['error'] ?? 'Failed to update complaint';
      }

      // Upload new evidence files if provided
      if (newEvidenceFiles != null && newEvidenceFiles.isNotEmpty) {
        for (final file in newEvidenceFiles) {
          await _uploadEvidenceFile(complaintId, file);
        }
      }

      // Create notification for user
      await _databaseService.saveNotification(
        title: 'Complaint Updated Successfully',
        message: 'Your complaint ${complaint.complaintNumber} has been updated with the requested information.',
        type: 'success',
        priority: 'normal',
        category: 'complaint_status',
        relatedComplaintId: complaintId,
      );

      // Trigger AI re-assessment
      await _triggerAiReassessment(complaintId);

      // Log analytics event
      await _databaseService.saveUserAnalytics(
        metricName: 'complaint_updated',
        metricValue: {
          'complaint_id': complaintId,
          'fields_updated': updates.keys.toList(),
          'update_count': updates.length,
          'new_evidence_count': newEvidenceFiles?.length ?? 0,
        },
      );

      return {
        'success': true,
        'update_id': result['update_id'],
        'message': 'Complaint updated successfully',
      };
    } catch (e) {
      print('Error updating complaint: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get complaint update history
  Future<List<Map<String, dynamic>>> getComplaintUpdateHistory(String complaintId) async {
    try {
      final result = await _supabase
          .from('complaint_update_history')
          .select('*')
          .eq('complaint_id', complaintId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      print('Error getting update history: $e');
      return [];
    }
  }

  /// Upload evidence file for complaint update
  Future<void> _uploadEvidenceFile(String complaintId, XFile file) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final filePath = '$complaintId/$fileName';
      
      // Upload to storage
      final fileBytes = await file.readAsBytes();
      await _supabase.storage
          .from('evidence-files')
          .uploadBinary(filePath, fileBytes);

      // Get download URL
      final downloadUrl = _supabase.storage
          .from('evidence-files')
          .getPublicUrl(filePath);

      // Get proper MIME type from file extension (matching original complaint submission)
      final properMimeType = _getMimeTypeFromExtension(file.name);

      // Save file metadata
      await _supabase.from('evidence_files').insert({
        'complaint_id': complaintId,
        'file_name': fileName,
        'file_path': filePath,
        'file_type': properMimeType,
        'file_size': fileBytes.length,
        'download_url': downloadUrl,
      });
    } catch (e) {
      print('Error uploading evidence file: $e');
      throw 'Failed to upload evidence file: ${e.toString()}';
    }
  }

  /// Get proper MIME type from file extension (matches EvidenceFile.fromFile logic)
  String _getMimeTypeFromExtension(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    
    switch (extension) {
      // Image formats
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      case 'svg':
        return 'image/svg+xml';
      
      // Video formats
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'mkv':
        return 'video/x-matroska';
      case 'webm':
        return 'video/webm';
      case '3gp':
        return 'video/3gpp';
      
      // Audio formats
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'aac':
        return 'audio/aac';
      case 'm4a':
        return 'audio/mp4';
      
      // Document formats
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      case 'rtf':
        return 'application/rtf';
      
      // Archive formats
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/x-rar-compressed';
      case '7z':
        return 'application/x-7z-compressed';
      
      // Default fallback
      default:
        print('⚠️ Unknown file extension: $extension, using application/octet-stream');
        return 'application/octet-stream';
    }
  }

  /// Trigger AI re-assessment after complaint update
  Future<void> _triggerAiReassessment(String complaintId) async {
    try {
      print('🤖 Triggering AI re-assessment for updated complaint: $complaintId');
      
      // Get the updated complaint data
      final complaint = await getComplaintWithDetails(complaintId);
      if (complaint == null) {
        throw 'Complaint not found for re-assessment';
      }
      
      // Prepare suspect info for AI assessment
      final suspectInfo = {
        'name': complaint.suspectName,
        'relationship': complaint.suspectRelationship,
        'contact': complaint.suspectContact,
        'details': complaint.suspectDetails,
      };
      
      // Perform AI risk assessment with updated data
      final assessment = await AIRiskAssessmentService.assessComplaint(
        description: complaint.description,
        crimeType: complaint.crimeType,
        evidenceFiles: complaint.evidenceFiles,
        financialLoss: complaint.estimatedFinancialLoss,
        suspectInfo: suspectInfo,
        incidentDate: complaint.incidentDateTime,
        incidentLocation: complaint.incidentLocation,
        complaintId: complaintId,
      );
      
      // Update complaint with new AI assessment results
      await _supabase
          .from('complaints')
          .update({
            'ai_priority': assessment.aiPriority,
            'ai_risk_score': assessment.aiRiskScore,
            'ai_confidence_score': assessment.confidenceScore,
            'risk_factors': assessment.riskFactors,
            'urgency_indicators': assessment.urgencyIndicators,
            'ai_reasoning': assessment.reasoning,
            'last_ai_assessment': PhilippineTime.toUtc(PhilippineTime.now()).toIso8601String(),
          })
          .eq('id', complaintId);
      
      // Mark AI reassessment as completed in updates table
      await _supabase
          .from('complaint_updates')
          .update({'ai_reassessment_completed': true})
          .eq('complaint_id', complaintId)
          .eq('ai_reassessment_completed', false);
      
      print('✅ AI re-assessment completed successfully');
      
      // Create notification about AI re-assessment
      await _databaseService.saveNotification(
        title: 'AI Assessment Updated',
        message: 'Your complaint has been re-analyzed with updated information. Risk score: ${assessment.aiRiskScore}%',
        type: 'info',
        priority: 'normal',
        category: 'complaint_status',
        relatedComplaintId: complaintId,
      );
      
    } catch (e) {
      print('❌ Error triggering AI reassessment: $e');
      // Don't throw error as this is not critical for the update process
    }
  }
}