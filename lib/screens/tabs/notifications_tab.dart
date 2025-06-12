import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';

class NotificationsTab extends StatefulWidget {
  const NotificationsTab({super.key});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'All';
  bool _showUnreadOnly = false;
  bool _isLoading = false;
  String _searchQuery = '';
  String _sortOrder = 'newest';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'system',
    'legal_update',
    'case_update',
    'user_management',
    'security',
    'announcement',
    'marketing'
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
      final authProvider = context.read<AuthProvider>();
      await authProvider.refreshNotifications();
    } catch (e) {
      print('Error loading notifications: $e');
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
      final authProvider = context.read<AuthProvider>();
      await authProvider.markNotificationAsRead(notificationId);
    } catch (e) {
      print('Error marking notification as read: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating notification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    if (!mounted) return;

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.markAllNotificationsAsRead();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    if (!mounted) return;

    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.deleteNotification(notificationId);

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

  Future<void> _handleActionUrl(String? actionUrl) async {
    if (actionUrl == null || actionUrl.isEmpty) return;

    try {
      if (actionUrl.startsWith('/')) {
        if (mounted) {
          Navigator.pushNamed(context, actionUrl);
        }
      } else {
        final Uri url = Uri.parse(actionUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      print('Error handling action URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening link: $e'),
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
      case 'success':
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case 'warning':
        iconData = Icons.warning;
        iconColor = Colors.orange;
        break;
      case 'error':
        iconData = Icons.error;
        iconColor = Colors.red;
        break;
      case 'legal_update':
        iconData = Icons.gavel;
        iconColor = Colors.blue;
        break;
      case 'security_alert':
        iconData = Icons.security;
        iconColor = Colors.red;
        break;
      case 'admin_message':
        iconData = Icons.admin_panel_settings;
        iconColor = Colors.purple;
        break;
      case 'announcement':
        iconData = Icons.campaign;
        iconColor = Colors.indigo;
        break;
      case 'system':
        iconData = Icons.settings;
        iconColor = Colors.grey;
        break;
      case 'user_signup':
        iconData = Icons.person_add;
        iconColor = Colors.green;
        break;
      case 'case_created':
      case 'case_update':
        iconData = Icons.folder_open;
        iconColor = Colors.blue;
        break;
      default:
        iconData = Icons.info;
        iconColor = Colors.blue;
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'URGENT',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (priority == 'high') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'HIGH',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  String _formatCategoryName(String category) {
    switch (category) {
      case 'user_management':
        return 'User Management';
      case 'legal_update':
        return 'Legal Updates';
      case 'case_update':
        return 'Case Updates';
      case 'security':
        return 'Security';
      case 'announcement':
        return 'Announcements';
      case 'marketing':
        return 'Marketing';
      case 'system':
        return 'System';
      default:
        return category.split('_').map((word) =>
        word.substring(0, 1).toUpperCase() + word.substring(1)
        ).join(' ');
    }
  }

  List<Map<String, dynamic>> _filterNotifications(List<Map<String, dynamic>> notifications) {
    List<Map<String, dynamic>> filtered = notifications.where((notification) {
      if (_selectedCategory != 'All' &&
          notification['notification_category'] != _selectedCategory) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final title = notification['title']?.toString().toLowerCase() ?? '';
        final message = notification['message']?.toString().toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();

        if (!title.contains(query) && !message.contains(query)) {
          return false;
        }
      }

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
    final title = notification['title'] ?? 'No Title';
    final message = notification['message'] ?? 'No Message';
    final type = notification['type'] ?? 'info';
    final priority = notification['priority'] ?? 'normal';
    final category = notification['notification_category'] ?? 'system';
    final senderName = notification['sender_name'] ?? 'System';
    final createdAt = notification['created_at'];
    final actionUrl = notification['action_url'];
    final notificationId = notification['id'];

    DateTime? createdTime;
    try {
      if (createdAt != null) {
        createdTime = DateTime.parse(createdAt);
      }
    } catch (e) {
      print('Error parsing date: $e');
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead
              ? (isDark ? Colors.grey[700]! : Colors.grey[300]!)
              : (isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB)),
          width: isRead ? 1 : 2,
        ),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            if (!isRead) {
              await _markAsRead(notificationId);
            }
            if (actionUrl != null) {
              await _handleActionUrl(actionUrl);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNotificationIcon(type, priority),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                              if (priority == 'urgent' || priority == 'high')
                                _buildPriorityIndicator(priority),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 14,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                senderName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.category_outlined,
                                size: 14,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatCategoryName(category),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      onSelected: (value) async {
                        switch (value) {
                          case 'mark_read':
                            await _markAsRead(notificationId);
                            break;
                          case 'delete':
                            await _deleteNotification(notificationId);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        if (!isRead)
                          const PopupMenuItem(
                            value: 'mark_read',
                            child: Row(
                              children: [
                                Icon(Icons.mark_email_read),
                                SizedBox(width: 8),
                                Text('Mark as Read'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (createdTime != null)
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeago.format(createdTime),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[500] : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),

                    if (actionUrl != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.open_in_new,
                              size: 12,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'View',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                if (!isRead)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    height: 3,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(bool isDark) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final stats = authProvider.notificationStats;

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
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final hasUnread = authProvider.unreadNotificationCount > 0;

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
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final allNotifications = authProvider.notifications;
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