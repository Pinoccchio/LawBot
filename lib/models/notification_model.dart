import '../utils/philippine_time.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final bool isImportant;
  final String createdAt;
  final String? readAt;
  final Map<String, dynamic>? metadata;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    this.isImportant = false,
    required this.createdAt,
    this.readAt,
    this.metadata,
  });

  /// Create a NotificationModel from JSON data
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String,
      isRead: json['is_read'] as bool? ?? false,
      isImportant: json['is_important'] as bool? ?? false,
      createdAt: json['created_at'] as String,
      readAt: json['read_at'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert NotificationModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'is_read': isRead,
      'is_important': isImportant,
      'created_at': createdAt,
      'read_at': readAt,
      'metadata': metadata,
    };
  }

  /// Create a copy of the notification with updated fields
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    bool? isImportant,
    String? createdAt,
    String? readAt,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      isImportant: isImportant ?? this.isImportant,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Mark notification as read with Philippines time
  NotificationModel markAsRead() {
    return copyWith(
      isRead: true,
      readAt: PhilippineTime.toUtc(PhilippineTime.now()).toIso8601String(),
    );
  }

  /// Get formatted creation time in Philippines timezone
  String get formattedCreatedAt {
    return PhilippineTime.formatSpecificTime(createdAt);
  }

  /// Get formatted read time in Philippines timezone
  String? get formattedReadAt {
    if (readAt == null) return null;
    return PhilippineTime.formatSpecificTime(readAt);
  }

  /// Check if notification was created today in Philippines time
  bool get isToday {
    try {
      final createdAtPhilippines = PhilippineTime.parseDatabaseTime(createdAt);
      return createdAtPhilippines != null && PhilippineTime.isToday(createdAtPhilippines);
    } catch (e) {
      return false;
    }
  }

  /// Get relative age of notification (e.g., "2 hours ago")
  String get timeAgo {
    try {
      final createdAtPhilippines = PhilippineTime.parseDatabaseTime(createdAt);
      if (createdAtPhilippines == null) return 'Unknown time';

      final now = PhilippineTime.now();
      final difference = now.difference(createdAtPhilippines);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 30) {
        return '${difference.inDays}d ago';
      } else {
        return formattedCreatedAt;
      }
    } catch (e) {
      return 'Unknown time';
    }
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, type: $type, isRead: $isRead, isImportant: $isImportant)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Notification types enum for type safety
class NotificationTypes {
  static const String caseUpdate = 'case_update';
  static const String success = 'success';
  static const String warning = 'warning';
  static const String error = 'error';
  static const String info = 'info';
  static const String securityAlert = 'security_alert';
  static const String announcement = 'announcement';
  static const String legalUpdate = 'legal_update';
  static const String general = 'general';
}

/// Notification priorities for importance levels
class NotificationPriorities {
  static const String low = 'low';
  static const String normal = 'normal';
  static const String high = 'high';
  static const String urgent = 'urgent';
}

/// Notification categories for organization
class NotificationCategories {
  static const String caseUpdate = 'case_update';
  static const String system = 'system';
  static const String security = 'security';
  static const String legalUpdate = 'legal_update';
  static const String general = 'general';
}