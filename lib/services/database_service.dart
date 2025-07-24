import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'dart:typed_data';
import '../utils/philippine_time.dart';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Service role client for storage operations (bypasses RLS)
  late final SupabaseClient _serviceRoleClient;

  DatabaseService() {
    _serviceRoleClient = SupabaseClient(
      'https://knoahdsfthalbdqockmw.supabase.co',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtub2FoZHNmdGhhbGJkcW9ja213Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0ODg2MTMzNCwiZXhwIjoyMDY0NDM3MzM0fQ.RIJDn6ZiyZYv-M9MtKyV9zo4AwZaGdxDGDWc8yK2s9Y',
    );
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
        final existingFiles = await _serviceRoleClient.storage
            .from('profile-pictures')
            .list(path: currentUserId!);

        for (final existingFile in existingFiles) {
          await _serviceRoleClient.storage
              .from('profile-pictures')
              .remove(['$currentUserId/${existingFile.name}']);
          print('🗑️ Deleted old profile picture: ${existingFile.name}');
        }
      } catch (e) {
        print('⚠️ No existing profile picture to delete or error deleting: $e');
      }

      // Upload new profile picture
      await _serviceRoleClient.storage
          .from('profile-pictures')
          .uploadBinary(fileName, Uint8List.fromList(bytes));

      // Get public URL
      final publicUrl = _serviceRoleClient.storage
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

      // Use service role client to bypass RLS for storage operations
      await _serviceRoleClient.storage
          .from('profile-pictures')
          .remove([fileName]);
      print('✅ Profile picture deleted');
    } catch (e) {
      print('Error deleting profile picture: $e');
    }
  }
}
