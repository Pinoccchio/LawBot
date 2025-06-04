import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';

import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/gemini_service.dart';
import '../../services/database_service.dart';
import '../../utils/philippine_time.dart';

class ChatTab extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const ChatTab({super.key, this.onNavigateToTab});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DatabaseService _databaseService = DatabaseService();

  bool _isTyping = false;
  String? _sessionId;
  String? _currentUserId;
  List<ChatMessage> _messages = [];
  Timer? _timeUpdateTimer;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _startTimeUpdateTimer();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _timeUpdateTimer?.cancel();
    super.dispose();
  }

  void _startTimeUpdateTimer() {
    _timeUpdateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _initializeChat() async {
    _sessionId = _databaseService.generateSessionId();
    final user = FirebaseAuth.instance.currentUser;
    _currentUserId = user?.uid ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';

    final welcomeTime = PhilippineTime.now();
    setState(() {
      _messages = [
        ChatMessage(
          text: "Hello! I am LawBot, your AI legal assistant specialized in Philippine cybercrime laws. I can help you with questions about the Cybercrime Prevention Act, Data Privacy Act, online harassment, e-commerce fraud, and more. How can I assist you today?",
          isBot: true,
          time: PhilippineTime.formatTime(welcomeTime),
          philippineDateTime: welcomeTime,
          category: 'General',
          confidenceScore: 1.0,
          keywords: ['cybercrime', 'legal assistance', 'philippines'],
          recommendations: ['Ask about specific cybercrime concerns', 'Report online harassment', 'Learn about data privacy rights'],
        ),
      ];
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    final currentPhilippineTime = PhilippineTime.now();

    _messageController.clear();
    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isBot: false,
        time: PhilippineTime.formatTime(currentPhilippineTime),
        philippineDateTime: currentPhilippineTime,
        category: 'User',
      ));
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      final chatHistory = await _databaseService.getChatHistoryForContext(
        sessionId: _sessionId,
        limit: 5,
      );

      final aiResponseData = await GeminiService.generateLegalResponse(userMessage, chatHistory);

      final aiResponse = aiResponseData['response'] as String;
      final category = aiResponseData['category'] as String;
      final confidenceScore = aiResponseData['confidence'] as double;
      final keywords = (aiResponseData['keywords'] as List?)?.cast<String>() ?? [];
      final recommendations = (aiResponseData['recommendations'] as List?)?.cast<String>() ?? [];

      final aiResponseTime = PhilippineTime.now();

      final aiMessage = ChatMessage(
        text: aiResponse,
        isBot: true,
        time: PhilippineTime.formatTime(aiResponseTime),
        philippineDateTime: aiResponseTime,
        category: category,
        confidenceScore: confidenceScore,
        keywords: keywords,
        recommendations: recommendations,
      );

      setState(() {
        _isTyping = false;
        _messages.add(aiMessage);
      });

      final chatId = await _databaseService.saveChatMessage(
        question: userMessage,
        answer: aiResponse,
        category: category,
        confidenceScore: confidenceScore,
        sessionId: _sessionId,
        keywords: keywords,
        recommendations: recommendations,
        metadata: {
          'response_time': aiResponseTime.millisecondsSinceEpoch - currentPhilippineTime.millisecondsSinceEpoch,
          'message_count': _messages.length,
          'user_type': _currentUserId!.startsWith('guest_') ? 'guest' : 'authenticated',
          'philippine_time': PhilippineTime.toPhilippineIsoString(currentPhilippineTime),
          'timezone': 'Asia/Manila',
          'user_local_time': PhilippineTime.formatDateTime(currentPhilippineTime),
        },
      );

      aiMessage.chatId = chatId;
      _scrollToBottom();
    } catch (e) {
      final errorTime = PhilippineTime.now();
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text: "I apologize, but I'm experiencing technical difficulties right now. Please try asking your question again in a moment. For urgent legal matters, please contact the PNP Anti-Cybercrime Group directly at (02) 8723-0401.",
          isBot: true,
          time: PhilippineTime.formatTime(errorTime),
          philippineDateTime: errorTime,
          category: 'Error',
          confidenceScore: 0.0,
        ));
      });
      _scrollToBottom();
      debugPrint('Error in chat: $e');
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _clearChat() async {
    setState(() {
      _messages.clear();
      _sessionId = _databaseService.generateSessionId();
    });
    await _initializeChat();
  }

  // Bookmark functionality
  Future<void> _bookmarkMessage(ChatMessage message) async {
    if (FirebaseAuth.instance.currentUser == null) {
      _showSignInRequiredDialog();
      return;
    }

    try {
      // Check if already saved
      final isAlreadySaved = await _databaseService.isAdviceSaved(
        _messages[_messages.indexOf(message) - 1].text, // User question
        message.text, // Bot answer
      );

      if (isAlreadySaved) {
        _showSnackBar('This advice is already saved!', Colors.orange);
        return;
      }

      // Get the user question that preceded this bot response
      final userQuestionIndex = _messages.indexOf(message) - 1;
      if (userQuestionIndex >= 0 && !_messages[userQuestionIndex].isBot) {
        final userQuestion = _messages[userQuestionIndex].text;

        await _databaseService.saveAdvice(
          question: userQuestion,
          answer: message.text,
          category: message.category,
          tags: message.keywords,
        );

        _showSnackBar('Legal advice saved to your bookmarks!', Colors.green);
      }
    } catch (e) {
      print('Error bookmarking message: $e');
      _showSnackBar('Failed to save advice. Please try again.', Colors.red);
    }
  }

  // Share functionality
  Future<void> _shareMessage(ChatMessage message) async {
    try {
      // Get the user question that preceded this bot response
      final userQuestionIndex = _messages.indexOf(message) - 1;
      String shareText = '';

      if (userQuestionIndex >= 0 && !_messages[userQuestionIndex].isBot) {
        final userQuestion = _messages[userQuestionIndex].text;
        shareText = '''
📋 Legal Question & Answer from LawBot

❓ Question:
$userQuestion

🤖 LawBot Answer:
${message.text}

📂 Category: ${message.category}
⏰ ${message.time}

---
Generated by LawBot - Your AI Legal Assistant for Philippine Cybercrime Laws
        ''';
      } else {
        shareText = '''
🤖 Legal Advice from LawBot

${message.text}

📂 Category: ${message.category}
⏰ ${message.time}

---
Generated by LawBot - Your AI Legal Assistant for Philippine Cybercrime Laws
        ''';
      }

      await Share.share(
        shareText.trim(),
        subject: 'Legal Advice from LawBot',
      );
    } catch (e) {
      print('Error sharing message: $e');
      _showSnackBar('Failed to share message. Please try again.', Colors.red);
    }
  }

  void _showSignInRequiredDialog() {
    final isDark = context.read<ThemeProvider>().isDarkMode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Row(
          children: [
            Icon(
              Icons.account_circle_outlined,
              color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
            ),
            const SizedBox(width: 8),
            Text(
              'Sign In Required',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        content: Text(
          'You need to sign in to save legal advice to your bookmarks. This helps us keep your saved advice synced across all your devices.',
          style: TextStyle(
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Maybe Later',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/signin');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
            ),
            child: const Text(
              'Sign In',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
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

  void _showChatOptions() {
    final isDark = context.read<ThemeProvider>().isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[600] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.refresh_rounded, color: Colors.blue),
              ),
              title: const Text('New Conversation'),
              subtitle: const Text('Start a fresh conversation'),
              onTap: () {
                Navigator.pop(context);
                _clearChat();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.history_rounded, color: Colors.green),
              ),
              title: const Text('View Chat History'),
              subtitle: const Text('See previous conversations'),
              onTap: () {
                Navigator.pop(context);
                if (widget.onNavigateToTab != null) {
                  widget.onNavigateToTab!(2);
                }
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.library_books_rounded, color: Colors.orange),
              ),
              title: const Text('Legal Resources'),
              subtitle: const Text('Browse legal documents and guides'),
              onTap: () {
                Navigator.pop(context);
                if (widget.onNavigateToTab != null) {
                  widget.onNavigateToTab!(1);
                }
              },
            ),
          ],
        ),
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
                Icons.smart_toy_rounded,
                size: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LawBot AI',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF2563EB),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Online • Philippine Time: ${PhilippineTime.getCurrentTimeString()}',
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
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.more_vert_rounded,
              color: isDark ? Colors.white : const Color(0xFF2563EB),
            ),
            onPressed: _showChatOptions,
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator(isDark);
                }
                final message = _messages[index];
                return ChatBubble(
                  message: message,
                  onBookmark: () => _bookmarkMessage(message),
                  onShare: () => _shareMessage(message),
                );
              },
            ),
          ),
          _buildMessageInput(isDark, languageProvider),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(isDark, 0),
                const SizedBox(width: 4),
                _buildDot(isDark, 1),
                const SizedBox(width: 4),
                _buildDot(isDark, 2),
                const SizedBox(width: 12),
                Text(
                  'LawBot is thinking...',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(bool isDark, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 600 + (index * 200)),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildMessageInput(bool isDark, LanguageProvider languageProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
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
                child: TextField(
                  controller: _messageController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ask about Philippine cybercrime laws...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                  maxLines: null,
                  enabled: !_isTyping,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]
                      : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB)).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isTyping ? null : _sendMessage,
                  borderRadius: BorderRadius.circular(24),
                  child: Icon(
                    _isTyping ? Icons.hourglass_empty_rounded : Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isBot;
  final String time;
  final DateTime philippineDateTime;
  final String category;
  final double? confidenceScore;
  final List<String>? keywords;
  final List<String>? recommendations;
  String? chatId;

  ChatMessage({
    required this.text,
    required this.isBot,
    required this.time,
    required this.philippineDateTime,
    required this.category,
    this.confidenceScore,
    this.keywords,
    this.recommendations,
    this.chatId,
  });

  String getRelativeTimeString() {
    return PhilippineTime.getRelativeTimeString(philippineDateTime);
  }
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onBookmark;
  final VoidCallback? onShare;

  const ChatBubble({
    super.key,
    required this.message,
    this.onBookmark,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isBot
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (message.isBot) ...[
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                  if (message.category != 'General' && message.category != 'User') ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]
                              : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        message.category,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black,
                      height: 1.4,
                    ),
                  ),
                  if (message.recommendations != null && message.recommendations!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.blue[900] : Colors.blue[50])?.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
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
                                size: 14,
                                color: isDark ? Colors.blue[300] : Colors.blue[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Recommendations:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.blue[300] : Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ...message.recommendations!.take(3).map((rec) => Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '• $rec',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.blue[200] : Colors.blue[800],
                              ),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.getRelativeTimeString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      if (message.confidenceScore != null) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.verified_rounded,
                          size: 14,
                          color: message.confidenceScore! > 0.8
                              ? Colors.green
                              : message.confidenceScore! > 0.6
                              ? Colors.orange
                              : Colors.grey,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${(message.confidenceScore! * 100).round()}%',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (message.isBot && onBookmark != null) ...[
                        InkWell(
                          onTap: onBookmark,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.bookmark_border_rounded,
                              size: 16,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (message.isBot && onShare != null)
                        InkWell(
                          onTap: onShare,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.share_outlined,
                              size: 16,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]
                      : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB)).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.text,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message.getRelativeTimeString(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
