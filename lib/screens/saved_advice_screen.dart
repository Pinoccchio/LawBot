import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/theme_provider.dart';
import '../services/database_service.dart';
import '../utils/philippine_time.dart';

class SavedAdviceScreen extends StatefulWidget {
  final List<Map<String, dynamic>> savedAdvice;
  final Function(String) onAdviceRemoved;

  const SavedAdviceScreen({
    super.key,
    required this.savedAdvice,
    required this.onAdviceRemoved,
  });

  @override
  State<SavedAdviceScreen> createState() => _SavedAdviceScreenState();
}

class _SavedAdviceScreenState extends State<SavedAdviceScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Map<String, dynamic>> _savedAdvice = [];
  bool _isLoading = false;
  String _selectedFilter = 'All';

  // Cache for expanded conversation details (for session-based advice)
  Map<String, List<Map<String, dynamic>>> _conversationCache = {};
  Set<String> _expandedAdvice = {};

  @override
  void initState() {
    super.initState();
    _savedAdvice = List.from(widget.savedAdvice);
  }

  // Check if this saved advice is from a session (has placeholder answer)
  bool _isSessionBasedAdvice(Map<String, dynamic> advice) {
    final answer = advice['answer']?.toString() ?? '';
    return answer.contains('conversation summary') ||
        answer == 'No answer available for this conversation summary' ||
        answer.isEmpty ||
        answer == 'No answer';
  }

  // Extract session ID from advice metadata or question
  String? _getSessionIdFromAdvice(Map<String, dynamic> advice) {
    // Check metadata first
    final metadata = advice['metadata'] as Map<String, dynamic>?;
    final sessionId = metadata?['session_id']?.toString();
    if (sessionId != null && sessionId.isNotEmpty) {
      return sessionId;
    }

    // If no session ID in metadata, this might be individual message advice
    return null;
  }

  // Fetch conversation details for session-based advice
  Future<List<Map<String, dynamic>>> _fetchConversationForAdvice(String sessionId) async {
    // Check cache first
    if (_conversationCache.containsKey(sessionId)) {
      return _conversationCache[sessionId]!;
    }

    try {
      final messages = await _databaseService.getSessionMessages(sessionId);

      // Sort messages by creation time
      messages.sort((a, b) {
        final aTime = a['created_at']?.toString();
        final bTime = b['created_at']?.toString();

        if (aTime == null || bTime == null) return 0;

        try {
          return DateTime.parse(aTime).compareTo(DateTime.parse(bTime));
        } catch (e) {
          return 0;
        }
      });

      // Cache the result
      _conversationCache[sessionId] = messages;
      return messages;
    } catch (e) {
      print('Error fetching conversation for advice: $e');
      return [];
    }
  }

  // Dynamic categories getter matching HistoryTab logic
  List<String> get categories {
    final Set<String> uniqueCategories = {'All'};

    // Define the expected categories from your AI response
    final expectedCategories = [
      'Cybercrime Prevention Act',
      'Online Harassment',
      'E-commerce Fraud',
      'Identity Theft',
      'Data Privacy',
      'Unauthorized Access',
      'General'
    ];

    // Only add categories that exist in your saved advice
    for (var advice in _savedAdvice) {
      if (advice['category'] != null) {
        final category = advice['category'].toString();
        if (expectedCategories.contains(category)) {
          uniqueCategories.add(category);
        }
      }
    }

    // Return in the order: All first, then the predefined order
    List<String> orderedCategories = ['All'];
    for (String expected in expectedCategories) {
      if (uniqueCategories.contains(expected)) {
        orderedCategories.add(expected);
      }
    }

    return orderedCategories;
  }

  Future<void> _refreshSavedAdvice() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedAdvice = await _databaseService.getSavedAdvice();
      setState(() {
        _savedAdvice = updatedAdvice;
        _isLoading = false;
        // Clear cache on refresh
        _conversationCache.clear();
        _expandedAdvice.clear();
      });
    } catch (e) {
      print('Error refreshing saved advice: $e');
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Failed to refresh saved advice. Please try again.', Colors.red);
    }
  }

  Future<void> _removeAdvice(String adviceId) async {
    try {
      await _databaseService.removeSavedAdvice(adviceId);
      setState(() {
        _savedAdvice.removeWhere((advice) => advice['id'] == adviceId);
        // Also remove from expanded set if it was expanded
        _expandedAdvice.removeWhere((id) => id.contains(adviceId));
      });
      widget.onAdviceRemoved(adviceId);
      _showSnackBar('Saved advice removed successfully!', Colors.green);
    } catch (e) {
      print('Error removing saved advice: $e');
      _showSnackBar('Failed to remove saved advice. Please try again.', Colors.red);
    }
  }

  Future<void> _shareAdvice(Map<String, dynamic> advice) async {
    try {
      final shareText = '''
📋 Saved Legal Advice from LawBot

❓ Question:
${advice['question'] ?? 'No question'}

🤖 LawBot Answer:
${advice['answer'] ?? 'No answer'}

📂 Category: ${advice['category'] ?? 'General'}
⏰ ${PhilippineTime.formatChatHistoryTime(advice['created_at'])}

---
Generated by LawBot - Your AI Legal Assistant for Philippine Cybercrime Laws
      ''';

      await Share.share(
        shareText.trim(),
        subject: 'Saved Legal Advice from LawBot',
      );
    } catch (e) {
      print('Error sharing advice: $e');
      _showSnackBar('Failed to share advice. Please try again.', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // Updated filtering logic to match HistoryTab exactly
  List<Map<String, dynamic>> get _filteredAdvice {
    if (_selectedFilter == 'All') {
      return _savedAdvice;
    }
    return _savedAdvice.where((advice) {
      final adviceCategory = (advice['category'] ?? '').toString();
      return adviceCategory == _selectedFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : const Color(0xFF2563EB),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF3B82F6).withOpacity(0.2)
                    : const Color(0xFF2563EB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF3B82F6).withOpacity(0.5)
                      : const Color(0xFF2563EB).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.bookmark,
                color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'Saved Advice',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _refreshSavedAdvice,
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? Colors.white : const Color(0xFF2563EB),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshSavedAdvice,
        child: _isLoading
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading saved advice...',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        )
            : Column(
          children: [
            // Category filter chips
            if (categories.length > 1)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filter by Category',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: categories.map((category) {
                          final isSelected = _selectedFilter == category;
                          return ChoiceChip(
                            label: Text(
                              category == 'All' ? 'All Categories' : category,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected
                                    ? Colors.white
                                    : isDark
                                    ? Colors.grey[300]
                                    : Colors.grey[700],
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedFilter = category;
                                });
                              }
                            },
                            backgroundColor: isDark ? const Color(0xFF334155) : Colors.grey[200],
                            selectedColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected
                                    ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB))
                                    : (isDark ? const Color(0xFF334155) : Colors.grey[300]!),
                                width: 1,
                              ),
                            ),
                            labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            // Advice List
            Expanded(
              child: _filteredAdvice.isEmpty
                  ? _buildEmptyState(isDark)
                  : RefreshIndicator(
                onRefresh: _refreshSavedAdvice,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredAdvice.length,
                  itemBuilder: (context, index) {
                    final advice = _filteredAdvice[index];
                    return _buildAdviceCard(advice, isDark);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF3B82F6).withOpacity(0.1)
                    : const Color(0xFF2563EB).withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF3B82F6).withOpacity(0.3)
                      : const Color(0xFF2563EB).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.bookmark_outline,
                size: 60,
                color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _selectedFilter == 'All'
                  ? 'No Saved Advice Yet'
                  : 'No $_selectedFilter Advice Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _selectedFilter == 'All'
                  ? 'Start saving important legal advice by tapping the bookmark icon on LawBot responses in the chat.'
                  : 'No saved advice found for "$_selectedFilter". Try selecting "All" to see all saved advice or save advice from this category.',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.chat, color: Colors.white),
              label: const Text(
                'Start Chatting',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdviceCard(Map<String, dynamic> advice, bool isDark) {
    final isSessionBased = _isSessionBasedAdvice(advice);
    final sessionId = _getSessionIdFromAdvice(advice);
    final adviceId = advice['id']?.toString() ?? '';
    final expandKey = '$adviceId-${sessionId ?? 'individual'}';
    final isExpanded = _expandedAdvice.contains(expandKey);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          border: Border.all(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAdviceHeader(advice, isDark),
            const SizedBox(height: 16),

            if (isSessionBased && sessionId != null) ...[
              // Show session-based advice with expandable conversation
              _buildSessionAdviceContent(advice, sessionId, expandKey, isDark),
            ] else ...[
              // Show regular individual advice
              _buildIndividualAdviceContent(advice, isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdviceHeader(Map<String, dynamic> advice, bool isDark) {
    return Row(
      children: [
        Flexible(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: (isDark ? Colors.amber[900] : Colors.amber[50])?.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (isDark ? Colors.amber[700] : Colors.amber[200])!,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bookmark,
                  size: 14,
                  color: isDark ? Colors.amber[300] : Colors.amber[700],
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    advice['category'] ?? 'General',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.amber[300] : Colors.amber[700],
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 2,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  advice['created_at'] != null
                      ? PhilippineTime.formatChatHistoryTime(advice['created_at'])
                      : 'Unknown date',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  size: 20,
                ),
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                onSelected: (value) {
                  switch (value) {
                    case 'share':
                      _shareAdvice(advice);
                      break;
                    case 'delete':
                      _showDeleteConfirmation(advice);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(
                          Icons.share_outlined,
                          size: 18,
                          color: isDark ? Colors.blue[300] : Colors.blue[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Share',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Remove',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSessionAdviceContent(Map<String, dynamic> advice, String sessionId, String expandKey, bool isDark) {
    final isExpanded = _expandedAdvice.contains(expandKey);
    final question = advice['question'] ?? 'No question';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question summary
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF3B82F6).withOpacity(0.1)
                : const Color(0xFF2563EB).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF3B82F6).withOpacity(0.3)
                  : const Color(0xFF2563EB).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.help_outline,
                    size: 16,
                    color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Saved Question',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.amber[900]?.withOpacity(0.5) : Colors.amber[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'From conversation',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.amber[300] : Colors.amber[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                question,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black,
                  height: 1.4,
                ),
                softWrap: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Expand/Collapse button for conversation
        InkWell(
          onTap: () async {
            if (isExpanded) {
              setState(() {
                _expandedAdvice.remove(expandKey);
              });
            } else {
              setState(() {
                _expandedAdvice.add(expandKey);
              });
              // Fetch conversation details if not already cached
              if (!_conversationCache.containsKey(sessionId)) {
                await _fetchConversationForAdvice(sessionId);
                if (mounted) setState(() {});
              }
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF10B981).withOpacity(0.1)
                  : const Color(0xFF10B981).withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF10B981).withOpacity(0.3)
                    : const Color(0xFF10B981).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.smart_toy_outlined,
                  size: 16,
                  color: Color(0xFF10B981),
                ),
                const SizedBox(width: 6),
                Text(
                  isExpanded ? 'Hide Full Conversation' : 'Show Full Conversation',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                  ),
                ),
                const Spacer(),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 16,
                  color: const Color(0xFF10B981),
                ),
              ],
            ),
          ),
        ),

        // Show full conversation when expanded
        if (isExpanded) ...[
          const SizedBox(height: 16),
          _buildFullConversationForAdvice(sessionId, isDark),
        ],
      ],
    );
  }

  Widget _buildFullConversationForAdvice(String sessionId, bool isDark) {
    final messages = _conversationCache[sessionId];

    if (messages == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Loading conversation...',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (messages.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No messages found in this conversation.',
          style: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      );
    }

    return Column(
      children: messages.map((message) => _buildConversationMessage(message, isDark)).toList(),
    );
  }

  Widget _buildConversationMessage(Map<String, dynamic> message, bool isDark) {
    final question = message['question'] ?? 'No question';
    final answer = message['answer'] ?? 'No answer';
    final createdAt = message['created_at'] ?? '';
    final metadata = message['metadata'] as Map<String, dynamic>?;
    final keywords = metadata?['keywords'] as List<dynamic>?;
    final recommendations = metadata?['recommendations'] as List<dynamic>?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          // Question
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF3B82F6).withOpacity(0.1)
                  : const Color(0xFF2563EB).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF3B82F6).withOpacity(0.3)
                    : const Color(0xFF2563EB).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.help_outline,
                      size: 14,
                      color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Q:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  question,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Answer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF10B981).withOpacity(0.1)
                  : const Color(0xFF10B981).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF10B981).withOpacity(0.3)
                    : const Color(0xFF10B981).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.smart_toy_outlined,
                      size: 14,
                      color: Color(0xFF10B981),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'A:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      PhilippineTime.formatChatHistoryTime(createdAt),
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.grey[400] : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  answer,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black,
                    height: 1.4,
                  ),
                ),

                // Keywords Section
                if (keywords != null && keywords.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: keywords.take(5).map((keyword) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.blue[900] : Colors.blue[50])?.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: (isDark ? Colors.blue[700] : Colors.blue[200])!,
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        keyword.toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.blue[300] : Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )).toList(),
                  ),
                ],

                // Recommendations Section
                if (recommendations != null && recommendations.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFFD97706).withOpacity(0.1)
                          : const Color(0xFFF59E0B).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFFD97706).withOpacity(0.3)
                            : const Color(0xFFF59E0B).withOpacity(0.2),
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
                              size: 12,
                              color: isDark ? Colors.amber[300] : Colors.amber[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Recommendations:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.amber[300] : Colors.amber[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ...recommendations.take(3).map((rec) => Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 3,
                                height: 3,
                                margin: const EdgeInsets.only(top: 5),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.amber[300] : Colors.amber[700],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  rec.toString(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.white : Colors.black,
                                    height: 1.3,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndividualAdviceContent(Map<String, dynamic> advice, bool isDark) {
    // Parse metadata for keywords and recommendations with null safety
    final metadata = advice['metadata'] as Map<String, dynamic>?;
    final keywords = metadata?['keywords'] as List<dynamic>?;
    final recommendations = metadata?['recommendations'] as List<dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF3B82F6).withOpacity(0.1)
                : const Color(0xFF2563EB).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF3B82F6).withOpacity(0.3)
                  : const Color(0xFF2563EB).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.help_outline,
                    size: 16,
                    color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Question',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                advice['question'] ?? 'No question',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black,
                  height: 1.4,
                ),
                softWrap: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Answer
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF10B981).withOpacity(0.1)
                : const Color(0xFF10B981).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF10B981).withOpacity(0.3)
                  : const Color(0xFF10B981).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.smart_toy_outlined,
                    size: 16,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'LawBot Answer',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                advice['answer'] ?? 'No answer',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black,
                  height: 1.4,
                ),
                softWrap: true,
              ),
            ],
          ),
        ),

        // Legal Keywords Section
        if (keywords != null && keywords.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E40AF).withOpacity(0.1)
                  : const Color(0xFF3B82F6).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF1E40AF).withOpacity(0.3)
                    : const Color(0xFF3B82F6).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.label_outline,
                      size: 16,
                      color: isDark ? Colors.blue[300] : Colors.blue[700],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Legal Keywords',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.blue[300] : Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: keywords.map((keyword) => Container(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth * 0.45,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.blue[900] : Colors.blue[50])?.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (isDark ? Colors.blue[700] : Colors.blue[200])!,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          keyword.toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.blue[300] : Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      )).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],

        // AI Recommendations Section
        if (recommendations != null && recommendations.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFFD97706).withOpacity(0.1)
                  : const Color(0xFFF59E0B).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? const Color(0xFFD97706).withOpacity(0.3)
                    : const Color(0xFFF59E0B).withOpacity(0.2),
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
                      color: isDark ? Colors.amber[300] : Colors.amber[700],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'AI Recommendations',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.amber[300] : Colors.amber[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...recommendations.take(3).map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.only(top: 6),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.amber[300] : Colors.amber[700],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rec.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white : Colors.black,
                            height: 1.4,
                          ),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],

        // Tags (if available - this was the original tags field)
        if (advice['tags'] != null && (advice['tags'] as List).isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF7C3AED).withOpacity(0.1)
                  : const Color(0xFF8B5CF6).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF7C3AED).withOpacity(0.3)
                    : const Color(0xFF8B5CF6).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.tag,
                      size: 16,
                      color: isDark ? Colors.purple[300] : Colors.purple[700],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Tags',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.purple[300] : Colors.purple[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: (advice['tags'] as List).map((tag) => Container(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth * 0.45,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.purple[900] : Colors.purple[50])?.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (isDark ? Colors.purple[700] : Colors.purple[200])!,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          tag.toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.purple[300] : Colors.purple[700],
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      )).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> advice) {
    final isDark = context.read<ThemeProvider>().isDarkMode;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental dismissal
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.delete_forever_outlined,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'Delete Saved Advice?',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to permanently delete this saved legal advice?',
              style: TextStyle(
                color: isDark ? Colors.grey[300] : Colors.grey[700],
                height: 1.4,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF374151) : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category: ${advice['category'] ?? 'General'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    advice['question'] ?? 'No question',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_outlined,
                    color: Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'This action cannot be undone!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Keep Advice',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final adviceId = advice['id']?.toString();
              if (adviceId != null) {
                _removeAdvice(adviceId);
              } else {
                _showSnackBar('Error: Unable to delete advice (no ID found)', Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.delete_forever,
                  size: 18,
                  color: Colors.white,
                ),
                SizedBox(width: 6),
                Text(
                  'Delete Forever',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}