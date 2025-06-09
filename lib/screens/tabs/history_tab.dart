import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/database_service.dart';
import '../../utils/philippine_time.dart';
import 'dart:async';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  final DatabaseService _databaseService = DatabaseService();
  List<Map<String, dynamic>> _chatSessions = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadChatSessions();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadChatSessions(showLoading: false);
      }
    });
  }

  Future<void> _loadChatSessions({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Check current user
      final currentUser = _databaseService.currentUserId;

      if (currentUser == null) {
        setState(() {
          _isLoading = false;
          _chatSessions = [];
        });
        return;
      }

      // Try to get sessions using the database function
      List<Map<String, dynamic>> chatSessions = [];

      try {
        chatSessions = await _databaseService.getChatSessions(limit: 50);
      } catch (sessionError) {
        print('❌ Session function error: $sessionError');

        // Fallback approach
        try {
          final allMessages = await _databaseService.getChatHistory(limit: 50);

          if (allMessages.isNotEmpty) {
            chatSessions = _convertMessagesToSessions(allMessages);
          }
        } catch (fallbackError) {
          print('❌ Fallback error: $fallbackError');
          chatSessions = [];
        }
      }

      // Update state safely
      if (mounted) {
        setState(() {
          _chatSessions = chatSessions;
          _isLoading = false;
        });
      }

    } catch (e) {
      print('❌ Overall error loading chat sessions: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _chatSessions = [];
        });
      }
    }
  }

  // Convert individual messages to session format
  List<Map<String, dynamic>> _convertMessagesToSessions(List<Map<String, dynamic>> messages) {
    if (messages.isEmpty) return [];

    // Group messages by session_id
    Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var message in messages) {
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

        // Safely get questions with null checks
        final firstQuestion = firstMessage['question']?.toString() ?? 'No question';
        final lastQuestion = lastMessage['question']?.toString() ?? firstQuestion;

        // Ensure created_at fields are valid
        final firstCreatedAt = firstMessage['created_at']?.toString() ?? DateTime.now().toUtc().toIso8601String();
        final lastCreatedAt = lastMessage['created_at']?.toString() ?? firstCreatedAt;

        sessions.add({
          'session_id': sessionId.startsWith('single_') ? null : sessionId,
          'first_question': firstQuestion,
          'last_question': lastQuestion,
          'message_count': sessionMessages.length,
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

  List<Map<String, dynamic>> get filteredSessions {
    if (_selectedFilter == 'All') {
      return _chatSessions;
    } else {
      return _chatSessions.where((session) {
        final categories = session['categories'] as List?;
        return categories?.any((cat) => cat.toString() == _selectedFilter) ?? false;
      }).toList();
    }
  }

  List<String> get categories {
    final Set<String> uniqueCategories = {'All'};

    final expectedCategories = [
      'Cybercrime Prevention Act',
      'Online Harassment',
      'E-commerce Fraud',
      'Identity Theft',
      'Data Privacy',
      'Unauthorized Access',
      'General'
    ];

    // Collect categories from sessions
    for (var session in _chatSessions) {
      final categories = session['categories'] as List?;
      if (categories != null) {
        for (var category in categories) {
          final categoryStr = category.toString();
          if (expectedCategories.contains(categoryStr)) {
            uniqueCategories.add(categoryStr);
          }
        }
      }
    }

    // Return in predefined order
    List<String> orderedCategories = ['All'];
    for (String expected in expectedCategories) {
      if (uniqueCategories.contains(expected)) {
        orderedCategories.add(expected);
      }
    }

    return orderedCategories;
  }

  double get averageConfidence {
    if (_chatSessions.isEmpty) return 0.0;
    final confidenceScores = _chatSessions
        .where((session) => session['avg_confidence'] != null)
        .map((session) => (session['avg_confidence'] as num).toDouble())
        .toList();

    if (confidenceScores.isEmpty) return 0.0;
    return confidenceScores.reduce((a, b) => a + b) / confidenceScores.length;
  }

  int _getTotalMessages() {
    return _chatSessions.fold<int>(0, (sum, session) {
      final messageCount = session['message_count'] as int? ?? 0;
      return sum + messageCount;
    });
  }

  void _showConversationDetail(Map<String, dynamic> session) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ConversationDetailPage(session: session),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]
                      : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB)).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.history_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'Chat History',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(
              Icons.search_rounded,
              color: isDark ? Colors.white : const Color(0xFF2563EB),
            ),
            onPressed: () {
              _showSearchDialog();
            },
          ),
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? Colors.white : const Color(0xFF2563EB),
            ),
            onPressed: () => _loadChatSessions(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadChatSessions,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Cards
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildOverviewCard(
                      context,
                      icon: Icons.chat_bubble_outline_rounded,
                      title: '${_chatSessions.length}',
                      subtitle: 'Conversations',
                      color: Colors.blue,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildOverviewCard(
                      context,
                      icon: Icons.forum_rounded,
                      title: '${_getTotalMessages()}',
                      subtitle: 'Total Messages',
                      color: Colors.green,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildOverviewCard(
                      context,
                      icon: Icons.category_rounded,
                      title: '${categories.length - 1}',
                      subtitle: 'Legal Categories',
                      color: Colors.orange,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildOverviewCard(
                      context,
                      icon: Icons.verified_rounded,
                      title: '${(averageConfidence * 100).round()}%',
                      subtitle: 'AI Confidence',
                      color: Colors.purple,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),

            // Category Filter
            if (categories.length > 1) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Filter by Category',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF3B82F6).withOpacity(0.2)
                            : const Color(0xFF2563EB).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${categories.length - 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = category == _selectedFilter;
                    final categoryCount = category == 'All'
                        ? _chatSessions.length
                        : _chatSessions.where((session) {
                      final sessionCategories = session['categories'] as List?;
                      return sessionCategories?.any((cat) => cat.toString() == category) ?? false;
                    }).length;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                category,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : isDark ? Colors.grey[300] : Colors.grey[700],
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (categoryCount > 0) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white.withOpacity(0.3)
                                      : (isDark ? Colors.grey[600] : Colors.grey[400])?.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$categoryCount',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedFilter = category;
                          });
                        },
                        backgroundColor: isDark ? const Color(0xFF334155) : Colors.grey[100],
                        selectedColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
                        checkmarkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Chat Sessions List
            Expanded(
              child: filteredSessions.isEmpty
                  ? _buildEmptyState(isDark)
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredSessions.length,
                itemBuilder: (context, index) {
                  final session = filteredSessions[index];
                  return _buildEnhancedSessionCard(
                    context,
                    session: session,
                    isDark: isDark,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF374151), const Color(0xFF1F2937)]
                    : [const Color(0xFFF3F4F6), const Color(0xFFE5E7EB)],
              ),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.history_rounded,
              size: 48,
              color: isDark ? Colors.grey[500] : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _chatSessions.isEmpty
                ? 'No conversations yet'
                : 'No conversations match your filter',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _chatSessions.isEmpty
                ? 'Start chatting with LawBot to see your conversations here'
                : 'Try selecting a different category',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color color,
        required bool isDark,
      }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSessionCard(
      BuildContext context, {
        required Map<String, dynamic> session,
        required bool isDark,
      }) {
    // Format the date using Philippine time
    String formattedDate = '';
    if (session['last_created_at'] != null) {
      try {
        formattedDate = PhilippineTime.formatChatHistoryTime(session['last_created_at']);
      } catch (e) {
        formattedDate = 'Unknown date';
      }
    }

    // Get session metadata
    final categories = session['categories'] as List<dynamic>?;
    final avgConfidence = session['avg_confidence'] as double?;
    final messageCount = session['message_count'] as int? ?? 0;
    final firstQuestion = session['first_question'] as String? ?? 'No question';
    final hasRecommendations = session['has_recommendations'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showConversationDetail(session),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category badges
                    Flexible(
                      flex: 2,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: (categories?.take(2) ?? ['General']).map((category) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]
                                  : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            category.toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        )).toList(),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Message count and confidence section
                    Flexible(
                      flex: 3,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Message count badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.blue.withOpacity(0.2)
                                  : Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? Colors.blue[700]! : Colors.blue[200]!,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.forum_rounded,
                                  size: 10,
                                  color: isDark ? Colors.blue[300] : Colors.blue[700],
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '$messageCount',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: isDark ? Colors.blue[300] : Colors.blue[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Recommendations indicator
                          if (hasRecommendations) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.orange,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    size: 10,
                                    color: Colors.orange[700],
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Tips',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.orange[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],

                          if (avgConfidence != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: avgConfidence > 0.8
                                    ? Colors.green.withOpacity(0.1)
                                    : avgConfidence > 0.6
                                    ? Colors.orange.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: avgConfidence > 0.8
                                      ? Colors.green
                                      : avgConfidence > 0.6
                                      ? Colors.orange
                                      : Colors.grey,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified_rounded,
                                    size: 10,
                                    color: avgConfidence > 0.8
                                        ? Colors.green
                                        : avgConfidence > 0.6
                                        ? Colors.orange
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${(avgConfidence * 100).round()}%',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: avgConfidence > 0.8
                                          ? Colors.green
                                          : avgConfidence > 0.6
                                          ? Colors.orange
                                          : Colors.grey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],

                          // Date
                          Flexible(
                            child: Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey[400] : Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // First question
                Text(
                  firstQuestion,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Session summary with recommendation hint
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        messageCount == 1
                            ? 'Single question conversation'
                            : '$messageCount messages in this conversation',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[300] : Colors.grey[600],
                          height: 1.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasRecommendations) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 12,
                              color: Colors.orange[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Has recommendations',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 16,
                          color: isDark ? Colors.grey[400] : Colors.grey[500],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'View Full Conversation',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (hasRecommendations) ...[
                          const SizedBox(width: 8),
                          Text(
                            '• Tips included',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSearchDialog() {
    final isDark = context.read<ThemeProvider>().isDarkMode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: const Text('Search Conversations'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Search by question or conversation...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (query) {
            Navigator.pop(context);
            _performSearch(query);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final searchResults = await _databaseService.searchChatSessions(
        searchQuery: query,
        category: _selectedFilter == 'All' ? null : _selectedFilter,
      );

      setState(() {
        _chatSessions = searchResults;
        _isLoading = false;
      });
    } catch (e) {
      print('Error searching: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
}

// Updated Conversation Detail Page with Recommendations and Fixed Overflow
class ConversationDetailPage extends StatefulWidget {
  final Map<String, dynamic> session;

  const ConversationDetailPage({super.key, required this.session});

  @override
  State<ConversationDetailPage> createState() => _ConversationDetailPageState();
}

class _ConversationDetailPageState extends State<ConversationDetailPage> {
  final DatabaseService _databaseService = DatabaseService();
  List<Map<String, dynamic>> _sessionMessages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessionMessages();
  }

  Future<void> _loadSessionMessages() async {
    try {
      // If session has no session_id, it's a converted single message
      final sessionId = widget.session['session_id'];

      if (sessionId != null) {
        final messages = await _databaseService.getSessionMessages(sessionId.toString());
        setState(() {
          _sessionMessages = messages;
          _isLoading = false;
        });
      } else {
        // Single message conversation - create from session data
        setState(() {
          _sessionMessages = [{
            'id': 'single',
            'question': widget.session['first_question'],
            'answer': 'Response not available for single messages',
            'category': widget.session['categories']?.first ?? 'General',
            'confidence_score': widget.session['avg_confidence'],
            'created_at': widget.session['first_created_at'],
            'metadata': {},
          }];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading session messages: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Extract recommendations from message metadata
  List<String> _getRecommendations(Map<String, dynamic> message) {
    try {
      final metadata = message['metadata'] as Map<String, dynamic>?;
      if (metadata != null && metadata['recommendations'] is List) {
        return (metadata['recommendations'] as List).cast<String>();
      }
    } catch (e) {
      print('Error extracting recommendations: $e');
    }
    return [];
  }

  // Extract keywords from message metadata
  List<String> _getKeywords(Map<String, dynamic> message) {
    try {
      final metadata = message['metadata'] as Map<String, dynamic>?;
      if (metadata != null && metadata['keywords'] is List) {
        return (metadata['keywords'] as List).cast<String>();
      }
    } catch (e) {
      print('Error extracting keywords: $e');
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    final categories = widget.session['categories'] as List<dynamic>?;
    final avgConfidence = widget.session['avg_confidence'] as double?;
    final messageCount = widget.session['message_count'] as int? ?? 0;

    String formattedDate = '';
    if (widget.session['first_created_at'] != null) {
      try {
        final philippineTime = PhilippineTime.parseDatabaseTime(widget.session['first_created_at']);
        if (philippineTime != null) {
          formattedDate = PhilippineTime.formatDateTime(philippineTime);
        } else {
          formattedDate = 'Unknown date';
        }
      } catch (e) {
        formattedDate = 'Unknown date';
      }
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        title: Text(
          'Conversation Details',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : const Color(0xFF2563EB),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session Header Card (FIXED OVERFLOW)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fixed: Responsive category badges and confidence section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category badges row
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (categories ?? ['General']).map((category) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]
                                  : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        )).toList(),
                      ),

                      const SizedBox(height: 12),

                      // Confidence and date row (FIXED OVERFLOW)
                      Row(
                        children: [
                          if (avgConfidence != null) ...[
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: avgConfidence > 0.8
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: avgConfidence > 0.8 ? Colors.green : Colors.orange,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified_rounded,
                                      size: 14,
                                      color: avgConfidence > 0.8 ? Colors.green : Colors.orange,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        '${(avgConfidence * 100).round()}% Confidence',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: avgConfidence > 0.8 ? Colors.green : Colors.orange,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],

                          // Date with proper text wrapping
                          Expanded(
                            child: Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Message count row
                  Row(
                    children: [
                      Icon(
                        Icons.forum_rounded,
                        size: 16,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$messageCount messages in this conversation',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Messages List
            ...(_sessionMessages.map((message) {
              final recommendations = _getRecommendations(message);
              final keywords = _getKeywords(message);

              return Column(
                children: [
                  // Question Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]
                            : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB)).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.person, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Your Question',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          message['question'] ?? 'No question',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Answer Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LawBot Response Header
                        Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDark
                                      ? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]
                                      : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.smart_toy,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'LawBot Response',
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            if (message['confidence_score'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${((message['confidence_score'] as double) * 100).round()}%',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Main Answer Text
                        Text(
                          message['answer'] ?? 'No answer',
                          style: TextStyle(
                            color: isDark ? Colors.grey[200] : const Color(0xFF374151),
                            fontSize: 16,
                            height: 1.6,
                          ),
                        ),

                        // Recommendations Section
                        if (recommendations.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (isDark ? Colors.blue[900] : Colors.blue[50])?.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: (isDark ? Colors.blue[700] : Colors.blue[200])!,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.lightbulb_outline,
                                      size: 16,
                                      color: isDark ? Colors.blue[300] : Colors.blue[700],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Recommendations:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.blue[300] : Colors.blue[700],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...recommendations.take(5).map((rec) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(top: 8, right: 8),
                                        width: 4,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.blue[200] : Colors.blue[800],
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          rec,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isDark ? Colors.blue[200] : Colors.blue[800],
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                              ],
                            ),
                          ),
                        ],

                        // Keywords Section
                        if (keywords.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: keywords.take(6).map((keyword) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey[700]?.withOpacity(0.5)
                                    : Colors.grey[200]?.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                keyword,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )).toList(),
                          ),
                        ],

                        // Message Timestamp
                        const SizedBox(height: 12),
                        Text(
                          PhilippineTime.formatChatHistoryTime(message['created_at'] ?? ''),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            })),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}