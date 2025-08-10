import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/philippine_time.dart';

class NotificationsTab extends StatefulWidget {
  const NotificationsTab({super.key});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'Recent'; // Default to Recent for better UX
  bool _showUnreadOnly = false;
  bool _isLoading = false;
  String _searchQuery = '';
  String _sortOrder = 'newest';
  final TextEditingController _searchController = TextEditingController();

  // Smart filtering categories for better UX
  final List<String> _categories = [
    'Recent',  // Default: shows unread + notifications from last 7 days
    'Unread',  // Only unread notifications
    'All',     // Complete notification history
    'Important' // High/urgent priority notifications regardless of read status
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final notificationProvider = context.read<NotificationProvider>();
      
      // Use the enhanced force immediate refresh for user-triggered refreshes
      await notificationProvider.forceImmediateRefresh();
      
      print('🔄 Manual refresh completed - notifications and badge count updated');
    } catch (e) {
      print('❌ Error loading notifications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    if (!mounted) return;

    try {
      final notificationProvider = context.read<NotificationProvider>();
      final success = await notificationProvider.markNotificationAsRead(notificationId);
      
      if (success && mounted) {
        // If user is viewing "Unread" filter and this was the last unread,
        // provide helpful feedback about where to find the notification
        if (_selectedCategory == 'Unread') {
          final unreadCount = notificationProvider.unreadNotificationCount;
          if (unreadCount == 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'All caught up! Switch to "Recent" to see read notifications.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.blue[600],
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'Recent',
                  textColor: Colors.white,
                  onPressed: () {
                    setState(() {
                      _selectedCategory = 'Recent';
                    });
                  },
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error marking notification as read: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Error updating notification: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    if (!mounted) return;

    try {
      final notificationProvider = context.read<NotificationProvider>();
      await notificationProvider.markAllNotificationsAsRead();

      if (mounted) {
        // Auto-switch to "Recent" filter to show newly-read notifications
        setState(() {
          _selectedCategory = 'Recent';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'All notifications marked as read. Switched to Recent view.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[600],
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Error updating notifications: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    if (!mounted) return;

    try {
      final notificationProvider = context.read<NotificationProvider>();
      final success = await notificationProvider.deleteNotification(notificationId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Notification deleted' : 'Failed to delete notification'),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error deleting notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting notification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  Widget _buildNotificationIcon(String type, String priority) {
    IconData iconData;
    Color iconColor;

    switch (type.toLowerCase()) {
      case 'info':
        iconData = Icons.info_outline;
        iconColor = const Color(0xFF2563EB);
        break;
      case 'success':
        iconData = Icons.check_circle_outline;
        iconColor = const Color(0xFF10B981);
        break;
      case 'warning':
        iconData = Icons.warning_amber_outlined;
        iconColor = const Color(0xFFF59E0B);
        break;
      case 'error':
        iconData = Icons.error_outline;
        iconColor = const Color(0xFFEF4444);
        break;
      case 'case_assignment':
        iconData = Icons.assignment_ind_outlined;
        iconColor = const Color(0xFF2563EB);
        break;
      case 'case_update':
        iconData = Icons.update;
        iconColor = const Color(0xFF2563EB);
        break;
      case 'case_submitted':
        iconData = Icons.send_outlined;
        iconColor = const Color(0xFF10B981);
        break;
      default:
        iconData = Icons.notifications_outlined;
        iconColor = const Color(0xFF2563EB);
    }

    if (priority == 'urgent') {
      iconColor = Colors.red;
    } else if (priority == 'high') {
      iconColor = Colors.orange;
    }

    return Icon(iconData, color: iconColor, size: 24);
  }

  Widget _buildPriorityIndicator(String priority) {
    if (priority == 'urgent') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Text(
          'URGENT',
          style: TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      );
    } else if (priority == 'high') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Text(
          'HIGH',
          style: TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  String _formatCategoryName(String category) {
    // Smart categories with user-friendly names
    return category;
  }

  // Helper method to check if notification was recently read (within 24 hours)
  bool _isRecentlyRead(Map<String, dynamic> notification) {
    if (notification['is_read'] != true) return false;
    
    try {
      final readAt = notification['read_at'];
      if (readAt == null) return false;
      
      final readTime = DateTime.parse(readAt);
      final now = DateTime.now();
      final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));
      
      return readTime.isAfter(twentyFourHoursAgo);
    } catch (e) {
      return false;
    }
  }

  // Helper method to get notification age category
  String _getNotificationAgeCategory(Map<String, dynamic> notification) {
    try {
      final createdAt = notification['created_at'];
      if (createdAt == null) return 'unknown';
      
      final createdTime = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(createdTime);
      
      if (difference.inHours < 1) return 'recent';
      if (difference.inDays < 1) return 'today';
      if (difference.inDays < 7) return 'week';
      return 'old';
    } catch (e) {
      return 'unknown';
    }
  }

  List<Map<String, dynamic>> _filterNotifications(List<Map<String, dynamic>> notifications) {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    
    List<Map<String, dynamic>> filtered = notifications.where((notification) {
      // Parse notification date
      DateTime? notificationDate;
      try {
        if (notification['created_at'] != null) {
          notificationDate = DateTime.parse(notification['created_at']);
        }
      } catch (e) {
        // If we can't parse the date, include it to avoid losing notifications
        notificationDate = now;
      }
      
      // Apply smart filtering categories
      switch (_selectedCategory) {
        case 'Recent':
          // Show unread notifications OR notifications from last 7 days
          final isUnread = notification['is_read'] != true;
          final isFromLastWeek = notificationDate != null && notificationDate.isAfter(sevenDaysAgo);
          if (!isUnread && !isFromLastWeek) {
            return false;
          }
          break;
          
        case 'Unread':
          // Only unread notifications
          if (notification['is_read'] == true) {
            return false;
          }
          break;
          
        case 'All':
          // Show all notifications - no filtering by read status or date
          break;
          
        case 'Important':
          // High/urgent priority notifications regardless of read status
          final priority = notification['priority'] ?? 'normal';
          if (priority != 'high' && priority != 'urgent') {
            return false;
          }
          break;
      }
      
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final title = notification['title']?.toString().toLowerCase() ?? '';
        final message = notification['message']?.toString().toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();

        if (!title.contains(query) && !message.contains(query)) {
          return false;
        }
      }

      // Legacy unread filter (kept for backward compatibility)
      if (_showUnreadOnly && notification['is_read'] == true) {
        return false;
      }

      return true;
    }).toList();

    filtered.sort((a, b) {
      final aCreatedAt = a['created_at'];
      final bCreatedAt = b['created_at'];

      if (aCreatedAt == null && bCreatedAt == null) return 0;
      if (aCreatedAt == null) return 1;
      if (bCreatedAt == null) return -1;

      try {
        final aDate = DateTime.parse(aCreatedAt);
        final bDate = DateTime.parse(bCreatedAt);

        return _sortOrder == 'newest'
            ? bDate.compareTo(aDate)
            : aDate.compareTo(bDate);
      } catch (e) {
        print('Error parsing dates for sorting: $e');
        return 0;
      }
    });

    return filtered;
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification, bool isDark) {
    final isRead = notification['is_read'] ?? false;
    final isRecentlyRead = _isRecentlyRead(notification);
    final ageCategory = _getNotificationAgeCategory(notification);
    final title = notification['title'] ?? 'No Title';
    final message = notification['message'] ?? 'No Message';
    final type = notification['type'] ?? 'info';
    final priority = notification['priority'] ?? 'normal';
    final senderName = notification['sender_name'] ?? 'System';
    final createdAt = notification['created_at'];
    final notificationId = notification['id'];

    DateTime? createdTime;
    try {
      if (createdAt != null) {
        createdTime = DateTime.parse(createdAt);
      }
    } catch (e) {
      print('Error parsing date: $e');
    }

    // Enhanced visual styling based on notification state
    Color borderColor;
    Color backgroundColor;
    double opacity;
    double borderWidth;
    List<BoxShadow> boxShadows;
    
    if (!isRead) {
      // Unread notifications - prominent styling
      borderColor = const Color(0xFF2563EB).withOpacity(0.3);
      backgroundColor = isDark ? const Color(0xFF1E293B) : Colors.white;
      opacity = 1.0;
      borderWidth = 1.5;
      boxShadows = [
        BoxShadow(
          color: const Color(0xFF2563EB).withOpacity(0.1),
          blurRadius: 8.0,
          offset: const Offset(0, 4),
          spreadRadius: 1.0,
        ),
      ];
    } else if (isRecentlyRead) {
      // Recently read notifications - muted but visible
      borderColor = isDark ? const Color(0xFF10B981).withOpacity(0.2) : const Color(0xFF6EE7B7).withOpacity(0.3);
      backgroundColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4);
      opacity = 0.85;
      borderWidth = 1.2;
      boxShadows = [
        BoxShadow(
          color: isDark ? Colors.black.withOpacity(0.15) : Colors.grey.withOpacity(0.08),
          blurRadius: 4.0,
          offset: const Offset(0, 2),
        ),
      ];
    } else {
      // Older read notifications - minimal but accessible
      borderColor = isDark ? Colors.grey[700]!.withOpacity(0.3) : Colors.grey[300]!.withOpacity(0.5);
      backgroundColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
      opacity = 0.75;
      borderWidth = 1.0;
      boxShadows = [
        BoxShadow(
          color: isDark ? Colors.black.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
          blurRadius: 2.0,
          offset: const Offset(0, 1),
        ),
      ];
    }

    return Opacity(
      opacity: opacity,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: backgroundColor,
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
          boxShadow: boxShadows,
        ),
        child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            // Simply mark notification as read when tapped
            if (!isRead) {
              await _markAsRead(notificationId);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Modern icon container
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isRead 
                            ? [Colors.grey.withOpacity(0.1), Colors.grey.withOpacity(0.05)]
                            : [const Color(0xFF2563EB).withOpacity(0.1), const Color(0xFF1D4ED8).withOpacity(0.05)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _buildNotificationIcon(type, priority),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                                        height: 1.3,
                                      ),
                                    ),
                                    // Recently Read badge
                                    if (isRecentlyRead) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDark 
                                            ? const Color(0xFF10B981).withOpacity(0.2) 
                                            : const Color(0xFFECFDF5),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isDark 
                                              ? const Color(0xFF10B981).withOpacity(0.3)
                                              : const Color(0xFF6EE7B7),
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Text(
                                          'Recently Read',
                                          style: TextStyle(
                                            color: isDark 
                                              ? const Color(0xFF6EE7B7)
                                              : const Color(0xFF047857),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (priority == 'urgent' || priority == 'high')
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: _buildPriorityIndicator(priority),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Spacer(),
                              if (createdTime != null) ...[
                                Icon(
                                  Icons.access_time_outlined,
                                  size: 12,
                                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  PhilippineTime.formatDateTime(PhilippineTime.fromUtc(createdTime)),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Read status indicator
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isRead 
                          ? Colors.transparent
                          : const Color(0xFF2563EB),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[300] : const Color(0xFF6B7280),
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(bool isDark) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        final stats = notificationProvider.notificationStats;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notification Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Total',
                      stats['total_notifications']?.toString() ?? '0',
                      Icons.notifications,
                      Colors.blue,
                      isDark,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Unread',
                      stats['unread_notifications']?.toString() ?? '0',
                      Icons.mark_email_unread,
                      Colors.orange,
                      isDark,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Urgent',
                      stats['urgent_notifications']?.toString() ?? '0',
                      Icons.priority_high,
                      Colors.red,
                      isDark,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Today',
                      stats['notifications_today']?.toString() ?? '0',
                      Icons.today,
                      Colors.green,
                      isDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When you receive notifications, they\'ll appear here',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Clean organized filter section
  Widget _buildFilterSection(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Column(
        children: [
          // Search Bar
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                if (mounted) {
                  setState(() {
                    _searchQuery = value;
                  });
                }
              },
              decoration: InputDecoration(
                hintText: 'Search notifications...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    if (mounted) {
                      setState(() {
                        _searchQuery = '';
                      });
                    }
                  },
                  icon: Icon(
                    Icons.clear,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    size: 18,
                  ),
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 14,
              ),
            ),
          ),

          // Categories Filter Row
          Container(
            height: 45,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;

                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        if (mounted) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB))
                              : (isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6)),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB))
                                : (isDark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB)),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _formatCategoryName(category),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.grey[300] : Colors.grey[700]),
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Sort and Filter Options Row
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                // Sort Options
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Icon(
                        Icons.sort,
                        size: 18,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: [
                            // Newest First Button
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () {
                                    if (mounted) {
                                      setState(() {
                                        _sortOrder = 'newest';
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: _sortOrder == 'newest'
                                          ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB))
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _sortOrder == 'newest'
                                            ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB))
                                            : (isDark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB)),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      'Newest',
                                      style: TextStyle(
                                        color: _sortOrder == 'newest'
                                            ? Colors.white
                                            : (isDark ? Colors.grey[300] : Colors.grey[700]),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Oldest First Button
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () {
                                    if (mounted) {
                                      setState(() {
                                        _sortOrder = 'oldest';
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: _sortOrder == 'oldest'
                                          ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB))
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _sortOrder == 'oldest'
                                            ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB))
                                            : (isDark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB)),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      'Oldest',
                                      style: TextStyle(
                                        color: _sortOrder == 'oldest'
                                            ? Colors.white
                                            : (isDark ? Colors.grey[300] : Colors.grey[700]),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Unread Only Toggle
                Expanded(
                  flex: 1,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        if (mounted) {
                          setState(() {
                            _showUnreadOnly = !_showUnreadOnly;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: _showUnreadOnly
                              ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _showUnreadOnly
                                ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB))
                                : (isDark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB)),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _showUnreadOnly ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                              size: 16,
                              color: _showUnreadOnly
                                  ? Colors.white
                                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Unread Only',
                                style: TextStyle(
                                  color: _showUnreadOnly
                                      ? Colors.white
                                      : (isDark ? Colors.grey[300] : Colors.grey[700]),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 1,
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        title: Text(
          'Notifications',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              final hasUnread = notificationProvider.unreadNotificationCount > 0;

              return Row(
                children: [
                  if (hasUnread)
                    IconButton(
                      onPressed: _markAllAsRead,
                      icon: Icon(
                        Icons.mark_email_read,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      tooltip: 'Mark all as read',
                    ),
                  IconButton(
                    onPressed: _loadNotifications,
                    icon: _isLoading
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    )
                        : Icon(
                      Icons.refresh,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    tooltip: 'Refresh',
                  ),
                  const SizedBox(width: 8),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          final allNotifications = notificationProvider.notifications;
          final filteredNotifications = _filterNotifications(allNotifications);

          if (_isLoading && allNotifications.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (allNotifications.isEmpty) {
            return RefreshIndicator(
              onRefresh: _loadNotifications,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: _buildEmptyState(isDark),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadNotifications,
            child: Column(
              children: [
                // Clean Organized Filter Section
                _buildFilterSection(isDark),

                // Notifications Content
                Expanded(
                  child: Column(
                    children: [
                      // Stats Card
                      _buildStatsCard(isDark),

                      // Notifications List
                      Expanded(
                        child: filteredNotifications.isEmpty
                            ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.filter_list_off,
                                size: 60,
                                color: isDark ? Colors.grey[600] : Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No notifications match your filters',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                            : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: filteredNotifications.length,
                          itemBuilder: (context, index) {
                            final notification = filteredNotifications[index];
                            return _buildNotificationCard(notification, isDark);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}