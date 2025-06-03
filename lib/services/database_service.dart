import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'dart:typed_data';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID from Firebase
  String? get currentUserId => _auth.currentUser?.uid;

  // User Profile Operations
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

  Future<void> createUserProfile({
    required String firebaseUid,
    required String email,
    required String fullName,
  }) async {
    try {
      await _supabase.from('user_profiles').insert({
        'firebase_uid': firebaseUid,
        'email': email,
        'full_name': fullName,
      });
    } catch (e) {
      print('Error creating user profile: $e');
      throw 'Failed to create user profile: $e';
    }
  }

  Future<void> updateUserProfile({
    String? fullName,
    String? phoneNumber,
    String? avatarUrl,
    String? preferredLanguage,
  }) async {
    try {
      if (currentUserId == null) throw 'User not authenticated';

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updateData['full_name'] = fullName;
      if (phoneNumber != null) updateData['phone_number'] = phoneNumber;
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;
      if (preferredLanguage != null) updateData['preferred_language'] = preferredLanguage;

      await _supabase.from('user_profiles').update(updateData).eq('firebase_uid', currentUserId!);
    } catch (e) {
      print('Error updating user profile: $e');
      throw 'Failed to update user profile';
    }
  }

  // Delete user account and all associated data
  Future<void> deleteUserAccount() async {
    try {
      if (currentUserId == null) throw 'User not authenticated';

      // Delete user's saved advice
      await _supabase
          .from('saved_advice')
          .delete()
          .eq('user_id', currentUserId!);

      // Delete user's chat history
      await _supabase
          .from('chat_history')
          .delete()
          .eq('user_id', currentUserId!);

      // Delete user's feedback
      await _supabase
          .from('feedback')
          .delete()
          .eq('user_id', currentUserId!);

      // Delete user's notifications
      await _supabase
          .from('notifications')
          .delete()
          .eq('user_id', currentUserId!);

      // Delete profile picture if exists
      final userProfile = await getUserProfile();
      if (userProfile != null && userProfile['avatar_url'] != null) {
        try {
          await deleteProfilePicture(userProfile['avatar_url']);
        } catch (e) {
          print('Error deleting profile picture during account deletion: $e');
          // Continue with deletion even if profile picture deletion fails
        }
      }

      // Finally delete the user profile
      await _supabase
          .from('user_profiles')
          .delete()
          .eq('firebase_uid', currentUserId!);

      print('User account and all associated data deleted successfully');
    } catch (e) {
      print('Error deleting user account: $e');
      throw 'Failed to delete user account: $e';
    }
  }

  // Chat History Operations
  Future<List<Map<String, dynamic>>> getChatHistory({int limit = 50}) async {
    try {
      if (currentUserId == null) return [];

      final response = await _supabase
          .from('chat_history')
          .select()
          .eq('user_id', currentUserId!)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting chat history: $e');
      return [];
    }
  }

  Future<void> saveChatMessage({
    required String question,
    required String answer,
    required String category,
    double? confidenceScore,
    String? sessionId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (currentUserId == null) throw 'User not authenticated';

      await _supabase.from('chat_history').insert({
        'user_id': currentUserId!,
        'question': question,
        'answer': answer,
        'category': category,
        'confidence_score': confidenceScore,
        'session_id': sessionId,
        'metadata': metadata,
      });
    } catch (e) {
      print('Error saving chat message: $e');
      throw 'Failed to save chat message';
    }
  }

  // Legal Resources Operations
  Future<List<Map<String, dynamic>>> getLegalResources({
    String? category,
    String? searchQuery,
    int limit = 20,
  }) async {
    try {
      var query = _supabase.from('legal_resources').select();

      if (category != null && category != 'All') {
        query = query.eq('category', category);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('title.ilike.%$searchQuery%,content.ilike.%$searchQuery%,tags.cs.{$searchQuery}');
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting legal resources: $e');
      return [];
    }
  }

  Future<void> incrementResourceViewCount(String resourceId) async {
    try {
      await _supabase.rpc('increment_resource_view_count', params: {
        'resource_id': resourceId,
      });
    } catch (e) {
      print('Error incrementing view count: $e');
    }
  }

  // Analytics Operations
  Future<Map<String, dynamic>> getUserAnalytics() async {
    try {
      if (currentUserId == null) return {};

      // Get total questions count
      final questionsResponse = await _supabase
          .from('chat_history')
          .select()
          .eq('user_id', currentUserId!);

      final totalQuestions = questionsResponse.length;

      // Get category breakdown
      final categoriesResponse = await _supabase
          .from('chat_history')
          .select('category')
          .eq('user_id', currentUserId!);

      // Process categories
      Map<String, int> categoryCount = {};
      for (var item in categoriesResponse) {
        String category = item['category'] ?? 'Other';
        categoryCount[category] = (categoryCount[category] ?? 0) + 1;
      }

      // Sort categories by count
      var sortedCategories = categoryCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Get recent activity (last 7 days)
      final recentActivity = await _supabase
          .from('chat_history')
          .select('created_at')
          .eq('user_id', currentUserId!)
          .gte('created_at', DateTime.now().subtract(const Duration(days: 7)).toIso8601String());

      return {
        'total_questions': totalQuestions,
        'top_categories': sortedCategories.take(5).map((e) => {
          'category': e.key,
          'count': e.value,
          'percentage': totalQuestions > 0 ? ((e.value / totalQuestions) * 100).round() : 0,
        }).toList(),
        'recent_activity_count': recentActivity.length,
        'accuracy_rate': 89, // This would come from feedback analysis
      };
    } catch (e) {
      print('Error getting user analytics: $e');
      return {};
    }
  }

  // Saved Legal Advice Operations
  Future<void> saveLegalAdvice({
    required String question,
    required String answer,
    required String category,
    List<String>? tags,
    String? notes,
  }) async {
    try {
      if (currentUserId == null) throw 'User not authenticated';

      await _supabase.from('saved_advice').insert({
        'user_id': currentUserId!,
        'question': question,
        'answer': answer,
        'category': category,
        'tags': tags,
        'notes': notes,
      });
    } catch (e) {
      print('Error saving legal advice: $e');
      throw 'Failed to save legal advice';
    }
  }

  Future<List<Map<String, dynamic>>> getSavedAdvice() async {
    try {
      if (currentUserId == null) return [];

      final response = await _supabase
          .from('saved_advice')
          .select()
          .eq('user_id', currentUserId!)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting saved advice: $e');
      return [];
    }
  }

  Future<void> deleteSavedAdvice(String adviceId) async {
    try {
      if (currentUserId == null) throw 'User not authenticated';

      await _supabase
          .from('saved_advice')
          .delete()
          .eq('id', adviceId)
          .eq('user_id', currentUserId!);
    } catch (e) {
      print('Error deleting saved advice: $e');
      throw 'Failed to delete saved advice';
    }
  }

  Future<void> toggleAdviceFavorite(String adviceId, bool isFavorite) async {
    try {
      if (currentUserId == null) throw 'User not authenticated';

      await _supabase
          .from('saved_advice')
          .update({'is_favorite': isFavorite, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', adviceId)
          .eq('user_id', currentUserId!);
    } catch (e) {
      print('Error toggling favorite: $e');
      throw 'Failed to update favorite status';
    }
  }

  // Legal Categories Operations
  Future<List<Map<String, dynamic>>> getLegalCategories() async {
    try {
      final response = await _supabase
          .from('legal_categories')
          .select()
          .eq('is_active', true)
          .order('sort_order');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting legal categories: $e');
      return [];
    }
  }

  // Feedback Operations
  Future<void> submitFeedback({
    required String chatHistoryId,
    required int rating,
    String? feedbackText,
    required String feedbackType,
  }) async {
    try {
      await _supabase.from('feedback').insert({
        'user_id': currentUserId,
        'chat_history_id': chatHistoryId,
        'rating': rating,
        'feedback_text': feedbackText,
        'feedback_type': feedbackType,
      });
    } catch (e) {
      print('Error submitting feedback: $e');
      throw 'Failed to submit feedback';
    }
  }

  // Notifications Operations
  Future<List<Map<String, dynamic>>> getNotifications({bool unreadOnly = false}) async {
    try {
      if (currentUserId == null) return [];

      var query = _supabase
          .from('notifications')
          .select()
          .eq('user_id', currentUserId!);

      if (unreadOnly) {
        query = query.eq('is_read', false);
      }

      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({
        'is_read': true,
        'read_at': DateTime.now().toIso8601String(),
      })
          .eq('id', notificationId)
          .eq('user_id', currentUserId!);
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<int> getUnreadNotificationCount() async {
    try {
      if (currentUserId == null) return 0;

      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', currentUserId!)
          .eq('is_read', false);

      return response.length;
    } catch (e) {
      print('Error getting unread notification count: $e');
      return 0;
    }
  }

  // Search Operations
  Future<List<Map<String, dynamic>>> searchLegalResources(String query) async {
    try {
      final response = await _supabase
          .from('legal_resources')
          .select()
          .or('title.ilike.%$query%,content.ilike.%$query%')
          .limit(20);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error searching legal resources: $e');
      return [];
    }
  }

  // Get popular resources
  Future<List<Map<String, dynamic>>> getPopularResources({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('legal_resources')
          .select()
          .order('view_count', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting popular resources: $e');
      return [];
    }
  }

  // Get featured resources
  Future<List<Map<String, dynamic>>> getFeaturedResources() async {
    try {
      final response = await _supabase
          .from('legal_resources')
          .select()
          .eq('is_featured', true)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting featured resources: $e');
      return [];
    }
  }

  // FIXED: Upload profile picture to Supabase storage
  Future<String> uploadProfilePicture(String filePath) async {
    try {
      if (currentUserId == null) throw 'User not authenticated';

      print('Starting profile picture upload for user: $currentUserId');

      // Read file as bytes
      final file = File(filePath);
      final Uint8List fileBytes = await file.readAsBytes();

      // Create unique filename with timestamp
      final fileExtension = filePath.split('.').last.toLowerCase();
      final fileName = 'profile_${currentUserId}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      print('Uploading file: $fileName');
      print('File size: ${fileBytes.length} bytes');

      // Upload to Supabase storage using uploadBinary
      final String fullPath = await _supabase.storage
          .from('profile-pictures')
          .uploadBinary(
        fileName,
        fileBytes,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: true, // Allow overwriting existing files
        ),
      );

      print('Upload successful. Full path: $fullPath');

      // Get the public URL
      final String publicUrl = _supabase.storage
          .from('profile-pictures')
          .getPublicUrl(fileName);

      print('Public URL: $publicUrl');

      // Update user profile with new avatar URL
      await updateUserProfile(avatarUrl: publicUrl);

      return publicUrl;
    } catch (e) {
      print('Error uploading profile picture: $e');

      // Provide more specific error messages
      if (e.toString().contains('row-level security')) {
        throw 'Permission denied. Please check storage permissions.';
      } else if (e.toString().contains('Unauthorized')) {
        throw 'Authentication failed. Please sign in again.';
      } else if (e.toString().contains('not found')) {
        throw 'Storage bucket not found. Please contact support.';
      } else {
        throw 'Failed to upload profile picture: ${e.toString()}';
      }
    }
  }

  // FIXED: Delete profile picture from Supabase storage
  Future<void> deleteProfilePicture(String imageUrl) async {
    try {
      if (currentUserId == null) throw 'User not authenticated';

      print('Deleting profile picture: $imageUrl');

      // Extract filename from URL
      final uri = Uri.parse(imageUrl);
      final fileName = uri.pathSegments.last;

      print('Extracted filename: $fileName');

      // Delete from storage
      final List<FileObject> result = await _supabase.storage
          .from('profile-pictures')
          .remove([fileName]);

      print('Delete result: ${result.length} files deleted');

      // Update user profile to remove avatar URL
      await updateUserProfile(avatarUrl: null);

      print('Profile updated successfully');
    } catch (e) {
      print('Error deleting profile picture: $e');

      // Even if deletion fails, try to remove from profile
      try {
        await updateUserProfile(avatarUrl: null);
      } catch (profileError) {
        print('Failed to update profile after delete error: $profileError');
      }

      throw 'Failed to delete profile picture: ${e.toString()}';
    }
  }
}
