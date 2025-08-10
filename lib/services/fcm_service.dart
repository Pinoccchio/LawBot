import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../utils/philippine_time.dart';
import '../services/database_service.dart';
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';

class FCMService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  static NotificationProvider? _notificationProvider;
  static String? _currentUserId;
  
  // Initialize FCM service
  static Future<void> initialize({
    required NotificationProvider notificationProvider,
    required String? userId,
  }) async {
    _notificationProvider = notificationProvider;
    _currentUserId = userId;
    
    if (_currentUserId == null) {
      print('⚠️ FCM Service: Cannot initialize without user ID');
      return;
    }
    
    try {
      // Request notification permissions
      await _requestPermissions();
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Get and store FCM token
      await _handleTokenRefresh();
      
      // Set up message handlers
      _setupMessageHandlers();
      
      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);
      
      print('✅ FCM Service initialized successfully for user: $_currentUserId');
      
    } catch (e) {
      print('❌ Error initializing FCM Service: $e');
    }
  }
  
  // Request notification permissions
  static Future<void> _requestPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ FCM: User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('✅ FCM: User granted provisional permission');
    } else {
      print('⚠️ FCM: User declined or has not accepted permission');
    }
  }
  
  // Initialize local notifications plugin
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    
    final DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) async {
        // Handle iOS local notification tap
        _handleNotificationTap(payload);
      },
    );
    
    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap
        _handleNotificationTap(response.payload);
      },
    );
  }
  
  // Get and store FCM token
  static Future<String?> _handleTokenRefresh() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null && _currentUserId != null) {
        print('🔑 FCM Token: ${token.substring(0, 20)}...');
        
        // Store token in database
        await _storeTokenInDatabase(token);
        return token;
      }
      return null;
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      return null;
    }
  }
  
  // Store FCM token in Supabase database
  static Future<void> _storeTokenInDatabase(String token) async {
    if (_currentUserId == null) return;
    
    try {
      await DatabaseService.updateUserFCMToken(_currentUserId!, token);
      print('✅ FCM token stored in database for user: $_currentUserId');
    } catch (e) {
      print('❌ Error storing FCM token: $e');
    }
  }
  
  // Handle token refresh
  static Future<void> _onTokenRefresh(String token) async {
    print('🔄 FCM Token refreshed: ${token.substring(0, 20)}...');
    await _storeTokenInDatabase(token);
  }
  
  // Setup message handlers for all app states
  static void _setupMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle messages when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    
    // Handle messages when app is opened from terminated state
    _handleTerminatedMessage();
  }
  
  // Handle foreground messages (app is open and active)
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📱 Foreground message received: ${message.notification?.title}');
    
    // Show local notification when app is in foreground
    await _showLocalNotification(message);
    
    // Add to notification provider for in-app display
    await _addToInAppNotifications(message);
  }
  
  // Handle background messages (app opened from background)
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('🔄 Background message opened app: ${message.notification?.title}');
    
    // Add to notification provider for in-app display
    await _addToInAppNotifications(message);
    
    // Navigate to relevant screen if needed
    _navigateToRelevantScreen(message);
  }
  
  // Handle terminated messages (app opened from terminated state)
  static Future<void> _handleTerminatedMessage() async {
    final RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    
    if (initialMessage != null) {
      print('🚀 App launched from terminated state by notification: ${initialMessage.notification?.title}');
      
      // Add to notification provider for in-app display
      await _addToInAppNotifications(initialMessage);
      
      // Navigate to relevant screen
      _navigateToRelevantScreen(initialMessage);
    }
  }
  
  // Show local notification for foreground messages
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'lawbot_notifications',
      'LawBot Case Updates',
      channelDescription: 'Notifications for case status updates and important information',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      message.notification?.title ?? 'LawBot Notification',
      message.notification?.body ?? 'You have a new update',
      platformDetails,
      payload: message.data['type'] ?? 'general',
    );
  }
  
  // Add FCM message to in-app notification system
  static Future<void> _addToInAppNotifications(RemoteMessage message) async {
    if (_notificationProvider == null || _currentUserId == null) return;
    
    try {
      // Create notification model from FCM message
      final notification = NotificationModel(
        id: 'fcm_${DateTime.now().millisecondsSinceEpoch}',
        userId: _currentUserId!,
        title: message.notification?.title ?? 'New Update',
        message: message.notification?.body ?? 'You have a new notification',
        type: message.data['notification_type'] ?? 'general',
        isRead: false,
        isImportant: message.data['is_important'] == 'true',
        createdAt: PhilippineTime.now().toIso8601String(),
        metadata: {
          'source': 'push_notification',
          'fcm_message_id': message.messageId,
          'case_id': message.data['case_id'],
          'complaint_number': message.data['complaint_number'],
        },
      );
      
      // Add to notification provider
      await _notificationProvider!.addNotification(notification);
      
      print('✅ FCM message added to in-app notifications');
      
    } catch (e) {
      print('❌ Error adding FCM message to notifications: $e');
    }
  }
  
  // Handle notification tap
  static void _handleNotificationTap(String? payload) {
    if (payload == null) return;
    
    print('👆 Notification tapped with payload: $payload');
    
    // Navigate based on payload type
    switch (payload) {
      case 'case_update':
        // Navigate to notifications tab or specific case
        break;
      case 'new_message':
        // Navigate to messages
        break;
      case 'general':
      default:
        // Navigate to notifications tab
        break;
    }
  }
  
  // Navigate to relevant screen based on message data
  static void _navigateToRelevantScreen(RemoteMessage message) {
    final String? type = message.data['type'];
    final String? caseId = message.data['case_id'];
    
    print('🧭 Navigating for notification type: $type, case: $caseId');
    
    // Implementation depends on your navigation structure
    // You might want to use Navigator or your routing system here
  }
  
  // Clear FCM token when user logs out
  static Future<void> clearToken() async {
    try {
      if (_currentUserId != null) {
        await DatabaseService.clearUserFCMToken(_currentUserId!);
        print('✅ FCM token cleared for user: $_currentUserId');
      }
      
      _currentUserId = null;
      _notificationProvider = null;
      
    } catch (e) {
      print('❌ Error clearing FCM token: $e');
    }
  }
  
  // Get current FCM token
  static Future<String?> getCurrentToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('❌ Error getting current FCM token: $e');
      return null;
    }
  }
  
  // Subscribe to topic (for broadcast notifications)
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('✅ Subscribed to topic: $topic');
    } catch (e) {
      print('❌ Error subscribing to topic $topic: $e');
    }
  }
  
  // Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ Error unsubscribing from topic $topic: $e');
    }
  }
}

// Top-level function for handling background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already initialized
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  print('📩 Background message received: ${message.notification?.title}');
  
  // Handle background message processing
  // Note: You have limited processing time (30 seconds) in background
  // Don't perform heavy operations here
  
  // You can store the notification for later processing when app opens
  // or update local storage/database if needed
}