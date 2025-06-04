import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/theme_provider.dart';
import '../services/database_service.dart';
import '../utils/philippine_time.dart';

class RecentCasesScreen extends StatefulWidget {
  final List<Map<String, dynamic>> recentCases;
  final VoidCallback onCaseUpdated;

  const RecentCasesScreen({
    super.key,
    required this.recentCases,
    required this.onCaseUpdated,
  });

  @override
  State<RecentCasesScreen> createState() => _RecentCasesScreenState();
}

class _RecentCasesScreenState extends State<RecentCasesScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Map<String, dynamic>> _recentCases = [];
  bool _isLoading = false;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _recentCases = List.from(widget.recentCases);
    // Debug: Print actual categories found in cases
    _debugPrintCategories();
  }

  void _debugPrintCategories() {
    final categories = _recentCases
        .map((chatCase) => chatCase['category']?.toString() ?? 'null')
        .toSet()
        .toList();
    print('Actual categories in recent cases: $categories');
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

    // Only add categories that exist in your chat history
    for (var chatCase in _recentCases) {
      if (chatCase['category'] != null) {
        final category = chatCase['category'].toString();
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

  String _getCategoryExamples(String category) {
    switch (category.toLowerCase()) {
      case 'cybercrime prevention act':
        return '"Cybercrime Prevention", "Cyber Law", etc.';
      case 'data privacy':
        return '"Data Protection", "Privacy", etc.';
      case 'online harassment':
        return '"Cyberbullying", "Harassment", etc.';
      case 'e-commerce fraud':
        return '"Online Shopping Fraud", "Digital Commerce Scams", etc.';
      case 'identity theft':
        return '"Identity Fraud", "Personal Information Theft", etc.';
      case 'unauthorized access':
        return '"Hacking", "Illegal Access", "System Intrusion", etc.';
      case 'general':
        return 'miscellaneous legal topics';
      default:
        return 'related topics';
    }
  }

  void _showSaveAsAdviceConfirmation(Map<String, dynamic> chatCase) {
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
                color: (isDark ? Colors.amber[900] : Colors.amber[50])?.withOpacity(0.8),
                shape: BoxShape.circle,
                border: Border.all(
                  color: (isDark ? Colors.amber[700] : Colors.amber[300])!,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.bookmark_add_outlined,
                color: isDark ? Colors.amber[300] : Colors.amber[700],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'Save as Advice?',
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
              'Do you want to save this legal case to your bookmarked advice for future reference?',
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]
                                : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          chatCase['category'] ?? 'General',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (chatCase['confidence_score'] != null)
                        Text(
                          '${((chatCase['confidence_score'] as double) * 100).round()}% Confidence',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    chatCase['question'] ?? 'No question',
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
                color: (isDark ? Colors.amber[900] : Colors.amber[50])?.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (isDark ? Colors.amber[700] : Colors.amber[300])!,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: isDark ? Colors.amber[300] : Colors.amber[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will be added to your Saved Advice collection for quick access.',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.amber[300] : Colors.amber[700],
                        fontWeight: FontWeight.w500,
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
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveAsAdvice(chatCase);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.amber[700] : Colors.amber[600],
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.bookmark_add,
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Save Advice',
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

  Future<void> _refreshRecentCases() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all cases and let the filtering logic handle category matching
      final updatedCases = await _databaseService.getChatHistory(limit: 50);
      setState(() {
        _recentCases = updatedCases;
        _isLoading = false;
      });
      // Debug: Print actual categories after refresh
      _debugPrintCategories();
      widget.onCaseUpdated();
    } catch (e) {
      print('Error refreshing recent cases: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _shareCase(Map<String, dynamic> chatCase) async {
    try {
      final shareText = '''
📋 Legal Case from LawBot

❓ Question:
${chatCase['question'] ?? 'No question'}

🤖 LawBot Answer:
${chatCase['answer'] ?? 'No answer'}

📂 Category: ${chatCase['category'] ?? 'General'}
⏰ ${PhilippineTime.formatChatHistoryTime(chatCase['created_at'])}

${chatCase['confidence_score'] != null ? '🎯 Confidence: ${((chatCase['confidence_score'] as double) * 100).round()}%' : ''}

---
Generated by LawBot - Your AI Legal Assistant for Philippine Cybercrime Laws
      ''';

      await Share.share(
        shareText.trim(),
        subject: 'Legal Case from LawBot',
      );
    } catch (e) {
      print('Error sharing case: $e');
      _showSnackBar('Failed to share case. Please try again.', Colors.red);
    }
  }

  Future<void> _saveAsAdvice(Map<String, dynamic> chatCase) async {
    try {
      // Check if already saved
      final isAlreadySaved = await _databaseService.isAdviceSaved(
        chatCase['question'] ?? '',
        chatCase['answer'] ?? '',
      );

      if (isAlreadySaved) {
        _showSnackBar('This advice is already saved!', Colors.orange);
        return;
      }

      await _databaseService.saveAdvice(
        question: chatCase['question'] ?? '',
        answer: chatCase['answer'] ?? '',
        category: chatCase['category'] ?? 'General',
        tags: chatCase['metadata']?['keywords']?.cast<String>() ?? [],
      );

      _showSnackBar('Case saved to your bookmarks!', Colors.green);
    } catch (e) {
      print('Error saving case as advice: $e');
      _showSnackBar('Failed to save case. Please try again.', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
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
  List<Map<String, dynamic>> get _filteredCases {
    if (_selectedCategory == 'All') {
      return _recentCases;
    }
    return _recentCases.where((chatCase) {
      final caseCategory = (chatCase['category'] ?? '').toString();
      return caseCategory == _selectedCategory;
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
                Icons.history,
                color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'Recent Cases',
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
            onPressed: _refreshRecentCases,
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? Colors.white : const Color(0xFF2563EB),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter with conversation counts (matching HistoryTab)
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
                  final isSelected = category == _selectedCategory;
                  final categoryCount = category == 'All'
                      ? _recentCases.length
                      : _recentCases.where((chatCase) => chatCase['category'] == category).length;

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
                          _selectedCategory = category;
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

          // Cases List
          Expanded(
            child: _isLoading
                ? Center(
              child: CircularProgressIndicator(
                color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
              ),
            )
                : _filteredCases.isEmpty
                ? _buildEmptyState(isDark)
                : RefreshIndicator(
              onRefresh: _refreshRecentCases,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredCases.length,
                itemBuilder: (context, index) {
                  final chatCase = _filteredCases[index];
                  return _buildCaseCard(chatCase, isDark);
                },
              ),
            ),
          ),
        ],
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
                Icons.chat_bubble_outline,
                size: 60,
                color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _selectedCategory == 'All'
                  ? 'No Cases Yet'
                  : 'No $_selectedCategory Cases Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _selectedCategory == 'All'
                  ? 'Start asking legal questions in the chat to see your conversation history here.'
                  : 'No cases found matching "$_selectedCategory". This includes related categories like ${_getCategoryExamples(_selectedCategory)}. Try asking questions about this topic or select "All" to see all cases.',
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

  Widget _buildCaseCard(Map<String, dynamic> chatCase, bool isDark) {
    // Parse metadata for keywords and recommendations
    final metadata = chatCase['metadata'] as Map<String, dynamic>?;
    final keywords = metadata?['keywords'] as List<dynamic>?;
    final recommendations = metadata?['recommendations'] as List<dynamic>?;

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
            // Header with category and actions
            Row(
              children: [
                Flexible(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]
                            : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      chatCase['category'] ?? 'General',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  flex: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Confidence Score
                      if (chatCase['confidence_score'] != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: (chatCase['confidence_score'] as double) > 0.8
                                ? Colors.green.withOpacity(0.1)
                                : (chatCase['confidence_score'] as double) > 0.6
                                ? Colors.orange.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: (chatCase['confidence_score'] as double) > 0.8
                                  ? Colors.green
                                  : (chatCase['confidence_score'] as double) > 0.6
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
                                color: (chatCase['confidence_score'] as double) > 0.8
                                    ? Colors.green
                                    : (chatCase['confidence_score'] as double) > 0.6
                                    ? Colors.orange
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${((chatCase['confidence_score'] as double) * 100).round()}%',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: (chatCase['confidence_score'] as double) > 0.8
                                      ? Colors.green
                                      : (chatCase['confidence_score'] as double) > 0.6
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
                          PhilippineTime.formatChatHistoryTime(chatCase['created_at']),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[400] : Colors.grey[500],
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Menu
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
                              _shareCase(chatCase);
                              break;
                            case 'save':
                              _showSaveAsAdviceConfirmation(chatCase);
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
                            value: 'save',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.bookmark_outline,
                                  size: 18,
                                  color: isDark ? Colors.amber[300] : Colors.amber[600],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Save as Advice',
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
            ),
            const SizedBox(height: 16),

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
                    chatCase['question'] ?? 'No question',
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
                    chatCase['answer'] ?? 'No answer',
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
          ],
        ),
      ),
    );
  }
}