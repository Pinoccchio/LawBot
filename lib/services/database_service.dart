import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'dart:typed_data';
import '../utils/philippine_time.dart';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  // Get current user ID from Firebase
  String? get currentUserId => _auth.currentUser?.uid;

  // Generate session ID for conversation grouping
  String generateSessionId() {
    return _uuid.v4();
  }

  // =============================================
  // USER PROFILE OPERATIONS (UPDATED)
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

  // Enhanced create user profile with automatic notification triggers
  Future<void> createUserProfile({
    required String firebaseUid,
    required String email,
    required String fullName,
    String userType = 'CLIENT',
    String preferredLanguage = 'en',
    Map<String, dynamic>? notificationPreferences,
  }) async {
    try {
      print('Creating user profile for: $firebaseUid');

      // Prepare notification preferences
      final defaultPreferences = {
        'email': true,
        'push': true,
        'legal_updates': true,
        'marketing': false,
        'security_alerts': true,
      };

      final finalPreferences = {...defaultPreferences, ...?notificationPreferences};

      // Insert user profile - this will automatically trigger admin notifications via database trigger
      await _supabase.from('user_profiles').insert({
        'firebase_uid': firebaseUid,
        'email': email,
        'full_name': fullName,
        'user_type': userType,
        'user_status': 'active',
        'preferred_language': preferredLanguage,
        'notification_preferences': finalPreferences,
        'last_active': DateTime.now().toUtc().toIso8601String(),
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      print('✅ User profile created successfully');

      // Send welcome notification to the new user using template
      try {
        await createNotificationFromTemplate(
          templateKey: 'welcome_user',
          recipientUid: firebaseUid,
          variables: {
            'user_name': fullName,
          },
          actionUrl: '/welcome',
        );
        print('✅ Welcome notification sent to user');
      } catch (welcomeError) {
        print('⚠️ Failed to send welcome notification: $welcomeError');
        // Don't fail the entire signup process if welcome notification fails
      }

      print('🎉 User signup process completed with notifications');
    } catch (e) {
      print('❌ Error creating user profile: $e');
      throw 'Failed to create user profile: $e';
    }
  }

  // =============================================
  // NOTIFICATION OPERATIONS (NEW)
  // =============================================

  // Get notifications for current user with enhanced filtering
  Future<List<Map<String, dynamic>>> getNotifications({
    bool unreadOnly = false,
    String? category,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      if (currentUserId == null) return [];

      final response = await _supabase.rpc('get_notifications', params: {
        'p_user_id': currentUserId!,
        'p_unread_only': unreadOnly,
        'p_category': category,
        'p_limit': limit,
        'p_offset': offset,
      });

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

      final response = await _supabase.rpc('get_notification_stats', params: {
        'p_user_id': currentUserId!,
      });

      if (response.isNotEmpty) {
        final stats = response.first;
        return {
          'total_notifications': stats['total_notifications'] ?? 0,
          'unread_notifications': stats['unread_notifications'] ?? 0,
          'urgent_notifications': stats['urgent_notifications'] ?? 0,
          'notifications_today': stats['notifications_today'] ?? 0,
        };
      }

      return {
        'total_notifications': 0,
        'unread_notifications': 0,
        'urgent_notifications': 0,
        'notifications_today': 0,
      };
    } catch (e) {
      print('Error getting notification stats: $e');
      return {};
    }
  }

  // Mark notification as read
  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      if (currentUserId == null) return false;

      final result = await _supabase.rpc('mark_notification_read', params: {
        'p_notification_id': notificationId,
        'p_user_id': currentUserId!,
      });

      return result == true;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  // Send admin notification (for admins only)
  Future<Map<String, dynamic>?> sendAdminNotification({
    required String title,
    required String message,
    String? recipientUserId, // null = all users
    String type = 'admin_message',
    String category = 'announcement',
    String priority = 'normal',
    String? actionUrl,
    DateTime? expiresAt,
  }) async {
    try {
      if (currentUserId == null) throw 'User not authenticated';

      // Verify current user is admin
      final userProfile = await getUserProfile();
      if (userProfile == null || userProfile['user_type'] != 'ADMIN') {
        throw 'Only admins can send notifications';
      }

      final response = await _supabase.rpc('send_admin_notification', params: {
        'p_sender_admin_uid': currentUserId!,
        'p_title': title,
        'p_message': message,
        'p_recipient_user_uid': recipientUserId,
        'p_type': type,
        'p_category': category,
        'p_priority': priority,
        'p_action_url': actionUrl,
        'p_expires_at': expiresAt?.toUtc().toIso8601String(),
      });

      if (response.isNotEmpty) {
        final result = response.first;
        return {
          'notification_id': result['notification_id'],
          'recipient_count': result['recipient_count'],
          'success': true,
        };
      }

      return {'success': false};
    } catch (e) {
      print('Error sending admin notification: $e');
      throw 'Failed to send notification: $e';
    }
  }

  // Create notification from template
  Future<String?> createNotificationFromTemplate({
    required String templateKey,
    required String recipientUid,
    String? senderUid,
    Map<String, dynamic>? variables,
    String? actionUrl,
  }) async {
    try {
      final variablesJson = variables ?? {};

      final response = await _supabase.rpc('create_notification_from_template', params: {
        'p_template_key': templateKey,
        'p_recipient_uid': recipientUid,
        'p_sender_uid': senderUid,
        'p_variables': variablesJson,
        'p_action_url': actionUrl,
      });

      return response?.toString();
    } catch (e) {
      print('Error creating notification from template: $e');
      return null;
    }
  }

  // Get unread notification count (for badges)
  Future<int> getUnreadNotificationCount() async {
    try {
      final stats = await getNotificationStats();
      return stats['unread_notifications'] ?? 0;
    } catch (e) {
      print('Error getting unread notification count: $e');
      return 0;
    }
  }

  // Get urgent notifications (for immediate display)
  Future<List<Map<String, dynamic>>> getUrgentNotifications() async {
    try {
      if (currentUserId == null) return [];

      final notifications = await getNotifications(
        unreadOnly: true,
        limit: 10,
      );

      return notifications
          .where((notification) => notification['priority'] == 'urgent')
          .toList();
    } catch (e) {
      print('Error getting urgent notifications: $e');
      return [];
    }
  }

  // Check for admin signup notifications (for admin users)
  Future<List<Map<String, dynamic>>> getAdminSignupNotifications() async {
    try {
      if (currentUserId == null) return [];

      // Verify current user is admin
      final userProfile = await getUserProfile();
      if (userProfile == null || userProfile['user_type'] != 'ADMIN') {
        return [];
      }

      return await getNotifications(
        unreadOnly: true,
        category: 'user_management',
        limit: 20,
      );
    } catch (e) {
      print('Error getting admin signup notifications: $e');
      return [];
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
        'read_at': DateTime.now().toUtc().toIso8601String(),
        'delivery_status': 'read',
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
      if (currentUserId == null) return false;

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

  // Get notification preferences for current user
  Future<List<Map<String, dynamic>>> getNotificationPreferences() async {
    try {
      if (currentUserId == null) return [];

      final response = await _supabase
          .from('notification_preferences')
          .select()
          .eq('user_id', currentUserId!)
          .order('notification_category');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting notification preferences: $e');
      return [];
    }
  }

  // Update notification preferences
  Future<bool> updateNotificationPreferences({
    required String category,
    bool? emailEnabled,
    bool? pushEnabled,
    bool? inAppEnabled,
    String? frequency,
    String? quietHoursStart,
    String? quietHoursEnd,
  }) async {
    try {
      if (currentUserId == null) return false;

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      if (emailEnabled != null) updateData['email_enabled'] = emailEnabled;
      if (pushEnabled != null) updateData['push_enabled'] = pushEnabled;
      if (inAppEnabled != null) updateData['in_app_enabled'] = inAppEnabled;
      if (frequency != null) updateData['frequency'] = frequency;
      if (quietHoursStart != null) updateData['quiet_hours_start'] = quietHoursStart;
      if (quietHoursEnd != null) updateData['quiet_hours_end'] = quietHoursEnd;

      await _supabase
          .from('notification_preferences')
          .upsert({
        'user_id': currentUserId!,
        'notification_category': category,
        ...updateData,
      });

      return true;
    } catch (e) {
      print('Error updating notification preferences: $e');
      return false;
    }
  }

  // Clean up expired notifications (admin function)
  Future<int> cleanupExpiredNotifications() async {
    try {
      final result = await _supabase.rpc('cleanup_expired_notifications');
      return result ?? 0;
    } catch (e) {
      print('Error cleaning up expired notifications: $e');
      return 0;
    }
  }

  // Save notification (generic method for system notifications)
  Future<bool> saveNotification({
    required String title,
    required String message,
    required String type, // 'info', 'warning', 'success', 'legal_update', 'system'
    String? actionUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (currentUserId == null) return false;

      await _supabase.from('notifications').insert({
        'user_id': currentUserId!,
        'title': title,
        'message': message,
        'type': type,
        'notification_category': 'system',
        'action_url': actionUrl,
        'metadata': metadata,
        'is_read': false,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Error saving notification: $e');
      return false;
    }
  }

  // =============================================
  // USER PROFILE OPERATIONS (CONTINUED)
  // =============================================

  // Update user profile with proper JSON encoding
  Future<void> updateUserProfile({
    String? fullName,
    String? phoneNumber,
    String? avatarUrl,
    String? preferredLanguage,
    Map<String, dynamic>? notificationPreferences,
    String? userStatus,
  }) async {
    try {
      if (currentUserId == null) throw 'User not authenticated';

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'last_active': DateTime.now().toUtc().toIso8601String(),
      };

      if (fullName != null) updateData['full_name'] = fullName;
      if (phoneNumber != null) updateData['phone_number'] = phoneNumber;
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;
      if (preferredLanguage != null) updateData['preferred_language'] = preferredLanguage;
      if (userStatus != null) updateData['user_status'] = userStatus;

      // Handle notification preferences as proper JSON
      if (notificationPreferences != null) {
        updateData['notification_preferences'] = notificationPreferences;
      }

      await _supabase
          .from('user_profiles')
          .update(updateData)
          .eq('firebase_uid', currentUserId!);
    } catch (e) {
      print('Error updating user profile: $e');
      throw 'Failed to update user profile';
    }
  }

  // Update user's last active timestamp
  Future<void> updateUserLastActive() async {
    try {
      if (currentUserId == null) return;

      // Try RPC function first
      try {
        await _supabase.rpc('update_user_last_active', params: {
          'p_firebase_uid': currentUserId!,
        });
      } catch (rpcError) {
        // Fallback: direct update
        await _supabase
            .from('user_profiles')
            .update({'last_active': DateTime.now().toUtc().toIso8601String()})
            .eq('firebase_uid', currentUserId!);
      }
    } catch (e) {
      print('Error updating last active: $e');
      // Don't throw error for this, as it's not critical
    }
  }

  // Get user status and type
  Future<Map<String, String>?> getUserStatusAndType() async {
    try {
      if (currentUserId == null) return null;

      final response = await _supabase
          .from('user_profiles')
          .select('user_type, user_status')
          .eq('firebase_uid', currentUserId!)
          .maybeSingle();

      if (response != null) {
        return {
          'user_type': response['user_type'] ?? 'CLIENT',
          'user_status': response['user_status'] ?? 'active',
        };
      }
      return null;
    } catch (e) {
      print('Error getting user status and type: $e');
      return null;
    }
  }

  // Check if user account is active
  Future<bool> isUserAccountActive() async {
    try {
      final statusInfo = await getUserStatusAndType();
      return statusInfo?['user_status'] == 'active';
    } catch (e) {
      print('Error checking user account status: $e');
      return true; // Default to active if error
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

      // Delete user's chat sessions
      await _supabase
          .from('chat_sessions')
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

      // Delete user's notification preferences
      await _supabase
          .from('notification_preferences')
          .delete()
          .eq('user_id', currentUserId!);

      // Delete user's analytics
      await _supabase
          .from('user_analytics')
          .delete()
          .eq('user_id', currentUserId!);

      // Delete user's sessions
      await _supabase
          .from('user_sessions')
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

  // =============================================
  // ENHANCED SESSION MANAGEMENT WITH DASHBOARD FILTERING
  // =============================================

  /// Start a new conversation and complete previous active sessions
  Future<String> startNewConversation() async {
    try {
      if (currentUserId == null) throw 'User not authenticated';

      print('🚀 Starting new conversation for user: $currentUserId');

      // Step 1: Complete all active sessions for this user
      try {
        final response = await _supabase.rpc('complete_user_active_sessions', params: {
          'p_user_id': currentUserId!,
        });
        print('✅ Completed ${response ?? 0} active sessions');
      } catch (e) {
        print('⚠️ Could not complete active sessions via RPC: $e');
        // Fallback: direct update
        try {
          await _supabase
              .from('chat_sessions')
              .update({
            'status': 'completed',
            'completed_at': DateTime.now().toUtc().toIso8601String(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
              .eq('user_id', currentUserId!)
              .eq('status', 'active');
          print('✅ Completed active sessions via direct update');
        } catch (directError) {
          print('⚠️ Direct update also failed: $directError');
        }
      }

      // Step 2: Generate new session ID
      final newSessionId = generateSessionId();

      // Step 3: Create new active session record
      try {
        await _supabase.rpc('upsert_chat_session', params: {
          'p_session_id': newSessionId,
          'p_user_id': currentUserId!,
          'p_title': 'New Conversation',
          'p_status': 'active',
        });
        print('✅ Created new active session: $newSessionId');
      } catch (e) {
        print('⚠️ Could not create session via RPC: $e');
        // Fallback: direct insert
        try {
          await _supabase.from('chat_sessions').insert({
            'session_id': newSessionId,
            'user_id': currentUserId!,
            'title': 'New Conversation',
            'status': 'active',
            'total_messages': 0,
            'first_message_at': DateTime.now().toUtc().toIso8601String(),
            'last_message_at': DateTime.now().toUtc().toIso8601String(),
            'created_at': DateTime.now().toUtc().toIso8601String(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          });
          print('✅ Created new session via direct insert: $newSessionId');
        } catch (directError) {
          print('⚠️ Direct session creation also failed: $directError');
        }
      }

      print('🎉 New conversation started successfully: $newSessionId');
      return newSessionId;
    } catch (e) {
      print('❌ Error starting new conversation: $e');
      // Return a fallback session ID
      final fallbackSessionId = generateSessionId();
      return fallbackSessionId;
    }
  }

  /// Get current active session for the user
  Future<Map<String, dynamic>?> getCurrentActiveSession() async {
    try {
      if (currentUserId == null) return null;

      try {
        // Try RPC function first
        final response = await _supabase.rpc('get_user_active_session', params: {
          'p_user_id': currentUserId!,
        });

        if (response != null && response.isNotEmpty) {
          final sessionData = response.first;
          return {
            'session_id': sessionData['session_id'],
            'title': sessionData['title'],
            'total_messages': sessionData['total_messages'],
            'last_message_at': sessionData['last_message_at'],
            'status': sessionData['status'],
          };
        }
      } catch (e) {
        print('⚠️ RPC get_user_active_session failed: $e');

        // Fallback: direct query
        final response = await _supabase
            .from('chat_sessions')
            .select()
            .eq('user_id', currentUserId!)
            .eq('status', 'active')
            .order('last_message_at', ascending: false)
            .limit(1);

        if (response.isNotEmpty) {
          return response.first;
        }
      }

      return null;
    } catch (e) {
      print('Error getting active session: $e');
      return null;
    }
  }

  /// Complete a specific session
  Future<bool> completeSession(String sessionId) async {
    try {
      if (currentUserId == null) return false;

      try {
        // Try RPC function first
        final result = await _supabase.rpc('complete_chat_session', params: {
          'p_session_id': sessionId,
        });
        return result == true;
      } catch (e) {
        print('⚠️ RPC complete_chat_session failed: $e');

        // Fallback: direct update
        await _supabase
            .from('chat_sessions')
            .update({
          'status': 'completed',
          'completed_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
            .eq('session_id', sessionId)
            .eq('user_id', currentUserId!)
            .eq('status', 'active');

        return true;
      }
    } catch (e) {
      print('Error completing session: $e');
      return false;
    }
  }

  /// FIXED: Enhanced getChatSessions with Dashboard Filtering Patterns
  Future<List<Map<String, dynamic>>> getChatSessions({
    int limit = 50,
    String? category,
    DateTime? fromDate,
    DateTime? toDate,
    String? status, // New: filter by status
  }) async {
    try {
      if (currentUserId == null) return [];

      // Update last active when accessing chat data
      updateUserLastActive();

      List<Map<String, dynamic>> sessions = [];

      try {
        // Try using the enhanced database function first
        final response = await _supabase.rpc('get_chat_sessions_with_status', params: {
          'p_user_id': currentUserId!,
          'p_limit': limit * 2, // Get more to account for filtering
        });

        sessions = List<Map<String, dynamic>>.from(response);

        // CRITICAL: Filter out placeholder sessions like the dashboard does
        sessions = sessions.where((session) {
          final title = session['title']?.toString() ?? '';
          final messageCount = session['message_count'] as int? ?? 0;
          final sessionStatus = session['status']?.toString() ?? '';

          // Filter out placeholder sessions - exact dashboard pattern
          bool isValidSession = title != 'New Conversation' &&
              title.trim().isNotEmpty &&
              messageCount > 0;

          // Additional check: if it's an active session with no real content, filter it out
          if (sessionStatus == 'active' && messageCount <= 1 && title == 'New Conversation') {
            return false;
          }

          return isValidSession;
        }).toList();

        // Limit after filtering
        if (sessions.length > limit) {
          sessions = sessions.take(limit).toList();
        }

        // Add enhanced session information
        for (var session in sessions) {
          await _enhanceSessionData(session);
        }

      } catch (rpcError) {
        print('❌ RPC function failed: $rpcError');

        // Fallback: Use dashboard pattern - get sessions but exclude placeholders
        try {
          var query = _supabase
              .from('chat_sessions')
              .select()
              .eq('user_id', currentUserId!)
              .neq('title', 'New Conversation')  // ← EXCLUDE placeholder sessions
              .gt('total_messages', 0);          // ← EXCLUDE empty sessions

          // Apply status filter if provided
          if (status != null) {
            query = query.eq('status', status);
          }

          final sessionResponse = await query
              .order('last_message_at', ascending: false)
              .limit(limit);

          sessions = [];
          for (var sessionRecord in sessionResponse) {
            // FIXED: Get actual Q&A pairs count like dashboard does
            final actualMessages = await _supabase
                .from('chat_history')
                .select('session_id')
                .eq('user_id', currentUserId!)
                .eq('session_id', sessionRecord['session_id'])
                .not('question', 'is', null)      // ← Dashboard filtering pattern
                .not('answer', 'is', null);       // ← Dashboard filtering pattern

            final actualMessageCount = actualMessages.length;

            // Only include sessions that have actual Q&A pairs
            if (actualMessageCount > 0) {
              // Get session metadata with Q&A filtering
              final messagesResponse = await _supabase
                  .from('chat_history')
                  .select('question, answer, created_at, category, confidence_score')
                  .eq('user_id', currentUserId!)
                  .eq('session_id', sessionRecord['session_id'])
                  .not('question', 'is', null)    // ← Only complete Q&A pairs
                  .not('answer', 'is', null)      // ← Only complete Q&A pairs
                  .order('created_at', ascending: true);

              if (messagesResponse.isNotEmpty) {
                final messages = messagesResponse;
                final firstMessage = messages.first;
                final lastMessage = messages.last;

                // Calculate average confidence from actual messages
                double totalConfidence = 0;
                int confidenceCount = 0;
                Set<String> categories = {};

                for (var msg in messages) {
                  if (msg['confidence_score'] != null) {
                    totalConfidence += (msg['confidence_score'] as num).toDouble();
                    confidenceCount++;
                  }
                  if (msg['category'] != null) {
                    categories.add(msg['category'].toString());
                  }
                }

                final avgConfidence = confidenceCount > 0 ? totalConfidence / confidenceCount : null;

                sessions.add({
                  'session_id': sessionRecord['session_id'],
                  'title': sessionRecord['title'],
                  'first_question': firstMessage['question'] ?? 'No question',
                  'last_question': lastMessage['question'] ?? firstMessage['question'] ?? 'No question',
                  'message_count': actualMessageCount, // ← Use actual Q&A pair count (dashboard pattern)
                  'status': sessionRecord['status'],
                  'categories': categories.toList(),
                  'first_created_at': sessionRecord['first_message_at'],
                  'last_created_at': sessionRecord['last_message_at'],
                  'completed_at': sessionRecord['completed_at'],
                  'avg_confidence': avgConfidence,
                  'has_recommendations': false, // Will be set by _enhanceSessionData
                });
              }
            }
          }
        } catch (directError) {
          print('❌ Direct query also failed: $directError');

          // Final fallback: Use chat_history directly with dashboard filtering
          final historyResponse = await _supabase
              .from('chat_history')
              .select()
              .eq('user_id', currentUserId!)
              .not('question', 'is', null)      // ← Dashboard filtering
              .not('answer', 'is', null)        // ← Dashboard filtering
              .not('session_id', 'is', null)
              .order('created_at', ascending: false)
              .limit(limit * 5);

          sessions = _convertMessagesToSessions(historyResponse);
        }
      }

      // Apply additional filters
      if (status != null) {
        sessions = sessions.where((session) => session['status'] == status).toList();
      }

      if (category != null && category != 'All') {
        sessions = sessions.where((session) {
          final categories = session['categories'] as List?;
          return categories?.contains(category) ?? false;
        }).toList();
      }

      if (fromDate != null || toDate != null) {
        sessions = sessions.where((session) {
          try {
            final sessionDate = DateTime.parse(session['last_created_at']);
            bool passesFromDate = fromDate == null || sessionDate.isAfter(PhilippineTime.toUtc(fromDate));
            bool passesToDate = toDate == null || sessionDate.isBefore(PhilippineTime.toUtc(toDate));
            return passesFromDate && passesToDate;
          } catch (e) {
            return true;
          }
        }).toList();
      }

      return sessions;
    } catch (e) {
      print('❌ Overall error getting chat sessions: $e');
      return [];
    }
  }

  /// FIXED: Convert messages to sessions with Dashboard filtering patterns
  List<Map<String, dynamic>> _convertMessagesToSessions(List<Map<String, dynamic>> messages) {
    if (messages.isEmpty) return [];

    // Group messages by session_id (only include complete Q&A pairs - dashboard pattern)
    Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var message in messages) {
      // CRITICAL: Skip incomplete Q&A pairs (dashboard pattern)
      if (message['question'] == null ||
          message['answer'] == null ||
          message['question'].toString().trim().isEmpty ||
          message['answer'].toString().trim().isEmpty) {
        continue;
      }

      String sessionKey = message['session_id']?.toString() ?? 'single_${message['id'] ?? DateTime.now().millisecondsSinceEpoch}';

      if (!grouped.containsKey(sessionKey)) {
        grouped[sessionKey] = [];
      }
      grouped[sessionKey]!.add(message);
    }

    // Convert to session format
    List<Map<String, dynamic>> sessions = [];

    grouped.forEach((sessionId, sessionMessages) {
      try {
        // Sort messages by creation time
        sessionMessages.sort((a, b) {
          final aTime = a['created_at']?.toString();
          final bTime = b['created_at']?.toString();

          if (aTime == null || bTime == null) return 0;

          try {
            return DateTime.parse(aTime).compareTo(DateTime.parse(bTime));
          } catch (e) {
            return 0;
          }
        });

        final firstMessage = sessionMessages.first;
        final lastMessage = sessionMessages.last;

        // Generate title from first question (dashboard pattern)
        final firstQuestion = firstMessage['question']?.toString() ?? 'No question';
        String sessionTitle = firstQuestion;

        // Create meaningful title
        if (firstQuestion.length > 50) {
          sessionTitle = '${firstQuestion.substring(0, 47)}...';
        }

        // CRITICAL: Skip if this looks like a placeholder session (dashboard pattern)
        if (sessionTitle == 'New Conversation' ||
            sessionTitle.trim().isEmpty ||
            firstQuestion == 'New Conversation') {
          return; // Skip this session
        }

        // Calculate average confidence
        double totalConfidence = 0;
        int confidenceCount = 0;

        for (var msg in sessionMessages) {
          if (msg['confidence_score'] != null) {
            try {
              totalConfidence += (msg['confidence_score'] as num).toDouble();
              confidenceCount++;
            } catch (e) {
              // Silent error handling
            }
          }
        }

        final avgConfidence = confidenceCount > 0 ? totalConfidence / confidenceCount : null;

        // Get unique categories
        Set<String> categories = {};
        for (var msg in sessionMessages) {
          if (msg['category'] != null && msg['category'].toString().isNotEmpty) {
            categories.add(msg['category'].toString());
          }
        }

        if (categories.isEmpty) {
          categories.add('General');
        }

        // Check if any message has recommendations
        bool hasRecommendations = false;
        for (var msg in sessionMessages) {
          try {
            final metadata = msg['metadata'] as Map<String, dynamic>?;
            if (metadata != null && metadata['recommendations'] is List) {
              final recommendations = metadata['recommendations'] as List;
              if (recommendations.isNotEmpty) {
                hasRecommendations = true;
                break;
              }
            }
          } catch (e) {
            // Silent error handling
          }
        }

        final lastQuestion = lastMessage['question']?.toString() ?? firstQuestion;
        final firstCreatedAt = firstMessage['created_at']?.toString() ?? DateTime.now().toUtc().toIso8601String();
        final lastCreatedAt = lastMessage['created_at']?.toString() ?? firstCreatedAt;

        sessions.add({
          'session_id': sessionId.startsWith('single_') ? null : sessionId,
          'title': sessionTitle,
          'first_question': firstQuestion,
          'last_question': lastQuestion,
          'message_count': sessionMessages.length, // ← Accurate Q&A pair count
          'status': 'completed', // Assume old sessions are completed
          'categories': categories.toList(),
          'first_created_at': firstCreatedAt,
          'last_created_at': lastCreatedAt,
          'avg_confidence': avgConfidence,
          'has_recommendations': hasRecommendations,
        });
      } catch (e) {
        print('Error processing session $sessionId: $e');
        // Skip this session if there's an error but continue with others
      }
    });

    // Sort by last created date (newest first)
    sessions.sort((a, b) {
      try {
        final aTime = a['last_created_at']?.toString();
        final bTime = b['last_created_at']?.toString();

        if (aTime == null || bTime == null) return 0;

        return DateTime.parse(bTime).compareTo(DateTime.parse(aTime));
      } catch (e) {
        return 0;
      }
    });

    return sessions;
  }

  /// Helper method to enhance session data with additional information
  Future<void> _enhanceSessionData(Map<String, dynamic> session) async {
    try {
      // Check for recommendations and other metadata
      final sessionId = session['session_id']?.toString();
      if (sessionId == null) {
        session['has_recommendations'] = false;
        return;
      }

      // Check if any message in this session has recommendations (with Q&A filtering)
      final messages = await _supabase
          .from('chat_history')
          .select('metadata')
          .eq('user_id', currentUserId!)
          .eq('session_id', sessionId)
          .not('question', 'is', null)    // ← Dashboard filtering
          .not('answer', 'is', null)      // ← Dashboard filtering
          .not('metadata', 'is', null);

      bool hasRecommendations = false;
      for (var message in messages) {
        if (_messageHasRecommendations(message)) {
          hasRecommendations = true;
          break;
        }
      }

      session['has_recommendations'] = hasRecommendations;

      // Add status display formatting
      session['status_display'] = _formatStatusForDisplay(session['status'] ?? 'unknown');

      // Add time ago formatting
      if (session['last_created_at'] != null) {
        final lastTime = DateTime.parse(session['last_created_at']);
        session['time_ago'] = _formatTimeAgo(lastTime);
      }

    } catch (e) {
      session['has_recommendations'] = false;
      session['status_display'] = 'Unknown';
    }
  }

  /// Format status for display in UI
  String _formatStatusForDisplay(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'completed':
        return 'Completed';
      case 'inactive':
        return 'Inactive';
      default:
        return 'Unknown';
    }
  }

  /// Format time ago for display
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  /// FIXED: Get session messages with Dashboard Q&A filtering
  Future<List<Map<String, dynamic>>> getSessionMessages(String sessionId) async {
    try {
      if (currentUserId == null) return [];

      try {
        // Try RPC function first
        final response = await _supabase.rpc('get_session_messages', params: {
          'p_user_id': currentUserId!,
          'p_session_id': sessionId,
        });

        return List<Map<String, dynamic>>.from(response);
      } catch (rpcError) {
        print('❌ RPC get_session_messages failed: $rpcError');

        // Fallback: direct query with Dashboard Q&A filtering
        final response = await _supabase
            .from('chat_history')
            .select()
            .eq('user_id', currentUserId!)
            .eq('session_id', sessionId)
            .not('question', 'is', null)    // ← Dashboard filtering pattern
            .not('answer', 'is', null)      // ← Dashboard filtering pattern
            .order('created_at', ascending: true);

        return List<Map<String, dynamic>>.from(response);
      }
    } catch (e) {
      print('Error getting session messages: $e');
      return [];
    }
  }

  // Helper method to check if a message has recommendations
  bool _messageHasRecommendations(Map<String, dynamic> message) {
    try {
      final metadata = message['metadata'] as Map<String, dynamic>?;
      if (metadata != null && metadata['recommendations'] is List) {
        final recommendations = metadata['recommendations'] as List;
        return recommendations.isNotEmpty;
      }
    } catch (e) {
      // Silent fail
    }
    return false;
  }

  /// FIXED: Search chat sessions with Dashboard filtering patterns
  Future<List<Map<String, dynamic>>> searchChatSessions({
    required String searchQuery,
    String? category,
    int limit = 20,
  }) async {
    try {
      if (currentUserId == null) return [];

      try {
        // Try RPC function first
        final response = await _supabase.rpc('search_chat_sessions', params: {
          'p_user_id': currentUserId!,
          'p_search_query': searchQuery,
          'p_category': category == 'All' ? null : category,
          'p_limit': limit,
        });

        final sessions = List<Map<String, dynamic>>.from(response);

        // CRITICAL: Filter out placeholder sessions from search results (dashboard pattern)
        return sessions.where((session) {
          final title = session['first_question']?.toString() ?? '';
          final messageCount = session['message_count'] as int? ?? 0;

          return title != 'New Conversation' &&
              title.trim().isNotEmpty &&
              messageCount > 0;
        }).toList();

      } catch (rpcError) {
        print('❌ RPC search_chat_sessions failed: $rpcError');

        // Fallback: direct search with Dashboard Q&A filtering
        var query = _supabase
            .from('chat_history')
            .select()
            .eq('user_id', currentUserId!)
            .not('session_id', 'is', null)
            .not('question', 'is', null)    // ← Dashboard filtering pattern
            .not('answer', 'is', null)      // ← Dashboard filtering pattern
            .or('question.ilike.%$searchQuery%,answer.ilike.%$searchQuery%');

        if (category != null && category != 'All') {
          query = query.eq('category', category);
        }

        final response = await query
            .order('created_at', ascending: false)
            .limit(limit * 2); // Get more for grouping

        // Convert individual messages to session format with filtering
        return _convertMessagesToSessions(response);
      }
    } catch (e) {
      print('Error searching chat sessions: $e');
      return [];
    }
  }

  /// FIXED: Get chat history with Dashboard Q&A filtering
  Future<List<Map<String, dynamic>>> getChatHistory({
    int limit = 50,
    String? category,
    String? sessionId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      if (currentUserId == null) return [];

      // If sessionId is provided, get messages for that session
      if (sessionId != null) {
        return await getSessionMessages(sessionId);
      }

      // Otherwise, get sessions (grouped conversations)
      return await getChatSessions(
        limit: limit,
        category: category,
        fromDate: fromDate,
        toDate: toDate,
      );
    } catch (e) {
      print('❌ Error in getChatHistory: $e');

      // Final fallback: get all messages with Dashboard Q&A filtering
      try {
        final response = await _supabase
            .from('chat_history')
            .select()
            .eq('user_id', currentUserId!)
            .not('question', 'is', null)    // ← Dashboard filtering
            .not('answer', 'is', null)      // ← Dashboard filtering
            .order('created_at', ascending: false)
            .limit(limit);

        return List<Map<String, dynamic>>.from(response);
      } catch (finalError) {
        print('❌ Final fallback failed: $finalError');
        return [];
      }
    }
  }

  // Get recent chat history for profile (last 5 conversations)
  Future<List<Map<String, dynamic>>> getRecentChatHistory() async {
    try {
      if (currentUserId == null) return [];

      return await getChatSessions(limit: 5);
    } catch (e) {
      print('Error getting recent chat history: $e');
      return [];
    }
  }

  /// FIXED: Get chat history for AI conversation context with Q&A filtering
  Future<List<Map<String, String>>> getChatHistoryForContext({
    String? sessionId,
    int limit = 10,
  }) async {
    try {
      if (currentUserId == null) return [];

      var queryBuilder = _supabase
          .from('chat_history')
          .select('question, answer, created_at, category')
          .eq('user_id', currentUserId!)
          .not('question', 'is', null)    // ← Dashboard filtering
          .not('answer', 'is', null);     // ← Dashboard filtering

      if (sessionId != null) {
        queryBuilder = queryBuilder.eq('session_id', sessionId);
      }

      final response = await queryBuilder
          .order('created_at', ascending: true)
          .limit(limit);

      List<Map<String, String>> context = [];
      for (var chat in response) {
        // Convert UTC timestamp to Philippine time for context
        final philippineTime = PhilippineTime.parseDatabaseTime(chat['created_at']);
        final timeString = philippineTime != null
            ? PhilippineTime.formatDateTime(philippineTime)
            : 'Unknown time';

        // Add user message
        context.add({
          'text': chat['question'] ?? '',
          'isBot': 'false',
          'timestamp': timeString,
          'category': chat['category'] ?? 'General',
        });
        // Add bot response
        context.add({
          'text': chat['answer'] ?? '',
          'isBot': 'true',
          'timestamp': timeString,
          'category': chat['category'] ?? 'General',
        });
      }

      return context;
    } catch (e) {
      print('Error fetching chat context: $e');
      return [];
    }
  }

  // Enhanced save chat message with proper timezone handling and session management
  Future<String?> saveChatMessage({
    required String question,
    required String answer,
    required String category,
    double? confidenceScore,
    String? sessionId,
    List<String>? keywords,
    List<String>? recommendations,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (currentUserId == null) throw 'User not authenticated';

      // Update last active when user chats
      updateUserLastActive();

      // Get current Philippine time for metadata
      final philippineNow = PhilippineTime.now();
      final utcNow = DateTime.now().toUtc();

      // Prepare enhanced metadata with timezone info
      Map<String, dynamic> enhancedMetadata = {
        'keywords': keywords ?? [],
        'recommendations': recommendations ?? [],
        'response_time': utcNow.millisecondsSinceEpoch,
        'ai_model': 'gemini-2.0-flash',
        'philippine_time': PhilippineTime.toPhilippineIsoString(philippineNow),
        'timezone': 'Asia/Manila',
        'user_local_time': PhilippineTime.formatDateTime(philippineNow),
        ...?metadata,
      };

      // Save the chat message (this will automatically trigger session update via database trigger)
      final response = await _supabase.from('chat_history').insert({
        'user_id': currentUserId!,
        'question': question,
        'answer': answer,
        'category': category,
        'confidence_score': confidenceScore,
        'session_id': sessionId,
        'metadata': enhancedMetadata,
        'created_at': utcNow.toIso8601String(),
      }).select('id').single();

      final chatId = response['id'] as String?;

      print('✅ Chat message saved: $chatId for session: $sessionId');

      return chatId;
    } catch (e) {
      print('❌ Error saving chat message: $e');
      return null;
    }
  }

  /// FIXED: Search method with Dashboard filtering patterns
  Future<List<Map<String, dynamic>>> searchChatHistory({
    required String searchQuery,
    String? category,
    int limit = 20,
  }) async {
    try {
      if (currentUserId == null) return [];

      // First try to search sessions
      final sessionResults = await searchChatSessions(
        searchQuery: searchQuery,
        category: category,
        limit: limit,
      );

      // If session results found, return them
      if (sessionResults.isNotEmpty) {
        return sessionResults;
      }

      // Fallback to old individual message search with Q&A filtering
      var query = _supabase
          .from('chat_history')
          .select()
          .eq('user_id', currentUserId!)
          .not('question', 'is', null)    // ← Dashboard filtering
          .not('answer', 'is', null)      // ← Dashboard filtering
          .or('question.ilike.%$searchQuery%,answer.ilike.%$searchQuery%');

      if (category != null && category != 'All') {
        query = query.eq('category', category);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error searching chat history: $e');
      return [];
    }
  }

  /// Get session statistics for analytics
  Future<Map<String, dynamic>> getSessionStatistics() async {
    try {
      if (currentUserId == null) return {};

      final sessions = await getChatSessions(limit: 1000);

      final totalSessions = sessions.length;
      final activeSessions = sessions.where((s) => s['status'] == 'active').length;
      final completedSessions = sessions.where((s) => s['status'] == 'completed').length;
      final totalMessages = sessions.fold<int>(0, (sum, session) => sum + (session['message_count'] as int? ?? 0));

      final avgMessagesPerSession = totalSessions > 0 ? totalMessages / totalSessions : 0.0;

      // Get recent activity (last 7 days)
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final recentSessions = sessions.where((session) {
        try {
          final sessionDate = DateTime.parse(session['last_created_at']);
          return sessionDate.isAfter(sevenDaysAgo);
        } catch (e) {
          return false;
        }
      }).length;

      return {
        'total_sessions': totalSessions,
        'active_sessions': activeSessions,
        'completed_sessions': completedSessions,
        'total_messages': totalMessages,
        'avg_messages_per_session': avgMessagesPerSession,
        'recent_sessions_7d': recentSessions,
        'completion_rate': totalSessions > 0 ? (completedSessions / totalSessions * 100).round() : 0,
      };
    } catch (e) {
      print('Error getting session statistics: $e');
      return {};
    }
  }

  /// Get active sessions count (for admin dashboard) with Q&A filtering
  Future<int> getActiveSessionsCount() async {
    try {
      // Get active sessions that have actual Q&A pairs (dashboard pattern)
      final activeSessions = await _supabase
          .from('chat_sessions')
          .select('session_id')
          .eq('status', 'active')
          .neq('title', 'New Conversation');

      int count = 0;
      for (var session in activeSessions) {
        final messages = await _supabase
            .from('chat_history')
            .select('id')
            .eq('session_id', session['session_id'])
            .not('question', 'is', null)
            .not('answer', 'is', null)
            .limit(1);

        if (messages.isNotEmpty) {
          count++;
        }
      }

      return count;
    } catch (e) {
      print('Error getting active sessions count: $e');
      return 0;
    }
  }

  /// Get completed sessions count (for admin dashboard) with Q&A filtering
  Future<int> getCompletedSessionsCount() async {
    try {
      // Get completed sessions that have actual Q&A pairs (dashboard pattern)
      final completedSessions = await _supabase
          .from('chat_sessions')
          .select('session_id')
          .eq('status', 'completed')
          .neq('title', 'New Conversation');

      int count = 0;
      for (var session in completedSessions) {
        final messages = await _supabase
            .from('chat_history')
            .select('id')
            .eq('session_id', session['session_id'])
            .not('question', 'is', null)
            .not('answer', 'is', null)
            .limit(1);

        if (messages.isNotEmpty) {
          count++;
        }
      }

      return count;
    } catch (e) {
      print('Error getting completed sessions count: $e');
      return 0;
    }
  }

  // =============================================
  // LEGAL RESOURCES OPERATIONS
  // =============================================

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

  // =============================================
  // ANALYTICS OPERATIONS
  // =============================================

  // Enhanced Analytics Operations with timezone handling
  Future<Map<String, dynamic>> getUserAnalytics() async {
    try {
      if (currentUserId == null) return {};

      // Get session-based analytics instead of individual message analytics
      final sessionsResponse = await getChatSessions(limit: 1000);

      if (sessionsResponse.isEmpty) {
        return {
          'total_conversations': 0,
          'total_messages': 0,
          'avg_messages_per_conversation': 0.0,
          'top_categories': <Map<String, dynamic>>[],
          'recent_activity_count': 0,
          'accuracy_rate': 0,
          'avg_confidence': 0.0,
          'top_keywords': <String>[],
          'last_activity': null,
        };
      }

      final totalConversations = sessionsResponse.length;
      final totalMessages = sessionsResponse.fold<int>(0, (sum, session) => sum + (session['message_count'] as int));
      final avgMessagesPerConversation = totalMessages / totalConversations;

      // Get category breakdown from sessions
      Map<String, int> categoryCount = {};
      double totalConfidence = 0.0;
      int confidenceCount = 0;

      for (var session in sessionsResponse) {
        final categories = session['categories'] as List?;
        if (categories != null) {
          for (var category in categories) {
            categoryCount[category.toString()] = (categoryCount[category.toString()] ?? 0) + 1;
          }
        }

        final confidence = session['avg_confidence'];
        if (confidence != null) {
          totalConfidence += (confidence as num).toDouble();
          confidenceCount++;
        }
      }

      // Sort categories by count
      var sortedCategories = categoryCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final avgConfidence = confidenceCount > 0 ? totalConfidence / confidenceCount : 0.0;

      // Get recent activity (last 7 days)
      final sevenDaysAgo = PhilippineTime.now().subtract(const Duration(days: 7));
      final recentSessions = sessionsResponse.where((session) {
        final sessionDate = DateTime.parse(session['last_created_at']);
        return sessionDate.isAfter(PhilippineTime.toUtc(sevenDaysAgo));
      }).length;

      // Get keywords from the most recent sessions with Q&A filtering
      final recentSessionIds = sessionsResponse.take(10).map((s) => s['session_id'].toString()).toList();

      final allKeywords = <String>[];
      if (recentSessionIds.isNotEmpty) {
        try {
          final keywordsResponse = await _supabase
              .from('chat_history')
              .select('metadata')
              .eq('user_id', currentUserId!)
              .contains('session_id', recentSessionIds)
              .not('question', 'is', null)    // ← Dashboard filtering
              .not('answer', 'is', null)      // ← Dashboard filtering
              .not('metadata', 'is', null);

          for (var item in keywordsResponse) {
            final metadata = item['metadata'] as Map<String, dynamic>?;
            if (metadata != null && metadata['keywords'] is List) {
              allKeywords.addAll((metadata['keywords'] as List).cast<String>());
            }
          }
        } catch (e) {
          print('Error fetching keywords: $e');
        }
      }

      final keywordFrequency = <String, int>{};
      for (var keyword in allKeywords) {
        keywordFrequency[keyword] = (keywordFrequency[keyword] ?? 0) + 1;
      }

      final topKeywords = keywordFrequency.entries
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return {
        'total_conversations': totalConversations,
        'total_messages': totalMessages,
        'avg_messages_per_conversation': avgMessagesPerConversation,
        'top_categories': sortedCategories.take(5).map((e) => {
          'category': e.key,
          'count': e.value,
          'percentage': totalConversations > 0 ? ((e.value / totalConversations) * 100).round() : 0,
        }).toList(),
        'recent_activity_count': recentSessions,
        'accuracy_rate': (avgConfidence * 100).round(),
        'avg_confidence': avgConfidence,
        'top_keywords': topKeywords.take(10).map((e) => e.key).toList(),
        'category_distribution': categoryCount,
        'last_activity': totalConversations > 0
            ? PhilippineTime.getCurrentDateTimeString()
            : null,
      };
    } catch (e) {
      print('Error getting user analytics: $e');
      return {};
    }
  }

  // Save user analytics event with proper timezone
  Future<bool> saveUserAnalytics({
    required String metricName,
    required Map<String, dynamic> metricValue,
  }) async {
    try {
      if (currentUserId == null) return false;

      final utcNow = DateTime.now().toUtc();
      final philippineNow = PhilippineTime.now();

      await _supabase.from('user_analytics').insert({
        'user_id': currentUserId!,
        'metric_name': metricName,
        'metric_value': {
          ...metricValue,
          'philippine_time': PhilippineTime.toPhilippineIsoString(philippineNow),
          'timezone': 'Asia/Manila',
        },
        'date_recorded': PhilippineTime.formatDate(philippineNow).split(',')[0], // Just the date part
        'created_at': utcNow.toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Error saving analytics: $e');
      return false;
    }
  }

  // =============================================
  // SAVED LEGAL ADVICE OPERATIONS
  // =============================================

  Future<void> saveLegalAdvice({
    required String question,
    required String answer,
    required String category,
    List<String>? tags,
    String? notes,
  }) async {
    try {
      if (currentUserId == null) throw 'User not authenticated';

      final utcNow = DateTime.now().toUtc();

      await _supabase.from('saved_advice').insert({
        'user_id': currentUserId!,
        'question': question,
        'answer': answer,
        'category': category,
        'tags': tags,
        'notes': notes,
        'created_at': utcNow.toIso8601String(),
        'updated_at': utcNow.toIso8601String(),
      });
    } catch (e) {
      print('Error saving legal advice: $e');
      throw 'Failed to save legal advice';
    }
  }

  // Save advice to bookmarks (alternative method name for consistency with chat_tab.dart)
  Future<String> saveAdvice({
    required String question,
    required String answer,
    required String category,
    List<String>? tags,
    String? notes,
  }) async {
    try {
      if (currentUserId == null) throw 'User not authenticated';

      final utcNow = DateTime.now().toUtc();

      final response = await _supabase
          .from('saved_advice')
          .insert({
        'user_id': currentUserId!,
        'question': question,
        'answer': answer,
        'category': category,
        'tags': tags ?? [],
        'notes': notes,
        'is_favorite': false,
        'created_at': utcNow.toIso8601String(),
        'updated_at': utcNow.toIso8601String(),
      })
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      print('Error saving advice: $e');
      throw 'Failed to save advice';
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

  // Remove saved advice (alternative method name for consistency)
  Future<void> removeSavedAdvice(String adviceId) async {
    try {
      if (currentUserId == null) throw 'User not authenticated';

      await _supabase
          .from('saved_advice')
          .delete()
          .eq('id', adviceId)
          .eq('user_id', currentUserId!);
    } catch (e) {
      print('Error removing saved advice: $e');
      throw 'Failed to remove saved advice';
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

  // Check if advice is already saved
  Future<bool> isAdviceSaved(String question, String answer) async {
    try {
      if (currentUserId == null) return false;

      final response = await _supabase
          .from('saved_advice')
          .select('id')
          .eq('user_id', currentUserId!)
          .eq('question', question)
          .eq('answer', answer)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      print('Error checking if advice is saved: $e');
      return false;
    }
  }

  // Toggle favorite status (alternative method name for consistency)
  Future<void> toggleFavorite(String adviceId, bool isFavorite) async {
    try {
      if (currentUserId == null) throw 'User not authenticated';

      await _supabase
          .from('saved_advice')
          .update({
        'is_favorite': isFavorite,
        'updated_at': DateTime.now().toUtc().toIso8601String()
      })
          .eq('id', adviceId)
          .eq('user_id', currentUserId!);
    } catch (e) {
      print('Error toggling favorite: $e');
      throw 'Failed to toggle favorite';
    }
  }

  Future<void> toggleAdviceFavorite(String adviceId, bool isFavorite) async {
    try {
      if (currentUserId == null) throw 'User not authenticated';

      await _supabase
          .from('saved_advice')
          .update({
        'is_favorite': isFavorite,
        'updated_at': DateTime.now().toUtc().toIso8601String()
      })
          .eq('id', adviceId)
          .eq('user_id', currentUserId!);
    } catch (e) {
      print('Error toggling favorite: $e');
      throw 'Failed to update favorite status';
    }
  }

  // =============================================
  // LEGAL CATEGORIES OPERATIONS
  // =============================================

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

  // =============================================
  // FEEDBACK OPERATIONS
  // =============================================

  Future<bool> submitFeedback({
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
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Error submitting feedback: $e');
      return false;
    }
  }

  // Get feedback for a specific chat message
  Future<Map<String, dynamic>?> getFeedbackForChat(String chatHistoryId) async {
    try {
      if (currentUserId == null) return null;

      final response = await _supabase
          .from('feedback')
          .select()
          .eq('user_id', currentUserId!)
          .eq('chat_history_id', chatHistoryId)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error getting feedback: $e');
      return null;
    }
  }

  // =============================================
  // SEARCH OPERATIONS
  // =============================================

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

  // Get popular legal topics (for recommendations)
  Future<List<Map<String, dynamic>>> getPopularLegalTopics({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('popular_legal_topics')
          .select()
          .order('question_count', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching popular topics: $e');
      return [];
    }
  }

  // =============================================
  // FILE UPLOAD OPERATIONS
  // =============================================

  // Upload profile picture to Supabase storage
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

  // Delete profile picture from Supabase storage
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