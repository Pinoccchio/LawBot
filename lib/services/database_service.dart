import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'dart:io';
import 'dart:typed_data';
import '../utils/philippine_time.dart';
import '../models/complaint_model.dart';
import 'ai_risk_assessment_service.dart';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  DatabaseService() {
    // Set up Firebase auth listener
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }
  
  // Update Supabase session when Firebase auth state changes
  Future<void> _onAuthStateChanged(firebase_auth.User? user) async {
    if (user != null) {
      print('✅ Firebase user authenticated: ${user.uid}');
    } else {
      print('ℹ️ Firebase user signed out');
    }
  }

  // Get current user ID from Firebase
  String? get currentUserId => _auth.currentUser?.uid;

  // =============================================
  // USER PROFILE OPERATIONS
  // =============================================

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (currentUserId == null) return null;
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('firebase_uid', currentUserId!)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Create user profile
  Future<void> createUserProfile({
    required String firebaseUid,
    required String email,
    required String fullName,
    required String phoneNumber,
    String userType = 'CLIENT',
  }) async {
    try {
      print('Creating user profile for: $firebaseUid');
      // Insert user profile
      await _supabase.from('user_profiles').insert({
        'firebase_uid': firebaseUid,
        'email': email,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'user_type': userType,
        'user_status': 'active',
        'last_active': PhilippineTime.toUtc(PhilippineTime.now()).toIso8601String(),
        'created_at': PhilippineTime.toUtc(PhilippineTime.now()).toIso8601String(),
        'updated_at': PhilippineTime.toUtc(PhilippineTime.now()).toIso8601String(),
      });
      print('✅ User profile created successfully');
    } catch (e) {
      print('❌ Error creating user profile: $e');
      throw 'Failed to create user profile: $e';
    }
  }

  // Enhanced profile picture upload with better file management
  Future<String> uploadProfilePicture(String filePath) async {
    try {
      if (currentUserId == null) {
        throw 'User not authenticated';
      }

      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final fileExt = filePath.split('.').last.toLowerCase();

      // Create unique filename with timestamp to avoid caching issues
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$currentUserId/avatar_$timestamp.$fileExt';

      print('📤 Uploading profile picture: $fileName');

      // Delete existing profile pictures for this user
      try {
        final existingFiles = await _supabase.storage
            .from('profile-pictures')
            .list(path: currentUserId!);

        for (final existingFile in existingFiles) {
          await _supabase.storage
              .from('profile-pictures')
              .remove(['$currentUserId/${existingFile.name}']);
          print('🗑️ Deleted old profile picture: ${existingFile.name}');
        }
      } catch (e) {
        print('⚠️ No existing profile picture to delete or error deleting: $e');
      }

      // Upload new profile picture using regular client with public bucket
      await _supabase.storage
          .from('profile-pictures')
          .uploadBinary(fileName, Uint8List.fromList(bytes));

      // Get public URL
      final publicUrl = _supabase.storage
          .from('profile-pictures')
          .getPublicUrl(fileName);

      print('✅ Profile picture uploaded successfully: $publicUrl');
      return publicUrl;

    } catch (e) {
      print('❌ Error uploading profile picture: $e');
      throw 'Failed to upload profile picture: $e';
    }
  }

  // Enhanced profile update method
  Future<void> updateUserProfile({
    String? fullName,
    String? phoneNumber,
    String? profilePictureUrl,
  }) async {
    try {
      if (currentUserId == null) {
        throw 'User not authenticated';
      }

      final updateData = <String, dynamic>{
        'updated_at': PhilippineTime.toUtc(PhilippineTime.now()).toIso8601String(),
      };

      if (fullName != null) updateData['full_name'] = fullName;
      if (phoneNumber != null) updateData['phone_number'] = phoneNumber;
      if (profilePictureUrl != null) updateData['profile_picture_url'] = profilePictureUrl;

      print('📝 Updating user profile with data: $updateData');

      await _supabase
          .from('user_profiles')
          .update(updateData)
          .eq('firebase_uid', currentUserId!);

      print('✅ User profile updated successfully');
    } catch (e) {
      print('❌ Error updating user profile: $e');
      throw 'Failed to update user profile: $e';
    }
  }

  // Update user's last active timestamp
  Future<void> updateUserLastActive() async {
    try {
      if (currentUserId == null) return;
      await _supabase
          .from('user_profiles')
          .update({
        'last_active': PhilippineTime.toUtc(PhilippineTime.now()).toIso8601String(),
      })
          .eq('firebase_uid', currentUserId!);
    } catch (e) {
      print('Error updating last active: $e');
    }
  }

  // Get user status and type
  Future<Map<String, dynamic>?> getUserStatusAndType() async {
    try {
      if (currentUserId == null) return null;
      final response = await _supabase
          .from('user_profiles')
          .select('user_status, user_type')
          .eq('firebase_uid', currentUserId!)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Error getting user status and type: $e');
      return null;
    }
  }

  // Delete user account and all associated data
  Future<void> deleteUserAccount() async {
    try {
      if (currentUserId == null) return;
      // Delete user profile (cascading deletes will handle related data)
      await _supabase
          .from('user_profiles')
          .delete()
          .eq('firebase_uid', currentUserId!);
      print('✅ User account deleted from database');
    } catch (e) {
      print('❌ Error deleting user account: $e');
      throw 'Failed to delete user account: $e';
    }
  }

  // =============================================
  // NOTIFICATION OPERATIONS
  // =============================================

  // Get notifications for current user
  Future<List<Map<String, dynamic>>> getNotifications({
    bool unreadOnly = false,
    String? category,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      if (currentUserId == null) return [];
      // Apply filters first, then transformations
      var query = _supabase
          .from('notifications')
          .select()
          .eq('user_id', currentUserId!);

      if (unreadOnly) {
        query = query.eq('is_read', false);
      }

      if (category != null) {
        query = query.eq('notification_category', category);
      }

      // Apply transformations after filters
      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }

  // Get notification statistics
  Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      if (currentUserId == null) return {};

      final unreadResponse = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', currentUserId!)
          .eq('is_read', false);

      final urgentResponse = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', currentUserId!)
          .eq('is_read', false)
          .eq('priority', 'urgent');

      return {
        'unread_notifications': unreadResponse.length,
        'urgent_notifications': urgentResponse.length,
      };
    } catch (e) {
      print('Error getting notification stats: $e');
      return {};
    }
  }

  // Mark notification as read
  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({
        'is_read': true,
        'read_at': PhilippineTime.toUtc(PhilippineTime.now()).toIso8601String(),
      })
          .eq('id', notificationId)
          .eq('user_id', currentUserId!);
      return true;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  // Mark all notifications as read
  Future<bool> markAllNotificationsAsRead() async {
    try {
      if (currentUserId == null) return false;
      await _supabase
          .from('notifications')
          .update({
        'is_read': true,
        'read_at': PhilippineTime.toUtc(PhilippineTime.now()).toIso8601String(),
      })
          .eq('user_id', currentUserId!)
          .eq('is_read', false);
      return true;
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }

  // Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId)
          .eq('user_id', currentUserId!);
      return true;
    } catch (e) {
      print('Error deleting notification: $e');
      return false;
    }
  }

  // Save notification
  Future<bool> saveNotification({
    required String title,
    required String message,
    String type = 'info',
    String priority = 'normal',
    String category = 'system',
    String? actionUrl,
  }) async {
    try {
      if (currentUserId == null) return false;
      await _supabase.from('notifications').insert({
        'user_id': currentUserId!,
        'title': title,
        'message': message,
        'type': type,
        'priority': priority,
        'notification_category': category,
        'action_url': actionUrl,
        'created_at': PhilippineTime.toUtc(PhilippineTime.now()).toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Error saving notification: $e');
      return false;
    }
  }

  // Get urgent notifications
  Future<List<Map<String, dynamic>>> getUrgentNotifications() async {
    try {
      return await getNotifications(
        unreadOnly: true,
        limit: 10,
      ).then((notifications) =>
          notifications.where((n) => n['priority'] == 'urgent').toList()
      );
    } catch (e) {
      print('Error getting urgent notifications: $e');
      return [];
    }
  }

  // =============================================
  // ANALYTICS OPERATIONS (SIMPLIFIED)
  // =============================================

  // Save user analytics event
  Future<bool> saveUserAnalytics({
    required String metricName,
    required Map<String, dynamic> metricValue,
  }) async {
    try {
      // For now, just log analytics - you can implement proper storage later
      print('📊 Analytics: $metricName - $metricValue');
      return true;
    } catch (e) {
      print('Error saving analytics: $e');
      return false;
    }
  }

  // Delete profile picture from Supabase storage
  Future<void> deleteProfilePicture(String imageUrl) async {
    try {
      if (currentUserId == null) return;
      // Extract file path from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final fileName = '${pathSegments[pathSegments.length - 2]}/${pathSegments.last}';

      // Use regular client for profile picture deletion with public bucket
      await _supabase.storage
          .from('profile-pictures')
          .remove([fileName]);
      print('✅ Profile picture deleted');
    } catch (e) {
      print('Error deleting profile picture: $e');
    }
  }

  // =============================================
  // COMPLAINT OPERATIONS
  // =============================================

  // Submit a new complaint
  Future<String?> submitComplaint(Complaint complaint) async {
    try {
      if (currentUserId == null) {
        throw 'User not authenticated';
      }

      // Generate complaint number
      final now = PhilippineTime.now();
      final year = now.year;
      
      // Get the latest complaint number for this year
      final latestResponse = await _supabase
          .from('complaints')
          .select('complaint_number')
          .like('complaint_number', 'CYB-$year-%')
          .order('created_at', ascending: false)
          .limit(1);

      int sequenceNumber = 1;
      if (latestResponse.isNotEmpty) {
        final latestNumber = latestResponse.first['complaint_number'] as String;
        final parts = latestNumber.split('-');
        if (parts.length == 3) {
          sequenceNumber = (int.tryParse(parts[2]) ?? 0) + 1;
        }
      }

      final complaintNumber = 'CYB-$year-${sequenceNumber.toString().padLeft(3, '0')}';

      print('📝 Submitting complaint: $complaintNumber');

      // Prepare complaint data for database
      final complaintData = {
        'user_id': currentUserId!,
        'complaint_number': complaintNumber,
        'crime_type': complaint.crimeType.name,
        'title': _generateComplaintTitle(complaint.crimeType, complaint.description),
        'description': complaint.description,
        'full_name': complaint.fullName,
        'email': complaint.email,
        'phone_number': complaint.phoneNumber,
        'incident_date_time': complaint.incidentDateTime.toUtc().toIso8601String(),
        'incident_location': complaint.incidentLocation,
        'estimated_loss': complaint.estimatedFinancialLoss,
        'status': 'Pending',
        'priority': _calculatePriority(complaint.crimeType, complaint.estimatedFinancialLoss),
        'risk_score': _calculateRiskScore(complaint.crimeType, complaint.estimatedFinancialLoss),
        'assigned_unit': complaint.crimeType.assignedUnit,
        'created_at': PhilippineTime.toUtc(now).toIso8601String(),
        'updated_at': PhilippineTime.toUtc(now).toIso8601String(),
      };

      // Insert complaint
      final response = await _supabase
          .from('complaints')
          .insert(complaintData)
          .select('id')
          .single();

      final complaintId = response['id'] as String;

      // Upload evidence files if any
      if (complaint.evidenceFiles.isNotEmpty) {
        await _uploadEvidenceFiles(complaintId, complaint.evidenceFiles);
      }

      // Add initial status history
      await _addStatusUpdate(
        complaintId,
        'Pending',
        'System',
        'Complaint submitted successfully',
      );

      print('✅ Complaint submitted successfully: $complaintNumber');
      return complaintId;

    } catch (e) {
      print('❌ Error submitting complaint: $e');
      throw 'Failed to submit complaint: $e';
    }
  }

  // Get user's active complaints (Pending, Under Investigation, Requires More Info)
  Future<List<Map<String, dynamic>>> getUserActiveComplaints() async {
    try {
      if (currentUserId == null) {
        print('❌ No current user ID for getUserActiveComplaints');
        return [];
      }

      print('🔍 Fetching active complaints for user: $currentUserId');

      // First, get complaints without complex JOINs (safer approach)
      final response = await _supabase
          .from('complaints')
          .select('*')
          .eq('user_id', currentUserId!)
          .inFilter('status', ['Pending', 'Under Investigation', 'Requires More Information'])
          .order('created_at', ascending: false);

      if (response == null || (response as List).isEmpty) {
        print('❌ No active complaints found for user: $currentUserId');
        return [];
      }

      print('✅ Found ${(response as List).length} active complaints');

      // Process each complaint and add related data separately
      List<Map<String, dynamic>> complaintsWithData = [];

      for (var complaint in response as List) {
        Map<String, dynamic> complaintData = Map<String, dynamic>.from(complaint);

        try {
          // Get evidence files separately
          final evidenceResponse = await _supabase
              .from('evidence_files')
              .select('*')
              .eq('complaint_id', complaint['id']);

          complaintData['evidence_files'] = evidenceResponse ?? [];
        } catch (e) {
          print('⚠️ Error getting evidence files for complaint ${complaint['id']}: $e');
          complaintData['evidence_files'] = [];
        }

        try {
          // Get case assignments separately (if they exist)
          final assignmentResponse = await _supabase
              .from('case_assignments')
              .select('''
                *,
                pnp_officer_profiles(
                  full_name,
                  badge_number,
                  rank
                )
              ''')
              .eq('complaint_id', complaint['id']);

          complaintData['case_assignments'] = assignmentResponse ?? [];
        } catch (e) {
          print('⚠️ Error getting case assignments for complaint ${complaint['id']}: $e');
          complaintData['case_assignments'] = [];
        }

        complaintsWithData.add(complaintData);
      }

      print('✅ Successfully processed ${complaintsWithData.length} complaints with related data');
      return complaintsWithData;
    } catch (e) {
      print('❌ Error getting active complaints: $e');
      return [];
    }
  }

  // Get user's completed complaints (Resolved, Dismissed)
  Future<List<Map<String, dynamic>>> getUserCompletedComplaints() async {
    try {
      if (currentUserId == null) {
        print('❌ No current user ID for getUserCompletedComplaints');
        return [];
      }

      print('🔍 Fetching completed complaints for user: $currentUserId');

      // First, get complaints without complex JOINs (safer approach)
      final response = await _supabase
          .from('complaints')
          .select('*')
          .eq('user_id', currentUserId!)
          .inFilter('status', ['Resolved', 'Dismissed'])
          .order('updated_at', ascending: false);

      if (response == null || (response as List).isEmpty) {
        print('❌ No completed complaints found for user: $currentUserId');
        return [];
      }

      print('✅ Found ${(response as List).length} completed complaints');

      // Process each complaint and add related data separately
      List<Map<String, dynamic>> complaintsWithData = [];

      for (var complaint in response as List) {
        Map<String, dynamic> complaintData = Map<String, dynamic>.from(complaint);

        try {
          // Get evidence files separately
          final evidenceResponse = await _supabase
              .from('evidence_files')
              .select('*')
              .eq('complaint_id', complaint['id']);

          complaintData['evidence_files'] = evidenceResponse ?? [];
        } catch (e) {
          print('⚠️ Error getting evidence files for completed complaint ${complaint['id']}: $e');
          complaintData['evidence_files'] = [];
        }

        try {
          // Get case assignments separately (if they exist)
          final assignmentResponse = await _supabase
              .from('case_assignments')
              .select('''
                *,
                pnp_officer_profiles(
                  full_name,
                  badge_number,
                  rank
                )
              ''')
              .eq('complaint_id', complaint['id']);

          complaintData['case_assignments'] = assignmentResponse ?? [];
        } catch (e) {
          print('⚠️ Error getting case assignments for completed complaint ${complaint['id']}: $e');
          complaintData['case_assignments'] = [];
        }

        complaintsWithData.add(complaintData);
      }

      print('✅ Successfully processed ${complaintsWithData.length} completed complaints with related data');
      return complaintsWithData;
    } catch (e) {
      print('❌ Error getting completed complaints: $e');
      return [];
    }
  }

  // Get single complaint by ID
  Future<Map<String, dynamic>?> getComplaint(String complaintId) async {
    try {
      if (currentUserId == null) return null;

      final response = await _supabase
          .from('complaints')
          .select('''
            *,
            evidence_files(*),
            case_assignments(
              pnp_officer_profiles(
                full_name,
                badge_number,
                rank,
                phone_number,
                pnp_units(
                  unit_name,
                  unit_code,
                  category
                )
              )
            )
          ''')
          .eq('id', complaintId)
          .eq('user_id', currentUserId!)
          .single();

      return response;
    } catch (e) {
      print('Error getting complaint: $e');
      return null;
    }
  }

  // Get complaint status history
  Future<List<Map<String, dynamic>>> getComplaintStatusHistory(String complaintId) async {
    try {
      final response = await _supabase
          .from('complaint_status_history')
          .select('*')
          .eq('complaint_id', complaintId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting complaint status history: $e');
      return [];
    }
  }

  // Upload evidence files for a complaint
  Future<void> _uploadEvidenceFiles(String complaintId, List<EvidenceFile> files) async {
    try {
      for (final evidenceFile in files) {
        final file = File(evidenceFile.filePath);
        final bytes = await file.readAsBytes();
        
        // Create unique filename
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = '${complaintId}_${timestamp}_${evidenceFile.fileName}';
        final filePath = 'evidence/$complaintId/$fileName';

        // Upload to Supabase Storage using regular client with public bucket
        await _supabase.storage
            .from('evidence-files')
            .uploadBinary(filePath, Uint8List.fromList(bytes));

        // Get public URL
        final publicUrl = _supabase.storage
            .from('evidence-files')
            .getPublicUrl(filePath);

        // Save evidence file record
        await _supabase.from('evidence_files').insert({
          'complaint_id': complaintId,
          'file_name': evidenceFile.fileName,
          'file_type': evidenceFile.fileType,
          'file_size': evidenceFile.fileSize,
          'file_path': filePath,
          'download_url': publicUrl,
          'uploaded_by': currentUserId!,
          'created_at': PhilippineTime.toUtc(PhilippineTime.now()).toIso8601String(),
        });

        print('✅ Evidence file uploaded: ${evidenceFile.fileName}');
      }
    } catch (e) {
      print('❌ Error uploading evidence files: $e');
      throw 'Failed to upload evidence files: $e';
    }
  }

  // Add status update to complaint history
  Future<void> _addStatusUpdate(
    String complaintId,
    String status,
    String updatedBy,
    String? remarks,
  ) async {
    try {
      await _supabase.from('complaint_status_history').insert({
        'complaint_id': complaintId,
        'status': status,
        'updated_by': updatedBy,
        'remarks': remarks,
        'created_at': PhilippineTime.toUtc(PhilippineTime.now()).toIso8601String(),
      });
    } catch (e) {
      print('Error adding status update: $e');
    }
  }

  // Helper: Generate complaint title based on crime type and description
  String _generateComplaintTitle(CrimeType crimeType, String description) {
    final words = description.split(' ').take(8);
    final title = words.join(' ');
    return title.length > 100 ? '${title.substring(0, 97)}...' : title;
  }

  // Helper: Calculate priority based on crime type and financial loss
  String _calculatePriority(CrimeType crimeType, double? financialLoss) {
    // High priority crimes
    if ([
      CrimeType.cyberterrorism,
      CrimeType.governmentSystemHacking,
      CrimeType.criticalInfrastructureAttacks,
      CrimeType.childSexualAbuseMaterial,
      CrimeType.ransomware,
      CrimeType.onlinePredatoryBehavior,
    ].contains(crimeType)) {
      return 'high';
    }

    // High priority based on financial loss
    if (financialLoss != null && financialLoss >= 100000) {
      return 'high';
    }

    // Medium priority crimes
    if ([
      CrimeType.identityTheft,
      CrimeType.onlineBankingFraud,
      CrimeType.creditCardFraud,
      CrimeType.sextortion,
      CrimeType.dataBreach,
      CrimeType.denialOfServiceAttacks,
    ].contains(crimeType)) {
      return 'medium';
    }

    // Medium priority based on financial loss
    if (financialLoss != null && financialLoss >= 10000) {
      return 'medium';
    }

    return 'low';
  }


  // Helper: Calculate risk score based on various factors
  int _calculateRiskScore(CrimeType crimeType, double? financialLoss) {
    int baseScore = 30;

    // Crime type multiplier
    final highRiskCrimes = [
      CrimeType.cyberterrorism,
      CrimeType.governmentSystemHacking,
      CrimeType.criticalInfrastructureAttacks,
      CrimeType.childSexualAbuseMaterial,
      CrimeType.ransomware,
      CrimeType.onlinePredatoryBehavior,
    ];

    final mediumRiskCrimes = [
      CrimeType.identityTheft,
      CrimeType.onlineBankingFraud,
      CrimeType.creditCardFraud,
      CrimeType.sextortion,
      CrimeType.dataBreach,
      CrimeType.denialOfServiceAttacks,
    ];

    if (highRiskCrimes.contains(crimeType)) {
      baseScore += 40;
    } else if (mediumRiskCrimes.contains(crimeType)) {
      baseScore += 25;
    } else {
      baseScore += 10;
    }

    // Financial loss impact
    if (financialLoss != null) {
      if (financialLoss >= 1000000) {
        baseScore += 25;
      } else if (financialLoss >= 100000) {
        baseScore += 15;
      } else if (financialLoss >= 10000) {
        baseScore += 10;
      } else if (financialLoss >= 1000) {
        baseScore += 5;
      }
    }

    // Ensure score is between 0-100
    return baseScore.clamp(0, 100);
  }

  // Get user complaint statistics
  Future<Map<String, dynamic>> getUserComplaintStats() async {
    try {
      if (currentUserId == null) return {};

      final allComplaints = await _supabase
          .from('complaints')
          .select('status')
          .eq('user_id', currentUserId!);

      final stats = <String, int>{
        'total': allComplaints.length,
        'pending': 0,
        'under_investigation': 0,
        'requires_more_info': 0,
        'resolved': 0,
        'dismissed': 0,
      };

      for (final complaint in allComplaints) {
        final status = complaint['status'] as String;
        switch (status) {
          case 'Pending':
            stats['pending'] = (stats['pending'] ?? 0) + 1;
            break;
          case 'Under Investigation':
            stats['under_investigation'] = (stats['under_investigation'] ?? 0) + 1;
            break;
          case 'Requires More Information':
            stats['requires_more_info'] = (stats['requires_more_info'] ?? 0) + 1;
            break;
          case 'Resolved':
            stats['resolved'] = (stats['resolved'] ?? 0) + 1;
            break;
          case 'Dismissed':
            stats['dismissed'] = (stats['dismissed'] ?? 0) + 1;
            break;
        }
      }

      return stats;
    } catch (e) {
      print('Error getting complaint stats: $e');
      return {};
    }
  }

  // =============================================
  // AI ASSESSMENT METHODS
  // =============================================

  /// Submit complaint with AI assessment
  Future<String?> submitComplaintWithAI(Complaint complaint) async {
    try {
      if (currentUserId == null) {
        throw 'User not authenticated';
      }

      print('🤖 Starting complaint submission with AI assessment');

      // First, get AI assessment
      final suspectInfo = {
        'suspectName': complaint.suspectName ?? '',
        'suspectRelationship': complaint.suspectRelationship ?? '',
        'suspectContact': complaint.suspectContact ?? '',
        'suspectDetails': complaint.suspectDetails ?? '',
      };

      AIRiskAssessment? aiAssessment;
      try {
        aiAssessment = await AIRiskAssessmentService.assessComplaint(
          description: complaint.description,
          crimeType: complaint.crimeType,
          evidenceFiles: complaint.evidenceFiles,
          financialLoss: complaint.estimatedFinancialLoss,
          suspectInfo: suspectInfo,
          incidentDate: complaint.incidentDateTime,
          incidentLocation: complaint.incidentLocation,
        );
        print('✅ AI assessment completed: ${aiAssessment.aiPriority} priority, ${aiAssessment.aiRiskScore}% risk');
      } catch (e) {
        print('⚠️ AI assessment failed, proceeding with rule-based: $e');
      }

      // Generate complaint number
      final now = PhilippineTime.now();
      final year = now.year;
      
      final latestResponse = await _supabase
          .from('complaints')
          .select('complaint_number')
          .like('complaint_number', 'CYB-$year-%')
          .order('created_at', ascending: false)
          .limit(1);

      int sequenceNumber = 1;
      if (latestResponse.isNotEmpty) {
        final latestNumber = latestResponse.first['complaint_number'] as String;
        final parts = latestNumber.split('-');
        if (parts.length == 3) {
          sequenceNumber = (int.tryParse(parts[2]) ?? 0) + 1;
        }
      }

      final complaintNumber = 'CYB-$year-${sequenceNumber.toString().padLeft(3, '0')}';

      // Prepare complaint data with AI fields
      final complaintData = {
        'user_id': currentUserId!,
        'complaint_number': complaintNumber,
        'crime_type': complaint.crimeType.name,
        'title': _generateComplaintTitle(complaint.crimeType, complaint.description),
        'description': complaint.description,
        'full_name': complaint.fullName,
        'email': complaint.email,
        'phone_number': complaint.phoneNumber,
        'incident_date_time': complaint.incidentDateTime.toUtc().toIso8601String(),
        'incident_location': complaint.incidentLocation,
        'estimated_loss': complaint.estimatedFinancialLoss,
        'status': 'Pending',
        // Rule-based scores (fallback)
        'priority': _calculatePriority(complaint.crimeType, complaint.estimatedFinancialLoss),
        'risk_score': _calculateRiskScore(complaint.crimeType, complaint.estimatedFinancialLoss),
        // AI scores (if available)
        'ai_priority': aiAssessment?.aiPriority,
        'ai_risk_score': aiAssessment?.aiRiskScore,
        'ai_confidence_score': aiAssessment?.confidenceScore,
        'risk_factors': aiAssessment?.riskFactors ?? [],
        'urgency_indicators': aiAssessment?.urgencyIndicators ?? [],
        'last_ai_assessment': aiAssessment?.assessedAt.toIso8601String(),
        'ai_reasoning': aiAssessment?.reasoning,
        'assigned_unit': complaint.crimeType.assignedUnit,
        'created_at': PhilippineTime.toUtc(now).toIso8601String(),
        'updated_at': PhilippineTime.toUtc(now).toIso8601String(),
      };

      // Insert complaint
      final response = await _supabase
          .from('complaints')
          .insert(complaintData)
          .select('id')
          .single();

      final complaintId = response['id'] as String;

      // Store detailed AI assessment if available
      if (aiAssessment != null) {
        await _storeAIAssessment(complaintId, aiAssessment, {
          'description': complaint.description,
          'crimeType': complaint.crimeType.name,
          'financialLoss': complaint.estimatedFinancialLoss,
          'evidenceCount': complaint.evidenceFiles.length,
          'suspectInfo': suspectInfo,
        });
      }

      // Upload evidence files if any
      if (complaint.evidenceFiles.isNotEmpty) {
        await _uploadEvidenceFiles(complaintId, complaint.evidenceFiles);
      }

      // Add initial status history
      await _addStatusUpdate(
        complaintId,
        'Pending',
        'System',
        'Complaint submitted successfully with ${aiAssessment != null ? 'AI' : 'rule-based'} assessment',
      );

      print('✅ Complaint submitted successfully: $complaintNumber');
      return complaintId;

    } catch (e) {
      print('❌ Error submitting complaint with AI: $e');
      throw 'Failed to submit complaint: $e';
    }
  }

  /// Store detailed AI assessment in dedicated table
  Future<void> _storeAIAssessment(
    String complaintId, 
    AIRiskAssessment assessment,
    Map<String, dynamic> inputData,
  ) async {
    try {
      await _supabase.from('ai_risk_assessments').insert({
        'complaint_id': complaintId,
        'ai_risk_score': assessment.aiRiskScore,
        'ai_priority': assessment.aiPriority,
        'confidence_score': assessment.confidenceScore,
        'risk_factors': assessment.riskFactors,
        'urgency_indicators': assessment.urgencyIndicators,
        'reasoning': assessment.reasoning,
        'assessment_type': 'full',
        'model_version': 'gemini-2.0-flash',
        'input_data': inputData,
        'created_at': assessment.assessedAt.toIso8601String(),
      });
      
      print('✅ AI assessment stored successfully');
    } catch (e) {
      print('⚠️ Failed to store AI assessment: $e');
      // Don't throw - this is non-critical
    }
  }

  /// Update complaint with new AI assessment
  Future<void> updateComplaintAIAssessment(
    String complaintId,
    AIRiskAssessment assessment,
  ) async {
    try {
      // Get current complaint data for change tracking
      final currentData = await _supabase
          .from('complaints')
          .select('ai_priority, ai_risk_score, ai_confidence_score')
          .eq('id', complaintId)
          .single();

      // Update complaint with new AI data
      await _supabase.from('complaints').update({
        'ai_priority': assessment.aiPriority,
        'ai_risk_score': assessment.aiRiskScore,
        'ai_confidence_score': assessment.confidenceScore,
        'risk_factors': assessment.riskFactors,
        'urgency_indicators': assessment.urgencyIndicators,
        'last_ai_assessment': assessment.assessedAt.toIso8601String(),
        'ai_reasoning': assessment.reasoning,
        'updated_at': PhilippineTime.toUtc(PhilippineTime.now()).toIso8601String(),
      }).eq('id', complaintId);

      // Store detailed assessment
      await _storeAIAssessment(complaintId, assessment, {
        'assessmentType': 'update',
        'previousPriority': currentData['ai_priority'],
        'previousRiskScore': currentData['ai_risk_score'],
      });

      // Log the change
      await _logPriorityChange(
        complaintId: complaintId,
        changeType: 'ai_update',
        oldValue: {
          'ai_priority': currentData['ai_priority'],
          'ai_risk_score': currentData['ai_risk_score'],
        },
        newValue: {
          'ai_priority': assessment.aiPriority,
          'ai_risk_score': assessment.aiRiskScore,
        },
        reason: 'AI reassessment triggered',
        confidenceBefore: currentData['ai_confidence_score'],
        confidenceAfter: assessment.confidenceScore,
      );

      print('✅ Complaint AI assessment updated: $complaintId');
    } catch (e) {
      print('❌ Error updating AI assessment: $e');
      throw 'Failed to update AI assessment: $e';
    }
  }

  /// Get complaints with AI assessment data
  Future<List<Map<String, dynamic>>> getUserActiveComplaintsWithAI() async {
    try {
      if (currentUserId == null) {
        print('❌ No current user ID for getUserActiveComplaintsWithAI');
        return [];
      }

      print('🔍 Fetching active complaints with AI data for user: $currentUserId');

      final response = await _supabase
          .from('complaints')
          .select('''
            *,
            ai_risk_assessments (
              id,
              confidence_score,
              reasoning,
              assessment_type,
              created_at
            )
          ''')
          .eq('user_id', currentUserId!)
          .inFilter('status', ['Pending', 'Under Investigation', 'Requires More Information'])
          .order('created_at', ascending: false);

      print('✅ Fetched ${response.length} active complaints with AI data');
      return response;
    } catch (e) {
      print('❌ Error fetching complaints with AI data: $e');
      return [];
    }
  }

  /// Perform quick AI assessment for real-time form updates
  Future<AIRiskAssessment?> performQuickAssessment(
    String description,
    CrimeType crimeType,
    double? financialLoss,
  ) async {
    try {
      print('🚀 Performing quick AI assessment...');
      
      final assessment = await AIRiskAssessmentService.quickAssessment(
        description: description,
        crimeType: crimeType,
        financialLoss: financialLoss,
      );
      
      print('✅ Quick AI assessment completed: ${assessment.aiPriority} priority');
      return assessment;
    } catch (e) {
      print('⚠️ Quick AI assessment failed: $e');
      return null;
    }
  }

  /// Log priority/risk score changes for audit trail
  Future<void> _logPriorityChange({
    required String complaintId,
    required String changeType,
    required Map<String, dynamic> oldValue,
    required Map<String, dynamic> newValue,
    required String reason,
    int? confidenceBefore,
    int? confidenceAfter,
    String? sessionId,
  }) async {
    try {
      await _supabase.from('priority_change_log').insert({
        'complaint_id': complaintId,
        'change_type': changeType,
        'old_value': oldValue,
        'new_value': newValue,
        'changed_by_type': 'ai',
        'reason': reason,
        'confidence_before': confidenceBefore,
        'confidence_after': confidenceAfter,
        'session_id': sessionId,
        'created_at': PhilippineTime.toUtc(PhilippineTime.now()).toIso8601String(),
      });
    } catch (e) {
      print('⚠️ Failed to log priority change: $e');
      // Don't throw - this is non-critical
    }
  }

  /// Get AI assessment history for a complaint
  Future<List<Map<String, dynamic>>> getAIAssessmentHistory(String complaintId) async {
    try {
      final response = await _supabase
          .from('ai_risk_assessments')
          .select('*')
          .eq('complaint_id', complaintId)
          .order('created_at', ascending: false);

      return response;
    } catch (e) {
      print('❌ Error fetching AI assessment history: $e');
      return [];
    }
  }

  /// Get priority change log for analysis
  Future<List<Map<String, dynamic>>> getPriorityChangeLog(String complaintId) async {
    try {
      final response = await _supabase
          .from('priority_change_log')
          .select('*')
          .eq('complaint_id', complaintId)
          .order('created_at', ascending: false);

      return response;
    } catch (e) {
      print('❌ Error fetching priority change log: $e');
      return [];
    }
  }

  /// Check if complaint needs AI reassessment
  Future<bool> needsAIReassessment(String complaintId) async {
    try {
      final response = await _supabase
          .from('complaints')
          .select('last_ai_assessment')
          .eq('id', complaintId)
          .single();

      final lastAssessment = response['last_ai_assessment'];
      if (lastAssessment == null) return true;

      final lastAssessmentDate = DateTime.parse(lastAssessment);
      final daysSince = DateTime.now().difference(lastAssessmentDate).inDays;
      
      return daysSince > 7; // Reassess if older than 7 days
    } catch (e) {
      print('❌ Error checking AI reassessment need: $e');
      return true; // Default to needing reassessment
    }
  }

  /// Batch update multiple complaints with AI assessments
  Future<void> batchUpdateAIAssessments(List<Map<String, dynamic>> updates) async {
    try {
      print('🔄 Batch updating ${updates.length} AI assessments...');
      
      for (final update in updates) {
        final complaintId = update['complaintId'] as String;
        final assessment = update['assessment'] as AIRiskAssessment;
        
        await updateComplaintAIAssessment(complaintId, assessment);
      }
      
      print('✅ Batch AI assessment update completed');
    } catch (e) {
      print('❌ Error in batch AI assessment update: $e');
      throw 'Failed to batch update AI assessments: $e';
    }
  }
}
